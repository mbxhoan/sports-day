set app.tenant_slug = 'petrovietnam2026';

create temporary table seed_roster (
  sport_slug text, tournament_slug text, full_name text, org_code text
) on commit drop;

insert into seed_roster values
  ('co-vua','nu','Nguyễn Thị Thiềm','PV DRILLING'),
  ('co-vua','nu','Phạm Nguyễn Như','PVE'),
  ('co-vua','nu','Bùi Trịnh Vân Anh','PVFCCO'),
  ('co-vua','nu','Nguyễn Thị Quế Châu','PVFCCO'),
  ('co-vua','nu','Đoàn Thị Loan','PVOIL'),
  ('co-vua','nu','Trần Thị Hoài Thương','PVOIL'),
  ('co-vua','nu','Đỗ Đức Hạnh','VSP'),
  ('co-vua','nu','Đỗ Thị Thùy Dung','VSP'),
  ('co-vua','nu','Lê Hải Hà My','VSP'),
  ('co-vua','nu','Trịnh Thị Phượng','VSP'),
  ('co-vua','nu','Vũ Thị Thanh Trúc','VSP'),
  ('co-vua','nu','Lê Thị Mai Thanh','BMĐH'),
  ('co-vua','nu','Đoàn Thanh Mai','PVFCCO'),
  ('co-vua','nam-duoi-45','Dương Tiến Trung','NCKHĐT'),
  ('co-vua','nam-duoi-45','Hoàng Đại Dương','PTSC'),
  ('co-vua','nam-duoi-45','Lê Quang Minh','PV DRILLING'),
  ('co-vua','nam-duoi-45','Lương Xuân Cường','PV DRILLING'),
  ('co-vua','nam-duoi-45','Hồ Ngọc Tuấn Vũ','PV GAS'),
  ('co-vua','nam-duoi-45','Lê Cẩm Hoàng Tuấn','PV GAS'),
  ('co-vua','nam-duoi-45','Nguyễn Công Thành','PV GAS'),
  ('co-vua','nam-duoi-45','Nguyễn Văn Ni','PV GAS'),
  ('co-vua','nam-duoi-45','Trần Đức Tài','PV GAS'),
  ('co-vua','nam-duoi-45','Trần Mạnh Duy','PV GAS'),
  ('co-vua','nam-duoi-45','Trần Minh Hiếu','PV GAS'),
  ('co-vua','nam-duoi-45','Vũ Thành Lâm','PV GAS'),
  ('co-vua','nam-duoi-45','Nguyễn Văn Toàn','PVCFC'),
  ('co-vua','nam-duoi-45','Lưu Văn Thuận','PVCOMBANK'),
  ('co-vua','nam-duoi-45','Đào Hoàng Anh','PVE'),
  ('co-vua','nam-duoi-45','Trịnh Cao Văn Phúc','PVE'),
  ('co-vua','nam-duoi-45','Lương Đức Hiếu','PVEP'),
  ('co-vua','nam-duoi-45','Nguyễn Hải Đăng','PVEP'),
  ('co-vua','nam-duoi-45','Trần Minh Đạt','PVEP'),
  ('co-vua','nam-duoi-45','Trịnh Duy Khánh','PVFCCO'),
  ('co-vua','nam-duoi-45','Vũ Minh Đức','PVFCCO'),
  ('co-vua','nam-duoi-45','Nguyễn Thanh An','PVOIL'),
  ('co-vua','nam-duoi-45','Bùi Cảnh Hưng','PVTRANS'),
  ('co-vua','nam-duoi-45','Bùi Hoàng Đức','PVTRANS'),
  ('co-vua','nam-duoi-45','Đặng Trọng Phương','VSP'),
  ('co-vua','nam-duoi-45','Phương Văn Anh','VSP'),
  ('co-vua','nam-duoi-45','Trần Lê Kiên','VSP'),
  ('co-vua','nam-tren-45','Lê Ngọc Thạch','PVCFC'),
  ('co-vua','nam-tren-45','Lê Đình Thành','PVEP'),
  ('co-vua','nam-tren-45','Nguyễn Anh Hùng','PVFCCO'),
  ('co-vua','nam-tren-45','Phan Lạc Đức','PVFCCO'),
  ('co-vua','nam-tren-45','Hà Hữu Anh','PVTRANS'),
  ('co-vua','nam-tren-45','Nguyễn Thái Bình','PVTRANS'),
  ('co-vua','nam-tren-45','Nguyễn Thúc Hà','VSP'),
  ('co-vua','nam-tren-45','Nguyễn Văn Lục','VSP'),
  ('co-vua','nam-tren-45','Phạm Linh Tùng','VSP'),
  ('co-tuong','nam-duoi-45','Võ Duy Nam','BĐPOC'),
  ('co-tuong','nam-duoi-45','Võ Hoàng Long','BĐPOC'),
  ('co-tuong','nam-duoi-45','Trần Ngọc Hiệp','NCKHĐT'),
  ('co-tuong','nam-duoi-45','Trương Thanh Tuấn','NCKHĐT'),
  ('co-tuong','nam-duoi-45','Nguyễn Ngọc Anh Huy','PQPOC'),
  ('co-tuong','nam-duoi-45','Chu Đình Quang Vinh','PTSC'),
  ('co-tuong','nam-duoi-45','Nguyễn Mạnh Cường','PTSC'),
  ('co-tuong','nam-duoi-45','Đỗ Quang Lâm','PV DRILLING'),
  ('co-tuong','nam-duoi-45','Nguyễn Thành Trung','PV DRILLING'),
  ('co-tuong','nam-duoi-45','Nguyễn Phúc Anh','PV GAS'),
  ('co-tuong','nam-duoi-45','Phan Tùng Hải','PV GAS'),
  ('co-tuong','nam-duoi-45','Trần Minh Phúc','PV GAS'),
  ('co-tuong','nam-duoi-45','Nguyễn Đức Hiên','PVCFC'),
  ('co-tuong','nam-duoi-45','Vũ Ngọc Thắng','PVCFC'),
  ('co-tuong','nam-duoi-45','Đỗ Ngọc Huân','PVCOMBANK'),
  ('co-tuong','nam-duoi-45','Đào Quốc Tuấn','PVE'),
  ('co-tuong','nam-duoi-45','Đoàn Văn Danh','PVE'),
  ('co-tuong','nam-duoi-45','Phạm Quốc Huy','PVEP'),
  ('co-tuong','nam-duoi-45','Lê Văn Ân','PVFCCO'),
  ('co-tuong','nam-duoi-45','Nguyễn Văn Hồng','PVFCCO'),
  ('co-tuong','nam-duoi-45','Phạm Thương Tín','PVFCCO'),
  ('co-tuong','nam-duoi-45','Lê Đức Dũng','PVMR'),
  ('co-tuong','nam-duoi-45','Phạm Hải Long','PVOIL'),
  ('co-tuong','nam-duoi-45','Vũ Hoàng Phúc','PVTRANS'),
  ('co-tuong','nam-duoi-45','Bùi Văn Hòa','VSP'),
  ('co-tuong','nam-duoi-45','Nguyễn Hữu Nhân','VSP'),
  ('co-tuong','nam-duoi-45','Nguyễn Mạnh Hải','VSP'),
  ('co-tuong','nam-duoi-45','Nguyễn Mạnh Tiến','VSP'),
  ('co-tuong','nam-duoi-45','Nguyễn Thái Quỳnh','VSP'),
  ('co-tuong','nam-duoi-45','Tạ Hoài Trang','VSP'),
  ('co-tuong','nam-tren-45','Huỳnh Huy Giáp','LP1PP'),
  ('co-tuong','nam-tren-45','Nguyễn Trung Kiên','PQPOC'),
  ('co-tuong','nam-tren-45','Nguyễn Trọng Quý','PQPOC'),
  ('co-tuong','nam-tren-45','Tạ Trung Dũng','PTSC'),
  ('co-tuong','nam-tren-45','Nguyễn Phúc Thọ','PV DRILLING'),
  ('co-tuong','nam-tren-45','Lưu Quang Tuấn','PV GAS'),
  ('co-tuong','nam-tren-45','Ngô Thế Phương','PV GAS'),
  ('co-tuong','nam-tren-45','Nguyễn Vỹ','PV GAS'),
  ('co-tuong','nam-tren-45','Vũ Ngọc Thạch','PV GAS'),
  ('co-tuong','nam-tren-45','Đái Quốc Triều','PVCFC'),
  ('co-tuong','nam-tren-45','Nguyễn Bá Phương','PVFCCO'),
  ('co-tuong','nam-tren-45','Nguyễn Thanh Mạnh','PVFCCO'),
  ('co-tuong','nam-tren-45','Nguyễn Trọng Nghĩa','PVFCCO'),
  ('co-tuong','nam-tren-45','Hoàng Văn Mười','PVOIL'),
  ('co-tuong','nam-tren-45','Mai Văn Hùng','PVOIL'),
  ('co-tuong','nam-tren-45','Nguyễn Xuân Tuấn','PVOIL'),
  ('co-tuong','nam-tren-45','Nguyễn Hoàng Trường','VSP'),
  ('co-tuong','nam-tren-45','Nguyễn Hoàng Vinh','VSP'),
  ('co-tuong','nam-tren-45','Trần Nguyên Đồng','VSP');

insert into public.participants (organization_id, full_name, gender)
select o.id, r.full_name, case when r.tournament_slug = 'nu' then 'female' else 'male' end
from seed_roster r join public.organizations o on o.code = r.org_code
where not exists (
  select 1 from public.participants p where p.organization_id = o.id and p.full_name = r.full_name
);

insert into public.entries (tournament_id, organization_id, kind, name_vi, name_en)
select t.id, o.id, 'individual', r.full_name, r.full_name
from seed_roster r
join public.sports s on s.slug = r.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = r.tournament_slug
join public.organizations o on o.code = r.org_code
where not exists (
  select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = r.full_name
);

insert into public.entry_members (entry_id, participant_id)
select e.id, p.id
from seed_roster r
join public.sports s on s.slug = r.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = r.tournament_slug
join public.organizations o on o.code = r.org_code
join public.entries e on e.tournament_id = t.id and e.organization_id = o.id and e.name_vi = r.full_name
join public.participants p on p.organization_id = o.id and p.full_name = r.full_name
on conflict (entry_id, participant_id) do nothing;
