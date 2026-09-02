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
  end loop;
end;
$$;

revoke all on function private.sync_fixture_slots(uuid) from public;
grant execute on function private.sync_fixture_slots(uuid) to authenticated;

insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side)
select fixture.tenant_id, slot.fixture_id, slot.source_entry_id, slot.side
from public.fixture_slots slot
join public.fixtures fixture on fixture.id = slot.fixture_id
where slot.archived_at is null
  and fixture.archived_at is null
  and slot.source_kind = 'entry'
  and slot.source_entry_id is not null
on conflict (fixture_id, entry_id) do update set side = excluded.side, archived_at = null;

do $$
declare
  source_id uuid;
begin
  for source_id in
    select fixture.id from public.fixtures fixture
    where fixture.archived_at is null
    order by fixture.id
  loop
    perform private.sync_fixture_slots(source_id);
  end loop;
end;
$$;

update public.fixture_entries item
set archived_at = now()
where item.archived_at is null
  and item.side is null
  and exists (
    select 1 from public.fixture_slots slot
    where slot.fixture_id = item.fixture_id and slot.archived_at is null
  );
