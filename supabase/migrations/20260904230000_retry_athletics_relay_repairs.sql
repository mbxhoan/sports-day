-- Retry relay repairs whose original migrations ran without a seed tenant.
set app.tenant_slug = 'petrovietnam2026';

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

  update public.participants participant
  set archived_at = null
  from desired_womens_relay_members desired
  join public.organizations organization on organization.tenant_id = target_tenant_id
    and organization.code = desired.organization_code
  where participant.tenant_id = target_tenant_id
    and participant.organization_id = organization.id
    and participant.full_name = desired.full_name;

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

  create temporary table desired_womens_members on commit drop as
  select distinct on (entry.id, desired.full_name)
    entry.id as entry_id, participant.id as participant_id, desired.sort_order
  from desired_womens_relay_members desired
  join public.sports sport on sport.tenant_id = target_tenant_id and sport.slug = 'dien-kinh'
  join public.tournaments tournament on tournament.tenant_id = target_tenant_id
    and tournament.sport_id = sport.id and tournament.slug = '4x100m-nu'
  join public.entries entry on entry.tenant_id = target_tenant_id
    and entry.tournament_id = tournament.id and entry.kind = 'team'
    and entry.name_vi = desired.entry_name
  join public.organizations organization on organization.tenant_id = target_tenant_id
    and organization.code = desired.organization_code
  join public.participants participant on participant.tenant_id = target_tenant_id
    and participant.organization_id = organization.id
    and participant.full_name = desired.full_name
    and participant.archived_at is null
  order by entry.id, desired.full_name, participant.id;

  update public.entry_members member
  set archived_at = now()
  where member.tenant_id = target_tenant_id
    and member.entry_id in (select entry_id from desired_womens_members)
    and not exists (
      select 1 from desired_womens_members desired
      where desired.entry_id = member.entry_id
        and desired.participant_id = member.participant_id
    );

  update public.entry_members member
  set sort_order = desired.sort_order, archived_at = null
  from desired_womens_members desired
  where member.tenant_id = target_tenant_id
    and member.entry_id = desired.entry_id
    and member.participant_id = desired.participant_id;

  insert into public.entry_members (tenant_id, entry_id, participant_id, sort_order)
  select target_tenant_id, desired.entry_id, desired.participant_id, desired.sort_order
  from desired_womens_members desired
  where not exists (
    select 1 from public.entry_members existing
    where existing.entry_id = desired.entry_id
      and existing.participant_id = desired.participant_id
  );

  update public.entries old_entry
  set name_vi = 'PV GAS 1', name_en = 'PV GAS 1', archived_at = null
  from public.tournaments tournament
  join public.sports sport on sport.id = tournament.sport_id
  where old_entry.tournament_id = tournament.id
    and old_entry.tenant_id = target_tenant_id
    and tournament.tenant_id = target_tenant_id
    and sport.tenant_id = target_tenant_id
    and sport.slug = 'dien-kinh'
    and tournament.slug = '4x100m-nam'
    and old_entry.name_vi = 'PV GAS'
    and not exists (
      select 1 from public.entries canonical
      where canonical.tournament_id = old_entry.tournament_id
        and canonical.name_vi = 'PV GAS 1'
    );

  insert into public.entries (tournament_id, organization_id, kind, name_vi, name_en, seed_number)
  select team_one.tournament_id, team_one.organization_id, 'team', 'PV GAS 2', 'PV GAS 2', 5
  from public.entries team_one
  join public.tournaments tournament on tournament.id = team_one.tournament_id
  join public.sports sport on sport.id = tournament.sport_id
  where team_one.tenant_id = target_tenant_id
    and team_one.name_vi = 'PV GAS 1'
    and team_one.kind = 'team'
    and tournament.tenant_id = target_tenant_id
    and sport.tenant_id = target_tenant_id
    and sport.slug = 'dien-kinh'
    and tournament.slug = '4x100m-nam'
    and not exists (
      select 1 from public.entries existing
      where existing.tournament_id = team_one.tournament_id
        and existing.name_vi = 'PV GAS 2'
    );

  update public.participants participant
  set archived_at = null
  from public.entries team_one
  cross join (values
    ('Lê Tiến Dũng'), ('Ngô Văn Cường'), ('Nguyễn Hữu Thức'), ('Nguyễn Xuân Tùng')
  ) roster(full_name)
  where team_one.tenant_id = target_tenant_id
    and team_one.name_vi = 'PV GAS 1'
    and participant.tenant_id = target_tenant_id
    and participant.organization_id = team_one.organization_id
    and participant.full_name = roster.full_name;

  insert into public.participants (tenant_id, organization_id, full_name)
  select target_tenant_id, team_one.organization_id, roster.full_name
  from public.entries team_one
  cross join (values
    ('Lê Tiến Dũng'), ('Ngô Văn Cường'), ('Nguyễn Hữu Thức'), ('Nguyễn Xuân Tùng')
  ) roster(full_name)
  where team_one.tenant_id = target_tenant_id
    and team_one.name_vi = 'PV GAS 1'
    and not exists (
      select 1 from public.participants existing
      where existing.tenant_id = target_tenant_id
        and existing.organization_id = team_one.organization_id
      and existing.full_name = roster.full_name
  );

  update public.entry_members member
  set archived_at = now()
  from public.entries entry
  cross join public.participants participant
  where member.entry_id = entry.id
    and participant.id = member.participant_id
    and member.tenant_id = target_tenant_id
    and entry.tenant_id = target_tenant_id
    and entry.name_vi = 'PV GAS 1'
    and participant.full_name not in ('Đỗ Minh Xuân', 'Ngô Phương Bắc', 'Trần Việt Dũng', 'Vũ Mạnh Nhất');

  insert into public.entry_members (tenant_id, entry_id, participant_id, sort_order)
  select target_tenant_id, team_one.id, participant.id, roster.sort_order
  from public.entries team_one
  cross join (values
    ('Đỗ Minh Xuân', 1), ('Ngô Phương Bắc', 2), ('Trần Việt Dũng', 3), ('Vũ Mạnh Nhất', 4)
  ) roster(full_name, sort_order)
  join public.participants participant on participant.tenant_id = target_tenant_id
    and participant.organization_id = team_one.organization_id
    and participant.full_name = roster.full_name
  where team_one.tenant_id = target_tenant_id
    and team_one.name_vi = 'PV GAS 1'
    and not exists (
      select 1 from public.entry_members existing
      where existing.entry_id = team_one.id and existing.participant_id = participant.id
    );

  insert into public.entry_members (tenant_id, entry_id, participant_id, sort_order)
  select target_tenant_id, team_two.id, participant.id, roster.sort_order
  from public.entries team_two
  join public.entries team_one on team_one.tournament_id = team_two.tournament_id
    and team_one.name_vi = 'PV GAS 1'
  cross join (values
    ('Lê Tiến Dũng', 1), ('Ngô Văn Cường', 2), ('Nguyễn Hữu Thức', 3), ('Nguyễn Xuân Tùng', 4)
  ) roster(full_name, sort_order)
  join public.participants participant on participant.tenant_id = target_tenant_id
    and participant.organization_id = team_one.organization_id
    and participant.full_name = roster.full_name
  where team_two.tenant_id = target_tenant_id
    and team_two.name_vi = 'PV GAS 2'
    and not exists (
      select 1 from public.entry_members existing
      where existing.entry_id = team_two.id and existing.participant_id = participant.id
    );

  with duplicate_members as (
    select member.id, row_number() over (
      partition by member.entry_id, participant.full_name
      order by member.archived_at nulls first, member.sort_order, member.id
    ) as duplicate_rank
    from public.entry_members member
    join public.entries entry on entry.id = member.entry_id
    join public.tournaments tournament on tournament.id = entry.tournament_id
    join public.sports sport on sport.id = tournament.sport_id
    join public.participants participant on participant.id = member.participant_id
    where member.tenant_id = target_tenant_id
      and sport.slug = 'dien-kinh'
      and tournament.slug = '4x100m-nam'
      and member.archived_at is null
  )
  update public.entry_members member
  set archived_at = now()
  from duplicate_members duplicate
  where member.id = duplicate.id and duplicate.duplicate_rank > 1;

  create temporary table obsolete_mens_relay_entries on commit drop as
  select entry.id
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  join public.sports sport on sport.id = tournament.sport_id
  where entry.tenant_id = target_tenant_id
    and tournament.tenant_id = target_tenant_id
    and sport.tenant_id = target_tenant_id
    and sport.slug = 'dien-kinh'
    and tournament.slug = '4x100m-nam'
    and entry.name_vi in ('NCKHĐT', 'Đội 2 - NCKHĐT', 'Đội 1 - PTSC', 'PV GAS');

  update public.fixture_entries set archived_at = now()
  where tenant_id = target_tenant_id and entry_id in (select id from obsolete_mens_relay_entries);
  update public.group_entries set archived_at = now()
  where tenant_id = target_tenant_id and entry_id in (select id from obsolete_mens_relay_entries);
  update public.standings set archived_at = now()
  where tenant_id = target_tenant_id and entry_id in (select id from obsolete_mens_relay_entries);
  update public.entry_members set archived_at = now()
  where tenant_id = target_tenant_id and entry_id in (select id from obsolete_mens_relay_entries);
  update public.entries set archived_at = now()
  where tenant_id = target_tenant_id and id in (select id from obsolete_mens_relay_entries);
end
$$;
