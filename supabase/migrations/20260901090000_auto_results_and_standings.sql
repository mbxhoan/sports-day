set app.tenant_slug = 'petrovietnam2026';

create or replace function private.validate_fixture_result()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  fixture_mode text;
  sport_slug text;
  first_entry uuid;
  second_entry uuid;
  first_score numeric;
  second_score numeric;
begin
  if new.status <> 'completed' then
    new.winner_entry_id := null;
    return new;
  end if;

  select tournament.competition_mode, sport.slug
  into fixture_mode, sport_slug
  from public.tournaments tournament
  join public.sports sport on sport.id = tournament.sport_id
  where tournament.id = new.tournament_id;

  select home.entry_id, away.entry_id, home.score_numeric, away.score_numeric
  into first_entry, second_entry, first_score, second_score
  from public.fixture_entries home
  join public.fixture_entries away on away.fixture_id = home.fixture_id
    and away.side = 'away' and away.archived_at is null
  where home.fixture_id = new.id
    and home.side = 'home'
    and home.archived_at is null;

  if first_entry is null or second_entry is null or first_entry = second_entry then
    raise exception 'Trận hoàn tất phải có đúng hai đội khác nhau';
  end if;
  if first_score is null or second_score is null then
    raise exception 'Trận hoàn tất phải có đủ hai tỷ số';
  end if;
  if first_score::text in ('NaN', 'Infinity', '-Infinity') or second_score::text in ('NaN', 'Infinity', '-Infinity') then
    raise exception 'Tỷ số không hợp lệ';
  end if;

  if sport_slug = 'keo-co' then
    if new.winner_entry_id is null or new.winner_entry_id not in (first_entry, second_entry) then
      raise exception 'Kéo co phải chọn đúng một đội thắng trong trận';
    end if;
    return new;
  end if;

  if first_score = second_score then
    if fixture_mode in ('knockout', 'group_knockout') and new.group_id is null then
      raise exception 'Vòng loại trực tiếp không được hòa; hãy nhập tỷ số phân định';
    end if;
    new.winner_entry_id := null;
  else
    new.winner_entry_id := case when first_score > second_score then first_entry else second_entry end;
  end if;
  return new;
end;
$$;

create or replace function private.recalculate_group_standings(p_tournament_id uuid, p_group_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  tournament_row public.tournaments%rowtype;
  rule_type text;
  win_points numeric;
  draw_points numeric;
  loss_points numeric;
begin
  select * into tournament_row
  from public.tournaments tournament
  where tournament.id = p_tournament_id
    and tournament.tenant_id = coalesce((select private.current_tenant_id()), (select private.seed_tenant_id()))
    and tournament.archived_at is null;
  if not found then return; end if;

  if (p_group_id is null and tournament_row.competition_mode <> 'swiss')
    or (p_group_id is not null and tournament_row.competition_mode not in ('round_robin', 'group_knockout')) then
    return;
  end if;

  rule_type := tournament_row.scoring_rule->>'type';
  if rule_type is distinct from 'head-to-head' then return; end if;
  if not (coalesce(tournament_row.scoring_rule->>'win', '') ~ '^[0-9]+(\.[0-9]+)?$')
    or not (coalesce(tournament_row.scoring_rule->>'draw', '') ~ '^[0-9]+(\.[0-9]+)?$')
    or not (coalesce(tournament_row.scoring_rule->>'loss', '') ~ '^[0-9]+(\.[0-9]+)?$') then
    raise exception 'Quy tắc điểm head-to-head không hợp lệ';
  end if;
  win_points := (tournament_row.scoring_rule->>'win')::numeric;
  draw_points := (tournament_row.scoring_rule->>'draw')::numeric;
  loss_points := (tournament_row.scoring_rule->>'loss')::numeric;

  update public.standings standing
  set rank = null
  where standing.tournament_id = p_tournament_id
    and standing.group_id is not distinct from p_group_id
    and standing.archived_at is null;

  update public.standings standing
  set archived_at = now()
  where standing.tournament_id = p_tournament_id
    and standing.group_id is not distinct from p_group_id
    and standing.archived_at is null
    and not exists (
      select 1
      from public.group_entries member
      where p_group_id is not null
        and member.group_id = p_group_id
        and member.entry_id = standing.entry_id
        and member.archived_at is null
    )
    and p_group_id is not null;

  with base as (
    select member.entry_id
    from public.group_entries member
    join public.entries entry on entry.id = member.entry_id
    where p_group_id is not null
      and member.group_id = p_group_id
      and member.archived_at is null
      and entry.archived_at is null
    union
    select entry.id
    from public.entries entry
    where p_group_id is null
      and entry.tournament_id = p_tournament_id
      and entry.archived_at is null
  ), match_scores as (
    select fixture.id,
      home.entry_id as home_id, away.entry_id as away_id,
      home.score_numeric as home_score, away.score_numeric as away_score
    from public.fixtures fixture
    join public.fixture_entries home on home.fixture_id = fixture.id and home.side = 'home' and home.archived_at is null
    join public.fixture_entries away on away.fixture_id = fixture.id and away.side = 'away' and away.archived_at is null
    where fixture.tournament_id = p_tournament_id
      and fixture.group_id is not distinct from p_group_id
      and fixture.status = 'completed'
      and fixture.archived_at is null
  ), contributions as (
    select home_id as entry_id, 1 as played,
      case when home_score > away_score then 1 else 0 end as won,
      case when home_score = away_score then 1 else 0 end as drawn,
      case when home_score < away_score then 1 else 0 end as lost,
      home_score as score_for, away_score as score_against,
      case when home_score > away_score then win_points when home_score = away_score then draw_points else loss_points end as points
    from match_scores
    where home_score is not null and away_score is not null
    union all
    select away_id as entry_id, 1,
      case when away_score > home_score then 1 else 0 end,
      case when away_score = home_score then 1 else 0 end,
      case when away_score < home_score then 1 else 0 end,
      away_score, home_score,
      case when away_score > home_score then win_points when away_score = home_score then draw_points else loss_points end
    from match_scores
    where home_score is not null and away_score is not null
  ), totals as (
    select base.entry_id,
      coalesce(sum(contribution.played), 0)::integer as played,
      coalesce(sum(contribution.won), 0)::integer as won,
      coalesce(sum(contribution.drawn), 0)::integer as drawn,
      coalesce(sum(contribution.lost), 0)::integer as lost,
      coalesce(sum(contribution.score_for), 0)::numeric as score_for,
      coalesce(sum(contribution.score_against), 0)::numeric as score_against,
      coalesce(sum(contribution.points), 0)::numeric as points
    from base
    left join contributions contribution on contribution.entry_id = base.entry_id
    group by base.entry_id
  ), ranked as (
    select totals.*,
      row_number() over (order by totals.points desc, (totals.score_for - totals.score_against) desc, totals.score_for desc, totals.entry_id) as rank
    from totals
  )
  insert into public.standings (
    tenant_id, tournament_id, group_id, entry_id, played, won, drawn, lost,
    score_for, score_against, points, rank, archived_at
  )
  select tournament_row.tenant_id, p_tournament_id, p_group_id, ranked.entry_id,
    ranked.played, ranked.won, ranked.drawn, ranked.lost,
    ranked.score_for, ranked.score_against, ranked.points, ranked.rank, null
  from ranked
  on conflict (tournament_id, group_id, entry_id) do update set
    played = excluded.played,
    won = excluded.won,
    drawn = excluded.drawn,
    lost = excluded.lost,
    score_for = excluded.score_for,
    score_against = excluded.score_against,
    points = excluded.points,
    rank = excluded.rank,
    archived_at = null;

  if p_group_id is not null then
    perform private.sync_group_standings(p_group_id);
  end if;
end;
$$;

create or replace function private.recalculate_fixture_standings()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  perform private.recalculate_group_standings(new.tournament_id, new.group_id);
  return new;
end;
$$;

create or replace function private.validate_standing_rank()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.archived_at is not null or new.rank is null then return new; end if;
  if new.rank < 1 then raise exception 'Hạng không hợp lệ'; end if;
  if exists (
    select 1
    from public.standings other
    where other.tournament_id = new.tournament_id
      and other.group_id is not distinct from new.group_id
      and other.rank = new.rank
      and other.archived_at is null
      and other.id is distinct from new.id
  ) then
    raise exception 'Hạng trong bảng không được trùng';
  end if;
  return new;
end;
$$;

drop trigger if exists fixtures_recalculate_standings on public.fixtures;
create trigger fixtures_recalculate_standings
  after update of status, winner_entry_id on public.fixtures
  for each row execute function private.recalculate_fixture_standings();

drop trigger if exists standings_rank_unique on public.standings;
create trigger standings_rank_unique
  before insert or update of rank, archived_at on public.standings
  for each row execute function private.validate_standing_rank();

update public.tournaments
set scoring_rule = case
  when competition_mode = 'swiss' then '{"type":"head-to-head","win":1,"draw":0.5,"loss":0}'::jsonb
  else '{"type":"head-to-head","win":3,"draw":1,"loss":0}'::jsonb
end
where tenant_id = (select private.seed_tenant_id())
  and scoring_rule = '{}'::jsonb
  and competition_mode in ('round_robin', 'group_knockout', 'swiss');

do $$
declare
  item record;
begin
  for item in
    select tournament.id as tournament_id, group_row.id as group_id
    from public.tournaments tournament
    join public.groups group_row on group_row.tournament_id = tournament.id and group_row.archived_at is null
    where tournament.tenant_id = (select private.seed_tenant_id())
      and tournament.competition_mode in ('round_robin', 'group_knockout')
      and tournament.archived_at is null
  loop
    perform private.recalculate_group_standings(item.tournament_id, item.group_id);
  end loop;
end;
$$;

-- Keep manual/race imports safe when ranks are swapped in one request.
create or replace function public.save_manual_standings(
  p_tournament_id uuid,
  p_group_id uuid,
  p_rows jsonb
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  tournament_row public.tournaments%rowtype;
  group_row public.groups%rowtype;
  item record;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  if jsonb_typeof(p_rows) is distinct from 'array' then raise exception 'Bảng xếp hạng không hợp lệ'; end if;

  select * into tournament_row from public.tournaments
  where id = p_tournament_id and tenant_id = (select private.current_tenant_id()) and archived_at is null;
  if not found then raise exception 'Không tìm thấy hạng mục'; end if;

  if p_group_id is not null then
    select * into group_row from public.groups
    where id = p_group_id and tournament_id = p_tournament_id and archived_at is null;
    if not found then raise exception 'Không tìm thấy bảng đấu'; end if;
    if group_row.standings_confirmed_at is not null and exists (
      select 1 from public.fixture_slots slot join public.fixtures fixture on fixture.id = slot.fixture_id
      where slot.source_group_id = p_group_id and slot.archived_at is null and fixture.archived_at is null
        and (fixture.status in ('live', 'completed') or fixture.winner_entry_id is not null or exists (
          select 1 from public.fixture_entries scored
          where scored.fixture_id = fixture.id and scored.archived_at is null
            and (scored.score is not null or scored.score_numeric is not null)
        ))
    ) then raise exception 'Vòng sau đã bắt đầu; hãy reset trước khi sửa bảng'; end if;
  end if;

  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, played integer, won integer, drawn integer, lost integer, score_for numeric, score_against numeric, points numeric, rank integer)
    group by entry_id having count(*) > 1
  ) then raise exception 'Đội thi bị trùng'; end if;
  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, played integer, won integer, drawn integer, lost integer, score_for numeric, score_against numeric, points numeric, rank integer)
    where row.rank is not null and row.rank <= 0
  ) then raise exception 'Hạng không hợp lệ'; end if;
  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, played integer, won integer, drawn integer, lost integer, score_for numeric, score_against numeric, points numeric, rank integer)
    where row.rank is not null group by row.rank having count(*) > 1
  ) then raise exception 'Hạng trong bảng không được trùng'; end if;
  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, played integer, won integer, drawn integer, lost integer, score_for numeric, score_against numeric, points numeric, rank integer)
    where coalesce(row.played, 0) < 0 or coalesce(row.won, 0) < 0 or coalesce(row.drawn, 0) < 0 or coalesce(row.lost, 0) < 0
      or coalesce(row.score_for, 0) < 0 or coalesce(row.score_against, 0) < 0 or coalesce(row.points, 0) < 0
      or coalesce(row.score_for, 0) in ('NaN'::numeric, 'Infinity'::numeric, '-Infinity'::numeric)
      or coalesce(row.score_against, 0) in ('NaN'::numeric, 'Infinity'::numeric, '-Infinity'::numeric)
      or coalesce(row.points, 0) in ('NaN'::numeric, 'Infinity'::numeric, '-Infinity'::numeric)
  ) then raise exception 'Chỉ số bảng xếp hạng không hợp lệ'; end if;
  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, played integer, won integer, drawn integer, lost integer, score_for numeric, score_against numeric, points numeric, rank integer)
    where not exists (
      select 1 from public.entries entry
      where entry.id = row.entry_id and entry.tournament_id = p_tournament_id and entry.archived_at is null
        and (p_group_id is null or exists (select 1 from public.group_entries member where member.group_id = p_group_id and member.entry_id = entry.id and member.archived_at is null))
    )
  ) then raise exception 'Đội thi không thuộc hạng mục hoặc bảng'; end if;

  -- Clear first so swapping existing ranks cannot fail on the row-level guard.
  update public.standings existing set rank = null
  where existing.tournament_id = p_tournament_id and existing.group_id is not distinct from p_group_id and existing.archived_at is null;
  update public.standings existing set archived_at = now()
  where existing.tournament_id = p_tournament_id and existing.group_id is not distinct from p_group_id and existing.archived_at is null
    and not exists (select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid) where row.entry_id = existing.entry_id);

  for item in select * from jsonb_to_recordset(p_rows) as row(entry_id uuid, played integer, won integer, drawn integer, lost integer, score_for numeric, score_against numeric, points numeric, rank integer)
  loop
    insert into public.standings (tenant_id, tournament_id, group_id, entry_id, played, won, drawn, lost, score_for, score_against, points, rank, archived_at)
    values ((select private.current_tenant_id()), p_tournament_id, p_group_id, item.entry_id,
      coalesce(item.played, 0), coalesce(item.won, 0), coalesce(item.drawn, 0), coalesce(item.lost, 0),
      coalesce(item.score_for, 0), coalesce(item.score_against, 0), coalesce(item.points, 0), item.rank, null)
    on conflict (tournament_id, group_id, entry_id) do update set
      played = excluded.played, won = excluded.won, drawn = excluded.drawn, lost = excluded.lost,
      score_for = excluded.score_for, score_against = excluded.score_against, points = excluded.points,
      rank = excluded.rank, archived_at = null;
  end loop;
  if p_group_id is not null then update public.groups set standings_confirmed_at = null where id = p_group_id; end if;
end;
$$;

revoke execute on function public.save_manual_standings(uuid, uuid, jsonb) from public, anon;
grant execute on function public.save_manual_standings(uuid, uuid, jsonb) to authenticated;
