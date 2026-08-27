#!/usr/bin/env python3
"""Development-only source inventory. Never called by application runtime."""

import argparse
import hashlib
import json
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "sports"
EXCLUDED = "Schedule_All_Sports_2026-08-27.pdf"
REVIEW_DIR = ROOT / "tmp" / "sports-pdf"
PICKLEBALL_TOURNAMENTS = {
    "DÔI NAM d30t-32.pdf": "doi-nam-duoi-30",
    "DÔI NAM 31-40T 37 (1).pdf": "doi-nam-31-40",
    "DÔI NAM 41-50T-40.pdf": "doi-nam-41-50",
    "DÔI NAM 51T-26.pdf": "doi-nam-tren-51",
    "DÔI NỮ 31-40T-18.pdf": "doi-nu-31-40",
    "DÔI NỮ 41-50.pdf": "doi-nu-41-50",
    "ĐÔI NỮ 50T.pdf": "doi-nu-tren-50",
    "DÔI NAM NƯ D30T-22.pdf": "doi-nam-nu-duoi-30",
    "DÔI NAM NỮ 31-40T-31.pdf": "doi-nam-nu-31-40",
    "DÔI NAM NỮ 41-50T-21.pdf": "doi-nam-nu-41-50",
    "ĐÔI NAM NỮ 51-10.pdf": "doi-nam-nu-tren-51",
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inventory() -> list[dict[str, object]]:
    rows = []
    for path in sorted(SOURCE_DIR.rglob("*.pdf")):
        with fitz.open(path) as document:
            rows.append({
                "filename": path.name,
                "path": str(path.relative_to(ROOT)),
                "sha256": digest(path),
                "pages": len(document),
                "folder": path.parent.name,
                "included": path.name != EXCLUDED,
            })
    return rows


def review_sources() -> dict[str, int]:
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    sources = []
    table_pages = 0
    page_count = 0
    for item in inventory():
        if not item["included"]:
            continue
        path = ROOT / str(item["path"])
        pages = []
        with fitz.open(path) as document:
            for number, page in enumerate(document, 1):
                tables = [table.extract() for table in page.find_tables().tables]
                if tables:
                    table_pages += 1
                image = REVIEW_DIR / f"{item['sha256'][:12]}-p{number}.png"
                page.get_pixmap(matrix=fitz.Matrix(1.25, 1.25), alpha=False).save(image)
                pages.append({"page": number, "image": str(image.relative_to(ROOT)), "text": page.get_text(), "tables": tables})
                page_count += 1
        sources.append({**item, "pages_data": pages})
    (REVIEW_DIR / "review.json").write_text(json.dumps(sources, ensure_ascii=False), encoding="utf-8")
    return {"sources": len(sources), "pages": page_count, "table_pages": table_pages}


def pickleball_pairs() -> list[dict[str, object]]:
    rows = []
    for item in inventory():
        if item["folder"] != "PICKLEBAL":
            continue
        pairs = []
        seen = set()
        with fitz.open(ROOT / str(item["path"])) as document:
            for page_number, page in enumerate(document, 1):
                for table in page.find_tables().tables:
                    data = table.extract()
                    if not data or len(data[0]) < 2 or str(data[0][1] or "").strip().upper() not in {"CẶP ĐÔI", "CẶP ĐOI", "VĐV"}:
                        continue
                    for row in data[1:]:
                        if len(row) < 2 or not row[1] or ("/" not in row[1] and "\n" not in row[1]):
                            continue
                        source_text = str(row[1]).strip()
                        key = " ".join(source_text.split())
                        if key in seen:
                            continue
                        seen.add(key)
                        pairs.append({"name": key, "source_text": source_text, "source_page": page_number})
        rows.append({"filename": item["filename"], "path": item["path"], "pairs": pairs})
    return rows


def sql(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def source_members(source_text: str):
    before, marker, organization = source_text.rpartition("-")
    if not marker or not organization.strip():
        return None, None, None
    names = [part.strip().rstrip("/").strip() for part in before.splitlines() if part.strip()]
    if len(names) == 1 and "/" in names[0]:
        names = [part.strip() for part in names[0].split("/") if part.strip()]
    if len(names) != 2:
        return organization.strip(), None, None
    return organization.strip(), names[0], names[1]


def pickleball_seed() -> str:
    """Emit source-only pairs/groups/fixtures; no player or org names are inferred."""
    pairs = []
    groups = []
    fixtures = []
    for item in inventory():
        if item["folder"] != "PICKLEBAL":
            continue
        tournament_slug = PICKLEBALL_TOURNAMENTS[str(item["filename"])]
        seen_pairs = set()
        group_order = 0
        with fitz.open(ROOT / str(item["path"])) as document:
            for page_number, page in enumerate(document, 1):
                current_group = None
                for table in page.find_tables().tables:
                    data = table.extract()
                    header = " ".join(str(cell or "").upper() for cell in data[0]) if data else ""
                    if len(data[0]) >= 2 and str(data[0][1] or "").strip().upper() in {"CẶP ĐÔI", "CẶP ĐOI", "VĐV"}:
                        group_order += 1
                        label = chr(64 + group_order) if group_order <= 26 else str(group_order)
                        current_group = f"Bảng {label}"
                        groups.append((tournament_slug, current_group, group_order))
                        for row in data[1:]:
                            if len(row) < 2 or not row[1]:
                                continue
                            source_text = str(row[1]).strip()
                            if "/" not in source_text and "\n" not in source_text:
                                continue
                            key = " ".join(source_text.split())
                            if key in seen_pairs:
                                continue
                            seen_pairs.add(key)
                            name = " / ".join(part.strip().rstrip("/") for part in source_text.splitlines() if part.strip())
                            organization, member_one, member_two = source_members(source_text)
                            pairs.append((tournament_slug, current_group, name, page_number, organization, member_one, member_two))
                    elif current_group and "CẶP ĐÔI 1" in header and "CẶP ĐÔI 2" in header:
                        for row in data[1:]:
                            if len(row) < 4 or not row[2] or not row[3]:
                                continue
                            first = " / ".join(part.strip().rstrip("/") for part in str(row[2]).splitlines() if part.strip())
                            second = " / ".join(part.strip().rstrip("/") for part in str(row[3]).splitlines() if part.strip())
                            fixtures.append((tournament_slug, current_group, first, second, page_number, len(fixtures) + 1))
    lines = [
        "-- Generated from reviewed PICKLEBAL PDFs. Unseparated source labels remain pair-only rather than guessed.",
        "create temporary table seed_pickleball_pairs (tournament_slug text, group_name text, pair_name text, source_page integer, organization_code text, member_one text, member_two text) on commit drop;",
        "insert into seed_pickleball_pairs values",
        ",\n".join(f"  ({sql(t)},{sql(g)},{sql(n)},{p},{'null' if not c else sql(c)},{'null' if not a else sql(a)},{'null' if not b else sql(b)})" for t, g, n, p, c, a, b in pairs) + ";",
        "insert into public.organizations (code, name_vi, name_en)",
        "select distinct organization_code, organization_code, organization_code from seed_pickleball_pairs where organization_code is not null",
        "on conflict (code) do update set archived_at = null;",
        "insert into public.participants (organization_id, full_name)",
        "select o.id, names.full_name from seed_pickleball_pairs p join public.organizations o on o.code = p.organization_code",
        "cross join lateral (values (p.member_one), (p.member_two)) names(full_name) where names.full_name is not null",
        "and not exists (select 1 from public.participants a where a.organization_id = o.id and a.full_name = names.full_name);",
        "insert into public.groups (tournament_id, name_vi, name_en, sort_order)",
        "select t.id, g.group_name, replace(g.group_name, 'Bảng ', 'Group '), min(g.group_order)",
        "from (values",
        ",\n".join(f"  ({sql(t)},{sql(g)},{o})" for t, g, o in sorted(set(groups))) + ") as g(tournament_slug, group_name, group_order)",
        "join public.sports s on s.slug = 'pickleball' join public.tournaments t on t.sport_id = s.id and t.slug = g.tournament_slug",
        "group by t.id, g.group_name on conflict (tournament_id, name_vi) do update set archived_at = null;",
        "insert into public.entries (tournament_id, organization_id, kind, name_vi, name_en)",
        "select t.id, o.id, 'pair', p.pair_name, p.pair_name from (select distinct tournament_slug, pair_name, organization_code from seed_pickleball_pairs) p",
        "join public.sports s on s.slug = 'pickleball' join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug",
        "left join public.organizations o on o.code = p.organization_code",
        "where not exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.pair_name);",
        "insert into public.entry_members (entry_id, participant_id, sort_order)",
        "select e.id, a.id, names.sort_order from seed_pickleball_pairs p join public.sports s on s.slug = 'pickleball'",
        "join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug join public.entries e on e.tournament_id = t.id and e.name_vi = p.pair_name",
        "join public.organizations o on o.code = p.organization_code cross join lateral (values (p.member_one, 1), (p.member_two, 2)) names(full_name, sort_order)",
        "join public.participants a on a.organization_id = o.id and a.full_name = names.full_name where names.full_name is not null",
        "on conflict (entry_id, participant_id) do update set archived_at = null;",
        "insert into public.group_entries (group_id, entry_id)",
        "select g.id, e.id from seed_pickleball_pairs p join public.sports s on s.slug = 'pickleball'",
        "join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name",
        "join public.entries e on e.tournament_id = t.id and e.name_vi = p.pair_name",
        "on conflict (group_id, entry_id) do update set archived_at = null;",
        "-- Match rows intentionally omit time/court: these PDF tables do not state either field.",
        "create temporary table seed_pickleball_fixtures (tournament_slug text, group_name text, home_name text, away_name text, source_page integer, sort_order integer) on commit drop;",
        "insert into seed_pickleball_fixtures values",
        ",\n".join(f"  ({sql(t)},{sql(g)},{sql(h)},{sql(a)},{p},{o})" for t, g, h, a, p, o in fixtures) + ";",
        "insert into public.fixtures (tournament_id, group_id, status, round_vi, round_en, round_order)",
        "select t.id, g.id, 'scheduled', 'Vòng bảng', 'Group stage', p.sort_order from seed_pickleball_fixtures p",
        "join public.sports s on s.slug = 'pickleball' join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug",
        "join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name",
        "where exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.home_name)",
        "and exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.away_name)",
        "and not exists (select 1 from public.fixtures f where f.tournament_id = t.id and f.group_id = g.id and f.round_order = p.sort_order);",
        "insert into public.fixture_entries (fixture_id, entry_id, side)",
        "select f.id, e.id, x.side from seed_pickleball_fixtures p join public.sports s on s.slug = 'pickleball'",
        "join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name",
        "join public.fixtures f on f.tournament_id = t.id and f.group_id = g.id and f.round_order = p.sort_order",
        "cross join lateral (values (p.home_name, 'home'), (p.away_name, 'away')) x(pair_name, side)",
        "join public.entries e on e.tournament_id = t.id and e.name_vi = x.pair_name",
        "on conflict (fixture_id, entry_id) do update set archived_at = null;",
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", action="store_true")
    parser.add_argument("--review", action="store_true")
    parser.add_argument("--pickleball", action="store_true")
    parser.add_argument("--pickleball-seed", action="store_true")
    args = parser.parse_args()
    if sum((args.inventory, args.review, args.pickleball, args.pickleball_seed)) != 1:
        parser.error("use one mode")
    if args.pickleball_seed:
        print(pickleball_seed(), end="")
    else:
        result = inventory() if args.inventory else review_sources() if args.review else pickleball_pairs()
        print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
