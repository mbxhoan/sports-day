set app.tenant_slug = 'ptsc2026';

do $$
declare
  v_tenant_id uuid := private.seed_tenant_id();
  v_tournament_id uuid;
  v_fixture_id uuid;
  v_group_id uuid;
  v_source_entry_id uuid;
  v_source_group_id uuid;
  v_source_fixture_id uuid;
  v_source_kind text;
  v_category text;
  v_round integer;
  v_position integer;
  v_round_size integer;
  v_fixture record;
  v_slot record;
begin
  if v_tenant_id is null then
    raise exception 'PTSC: không tìm thấy tenant';
  end if;

  -- Confirmed by BTC: this athlete belongs to the women's 5 km category.
  perform private.upsert_ptsc_position(v_tenant_id, $row${
    "category_code":"DK-NU45-5K",
    "sport_slug":"dien-kinh",
    "normalized_group":"X",
    "slot_no":16,
    "members":["Hà Thị Thảo Trinh"],
    "reserves":[],
    "unit":"PTSC Miền Trung",
    "note":"BTC xác nhận: Nữ dưới 45 tuổi - 5 km; PDF vẫn hiển thị ở trang Nữ dưới 45 tuổi - 10 km",
    "pdf_page":"8",
    "kind":"individual",
    "status":"active",
    "natural_key":"DK-NU45-5K|X|16"
  }$row$::jsonb);

  update public.fixture_entries item
  set archived_at = clock_timestamp()
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  where item.entry_id = entry.id
    and entry.tenant_id = v_tenant_id
    and tournament.tenant_id = v_tenant_id
    and tournament.category_code = 'DK-NU45-10K'
    and entry.name_vi = 'Hà Thị Thảo Trinh'
    and item.archived_at is null;

  update public.entry_members item
  set archived_at = clock_timestamp()
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  where item.entry_id = entry.id
    and entry.tenant_id = v_tenant_id
    and tournament.tenant_id = v_tenant_id
    and tournament.category_code = 'DK-NU45-10K'
    and entry.name_vi = 'Hà Thị Thảo Trinh'
    and item.archived_at is null;

  update public.group_entries item
  set archived_at = clock_timestamp()
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  where item.entry_id = entry.id
    and entry.tenant_id = v_tenant_id
    and tournament.tenant_id = v_tenant_id
    and tournament.category_code = 'DK-NU45-10K'
    and entry.name_vi = 'Hà Thị Thảo Trinh'
    and item.archived_at is null;

  update public.standings item
  set archived_at = clock_timestamp()
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  where item.entry_id = entry.id
    and entry.tenant_id = v_tenant_id
    and tournament.tenant_id = v_tenant_id
    and tournament.category_code = 'DK-NU45-10K'
    and entry.name_vi = 'Hà Thị Thảo Trinh'
    and item.archived_at is null;

  update public.entries entry
  set source_status = 'archived', archived_at = clock_timestamp()
  from public.tournaments tournament
  where tournament.id = entry.tournament_id
    and entry.tenant_id = v_tenant_id
    and tournament.tenant_id = v_tenant_id
    and tournament.category_code = 'DK-NU45-10K'
    and entry.name_vi = 'Hà Thị Thảo Trinh'
    and entry.archived_at is null;

  update public.tournaments
  set source_metadata = coalesce(source_metadata, '{}'::jsonb) || jsonb_build_object(
    'athletics_confirmation', 'Hà Thị Thảo Trinh thuộc DK-NU45-5K theo xác nhận BTC',
    'pdf_discrepancy', 'PDF trang 8 vẫn hiển thị tên ở DK-NU45-10K'
  )
  where tenant_id = v_tenant_id and category_code = 'DK-NU45-5K' and archived_at is null;

  update public.tournaments
  set workflow_status = 'active',
      format_vi = 'Seed 1-8; TK 1-8, 4-5, 2-7, 6-3; BK; CK',
      format_en = 'Seeds 1-8; QF 1-8, 4-5, 2-7, 6-3; SF; Final',
      source_metadata = coalesce(source_metadata, '{}'::jsonb) || jsonb_build_object(
        'bracket_confirmation', 'BTC xác nhận ngày 14/09/2026: Tứ kết 3 = Seed 2 vs Seed 7',
        'bracket_source_page', 21
      )
  where tenant_id = v_tenant_id and category_code = 'PB-DOI-NAM46' and archived_at is null;

  create temporary table ptsc_bracket_fixtures (
    category_code text not null,
    source_code text not null,
    round_order integer not null,
    bracket_position integer not null,
    round_vi text not null,
    round_en text not null,
    primary key (category_code, source_code)
  ) on commit drop;

  create temporary table ptsc_bracket_slots (
    category_code text not null,
    source_code text not null,
    side text not null,
    source_kind text not null,
    source_group_code text,
    source_rank integer,
    source_fixture_code text,
    source_slot_no integer,
    label_vi text not null,
    label_en text not null,
    primary key (category_code, source_code, side)
  ) on commit drop;

  -- Two group semifinals and a final.
  for v_category in
    select unnest(array[
      'BB-DON-NAM45', 'BB-DON-NAM46', 'BB-DON-NU45', 'BB-DOI-NAMNU45',
      'BDNA-DONGDOI', 'BDNB-DONGDOI', 'CL-DON-NAM45', 'CL-DON-NAM46',
      'TEN-DON-NAM45'
    ])
  loop
    insert into ptsc_bracket_fixtures values
      (v_category, 'SF1', 1, 1, 'Bán kết 1', 'Semifinal 1'),
      (v_category, 'SF2', 1, 2, 'Bán kết 2', 'Semifinal 2'),
      (v_category, 'F', 2, 1, 'Chung kết', 'Final');

    insert into ptsc_bracket_slots values
      (v_category, 'SF1', 'home', 'group_rank', 'A', 1, null, null, 'Nhất A', '1st A'),
      (v_category, 'SF1', 'away', 'group_rank', 'B', 2, null, null, 'Nhì B', '2nd B'),
      (v_category, 'SF2', 'home', 'group_rank', 'B', 1, null, null, 'Nhất B', '1st B'),
      (v_category, 'SF2', 'away', 'group_rank', 'A', 2, null, null, 'Nhì A', '2nd A'),
      (v_category, 'F', 'home', 'fixture_winner', null, null, 'SF1', null, 'Thắng bán kết 1', 'Winner SF1'),
      (v_category, 'F', 'away', 'fixture_winner', null, null, 'SF2', null, 'Thắng bán kết 2', 'Winner SF2');
  end loop;

  -- Four-group quarterfinals, semifinals and final.
  for v_category in
    select unnest(array[
      'BB-DOI-NAM45', 'PBLD-DOI-NAM', 'PB-DON-NAM46', 'PB-DON-NU45',
      'PB-DOI-NAMNU46'
    ])
  loop
    insert into ptsc_bracket_fixtures values
      (v_category, 'QF1', 1, 1, 'Tứ kết 1', 'Quarterfinal 1'),
      (v_category, 'QF2', 1, 2, 'Tứ kết 2', 'Quarterfinal 2'),
      (v_category, 'QF3', 1, 3, 'Tứ kết 3', 'Quarterfinal 3'),
      (v_category, 'QF4', 1, 4, 'Tứ kết 4', 'Quarterfinal 4'),
      (v_category, 'SF1', 2, 1, 'Bán kết 1', 'Semifinal 1'),
      (v_category, 'SF2', 2, 2, 'Bán kết 2', 'Semifinal 2'),
      (v_category, 'F', 3, 1, 'Chung kết', 'Final');

    insert into ptsc_bracket_slots values
      (v_category, 'QF1', 'home', 'group_rank', 'A', 1, null, null, 'Nhất A', '1st A'),
      (v_category, 'QF1', 'away', 'group_rank', 'B', 2, null, null, 'Nhì B', '2nd B'),
      (v_category, 'QF2', 'home', 'group_rank', 'C', 1, null, null, 'Nhất C', '1st C'),
      (v_category, 'QF2', 'away', 'group_rank', 'D', 2, null, null, 'Nhì D', '2nd D'),
      (v_category, 'QF3', 'home', 'group_rank', 'A', 2, null, null, 'Nhì A', '2nd A'),
      (v_category, 'QF3', 'away', 'group_rank', 'B', 1, null, null, 'Nhất B', '1st B'),
      (v_category, 'QF4', 'home', 'group_rank', 'C', 2, null, null, 'Nhì C', '2nd C'),
      (v_category, 'QF4', 'away', 'group_rank', 'D', 1, null, null, 'Nhất D', '1st D'),
      (v_category, 'SF1', 'home', 'fixture_winner', null, null, 'QF1', null, 'Thắng tứ kết 1', 'Winner QF1'),
      (v_category, 'SF1', 'away', 'fixture_winner', null, null, 'QF2', null, 'Thắng tứ kết 2', 'Winner QF2'),
      (v_category, 'SF2', 'home', 'fixture_winner', null, null, 'QF3', null, 'Thắng tứ kết 3', 'Winner QF3'),
      (v_category, 'SF2', 'away', 'fixture_winner', null, null, 'QF4', null, 'Thắng tứ kết 4', 'Winner QF4'),
      (v_category, 'F', 'home', 'fixture_winner', null, null, 'SF1', null, 'Thắng bán kết 1', 'Winner SF1'),
      (v_category, 'F', 'away', 'fixture_winner', null, null, 'SF2', null, 'Thắng bán kết 2', 'Winner SF2');
  end loop;

  -- Three-group branches with the best runner-up placeholder.
  for v_category in
    select unnest(array['CL-DOI-NAM45', 'TEN-DON-NAM46', 'TEN-DOI-NAM45'])
  loop
    insert into ptsc_bracket_fixtures values
      (v_category, 'SF1', 1, 1, 'Bán kết 1', 'Semifinal 1'),
      (v_category, 'SF2', 1, 2, 'Bán kết 2', 'Semifinal 2'),
      (v_category, 'F', 2, 1, 'Chung kết', 'Final');

    insert into ptsc_bracket_slots values
      (v_category, 'SF1', 'home', 'group_rank', 'A', 1, null, null, 'Nhất A', '1st A'),
      (v_category, 'SF1', 'away', 'group_rank', 'B', 1, null, null, 'Nhất B', '1st B'),
      (v_category, 'SF2', 'home', 'group_rank', 'C', 1, null, null, 'Nhất C', '1st C'),
      (v_category, 'SF2', 'away', 'bye', null, null, null, null, 'Nhì có điểm cao nhất', 'Best runner-up'),
      (v_category, 'F', 'home', 'fixture_winner', null, null, 'SF1', null, 'Thắng bán kết 1', 'Winner SF1'),
      (v_category, 'F', 'away', 'fixture_winner', null, null, 'SF2', null, 'Thắng bán kết 2', 'Winner SF2');
  end loop;

  -- Eight-group round of 16, quarterfinals, semifinals and final.
  for v_category in
    select unnest(array['PB-DON-NAM45', 'PB-DOI-NAM45', 'PB-DOI-NAMNU45'])
  loop
    insert into ptsc_bracket_fixtures values
      (v_category, 'R16-1', 1, 1, 'Vòng 1/8 - 1', 'Round of 16 - 1'),
      (v_category, 'R16-2', 1, 2, 'Vòng 1/8 - 2', 'Round of 16 - 2'),
      (v_category, 'R16-3', 1, 3, 'Vòng 1/8 - 3', 'Round of 16 - 3'),
      (v_category, 'R16-4', 1, 4, 'Vòng 1/8 - 4', 'Round of 16 - 4'),
      (v_category, 'R16-5', 1, 5, 'Vòng 1/8 - 5', 'Round of 16 - 5'),
      (v_category, 'R16-6', 1, 6, 'Vòng 1/8 - 6', 'Round of 16 - 6'),
      (v_category, 'R16-7', 1, 7, 'Vòng 1/8 - 7', 'Round of 16 - 7'),
      (v_category, 'R16-8', 1, 8, 'Vòng 1/8 - 8', 'Round of 16 - 8'),
      (v_category, 'QF1', 2, 1, 'Tứ kết 1', 'Quarterfinal 1'),
      (v_category, 'QF2', 2, 2, 'Tứ kết 2', 'Quarterfinal 2'),
      (v_category, 'QF3', 2, 3, 'Tứ kết 3', 'Quarterfinal 3'),
      (v_category, 'QF4', 2, 4, 'Tứ kết 4', 'Quarterfinal 4'),
      (v_category, 'SF1', 3, 1, 'Bán kết 1', 'Semifinal 1'),
      (v_category, 'SF2', 3, 2, 'Bán kết 2', 'Semifinal 2'),
      (v_category, 'F', 4, 1, 'Chung kết', 'Final');

    insert into ptsc_bracket_slots values
      (v_category, 'R16-1', 'home', 'group_rank', 'A', 1, null, null, 'Nhất A', '1st A'),
      (v_category, 'R16-1', 'away', 'group_rank', 'B', 2, null, null, 'Nhì B', '2nd B'),
      (v_category, 'R16-2', 'home', 'group_rank', 'C', 1, null, null, 'Nhất C', '1st C'),
      (v_category, 'R16-2', 'away', 'group_rank', 'D', 2, null, null, 'Nhì D', '2nd D'),
      (v_category, 'R16-3', 'home', 'group_rank', 'E', 1, null, null, 'Nhất E', '1st E'),
      (v_category, 'R16-3', 'away', 'group_rank', 'F', 2, null, null, 'Nhì F', '2nd F'),
      (v_category, 'R16-4', 'home', 'group_rank', 'G', 1, null, null, 'Nhất G', '1st G'),
      (v_category, 'R16-4', 'away', 'group_rank', 'H', 2, null, null, 'Nhì H', '2nd H'),
      (v_category, 'R16-5', 'home', 'group_rank', 'B', 1, null, null, 'Nhất B', '1st B'),
      (v_category, 'R16-5', 'away', 'group_rank', 'A', 2, null, null, 'Nhì A', '2nd A'),
      (v_category, 'R16-6', 'home', 'group_rank', 'D', 1, null, null, 'Nhất D', '1st D'),
      (v_category, 'R16-6', 'away', 'group_rank', 'C', 2, null, null, 'Nhì C', '2nd C'),
      (v_category, 'R16-7', 'home', 'group_rank', 'F', 1, null, null, 'Nhất F', '1st F'),
      (v_category, 'R16-7', 'away', 'group_rank', 'E', 2, null, null, 'Nhì E', '2nd E'),
      (v_category, 'R16-8', 'home', 'group_rank', 'H', 1, null, null, 'Nhất H', '1st H'),
      (v_category, 'R16-8', 'away', 'group_rank', 'G', 2, null, null, 'Nhì G', '2nd G'),
      (v_category, 'QF1', 'home', 'fixture_winner', null, null, 'R16-1', null, 'Thắng vòng 1/8 - 1', 'Winner R16-1'),
      (v_category, 'QF1', 'away', 'fixture_winner', null, null, 'R16-2', null, 'Thắng vòng 1/8 - 2', 'Winner R16-2'),
      (v_category, 'QF2', 'home', 'fixture_winner', null, null, 'R16-3', null, 'Thắng vòng 1/8 - 3', 'Winner R16-3'),
      (v_category, 'QF2', 'away', 'fixture_winner', null, null, 'R16-4', null, 'Thắng vòng 1/8 - 4', 'Winner R16-4'),
      (v_category, 'QF3', 'home', 'fixture_winner', null, null, 'R16-5', null, 'Thắng vòng 1/8 - 5', 'Winner R16-5'),
      (v_category, 'QF3', 'away', 'fixture_winner', null, null, 'R16-6', null, 'Thắng vòng 1/8 - 6', 'Winner R16-6'),
      (v_category, 'QF4', 'home', 'fixture_winner', null, null, 'R16-7', null, 'Thắng vòng 1/8 - 7', 'Winner R16-7'),
      (v_category, 'QF4', 'away', 'fixture_winner', null, null, 'R16-8', null, 'Thắng vòng 1/8 - 8', 'Winner R16-8'),
      (v_category, 'SF1', 'home', 'fixture_winner', null, null, 'QF1', null, 'Thắng tứ kết 1', 'Winner QF1'),
      (v_category, 'SF1', 'away', 'fixture_winner', null, null, 'QF2', null, 'Thắng tứ kết 2', 'Winner QF2'),
      (v_category, 'SF2', 'home', 'fixture_winner', null, null, 'QF3', null, 'Thắng tứ kết 3', 'Winner QF3'),
      (v_category, 'SF2', 'away', 'fixture_winner', null, null, 'QF4', null, 'Thắng tứ kết 4', 'Winner QF4'),
      (v_category, 'F', 'home', 'fixture_winner', null, null, 'SF1', null, 'Thắng bán kết 1', 'Winner SF1'),
      (v_category, 'F', 'away', 'fixture_winner', null, null, 'SF2', null, 'Thắng bán kết 2', 'Winner SF2');
  end loop;

  -- Seeded eight-team branches. QF3 is deliberately Seed 2 vs Seed 7.
  for v_category in select unnest(array['PB-DOI-NAM46', 'PB-DOI-NU45'])
  loop
    insert into ptsc_bracket_fixtures values
      (v_category, 'QF1', 1, 1, 'Tứ kết 1', 'Quarterfinal 1'),
      (v_category, 'QF2', 1, 2, 'Tứ kết 2', 'Quarterfinal 2'),
      (v_category, 'QF3', 1, 3, 'Tứ kết 3', 'Quarterfinal 3'),
      (v_category, 'QF4', 1, 4, 'Tứ kết 4', 'Quarterfinal 4'),
      (v_category, 'SF1', 2, 1, 'Bán kết 1', 'Semifinal 1'),
      (v_category, 'SF2', 2, 2, 'Bán kết 2', 'Semifinal 2'),
      (v_category, 'F', 3, 1, 'Chung kết', 'Final');

    insert into ptsc_bracket_slots values
      (v_category, 'QF1', 'home', 'bye', null, null, null, null, 'Seed 1', 'Seed 1'),
      (v_category, 'QF1', 'away', 'bye', null, null, null, null, 'Seed 8', 'Seed 8'),
      (v_category, 'QF2', 'home', 'bye', null, null, null, null, 'Seed 4', 'Seed 4'),
      (v_category, 'QF2', 'away', 'bye', null, null, null, null, 'Seed 5', 'Seed 5'),
      (v_category, 'QF3', 'home', 'bye', null, null, null, null, 'Seed 2', 'Seed 2'),
      (v_category, 'QF3', 'away', 'bye', null, null, null, null, 'Seed 7', 'Seed 7'),
      (v_category, 'QF4', 'home', 'bye', null, null, null, null, 'Seed 6', 'Seed 6'),
      (v_category, 'QF4', 'away', 'bye', null, null, null, null, 'Seed 3', 'Seed 3'),
      (v_category, 'SF1', 'home', 'fixture_winner', null, null, 'QF1', null, 'Thắng tứ kết 1', 'Winner QF1'),
      (v_category, 'SF1', 'away', 'fixture_winner', null, null, 'QF2', null, 'Thắng tứ kết 2', 'Winner QF2'),
      (v_category, 'SF2', 'home', 'fixture_winner', null, null, 'QF3', null, 'Thắng tứ kết 3', 'Winner QF3'),
      (v_category, 'SF2', 'away', 'fixture_winner', null, null, 'QF4', null, 'Thắng tứ kết 4', 'Winner QF4'),
      (v_category, 'F', 'home', 'fixture_winner', null, null, 'SF1', null, 'Thắng bán kết 1', 'Winner SF1'),
      (v_category, 'F', 'away', 'fixture_winner', null, null, 'SF2', null, 'Thắng bán kết 2', 'Winner SF2');
  end loop;

  -- Kéo co: the first round is attached to the 16 source positions in order.
  v_category := 'KC-DONGDOI';
  v_round_size := 8;
  for v_round in 1..4
  loop
    for v_position in 1..v_round_size
    loop
      insert into ptsc_bracket_fixtures values (
        v_category,
        case v_round when 1 then 'R16-' when 2 then 'QF' when 3 then 'SF' else 'F' end || v_position,
        v_round,
        v_position,
        case v_round when 1 then 'Vòng 1/8' when 2 then 'Tứ kết' when 3 then 'Bán kết' else 'Chung kết' end,
        case v_round when 1 then 'Round of 16' when 2 then 'Quarterfinal' when 3 then 'Semifinal' else 'Final' end
      );
    end loop;
    v_round_size := v_round_size / 2;
  end loop;

  v_round_size := 8;
  for v_round in 1..4
  loop
    for v_position in 1..v_round_size
    loop
      if v_round = 1 then
        insert into ptsc_bracket_slots values
          (v_category, 'R16-' || v_position, 'home', 'entry', 'X', null, null, v_position * 2 - 1, 'Vị trí ' || (v_position * 2 - 1), 'Position ' || (v_position * 2 - 1)),
          (v_category, 'R16-' || v_position, 'away', 'entry', 'X', null, null, v_position * 2, 'Vị trí ' || (v_position * 2), 'Position ' || (v_position * 2));
      else
        insert into ptsc_bracket_slots values
          (v_category, (case v_round when 2 then 'QF' when 3 then 'SF' else 'F' end) || v_position, 'home', 'fixture_winner', null, null,
            'R16-' || (v_position * 2 - 1), null, 'Thắng trận trước', 'Winner previous match'),
          (v_category, (case v_round when 2 then 'QF' when 3 then 'SF' else 'F' end) || v_position, 'away', 'fixture_winner', null, null,
            'R16-' || (v_position * 2), null, 'Thắng trận trước', 'Winner previous match');
      end if;
    end loop;
    v_round_size := v_round_size / 2;
  end loop;

  -- Repair the generated source codes for rounds after the first round.
  update ptsc_bracket_slots slot
  set source_fixture_code = case
    when fixture.source_code like 'QF%' then 'R16-' || ((substring(fixture.source_code from 3)::integer * 2) - 1)
    when fixture.source_code like 'SF%' then 'QF' || ((substring(fixture.source_code from 3)::integer * 2) - 1)
    when fixture.source_code = 'F1' then 'SF1'
    else 'SF2'
  end
  from ptsc_bracket_fixtures fixture
  where slot.category_code = v_category
    and fixture.category_code = slot.category_code
    and fixture.source_code = slot.source_code
    and slot.source_kind = 'fixture_winner'
    and slot.side = 'home';

  update ptsc_bracket_slots slot
  set source_fixture_code = case
    when fixture.source_code like 'QF%' then 'R16-' || (substring(fixture.source_code from 3)::integer * 2)
    when fixture.source_code like 'SF%' then 'QF' || (substring(fixture.source_code from 3)::integer * 2)
    else 'SF2'
  end
  from ptsc_bracket_fixtures fixture
  where slot.category_code = v_category
    and fixture.category_code = slot.category_code
    and fixture.source_code = slot.source_code
    and slot.source_kind = 'fixture_winner'
    and slot.side = 'away';

  -- Materialize the approved topology into the shared bracket tables.
  for v_fixture in select * from ptsc_bracket_fixtures order by category_code, round_order, bracket_position
  loop
    select id into v_tournament_id
    from public.tournaments
    where tenant_id = v_tenant_id and category_code = v_fixture.category_code and archived_at is null;
    if v_tournament_id is null then continue; end if;

    select id into v_fixture_id
    from public.fixtures
    where tenant_id = v_tenant_id
      and tournament_id = v_tournament_id
      and source_code = v_fixture.source_code
      and archived_at is null
    limit 1;

    if v_fixture_id is null then
      insert into public.fixtures (tenant_id, tournament_id, status, round_vi, round_en, round_order, bracket_position, source_code, archived_at)
      values (v_tenant_id, v_tournament_id, 'scheduled', v_fixture.round_vi, v_fixture.round_en, v_fixture.round_order, v_fixture.bracket_position, v_fixture.source_code, null)
      returning id into v_fixture_id;
    else
      update public.fixtures
      set round_vi = v_fixture.round_vi,
          round_en = v_fixture.round_en,
          round_order = v_fixture.round_order,
          bracket_position = v_fixture.bracket_position,
          archived_at = null
      where id = v_fixture_id and tenant_id = v_tenant_id;
    end if;

    for v_slot in
      select * from ptsc_bracket_slots
      where category_code = v_fixture.category_code and source_code = v_fixture.source_code
      order by side
    loop
      v_source_kind := v_slot.source_kind;
      v_source_entry_id := null;
      v_source_group_id := null;
      v_source_fixture_id := null;

      if v_source_kind = 'entry' then
        select group_row.id into v_group_id
        from public.groups group_row
        where group_row.tenant_id = v_tenant_id
          and group_row.tournament_id = v_tournament_id
          and group_row.group_code = v_slot.source_group_code
          and group_row.archived_at is null;
        select group_entry.entry_id into v_source_entry_id
        from public.group_entries group_entry
        where group_entry.tenant_id = v_tenant_id
          and group_entry.group_id = v_group_id
          and group_entry.slot_no = v_slot.source_slot_no
          and group_entry.archived_at is null;
        if v_source_entry_id is null then v_source_kind := 'bye'; end if;
      elsif v_source_kind = 'group_rank' then
        select group_row.id into v_source_group_id
        from public.groups group_row
        where group_row.tenant_id = v_tenant_id
          and group_row.tournament_id = v_tournament_id
          and group_row.group_code = v_slot.source_group_code
          and group_row.archived_at is null;
        if v_source_group_id is null then v_source_kind := 'bye'; end if;
      elsif v_source_kind = 'fixture_winner' then
        select source_fixture.id into v_source_fixture_id
        from public.fixtures source_fixture
        where source_fixture.tenant_id = v_tenant_id
          and source_fixture.tournament_id = v_tournament_id
          and source_fixture.source_code = v_slot.source_fixture_code
          and source_fixture.archived_at is null
        limit 1;
        if v_source_fixture_id is null then
          raise exception 'PTSC: không tìm thấy trận nguồn % cho %', v_slot.source_fixture_code, v_fixture.category_code;
        end if;
      end if;

      insert into public.fixture_slots (
        tenant_id, fixture_id, side, source_kind, source_entry_id, source_group_id, source_fixture_id,
        source_rank, label_vi, label_en, archived_at
      )
      values (
        v_tenant_id, v_fixture_id, v_slot.side, v_source_kind, v_source_entry_id, v_source_group_id, v_source_fixture_id,
        case when v_source_kind = 'group_rank' then v_slot.source_rank end,
        v_slot.label_vi, v_slot.label_en, null
      )
      on conflict (fixture_id, side) do update set
        source_kind = excluded.source_kind,
        source_entry_id = excluded.source_entry_id,
        source_group_id = excluded.source_group_id,
        source_fixture_id = excluded.source_fixture_id,
        source_rank = excluded.source_rank,
        label_vi = excluded.label_vi,
        label_en = excluded.label_en,
        archived_at = null;
    end loop;
  end loop;

  update public.fixtures source_fixture
  set next_fixture_id = (
    select destination.id
    from ptsc_bracket_slots slot
    join public.tournaments tournament
      on tournament.id = source_fixture.tournament_id
     and tournament.category_code = slot.category_code
    join public.fixtures destination
      on destination.tenant_id = v_tenant_id
     and destination.tournament_id = source_fixture.tournament_id
     and destination.source_code = slot.source_code
     and destination.archived_at is null
    where slot.source_kind = 'fixture_winner'
      and slot.source_fixture_code = source_fixture.source_code
    limit 1
  )
  where source_fixture.tenant_id = v_tenant_id
    and source_fixture.archived_at is null
    and exists (
      select 1
      from ptsc_bracket_slots slot
      join public.tournaments tournament
        on tournament.id = source_fixture.tournament_id
       and tournament.category_code = slot.category_code
      where slot.source_kind = 'fixture_winner'
        and slot.source_fixture_code = source_fixture.source_code
    );
end $$;
