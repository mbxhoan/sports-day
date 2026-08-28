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
