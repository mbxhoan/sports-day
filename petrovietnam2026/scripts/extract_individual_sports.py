#!/usr/bin/env python3
"""Build static swimming and athletics entries from reviewed PDF tables."""

from __future__ import annotations

import re
import unicodedata
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "boi-loi": ROOT / "assets/sports/BƠI LỘI/Boi pn 2026.pdf",
    "dien-kinh": ROOT / "assets/sports/ĐIỀN KINH/ĐKinh cap nhat 27.8 pvn 2026.pdf",
}
EVENTS = {
    "boi-loi": [("100m tu do nu", "100m-nu", "2026-09-05 08:45:00+07"), ("tu do nam 100m", "100m-nam", "2026-09-05 08:30:00+07"), ("100m tu do nam", "100m-nam", "2026-09-05 08:30:00+07"), ("50m tu do nu", "50m-nu", "2026-09-05 08:15:00+07"), ("tu do 50m nam", "50m-nam", "2026-09-05 08:00:00+07"), ("tu do nam 50m", "50m-nam", "2026-09-05 08:00:00+07"), ("50m tu do nam", "50m-nam", "2026-09-05 08:00:00+07"), ("dong doi nam 4x50m", "4x50m-nam", "2026-09-05 15:30:00+07"), ("dong doi nu 4x50m", "4x50m-nu", "2026-09-05 15:30:00+07")],
    "dien-kinh": [("chay tiep suc nam 4x100m", "4x100m-nam", "2026-09-06 07:00:00+07"), ("chay tiep suc nu 4x100m", "4x100m-nu", "2026-09-06 07:00:00+07"), ("cu ly 400m nu", "400m-nu", "2026-09-06 06:00:00+07"), ("cu ly 800m nam", "800m-nam", "2026-09-06 06:00:00+07"), ("cu ly 3000", "3000m-nu", "2026-09-06 15:00:00+07"), ("cu ly 5000", "5000m-nam", "2026-09-06 15:00:00+07")],
}


def folded(value: object) -> str:
    value = str(value or "").replace("Đ", "D").replace("đ", "d")
    value = unicodedata.normalize("NFD", value).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", value).strip()


def clean(value: object) -> str:
    return "\n".join(part.strip() for part in str(value or "").splitlines() if part.strip())


def sql(value: str | None) -> str:
    return "null" if value is None else "'" + value.replace("'", "''") + "'"


def event_for(sport: str, text: str, current: tuple[str, str] | None) -> tuple[str, str] | None:
    source = folded(text)
    for label, slug, starts_at in EVENTS[sport]:
        if label in source:
            return slug, starts_at
    return current


def organization(row: list[object], name_index: int) -> str | None:
    for value in [*row[name_index + 1:], *reversed(row[:name_index])]:
        candidate = clean(value)
        if not candidate or candidate in {"P", "s", "%s"} or re.fullmatch(r"[\d-]+", candidate):
            continue
        if any(character.isalpha() for character in candidate):
            return candidate.replace("\n", " ")
    return None


def extract() -> list[tuple]:
    rows: list[tuple] = []
    for sport, path in SOURCES.items():
        current_event = None
        with fitz.open(path) as document:
            for page_number, page in enumerate(document, 1):
                current_event = event_for(sport, page.get_text(), current_event)
                if not current_event:
                    continue
                slug, starts_at = current_event
                for table in page.find_tables().tables:
                    data = table.extract()
                    if not data or "vdv" not in folded(" ".join(str(cell or "") for cell in data[0])):
                        continue
                    name_index = next(index for index, value in enumerate(data[0]) if "vdv" in folded(value))
                    for row in data[1:]:
                        name = clean(row[name_index] if len(row) > name_index else "")
                        if not name or name in {"P", "s", "%s"} or name.upper() in {"NHẤT", "NHÌ", "BA"}:
                            continue
                        org = organization(row, name_index)
                        if not org:
                            continue
                        kind = "team" if "\n" in name else "individual"
                        entry_name = org if kind == "team" else name
                        rows.append((sport, slug, starts_at, page_number, kind, entry_name, org, name))
    return list(dict.fromkeys(rows))


def seed() -> str:
    rows = extract()
    values = ",\n".join("  (" + ",".join(sql(item) if isinstance(item, str) else str(item) for item in row) + ")" for row in rows)
    return f"""set app.tenant_slug = 'petrovietnam2026';

create temporary table seed_individual_sports (
  sport_slug text, tournament_slug text, starts_at timestamptz, source_page integer,
  kind text, entry_name text, organization_code text, member_names text
) on commit drop;
insert into seed_individual_sports values
{values};

insert into public.organizations (code, name_vi, name_en)
select distinct organization_code, organization_code, organization_code from seed_individual_sports
on conflict (tenant_id, code) do update set archived_at = null;

insert into public.participants (organization_id, full_name)
select o.id, names.full_name
from seed_individual_sports r join public.organizations o on o.code = r.organization_code
cross join lateral unnest(string_to_array(r.member_names, E'\\n')) names(full_name)
where not exists (select 1 from public.participants p where p.organization_id = o.id and p.full_name = names.full_name);

insert into public.entries (tournament_id, organization_id, kind, name_vi, name_en)
select t.id, o.id, r.kind, r.entry_name, r.entry_name
from (select distinct sport_slug, tournament_slug, kind, entry_name, organization_code from seed_individual_sports) r
join public.sports s on s.slug = r.sport_slug join public.tournaments t on t.sport_id = s.id and t.slug = r.tournament_slug
join public.organizations o on o.code = r.organization_code
where not exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = r.entry_name);

insert into public.entry_members (entry_id, participant_id, sort_order)
select distinct e.id, p.id, names.sort_order
from seed_individual_sports r join public.sports s on s.slug = r.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = r.tournament_slug
join public.entries e on e.tournament_id = t.id and e.name_vi = r.entry_name
join public.organizations o on o.code = r.organization_code
cross join lateral unnest(string_to_array(r.member_names, E'\\n')) with ordinality names(full_name, sort_order)
join public.participants p on p.organization_id = o.id and p.full_name = names.full_name
on conflict (entry_id, participant_id) do update set archived_at = null;
"""


if __name__ == "__main__":
    print(seed(), end="")
