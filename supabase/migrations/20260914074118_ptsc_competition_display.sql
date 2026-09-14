alter table public.organizations
  add column if not exists short_name text not null default '';

alter table public.organizations
  drop constraint if exists organizations_short_name_length_check;

alter table public.organizations
  add constraint organizations_short_name_length_check check (char_length(short_name) <= 160);

update public.organizations
set short_name = btrim(name_vi)
where tenant_id = '22222222-2222-2222-2222-222222222222'
  and archived_at is null
  and nullif(btrim(short_name), '') is null
  and nullif(btrim(name_vi), '') is not null;

create or replace function private.fill_ptsc_organization_short_name()
returns trigger
language plpgsql
set search_path = public, extensions
as $$
begin
  if new.tenant_id = '22222222-2222-2222-2222-222222222222'
     and nullif(btrim(new.short_name), '') is null then
    new.short_name := coalesce(nullif(btrim(new.name_vi), ''), new.code);
  elsif new.tenant_id = '22222222-2222-2222-2222-222222222222' then
    new.short_name := btrim(new.short_name);
  end if;
  return new;
end;
$$;

drop trigger if exists organizations_fill_ptsc_short_name on public.organizations;
create trigger organizations_fill_ptsc_short_name
before insert or update of tenant_id, code, name_vi, short_name on public.organizations
for each row execute function private.fill_ptsc_organization_short_name();

do $migration$
declare
  v_definition text := pg_get_functiondef('public.get_public_page(text, text)'::regprocedure);
begin
  v_definition := replace(v_definition,
    $old$'id', o.id, 'code', o.code, 'name_vi', o.name_vi$old$,
    $new$'id', o.id, 'code', o.code, 'short_name', o.short_name, 'name_vi', o.name_vi$new$);
  v_definition := replace(v_definition,
    $old$'id', id, 'code', code, 'name_vi', name_vi$old$,
    $new$'id', id, 'code', code, 'short_name', short_name, 'name_vi', name_vi$new$);
  if strpos(v_definition, $marker$'short_name', short_name, 'name_vi', name_vi, 'name_en', name_en, 'logo_path', logo_path, 'sort_order', sort_order, 'leaderboard_rank', leaderboard_rank, 'gold_medals', gold_medals, 'silver_medals', silver_medals, 'bronze_medals', bronze_medals) order by sort_order) from organizations where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'entries'$marker$) = 0 then
    v_definition := replace(v_definition,
      $old$      'entries', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'tournament_id', tournament_id, 'organization_id', organization_id, 'kind', kind, 'name_vi', name_vi, 'name_en', name_en) order by name_vi) from entries where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),$old$,
      $new$      'organizations', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'code', code, 'short_name', short_name, 'name_vi', name_vi, 'name_en', name_en, 'logo_path', logo_path, 'sort_order', sort_order, 'leaderboard_rank', leaderboard_rank, 'gold_medals', gold_medals, 'silver_medals', silver_medals, 'bronze_medals', bronze_medals) order by sort_order) from organizations where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'entries', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'tournament_id', tournament_id, 'organization_id', organization_id, 'kind', kind, 'name_vi', name_vi, 'name_en', name_en) order by name_vi) from entries where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),$new$);
  end if;
  execute v_definition;
end;
$migration$;

do $$
declare
  v_tenant_id uuid := '22222222-2222-2222-2222-222222222222';
  v_tournament_id uuid;
  v_group_id uuid;
  v_fixture_id uuid;
  v_home_entry_id uuid;
  v_away_entry_id uuid;
  v_match record;
begin
  if not exists (
    select 1 from public.tenants
    where id = v_tenant_id and slug = 'ptsc2026' and archived_at is null
  ) then
    raise exception 'PTSC: không tìm thấy tenant';
  end if;

  select id into v_tournament_id
  from public.tournaments
  where tenant_id = v_tenant_id
    and category_code = 'BDNU-DONGDOI'
    and archived_at is null;

  if v_tournament_id is null then
    raise exception 'PTSC: không tìm thấy hạng mục bóng đá nữ';
  end if;

  select id into v_group_id
  from public.groups
  where tenant_id = v_tenant_id
    and tournament_id = v_tournament_id
    and group_code = 'A'
    and archived_at is null;

  if v_group_id is null then
    raise exception 'PTSC: không tìm thấy bảng A bóng đá nữ';
  end if;

  create temporary table ptsc_womens_football_schedule (
    source_code text primary key,
    starts_at timestamptz not null,
    home_slot integer not null,
    away_slot integer not null
  ) on commit drop;

  insert into ptsc_womens_football_schedule (source_code, starts_at, home_slot, away_slot)
  values
    ('BDNU-A-01', '2026-09-17 15:00:00+07', 1, 2),
    ('BDNU-A-02', '2026-09-17 15:00:00+07', 3, 4),
    ('BDNU-A-03', '2026-09-18 15:30:00+07', 1, 3),
    ('BDNU-A-04', '2026-09-18 15:30:00+07', 2, 5),
    ('BDNU-A-05', '2026-09-19 06:30:00+07', 1, 4),
    ('BDNU-A-06', '2026-09-19 06:30:00+07', 3, 5),
    ('BDNU-A-07', '2026-09-19 15:30:00+07', 1, 5),
    ('BDNU-A-08', '2026-09-19 15:30:00+07', 2, 4),
    ('BDNU-A-09', '2026-09-20 06:30:00+07', 2, 3),
    ('BDNU-A-10', '2026-09-20 06:30:00+07', 4, 5);

  for v_match in select * from ptsc_womens_football_schedule order by source_code loop
    select entry_id into v_home_entry_id
    from public.group_entries
    where tenant_id = v_tenant_id
      and group_id = v_group_id
      and slot_no = v_match.home_slot
      and archived_at is null;

    select entry_id into v_away_entry_id
    from public.group_entries
    where tenant_id = v_tenant_id
      and group_id = v_group_id
      and slot_no = v_match.away_slot
      and archived_at is null;

    if v_home_entry_id is null or v_away_entry_id is null then
      raise exception 'PTSC: thiếu đội A% hoặc A% bóng đá nữ', v_match.home_slot, v_match.away_slot;
    end if;

    select id into v_fixture_id
    from public.fixtures
    where tenant_id = v_tenant_id
      and tournament_id = v_tournament_id
      and source_code = v_match.source_code
      and archived_at is null;

    if v_fixture_id is null then
      insert into public.fixtures (
        tenant_id, tournament_id, group_id, starts_at, status,
        round_vi, round_en, round_order, source_code, archived_at
      ) values (
        v_tenant_id, v_tournament_id, v_group_id, v_match.starts_at, 'scheduled',
        'Vòng bảng', 'Group stage', 1, v_match.source_code, null
      ) returning id into v_fixture_id;
    else
      update public.fixtures
      set group_id = v_group_id,
          starts_at = v_match.starts_at,
          status = 'scheduled',
          round_vi = 'Vòng bảng',
          round_en = 'Group stage',
          round_order = 1,
          archived_at = null
      where id = v_fixture_id and tenant_id = v_tenant_id;
    end if;

    insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side, seed_order, archived_at)
    values
      (v_tenant_id, v_fixture_id, v_home_entry_id, 'home', 1, null),
      (v_tenant_id, v_fixture_id, v_away_entry_id, 'away', 2, null)
    on conflict (fixture_id, entry_id) do update set
      side = excluded.side,
      seed_order = excluded.seed_order,
      archived_at = null;

    update public.fixture_entries
    set archived_at = clock_timestamp()
    where tenant_id = v_tenant_id
      and fixture_id = v_fixture_id
      and entry_id not in (v_home_entry_id, v_away_entry_id)
      and archived_at is null;
  end loop;
end;
$$;
