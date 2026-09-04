set app.tenant_slug = 'petrovietnam2026';

-- Keep the source pair as two athletes; the old import split "Đỗ Ngọc Giang" into three rows.
do $$
declare
  entry_row record;
  first_member uuid;
  second_member uuid;
begin
  select e.id, e.tenant_id
  into entry_row
  from public.entries e
  join public.tournaments t on t.id = e.tournament_id
  join public.sports s on s.id = t.sport_id
  where s.slug = 'cau-long'
    and t.slug = 'doi-nam-tren-51'
    and e.kind = 'pair'
    and e.name_vi in ('Đoàn Anh Sơn / Đỗ Ngọc / Giang', 'Đoàn Anh Sơn / Đỗ Ngọc Giang')
    and e.archived_at is null
  order by e.name_vi = 'Đoàn Anh Sơn / Đỗ Ngọc Giang' desc, e.id
  limit 1;

  if entry_row.id is null then return; end if;

  update public.entries
  set name_vi = 'Đoàn Anh Sơn / Đỗ Ngọc Giang', name_en = 'Đoàn Anh Sơn / Đỗ Ngọc Giang'
  where id = entry_row.id;

  select p.id into first_member
  from public.participants p
  where p.tenant_id = entry_row.tenant_id and private.entry_identity(p.full_name, 'individual') = private.entry_identity('Đoàn Anh Sơn', 'individual')
  order by p.id limit 1;

  select p.id into second_member
  from public.participants p
  where p.tenant_id = entry_row.tenant_id and private.entry_identity(p.full_name, 'individual') = private.entry_identity('Đỗ Ngọc Giang', 'individual')
  order by p.id limit 1;

  if second_member is null then
    insert into public.participants (tenant_id, full_name, full_name_en)
    values (entry_row.tenant_id, 'Đỗ Ngọc Giang', 'Đỗ Ngọc Giang')
    returning id into second_member;
  end if;

  update public.entry_members
  set archived_at = coalesce(archived_at, now())
  where entry_id = entry_row.id and participant_id not in (first_member, second_member) and archived_at is null;

  insert into public.entry_members (tenant_id, entry_id, participant_id, sort_order)
  values (entry_row.tenant_id, entry_row.id, first_member, 1), (entry_row.tenant_id, entry_row.id, second_member, 2)
  on conflict (entry_id, participant_id) do update set sort_order = excluded.sort_order, archived_at = null;

  update public.entry_members member
  set archived_at = coalesce(member.archived_at, now())
  from public.entries duplicate
  where member.entry_id = duplicate.id and duplicate.id <> entry_row.id
    and duplicate.name_vi = 'Đoàn Anh Sơn / Đỗ Ngọc / Giang' and duplicate.archived_at is null;
  update public.group_entries membership
  set archived_at = coalesce(membership.archived_at, now())
  from public.entries duplicate
  where membership.entry_id = duplicate.id and duplicate.id <> entry_row.id
    and duplicate.name_vi = 'Đoàn Anh Sơn / Đỗ Ngọc / Giang' and duplicate.archived_at is null;
  update public.standings standing
  set archived_at = coalesce(standing.archived_at, now())
  from public.entries duplicate
  where standing.entry_id = duplicate.id and duplicate.id <> entry_row.id
    and duplicate.name_vi = 'Đoàn Anh Sơn / Đỗ Ngọc / Giang' and duplicate.archived_at is null;
  update public.fixture_entries fixture_entry
  set archived_at = coalesce(fixture_entry.archived_at, now())
  from public.entries duplicate
  where fixture_entry.entry_id = duplicate.id and duplicate.id <> entry_row.id
    and duplicate.name_vi = 'Đoàn Anh Sơn / Đỗ Ngọc / Giang' and duplicate.archived_at is null;
  update public.entries duplicate
  set archived_at = coalesce(duplicate.archived_at, now())
  where duplicate.id <> entry_row.id
    and duplicate.name_vi = 'Đoàn Anh Sơn / Đỗ Ngọc / Giang' and duplicate.archived_at is null;
end
$$;

-- Reconcile the three table-tennis groups against the source pages.
do $$
declare
  tournament_id uuid;
  group_a uuid;
  group_b uuid;
  group_f uuid;
  women_b uuid;
begin
  select t.id into tournament_id
  from public.tournaments t join public.sports s on s.id = t.sport_id
  where s.slug = 'bong-ban' and t.slug = 'doi-nam-31-40';

  if tournament_id is not null then
    select group_row.id into group_a from public.groups group_row where group_row.tournament_id = tournament_id and group_row.name_vi = 'Bảng A' limit 1;
    select group_row.id into group_b from public.groups group_row where group_row.tournament_id = tournament_id and group_row.name_vi = 'Bảng B' and group_row.archived_at is null limit 1;
    if group_b is null then
      insert into public.groups (tenant_id, tournament_id, name_vi, name_en, sort_order)
      select t.tenant_id, t.id, 'Bảng B', 'Group B', 1 from public.tournaments t where t.id = tournament_id
      returning id into group_b;
    end if;

    update public.group_entries ge
    set archived_at = coalesce(ge.archived_at, now())
    from public.entries e
    where ge.group_id = group_a and ge.archived_at is null
      and e.id = ge.entry_id
      and private.entry_identity(e.name_vi, e.kind) not in (
        private.entry_identity('Nguyễn Mạnh Hà / Võ Bá Anh Tuấn - PV DRILLING', e.kind),
        private.entry_identity('Nguyễn Mạnh Tùng / Phạm Tú Anh - VSP', e.kind),
        private.entry_identity('Trần Ngọc Sơn / Vũ Hải Long - PVPMB', e.kind),
        private.entry_identity('Nguyễn Vũ Chiến / Trần Tất Thắng - PVTRANS', e.kind),
        private.entry_identity('Bùi Văn Thiện / Nguyễn Quốc Hưng - PV GAS', e.kind)
      );
    update public.standings standing
    set archived_at = coalesce(standing.archived_at, now())
    from public.entries e
    where standing.group_id = group_a and standing.archived_at is null and e.id = standing.entry_id
      and private.entry_identity(e.name_vi, e.kind) not in (
        private.entry_identity('Nguyễn Mạnh Hà / Võ Bá Anh Tuấn - PV DRILLING', e.kind),
        private.entry_identity('Nguyễn Mạnh Tùng / Phạm Tú Anh - VSP', e.kind),
        private.entry_identity('Trần Ngọc Sơn / Vũ Hải Long - PVPMB', e.kind),
        private.entry_identity('Nguyễn Vũ Chiến / Trần Tất Thắng - PVTRANS', e.kind),
        private.entry_identity('Bùi Văn Thiện / Nguyễn Quốc Hưng - PV GAS', e.kind)
      );

    insert into public.group_entries (tenant_id, group_id, entry_id, seed_order)
    select ge.tenant_id, group_b, ge.entry_id, ge.seed_order
    from public.group_entries ge join public.entries e on e.id = ge.entry_id
    where ge.group_id = group_a and private.entry_identity(e.name_vi, e.kind) in (
      private.entry_identity('Trần Huy Bảo / Võ Văn Lung - PVFCCO', e.kind),
      private.entry_identity('Phạm Dương Ngọc Lợi / Trần Quốc Bình - PETROSETCO', e.kind),
      private.entry_identity('Phan Ngọc Lai / Nguyễn Văn Vinh - PVTRANS', e.kind),
      private.entry_identity('Nguyễn Trọng Vĩnh / Trần Nhựt Duy - PV GAS', e.kind),
      private.entry_identity('Phạm Đức Thư / Trần Việt Dũng - PTSC', e.kind),
      private.entry_identity('Đặng Đình Phúc / Lê Anh Thoại - VSP', e.kind)
    )
    on conflict (group_id, entry_id) do update set seed_order = excluded.seed_order, archived_at = null;
    update public.group_entries ge set archived_at = coalesce(ge.archived_at, now())
    from public.entries e
    where ge.group_id = group_a and ge.archived_at is null and e.id = ge.entry_id
      and private.entry_identity(e.name_vi, e.kind) in (
        private.entry_identity('Trần Huy Bảo / Võ Văn Lung - PVFCCO', e.kind),
        private.entry_identity('Phạm Dương Ngọc Lợi / Trần Quốc Bình - PETROSETCO', e.kind),
        private.entry_identity('Phan Ngọc Lai / Nguyễn Văn Vinh - PVTRANS', e.kind),
        private.entry_identity('Nguyễn Trọng Vĩnh / Trần Nhựt Duy - PV GAS', e.kind),
        private.entry_identity('Phạm Đức Thư / Trần Việt Dũng - PTSC', e.kind),
        private.entry_identity('Đặng Đình Phúc / Lê Anh Thoại - VSP', e.kind)
      );
    update public.standings source_standing
    set group_id = group_b
    from public.entries e
    where source_standing.group_id = group_a and source_standing.archived_at is null and e.id = source_standing.entry_id
      and e.name_vi in (
        'Trần Huy Bảo / Võ Văn Lung - PVFCCO',
        'Phạm Dương Ngọc Lợi / Trần Quốc Bình - PETROSETCO',
        'Phan Ngọc Lai / Nguyễn Văn Vinh - PVTRANS',
        'Nguyễn Trọng Vĩnh / Trần Nhựt Duy - PV GAS',
        'Phạm Đức Thư / Trần Việt Dũng - PTSC',
        'Đặng Đình Phúc / Lê Anh Thoại - VSP'
      )
      and not exists (select 1 from public.standings target where target.group_id = group_b and target.entry_id = source_standing.entry_id);

    update public.fixtures fixture
    set group_id = group_b
    where fixture.tournament_id = tournament_id
      and fixture.archived_at is null
      and fixture.source_code in (
        'UPD-DOI-NAM-31-40-BANG-A-10', 'UPD-DOI-NAM-31-40-BANG-A-11', 'UPD-DOI-NAM-31-40-BANG-A-12',
        'UPD-DOI-NAM-31-40-BANG-A-13', 'UPD-DOI-NAM-31-40-BANG-A-14', 'UPD-DOI-NAM-31-40-BANG-A-15',
        'UPD-DOI-NAM-31-40-BANG-A-16', 'UPD-DOI-NAM-31-40-BANG-A-17', 'UPD-DOI-NAM-31-40-BANG-A-18',
        'UPD-DOI-NAM-31-40-BANG-A-19', 'UPD-DOI-NAM-31-40-BANG-A-20', 'UPD-DOI-NAM-31-40-BANG-A-21',
        'UPD-DOI-NAM-31-40-BANG-A-22', 'UPD-DOI-NAM-31-40-BANG-A-23'
      );
  end if;

  select g.id into group_f
  from public.groups g join public.tournaments t on t.id = g.tournament_id join public.sports s on s.id = t.sport_id
  where s.slug = 'bong-ban' and t.slug = 'doi-nam-41-50' and g.name_vi = 'Bảng F' and g.archived_at is null;
  if group_f is not null then
    update public.group_entries ge set archived_at = coalesce(ge.archived_at, now())
    from public.entries e where ge.group_id = group_f and ge.archived_at is null and e.id = ge.entry_id
      and private.entry_identity(e.name_vi, e.kind) not in (
        private.entry_identity('Nguyễn Tấn Nam Phương / Phù Quang Thạch - PVTRANS', e.kind),
        private.entry_identity('Dương Minh Bảo Phác / Đặng Văn Sơn - PVEP', e.kind),
        private.entry_identity('Nguyễn Văn Hiếu / Vũ Văn Sỹ - VSP', e.kind),
        private.entry_identity('Đào Quang Thành / Hoàng Văn Tuấn - BĐPOC', e.kind),
        private.entry_identity('Đặng Quyết Thắng / Nguyễn Duy Thế - PVOIL', e.kind)
      );
    update public.standings standing set archived_at = coalesce(standing.archived_at, now())
    from public.entries e where standing.group_id = group_f and standing.archived_at is null and e.id = standing.entry_id
      and private.entry_identity(e.name_vi, e.kind) not in (
        private.entry_identity('Nguyễn Tấn Nam Phương / Phù Quang Thạch - PVTRANS', e.kind),
        private.entry_identity('Dương Minh Bảo Phác / Đặng Văn Sơn - PVEP', e.kind),
        private.entry_identity('Nguyễn Văn Hiếu / Vũ Văn Sỹ - VSP', e.kind),
        private.entry_identity('Đào Quang Thành / Hoàng Văn Tuấn - BĐPOC', e.kind),
        private.entry_identity('Đặng Quyết Thắng / Nguyễn Duy Thế - PVOIL', e.kind)
      );
  end if;

  select g.id into women_b
  from public.groups g join public.tournaments t on t.id = g.tournament_id join public.sports s on s.id = t.sport_id
  where s.slug = 'bong-ban' and t.slug = 'doi-nu' and g.name_vi = 'Bảng B' and g.archived_at is null;
  if women_b is not null then
    update public.group_entries ge set archived_at = coalesce(ge.archived_at, now())
    from public.entries e where ge.group_id = women_b and ge.archived_at is null and e.id = ge.entry_id
      and private.entry_identity(e.name_vi, e.kind) not in (
        private.entry_identity('Nguyễn Thị Anh Thơ / Nguyễn Thị Thu Thủy - PVCOMBANK', e.kind),
        private.entry_identity('Hoàng Thị Thơm / Nguyễn Thị Hiên - VSP', e.kind),
        private.entry_identity('Nguyễn Thị Bạch Mai / Phan Thị Mai - VSP', e.kind),
        private.entry_identity('Đào Thị Kim Anh / Trần Thị Thanh Huyền - PVFCCO', e.kind)
      );
    update public.standings standing set archived_at = coalesce(standing.archived_at, now())
    from public.entries e where standing.group_id = women_b and standing.archived_at is null and e.id = standing.entry_id
      and private.entry_identity(e.name_vi, e.kind) not in (
        private.entry_identity('Nguyễn Thị Anh Thơ / Nguyễn Thị Thu Thủy - PVCOMBANK', e.kind),
        private.entry_identity('Hoàng Thị Thơm / Nguyễn Thị Hiên - VSP', e.kind),
        private.entry_identity('Nguyễn Thị Bạch Mai / Phan Thị Mai - VSP', e.kind),
        private.entry_identity('Đào Thị Kim Anh / Trần Thị Thanh Huyền - PVFCCO', e.kind)
      );
  end if;
end
$$;

-- Restore the PDF topology for the two badminton men's brackets. Older live rows
-- may have the right teams but the wrong source links in fixture_slots.
create temporary table repair_badminton_fixtures (
  sport_slug text not null,
  tournament_slug text not null,
  source_code text not null,
  round_vi text not null,
  round_en text not null,
  round_order integer not null,
  bracket_position integer not null,
  primary key (sport_slug, tournament_slug, source_code)
) on commit drop;

insert into repair_badminton_fixtures values
  ('cau-long','doi-nam-31-40','1','Vòng loại 1','Knockout round 1',1,1),
  ('cau-long','doi-nam-31-40','2','Vòng loại 1','Knockout round 1',1,2),
  ('cau-long','doi-nam-31-40','3','Vòng loại 1','Knockout round 1',1,3),
  ('cau-long','doi-nam-31-40','4','Tứ kết','Quarterfinal',2,1),
  ('cau-long','doi-nam-31-40','5','Tứ kết','Quarterfinal',2,2),
  ('cau-long','doi-nam-31-40','6','Tứ kết','Quarterfinal',2,3),
  ('cau-long','doi-nam-31-40','7','Tứ kết','Quarterfinal',2,4),
  ('cau-long','doi-nam-31-40','8','Bán kết','Semifinal',3,1),
  ('cau-long','doi-nam-31-40','9','Bán kết','Semifinal',3,2),
  ('cau-long','doi-nam-31-40','10','Chung kết','Final',4,1),
  ('cau-long','doi-nam-41-50','1','Vòng loại 1','Knockout round 1',1,1),
  ('cau-long','doi-nam-41-50','2','Vòng loại 1','Knockout round 1',1,2),
  ('cau-long','doi-nam-41-50','3','Vòng loại 1','Knockout round 1',1,3),
  ('cau-long','doi-nam-41-50','4','Tứ kết','Quarterfinal',2,1),
  ('cau-long','doi-nam-41-50','5','Tứ kết','Quarterfinal',2,2),
  ('cau-long','doi-nam-41-50','6','Tứ kết','Quarterfinal',2,3),
  ('cau-long','doi-nam-41-50','7','Tứ kết','Quarterfinal',2,4),
  ('cau-long','doi-nam-41-50','8','Bán kết','Semifinal',3,1),
  ('cau-long','doi-nam-41-50','9','Bán kết','Semifinal',3,2),
  ('cau-long','doi-nam-41-50','10','Chung kết','Final',4,1);

create temporary table repair_badminton_slots (
  sport_slug text not null,
  tournament_slug text not null,
  destination_code text not null,
  side text not null,
  source_kind text not null,
  entry_name text,
  source_fixture_code text,
  label_vi text not null,
  label_en text not null,
  primary key (sport_slug, tournament_slug, destination_code, side)
) on commit drop;

insert into repair_badminton_slots values
  ('cau-long','doi-nam-31-40','1','home','entry','Đoàn Văn Đặng / Nguyễn Hoàng Nam-PVCOM',null,'Đoàn Văn Đặng / Nguyễn Hoàng Nam-PVCOM','Đoàn Văn Đặng / Nguyễn Hoàng Nam-PVCOM'),
  ('cau-long','doi-nam-31-40','1','away','entry','Bùi Thái Sơn / Lê Tuấn Anh-VSP',null,'Bùi Thái Sơn / Lê Tuấn Anh-VSP','Bùi Thái Sơn / Lê Tuấn Anh-VSP'),
  ('cau-long','doi-nam-31-40','2','home','entry','Lê Nguyễn Hoàng Dương / Vũ Khoa Huân-PVI',null,'Lê Nguyễn Hoàng Dương / Vũ Khoa Huân-PVI','Lê Nguyễn Hoàng Dương / Vũ Khoa Huân-PVI'),
  ('cau-long','doi-nam-31-40','2','away','entry','Đào Quốc Dũng / Võ Văn Thịnh-PVG',null,'Đào Quốc Dũng / Võ Văn Thịnh-PVG','Đào Quốc Dũng / Võ Văn Thịnh-PVG'),
  ('cau-long','doi-nam-31-40','3','home','entry','Chung Bảo Hiếu / Lê Tiến Bảo-PVFCCo',null,'Chung Bảo Hiếu / Lê Tiến Bảo-PVFCCo','Chung Bảo Hiếu / Lê Tiến Bảo-PVFCCo'),
  ('cau-long','doi-nam-31-40','3','away','entry','Nguyễn Đình Toàn / Võ Quang Khải-PVG',null,'Nguyễn Đình Toàn / Võ Quang Khải-PVG','Nguyễn Đình Toàn / Võ Quang Khải-PVG'),
  ('cau-long','doi-nam-31-40','4','home','entry','Đặng Vũ Khởi / Hồ Tuấn Anh-BMĐH',null,'Đặng Vũ Khởi / Hồ Tuấn Anh-BMĐH','Đặng Vũ Khởi / Hồ Tuấn Anh-BMĐH'),
  ('cau-long','doi-nam-31-40','4','away','fixture_winner',null,'1','Thắng 1','Winner 1'),
  ('cau-long','doi-nam-31-40','5','home','fixture_winner',null,'2','Thắng 2','Winner 2'),
  ('cau-long','doi-nam-31-40','5','away','entry','Dương Trí Quả / Trịnh Văn Thành',null,'Dương Trí Quả / Trịnh Văn Thành','Dương Trí Quả / Trịnh Văn Thành'),
  ('cau-long','doi-nam-31-40','6','home','entry','Lê Minh Đức / Nguyễn Khánh Phong-PVOIL',null,'Lê Minh Đức / Nguyễn Khánh Phong-PVOIL','Lê Minh Đức / Nguyễn Khánh Phong-PVOIL'),
  ('cau-long','doi-nam-31-40','6','away','entry','Đỗ Đức Thọ / Nguyễn Việt Thắng-PVD',null,'Đỗ Đức Thọ / Nguyễn Việt Thắng-PVD','Đỗ Đức Thọ / Nguyễn Việt Thắng-PVD'),
  ('cau-long','doi-nam-31-40','7','home','fixture_winner',null,'3','Thắng 3','Winner 3'),
  ('cau-long','doi-nam-31-40','7','away','entry','Nguyễn Minh Hoàng / Nguyễn Văn Hiếu-PQPOC',null,'Nguyễn Minh Hoàng / Nguyễn Văn Hiếu-PQPOC','Nguyễn Minh Hoàng / Nguyễn Văn Hiếu-PQPOC'),
  ('cau-long','doi-nam-31-40','8','home','fixture_winner',null,'4','Thắng 4','Winner 4'),
  ('cau-long','doi-nam-31-40','8','away','fixture_winner',null,'5','Thắng 5','Winner 5'),
  ('cau-long','doi-nam-31-40','9','home','fixture_winner',null,'6','Thắng 6','Winner 6'),
  ('cau-long','doi-nam-31-40','9','away','fixture_winner',null,'7','Thắng 7','Winner 7'),
  ('cau-long','doi-nam-31-40','10','home','fixture_winner',null,'8','Thắng 8','Winner 8'),
  ('cau-long','doi-nam-31-40','10','away','fixture_winner',null,'9','Thắng 9','Winner 9'),
  ('cau-long','doi-nam-41-50','1','home','entry','Đào Công Thiện / Trần Xuân Ngọc',null,'Đào Công Thiện / Trần Xuân Ngọc','Đào Công Thiện / Trần Xuân Ngọc'),
  ('cau-long','doi-nam-41-50','1','away','entry','Nguyễn Chí Trung / Nguyễn Văn Mười',null,'Nguyễn Chí Trung / Nguyễn Văn Mười','Nguyễn Chí Trung / Nguyễn Văn Mười'),
  ('cau-long','doi-nam-41-50','2','home','entry','Ngô Thế Quỳnh / Nguyễn Đăng Khoa',null,'Ngô Thế Quỳnh / Nguyễn Đăng Khoa','Ngô Thế Quỳnh / Nguyễn Đăng Khoa'),
  ('cau-long','doi-nam-41-50','2','away','entry','Nguyễn Đình Phong / Nguyễn Ngọc Ánh',null,'Nguyễn Đình Phong / Nguyễn Ngọc Ánh','Nguyễn Đình Phong / Nguyễn Ngọc Ánh'),
  ('cau-long','doi-nam-41-50','3','home','entry','Hồ Viết Tập / Phạm Tất Lộc',null,'Hồ Viết Tập / Phạm Tất Lộc','Hồ Viết Tập / Phạm Tất Lộc'),
  ('cau-long','doi-nam-41-50','3','away','entry','Phạm Văn Hiệu / Vũ Văn Dũng',null,'Phạm Văn Hiệu / Vũ Văn Dũng','Phạm Văn Hiệu / Vũ Văn Dũng'),
  ('cau-long','doi-nam-41-50','4','home','entry','Bùi Anh Võ / Hồ Ngọc Hưng',null,'Bùi Anh Võ / Hồ Ngọc Hưng','Bùi Anh Võ / Hồ Ngọc Hưng'),
  ('cau-long','doi-nam-41-50','4','away','fixture_winner',null,'1','Thắng 1','Winner 1'),
  ('cau-long','doi-nam-41-50','5','home','fixture_winner',null,'2','Thắng 2','Winner 2'),
  ('cau-long','doi-nam-41-50','5','away','entry','Nguyễn Trung Hải / Tất Phi Hải',null,'Nguyễn Trung Hải / Tất Phi Hải','Nguyễn Trung Hải / Tất Phi Hải'),
  ('cau-long','doi-nam-41-50','6','home','entry','Đỗ Văn Toàn / Trần Quốc Huy',null,'Đỗ Văn Toàn / Trần Quốc Huy','Đỗ Văn Toàn / Trần Quốc Huy'),
  ('cau-long','doi-nam-41-50','6','away','entry','Đặng Đình Bình / Nguyễn Hải Long',null,'Đặng Đình Bình / Nguyễn Hải Long','Đặng Đình Bình / Nguyễn Hải Long'),
  ('cau-long','doi-nam-41-50','7','home','fixture_winner',null,'3','Thắng 3','Winner 3'),
  ('cau-long','doi-nam-41-50','7','away','entry','Hoàng Quang Chính / Ng Công Anh Anh',null,'Hoàng Quang Chính / Ng Công Anh Anh','Hoàng Quang Chính / Ng Công Anh Anh'),
  ('cau-long','doi-nam-41-50','8','home','fixture_winner',null,'4','Thắng 4','Winner 4'),
  ('cau-long','doi-nam-41-50','8','away','fixture_winner',null,'5','Thắng 5','Winner 5'),
  ('cau-long','doi-nam-41-50','9','home','fixture_winner',null,'6','Thắng 6','Winner 6'),
  ('cau-long','doi-nam-41-50','9','away','fixture_winner',null,'7','Thắng 7','Winner 7'),
  ('cau-long','doi-nam-41-50','10','home','fixture_winner',null,'8','Thắng 8','Winner 8'),
  ('cau-long','doi-nam-41-50','10','away','fixture_winner',null,'9','Thắng 9','Winner 9');

update public.fixtures fixture
set round_vi = source.round_vi,
    round_en = source.round_en,
    round_order = source.round_order,
    bracket_position = source.bracket_position
from repair_badminton_fixtures source
join public.tournaments tournament on tournament.slug = source.tournament_slug
join public.sports sport on sport.id = tournament.sport_id and sport.slug = source.sport_slug
where fixture.tournament_id = tournament.id
  and fixture.source_code = source.source_code
  and fixture.archived_at is null;

-- Remove every old active source link first so filtered source uniqueness cannot
-- preserve a stale assignment from an earlier import.
update public.fixture_slots slot
set archived_at = now()
from public.fixtures fixture
join public.tournaments tournament on tournament.id = fixture.tournament_id
join public.sports sport on sport.id = tournament.sport_id
where slot.fixture_id = fixture.id
  and slot.archived_at is null
  and sport.slug = 'cau-long'
  and tournament.slug in ('doi-nam-31-40', 'doi-nam-41-50');

insert into public.fixture_slots (tenant_id, fixture_id, side, source_kind, source_entry_id, source_fixture_id, label_vi, label_en, archived_at)
select tournament.tenant_id,
       destination.id,
       source.side,
       source.source_kind,
       source_entry.id,
       source_fixture.id,
       source.label_vi,
       source.label_en,
       null
from repair_badminton_slots source
join public.tournaments tournament on tournament.slug = source.tournament_slug
join public.sports sport on sport.id = tournament.sport_id and sport.slug = source.sport_slug
join public.fixtures destination on destination.tournament_id = tournament.id
  and destination.source_code = source.destination_code
  and destination.archived_at is null
left join lateral (
  select entry.id
  from public.entries entry
  where source.source_kind = 'entry'
    and entry.tournament_id = tournament.id
    and entry.kind = 'pair'
    and entry.archived_at is null
    and private.entry_identity(entry.name_vi, entry.kind) = private.entry_identity(source.entry_name, 'pair')
  order by entry.id
  limit 1
) source_entry on true
left join lateral (
  select fixture.id
  from public.fixtures fixture
  where source.source_kind = 'fixture_winner'
    and fixture.tournament_id = tournament.id
    and fixture.source_code = source.source_fixture_code
    and fixture.archived_at is null
  order by fixture.id
  limit 1
) source_fixture on true
where (source.source_kind = 'entry' and source_entry.id is not null)
   or (source.source_kind = 'fixture_winner' and source_fixture.id is not null)
on conflict (fixture_id, side) do update set
  source_kind = excluded.source_kind,
  source_entry_id = excluded.source_entry_id,
  source_group_id = null,
  source_fixture_id = excluded.source_fixture_id,
  source_rank = null,
  label_vi = excluded.label_vi,
  label_en = excluded.label_en,
  archived_at = null;

do $$
declare
  expected_count integer;
  actual_count integer;
begin
  if not exists (
    select 1
    from public.tournaments tournament
    join public.sports sport on sport.id = tournament.sport_id
    where sport.slug = 'cau-long'
      and tournament.slug in ('doi-nam-31-40', 'doi-nam-41-50')
  ) then
    return;
  end if;

  select count(*) into expected_count from repair_badminton_slots;
  select count(*) into actual_count
  from public.fixture_slots slot
  join public.fixtures fixture on fixture.id = slot.fixture_id
  join public.tournaments tournament on tournament.id = fixture.tournament_id
  join public.sports sport on sport.id = tournament.sport_id
  where slot.archived_at is null
    and sport.slug = 'cau-long'
    and tournament.slug in ('doi-nam-31-40', 'doi-nam-41-50');
  if actual_count <> expected_count then
    raise exception 'Badminton source bracket repair incomplete: expected %, found %', expected_count, actual_count;
  end if;
end
$$;

-- Refresh static legacy rows too; dynamic rows are refreshed by the dependency walk.
update public.fixture_entries item
set archived_at = now()
from public.fixture_slots slot
where item.fixture_id = slot.fixture_id
  and item.side = slot.side
  and item.archived_at is null
  and slot.archived_at is null
  and slot.source_kind = 'entry'
  and item.entry_id is distinct from slot.source_entry_id;

insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side, archived_at)
select fixture.tenant_id, slot.fixture_id, slot.source_entry_id, slot.side, null
from public.fixture_slots slot
join public.fixtures fixture on fixture.id = slot.fixture_id
where slot.archived_at is null
  and slot.source_kind = 'entry'
  and exists (
    select 1
    from public.tournaments tournament
    join public.sports sport on sport.id = tournament.sport_id
    where tournament.id = fixture.tournament_id
      and sport.slug = 'cau-long'
      and tournament.slug in ('doi-nam-31-40', 'doi-nam-41-50')
  )
on conflict (fixture_id, entry_id) do update set side = excluded.side, archived_at = null;

do $$
declare
  source_id uuid;
begin
  for source_id in
    select fixture.id
    from public.fixtures fixture
    join public.tournaments tournament on tournament.id = fixture.tournament_id
    join public.sports sport on sport.id = tournament.sport_id
    where sport.slug = 'cau-long'
      and tournament.slug in ('doi-nam-31-40', 'doi-nam-41-50')
      and fixture.archived_at is null
    order by fixture.round_order nulls first, fixture.bracket_position nulls first, fixture.id
  loop
    perform private.sync_fixture_slots(source_id);
  end loop;
end
$$;

-- The workbook supplies this category, while the previous seed only supplied its group tables.
update public.tournaments t
set competition_mode = 'group_knockout',
    source_metadata = '{"file":"updates/PICKLEBALL EXCEL/ĐÔI NỮ/ĐÔI NỮ DƯỚI 30 TUỔI.xlsx","page_or_sheet":1,"warnings":["Sơ đồ loại trực tiếp được đối chiếu từ workbook cập nhật; ba bảng vòng loại giữ nguyên dữ liệu nguồn."]}'::jsonb
from public.sports s
where t.sport_id = s.id and s.slug = 'pickleball' and t.slug = 'doi-nu-duoi-30';

insert into public.fixtures (tenant_id, tournament_id, status, source_code, round_vi, round_en, round_order, bracket_position)
select t.tenant_id, t.id, 'scheduled', v.source_code, v.round_vi, v.round_en, v.round_order, v.bracket_position
from public.tournaments t
join public.sports s on s.id = t.sport_id
cross join (values
  ('1','Tứ kết','Quarterfinal',1,1), ('2','Tứ kết','Quarterfinal',1,2),
  ('3','Bán kết','Semifinal',2,1), ('4','Bán kết','Semifinal',2,2),
  ('CK','Chung kết','Final',3,1), ('H3','Tranh hạng ba','Bronze medal match',3,2)
) v(source_code, round_vi, round_en, round_order, bracket_position)
where s.slug = 'pickleball' and t.slug = 'doi-nu-duoi-30'
  and not exists (select 1 from public.fixtures existing where existing.tournament_id = t.id and existing.source_code = v.source_code and existing.archived_at is null);

insert into public.fixture_slots (tenant_id, fixture_id, side, source_kind, source_group_id, source_fixture_id, source_rank, label_vi, label_en)
select t.tenant_id, destination.id, v.side, v.source_kind, source_group.id, source_fixture.id, v.source_rank, v.label_vi, v.label_en
from public.tournaments t
join public.sports s on s.id = t.sport_id
cross join (values
  ('1','home','group_rank','Bảng C',null,2,'Nhì C','2nd C'), ('1','away','group_rank','Bảng B',null,1,'Nhất B','1st B'),
  ('2','home','group_rank','Bảng A',null,2,'Nhì A','2nd A'), ('2','away','group_rank','Bảng B',null,2,'Nhì B','2nd B'),
  ('3','home','group_rank','Bảng A',null,1,'Nhất A','1st A'), ('3','away','fixture_winner','', '1',null,'Thắng 1','Winner 1'),
  ('4','home','fixture_winner','', '2',null,'Thắng 2','Winner 2'), ('4','away','group_rank','Bảng C',null,1,'Nhất C','1st C'),
  ('CK','home','fixture_winner','', '3',null,'Thắng 3','Winner 3'), ('CK','away','fixture_winner','', '4',null,'Thắng 4','Winner 4'),
  ('H3','home','fixture_loser','', '3',null,'Thua bán kết 1','Loser semifinal 1'), ('H3','away','fixture_loser','', '4',null,'Thua bán kết 2','Loser semifinal 2')
) v(destination_code, side, source_kind, group_name, source_fixture_code, source_rank, label_vi, label_en)
join public.fixtures destination on destination.tournament_id = t.id and destination.source_code = v.destination_code and destination.archived_at is null
left join public.groups source_group on source_group.tournament_id = t.id and source_group.name_vi = v.group_name and source_group.archived_at is null
left join public.fixtures source_fixture on source_fixture.tournament_id = t.id and source_fixture.source_code = v.source_fixture_code and source_fixture.archived_at is null
where s.slug = 'pickleball' and t.slug = 'doi-nu-duoi-30'
  and ((v.source_kind = 'group_rank' and source_group.id is not null) or (v.source_kind in ('fixture_winner','fixture_loser') and source_fixture.id is not null))
on conflict (fixture_id, side) do update set
  source_kind = excluded.source_kind, source_group_id = excluded.source_group_id, source_fixture_id = excluded.source_fixture_id,
  source_rank = excluded.source_rank, label_vi = excluded.label_vi, label_en = excluded.label_en, archived_at = null;

-- Existing legacy rows must not override the reviewed source slots.
do $$
declare
  source_id uuid;
begin
  for source_id in select f.id from public.fixtures f where f.tenant_id = private.seed_tenant_id() and f.archived_at is null order by f.id loop
    perform private.sync_fixture_slots(source_id);
  end loop;
end
$$;
