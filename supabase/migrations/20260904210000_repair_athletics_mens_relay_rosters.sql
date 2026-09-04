-- Customer feedback: use the 15 reviewed men's 4×100m relay teams.
do $$
declare
  target_tenant_id uuid := private.seed_tenant_id();
begin
  -- Production may already contain the old single PV GAS entry from the
  -- workbook import. Reuse it as team 1, then create the missing team 2.
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

  update public.fixture_entries item
  set archived_at = now()
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  join public.sports sport on sport.id = tournament.sport_id
  where item.entry_id = entry.id
    and entry.tenant_id = target_tenant_id
    and tournament.tenant_id = target_tenant_id
    and sport.tenant_id = target_tenant_id
    and sport.slug = 'dien-kinh'
    and tournament.slug = '4x100m-nam'
    and entry.name_vi in ('NCKHĐT', 'Đội 2 - NCKHĐT', 'Đội 1 - PTSC', 'PV GAS');

  update public.group_entries item
  set archived_at = now()
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  join public.sports sport on sport.id = tournament.sport_id
  where item.entry_id = entry.id
    and entry.tenant_id = target_tenant_id
    and tournament.tenant_id = target_tenant_id
    and sport.tenant_id = target_tenant_id
    and sport.slug = 'dien-kinh'
    and tournament.slug = '4x100m-nam'
    and entry.name_vi in ('NCKHĐT', 'Đội 2 - NCKHĐT', 'Đội 1 - PTSC', 'PV GAS');

  update public.standings item
  set archived_at = now()
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  join public.sports sport on sport.id = tournament.sport_id
  where item.entry_id = entry.id
    and entry.tenant_id = target_tenant_id
    and tournament.tenant_id = target_tenant_id
    and sport.tenant_id = target_tenant_id
    and sport.slug = 'dien-kinh'
    and tournament.slug = '4x100m-nam'
    and entry.name_vi in ('NCKHĐT', 'Đội 2 - NCKHĐT', 'Đội 1 - PTSC', 'PV GAS');

  update public.entry_members item
  set archived_at = now()
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  join public.sports sport on sport.id = tournament.sport_id
  where item.entry_id = entry.id
    and entry.tenant_id = target_tenant_id
    and tournament.tenant_id = target_tenant_id
    and sport.tenant_id = target_tenant_id
    and sport.slug = 'dien-kinh'
    and tournament.slug = '4x100m-nam'
    and entry.name_vi in ('NCKHĐT', 'Đội 2 - NCKHĐT', 'Đội 1 - PTSC', 'PV GAS');

  update public.entries entry
  set archived_at = now()
  from public.tournaments tournament
  join public.sports sport on sport.id = tournament.sport_id
  where entry.tournament_id = tournament.id
    and entry.tenant_id = target_tenant_id
    and tournament.tenant_id = target_tenant_id
    and sport.tenant_id = target_tenant_id
    and sport.slug = 'dien-kinh'
    and tournament.slug = '4x100m-nam'
    and entry.name_vi in ('NCKHĐT', 'Đội 2 - NCKHĐT', 'Đội 1 - PTSC', 'PV GAS');
end
$$;
