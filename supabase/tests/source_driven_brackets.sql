begin;
set local app.tenant_slug = 'petrovietnam2026';
set local role postgres;

insert into public.sports (id, tenant_id, slug, name_vi, name_en, emoji)
values ('71000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'bracket-test', 'Bracket test', 'Bracket test', 'T');

insert into public.tournaments (id, tenant_id, sport_id, slug, name_vi, name_en, competition_mode)
values ('71000000-0000-0000-0000-000000000010', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000001', 'knockout', 'Loại trực tiếp', 'Knockout', 'knockout');

insert into public.entries (id, tenant_id, tournament_id, kind, name_vi, name_en) values
  ('71000000-0000-0000-0000-000000000021', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'individual', 'A', 'A'),
  ('71000000-0000-0000-0000-000000000022', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'individual', 'B', 'B'),
  ('71000000-0000-0000-0000-000000000023', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'individual', 'C', 'C'),
  ('71000000-0000-0000-0000-000000000024', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'individual', 'D', 'D');

insert into public.fixtures (id, tenant_id, tournament_id, status, round_vi, round_en, round_order, bracket_position, winner_entry_id) values
  ('71000000-0000-0000-0000-000000000031', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'scheduled', 'Bán kết 1', 'Semifinal 1', 1, 1, null),
  ('71000000-0000-0000-0000-000000000032', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'scheduled', 'Bán kết 2', 'Semifinal 2', 1, 2, null),
  ('71000000-0000-0000-0000-000000000033', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'scheduled', 'Chung kết', 'Final', 2, 1, null);

insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side) values
  ('11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000031', '71000000-0000-0000-0000-000000000021', 'home'),
  ('11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000031', '71000000-0000-0000-0000-000000000022', 'away'),
  ('11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000032', '71000000-0000-0000-0000-000000000023', 'home'),
  ('11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000032', '71000000-0000-0000-0000-000000000024', 'away');

insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side) values
  ('11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000033', '71000000-0000-0000-0000-000000000022', null),
  ('11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000033', '71000000-0000-0000-0000-000000000024', null);

insert into public.fixture_slots (id, tenant_id, fixture_id, side, source_kind, source_fixture_id, label_vi, label_en) values
  ('71000000-0000-0000-0000-000000000041', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000033', 'home', 'fixture_winner', '71000000-0000-0000-0000-000000000031', 'Thắng BK1', 'Winner SF1'),
  ('71000000-0000-0000-0000-000000000042', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000033', 'away', 'fixture_winner', '71000000-0000-0000-0000-000000000032', 'Thắng BK2', 'Winner SF2');

update public.fixture_entries
set score_numeric = case side when 'home' then 11 when 'away' then 4 end
where fixture_id in ('71000000-0000-0000-0000-000000000031', '71000000-0000-0000-0000-000000000032');

update public.fixtures
set status = 'completed', winner_entry_id = case id
  when '71000000-0000-0000-0000-000000000031' then '71000000-0000-0000-0000-000000000021'::uuid
  else '71000000-0000-0000-0000-000000000023'::uuid
end
where id in ('71000000-0000-0000-0000-000000000031', '71000000-0000-0000-0000-000000000032');

select private.sync_fixture_slots('71000000-0000-0000-0000-000000000031');
select private.sync_fixture_slots('71000000-0000-0000-0000-000000000032');

do $$
begin
  if not exists (select 1 from public.fixture_entries where fixture_id = '71000000-0000-0000-0000-000000000033' and side = 'home' and entry_id = '71000000-0000-0000-0000-000000000021' and archived_at is null) then
    raise exception 'winner propagation failed';
  end if;
  if (select count(*) from public.fixture_entries where fixture_id = '71000000-0000-0000-0000-000000000033' and archived_at is null) <> 2
    or exists (select 1 from public.fixture_entries where fixture_id = '71000000-0000-0000-0000-000000000033' and archived_at is null and side is null) then
    raise exception 'winner propagation left legacy participant rows';
  end if;
end $$;

update public.fixture_entries set score_numeric = case side when 'home' then 11 else 8 end
where fixture_id = '71000000-0000-0000-0000-000000000033' and archived_at is null;
update public.fixtures
set status = 'completed', winner_entry_id = '71000000-0000-0000-0000-000000000021'
where id = '71000000-0000-0000-0000-000000000033';

set local request.headers = '{"x-tenant-slug":"petrovietnam2026"}';
set local request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
set local role authenticated;

do $$
begin
  begin
    perform public.save_fixture_result(
      '71000000-0000-0000-0000-000000000031', 'completed',
      '71000000-0000-0000-0000-000000000022', '', '',
      '[{"entry_id":"71000000-0000-0000-0000-000000000021","side":"home","score_numeric":4},{"entry_id":"71000000-0000-0000-0000-000000000022","side":"away","score_numeric":11}]'::jsonb,
      null
    );
    raise exception 'completed dependent did not block';
  exception when others then
    if sqlerrm not like '%Trận phụ thuộc đã có kết quả%' then raise; end if;
  end;
end $$;

do $$
declare preview jsonb;
begin
  preview := public.reset_fixture_dependents('71000000-0000-0000-0000-000000000031', false);
  if preview ->> 'blocked' <> 'true' or jsonb_array_length(preview -> 'fixtures') <> 1 then
    raise exception 'reset preview failed: %', preview;
  end if;
  if not exists (select 1 from public.fixtures where id = '71000000-0000-0000-0000-000000000033' and status = 'completed') then
    raise exception 'preview mutated dependent';
  end if;
end $$;

select public.reset_fixture_dependents('71000000-0000-0000-0000-000000000031', true);

do $$
begin
  if not exists (select 1 from public.fixtures where id = '71000000-0000-0000-0000-000000000033' and status = 'scheduled' and winner_entry_id is null) then
    raise exception 'confirmed reset failed';
  end if;
end $$;

select public.save_fixture_result(
  '71000000-0000-0000-0000-000000000031', 'completed',
  '71000000-0000-0000-0000-000000000022', '', '',
  '[{"entry_id":"71000000-0000-0000-0000-000000000021","side":"home","score_numeric":4},{"entry_id":"71000000-0000-0000-0000-000000000022","side":"away","score_numeric":11}]'::jsonb,
  null
);

do $$
begin
  if not exists (select 1 from public.fixture_entries where fixture_id = '71000000-0000-0000-0000-000000000033' and side = 'home' and entry_id = '71000000-0000-0000-0000-000000000022' and archived_at is null) then
    raise exception 'corrected winner propagation failed';
  end if;
end $$;

rollback;
