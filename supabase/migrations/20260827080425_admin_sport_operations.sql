alter table public.event_settings
  add column hero_mobile_path text not null default '/kv-mobile.png';

alter table public.media
  add column sport_id uuid references public.sports(id),
  add column album_vi text not null default '',
  add column album_en text not null default '';

alter table public.tournaments
  add column scoring_rule jsonb not null default '{}'::jsonb,
  add constraint tournaments_scoring_rule_object check (jsonb_typeof(scoring_rule) = 'object');

alter table public.standings
  drop constraint standings_tournament_id_group_id_entry_id_key,
  add constraint standings_tournament_group_entry_key unique nulls not distinct (tournament_id, group_id, entry_id);

create index media_sport_album_active_idx
  on public.media (sport_id, album_vi, sort_order)
  where archived_at is null;

create or replace function public.save_fixture_result(
  p_fixture_id uuid,
  p_status text,
  p_winner_entry_id uuid,
  p_result_summary_vi text,
  p_result_summary_en text,
  p_entries jsonb,
  p_standings jsonb default null
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  fixture_row public.fixtures%rowtype;
  entry_row record;
  standing_row record;
begin
  if not (select private.is_admin()) then
    raise exception 'Không có quyền quản trị';
  end if;

  if p_status not in ('scheduled', 'live', 'completed', 'postponed', 'cancelled') then
    raise exception 'Trạng thái trận đấu không hợp lệ';
  end if;

  if jsonb_typeof(p_entries) <> 'array' or jsonb_array_length(p_entries) = 0 then
    raise exception 'Danh sách đội thi không hợp lệ';
  end if;

  select * into fixture_row
  from public.fixtures
  where id = p_fixture_id and archived_at is null
  for update;

  if not found then
    raise exception 'Không tìm thấy trận đấu';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_entries) as item(entry_id uuid, side text)
    group by entry_id
    having count(*) > 1
  ) then
    raise exception 'Đội thi bị trùng';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_entries) as item(entry_id uuid, side text)
    where side is not null
    group by side
    having count(*) > 1
  ) then
    raise exception 'Vị trí thi đấu bị trùng';
  end if;

  for entry_row in
    select *
    from jsonb_to_recordset(p_entries) as item(
      entry_id uuid,
      side text,
      lane integer,
      score text,
      score_numeric numeric,
      rank integer,
      result_detail jsonb
    )
  loop
    if entry_row.side is not null and entry_row.side not in ('home', 'away') then
      raise exception 'Bên thi đấu không hợp lệ';
    end if;

    if not exists (
      select 1 from public.entries
      where id = entry_row.entry_id
        and tournament_id = fixture_row.tournament_id
        and archived_at is null
    ) then
      raise exception 'Đội thi không thuộc hạng mục';
    end if;
  end loop;

  if p_winner_entry_id is not null and not exists (
    select 1 from jsonb_to_recordset(p_entries) as item(entry_id uuid)
    where item.entry_id = p_winner_entry_id
  ) then
    raise exception 'Đội thắng không thuộc trận đấu';
  end if;

  update public.fixture_entries existing
  set archived_at = now()
  where existing.fixture_id = p_fixture_id
    and existing.archived_at is null
    and not exists (
      select 1 from jsonb_to_recordset(p_entries) as item(entry_id uuid)
      where item.entry_id = existing.entry_id
    );

  insert into public.fixture_entries (fixture_id, entry_id, side, lane, score, score_numeric, rank, result_detail, archived_at)
  select p_fixture_id, item.entry_id, item.side, item.lane, item.score, item.score_numeric, item.rank, coalesce(item.result_detail, '{}'::jsonb), null
  from jsonb_to_recordset(p_entries) as item(
    entry_id uuid,
    side text,
    lane integer,
    score text,
    score_numeric numeric,
    rank integer,
    result_detail jsonb
  )
  on conflict (fixture_id, entry_id) do update set
    side = excluded.side,
    lane = excluded.lane,
    score = excluded.score,
    score_numeric = excluded.score_numeric,
    rank = excluded.rank,
    result_detail = excluded.result_detail,
    archived_at = null;

  update public.fixtures
  set status = p_status,
      winner_entry_id = p_winner_entry_id,
      result_summary_vi = coalesce(p_result_summary_vi, ''),
      result_summary_en = coalesce(p_result_summary_en, '')
  where id = p_fixture_id;

  if p_standings is null then
    return;
  end if;

  if jsonb_typeof(p_standings) <> 'array' then
    raise exception 'Bảng xếp hạng không hợp lệ';
  end if;

  update public.standings existing
  set archived_at = now()
  where existing.tournament_id = fixture_row.tournament_id
    and existing.group_id is not distinct from fixture_row.group_id
    and existing.archived_at is null
    and not exists (
      select 1 from jsonb_to_recordset(p_standings) as item(entry_id uuid)
      where item.entry_id = existing.entry_id
    );

  for standing_row in
    select *
    from jsonb_to_recordset(p_standings) as item(
      entry_id uuid,
      played integer,
      won integer,
      drawn integer,
      lost integer,
      score_for numeric,
      score_against numeric,
      points numeric,
      rank integer
    )
  loop
    if not exists (
      select 1 from public.entries
      where id = standing_row.entry_id
        and tournament_id = fixture_row.tournament_id
        and archived_at is null
    ) then
      raise exception 'Đội xếp hạng không thuộc hạng mục';
    end if;

    insert into public.standings (
      tournament_id, group_id, entry_id, played, won, drawn, lost,
      score_for, score_against, points, rank, archived_at
    ) values (
      fixture_row.tournament_id, fixture_row.group_id, standing_row.entry_id,
      greatest(coalesce(standing_row.played, 0), 0),
      greatest(coalesce(standing_row.won, 0), 0),
      greatest(coalesce(standing_row.drawn, 0), 0),
      greatest(coalesce(standing_row.lost, 0), 0),
      coalesce(standing_row.score_for, 0), coalesce(standing_row.score_against, 0),
      coalesce(standing_row.points, 0), standing_row.rank, null
    )
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
  end loop;
end;
$$;

revoke execute on function public.save_fixture_result(uuid, text, uuid, text, text, jsonb, jsonb) from public, anon;
grant execute on function public.save_fixture_result(uuid, text, uuid, text, text, jsonb, jsonb) to authenticated;
