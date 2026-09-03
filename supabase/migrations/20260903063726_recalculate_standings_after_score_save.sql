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
    if first_score = second_score then
      raise exception 'Kéo co không được hòa; hãy nhập tỷ số phân định';
    end if;
    if new.winner_entry_id is distinct from (case when first_score > second_score then first_entry else second_entry end) then
      raise exception 'Đội thắng phải khớp với tỷ số';
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

create or replace function private.recalculate_tournament_standings()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  group_row record;
begin
  if new.scoring_rule is not distinct from old.scoring_rule then return new; end if;
  if new.competition_mode = 'swiss' then
    perform private.recalculate_group_standings(new.id, null);
  elsif new.competition_mode in ('round_robin', 'group_knockout') then
    for group_row in select id from public.groups where tournament_id = new.id and archived_at is null loop
      perform private.recalculate_group_standings(new.id, group_row.id);
    end loop;
  end if;
  return new;
end;
$$;

revoke all on function private.recalculate_tournament_standings() from public;

drop trigger if exists tournaments_recalculate_standings on public.tournaments;
create trigger tournaments_recalculate_standings
  after update of scoring_rule on public.tournaments
  for each row execute function private.recalculate_tournament_standings();

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

  perform dependent.id
  from public.fixtures dependent
  where dependent.id in (
    with recursive downstream(id) as (
      select slot.fixture_id
      from public.fixture_slots slot
      where slot.archived_at is null
        and (slot.source_fixture_id = p_fixture_id or (fixture_row.group_id is not null and slot.source_group_id = fixture_row.group_id))
      union
      select slot.fixture_id
      from public.fixture_slots slot
      join downstream on slot.source_fixture_id = downstream.id
      where slot.archived_at is null
    )
    select id from downstream
  )
  for update;

  if (
    fixture_row.status is distinct from p_status or
    fixture_row.winner_entry_id is distinct from p_winner_entry_id or
    p_standings is not null
  ) and exists (
    with recursive downstream(id) as (
      select slot.fixture_id
      from public.fixture_slots slot
      where slot.archived_at is null
        and (slot.source_fixture_id = p_fixture_id or (fixture_row.group_id is not null and slot.source_group_id = fixture_row.group_id))
      union
      select slot.fixture_id
      from public.fixture_slots slot
      join downstream on slot.source_fixture_id = downstream.id
      where slot.archived_at is null
    )
    select 1
    from downstream
    join public.fixtures dependent on dependent.id = downstream.id
    where dependent.archived_at is null
      and (
        dependent.status in ('live', 'completed') or
        dependent.winner_entry_id is not null or
        exists (
          select 1 from public.fixture_entries scored
          where scored.fixture_id = dependent.id
            and scored.archived_at is null
            and (scored.score is not null or scored.score_numeric is not null or scored.rank is not null or scored.result_status is not null)
        )
      )
  ) then
    raise exception 'Trận phụ thuộc đã có kết quả; hãy xem trước và xác nhận đặt lại';
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
      result_status text,
      result_detail jsonb
    )
  loop
    if entry_row.side is not null and entry_row.side not in ('home', 'away') then
      raise exception 'Bên thi đấu không hợp lệ';
    end if;

    if entry_row.result_status is not null and entry_row.result_status not in ('finished', 'dns', 'dnf', 'dsq') then
      raise exception 'Trạng thái kết quả không hợp lệ';
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

  insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side, lane, score, score_numeric, rank, result_status, result_detail, archived_at)
  select fixture_row.tenant_id, p_fixture_id, item.entry_id, item.side, item.lane, item.score, item.score_numeric, item.rank, item.result_status, coalesce(item.result_detail, '{}'::jsonb), null
  from jsonb_to_recordset(p_entries) as item(
    entry_id uuid,
    side text,
    lane integer,
    score text,
    score_numeric numeric,
    rank integer,
    result_status text,
    result_detail jsonb
  )
  on conflict (fixture_id, entry_id) do update set
    side = excluded.side,
    lane = excluded.lane,
    score = excluded.score,
    score_numeric = excluded.score_numeric,
    rank = excluded.rank,
    result_status = excluded.result_status,
    result_detail = excluded.result_detail,
    archived_at = null;

  update public.fixtures
  set status = p_status,
      winner_entry_id = p_winner_entry_id,
      result_summary_vi = coalesce(p_result_summary_vi, ''),
      result_summary_en = coalesce(p_result_summary_en, '')
  where id = p_fixture_id;

  if p_standings is not null then
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
        tenant_id, tournament_id, group_id, entry_id, played, won, drawn, lost,
        score_for, score_against, points, rank, archived_at
      ) values (
        fixture_row.tenant_id, fixture_row.tournament_id, fixture_row.group_id, standing_row.entry_id,
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
  end if;

  if p_standings is null then
    perform private.recalculate_group_standings(fixture_row.tournament_id, fixture_row.group_id);
  end if;
  perform private.sync_fixture_slots(p_fixture_id);
end;
$$;

revoke execute on function public.save_fixture_result(uuid, text, uuid, text, text, jsonb, jsonb) from public, anon;
grant execute on function public.save_fixture_result(uuid, text, uuid, text, text, jsonb, jsonb) to authenticated;
