-- Customer feedback: these relay rosters must contain each athlete once.
do $$
declare
  target_tenant_id uuid := private.seed_tenant_id();
begin
  with desired(entry_name, organization_code, full_name, sort_order) as (
    values
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
      ('PVG', 'PVG', 'Trần Thị Nhiên', 4)
  ),
  target_entries as (
    select entry.id, desired.entry_name, desired.organization_code
    from desired
    join public.sports sport on sport.tenant_id = target_tenant_id and sport.slug = 'dien-kinh'
    join public.tournaments tournament on tournament.tenant_id = target_tenant_id and tournament.sport_id = sport.id and tournament.slug = '4x100m-nu'
    join public.entries entry on entry.tenant_id = target_tenant_id and entry.tournament_id = tournament.id and entry.kind = 'team' and entry.name_vi = desired.entry_name
    group by entry.id, desired.entry_name, desired.organization_code
  ),
  keepers as (
    select distinct on (target.id, participant.full_name)
      target.id as entry_id, participant.id as participant_id
    from target_entries target
    join public.participants participant on participant.tenant_id = target_tenant_id and participant.organization_id = (
      select organization.id from public.organizations organization where organization.tenant_id = target_tenant_id and organization.code = target.organization_code limit 1
    )
    join desired on desired.entry_name = target.entry_name and desired.organization_code = target.organization_code and desired.full_name = participant.full_name
    where participant.archived_at is null
    order by target.id, participant.full_name, participant.id
  )
  update public.entry_members member
  set archived_at = now()
  from public.entries entry
  where member.entry_id = entry.id
    and member.tenant_id = target_tenant_id
    and entry.id in (select id from target_entries)
    and not exists (select 1 from keepers keep where keep.entry_id = member.entry_id and keep.participant_id = member.participant_id);

  with desired(entry_name, organization_code, full_name, sort_order) as (
    values
      ('PVD', 'PVD', 'Nguyễn Thị Hồng Thúy', 1), ('PVD', 'PVD', 'Nguyễn Thị Thìn', 2), ('PVD', 'PVD', 'Vũ Thị Huệ', 3), ('PVD', 'PVD', 'Vương Thị Hiền', 4),
      ('PVFCCo', 'PVFCCo', 'Lê Thị Ánh Tuyết', 1), ('PVFCCo', 'PVFCCo', 'Nguyễn Thị Minh Hiền', 2), ('PVFCCo', 'PVFCCo', 'Phan Thị Hồng Thắm', 3), ('PVFCCo', 'PVFCCo', 'Trương Thị Thanh Toàn', 4),
      ('PVG', 'PVG', 'Hoàng Thị Hà', 1), ('PVG', 'PVG', 'Hoàng Thị Hoài', 2), ('PVG', 'PVG', 'Nguyễn Mỹ Thanh', 3), ('PVG', 'PVG', 'Trần Thị Nhiên', 4)
  )
  update public.entry_members member
  set sort_order = desired.sort_order, archived_at = null
  from desired
  join public.entries entry on entry.tenant_id = target_tenant_id and entry.name_vi = desired.entry_name and entry.kind = 'team'
  join public.tournaments tournament on tournament.id = entry.tournament_id and tournament.tenant_id = target_tenant_id and tournament.slug = '4x100m-nu'
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = target_tenant_id and sport.slug = 'dien-kinh'
  join public.participants participant on participant.tenant_id = target_tenant_id and participant.full_name = desired.full_name and participant.archived_at is null
  where member.entry_id = entry.id
    and member.participant_id = participant.id
    and participant.id = (
      select candidate.id
      from public.participants candidate
      where candidate.tenant_id = target_tenant_id
        and candidate.organization_id = participant.organization_id
        and candidate.full_name = desired.full_name
        and candidate.archived_at is null
      order by candidate.id
      limit 1
    );
end
$$;
