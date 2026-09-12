#!/usr/bin/env python3
"""Build a static seed from reviewed table-tennis and badminton PDFs."""

from __future__ import annotations

import re
import unicodedata
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "bong-ban": ROOT / "assets/sports/BÓNG BÀN/B Bàn pn 26 (1).pdf",
    "cau-long": ROOT / "assets/sports/CẦU LÔNG/CẦU LÔNG PN 2026.pdf",
}
TOURNAMENTS = {
    "bong-ban": [
        ("doi nam nu 41 50", "doi-nam-nu-41-50"), ("doi nam nu 31 40", "doi-nam-nu-31-40"),
        ("doi nam 41 50", "doi-nam-41-50"), ("doi nam 31 40", "doi-nam-31-40"),
        ("doi nam duoi 30", "doi-nam-duoi-30"), ("doi nu", "doi-nu"),
    ],
    "cau-long": [
        ("doi nam nu 41 50", "doi-nam-nu-41-50"), ("doi nam nu 31 40", "doi-nam-nu-31-40"),
        ("doi nam nu duoi 30", "doi-nam-nu-duoi-30"), ("doi nam tren 51", "doi-nam-tren-51"),
        ("doi nam 41 50", "doi-nam-41-50"), ("doi nam 31 40", "doi-nam-31-40"),
        ("doi nam duoi 30", "doi-nam-duoi-30"), ("doi nu 31 40", "doi-nu-31-40"),
        ("doi nu", "doi-nu-duoi-30"),
    ],
}


def folded(value: object) -> str:
    value = str(value or "").replace("Đ", "D").replace("đ", "d")
    value = unicodedata.normalize("NFD", value).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", value).strip()


def clean(value: object) -> str:
    return " / ".join(part.strip().rstrip("/").strip() for part in str(value or "").splitlines() if part.strip())


def sql(value: str | None) -> str:
    return "null" if value is None else "'" + value.replace("'", "''") + "'"


def members(pair: str) -> tuple[str | None, str | None, str | None]:
    before, marker, organization = pair.rpartition("-")
    if not marker or not organization.strip():
        return None, None, None
    names = [part.strip() for part in before.split(" / ") if part.strip()]
    return organization.strip(), names[0] if len(names) == 2 else None, names[1] if len(names) == 2 else None


def tournament_for(sport: str, text: str, current: str | None) -> str | None:
    source = folded(text)
    for label, slug in TOURNAMENTS[sport]:
        if label in source:
            return slug
    return current


def extract() -> tuple[list[tuple], list[tuple]]:
    pairs: list[tuple] = []
    fixtures: list[tuple] = []
    for sport, path in SOURCES.items():
        current_tournament = None
        group_order = 0
        fixture_order = 0
        with fitz.open(path) as document:
            for page_number, page in enumerate(document, 1):
                text = page.get_text()
                current_tournament = tournament_for(sport, text, current_tournament)
                if not current_tournament:
                    continue
                group_labels = re.findall(r"BẢNG\s*([A-Z])", text, flags=re.I)
                label_index = 0
                current_group = None
                roster_found = False
                for table in page.find_tables().tables:
                    rows = table.extract()
                    if not rows:
                        continue
                    header = " ".join(str(cell or "") for cell in rows[0])
                    normalized_header = folded(header)
                    if "vdv" in normalized_header and len(rows[0]) > 1:
                        roster_found = True
                        label = group_labels[label_index] if label_index < len(group_labels) else None
                        label_index += 1
                        group_order += 1
                        current_group = f"Bảng {label}" if label else f"Bảng {group_order}"
                        for row in rows[1:]:
                            if len(row) < 2 or not str(row[0] or "").strip().isdigit():
                                continue
                            pair = clean(row[1])
                            if "/" not in pair:
                                continue
                            organization, member_one, member_two = members(pair)
                            pairs.append((sport, current_tournament, current_group, group_order, pair, organization, member_one, member_two, page_number))
                    elif current_group and "cap doi 1" in normalized_header and "cap doi 2" in normalized_header:
                        for row in rows[1:]:
                            if len(row) < 4:
                                continue
                            home, away = clean(row[2]), clean(row[3])
                            if not home or not away or "/" not in home or "/" not in away or home == away:
                                continue
                            fixture_order += 1
                            fixtures.append((sport, current_tournament, current_group, home, away, fixture_order, page_number))
                if not roster_found:
                    group_order += 1
                    current_group = "Danh sách"
                    for first, second in re.findall(r"(?m)^([^\n]+/)\n(?:\d+\s*)?([^\n]+)$", text):
                        pair = clean(f"{first}\n{second}")
                        if "/" not in pair:
                            continue
                        organization, member_one, member_two = members(pair)
                        pairs.append((sport, current_tournament, current_group, group_order, pair, organization, member_one, member_two, page_number))
    return list(dict.fromkeys(pairs)), list(dict.fromkeys(fixtures))


def seed() -> str:
    pairs, fixtures = extract()
    pair_values = ",\n".join("  (" + ",".join(sql(value) if isinstance(value, str) or value is None else str(value) for value in row) + ")" for row in pairs)
    fixture_values = ",\n".join("  (" + ",".join(sql(value) if isinstance(value, str) or value is None else str(value) for value in row) + ")" for row in fixtures)
    return f"""set app.tenant_slug = 'petrovietnam2026';

-- Generated from reviewed PDFs. Missing unit labels and self-pair extraction artifacts stay unseeded.
create temporary table seed_pair_sports (
  sport_slug text, tournament_slug text, group_name text, group_order integer, pair_name text,
  organization_code text, member_one text, member_two text, source_page integer
) on commit drop;
insert into seed_pair_sports values
{pair_values};

insert into public.organizations (code, name_vi, name_en)
select distinct organization_code, organization_code, organization_code
from seed_pair_sports where organization_code is not null
on conflict (tenant_id, code) do update set archived_at = null;

insert into public.participants (organization_id, full_name)
select o.id, names.full_name
from seed_pair_sports p join public.organizations o on o.code = p.organization_code
cross join lateral (values (p.member_one), (p.member_two)) names(full_name)
where names.full_name is not null
and not exists (select 1 from public.participants a where a.organization_id = o.id and a.full_name = names.full_name);

insert into public.groups (tournament_id, name_vi, name_en, sort_order)
select t.id, p.group_name, replace(p.group_name, 'Bảng ', 'Group '), min(p.group_order)
from seed_pair_sports p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
group by t.id, p.group_name
on conflict (tournament_id, name_vi) do update set archived_at = null;

insert into public.entries (tournament_id, organization_id, kind, name_vi, name_en)
select t.id, o.id, 'pair', p.pair_name, p.pair_name
from (select distinct sport_slug, tournament_slug, pair_name, organization_code from seed_pair_sports) p
join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
left join public.organizations o on o.code = p.organization_code
where not exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.pair_name);

insert into public.entry_members (entry_id, participant_id, sort_order)
select distinct e.id, a.id, names.sort_order
from seed_pair_sports p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
join public.entries e on e.tournament_id = t.id and e.name_vi = p.pair_name
join public.organizations o on o.code = p.organization_code
cross join lateral (values (p.member_one, 1), (p.member_two, 2)) names(full_name, sort_order)
join public.participants a on a.organization_id = o.id and a.full_name = names.full_name
where names.full_name is not null
on conflict (entry_id, participant_id) do update set archived_at = null;

insert into public.group_entries (group_id, entry_id)
select distinct g.id, e.id
from seed_pair_sports p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name
join public.entries e on e.tournament_id = t.id and e.name_vi = p.pair_name
on conflict (group_id, entry_id) do update set archived_at = null;

create temporary table seed_pair_fixtures (
  sport_slug text, tournament_slug text, group_name text, home_name text, away_name text,
  sort_order integer, source_page integer
) on commit drop;
insert into seed_pair_fixtures values
{fixture_values};

insert into public.fixtures (tournament_id, group_id, status, round_vi, round_en, round_order)
select t.id, g.id, 'scheduled', 'Vòng bảng', 'Group stage', p.sort_order
from seed_pair_fixtures p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name
where exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.home_name)
and exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.away_name)
and not exists (select 1 from public.fixtures f where f.tournament_id = t.id and f.group_id = g.id and f.round_order = p.sort_order);

insert into public.fixture_entries (fixture_id, entry_id, side)
select distinct f.id, e.id, x.side
from seed_pair_fixtures p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name
join public.fixtures f on f.tournament_id = t.id and f.group_id = g.id and f.round_order = p.sort_order
cross join lateral (values (p.home_name, 'home'), (p.away_name, 'away')) x(pair_name, side)
join public.entries e on e.tournament_id = t.id and e.name_vi = x.pair_name
on conflict (fixture_id, entry_id) do update set archived_at = null;
"""


if __name__ == "__main__":
    print(seed(), end="")
