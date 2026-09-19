begin;
set local app.tenant_slug = 'ptsc2026';
set local role postgres;

insert into public.sports (id, tenant_id, slug, name_vi, name_en, emoji) values
  ('75000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'pickleball-lanh-dao-reset-test', 'PBLD reset test', 'PBLD reset test', 'P'),
  ('75000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'pickleball-reset-control-test', 'PB control test', 'PB control test', 'P'),
  ('75000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'legacy-reset-control-test', 'Legacy control test', 'Legacy control test', 'L');

insert into public.tournaments (id, tenant_id, sport_id, slug, name_vi, name_en, competition_mode) values
  ('75000000-0000-0000-0000-000000000010', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000001', 'men', 'Leadership men', 'Leadership men', 'group_knockout'),
  ('75000000-0000-0000-0000-000000000011', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000002', 'mixed', 'Control mixed', 'Control mixed', 'round_robin'),
  ('75000000-0000-0000-0000-000000000012', '11111111-1111-1111-1111-111111111111', '75000000-0000-0000-0000-000000000003', 'legacy', 'Legacy control', 'Legacy control', 'round_robin');

insert into public.entries (id, tenant_id, tournament_id, kind, name_vi, name_en) values
  ('75000000-0000-0000-0000-000000000021', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000010', 'pair', 'PBLD A', 'PBLD A'),
  ('75000000-0000-0000-0000-000000000022', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000010', 'pair', 'PBLD B', 'PBLD B'),
  ('75000000-0000-0000-0000-000000000023', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000011', 'pair', 'Control A', 'Control A'),
  ('75000000-0000-0000-0000-000000000024', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000011', 'pair', 'Control B', 'Control B'),
  ('75000000-0000-0000-0000-000000000025', '11111111-1111-1111-1111-111111111111', '75000000-0000-0000-0000-000000000012', 'pair', 'Legacy A', 'Legacy A'),
  ('75000000-0000-0000-0000-000000000026', '11111111-1111-1111-1111-111111111111', '75000000-0000-0000-0000-000000000012', 'pair', 'Legacy B', 'Legacy B');

insert into public.participants (id, tenant_id, full_name, full_name_en) values
  ('75000000-0000-0000-0000-000000000061', '22222222-2222-2222-2222-222222222222', 'VĐV PBLD', 'PBLD athlete');

insert into public.entry_members (tenant_id, entry_id, participant_id) values
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000021', '75000000-0000-0000-0000-000000000061');

insert into public.groups (id, tenant_id, tournament_id, name_vi, name_en, standings_confirmed_at)
values ('75000000-0000-0000-0000-000000000030', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000010', 'Bảng A', 'Group A', now());

insert into public.group_entries (tenant_id, group_id, entry_id, seed_order) values
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000030', '75000000-0000-0000-0000-000000000021', 1),
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000030', '75000000-0000-0000-0000-000000000022', 2);

insert into public.fixtures (id, tenant_id, tournament_id, group_id, status, round_vi, starts_at, bracket_position, winner_entry_id, result_summary_vi) values
  ('75000000-0000-0000-0000-000000000041', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000010', '75000000-0000-0000-0000-000000000030', 'scheduled', 'Vòng bảng', '2026-09-19 09:00:00+07', null, null, ''),
  ('75000000-0000-0000-0000-000000000042', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000010', null, 'scheduled', 'Chung kết', '2026-09-19 11:00:00+07', 1, null, ''),
  ('75000000-0000-0000-0000-000000000043', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000011', null, 'completed', 'Vòng bảng', '2026-09-19 10:00:00+07', null, '75000000-0000-0000-0000-000000000023', 'Control A 8 - 6 Control B'),
  ('75000000-0000-0000-0000-000000000044', '11111111-1111-1111-1111-111111111111', '75000000-0000-0000-0000-000000000012', null, 'completed', 'Vòng bảng', '2026-09-19 10:00:00+07', null, '75000000-0000-0000-0000-000000000025', 'Legacy A 8 - 6 Legacy B');

insert into public.fixture_slots (id, tenant_id, fixture_id, side, source_kind, source_entry_id, source_fixture_id, label_vi, label_en) values
  ('75000000-0000-0000-0000-000000000051', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000041', 'home', 'entry', '75000000-0000-0000-0000-000000000021', null, 'PBLD A', 'PBLD A'),
  ('75000000-0000-0000-0000-000000000052', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000041', 'away', 'entry', '75000000-0000-0000-0000-000000000022', null, 'PBLD B', 'PBLD B'),
  ('75000000-0000-0000-0000-000000000053', '22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000042', 'home', 'fixture_winner', null, '75000000-0000-0000-0000-000000000041', 'Thắng vòng bảng', 'Group winner');

insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side, score, score_numeric, result_status, result_detail) values
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000041', '75000000-0000-0000-0000-000000000021', 'home', '11', 11, 'finished', '{"note":"PBLD note"}'),
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000041', '75000000-0000-0000-0000-000000000022', 'away', '7', 7, 'finished', '{}'),
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000042', '75000000-0000-0000-0000-000000000021', 'home', null, null, null, '{}'),
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000043', '75000000-0000-0000-0000-000000000023', 'home', '8', 8, 'finished', '{"note":"control note"}'),
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000043', '75000000-0000-0000-0000-000000000024', 'away', '6', 6, 'finished', '{}'),
  ('11111111-1111-1111-1111-111111111111', '75000000-0000-0000-0000-000000000044', '75000000-0000-0000-0000-000000000025', 'home', '8', 8, 'finished', '{}'),
  ('11111111-1111-1111-1111-111111111111', '75000000-0000-0000-0000-000000000044', '75000000-0000-0000-0000-000000000026', 'away', '6', 6, 'finished', '{}');

update public.fixtures
set status = 'completed', winner_entry_id = '75000000-0000-0000-0000-000000000021', result_summary_vi = 'PBLD A 11 - 7 PBLD B'
where id = '75000000-0000-0000-0000-000000000041';

insert into public.standings (tenant_id, tournament_id, group_id, entry_id, played, won, score_for, score_against, points, rank, note_vi) values
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000010', '75000000-0000-0000-0000-000000000030', '75000000-0000-0000-0000-000000000021', 1, 1, 11, 7, 3, 1, 'Giữ ghi chú'),
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000010', '75000000-0000-0000-0000-000000000030', '75000000-0000-0000-0000-000000000022', 1, 0, 7, 11, 0, 2, 'Giữ ghi chú'),
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000011', null, '75000000-0000-0000-0000-000000000023', 1, 1, 8, 6, 3, 1, 'Control');

insert into public.awards (tenant_id, sport_id, tournament_id, entry_id, participant_id, medal, title_vi, title_en) values
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000001', '75000000-0000-0000-0000-000000000010', '75000000-0000-0000-0000-000000000021', null, 'gold', 'Giải PBLD', 'PBLD direct award'),
  ('22222222-2222-2222-2222-222222222222', null, '75000000-0000-0000-0000-000000000010', '75000000-0000-0000-0000-000000000021', null, 'silver', 'Giải theo hạng mục', 'PBLD tournament award'),
  ('22222222-2222-2222-2222-222222222222', null, null, '75000000-0000-0000-0000-000000000021', null, 'special', 'Giải theo đội', 'PBLD entry award'),
  ('22222222-2222-2222-2222-222222222222', null, null, null, '75000000-0000-0000-0000-000000000061', 'special', 'Giải theo VĐV', 'PBLD participant award'),
  ('22222222-2222-2222-2222-222222222222', '75000000-0000-0000-0000-000000000002', '75000000-0000-0000-0000-000000000011', '75000000-0000-0000-0000-000000000023', null, 'gold', 'Giải môn khác', 'Control award'),
  ('11111111-1111-1111-1111-111111111111', '75000000-0000-0000-0000-000000000003', '75000000-0000-0000-0000-000000000012', '75000000-0000-0000-0000-000000000025', null, 'gold', 'Giải legacy', 'Legacy award');

set local request.headers = '{"x-tenant-slug":"ptsc2026"}';
set local request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
set local request.jwt.claims = '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';
set local role authenticated;

do $$
declare preview jsonb;
begin
  preview := public.reset_sport_results_and_awards('75000000-0000-0000-0000-000000000001');
  if preview ->> 'fixtures' <> '2' or preview ->> 'fixture_entries' <> '3' or preview ->> 'standings' <> '2' or preview ->> 'confirmed_groups' <> '1' or coalesce(preview ->> 'awards', '') <> '4' then
    raise exception 'sport reset preview counts are wrong: %', preview;
  end if;
  if not exists (select 1 from public.fixtures where id = '75000000-0000-0000-0000-000000000041' and status = 'completed' and winner_entry_id = '75000000-0000-0000-0000-000000000021') then
    raise exception 'preview mutated match results';
  end if;
  if not exists (select 1 from public.fixture_entries where fixture_id = '75000000-0000-0000-0000-000000000041' and score = '11' and result_detail ->> 'note' = 'PBLD note') then
    raise exception 'preview mutated participant results or notes';
  end if;
  if not exists (select 1 from public.standings where tournament_id = '75000000-0000-0000-0000-000000000010' and played = 1 and note_vi = 'Giữ ghi chú') then
    raise exception 'preview mutated standings';
  end if;
  if not exists (select 1 from public.groups where id = '75000000-0000-0000-0000-000000000030' and standings_confirmed_at is not null) then
    raise exception 'preview mutated group confirmation';
  end if;
  if (select count(*) from public.awards where title_en in ('PBLD direct award', 'PBLD tournament award', 'PBLD entry award', 'PBLD participant award') and archived_at is null) <> 4 then
    raise exception 'preview mutated PBLD awards';
  end if;
end $$;

do $$
begin
  begin
    perform public.reset_sport_results_and_awards('75000000-0000-0000-0000-000000000003', true);
    raise exception 'reset accepted a sport from another tenant';
  exception when others then
    if sqlerrm not like '%Môn thể thao không hợp lệ%' then raise; end if;
  end;
end $$;

set local request.headers = '{"x-tenant-slug":"ptsc2026"}';
set local request.jwt.claim.sub = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
set local request.jwt.claims = '{"sub":"cccccccc-cccc-cccc-cccc-cccccccccccc","role":"authenticated"}';
do $$
begin
  begin
    perform public.reset_sport_results_and_awards('75000000-0000-0000-0000-000000000001', true);
    raise exception 'reset accepted a non-admin user';
  exception when others then
    if sqlerrm not like '%Không có quyền quản trị%' then raise; end if;
  end;
end $$;

set local request.headers = '{"x-tenant-slug":"petrovietnam2026"}';
set local request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
do $$
begin
  begin
    perform public.reset_sport_results_and_awards('75000000-0000-0000-0000-000000000003', true);
    raise exception 'reset accepted a legacy tenant';
  exception when others then
    if sqlerrm not like '%Chỉ được reset môn thể thao của tenant PTSC%' then raise; end if;
  end;
end $$;

set local request.headers = '{"x-tenant-slug":"ptsc2026"}';
set local request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
set local request.jwt.claims = '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

select public.reset_sport_results_and_awards('75000000-0000-0000-0000-000000000001', true);

do $$
begin
  if exists (select 1 from public.fixtures where id = '75000000-0000-0000-0000-000000000041' and (status <> 'scheduled' or winner_entry_id is not null or result_summary_vi <> '')) then
    raise exception 'PBLD fixture results were not reset';
  end if;
  if not exists (select 1 from public.fixtures where id = '75000000-0000-0000-0000-000000000041' and starts_at = '2026-09-19 09:00:00+07' and round_vi = 'Vòng bảng') then
    raise exception 'PBLD schedule data was changed';
  end if;
  if not exists (select 1 from public.fixture_entries where fixture_id = '75000000-0000-0000-0000-000000000041' and entry_id = '75000000-0000-0000-0000-000000000021' and archived_at is null and score is null and score_numeric is null and result_status is null and result_detail = '{}') then
    raise exception 'PBLD match participant or result note was not reset safely';
  end if;
  if exists (select 1 from public.fixture_entries where fixture_id = '75000000-0000-0000-0000-000000000042' and archived_at is null) then
    raise exception 'unresolved dependent participant was not resynchronized';
  end if;
  if not exists (select 1 from public.fixture_slots where id = '75000000-0000-0000-0000-000000000053' and archived_at is null and source_fixture_id = '75000000-0000-0000-0000-000000000041') then
    raise exception 'PBLD bracket source structure was changed';
  end if;
  if not exists (select 1 from public.group_entries where group_id = '75000000-0000-0000-0000-000000000030' and entry_id = '75000000-0000-0000-0000-000000000021' and archived_at is null) then
    raise exception 'PBLD roster/group assignment was changed';
  end if;
  if exists (select 1 from public.standings where tournament_id = '75000000-0000-0000-0000-000000000010' and archived_at is null and (played <> 0 or won <> 0 or score_for <> 0 or score_against <> 0 or points <> 0 or rank is not null or note_vi <> 'Giữ ghi chú')) then
    raise exception 'PBLD standings were not reset while preserving notes';
  end if;
  if not exists (select 1 from public.groups where id = '75000000-0000-0000-0000-000000000030' and standings_confirmed_at is null) then
    raise exception 'PBLD group confirmation was not cleared';
  end if;
  if exists (select 1 from public.awards where tenant_id = '22222222-2222-2222-2222-222222222222' and archived_at is null and (sport_id = '75000000-0000-0000-0000-000000000001' or tournament_id = '75000000-0000-0000-0000-000000000010' or entry_id = '75000000-0000-0000-0000-000000000021')) then
    raise exception 'PBLD awards were not archived';
  end if;
  if not exists (select 1 from public.awards where title_en = 'PBLD direct award' and archived_at is not null)
    or not exists (select 1 from public.awards where title_en = 'PBLD tournament award' and archived_at is not null)
    or not exists (select 1 from public.awards where title_en = 'PBLD entry award' and archived_at is not null)
    or not exists (select 1 from public.awards where title_en = 'PBLD participant award' and archived_at is not null) then
    raise exception 'PBLD award history was not preserved';
  end if;
  if not exists (select 1 from public.awards where title_en = 'Control award' and archived_at is null) then
    raise exception 'another PTSC sport awards were changed';
  end if;
  if not exists (select 1 from public.fixtures where id = '75000000-0000-0000-0000-000000000043' and status = 'completed' and winner_entry_id = '75000000-0000-0000-0000-000000000023') then
    raise exception 'another PTSC sport was changed';
  end if;
end $$;

select public.reset_sport_results_and_awards('75000000-0000-0000-0000-000000000001', true);

set local role postgres;
do $$
begin
  if not exists (select 1 from public.fixtures where id = '75000000-0000-0000-0000-000000000044' and status = 'completed' and winner_entry_id = '75000000-0000-0000-0000-000000000025') then
    raise exception 'legacy tenant data was changed';
  end if;
  if not exists (select 1 from public.awards where title_en = 'Legacy award' and archived_at is null) then
    raise exception 'legacy tenant awards were changed';
  end if;
end $$;

rollback;
