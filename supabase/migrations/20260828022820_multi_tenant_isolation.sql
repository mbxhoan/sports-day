create table public.tenants (
  id uuid primary key,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name_vi text not null,
  name_en text not null,
  created_at timestamptz not null default now(),
  archived_at timestamptz
);

insert into public.tenants (id, slug, name_vi, name_en) values
  ('11111111-1111-1111-1111-111111111111', 'petrovietnam2026', 'Petrovietnam 2026', 'Petrovietnam 2026'),
  ('22222222-2222-2222-2222-222222222222', 'ptsc2026', 'Hội thao PTSC lần thứ 15', 'PTSC 15th Sports Festival');

create or replace function private.seed_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.tenants
  where slug = current_setting('app.tenant_slug', true)
    and archived_at is null;
$$;

revoke all on function private.seed_tenant_id() from public;
grant execute on function private.seed_tenant_id() to postgres;

create or replace function private.current_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.tenants
  where slug = coalesce(current_setting('request.headers', true), '{}')::jsonb ->> 'x-tenant-slug'
    and archived_at is null;
$$;

revoke all on function private.current_tenant_id() from public;
grant execute on function private.current_tenant_id() to anon, authenticated;

alter table public.admin_users add column tenant_id uuid;
alter table public.event_settings add column tenant_id uuid;
alter table public.contacts add column tenant_id uuid;
alter table public.footer_links add column tenant_id uuid;
alter table public.media add column tenant_id uuid;
alter table public.sports add column tenant_id uuid;
alter table public.tournaments add column tenant_id uuid;
alter table public.organizations add column tenant_id uuid;
alter table public.participants add column tenant_id uuid;
alter table public.entries add column tenant_id uuid;
alter table public.entry_members add column tenant_id uuid;
alter table public.venues add column tenant_id uuid;
alter table public.courts add column tenant_id uuid;
alter table public.groups add column tenant_id uuid;
alter table public.group_entries add column tenant_id uuid;
alter table public.fixtures add column tenant_id uuid;
alter table public.fixture_entries add column tenant_id uuid;
alter table public.standings add column tenant_id uuid;
alter table public.awards add column tenant_id uuid;
alter table public.source_documents add column tenant_id uuid;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'admin_users', 'event_settings', 'contacts', 'footer_links', 'media', 'sports', 'tournaments',
    'organizations', 'participants', 'entries', 'entry_members', 'venues', 'courts', 'groups',
    'group_entries', 'fixtures', 'fixture_entries', 'standings', 'awards', 'source_documents'
  ] loop
    execute format('update public.%I set tenant_id = %L where tenant_id is null', table_name, '11111111-1111-1111-1111-111111111111');
    execute format('alter table public.%I alter column tenant_id set not null', table_name);
    execute format('alter table public.%I alter column tenant_id set default coalesce(private.current_tenant_id(), private.seed_tenant_id())', table_name);
    execute format('alter table public.%I add constraint %I foreign key (tenant_id) references public.tenants(id)', table_name, table_name || '_tenant_id_fkey');
  end loop;
end $$;

alter table public.event_settings alter column start_at drop not null;

alter table public.admin_users drop constraint if exists admin_users_pkey;
alter table public.admin_users add constraint admin_users_pkey primary key (tenant_id, user_id);

alter table public.event_settings drop constraint if exists event_settings_singleton_key_key;
alter table public.sports drop constraint if exists sports_slug_key;
alter table public.organizations drop constraint if exists organizations_code_key;
alter table public.source_documents drop constraint if exists source_documents_raw_filename_key;
alter table public.tournaments drop constraint if exists tournaments_sport_id_slug_key;

alter table public.event_settings add constraint event_settings_tenant_singleton_key_key unique (tenant_id, singleton_key);
alter table public.sports add constraint sports_tenant_slug_key unique (tenant_id, slug);
alter table public.organizations add constraint organizations_tenant_code_key unique (tenant_id, code);
alter table public.source_documents add constraint source_documents_tenant_filename_key unique (tenant_id, raw_filename);
alter table public.tournaments add constraint tournaments_tenant_sport_slug_key unique (tenant_id, sport_id, slug);

create index tenants_active_slug_idx on public.tenants (slug) where archived_at is null;
create index admin_users_tenant_user_idx on public.admin_users (tenant_id, user_id) where archived_at is null;
create index event_settings_tenant_idx on public.event_settings (tenant_id) where archived_at is null;
create index contacts_tenant_idx on public.contacts (tenant_id, sort_order) where archived_at is null;
create index footer_links_tenant_idx on public.footer_links (tenant_id, sort_order) where archived_at is null;
create index media_tenant_idx on public.media (tenant_id, sort_order) where archived_at is null;
create index sports_tenant_idx on public.sports (tenant_id, sort_order) where archived_at is null;
create index tournaments_tenant_idx on public.tournaments (tenant_id, sport_id, sort_order) where archived_at is null;
create index organizations_tenant_idx on public.organizations (tenant_id, sort_order) where archived_at is null;
create index participants_tenant_idx on public.participants (tenant_id, organization_id) where archived_at is null;
create index entries_tenant_idx on public.entries (tenant_id, tournament_id) where archived_at is null;
create index entry_members_tenant_idx on public.entry_members (tenant_id, entry_id) where archived_at is null;
create index venues_tenant_idx on public.venues (tenant_id, sort_order) where archived_at is null;
create index courts_tenant_idx on public.courts (tenant_id, venue_id) where archived_at is null;
create index groups_tenant_idx on public.groups (tenant_id, tournament_id) where archived_at is null;
create index group_entries_tenant_idx on public.group_entries (tenant_id, group_id) where archived_at is null;
create index fixtures_tenant_idx on public.fixtures (tenant_id, tournament_id, starts_at) where archived_at is null;
create index fixture_entries_tenant_idx on public.fixture_entries (tenant_id, fixture_id) where archived_at is null;
create index standings_tenant_idx on public.standings (tenant_id, tournament_id, rank) where archived_at is null;
create index awards_tenant_idx on public.awards (tenant_id, sport_id, sort_order) where archived_at is null;
create index source_documents_tenant_idx on public.source_documents (tenant_id, raw_filename) where archived_at is null;

create or replace function private.is_admin(p_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = (select auth.uid())
      and tenant_id = p_tenant_id
      and archived_at is null
  );
$$;

revoke all on function private.is_admin(uuid) from public;
grant execute on function private.is_admin(uuid) to authenticated;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_admin(private.current_tenant_id());
$$;

revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated;

create or replace function private.enforce_same_tenant()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  index integer;
  parent_tenant uuid;
  parent_id uuid;
begin
  if tg_op = 'UPDATE' and old.tenant_id is distinct from new.tenant_id then
    raise exception 'Không được chuyển dữ liệu giữa tenant';
  end if;
  for index in 0..(coalesce(array_length(tg_argv, 1), 0) - 1) by 2 loop
    parent_id := (to_jsonb(new) ->> tg_argv[index + 1])::uuid;
    if parent_id is null then continue; end if;
    execute format('select tenant_id from public.%I where id = $1', tg_argv[index]) into parent_tenant using parent_id;
    if parent_tenant is distinct from new.tenant_id then
      raise exception 'Quan hệ dữ liệu khác tenant';
    end if;
  end loop;
  return new;
end;
$$;

revoke all on function private.enforce_same_tenant() from public;
grant execute on function private.enforce_same_tenant() to authenticated;

create trigger participants_same_tenant before insert or update on public.participants for each row execute function private.enforce_same_tenant('organizations', 'organization_id');
create trigger tournaments_same_tenant before insert or update on public.tournaments for each row execute function private.enforce_same_tenant('sports', 'sport_id');
create trigger entries_same_tenant before insert or update on public.entries for each row execute function private.enforce_same_tenant('tournaments', 'tournament_id', 'organizations', 'organization_id');
create trigger entry_members_same_tenant before insert or update on public.entry_members for each row execute function private.enforce_same_tenant('entries', 'entry_id', 'participants', 'participant_id');
create trigger courts_same_tenant before insert or update on public.courts for each row execute function private.enforce_same_tenant('venues', 'venue_id');
create trigger groups_same_tenant before insert or update on public.groups for each row execute function private.enforce_same_tenant('tournaments', 'tournament_id');
create trigger group_entries_same_tenant before insert or update on public.group_entries for each row execute function private.enforce_same_tenant('groups', 'group_id', 'entries', 'entry_id');
create trigger fixtures_same_tenant before insert or update on public.fixtures for each row execute function private.enforce_same_tenant('tournaments', 'tournament_id', 'groups', 'group_id', 'venues', 'venue_id', 'courts', 'court_id', 'fixtures', 'next_fixture_id', 'entries', 'winner_entry_id');
create trigger fixture_entries_same_tenant before insert or update on public.fixture_entries for each row execute function private.enforce_same_tenant('fixtures', 'fixture_id', 'entries', 'entry_id');
create trigger standings_same_tenant before insert or update on public.standings for each row execute function private.enforce_same_tenant('tournaments', 'tournament_id', 'groups', 'group_id', 'entries', 'entry_id');
create trigger awards_same_tenant before insert or update on public.awards for each row execute function private.enforce_same_tenant('sports', 'sport_id', 'tournaments', 'tournament_id', 'entries', 'entry_id', 'participants', 'participant_id', 'organizations', 'organization_id');
create trigger media_same_tenant before insert or update on public.media for each row execute function private.enforce_same_tenant('sports', 'sport_id');

alter table public.tenants enable row level security;
revoke all on public.tenants from anon, authenticated;
grant select on public.tenants to anon, authenticated;
create policy tenants_public_read on public.tenants
  for select to anon, authenticated
  using (archived_at is null and slug = coalesce(current_setting('request.headers', true), '{}')::jsonb ->> 'x-tenant-slug');

drop policy if exists admin_users_read_self on public.admin_users;
create policy admin_users_read_self on public.admin_users
  for select to authenticated
  using (user_id = (select auth.uid()) and tenant_id = (select private.current_tenant_id()));

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'event_settings', 'contacts', 'footer_links', 'media', 'sports', 'tournaments',
    'organizations', 'participants', 'entries', 'entry_members', 'venues', 'courts',
    'groups', 'group_entries', 'fixtures', 'fixture_entries', 'standings', 'awards',
    'source_documents'
  ] loop
    execute format('drop policy if exists %I on public.%I', table_name || '_public_read', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_admin_read', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_admin_insert', table_name);
    execute format('drop policy if exists %I on public.%I', table_name || '_admin_update', table_name);
    execute format('create policy %I on public.%I for select to anon using (tenant_id = (select private.current_tenant_id()) and archived_at is null)', table_name || '_public_read', table_name);
    execute format('create policy %I on public.%I for select to authenticated using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)))', table_name || '_admin_read', table_name);
    execute format('create policy %I on public.%I for insert to authenticated with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)))', table_name || '_admin_insert', table_name);
    execute format('create policy %I on public.%I for update to authenticated using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id))) with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)))', table_name || '_admin_update', table_name);
  end loop;
end $$;

drop policy if exists event_media_public_read on storage.objects;
drop policy if exists event_media_admin_insert on storage.objects;
drop policy if exists event_media_admin_update on storage.objects;
create policy event_media_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'event-media');
create policy event_media_admin_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'event-media' and name like (coalesce(current_setting('request.headers', true), '{}')::jsonb ->> 'x-tenant-slug') || '/%' and (select private.is_admin((select private.current_tenant_id()))));
create policy event_media_admin_update on storage.objects
  for update to authenticated
  using (bucket_id = 'event-media' and name like (coalesce(current_setting('request.headers', true), '{}')::jsonb ->> 'x-tenant-slug') || '/%' and (select private.is_admin((select private.current_tenant_id()))))
  with check (bucket_id = 'event-media' and name like (coalesce(current_setting('request.headers', true), '{}')::jsonb ->> 'x-tenant-slug') || '/%' and (select private.is_admin((select private.current_tenant_id()))));
