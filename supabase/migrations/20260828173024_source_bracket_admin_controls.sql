alter table public.fixtures
  add column source_code text;

alter table public.tournaments
  add column source_metadata jsonb not null default '{}'::jsonb,
  add constraint tournaments_source_metadata_object check (jsonb_typeof(source_metadata) = 'object');

create unique index fixture_slots_entry_source_key on public.fixture_slots (fixture_id, source_entry_id)
  where source_kind = 'entry' and archived_at is null;
create unique index fixture_slots_group_source_key on public.fixture_slots (fixture_id, source_group_id, source_rank)
  where source_kind = 'group_rank' and archived_at is null;
create unique index fixture_slots_fixture_source_key on public.fixture_slots (fixture_id, source_fixture_id, source_kind)
  where source_kind in ('fixture_winner', 'fixture_loser') and archived_at is null;

create or replace function private.lock_started_bracket_structure()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  target_tournament_id uuid;
begin
  select fixture.tournament_id into target_tournament_id
  from public.fixtures fixture
  where fixture.id = case when tg_op = 'DELETE' then old.fixture_id else new.fixture_id end;

  if exists (
    select 1
    from public.fixtures fixture
    where fixture.tournament_id = target_tournament_id
      and fixture.archived_at is null
      and (
        fixture.status in ('live', 'completed') or
        fixture.winner_entry_id is not null or
        exists (
          select 1 from public.fixture_entries item
          where item.fixture_id = fixture.id
            and item.archived_at is null
            and (
              item.score is not null or item.score_numeric is not null or
              item.rank is not null or item.result_status is not null
            )
        )
      )
  ) then
    raise exception 'Cấu trúc đã khóa vì hạng mục đã có kết quả';
  end if;

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

revoke all on function private.lock_started_bracket_structure() from public;

create trigger fixture_slots_lock_started
  before insert or update or delete on public.fixture_slots
  for each row execute function private.lock_started_bracket_structure();

create or replace function public.sync_tournament_slots(p_tournament_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  source_fixture_id uuid;
begin
  if not (select private.is_admin()) then
    raise exception 'Không có quyền quản trị';
  end if;

  if not exists (
    select 1 from public.tournaments tournament
    where tournament.id = p_tournament_id
      and tournament.tenant_id = (select private.current_tenant_id())
      and tournament.archived_at is null
  ) then
    raise exception 'Không tìm thấy hạng mục';
  end if;

  update public.fixture_entries item
  set archived_at = now()
  where item.archived_at is null
    and exists (
      select 1
      from public.fixture_slots slot
      join public.fixtures fixture on fixture.id = slot.fixture_id
      where fixture.tournament_id = p_tournament_id
        and slot.archived_at is null
        and slot.fixture_id = item.fixture_id
        and slot.side = item.side
        and slot.source_kind in ('entry', 'bye')
        and (slot.source_kind = 'bye' or item.entry_id is distinct from slot.source_entry_id)
    );

  insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side, archived_at)
  select fixture.tenant_id, slot.fixture_id, slot.source_entry_id, slot.side, null
  from public.fixture_slots slot
  join public.fixtures fixture on fixture.id = slot.fixture_id
  where fixture.tournament_id = p_tournament_id
    and fixture.archived_at is null
    and slot.archived_at is null
    and slot.source_kind = 'entry'
  on conflict (fixture_id, entry_id) do update set side = excluded.side, archived_at = null;

  for source_fixture_id in
    select fixture.id from public.fixtures fixture
    where fixture.tournament_id = p_tournament_id and fixture.archived_at is null
    order by fixture.round_order nulls first, fixture.bracket_position nulls first, fixture.id
  loop
    perform private.sync_fixture_slots(source_fixture_id);
  end loop;
end;
$$;

revoke execute on function public.sync_tournament_slots(uuid) from public, anon;
grant execute on function public.sync_tournament_slots(uuid) to authenticated;
