-- Reconcile the reviewed women's 4×100m relay rosters on existing databases.
-- This is intentionally idempotent so `supabase db push` is safe to retry.
do $$
declare
  target_tenant_id uuid := private.seed_tenant_id();
begin
  create temporary table desired_womens_relay_members (
    entry_name text,
    organization_code text,
    full_name text,
    sort_order integer
  ) on commit drop;

  insert into desired_womens_relay_members values
    ('PVD', 'PVD', 'Nguyễn Thị Hồng Thúy', 1),
    ('PVD', 'PVD', 'Nguyễn Thị Thìn', 2),
    ('PVD', 'PVD', 'Vũ Thị Huệ', 3),
    ('PVD', 'PVD', 'Vương Thị Hiền', 4),
    ('PVFCCo', 'PVFCCo', 'Lê Thị Ánh Tuyết', 1),
    ('PVFCCo', 'PVFCCo', 'Nguyễn Thị Minh Hiền', 2),
    ('PVFCCo', 'PVFCCo', 'Phan Thị Hồng Thắm', 3),
    ('PVFCCo', 'PVFCCo', 'Trương Thị Thanh Toàn', 4),
    ('PVG', 'PVG', 'Hoàng Thị Hà', 1),
    ('PVG', 'PVG', 'Hoàng Thị Hoài', 2),
    ('PVG', 'PVG', 'Nguyễn Mỹ Thanh', 3),
    ('PVG', 'PVG', 'Trần Thị Nhiên', 4);

  insert into public.participants (tenant_id, organization_id, full_name)
  select target_tenant_id, organization.id, desired.full_name
  from desired_womens_relay_members desired
  join public.organizations organization on organization.tenant_id = target_tenant_id
    and organization.code = desired.organization_code
  where not exists (
    select 1 from public.participants existing
    where existing.tenant_id = target_tenant_id
      and existing.organization_id = organization.id
      and existing.full_name = desired.full_name
  );

  with target_entries as (
    select distinct on (entry.name_vi)
      entry.id, entry.name_vi
    from desired_womens_relay_members desired
    join public.sports sport on sport.tenant_id = target_tenant_id and sport.slug = 'dien-kinh'
    join public.tournaments tournament on tournament.tenant_id = target_tenant_id
      and tournament.sport_id = sport.id and tournament.slug = '4x100m-nu'
    join public.entries entry on entry.tenant_id = target_tenant_id
      and entry.tournament_id = tournament.id and entry.kind = 'team'
      and entry.name_vi = desired.entry_name
    order by entry.name_vi, entry.archived_at nulls first, entry.id
  ),
  desired_members as (
    select distinct on (target.id, desired.full_name)
      target.id as entry_id, participant.id as participant_id, desired.sort_order
    from target_entries target
    join desired_womens_relay_members desired on desired.entry_name = target.name_vi
    join public.organizations organization on organization.tenant_id = target_tenant_id
      and organization.code = desired.organization_code
    join public.participants participant on participant.tenant_id = target_tenant_id
      and participant.organization_id = organization.id
      and participant.full_name = desired.full_name
      and participant.archived_at is null
    order by target.id, desired.full_name, participant.id
  )
  update public.entry_members member
  set archived_at = now()
  from target_entries target
  where member.tenant_id = target_tenant_id
    and member.entry_id = target.id
    and not exists (
      select 1 from desired_members desired
      where desired.entry_id = member.entry_id
        and desired.participant_id = member.participant_id
    );

  with target_entries as (
    select distinct on (entry.name_vi)
      entry.id, entry.name_vi
    from desired_womens_relay_members desired
    join public.sports sport on sport.tenant_id = target_tenant_id and sport.slug = 'dien-kinh'
    join public.tournaments tournament on tournament.tenant_id = target_tenant_id
      and tournament.sport_id = sport.id and tournament.slug = '4x100m-nu'
    join public.entries entry on entry.tenant_id = target_tenant_id
      and entry.tournament_id = tournament.id and entry.kind = 'team'
      and entry.name_vi = desired.entry_name
    order by entry.name_vi, entry.archived_at nulls first, entry.id
  ),
  desired_members as (
    select distinct on (target.id, desired.full_name)
      target.id as entry_id, participant.id as participant_id, desired.sort_order
    from target_entries target
    join desired_womens_relay_members desired on desired.entry_name = target.name_vi
    join public.organizations organization on organization.tenant_id = target_tenant_id
      and organization.code = desired.organization_code
    join public.participants participant on participant.tenant_id = target_tenant_id
      and participant.organization_id = organization.id
      and participant.full_name = desired.full_name
      and participant.archived_at is null
    order by target.id, desired.full_name, participant.id
  )
  update public.entry_members member
  set sort_order = desired.sort_order, archived_at = null
  from desired_members desired
  where member.tenant_id = target_tenant_id
    and member.entry_id = desired.entry_id
    and member.participant_id = desired.participant_id;

  with target_entries as (
    select distinct on (entry.name_vi)
      entry.id, entry.name_vi
    from desired_womens_relay_members desired
    join public.sports sport on sport.tenant_id = target_tenant_id and sport.slug = 'dien-kinh'
    join public.tournaments tournament on tournament.tenant_id = target_tenant_id
      and tournament.sport_id = sport.id and tournament.slug = '4x100m-nu'
    join public.entries entry on entry.tenant_id = target_tenant_id
      and entry.tournament_id = tournament.id and entry.kind = 'team'
      and entry.name_vi = desired.entry_name
    order by entry.name_vi, entry.archived_at nulls first, entry.id
  ),
  desired_members as (
    select distinct on (target.id, desired.full_name)
      target.id as entry_id, participant.id as participant_id, desired.sort_order
    from target_entries target
    join desired_womens_relay_members desired on desired.entry_name = target.name_vi
    join public.organizations organization on organization.tenant_id = target_tenant_id
      and organization.code = desired.organization_code
    join public.participants participant on participant.tenant_id = target_tenant_id
      and participant.organization_id = organization.id
      and participant.full_name = desired.full_name
      and participant.archived_at is null
    order by target.id, desired.full_name, participant.id
  )
  insert into public.entry_members (tenant_id, entry_id, participant_id, sort_order)
  select target_tenant_id, desired.entry_id, desired.participant_id, desired.sort_order
  from desired_members desired
  where not exists (
    select 1 from public.entry_members existing
    where existing.entry_id = desired.entry_id
      and existing.participant_id = desired.participant_id
  );
end
$$;
