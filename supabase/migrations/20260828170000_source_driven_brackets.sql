alter table public.tournaments
  add column competition_mode text not null default 'round_robin'
  check (competition_mode in ('knockout', 'group_knockout', 'round_robin', 'swiss', 'race'));

alter table public.fixture_entries
  add column result_status text
  check (result_status is null or result_status in ('finished', 'dns', 'dnf', 'dsq'));

create unique index fixture_entries_side_key
  on public.fixture_entries (fixture_id, side)
  where side is not null and archived_at is null;

create table public.fixture_slots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null default coalesce(private.current_tenant_id(), private.seed_tenant_id()) references public.tenants(id),
  fixture_id uuid not null references public.fixtures(id),
  side text not null check (side in ('home', 'away')),
  source_kind text not null check (source_kind in ('entry', 'group_rank', 'fixture_winner', 'fixture_loser', 'bye')),
  source_entry_id uuid references public.entries(id),
  source_group_id uuid references public.groups(id),
  source_fixture_id uuid references public.fixtures(id),
  source_rank integer check (source_rank > 0),
  label_vi text not null default '',
  label_en text not null default '',
  archived_at timestamptz,
  unique (fixture_id, side),
  check (
    (source_kind = 'entry' and source_entry_id is not null and source_group_id is null and source_fixture_id is null and source_rank is null) or
    (source_kind = 'group_rank' and source_entry_id is null and source_group_id is not null and source_fixture_id is null and source_rank is not null) or
    (source_kind in ('fixture_winner', 'fixture_loser') and source_entry_id is null and source_group_id is null and source_fixture_id is not null and source_rank is null) or
    (source_kind = 'bye' and source_entry_id is null and source_group_id is null and source_fixture_id is null and source_rank is null)
  )
);

create index fixture_slots_tenant_fixture_idx
  on public.fixture_slots (tenant_id, fixture_id)
  where archived_at is null;

create index fixture_slots_source_fixture_idx
  on public.fixture_slots (source_fixture_id)
  where source_fixture_id is not null and archived_at is null;

create trigger fixture_slots_same_tenant
  before insert or update on public.fixture_slots
  for each row execute function private.enforce_same_tenant(
    'fixtures', 'fixture_id',
    'entries', 'source_entry_id',
    'groups', 'source_group_id',
    'fixtures', 'source_fixture_id'
  );

create or replace function private.validate_fixture_slot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  destination_tournament_id uuid;
  source_tournament_id uuid;
begin
  select tournament_id into destination_tournament_id
  from public.fixtures
  where id = new.fixture_id;

  if new.source_kind = 'entry' then
    select tournament_id into source_tournament_id
    from public.entries
    where id = new.source_entry_id;
  elsif new.source_kind = 'group_rank' then
    select tournament_id into source_tournament_id
    from public.groups
    where id = new.source_group_id;
  elsif new.source_kind in ('fixture_winner', 'fixture_loser') then
    select tournament_id into source_tournament_id
    from public.fixtures
    where id = new.source_fixture_id;

    if new.source_fixture_id = new.fixture_id then
      raise exception 'Một trận không thể phụ thuộc chính nó';
    end if;

    if exists (
      with recursive downstream(fixture_id) as (
        select new.fixture_id
        union
        select slot.fixture_id
        from public.fixture_slots slot
        join downstream on slot.source_fixture_id = downstream.fixture_id
        where slot.archived_at is null
          and slot.id is distinct from new.id
      )
      select 1 from downstream where fixture_id = new.source_fixture_id
    ) then
      raise exception 'Quan hệ bracket tạo chu trình';
    end if;
  end if;

  if source_tournament_id is not null and source_tournament_id is distinct from destination_tournament_id then
    raise exception 'Nguồn slot phải cùng hạng mục với trận đích';
  end if;

  return new;
end;
$$;

revoke all on function private.validate_fixture_slot() from public;
grant execute on function private.validate_fixture_slot() to authenticated;

create trigger fixture_slots_validate
  before insert or update on public.fixture_slots
  for each row execute function private.validate_fixture_slot();

alter table public.fixture_slots enable row level security;

create policy fixture_slots_public_read on public.fixture_slots
  for select to anon
  using (tenant_id = (select private.current_tenant_id()) and archived_at is null);

create policy fixture_slots_admin_read on public.fixture_slots
  for select to authenticated
  using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));

create policy fixture_slots_admin_insert on public.fixture_slots
  for insert to authenticated
  with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));

create policy fixture_slots_admin_update on public.fixture_slots
  for update to authenticated
  using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)))
  with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));

grant select on public.fixture_slots to anon, authenticated;
grant insert, update on public.fixture_slots to authenticated;
revoke delete on public.fixture_slots from anon, authenticated;

-- ponytail: recursive tournament graph is small; move to queued propagation only if tournament writes become high-volume.
create or replace function private.sync_fixture_slots(p_source_fixture_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  slot record;
  desired_entry_id uuid;
begin
  for slot in
    select destination.*
    from public.fixture_slots destination
    where destination.archived_at is null
      and (
        destination.source_fixture_id = p_source_fixture_id or
        destination.source_group_id = (
          select source.group_id from public.fixtures source where source.id = p_source_fixture_id
        )
      )
    order by destination.fixture_id, destination.side
  loop
    desired_entry_id := null;

    if slot.source_kind = 'fixture_winner' then
      select winner_entry_id into desired_entry_id
      from public.fixtures
      where id = slot.source_fixture_id and archived_at is null;
    elsif slot.source_kind = 'fixture_loser' then
      select participant.entry_id into desired_entry_id
      from public.fixture_entries participant
      join public.fixtures source on source.id = participant.fixture_id
      where participant.fixture_id = slot.source_fixture_id
        and participant.archived_at is null
        and source.winner_entry_id is not null
        and participant.entry_id <> source.winner_entry_id
      order by case participant.side when 'home' then 0 else 1 end, participant.seed_order nulls last
      limit 1;
    elsif slot.source_kind = 'group_rank'
      and exists (
        select 1 from public.fixtures grouped
        where grouped.group_id = slot.source_group_id and grouped.archived_at is null
      )
      and not exists (
        select 1 from public.fixtures grouped
        where grouped.group_id = slot.source_group_id
          and grouped.archived_at is null
          and grouped.status <> 'completed'
      )
      and 1 = (
        select count(*) from public.standings ranked
        where ranked.group_id = slot.source_group_id
          and ranked.rank = slot.source_rank
          and ranked.archived_at is null
      )
    then
      select ranked.entry_id into desired_entry_id
      from public.standings ranked
      where ranked.group_id = slot.source_group_id
        and ranked.rank = slot.source_rank
        and ranked.archived_at is null;
    end if;

    update public.fixture_entries participant
    set archived_at = now()
    where participant.fixture_id = slot.fixture_id
      and participant.side = slot.side
      and participant.archived_at is null
      and (desired_entry_id is null or participant.entry_id <> desired_entry_id);

    if desired_entry_id is not null then
      insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side)
      values (slot.tenant_id, slot.fixture_id, desired_entry_id, slot.side)
      on conflict (fixture_id, entry_id) do update set
        side = excluded.side,
        score = case when fixture_entries.archived_at is not null then null else fixture_entries.score end,
        score_numeric = case when fixture_entries.archived_at is not null then null else fixture_entries.score_numeric end,
        rank = case when fixture_entries.archived_at is not null then null else fixture_entries.rank end,
        result_status = case when fixture_entries.archived_at is not null then null else fixture_entries.result_status end,
        result_detail = case when fixture_entries.archived_at is not null then '{}'::jsonb else fixture_entries.result_detail end,
        archived_at = null;
    end if;
  end loop;
end;
$$;

revoke all on function private.sync_fixture_slots(uuid) from public;
grant execute on function private.sync_fixture_slots(uuid) to authenticated;

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

  perform private.sync_fixture_slots(p_fixture_id);
end;
$$;

revoke execute on function public.save_fixture_result(uuid, text, uuid, text, text, jsonb, jsonb) from public, anon;
grant execute on function public.save_fixture_result(uuid, text, uuid, text, text, jsonb, jsonb) to authenticated;

create or replace function public.reset_fixture_dependents(p_fixture_id uuid, p_confirm boolean default false)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  fixture_row public.fixtures%rowtype;
  affected jsonb;
  has_results boolean;
  source_id uuid;
begin
  if not (select private.is_admin()) then
    raise exception 'Không có quyền quản trị';
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
  select
    coalesce(bool_or(
      dependent.status in ('live', 'completed') or
      dependent.winner_entry_id is not null or
      exists (
        select 1 from public.fixture_entries scored
        where scored.fixture_id = dependent.id
          and scored.archived_at is null
          and (scored.score is not null or scored.score_numeric is not null or scored.rank is not null or scored.result_status is not null)
      )
    ), false),
    coalesce(jsonb_agg(jsonb_build_object(
      'id', dependent.id,
      'round_vi', dependent.round_vi,
      'status', dependent.status
    ) order by dependent.round_order, dependent.bracket_position), '[]'::jsonb)
  into has_results, affected
  from downstream
  join public.fixtures dependent on dependent.id = downstream.id
  where dependent.archived_at is null;

  if not p_confirm then
    return jsonb_build_object('blocked', has_results, 'fixtures', affected);
  end if;

  update public.fixture_entries participant
  set score = null,
      score_numeric = null,
      rank = null,
      result_status = null,
      result_detail = '{}'::jsonb
  where participant.archived_at is null
    and participant.fixture_id in (
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
    );

  update public.fixture_entries participant
  set archived_at = now()
  where participant.archived_at is null
    and exists (
      select 1 from public.fixture_slots slot
      where slot.fixture_id = participant.fixture_id
        and slot.side = participant.side
        and slot.archived_at is null
        and slot.source_kind in ('group_rank', 'fixture_winner', 'fixture_loser')
        and slot.fixture_id in (
          with recursive downstream(id) as (
            select initial.fixture_id
            from public.fixture_slots initial
            where initial.archived_at is null
              and (initial.source_fixture_id = p_fixture_id or (fixture_row.group_id is not null and initial.source_group_id = fixture_row.group_id))
            union
            select child.fixture_id
            from public.fixture_slots child
            join downstream on child.source_fixture_id = downstream.id
            where child.archived_at is null
          )
          select id from downstream
        )
    );

  update public.fixtures dependent
  set status = 'scheduled',
      winner_entry_id = null,
      result_summary_vi = '',
      result_summary_en = ''
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
  );

  for source_id in
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
    select distinct slot.source_fixture_id
    from public.fixture_slots slot
    where slot.fixture_id in (select id from downstream)
      and slot.source_fixture_id is not null
      and slot.archived_at is null
    union
    select distinct on (slot.source_group_id) grouped.id
    from public.fixture_slots slot
    join public.fixtures grouped on grouped.group_id = slot.source_group_id and grouped.archived_at is null
    where slot.fixture_id in (select id from downstream)
      and slot.source_group_id is not null
      and slot.archived_at is null
    order by 1
  loop
    perform private.sync_fixture_slots(source_id);
  end loop;

  return jsonb_build_object('blocked', has_results, 'fixtures', affected);
end;
$$;

revoke execute on function public.reset_fixture_dependents(uuid, boolean) from public, anon;
grant execute on function public.reset_fixture_dependents(uuid, boolean) to authenticated;
