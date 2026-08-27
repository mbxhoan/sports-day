create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;

create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.event_settings (
  id uuid primary key default gen_random_uuid(),
  singleton_key text not null default 'main' unique check (singleton_key = 'main'),
  event_name_vi text not null,
  event_name_en text not null,
  subtitle_vi text not null default '',
  subtitle_en text not null default '',
  about_vi text not null default '',
  about_en text not null default '',
  venue_vi text not null default '',
  venue_en text not null default '',
  hero_path text not null default '/kv.png',
  start_at timestamptz not null,
  end_at timestamptz,
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  label_vi text not null,
  label_en text not null,
  value text not null,
  href text,
  sort_order integer not null default 0,
  archived_at timestamptz
);

create table public.footer_links (
  id uuid primary key default gen_random_uuid(),
  label_vi text not null,
  label_en text not null,
  href text not null,
  sort_order integer not null default 0,
  archived_at timestamptz
);

create table public.media (
  id uuid primary key default gen_random_uuid(),
  kind text not null default 'gallery' check (kind in ('gallery', 'hero', 'logo', 'content')),
  storage_path text not null unique,
  title_vi text not null default '',
  title_en text not null default '',
  alt_vi text not null default '',
  alt_en text not null default '',
  filter_tag text not null default 'all',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.sports (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name_vi text not null,
  name_en text not null,
  emoji text not null,
  description_vi text not null default '',
  description_en text not null default '',
  rules_vi text not null default '',
  rules_en text not null default '',
  sort_order integer not null default 0,
  archived_at timestamptz
);

create table public.tournaments (
  id uuid primary key default gen_random_uuid(),
  sport_id uuid not null references public.sports(id),
  slug text not null,
  name_vi text not null,
  name_en text not null,
  category_vi text not null default '',
  category_en text not null default '',
  gender text not null default 'mixed' check (gender in ('male', 'female', 'mixed', 'open')),
  format_vi text not null default '',
  format_en text not null default '',
  rules_vi text not null default '',
  rules_en text not null default '',
  sort_order integer not null default 0,
  archived_at timestamptz,
  unique (sport_id, slug)
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_vi text not null,
  name_en text not null,
  logo_path text,
  sort_order integer not null default 0,
  archived_at timestamptz
);

create table public.participants (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id),
  full_name text not null,
  full_name_en text,
  gender text check (gender in ('male', 'female', 'other')),
  birth_date date,
  archived_at timestamptz
);

create table public.entries (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id),
  organization_id uuid references public.organizations(id),
  kind text not null check (kind in ('individual', 'pair', 'team')),
  name_vi text not null,
  name_en text not null,
  seed_number integer check (seed_number is null or seed_number > 0),
  bib_number text,
  archived_at timestamptz
);

create table public.entry_members (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references public.entries(id),
  participant_id uuid not null references public.participants(id),
  role_vi text not null default 'Vận động viên',
  role_en text not null default 'Athlete',
  sort_order integer not null default 0,
  archived_at timestamptz,
  unique (entry_id, participant_id)
);

create table public.venues (
  id uuid primary key default gen_random_uuid(),
  name_vi text not null,
  name_en text not null,
  address_vi text not null default '',
  address_en text not null default '',
  sort_order integer not null default 0,
  archived_at timestamptz
);

create table public.courts (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues(id),
  name_vi text not null,
  name_en text not null,
  sort_order integer not null default 0,
  archived_at timestamptz,
  unique (venue_id, name_vi)
);

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id),
  name_vi text not null,
  name_en text not null,
  sort_order integer not null default 0,
  archived_at timestamptz,
  unique (tournament_id, name_vi)
);

create table public.group_entries (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id),
  entry_id uuid not null references public.entries(id),
  seed_order integer,
  archived_at timestamptz,
  unique (group_id, entry_id)
);

create table public.fixtures (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id),
  group_id uuid references public.groups(id),
  venue_id uuid references public.venues(id),
  court_id uuid references public.courts(id),
  starts_at timestamptz,
  ends_at timestamptz,
  status text not null default 'scheduled' check (status in ('scheduled', 'live', 'completed', 'postponed', 'cancelled')),
  round_vi text not null default '',
  round_en text not null default '',
  round_order integer,
  bracket_position integer,
  next_fixture_id uuid references public.fixtures(id),
  result_summary_vi text not null default '',
  result_summary_en text not null default '',
  winner_entry_id uuid references public.entries(id),
  archived_at timestamptz
);

create table public.fixture_entries (
  id uuid primary key default gen_random_uuid(),
  fixture_id uuid not null references public.fixtures(id),
  entry_id uuid not null references public.entries(id),
  side text check (side in ('home', 'away')),
  lane integer,
  seed_order integer,
  score text,
  score_numeric numeric,
  rank integer,
  result_detail jsonb not null default '{}'::jsonb,
  archived_at timestamptz,
  unique (fixture_id, entry_id)
);

create table public.standings (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id),
  group_id uuid references public.groups(id),
  entry_id uuid not null references public.entries(id),
  played integer not null default 0 check (played >= 0),
  won integer not null default 0 check (won >= 0),
  drawn integer not null default 0 check (drawn >= 0),
  lost integer not null default 0 check (lost >= 0),
  score_for numeric not null default 0,
  score_against numeric not null default 0,
  points numeric not null default 0,
  rank integer check (rank is null or rank > 0),
  note_vi text not null default '',
  note_en text not null default '',
  archived_at timestamptz,
  unique (tournament_id, group_id, entry_id)
);

create table public.awards (
  id uuid primary key default gen_random_uuid(),
  sport_id uuid references public.sports(id),
  tournament_id uuid references public.tournaments(id),
  entry_id uuid references public.entries(id),
  participant_id uuid references public.participants(id),
  organization_id uuid references public.organizations(id),
  title_vi text not null,
  title_en text not null,
  medal text not null default 'special' check (medal in ('gold', 'silver', 'bronze', 'special')),
  sort_order integer not null default 0,
  archived_at timestamptz
);

create table public.source_documents (
  id uuid primary key default gen_random_uuid(),
  raw_filename text not null unique,
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  page_count integer not null check (page_count > 0),
  sport_slug text,
  imported boolean not null default false,
  notes text not null default '',
  reviewed_at timestamptz,
  archived_at timestamptz
);

create index tournaments_sport_id_idx on public.tournaments (sport_id);
create index participants_organization_id_idx on public.participants (organization_id);
create index entries_tournament_id_idx on public.entries (tournament_id);
create index entries_organization_id_idx on public.entries (organization_id);
create index entry_members_entry_id_idx on public.entry_members (entry_id);
create index entry_members_participant_id_idx on public.entry_members (participant_id);
create index courts_venue_id_idx on public.courts (venue_id);
create index groups_tournament_id_idx on public.groups (tournament_id);
create index group_entries_group_id_idx on public.group_entries (group_id);
create index group_entries_entry_id_idx on public.group_entries (entry_id);
create index fixtures_tournament_start_idx on public.fixtures (tournament_id, starts_at);
create index fixtures_group_id_idx on public.fixtures (group_id);
create index fixtures_venue_id_idx on public.fixtures (venue_id);
create index fixtures_court_id_idx on public.fixtures (court_id);
create index fixtures_next_fixture_id_idx on public.fixtures (next_fixture_id);
create index fixtures_winner_entry_id_idx on public.fixtures (winner_entry_id);
create index fixture_entries_fixture_id_idx on public.fixture_entries (fixture_id);
create index fixture_entries_entry_id_idx on public.fixture_entries (entry_id);
create index standings_tournament_rank_idx on public.standings (tournament_id, rank);
create index standings_group_id_idx on public.standings (group_id);
create index standings_entry_id_idx on public.standings (entry_id);
create index awards_sport_id_idx on public.awards (sport_id);
create index awards_tournament_id_idx on public.awards (tournament_id);
create index awards_entry_id_idx on public.awards (entry_id);
create index awards_participant_id_idx on public.awards (participant_id);
create index awards_organization_id_idx on public.awards (organization_id);
create index archived_sports_idx on public.sports (sort_order) where archived_at is null;
create index archived_fixtures_idx on public.fixtures (starts_at) where archived_at is null;
create index admin_users_active_idx on public.admin_users (user_id) where archived_at is null;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = (select auth.uid()) and archived_at is null
  );
$$;

revoke all on schema private from public;
grant usage on schema private to authenticated;
revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated;

alter table public.admin_users enable row level security;
create policy admin_users_read_self on public.admin_users
  for select to authenticated
  using (user_id = (select auth.uid()));

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'event_settings', 'contacts', 'footer_links', 'media', 'sports', 'tournaments',
    'organizations', 'participants', 'entries', 'entry_members', 'venues', 'courts',
    'groups', 'group_entries', 'fixtures', 'fixture_entries', 'standings', 'awards',
    'source_documents'
  ] loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('create policy %I on public.%I for select to anon using (archived_at is null)', table_name || '_public_read', table_name);
    execute format('create policy %I on public.%I for select to authenticated using ((select private.is_admin()))', table_name || '_admin_read', table_name);
    execute format('create policy %I on public.%I for insert to authenticated with check ((select private.is_admin()))', table_name || '_admin_insert', table_name);
    execute format('create policy %I on public.%I for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()))', table_name || '_admin_update', table_name);
    execute format('grant select on public.%I to anon, authenticated', table_name);
    execute format('grant insert, update on public.%I to authenticated', table_name);
  end loop;
end $$;

grant select on public.admin_users to authenticated;
revoke delete on all tables in schema public from anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('event-media', 'event-media', true, 10485760, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy event_media_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'event-media');

create policy event_media_admin_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'event-media' and (select private.is_admin()));

create policy event_media_admin_update on storage.objects
  for update to authenticated
  using (bucket_id = 'event-media' and (select private.is_admin()))
  with check (bucket_id = 'event-media' and (select private.is_admin()));
