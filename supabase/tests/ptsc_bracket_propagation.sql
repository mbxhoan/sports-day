begin;
set local app.tenant_slug = 'ptsc2026';
set local role postgres;

insert into public.sports (id, tenant_id, slug, name_vi, name_en, emoji)
values ('74000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'propagation-test', 'Propagation test', 'Propagation test', 'P');

insert into public.tournaments (id, tenant_id, sport_id, slug, name_vi, name_en, competition_mode)
values ('74000000-0000-0000-0000-000000000010', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000001', 'knockout', 'Propagation test', 'Propagation test', 'group_knockout');

insert into public.entries (id, tenant_id, tournament_id, kind, name_vi, name_en) values
  ('74000000-0000-0000-0000-000000000021', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'individual', 'A', 'A'),
  ('74000000-0000-0000-0000-000000000022', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'individual', 'B', 'B'),
  ('74000000-0000-0000-0000-000000000023', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'individual', 'C', 'C'),
  ('74000000-0000-0000-0000-000000000024', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'individual', 'D', 'D');

insert into public.groups (id, tenant_id, tournament_id, name_vi, name_en)
values ('74000000-0000-0000-0000-000000000030', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'Bảng A', 'Group A');

insert into public.group_entries (tenant_id, group_id, entry_id, seed_order) values
  ('22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000030', '74000000-0000-0000-0000-000000000021', 1),
  ('22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000030', '74000000-0000-0000-0000-000000000022', 2);

insert into public.standings (tenant_id, tournament_id, group_id, entry_id, rank, points) values
  ('22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', '74000000-0000-0000-0000-000000000030', '74000000-0000-0000-0000-000000000021', 1, 3),
  ('22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', '74000000-0000-0000-0000-000000000030', '74000000-0000-0000-0000-000000000022', 2, 0);

insert into public.fixtures (id, tenant_id, tournament_id, status, round_vi, round_en, round_order, bracket_position) values
  ('74000000-0000-0000-0000-000000000031', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'scheduled', 'Tứ kết', 'Quarterfinal', 1, 1),
  ('74000000-0000-0000-0000-000000000032', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'scheduled', 'Bán kết', 'Semifinal', 2, 1),
  ('74000000-0000-0000-0000-000000000033', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000010', 'scheduled', 'Chung kết', 'Final', 3, 1);

insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side) values
  ('22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000031', '74000000-0000-0000-0000-000000000023', 'away'),
  ('22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000032', '74000000-0000-0000-0000-000000000024', 'away'),
  ('22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000033', '74000000-0000-0000-0000-000000000023', 'away');

insert into public.fixture_slots (id, tenant_id, fixture_id, side, source_kind, source_group_id, source_rank, label_vi, label_en) values
  ('74000000-0000-0000-0000-000000000041', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000031', 'home', 'group_rank', '74000000-0000-0000-0000-000000000030', 1, 'Nhất A', '1st A');
insert into public.fixture_slots (id, tenant_id, fixture_id, side, source_kind, source_fixture_id, label_vi, label_en) values
  ('74000000-0000-0000-0000-000000000042', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000032', 'home', 'fixture_winner', '74000000-0000-0000-0000-000000000031', 'Thắng TK', 'Quarterfinal winner'),
  ('74000000-0000-0000-0000-000000000043', '22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000033', 'home', 'fixture_winner', '74000000-0000-0000-0000-000000000032', 'Thắng BK', 'Semifinal winner');

set local request.headers = '{"x-tenant-slug":"ptsc2026"}';
set local request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
set local request.jwt.claims = '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';
set local role authenticated;

select public.confirm_group_standings('74000000-0000-0000-0000-000000000030');

do $$
begin
  if not exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000031' and side = 'home' and entry_id = '74000000-0000-0000-0000-000000000021' and archived_at is null) then
    raise exception 'group rank did not populate PTSC bracket';
  end if;
end $$;

select public.save_manual_standings(
  '74000000-0000-0000-0000-000000000010',
  '74000000-0000-0000-0000-000000000030',
  '[
    {"entry_id":"74000000-0000-0000-0000-000000000021","played":0,"won":0,"drawn":0,"lost":0,"score_for":0,"score_against":0,"points":0,"rank":2},
    {"entry_id":"74000000-0000-0000-0000-000000000022","played":0,"won":0,"drawn":0,"lost":0,"score_for":0,"score_against":0,"points":3,"rank":1}
  ]'::jsonb
);
select public.confirm_group_standings('74000000-0000-0000-0000-000000000030');

do $$
begin
  if not exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000031' and side = 'home' and entry_id = '74000000-0000-0000-0000-000000000022' and archived_at is null) then
    raise exception 'updated group rank did not refresh PTSC bracket';
  end if;
end $$;

select public.save_manual_standings(
  '74000000-0000-0000-0000-000000000010',
  '74000000-0000-0000-0000-000000000030',
  '[
    {"entry_id":"74000000-0000-0000-0000-000000000021","played":0,"won":0,"drawn":0,"lost":0,"score_for":0,"score_against":0,"points":0,"rank":2},
    {"entry_id":"74000000-0000-0000-0000-000000000022","played":0,"won":0,"drawn":0,"lost":0,"score_for":0,"score_against":0,"points":0,"rank":3}
  ]'::jsonb
);
select public.confirm_group_standings('74000000-0000-0000-0000-000000000030');

do $$
begin
  if exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000031' and side = 'home' and archived_at is null) then
    raise exception 'unresolved group rank did not clear PTSC source fixture';
  end if;
  if exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000032' and side = 'home' and archived_at is null) then
    raise exception 'unresolved group rank did not clear PTSC downstream fixture';
  end if;
  if exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000033' and side = 'home' and archived_at is null) then
    raise exception 'unresolved group rank did not clear PTSC deep fixture';
  end if;
end $$;

select public.save_manual_standings(
  '74000000-0000-0000-0000-000000000010',
  '74000000-0000-0000-0000-000000000030',
  '[
    {"entry_id":"74000000-0000-0000-0000-000000000021","played":0,"won":0,"drawn":0,"lost":0,"score_for":0,"score_against":0,"points":0,"rank":2},
    {"entry_id":"74000000-0000-0000-0000-000000000022","played":0,"won":0,"drawn":0,"lost":0,"score_for":0,"score_against":0,"points":3,"rank":1}
  ]'::jsonb
);
select public.confirm_group_standings('74000000-0000-0000-0000-000000000030');

select public.save_fixture_result(
  '74000000-0000-0000-0000-000000000031', 'completed',
  '74000000-0000-0000-0000-000000000022', 'B 3 - 1 C', 'B 3 - 1 C',
  '[{"entry_id":"74000000-0000-0000-0000-000000000022","side":"home","score_numeric":3},{"entry_id":"74000000-0000-0000-0000-000000000023","side":"away","score_numeric":1}]'::jsonb,
  null
);

do $$
begin
  if not exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000032' and side = 'home' and entry_id = '74000000-0000-0000-0000-000000000022' and archived_at is null) then
    raise exception 'winner did not populate immediate PTSC fixture';
  end if;
  if exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000033' and side = 'home' and archived_at is null) then
    raise exception 'unfinished winner propagated too early';
  end if;
end $$;

select public.save_fixture_result(
  '74000000-0000-0000-0000-000000000032', 'completed',
  '74000000-0000-0000-0000-000000000022', 'B 2 - 0 D', 'B 2 - 0 D',
  '[{"entry_id":"74000000-0000-0000-0000-000000000022","side":"home","score_numeric":2},{"entry_id":"74000000-0000-0000-0000-000000000024","side":"away","score_numeric":0}]'::jsonb,
  null
);

do $$
begin
  if not exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000033' and side = 'home' and entry_id = '74000000-0000-0000-0000-000000000022' and archived_at is null) then
    raise exception 'winner did not populate next PTSC fixture';
  end if;
end $$;

update public.fixture_entries
set archived_at = now()
where fixture_id = '74000000-0000-0000-0000-000000000033' and side = 'home' and archived_at is null;
insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side)
values ('22222222-2222-2222-2222-222222222222', '74000000-0000-0000-0000-000000000033', '74000000-0000-0000-0000-000000000021', 'home');
select private.sync_fixture_slots('74000000-0000-0000-0000-000000000031');

do $$
begin
  if not exists (select 1 from public.fixture_entries where fixture_id = '74000000-0000-0000-0000-000000000033' and side = 'home' and entry_id = '74000000-0000-0000-0000-000000000022' and archived_at is null) then
    raise exception 'deep PTSC propagation failed';
  end if;
end $$;

do $$
begin
  begin
    perform public.save_fixture_result(
      '74000000-0000-0000-0000-000000000031', 'completed',
      '74000000-0000-0000-0000-000000000023', 'C 4 - 1 B', 'C 4 - 1 B',
      '[{"entry_id":"74000000-0000-0000-0000-000000000022","side":"home","score_numeric":1},{"entry_id":"74000000-0000-0000-0000-000000000023","side":"away","score_numeric":4}]'::jsonb,
      null
    );
    raise exception 'dependent PTSC result did not block';
  exception when others then
    if sqlerrm not like '%Trận phụ thuộc đã có kết quả%' then raise; end if;
  end;
  if not exists (select 1 from public.fixtures where id = '74000000-0000-0000-0000-000000000031' and winner_entry_id = '74000000-0000-0000-0000-000000000022') then
    raise exception 'blocked update mutated source result';
  end if;
end $$;

rollback;
