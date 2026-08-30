alter table public.event_settings
  add column gallery_drive_url text not null default '';

alter table public.organizations
  add column leaderboard_rank integer,
  add column gold_medals integer not null default 0,
  add column silver_medals integer not null default 0,
  add column bronze_medals integer not null default 0,
  add constraint organizations_leaderboard_rank_positive check (leaderboard_rank is null or leaderboard_rank > 0),
  add constraint organizations_gold_medals_nonnegative check (gold_medals >= 0),
  add constraint organizations_silver_medals_nonnegative check (silver_medals >= 0),
  add constraint organizations_bronze_medals_nonnegative check (bronze_medals >= 0);

update public.organizations organization
set gold_medals = coalesce((select count(*) from public.awards award where award.organization_id = organization.id and award.medal = 'gold' and award.archived_at is null), 0),
    silver_medals = coalesce((select count(*) from public.awards award where award.organization_id = organization.id and award.medal = 'silver' and award.archived_at is null), 0),
    bronze_medals = coalesce((select count(*) from public.awards award where award.organization_id = organization.id and award.medal = 'bronze' and award.archived_at is null), 0)
where organization.archived_at is null;

create unique index organizations_leaderboard_rank_key
  on public.organizations (tenant_id, leaderboard_rank)
  where leaderboard_rank is not null and archived_at is null;

alter table public.groups
  add column standings_confirmed_at timestamptz;

create unique index standings_group_rank_key
  on public.standings (group_id, rank)
  where group_id is not null and rank is not null and archived_at is null;

create or replace function private.validate_fixture_result()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  first_entry uuid;
  second_entry uuid;
  first_score numeric;
  second_score numeric;
begin
  if new.status = 'completed' and new.winner_entry_id is null then
    raise exception 'Trận hoàn tất phải có đúng một đội thắng';
  end if;

  if new.status <> 'completed' and new.winner_entry_id is not null then
    raise exception 'Trận chưa hoàn tất không được có đội thắng';
  end if;

  if new.winner_entry_id is not null and not exists (
    select 1 from public.fixture_entries item
    where item.fixture_id = new.id
      and item.entry_id = new.winner_entry_id
      and item.archived_at is null
  ) then
    raise exception 'Đội thắng không thuộc trận đấu';
  end if;

  select home.entry_id, away.entry_id, home.score_numeric, away.score_numeric
  into first_entry, second_entry, first_score, second_score
  from public.fixture_entries home
  join public.fixture_entries away on away.fixture_id = home.fixture_id
    and away.side = 'away' and away.archived_at is null
  where home.fixture_id = new.id
    and home.side = 'home'
    and home.archived_at is null;

  if first_score is not null and second_score is not null then
    if first_score = second_score then
      if new.winner_entry_id is not null then
        raise exception 'Tỷ số hòa không xác định được đội thắng';
      end if;
    elsif new.winner_entry_id is distinct from (case when first_score > second_score then first_entry else second_entry end) then
      raise exception 'Đội thắng không khớp tỷ số';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.validate_fixture_result() from public;

create trigger fixtures_validate_result
  before update of status, winner_entry_id on public.fixtures
  for each row execute function private.validate_fixture_result();

create or replace function private.sync_group_standings(p_group_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  destination record;
  desired_entry_id uuid;
begin
  for destination in
    select slot.fixture_id, slot.side, slot.tenant_id, slot.source_rank
    from public.fixture_slots slot
    where slot.source_group_id = p_group_id
      and slot.source_kind = 'group_rank'
      and slot.archived_at is null
  loop
    select standing.entry_id into desired_entry_id
    from public.standings standing
    where standing.group_id = p_group_id
      and standing.rank = destination.source_rank
      and standing.archived_at is null;

    update public.fixture_entries item
    set archived_at = now()
    where item.fixture_id = destination.fixture_id
      and item.side = destination.side
      and item.archived_at is null
      and (desired_entry_id is null or item.entry_id <> desired_entry_id);

    if desired_entry_id is not null then
      insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side)
      values (destination.tenant_id, destination.fixture_id, desired_entry_id, destination.side)
      on conflict (fixture_id, entry_id) do update set side = excluded.side, archived_at = null;
      perform private.sync_fixture_slots(destination.fixture_id);
    end if;
  end loop;
end;
$$;

revoke all on function private.sync_group_standings(uuid) from public;
grant execute on function private.sync_group_standings(uuid) to authenticated;

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
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, points numeric, rank integer)
    group by entry_id having count(*) > 1
  ) then raise exception 'Đội thi bị trùng'; end if;
  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, points numeric, rank integer)
    where row.rank is not null and row.rank <= 0
  ) then raise exception 'Hạng không hợp lệ'; end if;
  if p_group_id is not null and exists (
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, points numeric, rank integer)
    where row.rank is not null
    group by row.rank having count(*) > 1
  ) then raise exception 'Hạng trong bảng không được trùng'; end if;

  if exists (
    select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid, points numeric, rank integer)
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
    and not exists (select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid) where row.entry_id = existing.entry_id);

  update public.standings existing
  set rank = null
  where existing.tournament_id = p_tournament_id
    and existing.group_id is not distinct from p_group_id
    and existing.archived_at is null
    and exists (select 1 from jsonb_to_recordset(p_rows) as row(entry_id uuid) where row.entry_id = existing.entry_id);

  for item in select * from jsonb_to_recordset(p_rows) as row(entry_id uuid, points numeric, rank integer)
  loop
    insert into public.standings (tenant_id, tournament_id, group_id, entry_id, points, rank, archived_at)
    values ((select private.current_tenant_id()), p_tournament_id, p_group_id, item.entry_id, coalesce(item.points, 0), item.rank, null)
    on conflict (tournament_id, group_id, entry_id) do update set points = excluded.points, rank = excluded.rank, archived_at = null;
  end loop;

  if p_group_id is not null then
    update public.groups set standings_confirmed_at = null where id = p_group_id;
  end if;
end;
$$;

revoke execute on function public.save_manual_standings(uuid, uuid, jsonb) from public, anon;
grant execute on function public.save_manual_standings(uuid, uuid, jsonb) to authenticated;

create or replace function public.confirm_group_standings(p_group_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  group_row public.groups%rowtype;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  select * into group_row from public.groups
  where id = p_group_id and tenant_id = (select private.current_tenant_id()) and archived_at is null for update;
  if not found then raise exception 'Không tìm thấy bảng đấu'; end if;
  if exists (
    select 1 from public.group_entries member
    where member.group_id = p_group_id and member.archived_at is null
      and not exists (select 1 from public.standings standing where standing.group_id = p_group_id and standing.entry_id = member.entry_id and standing.rank is not null and standing.archived_at is null)
  ) then raise exception 'Bảng chưa đủ hạng'; end if;
  if exists (
    select 1 from public.standings standing
    where standing.group_id = p_group_id and standing.rank is not null and standing.archived_at is null
    group by standing.rank having count(*) > 1
  ) then raise exception 'Hạng trong bảng không được trùng'; end if;

  update public.groups set standings_confirmed_at = now() where id = p_group_id;
  perform private.sync_group_standings(p_group_id);
end;
$$;

revoke execute on function public.confirm_group_standings(uuid) from public, anon;
grant execute on function public.confirm_group_standings(uuid) to authenticated;

create or replace function public.save_manual_leaderboard(p_rows jsonb)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  item record;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  if jsonb_typeof(p_rows) <> 'array' then raise exception 'Bảng xếp hạng không hợp lệ'; end if;
  if exists (select 1 from jsonb_to_recordset(p_rows) as row(organization_id uuid, rank integer, gold integer, silver integer, bronze integer) group by organization_id having count(*) > 1) then raise exception 'Đơn vị bị trùng'; end if;
  if exists (select 1 from jsonb_to_recordset(p_rows) as row(organization_id uuid, rank integer, gold integer, silver integer, bronze integer) where rank is not null and rank <= 0) then raise exception 'Hạng không hợp lệ'; end if;
  if exists (select 1 from jsonb_to_recordset(p_rows) as row(organization_id uuid, rank integer, gold integer, silver integer, bronze integer) where gold < 0 or silver < 0 or bronze < 0) then raise exception 'Số huy chương không hợp lệ'; end if;
  if exists (select 1 from jsonb_to_recordset(p_rows) as row(organization_id uuid, rank integer, gold integer, silver integer, bronze integer) where rank is not null group by rank having count(*) > 1) then raise exception 'Hạng đoàn không được trùng'; end if;
  update public.organizations organization
  set leaderboard_rank = null
  where organization.tenant_id = (select private.current_tenant_id())
    and organization.archived_at is null
    and exists (select 1 from jsonb_to_recordset(p_rows) as row(organization_id uuid) where row.organization_id = organization.id);
  for item in select * from jsonb_to_recordset(p_rows) as row(organization_id uuid, rank integer, gold integer, silver integer, bronze integer)
  loop
    update public.organizations
    set leaderboard_rank = item.rank, gold_medals = coalesce(item.gold, 0), silver_medals = coalesce(item.silver, 0), bronze_medals = coalesce(item.bronze, 0)
    where id = item.organization_id and tenant_id = (select private.current_tenant_id()) and archived_at is null;
    if not found then raise exception 'Đơn vị không hợp lệ'; end if;
  end loop;
end;
$$;

revoke execute on function public.save_manual_leaderboard(jsonb) from public, anon;
grant execute on function public.save_manual_leaderboard(jsonb) to authenticated;

create or replace function public.save_fixture_slot_and_sync(
  p_slot_id uuid,
  p_source_kind text,
  p_source_entry_id uuid,
  p_source_group_id uuid,
  p_source_fixture_id uuid,
  p_source_rank integer,
  p_label_vi text,
  p_label_en text
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  slot_row public.fixture_slots%rowtype;
  tournament_id uuid;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  select slot.* into slot_row
  from public.fixture_slots slot
  where slot.id = p_slot_id and slot.tenant_id = (select private.current_tenant_id()) and slot.archived_at is null for update;
  if not found then raise exception 'Không tìm thấy ô nhánh'; end if;
  update public.fixture_slots set source_kind = p_source_kind, source_entry_id = p_source_entry_id, source_group_id = p_source_group_id, source_fixture_id = p_source_fixture_id, source_rank = p_source_rank, label_vi = coalesce(p_label_vi, ''), label_en = coalesce(p_label_en, '') where id = p_slot_id;
  select fixture.tournament_id into tournament_id from public.fixtures fixture where fixture.id = slot_row.fixture_id;
  perform public.sync_tournament_slots(tournament_id);
end;
$$;

revoke execute on function public.save_fixture_slot_and_sync(uuid, text, uuid, uuid, uuid, integer, text, text) from public, anon;
grant execute on function public.save_fixture_slot_and_sync(uuid, text, uuid, uuid, uuid, integer, text, text) to authenticated;
