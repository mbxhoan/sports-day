set app.tenant_slug = 'petrovietnam2026';

do $$
declare
  target_tenant uuid := private.seed_tenant_id();
  typo_id uuid;
  existing_id uuid;
begin
  select id into typo_id
  from public.organizations
  where tenant_id = target_tenant and code = 'PVPMP' and archived_at is null
  limit 1;

  if typo_id is null then
    return;
  end if;

  select id into existing_id
  from public.organizations
  where tenant_id = target_tenant and code = 'PVPMB'
  limit 1;

  if existing_id is null then
    update public.organizations set code = 'PVPMB' where id = typo_id;
    return;
  end if;

  -- Keep the typo row's ID and foreign-key links; retire any older duplicate.
  update public.organizations
  set code = 'PVPMB__legacy_' || left(existing_id::text, 8)
  where id = existing_id;

  update public.organizations
  set code = 'PVPMB', archived_at = null
  where id = typo_id;

  update public.organizations
  set archived_at = coalesce(archived_at, now())
  where id = existing_id;
end
$$;
