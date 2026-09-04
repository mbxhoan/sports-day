-- Reconcile the reviewed chess names and split swimming races into the source age groups.
create or replace function private.repair_chess_swimming_customer_feedback(p_tenant_id uuid)
returns void
language plpgsql
set search_path = public, pg_temp
as $function$
declare
  participant_group record;
  duplicate_participant uuid;
  keeper_participant uuid;
begin
  -- The workbook uses one spelling for the Xiangqi competitor and the full chess name.
  update public.entries entry
  set name_vi = 'Đái Quốc Triều', name_en = 'Đái Quốc Triều'
  from public.tournaments tournament
  join public.sports sport on sport.id = tournament.sport_id
  where entry.tenant_id = p_tenant_id
    and entry.tournament_id = tournament.id
    and sport.tenant_id = p_tenant_id and sport.slug = 'co-tuong'
    and tournament.slug = 'nam-tren-45'
    and entry.name_vi in ('Đái Quốc Triều', 'Ðái Quốc Triều');
  update public.entries entry
  set name_vi = 'Phạm Nguyễn Như Thường', name_en = 'Phạm Nguyễn Như Thường'
  from public.tournaments tournament
  join public.sports sport on sport.id = tournament.sport_id
  where entry.tenant_id = p_tenant_id
    and entry.tournament_id = tournament.id
    and sport.tenant_id = p_tenant_id and sport.slug = 'co-vua'
    and tournament.slug = 'nu'
    and entry.name_vi in ('Phạm Nguyễn Như', 'Phạm Nguyễn Như Thường');
  update public.entries entry
  set name_vi = 'Chu Đình Quang Vinh', name_en = 'Chu Đình Quang Vinh'
  from public.tournaments tournament
  join public.sports sport on sport.id = tournament.sport_id
  where entry.tenant_id = p_tenant_id
    and entry.tournament_id = tournament.id
    and sport.tenant_id = p_tenant_id and sport.slug = 'co-tuong'
    and tournament.slug = 'nam-duoi-45'
    and entry.name_vi in ('Chu Đình Quang Vinh', 'Chu Ðình Quang Vinh');
  update public.entries entry
  set name_vi = 'Nguyễn Bá Phượng', name_en = 'Nguyễn Bá Phượng'
  from public.tournaments tournament
  join public.sports sport on sport.id = tournament.sport_id
  where entry.tenant_id = p_tenant_id
    and entry.tournament_id = tournament.id
    and sport.tenant_id = p_tenant_id and sport.slug = 'co-tuong'
    and tournament.slug = 'nam-tren-45'
    and entry.name_vi in ('Nguyễn Bá Phương', 'Nguyễn Bá Phượng');
  update public.participants
  set full_name = 'Đái Quốc Triều', full_name_en = 'Đái Quốc Triều'
  where tenant_id = p_tenant_id and full_name = 'Ðái Quốc Triều';
  update public.participants
  set full_name = 'Phạm Nguyễn Như Thường', full_name_en = 'Phạm Nguyễn Như Thường'
  where tenant_id = p_tenant_id and full_name = 'Phạm Nguyễn Như';
  update public.participants
  set full_name = 'Chu Đình Quang Vinh', full_name_en = 'Chu Đình Quang Vinh'
  where tenant_id = p_tenant_id and full_name = 'Chu Ðình Quang Vinh';
  update public.participants
  set full_name = 'Nguyễn Bá Phượng', full_name_en = 'Nguyễn Bá Phượng'
  where tenant_id = p_tenant_id and full_name = 'Nguyễn Bá Phương';

  -- Merge duplicate participant rows without dropping their entry or award references.
  for participant_group in
    select organization_id, full_name
    from public.participants
    where tenant_id = p_tenant_id and full_name in ('Đái Quốc Triều', 'Phạm Nguyễn Như Thường', 'Chu Đình Quang Vinh', 'Nguyễn Bá Phượng')
    group by organization_id, full_name
    having count(*) > 1
  loop
    select min(id) into keeper_participant
    from public.participants
    where tenant_id = p_tenant_id
      and organization_id is not distinct from participant_group.organization_id
      and full_name = participant_group.full_name;
    for duplicate_participant in
      select id
      from public.participants
      where tenant_id = p_tenant_id
        and organization_id is not distinct from participant_group.organization_id
        and full_name = participant_group.full_name
        and id <> keeper_participant
    loop
      update public.awards set participant_id = keeper_participant
      where tenant_id = p_tenant_id and participant_id = duplicate_participant;
      delete from public.entry_members duplicate_member
      where duplicate_member.tenant_id = p_tenant_id
        and duplicate_member.participant_id = duplicate_participant
        and exists (
          select 1 from public.entry_members keeper_member
          where keeper_member.tenant_id = p_tenant_id
            and keeper_member.entry_id = duplicate_member.entry_id
            and keeper_member.participant_id = keeper_participant
        );
      update public.entry_members
      set participant_id = keeper_participant
      where tenant_id = p_tenant_id and participant_id = duplicate_participant;
      delete from public.participants where tenant_id = p_tenant_id and id = duplicate_participant;
    end loop;
  end loop;
  perform private.merge_entry_variants(p_tenant_id);

  create temporary table swimming_tournament_definitions (
    source_slug text not null,
    target_slug text primary key,
    name_vi text not null,
    name_en text not null,
    category_vi text not null,
    category_en text not null,
    sort_order integer not null,
    supporting_sheet text not null
  ) on commit drop;
  insert into swimming_tournament_definitions values
    ('50m-nam','50m-nam-duoi-30','50m tự do nam dưới 30 tuổi','Men’s 50m Freestyle Under 30','Dưới 30 tuổi','Under 30',1,'Trang 3'),
    ('50m-nam','50m-nam-31-40','50m tự do nam 31–40 tuổi','Men’s 50m Freestyle 31–40','31–40 tuổi','Ages 31–40',2,'Trang 3'),
    ('50m-nam','50m-nam-41-50','50m tự do nam 41–50 tuổi','Men’s 50m Freestyle 41–50','41–50 tuổi','Ages 41–50',3,'Trang 4'),
    ('50m-nam','50m-nam-tren-50','50m tự do nam trên 50 tuổi','Men’s 50m Freestyle 50+','Trên 50 tuổi','Ages 50+',4,'Trang 4'),
    ('50m-nu','50m-nu-duoi-30','50m tự do nữ dưới 30 tuổi','Women’s 50m Freestyle Under 30','Dưới 30 tuổi','Under 30',5,'Trang 6'),
    ('50m-nu','50m-nu-31-40','50m tự do nữ 31–40 tuổi','Women’s 50m Freestyle 31–40','31–40 tuổi','Ages 31–40',6,'Trang 7'),
    ('100m-nam','100m-nam-duoi-30','100m tự do nam dưới 30 tuổi','Men’s 100m Freestyle Under 30','Dưới 30 tuổi','Under 30',7,'Trang 5'),
    ('100m-nam','100m-nam-41-50','100m tự do nam 41–50 tuổi','Men’s 100m Freestyle 41–50','41–50 tuổi','Ages 41–50',8,'Trang 5');

  insert into public.tournaments (
    tenant_id, sport_id, slug, name_vi, name_en, category_vi, category_en, gender,
    format_vi, format_en, rules_vi, rules_en, competition_mode, source_metadata, scoring_rule, sort_order
  )
  select p_tenant_id, old_tournament.sport_id, definition.target_slug, definition.name_vi, definition.name_en,
    definition.category_vi, definition.category_en, old_tournament.gender, old_tournament.format_vi, old_tournament.format_en,
    old_tournament.rules_vi, old_tournament.rules_en, 'race',
    coalesce(old_tournament.source_metadata, '{}'::jsonb) || jsonb_build_object(
      'update_workbook', 'updates/BƠI LỘI EXCEL/bơi lội.xlsx',
      'supporting_sheet', definition.supporting_sheet
    ),
    old_tournament.scoring_rule, definition.sort_order
  from swimming_tournament_definitions definition
  join public.tournaments old_tournament on old_tournament.tenant_id = p_tenant_id and old_tournament.slug = definition.source_slug
  join public.sports sport on sport.id = old_tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'boi-loi'
  on conflict (tenant_id, sport_id, slug) do update set
    name_vi = excluded.name_vi, name_en = excluded.name_en, category_vi = excluded.category_vi,
    category_en = excluded.category_en, competition_mode = 'race', source_metadata = excluded.source_metadata,
    sort_order = excluded.sort_order, archived_at = null;

  create temporary table swimming_entry_map (
    entry_id uuid primary key,
    old_tournament_id uuid not null,
    target_tournament_id uuid not null,
    entry_name text not null
  ) on commit drop;
  insert into swimming_entry_map (entry_id, old_tournament_id, target_tournament_id, entry_name)
  select entry.id, old_tournament.id, target_tournament.id, entry.name_vi
  from public.entries entry
  join public.tournaments old_tournament on old_tournament.id = entry.tournament_id
  join public.sports sport on sport.id = old_tournament.sport_id
  join (values
    ('50m-nam','50m-nam-duoi-30','Ngô Minh Chí Bảo'),('50m-nam','50m-nam-duoi-30','Trịnh Xuân Cảnh'),('50m-nam','50m-nam-duoi-30','Nguyễn Trường Giang'),('50m-nam','50m-nam-duoi-30','Nguyễn Quách Thanh Nam'),('50m-nam','50m-nam-duoi-30','Tokio DOSHITA'),('50m-nam','50m-nam-duoi-30','Bùi Tuấn Minh'),('50m-nam','50m-nam-duoi-30','Bùi Cảnh Hưng'),('50m-nam','50m-nam-duoi-30','Nguyễn Mai Nam'),('50m-nam','50m-nam-duoi-30','Vũ Hoàng Phúc'),('50m-nam','50m-nam-duoi-30','Điêu Lâm Thành'),('50m-nam','50m-nam-duoi-30','Phạm Minh Tài'),
    ('50m-nam','50m-nam-31-40','Đặng Trọng Dũng'),('50m-nam','50m-nam-31-40','Hồ Tấn Đạt'),('50m-nam','50m-nam-31-40','Trịnh Hữu Chung'),('50m-nam','50m-nam-31-40','Huỳnh Tấn Giang'),('50m-nam','50m-nam-31-40','Bùi Sĩ Hồi'),('50m-nam','50m-nam-31-40','Ngô Cửu Long'),('50m-nam','50m-nam-31-40','Hoàng Nghĩa Ngọc'),('50m-nam','50m-nam-31-40','Trần Linh Vương'),('50m-nam','50m-nam-31-40','Nguyễn Hoàng Tân'),('50m-nam','50m-nam-31-40','Nguyễn Duy Sơn'),('50m-nam','50m-nam-31-40','Lê Minh Quyết'),('50m-nam','50m-nam-31-40','Trần Ngọc Minh'),('50m-nam','50m-nam-31-40','Nobuhiko MAKI'),
    ('50m-nam','50m-nam-41-50','Lê Tiến Dũng'),('50m-nam','50m-nam-41-50','Nguyễn Dương Bình'),('50m-nam','50m-nam-41-50','Nguyễn Vân Nam'),('50m-nam','50m-nam-41-50','Phạm Văn Em'),('50m-nam','50m-nam-41-50','Ngô Thế Lạc'),('50m-nam','50m-nam-41-50','Vũ Hoàng Lập'),('50m-nam','50m-nam-41-50','Lê Ngọc Linh'),('50m-nam','50m-nam-41-50','Lê Tiến Trung'),('50m-nam','50m-nam-41-50','Vũ Trung Kiên'),('50m-nam','50m-nam-41-50','Hoàng Duy Thu'),('50m-nam','50m-nam-41-50','Hà Thiếu Sang'),('50m-nam','50m-nam-41-50','Trần Văn Toàn'),('50m-nam','50m-nam-41-50','Nguyễn Công Khiên'),
    ('50m-nam','50m-nam-tren-50','Nguyễn Văn Phong'),('50m-nam','50m-nam-tren-50','Phạm Ngọc Tuân'),('50m-nam','50m-nam-tren-50','Trần Song Hào'),('50m-nam','50m-nam-tren-50','Nguyễn Như Thức'),('50m-nam','50m-nam-tren-50','Lê Huy'),('50m-nam','50m-nam-tren-50','Đặng Trọng Thông'),
    ('50m-nu','50m-nu-duoi-30','Trần Ngọc Thùy Dương'),('50m-nu','50m-nu-duoi-30','Đỗ Hồ Minh Phương'),('50m-nu','50m-nu-duoi-30','Lữ Thị Nhung'),('50m-nu','50m-nu-duoi-30','Phương Thị Huyền'),('50m-nu','50m-nu-duoi-30','Nguyễn Thị Lý'),('50m-nu','50m-nu-duoi-30','Nguyễn Thị Thanh Thanh'),('50m-nu','50m-nu-duoi-30','Trần Thị Quỳnh Vân'),('50m-nu','50m-nu-duoi-30','Nguyễn Thị Ngọc Lan'),('50m-nu','50m-nu-duoi-30','Lê Thị Phượng Uyển'),('50m-nu','50m-nu-duoi-30','Nguyễn Thị Thanh Nhã'),
    ('50m-nu','50m-nu-31-40','Châu Pha Diễm'),('50m-nu','50m-nu-31-40','Nguyễn Minh Nguyệt'),('50m-nu','50m-nu-31-40','Hà Thị Trang'),('50m-nu','50m-nu-31-40','Trịnh Thị Thanh'),('50m-nu','50m-nu-31-40','Nguyễn Ái Thanh Đan'),('50m-nu','50m-nu-31-40','Lê Thị Hằng'),('50m-nu','50m-nu-31-40','Nguyễn Thị Thùy Dung'),
    ('100m-nam','100m-nam-duoi-30','Đặng Trần Anh Tuấn'),('100m-nam','100m-nam-duoi-30','Masakazu KAGANOI'),('100m-nam','100m-nam-duoi-30','Nguyễn Anh Tuấn'),('100m-nam','100m-nam-duoi-30','Trần Quốc Toản'),('100m-nam','100m-nam-duoi-30','Lý Gia Thành'),('100m-nam','100m-nam-duoi-30','Tăng Hoàng Nhân'),('100m-nam','100m-nam-duoi-30','Shumpei YONETSU'),('100m-nam','100m-nam-duoi-30','Nguyễn Phú Nam'),('100m-nam','100m-nam-duoi-30','Lê Minh Hoàng'),('100m-nam','100m-nam-duoi-30','Trần Xuân Chánh'),('100m-nam','100m-nam-duoi-30','Trần Công Bằng'),('100m-nam','100m-nam-duoi-30','Trần Văn Cường'),('100m-nam','100m-nam-duoi-30','Trương Trần Trung Tín'),
    ('100m-nam','100m-nam-41-50','Alexey'),('100m-nam','100m-nam-41-50','Phạm Ngọc Anh'),('100m-nam','100m-nam-41-50','Phạm Hồng Minh'),('100m-nam','100m-nam-41-50','Vũ Việt Bình'),('100m-nam','100m-nam-41-50','Lê Trọng Hiếu'),('100m-nam','100m-nam-41-50','Đỗ Công Hữu'),('100m-nam','100m-nam-41-50','Nguyễn Văn Lếm'),('100m-nam','100m-nam-41-50','Huỳnh Lương Sánh'),('100m-nam','100m-nam-41-50','Fumitoshi SATO'),('100m-nam','100m-nam-41-50','Shamil'),('100m-nam','100m-nam-41-50','Nguyễn Quang Trung'),('100m-nam','100m-nam-41-50','Ngô Minh Phú'),('100m-nam','100m-nam-41-50','Lâm Tất Thắng'),('100m-nam','100m-nam-41-50','Nguyễn Tiến Trình'),('100m-nam','100m-nam-41-50','Phạm Văn Thuận'),('100m-nam','100m-nam-41-50','Nguyễn Hồng Phúc'),('100m-nam','100m-nam-41-50','Bùi Trung Kiên')
  ) as source(source_slug, target_slug, entry_name) on source.source_slug = old_tournament.slug and source.entry_name = entry.name_vi
  join public.tournaments target_tournament on target_tournament.tenant_id = p_tenant_id and target_tournament.sport_id = old_tournament.sport_id and target_tournament.slug = source.target_slug
  where entry.tenant_id = p_tenant_id and entry.kind = 'individual' and entry.archived_at is null
    and sport.tenant_id = p_tenant_id and sport.slug = 'boi-loi';

  -- Copy race result rows to one fixture per new category before hiding the old aggregate fixtures.
  insert into public.fixtures (tenant_id, tournament_id, status, starts_at, round_vi, round_en, source_code)
  select p_tenant_id, target.id,
    case when bool_or(old_fixture.status = 'completed') then 'completed' when bool_or(old_fixture.status = 'live') then 'live' else 'scheduled' end,
    min(old_fixture.starts_at), 'Thi đấu', 'Competition', 'UPD-BOI-' || target.slug
  from swimming_entry_map map
  join public.fixtures old_fixture on old_fixture.tenant_id = p_tenant_id and old_fixture.tournament_id = map.old_tournament_id and old_fixture.archived_at is null
  join public.tournaments target on target.id = map.target_tournament_id
  group by target.id, target.slug
  having not exists (select 1 from public.fixtures existing where existing.tenant_id = p_tenant_id and existing.source_code = 'UPD-BOI-' || target.slug and existing.archived_at is null);

  insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side, lane, seed_order, score, score_numeric, rank, result_detail, result_status)
  select distinct on (destination.id, map.entry_id)
    p_tenant_id, destination.id, map.entry_id, old_entry.side, old_entry.lane, old_entry.seed_order,
    old_entry.score, old_entry.score_numeric, old_entry.rank, old_entry.result_detail, old_entry.result_status
  from swimming_entry_map map
  join public.fixtures old_fixture on old_fixture.tenant_id = p_tenant_id and old_fixture.tournament_id = map.old_tournament_id and old_fixture.archived_at is null
  join public.fixture_entries old_entry on old_entry.tenant_id = p_tenant_id and old_entry.fixture_id = old_fixture.id and old_entry.entry_id = map.entry_id and old_entry.archived_at is null
  join public.fixtures destination on destination.tenant_id = p_tenant_id and destination.tournament_id = map.target_tournament_id and destination.source_code = 'UPD-BOI-' || (select slug from public.tournaments where id = map.target_tournament_id) and destination.archived_at is null
  order by destination.id, map.entry_id, (old_entry.score is not null or old_entry.score_numeric is not null or old_entry.rank is not null) desc, old_fixture.id
  on conflict (fixture_id, entry_id) do update set
    side = coalesce(fixture_entries.side, excluded.side), lane = coalesce(fixture_entries.lane, excluded.lane),
    seed_order = coalesce(fixture_entries.seed_order, excluded.seed_order), score = coalesce(fixture_entries.score, excluded.score),
    score_numeric = coalesce(fixture_entries.score_numeric, excluded.score_numeric), rank = coalesce(fixture_entries.rank, excluded.rank),
    result_detail = case when fixture_entries.result_detail = '{}'::jsonb then excluded.result_detail else fixture_entries.result_detail end,
    result_status = coalesce(fixture_entries.result_status, excluded.result_status), archived_at = null;

  update public.standings standing
  set tournament_id = map.target_tournament_id
  from swimming_entry_map map
  where standing.tenant_id = p_tenant_id and standing.entry_id = map.entry_id and standing.tournament_id = map.old_tournament_id;
  update public.awards award
  set tournament_id = map.target_tournament_id
  from swimming_entry_map map
  where award.tenant_id = p_tenant_id and award.entry_id = map.entry_id and award.tournament_id = map.old_tournament_id;
  update public.entries entry
  set tournament_id = map.target_tournament_id
  from swimming_entry_map map
  where entry.tenant_id = p_tenant_id and entry.id = map.entry_id;
  update public.fixture_entries old_entry
  set archived_at = now()
  from swimming_entry_map map
  join public.fixtures old_fixture on old_fixture.id = old_entry.fixture_id
  where old_entry.tenant_id = p_tenant_id and old_entry.entry_id = map.entry_id and old_fixture.tournament_id = map.old_tournament_id and old_entry.archived_at is null;
  update public.fixtures old_fixture
  set archived_at = now()
  where old_fixture.tenant_id = p_tenant_id and old_fixture.archived_at is null
    and old_fixture.tournament_id in (select distinct old_tournament_id from swimming_entry_map)
    and not exists (select 1 from public.fixture_entries item where item.fixture_id = old_fixture.id and item.archived_at is null);
  update public.tournaments old_tournament
  set archived_at = now()
  where old_tournament.tenant_id = p_tenant_id
    and old_tournament.slug in ('50m-nam','50m-nu','100m-nam')
    and old_tournament.archived_at is null;
  perform private.merge_entry_variants(p_tenant_id);
end;
$function$;

revoke all on function private.repair_chess_swimming_customer_feedback(uuid) from public;

do $$
begin
  if exists (
    select 1
    from public.sports sport
    where sport.tenant_id = private.seed_tenant_id() and sport.slug in ('co-vua', 'co-tuong', 'boi-loi')
  ) then
    perform private.repair_chess_swimming_customer_feedback(private.seed_tenant_id());
  end if;
end
$$;
