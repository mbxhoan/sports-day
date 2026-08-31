create table public.sport_excel_exports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  sport_id uuid not null references public.sports(id),
  template_version integer not null,
  mode text not null check (mode in ('current', 'blank')),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.sport_excel_imports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  sport_id uuid not null references public.sports(id),
  export_id uuid not null references public.sport_excel_exports(id),
  template_version integer not null,
  mode text not null check (mode in ('current', 'blank')),
  file_sha256 text not null check (file_sha256 ~ '^[0-9a-f]{64}$'),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  preview jsonb not null default '{}'::jsonb check (jsonb_typeof(preview) = 'object'),
  status text not null default 'prepared' check (status in ('prepared', 'applied', 'rolled_back', 'rejected')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  applied_at timestamptz,
  rolled_back_at timestamptz,
  before_snapshot jsonb,
  after_snapshot jsonb,
  error_message text
);

create table public.sport_excel_changes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  import_id uuid not null references public.sport_excel_imports(id),
  table_name text not null,
  row_id uuid not null,
  action text not null check (action in ('insert', 'update', 'archive')),
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create index sport_excel_exports_tenant_sport_idx on public.sport_excel_exports (tenant_id, sport_id, created_at desc);
create index sport_excel_imports_tenant_sport_idx on public.sport_excel_imports (tenant_id, sport_id, created_at desc);
create index sport_excel_changes_import_idx on public.sport_excel_changes (tenant_id, import_id, table_name, row_id);

alter table public.sport_excel_exports enable row level security;
alter table public.sport_excel_imports enable row level security;
alter table public.sport_excel_changes enable row level security;

create policy sport_excel_exports_admin_read on public.sport_excel_exports
  for select to authenticated
  using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));
create policy sport_excel_exports_admin_insert on public.sport_excel_exports
  for insert to authenticated
  with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)) and created_by = (select auth.uid()));
create policy sport_excel_exports_admin_update on public.sport_excel_exports
  for update to authenticated
  using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)))
  with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));

create policy sport_excel_imports_admin_read on public.sport_excel_imports
  for select to authenticated
  using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));
create policy sport_excel_imports_admin_insert on public.sport_excel_imports
  for insert to authenticated
  with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)) and created_by = (select auth.uid()));
create policy sport_excel_imports_admin_update on public.sport_excel_imports
  for update to authenticated
  using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)))
  with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));

create policy sport_excel_changes_admin_read on public.sport_excel_changes
  for select to authenticated
  using (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));
create policy sport_excel_changes_admin_insert on public.sport_excel_changes
  for insert to authenticated
  with check (tenant_id = (select private.current_tenant_id()) and (select private.is_admin(tenant_id)));

grant select, insert, update on public.sport_excel_exports, public.sport_excel_imports to authenticated;
grant select, insert on public.sport_excel_changes to authenticated;
revoke delete on public.sport_excel_exports, public.sport_excel_imports, public.sport_excel_changes from anon, authenticated;

create or replace function private.sport_excel_snapshot(p_tenant_id uuid, p_sport_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  sport_row public.sports%rowtype;
  tournament_ids uuid[];
  snapshot jsonb;
begin
  select * into sport_row
  from public.sports
  where id = p_sport_id and tenant_id = p_tenant_id and archived_at is null;
  if not found then raise exception 'Không tìm thấy môn thể thao'; end if;

  select coalesce(array_agg(tournament.id), '{}'::uuid[]) into tournament_ids
  from public.tournaments tournament
  where tournament.tenant_id = p_tenant_id
    and tournament.sport_id = p_sport_id
    and tournament.archived_at is null;

  select jsonb_build_object(
    'sport_id', p_sport_id,
    'sport_slug', sport_row.slug,
    'tables', jsonb_build_object(
      'sports', jsonb_build_array(to_jsonb(sport_row)),
      'tournaments', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.tournaments item where item.id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'organizations', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.organizations item where item.tenant_id = p_tenant_id and item.archived_at is null), '[]'::jsonb),
      'participants', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.participants item where item.tenant_id = p_tenant_id and item.archived_at is null), '[]'::jsonb),
      'entries', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.entries item join public.tournaments parent on parent.id = item.tournament_id where item.tenant_id = p_tenant_id and item.tournament_id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'entry_members', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.entry_members item join public.entries parent on parent.id = item.entry_id where item.tenant_id = p_tenant_id and parent.tournament_id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'venues', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.venues item where item.tenant_id = p_tenant_id and item.archived_at is null), '[]'::jsonb),
      'courts', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.courts item where item.tenant_id = p_tenant_id and item.archived_at is null), '[]'::jsonb),
      'groups', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.groups item where item.tenant_id = p_tenant_id and item.tournament_id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'group_entries', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.group_entries item join public.groups parent on parent.id = item.group_id where item.tenant_id = p_tenant_id and parent.tournament_id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'fixtures', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.fixtures item where item.tenant_id = p_tenant_id and item.tournament_id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'fixture_entries', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.fixture_entries item join public.fixtures parent on parent.id = item.fixture_id where item.tenant_id = p_tenant_id and parent.tournament_id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'fixture_slots', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.fixture_slots item join public.fixtures parent on parent.id = item.fixture_id where item.tenant_id = p_tenant_id and parent.tournament_id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'standings', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.standings item where item.tenant_id = p_tenant_id and item.tournament_id = any(tournament_ids) and item.archived_at is null), '[]'::jsonb),
      'awards', coalesce((select jsonb_agg(to_jsonb(item) order by item.id) from public.awards item where item.tenant_id = p_tenant_id and (item.sport_id = p_sport_id or item.tournament_id = any(tournament_ids) or item.entry_id in (select entry.id from public.entries entry where entry.tournament_id = any(tournament_ids)) or item.participant_id in (select member.participant_id from public.entry_members member join public.entries entry on entry.id = member.entry_id where entry.tournament_id = any(tournament_ids))) and item.archived_at is null), '[]'::jsonb)
    )
  ) into snapshot;
  return snapshot;
end;
$$;

revoke all on function private.sport_excel_snapshot(uuid, uuid) from public;
grant execute on function private.sport_excel_snapshot(uuid, uuid) to authenticated;

create or replace function private.sport_excel_columns(p_table text)
returns text[]
language sql
immutable
set search_path = ''
as $$
  select case p_table
    when 'sports' then array['slug','name_vi','name_en','emoji','description_vi','description_en','rules_vi','rules_en','sort_order']
    when 'tournaments' then array['sport_id','slug','name_vi','name_en','category_vi','category_en','gender','format_vi','format_en','rules_vi','rules_en','competition_mode','source_metadata','scoring_rule','sort_order']
    when 'organizations' then array['code','name_vi','name_en','logo_path','leaderboard_rank','gold_medals','silver_medals','bronze_medals','sort_order']
    when 'participants' then array['organization_id','full_name','full_name_en','gender','birth_date']
    when 'entries' then array['tournament_id','organization_id','kind','name_vi','name_en','seed_number','bib_number']
    when 'entry_members' then array['entry_id','participant_id','role_vi','role_en','sort_order']
    when 'venues' then array['name_vi','name_en','address_vi','address_en','sort_order']
    when 'courts' then array['venue_id','name_vi','name_en','sort_order']
    when 'groups' then array['tournament_id','name_vi','name_en','sort_order']
    when 'group_entries' then array['group_id','entry_id','seed_order']
    when 'fixtures' then array['tournament_id','group_id','venue_id','court_id','starts_at','ends_at','status','round_vi','round_en','round_order','bracket_position','next_fixture_id','result_summary_vi','result_summary_en','winner_entry_id','source_code']
    when 'fixture_entries' then array['fixture_id','entry_id','side','lane','seed_order','score','score_numeric','rank','result_status','result_detail']
    when 'fixture_slots' then array['fixture_id','side','source_kind','source_entry_id','source_group_id','source_fixture_id','source_rank','label_vi','label_en']
    when 'standings' then array['tournament_id','group_id','entry_id','played','won','drawn','lost','score_for','score_against','points','rank','note_vi','note_en']
    when 'awards' then array['sport_id','tournament_id','entry_id','participant_id','organization_id','title_vi','title_en','medal','sort_order']
    else null
  end;
$$;

create or replace function private.sport_excel_relation_columns(p_table text)
returns text[]
language sql
immutable
set search_path = ''
as $$
  select case p_table
    when 'tournaments' then array['sport_id']
    when 'participants' then array['organization_id']
    when 'entries' then array['tournament_id','organization_id']
    when 'entry_members' then array['entry_id','participant_id']
    when 'courts' then array['venue_id']
    when 'groups' then array['tournament_id']
    when 'group_entries' then array['group_id','entry_id']
    when 'fixtures' then array['tournament_id','group_id','venue_id','court_id','next_fixture_id','winner_entry_id']
    when 'fixture_entries' then array['fixture_id','entry_id']
    when 'fixture_slots' then array['fixture_id','source_entry_id','source_group_id','source_fixture_id']
    when 'standings' then array['tournament_id','group_id','entry_id']
    when 'awards' then array['sport_id','tournament_id','entry_id','participant_id','organization_id']
    else array[]::text[]
  end;
$$;

create or replace function private.sport_excel_parent_table(p_table text, p_column text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_column
    when 'sport_id' then 'sports'
    when 'tournament_id' then 'tournaments'
    when 'organization_id' then 'organizations'
    when 'participant_id' then 'participants'
    when 'entry_id' then 'entries'
    when 'venue_id' then 'venues'
    when 'court_id' then 'courts'
    when 'group_id' then 'groups'
    when 'fixture_id' then 'fixtures'
    when 'next_fixture_id' then 'fixtures'
    when 'winner_entry_id' then 'entries'
    when 'source_entry_id' then 'entries'
    when 'source_group_id' then 'groups'
    when 'source_fixture_id' then 'fixtures'
    else null
  end;
$$;

create or replace function private.sport_excel_resolve_data(p_table text, p_data jsonb, p_refs jsonb)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  column_name text;
  raw_value text;
  resolved_value text;
  parent_table text;
  output jsonb := p_data;
begin
  foreach column_name in array private.sport_excel_relation_columns(p_table) loop
    raw_value := output ->> column_name;
    if raw_value is null or raw_value = '' then continue; end if;
    if left(raw_value, 6) = '@ref:' then
      parent_table := private.sport_excel_parent_table(p_table, column_name);
      resolved_value := p_refs ->> (parent_table || ':' || substring(raw_value from 6));
      if resolved_value is null then raise exception 'Không tìm thấy liên kết mới %', substring(raw_value from 6); end if;
      output := jsonb_set(output, array[column_name], to_jsonb(resolved_value), true);
    end if;
  end loop;
  return output;
end;
$$;

revoke all on function private.sport_excel_resolve_data(text, jsonb, jsonb) from public;
grant execute on function private.sport_excel_resolve_data(text, jsonb, jsonb) to authenticated;

create or replace function private.sport_excel_write_row(p_table text, p_id uuid, p_tenant_id uuid, p_data jsonb, p_archive boolean default false, p_excluded text[] default array[]::text[])
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  columns text[] := private.sport_excel_columns(p_table);
  included text[];
  column_name text;
  set_clause text := '';
  row_exists boolean;
begin
  if columns is null then raise exception 'Bảng Excel không được phép'; end if;
  select coalesce(array_agg(item), '{}'::text[]) into included from unnest(columns) item where not (item = any(p_excluded));
  foreach column_name in array included loop
    set_clause := set_clause || case when set_clause = '' then '' else ', ' end || format('%I = source.%I', column_name, column_name);
  end loop;
  if p_archive then
    execute format('update public.%I set archived_at = now() where id = $1 and tenant_id = $2', p_table) using p_id, p_tenant_id;
  elsif p_id is null then
    execute format('insert into public.%I (tenant_id, %s) select $1, %s from jsonb_populate_record(null::public.%I, $2) source', p_table, array_to_string(columns, ', '), array_to_string(columns, ', '), p_table) using p_tenant_id, p_data;
  else
    execute format('select exists (select 1 from public.%I where id = $1 and tenant_id = $2)', p_table) into row_exists using p_id, p_tenant_id;
    if not row_exists then
      execute format('insert into public.%I (id, tenant_id, %s) select $1, $2, %s from jsonb_populate_record(null::public.%I, $3) source', p_table, array_to_string(columns, ', '), array_to_string(columns, ', '), p_table) using p_id, p_tenant_id, p_data;
    elsif set_clause <> '' then
      set_clause := set_clause || ', archived_at = null';
      execute format('update public.%I target set %s from jsonb_populate_record(null::public.%I, $1) source where target.id = $2 and target.tenant_id = $3', p_table, set_clause, p_table) using p_data, p_id, p_tenant_id;
    end if;
  end if;
end;
$$;

revoke all on function private.sport_excel_write_row(text, uuid, uuid, jsonb, boolean, text[]) from public;
grant execute on function private.sport_excel_write_row(text, uuid, uuid, jsonb, boolean, text[]) to authenticated;

create or replace function private.sport_excel_archive_dependency(p_table text, p_id uuid, p_tenant_id uuid)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  details text;
begin
  if p_table = 'sports' then
    if exists (select 1 from public.tournaments where tenant_id = p_tenant_id and sport_id = p_id and archived_at is null) then details := 'tournaments'; end if;
  elsif p_table = 'organizations' then
    select string_agg(format('%s=%s', child_name, child_count), ', ') into details from (values
      ('participants', (select count(*) from public.participants where tenant_id = p_tenant_id and organization_id = p_id and archived_at is null)),
      ('entries', (select count(*) from public.entries where tenant_id = p_tenant_id and organization_id = p_id and archived_at is null)),
      ('awards', (select count(*) from public.awards where tenant_id = p_tenant_id and organization_id = p_id and archived_at is null))
    ) as dependency(child_name, child_count) where child_count > 0;
  elsif p_table = 'participants' then
    select string_agg(format('%s=%s', child_name, child_count), ', ') into details from (values
      ('entry_members', (select count(*) from public.entry_members where tenant_id = p_tenant_id and participant_id = p_id and archived_at is null)),
      ('awards', (select count(*) from public.awards where tenant_id = p_tenant_id and participant_id = p_id and archived_at is null))
    ) as dependency(child_name, child_count) where child_count > 0;
  elsif p_table = 'tournaments' then
    select string_agg(format('%s=%s', child_name, child_count), ', ') into details from (values
      ('entries', (select count(*) from public.entries where tenant_id = p_tenant_id and tournament_id = p_id and archived_at is null)),
      ('groups', (select count(*) from public.groups where tenant_id = p_tenant_id and tournament_id = p_id and archived_at is null)),
      ('fixtures', (select count(*) from public.fixtures where tenant_id = p_tenant_id and tournament_id = p_id and archived_at is null)),
      ('standings', (select count(*) from public.standings where tenant_id = p_tenant_id and tournament_id = p_id and archived_at is null)),
      ('awards', (select count(*) from public.awards where tenant_id = p_tenant_id and tournament_id = p_id and archived_at is null))
    ) as dependency(child_name, child_count) where child_count > 0;
  elsif p_table = 'entries' then
    select string_agg(format('%s=%s', child_name, child_count), ', ') into details from (values
      ('entry_members', (select count(*) from public.entry_members where tenant_id = p_tenant_id and entry_id = p_id and archived_at is null)),
      ('group_entries', (select count(*) from public.group_entries where tenant_id = p_tenant_id and entry_id = p_id and archived_at is null)),
      ('fixture_entries', (select count(*) from public.fixture_entries where tenant_id = p_tenant_id and entry_id = p_id and archived_at is null)),
      ('standings', (select count(*) from public.standings where tenant_id = p_tenant_id and entry_id = p_id and archived_at is null)),
      ('awards', (select count(*) from public.awards where tenant_id = p_tenant_id and entry_id = p_id and archived_at is null))
    ) as dependency(child_name, child_count) where child_count > 0;
  elsif p_table = 'venues' then
    select string_agg(format('courts=%s, fixtures=%s', (select count(*) from public.courts where tenant_id = p_tenant_id and venue_id = p_id and archived_at is null), (select count(*) from public.fixtures where tenant_id = p_tenant_id and venue_id = p_id and archived_at is null)), ', ') into details where exists (select 1 from public.courts where tenant_id = p_tenant_id and venue_id = p_id and archived_at is null) or exists (select 1 from public.fixtures where tenant_id = p_tenant_id and venue_id = p_id and archived_at is null);
  elsif p_table = 'courts' then
    if exists (select 1 from public.fixtures where tenant_id = p_tenant_id and court_id = p_id and archived_at is null) then details := 'fixtures'; end if;
  elsif p_table = 'groups' then
    select string_agg(format('%s=%s', child_name, child_count), ', ') into details from (values
      ('group_entries', (select count(*) from public.group_entries where tenant_id = p_tenant_id and group_id = p_id and archived_at is null)),
      ('fixtures', (select count(*) from public.fixtures where tenant_id = p_tenant_id and group_id = p_id and archived_at is null)),
      ('standings', (select count(*) from public.standings where tenant_id = p_tenant_id and group_id = p_id and archived_at is null)),
      ('fixture_slots', (select count(*) from public.fixture_slots where tenant_id = p_tenant_id and source_group_id = p_id and archived_at is null))
    ) as dependency(child_name, child_count) where child_count > 0;
  elsif p_table = 'fixtures' then
    select string_agg(format('%s=%s', child_name, child_count), ', ') into details from (values
      ('fixture_entries', (select count(*) from public.fixture_entries where tenant_id = p_tenant_id and fixture_id = p_id and archived_at is null)),
      ('fixture_slots', (select count(*) from public.fixture_slots where tenant_id = p_tenant_id and fixture_id = p_id and archived_at is null)),
      ('next_fixtures', (select count(*) from public.fixtures where tenant_id = p_tenant_id and next_fixture_id = p_id and archived_at is null))
    ) as dependency(child_name, child_count) where child_count > 0;
  end if;
  return details;
end;
$$;

revoke all on function private.sport_excel_archive_dependency(text, uuid, uuid) from public;
grant execute on function private.sport_excel_archive_dependency(text, uuid, uuid) to authenticated;

create or replace function public.create_sport_excel_export(p_sport_id uuid, p_mode text default 'current', p_template_version integer default 1)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_tenant_id uuid := (select private.current_tenant_id());
  snapshot jsonb;
  export_id uuid;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  if p_mode not in ('current', 'blank') then raise exception 'Chế độ export không hợp lệ'; end if;
  if p_template_version <> 1 then raise exception 'Phiên bản template không được hỗ trợ'; end if;
  snapshot := private.sport_excel_snapshot(v_tenant_id, p_sport_id);
  insert into public.sport_excel_exports (tenant_id, sport_id, template_version, mode, payload, created_by)
  values (v_tenant_id, p_sport_id, p_template_version, p_mode, snapshot, (select auth.uid()))
  returning id into export_id;
  return jsonb_build_object('export_id', export_id, 'snapshot', snapshot);
end;
$$;

revoke execute on function public.create_sport_excel_export(uuid, text, integer) from public, anon;
grant execute on function public.create_sport_excel_export(uuid, text, integer) to authenticated;

create or replace function public.prepare_sport_excel_import(p_sport_id uuid, p_export_id uuid, p_template_version integer, p_mode text, p_file_sha256 text, p_payload jsonb, p_preview jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_tenant_id uuid := (select private.current_tenant_id());
  export_row public.sport_excel_exports%rowtype;
  import_id uuid;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  if p_template_version <> 1 or p_mode not in ('current', 'blank') or p_file_sha256 !~ '^[0-9a-f]{64}$' then raise exception 'Thông tin import không hợp lệ'; end if;
  select * into export_row from public.sport_excel_exports export_item where export_item.id = p_export_id and export_item.tenant_id = v_tenant_id and export_item.sport_id = p_sport_id and export_item.archived_at is null for update;
  if not found or export_row.mode is distinct from p_mode then raise exception 'Snapshot export không hợp lệ'; end if;
  if jsonb_typeof(p_payload) <> 'object' or jsonb_typeof(p_payload->'operations') <> 'array' or pg_column_size(p_payload) > 10 * 1024 * 1024 or jsonb_array_length(p_payload->'operations') > 20000 then raise exception 'Payload import không hợp lệ hoặc vượt giới hạn'; end if;
  insert into public.sport_excel_imports (tenant_id, sport_id, export_id, template_version, mode, file_sha256, payload, preview, created_by)
  values (v_tenant_id, p_sport_id, p_export_id, p_template_version, p_mode, p_file_sha256, p_payload, coalesce(p_preview, '{}'::jsonb), (select auth.uid()))
  returning id into import_id;
  return jsonb_build_object('import_id', import_id, 'preview', coalesce(p_preview, '{}'::jsonb));
end;
$$;

revoke execute on function public.prepare_sport_excel_import(uuid, uuid, integer, text, text, jsonb, jsonb) from public, anon;
grant execute on function public.prepare_sport_excel_import(uuid, uuid, integer, text, text, jsonb, jsonb) to authenticated;

create or replace function public.apply_sport_excel_import(p_import_id uuid, p_confirm boolean default false)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_tenant_id uuid := (select private.current_tenant_id());
  import_row public.sport_excel_imports%rowtype;
  export_row public.sport_excel_exports%rowtype;
  v_before_snapshot jsonb;
  v_after_snapshot jsonb;
  operations jsonb := '[]'::jsonb;
  new_refs jsonb := '{}'::jsonb;
  resolved_ops jsonb := '[]'::jsonb;
  op jsonb;
  data jsonb;
  base_data jsonb;
  table_name text;
  row_ref text;
  action text;
  row_id uuid;
  current_data jsonb;
  relation_column text;
  relation_table text;
  relation_tenant uuid;
  relation_active boolean;
  dependency text;
  set_data jsonb;
  touched_fixtures jsonb := '{}'::jsonb;
  standing_groups jsonb := '{}'::jsonb;
  v_fixture_id uuid;
  fixture_state record;
  fixture_entries jsonb;
  desired_status text;
  desired_winner uuid;
  desired_summary_vi text;
  desired_summary_en text;
  result_op_found boolean;
  standing_key text;
  standing_tournament uuid;
  standing_group uuid;
  standing_rows jsonb;
  item jsonb;
  change_before jsonb;
  change_after jsonb;
  table_order text[] := array['organizations','participants','tournaments','entries','entry_members','venues','courts','groups','group_entries','fixture_entries','fixtures','awards'];
  table_name_loop text;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  select * into import_row from public.sport_excel_imports import_item where import_item.id = p_import_id and import_item.tenant_id = v_tenant_id for update;
  if not found then raise exception 'Không tìm thấy import'; end if;
  if import_row.status <> 'prepared' then raise exception 'Import không còn ở trạng thái chờ áp dụng'; end if;
  if not p_confirm and coalesce(jsonb_array_length(import_row.preview->'warnings'), 0) > 0 then raise exception 'Cần xác nhận các cảnh báo trước khi áp dụng'; end if;
  if coalesce(jsonb_array_length(import_row.preview->'blockers'), 0) > 0 then raise exception 'Import còn lỗi chặn'; end if;
  select * into export_row from public.sport_excel_exports export_item where export_item.id = import_row.export_id and export_item.tenant_id = v_tenant_id and export_item.sport_id = import_row.sport_id and export_item.archived_at is null for update;
  if not found then raise exception 'Snapshot export không tồn tại'; end if;
  operations := import_row.payload->'operations';

  v_before_snapshot := private.sport_excel_snapshot(v_tenant_id, import_row.sport_id);

  for op in select value from jsonb_array_elements(operations) value loop
    table_name := op->>'table'; row_ref := op->>'ref'; action := op->>'action';
    if private.sport_excel_columns(table_name) is null then raise exception 'Bảng Excel không được phép'; end if;
    if action not in ('UPDATE','UPSERT','ARCHIVE') then raise exception 'Thao tác Excel không hợp lệ'; end if;
    if op->>'id' is null or op->>'id' = '' then
      if action <> 'UPSERT' or not left(row_ref, 4) = 'NEW-' then raise exception 'Dòng mới phải dùng mã NEW-* và UPSERT'; end if;
      if new_refs ? (table_name || ':' || row_ref) then raise exception 'Mã dòng mới bị trùng'; end if;
      new_refs := jsonb_set(new_refs, array[table_name || ':' || row_ref], to_jsonb(gen_random_uuid()::text), true);
    else
      row_id := (op->>'id')::uuid;
      if not exists (select 1 from jsonb_array_elements(export_row.payload->'tables'->table_name) exported where exported->>'id' = row_id::text) then raise exception 'Dòng không thuộc snapshot export: %', row_ref; end if;
      execute format('select to_jsonb(item) from public.%I item where item.id = $1 and item.tenant_id = $2', table_name) into current_data using row_id, v_tenant_id;
      if current_data is distinct from op->'base' then raise exception 'Dữ liệu đã thay đổi từ lúc export: %', row_ref; end if;
    end if;
  end loop;

  for op in select value from jsonb_array_elements(operations) value loop
    table_name := op->>'table'; row_ref := op->>'ref'; action := op->>'action';
    if op->>'id' is null or op->>'id' = '' then row_id := (new_refs ->> (table_name || ':' || row_ref))::uuid; else row_id := (op->>'id')::uuid; end if;
    data := private.sport_excel_resolve_data(table_name, op->'data', new_refs);
    foreach relation_column in array private.sport_excel_relation_columns(table_name) loop
      if data ->> relation_column is null or data ->> relation_column = '' then continue; end if;
      relation_table := private.sport_excel_parent_table(table_name, relation_column);
      execute format('select tenant_id, archived_at is null from public.%I where id = $1', relation_table) into relation_tenant, relation_active using (data ->> relation_column)::uuid;
      if relation_tenant is distinct from v_tenant_id or not coalesce(relation_active, false) then raise exception 'Liên kết không hợp lệ tại %', row_ref; end if;
    end loop;
    if action = 'ARCHIVE' then
      dependency := private.sport_excel_archive_dependency(table_name, row_id, v_tenant_id);
      if dependency is not null then raise exception 'Không thể lưu trữ % vì còn dữ liệu phụ thuộc: %', row_ref, dependency; end if;
    end if;
    if table_name = 'organizations' and ((data->>'leaderboard_rank' is not null and (data->>'leaderboard_rank')::integer < 1) or coalesce((data->>'gold_medals')::integer, 0) < 0 or coalesce((data->>'silver_medals')::integer, 0) < 0 or coalesce((data->>'bronze_medals')::integer, 0) < 0) then raise exception 'Hạng hoặc huy chương không hợp lệ tại %', row_ref; end if;
    if table_name = 'entries' and data->>'seed_number' is not null and (data->>'seed_number')::integer < 1 then raise exception 'Seed không hợp lệ tại %', row_ref; end if;
    if table_name = 'fixture_entries' and ((data->>'lane' is not null and (data->>'lane')::integer < 1) or (data->>'rank' is not null and (data->>'rank')::integer < 1) or (data->>'seed_order' is not null and (data->>'seed_order')::integer < 1) or (data->>'score_numeric' is not null and (data->>'score_numeric')::numeric < 0)) then raise exception 'Làn, hạng, seed hoặc điểm trận không hợp lệ tại %', row_ref; end if;
    if table_name = 'fixture_slots' then raise exception 'NGUỒN_NHÁNH chỉ đọc trong Excel'; end if;
    if table_name = 'fixtures' and op->>'id' is not null and data->>'source_code' is distinct from op->'base'->>'source_code' then raise exception 'Không được đổi mã nguồn trận: %', row_ref; end if;
    if table_name = 'fixture_entries' and op->>'id' is not null and exists (select 1 from public.fixture_slots slot where slot.fixture_id = (data->>'fixture_id')::uuid and slot.archived_at is null) and (data->>'entry_id' is distinct from op->'base'->>'entry_id' or data->>'side' is distinct from op->'base'->>'side') then raise exception 'Không được đổi đội/side của trận có nguồn nhánh: %', row_ref; end if;
    set_data := jsonb_set(op, array['data'], data, true);
    set_data := jsonb_set(set_data, array['id'], to_jsonb(row_id::text), true);
    set_data := jsonb_set(set_data, array['is_new'], to_jsonb((op->>'id') is null), true);
    resolved_ops := resolved_ops || jsonb_build_array(set_data);
    if table_name = 'standings' then
      standing_key := (data->>'tournament_id') || ':' || coalesce(data->>'group_id', '');
      standing_groups := jsonb_set(standing_groups, array[standing_key], 'true'::jsonb, true);
    elsif table_name = 'fixtures' and (op->>'id' is null or data->>'status' is distinct from op->'base'->>'status' or data->>'winner_entry_id' is distinct from op->'base'->>'winner_entry_id' or data->>'result_summary_vi' is distinct from op->'base'->>'result_summary_vi' or data->>'result_summary_en' is distinct from op->'base'->>'result_summary_en') then
      touched_fixtures := jsonb_set(touched_fixtures, array[row_id::text], 'true'::jsonb, true);
    elsif table_name = 'fixture_entries' then
      touched_fixtures := jsonb_set(touched_fixtures, array[(data->>'fixture_id')], 'true'::jsonb, true);
    end if;
  end loop;

  for table_name_loop in select unnest(table_order) loop
    for op in select value from jsonb_array_elements(resolved_ops) value where value->>'table' = table_name_loop loop
      table_name := op->>'table'; action := op->>'action'; row_id := (op->>'id')::uuid; data := op->'data';
      if table_name = 'standings' then continue; end if;
      if action = 'ARCHIVE' then perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, data, true); continue; end if;
      if table_name = 'fixtures' and op->>'is_new' <> 'true' and (touched_fixtures ? row_id::text) then
        perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, data, false, array['status','winner_entry_id','result_summary_vi','result_summary_en']);
      elsif table_name = 'fixtures' and op->>'is_new' <> 'true' then
        perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, data, false);
      elsif table_name = 'fixtures' then
        set_data := jsonb_set(data, array['status'], to_jsonb('scheduled'::text), true);
        set_data := jsonb_set(set_data, array['winner_entry_id'], 'null'::jsonb, true);
        set_data := jsonb_set(set_data, array['result_summary_vi'], to_jsonb(''::text), true);
        set_data := jsonb_set(set_data, array['result_summary_en'], to_jsonb(''::text), true);
        perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, set_data, false);
      else
        perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, data, false);
      end if;
    end loop;
  end loop;

  for standing_key in select jsonb_object_keys(standing_groups) loop
    standing_tournament := split_part(standing_key, ':', 1)::uuid;
    standing_group := nullif(split_part(standing_key, ':', 2), '')::uuid;
    select coalesce(jsonb_agg(jsonb_build_object('entry_id', item.entry_id, 'played', item.played, 'won', item.won, 'drawn', item.drawn, 'lost', item.lost, 'score_for', item.score_for, 'score_against', item.score_against, 'points', item.points, 'rank', item.rank) order by item.id), '[]'::jsonb) into standing_rows
    from public.standings item
    where item.tenant_id = v_tenant_id and item.tournament_id = standing_tournament and item.group_id is not distinct from standing_group and item.archived_at is null;
    for op in select value from jsonb_array_elements(resolved_ops) value where value->>'table' = 'standings' and value->'data'->>'tournament_id' = standing_tournament::text and value->'data'->>'group_id' is not distinct from standing_group::text loop
      data := op->'data';
      select coalesce(jsonb_agg(item) filter (where item->>'entry_id' is distinct from data->>'entry_id'), '[]'::jsonb) into standing_rows from jsonb_array_elements(standing_rows) item;
      if op->>'action' <> 'ARCHIVE' then
        standing_rows := standing_rows || jsonb_build_array(jsonb_build_object('entry_id', (data->>'entry_id')::uuid, 'played', coalesce((data->>'played')::integer, 0), 'won', coalesce((data->>'won')::integer, 0), 'drawn', coalesce((data->>'drawn')::integer, 0), 'lost', coalesce((data->>'lost')::integer, 0), 'score_for', coalesce((data->>'score_for')::numeric, 0), 'score_against', coalesce((data->>'score_against')::numeric, 0), 'points', coalesce((data->>'points')::numeric, 0), 'rank', nullif(data->>'rank', '')::integer));
      end if;
    end loop;
    perform public.save_manual_standings(standing_tournament, standing_group, standing_rows);
  end loop;

  for v_fixture_id in select key::uuid from jsonb_object_keys(touched_fixtures) key loop
    select fixture.status, fixture.winner_entry_id, fixture.result_summary_vi, fixture.result_summary_en into fixture_state
    from public.fixtures fixture where fixture.id = v_fixture_id and fixture.tenant_id = v_tenant_id and fixture.archived_at is null;
    if not found then raise exception 'Không tìm thấy trận sau khi cập nhật'; end if;
    select coalesce(jsonb_agg(jsonb_build_object('entry_id', item.entry_id, 'side', item.side, 'lane', item.lane, 'score', item.score, 'score_numeric', item.score_numeric, 'rank', item.rank, 'result_status', item.result_status, 'result_detail', item.result_detail) order by item.id), '[]'::jsonb) into fixture_entries
    from public.fixture_entries item where item.fixture_id = v_fixture_id and item.tenant_id = v_tenant_id and item.archived_at is null;
    select resolved_item->'data'->>'status', nullif(resolved_item->'data'->>'winner_entry_id', '')::uuid, resolved_item->'data'->>'result_summary_vi', resolved_item->'data'->>'result_summary_en' into desired_status, desired_winner, desired_summary_vi, desired_summary_en
    from jsonb_array_elements(resolved_ops) resolved_item where resolved_item->>'table' = 'fixtures' and (resolved_item->>'id')::uuid = v_fixture_id;
    result_op_found := found;
    if not result_op_found then
      desired_status := fixture_state.status;
      desired_winner := fixture_state.winner_entry_id;
      desired_summary_vi := fixture_state.result_summary_vi;
      desired_summary_en := fixture_state.result_summary_en;
    end if;
    if jsonb_array_length(fixture_entries) = 0 and desired_status in ('scheduled','live','postponed','cancelled') and desired_winner is null then
      perform private.sport_excel_write_row('fixtures', v_fixture_id, v_tenant_id, jsonb_build_object('status', desired_status, 'winner_entry_id', desired_winner, 'result_summary_vi', desired_summary_vi, 'result_summary_en', desired_summary_en), false, array['tournament_id','group_id','venue_id','court_id','starts_at','ends_at','round_vi','round_en','round_order','bracket_position','next_fixture_id','source_code']);
    else
      perform public.save_fixture_result(v_fixture_id, desired_status, desired_winner, desired_summary_vi, desired_summary_en, fixture_entries, null);
    end if;
  end loop;

  v_after_snapshot := private.sport_excel_snapshot(v_tenant_id, import_row.sport_id);
  update public.sport_excel_imports import_item set status = 'applied', applied_at = now(), before_snapshot = v_before_snapshot, after_snapshot = v_after_snapshot where import_item.id = p_import_id;

  for table_name_loop in select unnest(array['organizations','participants','tournaments','entries','entry_members','venues','courts','groups','group_entries','fixtures','fixture_entries','fixture_slots','standings','awards']) loop
    for item in select value from jsonb_array_elements(v_before_snapshot->'tables'->table_name_loop) value loop
      select value into change_after from jsonb_array_elements(v_after_snapshot->'tables'->table_name_loop) value where value->>'id' = item->>'id';
      if change_after is null then
        insert into public.sport_excel_changes (tenant_id, import_id, table_name, row_id, action, before_data, after_data) values (v_tenant_id, p_import_id, table_name_loop, (item->>'id')::uuid, 'archive', item, null);
      elsif change_after is distinct from item then
        insert into public.sport_excel_changes (tenant_id, import_id, table_name, row_id, action, before_data, after_data) values (v_tenant_id, p_import_id, table_name_loop, (item->>'id')::uuid, 'update', item, change_after);
      end if;
    end loop;
    for item in select value from jsonb_array_elements(v_after_snapshot->'tables'->table_name_loop) value loop
      if not exists (select 1 from jsonb_array_elements(v_before_snapshot->'tables'->table_name_loop) value where value->>'id' = item->>'id') then
        insert into public.sport_excel_changes (tenant_id, import_id, table_name, row_id, action, before_data, after_data) values (v_tenant_id, p_import_id, table_name_loop, (item->>'id')::uuid, 'insert', null, item);
      end if;
    end loop;
  end loop;
  return jsonb_build_object('import_id', p_import_id, 'status', 'applied');
end;
$$;

revoke execute on function public.apply_sport_excel_import(uuid, boolean) from public, anon;
grant execute on function public.apply_sport_excel_import(uuid, boolean) to authenticated;

create or replace function public.rollback_sport_excel_import(p_import_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_tenant_id uuid := (select private.current_tenant_id());
  import_row public.sport_excel_imports%rowtype;
  current_snapshot jsonb;
  restored_snapshot jsonb;
  item jsonb;
  after_item jsonb;
  before_fixture_entries jsonb;
  after_fixture_entries jsonb;
  table_name_loop text;
  fixture_item jsonb;
  row_id uuid;
  table_order text[] := array['organizations','participants','tournaments','entries','entry_members','venues','courts','groups','group_entries','fixture_entries','fixtures','standings','awards'];
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  select * into import_row from public.sport_excel_imports import_item where import_item.id = p_import_id and import_item.tenant_id = v_tenant_id for update;
  if not found or import_row.status <> 'applied' or import_row.before_snapshot is null or import_row.after_snapshot is null then raise exception 'Import chưa thể rollback'; end if;
  current_snapshot := private.sport_excel_snapshot(v_tenant_id, import_row.sport_id);
  if current_snapshot is distinct from import_row.after_snapshot then raise exception 'Dữ liệu đã thay đổi sau import; rollback bị chặn để tránh ghi đè'; end if;

  for table_name_loop in select unnest(table_order) loop
    for item in select value from jsonb_array_elements(import_row.before_snapshot->'tables'->table_name_loop) value loop
      perform private.sport_excel_write_row(table_name_loop, (item->>'id')::uuid, v_tenant_id, item, false);
    end loop;
  end loop;
  for fixture_item in select value from jsonb_array_elements(import_row.before_snapshot->'tables'->'fixtures') value loop
    select value into after_item from jsonb_array_elements(import_row.after_snapshot->'tables'->'fixtures') value where value->>'id' = fixture_item->>'id';
    select coalesce(jsonb_agg(value order by value->>'id'), '[]'::jsonb) into before_fixture_entries from jsonb_array_elements(import_row.before_snapshot->'tables'->'fixture_entries') value where value->>'fixture_id' = fixture_item->>'id';
    select coalesce(jsonb_agg(value order by value->>'id'), '[]'::jsonb) into after_fixture_entries from jsonb_array_elements(import_row.after_snapshot->'tables'->'fixture_entries') value where value->>'fixture_id' = fixture_item->>'id';
    if after_item is not null and (fixture_item->>'status' is distinct from after_item->>'status' or fixture_item->>'winner_entry_id' is distinct from after_item->>'winner_entry_id' or fixture_item->>'result_summary_vi' is distinct from after_item->>'result_summary_vi' or fixture_item->>'result_summary_en' is distinct from after_item->>'result_summary_en' or before_fixture_entries is distinct from after_fixture_entries) then
      perform public.save_fixture_result((fixture_item->>'id')::uuid, fixture_item->>'status', nullif(fixture_item->>'winner_entry_id', '')::uuid, fixture_item->>'result_summary_vi', fixture_item->>'result_summary_en', before_fixture_entries, null);
    end if;
  end loop;
  for table_name_loop in select ordered.item from unnest(table_order) with ordinality as ordered(item, position) order by ordered.position desc loop
    for item in select value from jsonb_array_elements(import_row.after_snapshot->'tables'->table_name_loop) value loop
      if not exists (select 1 from jsonb_array_elements(import_row.before_snapshot->'tables'->table_name_loop) value where value->>'id' = item->>'id') then
        perform private.sport_excel_write_row(table_name_loop, (item->>'id')::uuid, v_tenant_id, item, true);
      end if;
    end loop;
  end loop;
  restored_snapshot := private.sport_excel_snapshot(v_tenant_id, import_row.sport_id);
  if restored_snapshot is distinct from import_row.before_snapshot then raise exception 'Rollback không khôi phục đúng snapshot ban đầu'; end if;
  update public.sport_excel_imports set status = 'rolled_back', rolled_back_at = now() where id = p_import_id;
  return jsonb_build_object('import_id', p_import_id, 'status', 'rolled_back');
end;
$$;

revoke execute on function public.rollback_sport_excel_import(uuid) from public, anon;
grant execute on function public.rollback_sport_excel_import(uuid) to authenticated;
