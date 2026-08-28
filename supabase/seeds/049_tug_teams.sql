set app.tenant_slug = 'petrovietnam2026';

-- Team labels are preserved exactly as printed in the tug-of-war draw sheets.
create temporary table seed_tug_teams (tournament_slug text, team_name text, sort_order integer) on commit drop;
insert into seed_tug_teams values
  ('nu','PVCHEM',1), ('nu','VSP',2), ('nu','PVI',3), ('nu','NCKH',4), ('nu','PVOIL',5), ('nu','PVMR',6),
  ('nu','PVTRANS',7), ('nu','PTSC',8), ('nu','PVCOMBANK',9), ('nu','PETROCONs',10), ('nu','PVPMB',11), ('nu','PETROSETCO',12),
  ('nam','PVFCCo',1), ('nam','PTSC',2), ('nam','PVGAS',3), ('nam','PVOIL',4), ('nam','PVPMB',5), ('nam','PVMR',6),
  ('nam','PVCHEM',7), ('nam','PVI',8), ('nam','PETROSETCO',9), ('nam','PCTRANS',10), ('nam','PVD',11), ('nam','SWPOC',12),
  ('nam','NCKH',13), ('nam','PVCOMBANK',14), ('nam','PQPOC',15), ('nam','BỘ MÁY QL&ĐH PETROVN',16), ('nam','VSP',17);

insert into public.organizations (code, name_vi, name_en)
select distinct team_name, team_name, team_name from seed_tug_teams
on conflict (tenant_id, code) do update set archived_at = null;

insert into public.entries (tournament_id, organization_id, kind, name_vi, name_en, seed_number)
select t.id, o.id, 'team', r.team_name, r.team_name, r.sort_order
from seed_tug_teams r join public.sports s on s.slug = 'keo-co'
join public.tournaments t on t.sport_id = s.id and t.slug = r.tournament_slug
join public.organizations o on o.code = r.team_name
where not exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = r.team_name);
