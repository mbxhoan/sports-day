set app.tenant_slug = 'ptsc2026';

-- PTSC uses the path-aware overload so every downstream source slot is refreshed.
create or replace function private.sync_fixture_slots(p_source_fixture_id uuid, p_path uuid[])
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  slot record;
  desired_entry_id uuid;
  source_tenant_id uuid;
  ptsc_tenant boolean;
  current_path uuid[] := coalesce(p_path, array[p_source_fixture_id]);
begin
  select fixture.tenant_id into source_tenant_id
  from public.fixtures fixture
  where fixture.id = p_source_fixture_id and fixture.archived_at is null;
  if source_tenant_id is null then return; end if;

  select exists (
    select 1 from public.tenants tenant
    where tenant.id = source_tenant_id and tenant.slug = 'ptsc2026' and tenant.archived_at is null
  ) into ptsc_tenant;

  for slot in
    select destination.*
    from public.fixture_slots destination
    where destination.tenant_id = source_tenant_id
      and destination.archived_at is null
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
      and (
        exists (
          select 1 from public.groups source_group
          where source_group.id = slot.source_group_id
            and source_group.archived_at is null
            and source_group.standings_confirmed_at is not null
        )
        or (
          exists (
            select 1 from public.fixtures grouped
            where grouped.group_id = slot.source_group_id and grouped.archived_at is null
          )
          and not exists (
            select 1 from public.fixtures grouped
            where grouped.group_id = slot.source_group_id
              and grouped.archived_at is null
              and grouped.status <> 'completed'
          )
        )
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
      and (participant.side = slot.side or participant.side is null)
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

    if ptsc_tenant and not (slot.fixture_id = any(current_path)) then
      perform private.sync_fixture_slots(slot.fixture_id, current_path || slot.fixture_id);
    end if;
  end loop;
end;
$$;

create or replace function private.sync_fixture_slots(p_source_fixture_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  perform private.sync_fixture_slots(p_source_fixture_id, array[p_source_fixture_id]);
end;
$$;

-- Re-run downstream slots even when a PTSC group rank becomes unresolved.
-- Legacy tenants retain the previous direct-only call behavior.
create or replace function private.sync_group_standings(p_group_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  destination record;
  desired_entry_id uuid;
  ptsc_tenant boolean;
begin
  select exists (
    select 1
    from public.groups source_group
    join public.tenants tenant on tenant.id = source_group.tenant_id
    where source_group.id = p_group_id
      and source_group.archived_at is null
      and tenant.slug = 'ptsc2026'
      and tenant.archived_at is null
  ) into ptsc_tenant;

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
    end if;

    if ptsc_tenant or desired_entry_id is not null then
      perform private.sync_fixture_slots(destination.fixture_id);
    end if;
  end loop;
end;
$$;

revoke all on function private.sync_group_standings(uuid) from public;
grant execute on function private.sync_group_standings(uuid) to authenticated;

revoke all on function private.sync_fixture_slots(uuid, uuid[]) from public;
grant execute on function private.sync_fixture_slots(uuid, uuid[]) to authenticated;
revoke all on function private.sync_fixture_slots(uuid) from public;
grant execute on function private.sync_fixture_slots(uuid) to authenticated;
