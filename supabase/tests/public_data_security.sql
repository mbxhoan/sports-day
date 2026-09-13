begin;

set local role postgres;
insert into public.sports (id, tenant_id, slug, name_vi, name_en, emoji)
values
  ('73000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'security-ptsc', 'PTSC only', 'PTSC only', 'P'),
  ('73000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'security-pvn', 'PVN only', 'PVN only', 'V');
insert into public.participants (id, tenant_id, full_name, full_name_en, gender, birth_date)
values ('73000000-0000-0000-0000-000000000010', '22222222-2222-2222-2222-222222222222', 'Public Athlete', 'Public Athlete', 'male', '1990-01-01');

do $$
begin
  if has_table_privilege('anon', 'public.source_documents', 'select') then raise exception 'anon can select source_documents'; end if;
  if has_table_privilege('anon', 'public.media', 'select') then raise exception 'anon can select media'; end if;
  if has_table_privilege('anon', 'public.participants', 'select') then raise exception 'anon has table-level participant select'; end if;
  if not (has_column_privilege('anon', 'public.participants', 'id', 'select') and has_column_privilege('anon', 'public.participants', 'organization_id', 'select') and has_column_privilege('anon', 'public.participants', 'full_name', 'select') and has_column_privilege('anon', 'public.participants', 'full_name_en', 'select')) then raise exception 'public participant columns missing'; end if;
  if has_column_privilege('anon', 'public.participants', 'gender', 'select') or has_column_privilege('anon', 'public.participants', 'birth_date', 'select') then raise exception 'anon can select participant PII'; end if;
  if not has_function_privilege('anon', 'public.get_public_page(text,text)', 'execute') then raise exception 'anon cannot execute public RPC'; end if;
  if has_function_privilege('public', 'public.get_public_page(text,text)', 'execute') then raise exception 'PUBLIC can execute public RPC'; end if;
end $$;

set local request.headers = '{"x-tenant-slug":"ptsc2026"}';
set local role anon;
do $$
declare payload jsonb;
begin
  payload := public.get_public_page('sports-index', null);
  if not (payload->'sports' @> '[{"slug":"security-ptsc"}]'::jsonb) then raise exception 'PTSC public RPC row missing'; end if;
  if payload::text like '%security-pvn%' then raise exception 'public RPC crossed tenant boundary'; end if;
  if payload::text like '%gender%' or payload::text like '%birth_date%' or payload::text like '%source_documents%' or payload::text like '%media%' then raise exception 'public RPC leaked private fields'; end if;
  if (select full_name from public.participants where id = '73000000-0000-0000-0000-000000000010') <> 'Public Athlete' then raise exception 'public athlete name unavailable'; end if;
end $$;

set local request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
set local request.jwt.claims = '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';
set local role authenticated;
do $$
begin
  if not exists (select 1 from public.sports where slug = 'security-ptsc') then raise exception 'PTSC admin cannot read own tenant'; end if;
  set local request.headers = '{"x-tenant-slug":"petrovietnam2026"}';
  if exists (select 1 from public.sports where slug = 'security-pvn') then raise exception 'PTSC admin crossed into PVN'; end if;
end $$;

set local request.jwt.claim.sub = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
set local request.jwt.claims = '{"sub":"cccccccc-cccc-cccc-cccc-cccccccccccc","role":"authenticated"}';
do $$
begin
  begin
    perform public.save_manual_leaderboard('[]'::jsonb);
    raise exception 'non-admin mutation unexpectedly succeeded';
  exception when others then
    if sqlerrm not like '%quyền quản trị%' then raise; end if;
  end;
end $$;

rollback;
