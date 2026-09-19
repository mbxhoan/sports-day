begin;

set local role postgres;
select plan(1);
insert into public.organizations (id, tenant_id, code, name_vi, name_en, leaderboard_rank, gold_medals, silver_medals, bronze_medals)
values
  ('74000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'PTSC-VISIBILITY-VISIBLE', 'Visible', 'Visible', 1, 1, 0, 0),
  ('74000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'PTSC-VISIBILITY-HIDDEN', 'Hidden', 'Hidden', 2, 2, 3, 4),
  ('74000000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'PTSC-VISIBILITY-ZERO', 'Zero', 'Zero', 3, 0, 0, 0),
  ('74000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'PVN-VISIBILITY-LEGACY', 'Legacy', 'Legacy', 1, 5, 0, 0);

insert into public.sports (id, tenant_id, slug, name_vi, name_en, emoji)
values ('74000000-0000-0000-0000-000000000010', '22222222-2222-2222-2222-222222222222', 'visibility-probe', 'Visibility probe', 'Visibility probe', 'V');
insert into public.tournaments (id, tenant_id, sport_id, slug, name_vi, name_en)
values ('74000000-0000-0000-0000-000000000011', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'visibility-probe', 'Visibility probe', 'Visibility probe');
insert into public.entries (id, tenant_id, tournament_id, organization_id, kind, name_vi, name_en)
values ('74000000-0000-0000-0000-000000000012', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000011', '74000000-0000-0000-0000-000000000002', 'team', 'Hidden team', 'Hidden team');

update public.organizations set leaderboard_hidden = true where id = '74000000-0000-0000-0000-000000000002';

do $$
begin
  if not exists (select 1 from public.organizations where id = '74000000-0000-0000-0000-000000000001' and leaderboard_hidden is false) then raise exception 'organizations default to visible'; end if;
  if not exists (select 1 from public.organizations where id = '74000000-0000-0000-0000-000000000002' and gold_medals = 2 and silver_medals = 3 and bronze_medals = 4 and leaderboard_rank = 2) then raise exception 'hiding an organization changed its leaderboard data'; end if;
  if not exists (select 1 from public.organizations where id = '74000000-0000-0000-0000-000000000002') then raise exception 'hiding an organization deleted it'; end if;
  if not exists (select 1 from public.organizations where id = '74000000-0000-0000-0000-000000000004' and leaderboard_hidden is false) then raise exception 'legacy organization was modified'; end if;
end $$;

set local request.headers = '{"x-tenant-slug":"ptsc2026"}';
set local role anon;
do $$
declare
  leaderboard jsonb;
  schedule_data jsonb;
  sport_data jsonb;
begin
  leaderboard := public.get_public_page('leaderboard', null);
  if not (leaderboard->'organizations' @> '[{"id":"74000000-0000-0000-0000-000000000001"}]'::jsonb) then raise exception 'visible organization missing from leaderboard'; end if;
  if not (leaderboard->'organizations' @> '[{"id":"74000000-0000-0000-0000-000000000003"}]'::jsonb) then raise exception 'zero-medal organization missing from leaderboard'; end if;
  if leaderboard->'organizations' @> '[{"id":"74000000-0000-0000-0000-000000000002"}]'::jsonb then raise exception 'hidden organization remains on leaderboard'; end if;

  schedule_data := public.get_public_page('schedule', null);
  if not (schedule_data->'organizations' @> '[{"id":"74000000-0000-0000-0000-000000000002"}]'::jsonb) then raise exception 'hiding organization affected schedule data'; end if;
  sport_data := public.get_public_page('sport', 'visibility-probe');
  if not (sport_data->'organizations' @> '[{"id":"74000000-0000-0000-0000-000000000002"}]'::jsonb) then raise exception 'hiding organization affected sport page data'; end if;
end $$;

set local request.headers = '{"x-tenant-slug":"petrovietnam2026"}';
do $$
declare payload jsonb;
begin
  payload := public.get_public_page('leaderboard', null);
  if not (payload->'organizations' @> '[{"id":"74000000-0000-0000-0000-000000000004"}]'::jsonb) then raise exception 'legacy leaderboard organization missing'; end if;
  if payload::text like '%PTSC-VISIBILITY-%' then raise exception 'leaderboard crossed tenant boundary'; end if;
end $$;

set local role postgres;
select pass('PTSC organization visibility is scoped and preserves organization data');
select * from finish();
rollback;
