-- Keep the reviewed workbook fixtures for Pickleball men 31-40, group D.
-- The older PDF import left duplicate group-stage fixtures beside D-01..D-03.
create or replace function private.archive_legacy_pickleball_group_d_fixtures(p_tenant_id uuid)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
  tournament_row record;
  legacy_fixture_ids uuid[];
begin
  for tournament_row in
    select tournament.id as tournament_id, group_row.id as group_id
    from public.tournaments tournament
    join public.sports sport on sport.id = tournament.sport_id
    join public.groups group_row on group_row.tournament_id = tournament.id
      and group_row.name_vi = 'Bảng D'
      and group_row.archived_at is null
    where tournament.tenant_id = p_tenant_id
      and sport.slug = 'pickleball'
      and tournament.slug = 'doi-nam-31-40'
      and tournament.archived_at is null
  loop
    select array_agg(fixture.id)
    into legacy_fixture_ids
    from public.fixtures fixture
    where fixture.tenant_id = p_tenant_id
      and fixture.tournament_id = tournament_row.tournament_id
      and fixture.group_id = tournament_row.group_id
      and fixture.source_code is null
      and fixture.round_order between 10 and 12
      and exists (
        select 1
        from public.fixture_entries item
        join public.entries entry on entry.id = item.entry_id
        where item.fixture_id = fixture.id
          and item.archived_at is null
          and entry.archived_at is null
          and entry.name_vi = 'Đinh Viết Long / Phạm Ngọc Hải - PV DRILLING'
      )
      and exists (
        select 1
        from public.fixture_entries item
        join public.entries entry on entry.id = item.entry_id
        where item.fixture_id = fixture.id
          and item.archived_at is null
          and entry.archived_at is null
          and entry.name_vi = 'Nguyễn Bình Phương / Nguyễn Ngọc Thành - PQPOC'
      );

    if legacy_fixture_ids is not null then
      update public.fixture_slots
      set archived_at = coalesce(archived_at, now())
      where tenant_id = p_tenant_id
        and fixture_id = any(legacy_fixture_ids)
        and archived_at is null;

      update public.fixture_entries
      set archived_at = coalesce(archived_at, now())
      where tenant_id = p_tenant_id
        and fixture_id = any(legacy_fixture_ids)
        and archived_at is null;

      update public.fixtures
      set archived_at = coalesce(archived_at, now())
      where tenant_id = p_tenant_id
        and id = any(legacy_fixture_ids)
        and archived_at is null;
    end if;

    -- A scheduled fixture must not retain a result from an earlier import.
    update public.fixture_entries item
    set score = null,
        score_numeric = null,
        rank = null,
        result_status = null,
        result_detail = '{}'::jsonb
    from public.fixtures fixture
    where item.fixture_id = fixture.id
      and item.tenant_id = p_tenant_id
      and item.archived_at is null
      and fixture.tenant_id = p_tenant_id
      and fixture.tournament_id = tournament_row.tournament_id
      and fixture.group_id = tournament_row.group_id
      and fixture.status = 'scheduled'
      and fixture.source_code in (
        'UPD-DOI-NAM-31-40-BANG-D-02',
        'UPD-DOI-NAM-31-40-BANG-D-03'
      );

    update public.fixtures
    set winner_entry_id = null,
        result_summary_vi = '',
        result_summary_en = ''
    where tenant_id = p_tenant_id
      and tournament_id = tournament_row.tournament_id
      and group_id = tournament_row.group_id
      and status = 'scheduled'
      and source_code in (
        'UPD-DOI-NAM-31-40-BANG-D-02',
        'UPD-DOI-NAM-31-40-BANG-D-03'
      );

    perform private.recalculate_group_standings(tournament_row.tournament_id, tournament_row.group_id);
  end loop;
end
$$;

revoke all on function private.archive_legacy_pickleball_group_d_fixtures(uuid) from public;

do $$
declare
  tenant record;
begin
  for tenant in select id from public.tenants loop
    perform private.archive_legacy_pickleball_group_d_fixtures(tenant.id);
  end loop;
end
$$;
