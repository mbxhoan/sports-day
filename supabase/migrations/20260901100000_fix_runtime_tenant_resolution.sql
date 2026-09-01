-- Runtime requests use x-tenant-slug; seed_tenant_id is seed-only and not executable by authenticated users.
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
    and tournament.tenant_id = (select private.current_tenant_id())
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

revoke all on function private.recalculate_group_standings(uuid, uuid) from public;
grant execute on function private.recalculate_group_standings(uuid, uuid) to authenticated;
