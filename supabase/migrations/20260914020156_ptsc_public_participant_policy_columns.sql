-- Keep participant reads column-scoped without granting anon the RLS policy columns.
create or replace function private.participant_public_visible(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.participants
    where id = p_id
      and tenant_id = private.current_tenant_id()
      and archived_at is null
  );
$$;

revoke all on function private.participant_public_visible(uuid) from public;
grant execute on function private.participant_public_visible(uuid) to anon, authenticated;

drop policy if exists participants_public_read on public.participants;
create policy participants_public_read on public.participants
for select to anon
using (private.participant_public_visible(id));
