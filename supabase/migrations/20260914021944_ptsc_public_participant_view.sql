-- Public pages need participant names, but anon must not read the base table.
-- The private view keeps the projection narrow and enforces the request tenant.
create or replace view private.public_participants
with (security_barrier = true)
as
select p.id, p.organization_id, p.full_name, p.full_name_en
from public.participants p
where p.tenant_id = private.current_tenant_id()
  and p.archived_at is null;

revoke all on table private.public_participants from public;
grant select on table private.public_participants to anon, authenticated;

do $fix$
declare
  v_definition text;
  v_patched text;
begin
  select pg_get_functiondef('public.get_public_page(text, text)'::regprocedure)
  into v_definition;
  if v_definition is null then
    raise exception 'public.get_public_page(text, text) không tồn tại';
  end if;

  v_patched := replace(
    v_definition,
    'count(id) from participants where tenant_id = v_tenant_id and archived_at is null',
    'count(*) from private.public_participants'
  );
  v_patched := replace(
    v_patched,
    'from participants p where p.tenant_id = v_tenant_id and p.archived_at is null and exists (',
    'from private.public_participants p where exists ('
  );
  v_patched := replace(
    v_patched,
    'from participants where tenant_id = v_tenant_id and archived_at is null',
    'from private.public_participants'
  );

  if v_patched = v_definition or v_patched like '%from participants%' then
    raise exception 'Không thay thế đầy đủ truy vấn participants trong get_public_page';
  end if;

  execute v_patched;
end
$fix$;
