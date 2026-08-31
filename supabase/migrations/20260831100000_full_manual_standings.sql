set app.tenant_slug = 'petrovietnam2026';

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
  if not (select private.is_admin()) then
    raise exception 'Không có quyền quản trị';
  end if;
  if jsonb_typeof(p_rows) <> 'array' then
    raise exception 'Bảng xếp hạng không hợp lệ';
  end if;

  select * into tournament_row
  from public.tournaments
  where id = p_tournament_id
    and tenant_id = (select private.current_tenant_id())
    and archived_at is null;
  if not found then raise exception 'Không tìm thấy hạng mục'; end if;

  if p_group_id is not null then
    select * into group_row from public.groups
    where id = p_group_id and tournament_id = p_tournament_id and archived_at is null;
    if not found then raise exception 'Không tìm thấy bảng đấu'; end if;
    if group_row.standings_confirmed_at is not null and exists (
      select 1
      from public.fixture_slots slot
      join public.fixtures fixture on fixture.id = slot.fixture_id
      where slot.source_group_id = p_group_id
        and slot.archived_at is null
        and fixture.archived_at is null
        and (fixture.status in ('live', 'completed') or fixture.winner_entry_id is not null or exists (
          select 1 from public.fixture_entries scored
          where scored.fixture_id = fixture.id and scored.archived_at is null
            and (scored.score is not null or scored.score_numeric is not null)
        ))
    ) then
      raise exception 'Vòng sau đã bắt đầu; hãy reset trước khi sửa bảng';
    end if;
  end if;

  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(
      entry_id uuid, played integer, won integer, drawn integer, lost integer,
      score_for numeric, score_against numeric, points numeric, rank integer
    )
    group by entry_id having count(*) > 1
  ) then raise exception 'Đội thi bị trùng'; end if;
  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(
      entry_id uuid, played integer, won integer, drawn integer, lost integer,
      score_for numeric, score_against numeric, points numeric, rank integer
    )
    where row.rank is not null and row.rank <= 0
  ) then raise exception 'Hạng không hợp lệ'; end if;
  if p_group_id is not null and exists (
    select 1 from jsonb_to_recordset(p_rows) as row(
      entry_id uuid, played integer, won integer, drawn integer, lost integer,
      score_for numeric, score_against numeric, points numeric, rank integer
    )
    where row.rank is not null
    group by row.rank having count(*) > 1
  ) then raise exception 'Hạng trong bảng không được trùng'; end if;
  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(
      entry_id uuid, played integer, won integer, drawn integer, lost integer,
      score_for numeric, score_against numeric, points numeric, rank integer
    )
    where coalesce(row.played, 0) < 0 or coalesce(row.won, 0) < 0 or coalesce(row.drawn, 0) < 0 or coalesce(row.lost, 0) < 0
      or coalesce(row.score_for, 0) < 0 or coalesce(row.score_against, 0) < 0 or coalesce(row.points, 0) < 0
  ) then raise exception 'Chỉ số bảng xếp hạng không hợp lệ'; end if;

  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(
      entry_id uuid, played integer, won integer, drawn integer, lost integer,
      score_for numeric, score_against numeric, points numeric, rank integer
    )
    where not exists (
      select 1 from public.entries entry
      where entry.id = row.entry_id
        and entry.tournament_id = p_tournament_id
        and entry.archived_at is null
        and (p_group_id is null or exists (
          select 1 from public.group_entries member
          where member.group_id = p_group_id and member.entry_id = entry.id and member.archived_at is null
        ))
    )
  ) then raise exception 'Đội thi không thuộc hạng mục hoặc bảng'; end if;

  update public.standings existing
  set archived_at = now()
  where existing.tournament_id = p_tournament_id
    and existing.group_id is not distinct from p_group_id
    and existing.archived_at is null
    and not exists (
      select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid) where row.entry_id = existing.entry_id
    );

  for item in select * from jsonb_to_recordset(p_rows) as row(
    entry_id uuid, played integer, won integer, drawn integer, lost integer,
    score_for numeric, score_against numeric, points numeric, rank integer
  )
  loop
    insert into public.standings (
      tenant_id, tournament_id, group_id, entry_id, played, won, drawn, lost,
      score_for, score_against, points, rank, archived_at
    )
    values (
      (select private.current_tenant_id()), p_tournament_id, p_group_id, item.entry_id,
      coalesce(item.played, 0), coalesce(item.won, 0), coalesce(item.drawn, 0), coalesce(item.lost, 0),
      coalesce(item.score_for, 0), coalesce(item.score_against, 0), coalesce(item.points, 0), item.rank, null
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

  if p_group_id is not null then
    update public.groups set standings_confirmed_at = null where id = p_group_id;
  end if;
end;
$$;

revoke execute on function public.save_manual_standings(uuid, uuid, jsonb) from public, anon;
grant execute on function public.save_manual_standings(uuid, uuid, jsonb) to authenticated;
