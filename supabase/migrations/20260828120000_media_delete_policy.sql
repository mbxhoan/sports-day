-- Allow authenticated admins to remove their tenant's gallery objects.
update storage.buckets
set file_size_limit = 10485760
where id = 'event-media';

create policy event_media_admin_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'event-media'
    and name like (coalesce(current_setting('request.headers', true), '{}')::jsonb ->> 'x-tenant-slug') || '/%'
    and (select private.is_admin((select private.current_tenant_id())))
  );
