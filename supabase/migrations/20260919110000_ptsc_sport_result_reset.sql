create or replace function public.reset_sport_results(p_sport_id uuid, p_confirm boolean default false)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  expected_tenant_id constant uuid := '22222222-2222-2222-2222-222222222222';
  v_tenant_id uuid := (select private.current_tenant_id());
  v_tenant_slug text;
  v_sport_slug text;
  fixture_count integer;
  entry_count integer;
  standing_count integer;
  group_count integer;
  fixture_row record;
begin
  if not (select private.is_admin()) then
    raise exception 'Không có quyền quản trị';
  end if;

  select tenant.slug into v_tenant_slug
  from public.tenants tenant
  where tenant.id = v_tenant_id and tenant.archived_at is null;

  if v_tenant_id is distinct from expected_tenant_id or v_tenant_slug is distinct from 'ptsc2026' then
    raise exception 'Chỉ được reset môn thể thao của tenant PTSC';
  end if;

  select sport.slug into v_sport_slug
  from public.sports sport
  where sport.id = p_sport_id
    and sport.tenant_id = v_tenant_id
    and sport.archived_at is null;
  if v_sport_slug is null then
    raise exception 'Môn thể thao không hợp lệ';
  end if;

  if p_confirm is true then
    perform set_config('lock_timeout', '5s', true);
    perform set_config('statement_timeout', '180s', true);
    perform pg_advisory_xact_lock(hashtextextended('sports-day:ptsc2026:result-reset:' || p_sport_id::text, 0));

    perform fixture.id
    from public.fixtures fixture
    join public.tournaments tournament on tournament.id = fixture.tournament_id
    where fixture.tenant_id = v_tenant_id
      and fixture.archived_at is null
      and tournament.tenant_id = v_tenant_id
      and tournament.sport_id = p_sport_id
      and tournament.archived_at is null
    order by fixture.id
    for update of fixture;
  end if;

  select count(*) into fixture_count
  from public.fixtures fixture
  join public.tournaments tournament on tournament.id = fixture.tournament_id
  where fixture.tenant_id = v_tenant_id and fixture.archived_at is null
    and tournament.tenant_id = v_tenant_id and tournament.sport_id = p_sport_id and tournament.archived_at is null;

  select count(*) into entry_count
  from public.fixture_entries item
  join public.fixtures fixture on fixture.id = item.fixture_id
  join public.tournaments tournament on tournament.id = fixture.tournament_id
  where item.tenant_id = v_tenant_id and item.archived_at is null
    and fixture.tenant_id = v_tenant_id and fixture.archived_at is null
    and tournament.tenant_id = v_tenant_id and tournament.sport_id = p_sport_id and tournament.archived_at is null;

  select count(*) into standing_count
  from public.standings standing
  join public.tournaments tournament on tournament.id = standing.tournament_id
  where standing.tenant_id = v_tenant_id and standing.archived_at is null
    and tournament.tenant_id = v_tenant_id and tournament.sport_id = p_sport_id and tournament.archived_at is null;

  select count(*) into group_count
  from public.groups competition_group
  join public.tournaments tournament on tournament.id = competition_group.tournament_id
  where competition_group.tenant_id = v_tenant_id
    and competition_group.archived_at is null
    and competition_group.standings_confirmed_at is not null
    and tournament.tenant_id = v_tenant_id
    and tournament.sport_id = p_sport_id
    and tournament.archived_at is null;

  if p_confirm is distinct from true then
    return jsonb_build_object(
      'tenant_slug', v_tenant_slug,
      'sport_id', p_sport_id,
      'sport_slug', v_sport_slug,
      'fixtures', fixture_count,
      'fixture_entries', entry_count,
      'standings', standing_count,
      'confirmed_groups', group_count
    );
  end if;

  update public.groups competition_group
  set standings_confirmed_at = null
  from public.tournaments tournament
  where competition_group.tournament_id = tournament.id
    and competition_group.tenant_id = v_tenant_id
    and competition_group.archived_at is null
    and tournament.tenant_id = v_tenant_id
    and tournament.sport_id = p_sport_id
    and tournament.archived_at is null;

  update public.fixture_entries item
  set score = null,
      score_numeric = null,
      rank = null,
      result_status = null,
      result_detail = '{}'::jsonb
  from public.fixtures fixture
  join public.tournaments tournament on tournament.id = fixture.tournament_id
  where item.fixture_id = fixture.id
    and item.tenant_id = v_tenant_id
    and item.archived_at is null
    and fixture.tenant_id = v_tenant_id
    and fixture.archived_at is null
    and tournament.tenant_id = v_tenant_id
    and tournament.sport_id = p_sport_id
    and tournament.archived_at is null;

  update public.fixtures fixture
  set status = case when fixture.status in ('completed', 'live') then 'scheduled' else fixture.status end,
      winner_entry_id = null,
      result_summary_vi = '',
      result_summary_en = ''
  from public.tournaments tournament
  where fixture.tournament_id = tournament.id
    and fixture.tenant_id = v_tenant_id
    and fixture.archived_at is null
    and tournament.tenant_id = v_tenant_id
    and tournament.sport_id = p_sport_id
    and tournament.archived_at is null;

  update public.standings standing
  set played = 0,
      won = 0,
      drawn = 0,
      lost = 0,
      score_for = 0,
      score_against = 0,
      points = 0,
      rank = null
  from public.tournaments tournament
  where standing.tournament_id = tournament.id
    and standing.tenant_id = v_tenant_id
    and standing.archived_at is null
    and tournament.tenant_id = v_tenant_id
    and tournament.sport_id = p_sport_id
    and tournament.archived_at is null;

  for fixture_row in
    select fixture.id
    from public.fixtures fixture
    join public.tournaments tournament on tournament.id = fixture.tournament_id
    where fixture.tenant_id = v_tenant_id
      and fixture.archived_at is null
      and tournament.tenant_id = v_tenant_id
      and tournament.sport_id = p_sport_id
      and tournament.archived_at is null
    order by fixture.id
  loop
    perform private.sync_fixture_slots(fixture_row.id);
  end loop;

  if exists (
    select 1
    from public.fixtures fixture
    join public.tournaments tournament on tournament.id = fixture.tournament_id
    where fixture.tenant_id = v_tenant_id
      and fixture.archived_at is null
      and tournament.tenant_id = v_tenant_id
      and tournament.sport_id = p_sport_id
      and tournament.archived_at is null
      and (fixture.status in ('live', 'completed') or fixture.winner_entry_id is not null or fixture.result_summary_vi <> '' or fixture.result_summary_en <> '')
  ) then
    raise exception 'Reset môn chưa sạch dữ liệu kết quả trận';
  end if;

  if exists (
    select 1
    from public.fixture_entries item
    join public.fixtures fixture on fixture.id = item.fixture_id
    join public.tournaments tournament on tournament.id = fixture.tournament_id
    where item.tenant_id = v_tenant_id
      and item.archived_at is null
      and fixture.tenant_id = v_tenant_id
      and fixture.archived_at is null
      and tournament.tenant_id = v_tenant_id
      and tournament.sport_id = p_sport_id
      and tournament.archived_at is null
      and (item.score is not null or item.score_numeric is not null or item.rank is not null or item.result_status is not null or item.result_detail <> '{}'::jsonb)
  ) then
    raise exception 'Reset môn chưa sạch dữ liệu đội trong trận';
  end if;

  if exists (
    select 1
    from public.standings standing
    join public.tournaments tournament on tournament.id = standing.tournament_id
    where standing.tenant_id = v_tenant_id
      and standing.archived_at is null
      and tournament.tenant_id = v_tenant_id
      and tournament.sport_id = p_sport_id
      and tournament.archived_at is null
      and (standing.played <> 0 or standing.won <> 0 or standing.drawn <> 0 or standing.lost <> 0 or standing.score_for <> 0 or standing.score_against <> 0 or standing.points <> 0 or standing.rank is not null)
  ) then
    raise exception 'Reset môn chưa sạch bảng xếp hạng';
  end if;

  if exists (
    select 1
    from public.groups competition_group
    join public.tournaments tournament on tournament.id = competition_group.tournament_id
    where competition_group.tenant_id = v_tenant_id
      and competition_group.archived_at is null
      and competition_group.standings_confirmed_at is not null
      and tournament.tenant_id = v_tenant_id
      and tournament.sport_id = p_sport_id
      and tournament.archived_at is null
  ) then
    raise exception 'Reset môn chưa xóa xác nhận bảng';
  end if;

  return jsonb_build_object(
    'tenant_slug', v_tenant_slug,
    'sport_id', p_sport_id,
    'sport_slug', v_sport_slug,
    'fixtures', fixture_count,
    'fixture_entries', entry_count,
    'standings', standing_count,
    'confirmed_groups', group_count
  );
end;
$$;

revoke all on function public.reset_sport_results(uuid, boolean) from public, anon;
grant execute on function public.reset_sport_results(uuid, boolean) to authenticated;
