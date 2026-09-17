-- Guarded, repeatable PTSC test-result reset. Deployment only creates the RPC;
-- data changes happen only after an authenticated admin explicitly confirms.
create or replace function public.reset_ptsc_results(p_confirm boolean default false)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  expected_tenant_id constant uuid := '22222222-2222-2222-2222-222222222222';
  v_tenant_id uuid := (select private.current_tenant_id());
  tenant_slug text;
  fixture_count integer;
  entry_count integer;
  standing_count integer;
  group_count integer;
  slot_count integer;
  fixture_row record;
begin
  if p_confirm is distinct from true then
    raise exception 'Cần xác nhận reset kết quả PTSC';
  end if;

  if not (select private.is_admin()) then
    raise exception 'Không có quyền quản trị';
  end if;

  select tenant.slug into tenant_slug
  from public.tenants tenant
  where tenant.id = v_tenant_id
    and tenant.archived_at is null;

  if v_tenant_id is distinct from expected_tenant_id
     or tenant_slug is distinct from 'ptsc2026' then
    raise exception 'Chỉ được reset tenant PTSC';
  end if;

  perform set_config('lock_timeout', '5s', true);
  perform set_config('statement_timeout', '180s', true);
  perform pg_advisory_xact_lock(hashtext('sports-day:ptsc2026:results-reset'));

  lock table public.groups,
             public.fixture_slots,
             public.fixtures,
             public.fixture_entries,
             public.standings
    in share row exclusive mode;

  update public.groups
  set standings_confirmed_at = null
  where groups.tenant_id = v_tenant_id
    and groups.archived_at is null;

  update public.fixture_entries
  set score = null,
      score_numeric = null,
      rank = null,
      result_status = null,
      result_detail = '{}'::jsonb
  where fixture_entries.tenant_id = v_tenant_id
    and fixture_entries.archived_at is null;

  update public.fixtures
  set status = case when status in ('completed', 'live') then 'scheduled' else status end,
      winner_entry_id = null,
      result_summary_vi = '',
      result_summary_en = ''
  where fixtures.tenant_id = v_tenant_id
    and fixtures.archived_at is null;

  update public.standings
  set played = 0,
      won = 0,
      drawn = 0,
      lost = 0,
      score_for = 0,
      score_against = 0,
      points = 0,
      rank = null
  where standings.tenant_id = v_tenant_id
    and standings.archived_at is null;

  for fixture_row in
    select fixtures.id
    from public.fixtures
    where fixtures.tenant_id = v_tenant_id
      and fixtures.archived_at is null
    order by fixtures.id
  loop
    perform private.sync_fixture_slots(fixture_row.id);
  end loop;

  if exists (
    select 1
    from public.fixtures
    where fixtures.tenant_id = v_tenant_id
      and fixtures.archived_at is null
      and (
        fixtures.status in ('live', 'completed')
        or fixtures.winner_entry_id is not null
        or fixtures.result_summary_vi <> ''
        or fixtures.result_summary_en <> ''
      )
  ) then
    raise exception 'Reset PTSC chưa sạch dữ liệu kết quả trận';
  end if;

  if exists (
    select 1
    from public.fixture_entries
    where fixture_entries.tenant_id = v_tenant_id
      and fixture_entries.archived_at is null
      and (
        fixture_entries.score is not null
        or fixture_entries.score_numeric is not null
        or fixture_entries.rank is not null
        or fixture_entries.result_status is not null
        or fixture_entries.result_detail <> '{}'::jsonb
      )
  ) then
    raise exception 'Reset PTSC chưa sạch dữ liệu đội trong trận';
  end if;

  if exists (
    select 1
    from public.standings
    where standings.tenant_id = v_tenant_id
      and standings.archived_at is null
      and (
        standings.played <> 0
        or standings.won <> 0
        or standings.drawn <> 0
        or standings.lost <> 0
        or standings.score_for <> 0
        or standings.score_against <> 0
        or standings.points <> 0
        or standings.rank is not null
      )
  ) then
    raise exception 'Reset PTSC chưa sạch bảng xếp hạng';
  end if;

  select count(*) into fixture_count
  from public.fixtures
  where fixtures.tenant_id = v_tenant_id
    and fixtures.archived_at is null;
  select count(*) into entry_count
  from public.fixture_entries
  where fixture_entries.tenant_id = v_tenant_id
    and fixture_entries.archived_at is null;
  select count(*) into standing_count
  from public.standings
  where standings.tenant_id = v_tenant_id
    and standings.archived_at is null;
  select count(*) into group_count
  from public.groups
  where groups.tenant_id = v_tenant_id
    and groups.archived_at is null
    and groups.standings_confirmed_at is not null;
  select count(*) into slot_count
  from public.fixture_slots
  where fixture_slots.tenant_id = v_tenant_id
    and fixture_slots.archived_at is null;

  return jsonb_build_object(
    'tenant_slug', tenant_slug,
    'tenant_id', v_tenant_id,
    'fixtures', fixture_count,
    'fixture_entries', entry_count,
    'standings', standing_count,
    'confirmed_groups', group_count,
    'fixture_slots', slot_count
  );
end;
$$;

revoke all on function public.reset_ptsc_results(boolean) from public, anon;
grant execute on function public.reset_ptsc_results(boolean) to authenticated;
