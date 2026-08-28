-- Allow authenticated tenant admins to permanently remove gallery records.
grant delete on table public.media to authenticated;

create policy media_admin_delete on public.media
  for delete to authenticated
  using (
    tenant_id = (select private.current_tenant_id())
    and (select private.is_admin(tenant_id))
  );
