set app.tenant_slug = 'petrovietnam2026';

insert into public.sports (id, slug, name_vi, name_en, emoji, description_vi, description_en, rules_vi, rules_en, sort_order) values
  ('10000000-0000-0000-0000-000000000001', 'pickleball', 'Pickleball', 'Pickleball', '/icons/pickleball.png', 'Thi đấu đôi theo nhóm tuổi.', 'Doubles competition by age group.', '12 hạng mục đôi nam, đôi nữ và đôi nam nữ theo nhóm tuổi. Thi đấu theo vòng bảng và loại trực tiếp; lịch đấu, bảng đấu và kết quả cập nhật theo dữ liệu thực tế.', '12 men’s, women’s and mixed doubles age-group categories. Group and knockout stages; schedules, brackets and results follow the live competition data.', 1),
  ('10000000-0000-0000-0000-000000000002', 'bong-ban', 'Bóng bàn', 'Table Tennis', '🏓', 'Thi đấu đôi nam, đôi nữ và đôi nam nữ.', 'Men’s, women’s and mixed doubles.', 'Thi đấu đôi nam, đôi nữ và đôi nam nữ theo các hạng mục tuổi. Vòng bảng và loại trực tiếp; đội thắng được xác định theo tỷ số trận.', 'Men’s, women’s and mixed doubles by age category. Group and knockout stages; winners are determined by match score.', 2),
  ('10000000-0000-0000-0000-000000000003', 'cau-long', 'Cầu lông', 'Badminton', '🏸', 'Thi đấu đôi theo giới tính và nhóm tuổi.', 'Doubles competition by gender and age group.', 'Thi đấu đôi theo giới tính và nhóm tuổi. Vận động viên thi đấu theo lịch và hạng mục đã đăng ký; kết quả được cập nhật sau từng trận.', 'Doubles competition by gender and age group. Athletes compete in their registered category; results are updated after each match.', 3),
  ('10000000-0000-0000-0000-000000000004', 'boi-loi', 'Bơi lội', 'Swimming', '🏊', 'Các cự ly tự do cá nhân và tiếp sức 4×50m.', 'Individual freestyle and 4×50m relays.', 'Gồm các nội dung 50m, 100m tự do và tiếp sức 4×50m. Xếp hạng theo thành tích thời gian được ghi nhận tại lượt thi.', 'Includes 50m, 100m freestyle and 4×50m relay events. Ranking follows the recorded time in each heat.', 4),
  ('10000000-0000-0000-0000-000000000005', 'keo-co', 'Kéo co', 'Tug of War', '🪢', 'Thi đấu đồng đội nam và nữ.', 'Men’s and women’s team competition.', 'Thi đấu đồng đội nam và nữ theo hạng mục. Mỗi trận gồm các đội đối đầu trực tiếp; kết quả và lịch thi đấu do Ban Tổ chức cập nhật.', 'Men’s and women’s team competition. Teams face each other directly; schedules and results are updated by the Organizing Committee.', 5),
  ('10000000-0000-0000-0000-000000000006', 'dien-kinh', 'Điền kinh', 'Athletics', '🏃', 'Các cự ly 400m, 800m, 3.000m, 5.000m và tiếp sức 4×100m.', '400m, 800m, 3,000m, 5,000m and 4×100m relay events.', 'Gồm các nội dung chạy cá nhân và tiếp sức 4×100m. Vận động viên xuất phát theo lượt; thành tích được tính bằng thời gian hoàn thành.', 'Includes individual running and 4×100m relay events. Athletes start in heats; performance is measured by finishing time.', 6),
  ('10000000-0000-0000-0000-000000000007', 'co-vua', 'Cờ vua', 'Chess', '♟️', 'Hệ Thụy Sĩ cá nhân.', 'Individual Swiss system.', 'Thi đấu cá nhân theo hệ Thụy Sĩ. Ghép cặp và xếp hạng căn cứ vào kết quả từng ván và các tiêu chí phụ theo điều lệ giải.', 'Individual Swiss-system competition. Pairings and ranking follow game results and the tie-break criteria of the event rules.', 7),
  ('10000000-0000-0000-0000-000000000008', 'co-tuong', 'Cờ tướng', 'Xiangqi', '♜', 'Hệ Thụy Sĩ cá nhân.', 'Individual Swiss system.', 'Thi đấu cá nhân theo hệ Thụy Sĩ. Mỗi ván được ghi nhận thắng, hòa hoặc thua; bảng xếp hạng cập nhật theo kết quả thi đấu.', 'Individual Swiss-system competition. Each game records a win, draw or loss; standings update from competition results.', 8)
on conflict (tenant_id, slug) do update set
  name_vi = excluded.name_vi, name_en = excluded.name_en, emoji = excluded.emoji,
  description_vi = excluded.description_vi, description_en = excluded.description_en,
  rules_vi = excluded.rules_vi, rules_en = excluded.rules_en,
  sort_order = excluded.sort_order, archived_at = null;

insert into public.tournaments (sport_id, slug, name_vi, name_en, category_vi, category_en, gender, format_vi, format_en, sort_order)
select s.id, v.slug, v.name_vi, v.name_en, v.category_vi, v.category_en, v.gender, v.format_vi, v.format_en, v.sort_order
from public.sports s
join (values
  ('pickleball','doi-nam-duoi-30','Đôi nam dưới 30 tuổi','Men’s Doubles Under 30','Dưới 30 tuổi','Under 30','male','Đôi','Doubles',1),
  ('pickleball','doi-nam-31-40','Đôi nam 31–40 tuổi','Men’s Doubles 31–40','31–40 tuổi','Ages 31–40','male','Đôi','Doubles',2),
  ('pickleball','doi-nam-41-50','Đôi nam 41–50 tuổi','Men’s Doubles 41–50','41–50 tuổi','Ages 41–50','male','Đôi','Doubles',3),
  ('pickleball','doi-nam-tren-51','Đôi nam từ 51 tuổi','Men’s Doubles 51+','Từ 51 tuổi','Ages 51+','male','Đôi','Doubles',4),
  ('pickleball','doi-nu-duoi-30','Đôi nữ dưới 30 tuổi','Women’s Doubles Under 30','Dưới 30 tuổi','Under 30','female','Đôi','Doubles',5),
  ('pickleball','doi-nu-31-40','Đôi nữ 31–40 tuổi','Women’s Doubles 31–40','31–40 tuổi','Ages 31–40','female','Đôi','Doubles',6),
  ('pickleball','doi-nu-41-50','Đôi nữ 41–50 tuổi','Women’s Doubles 41–50','41–50 tuổi','Ages 41–50','female','Đôi','Doubles',7),
  ('pickleball','doi-nu-tren-50','Đôi nữ từ 50 tuổi','Women’s Doubles 50+','Từ 50 tuổi','Ages 50+','female','Đôi','Doubles',8),
  ('pickleball','doi-nam-nu-duoi-30','Đôi nam nữ dưới 30 tuổi','Mixed Doubles Under 30','Dưới 30 tuổi','Under 30','mixed','Đôi','Doubles',9),
  ('pickleball','doi-nam-nu-31-40','Đôi nam nữ 31–40 tuổi','Mixed Doubles 31–40','31–40 tuổi','Ages 31–40','mixed','Đôi','Doubles',10),
  ('pickleball','doi-nam-nu-41-50','Đôi nam nữ 41–50 tuổi','Mixed Doubles 41–50','41–50 tuổi','Ages 41–50','mixed','Đôi','Doubles',11),
  ('pickleball','doi-nam-nu-tren-51','Đôi nam nữ từ 51 tuổi','Mixed Doubles 51+','Từ 51 tuổi','Ages 51+','mixed','Đôi','Doubles',12),
  ('bong-ban','doi-nam-duoi-30','Đôi nam dưới 30 tuổi','Men’s Doubles Under 30','Dưới 30 tuổi','Under 30','male','Vòng bảng và loại trực tiếp','Groups and knockouts',1),
  ('bong-ban','doi-nam-31-40','Đôi nam 31–40 tuổi','Men’s Doubles 31–40','31–40 tuổi','Ages 31–40','male','Vòng bảng và loại trực tiếp','Groups and knockouts',2),
  ('bong-ban','doi-nam-41-50','Đôi nam 41–50 tuổi','Men’s Doubles 41–50','41–50 tuổi','Ages 41–50','male','Vòng bảng và loại trực tiếp','Groups and knockouts',3),
  ('bong-ban','doi-nu','Đôi nữ','Women’s Doubles','Mở rộng','Open','female','Vòng bảng và loại trực tiếp','Groups and knockouts',4),
  ('bong-ban','doi-nam-nu-31-40','Đôi nam nữ 31–40 tuổi','Mixed Doubles 31–40','31–40 tuổi','Ages 31–40','mixed','Vòng bảng và loại trực tiếp','Groups and knockouts',5),
  ('bong-ban','doi-nam-nu-41-50','Đôi nam nữ 41–50 tuổi','Mixed Doubles 41–50','41–50 tuổi','Ages 41–50','mixed','Vòng bảng và loại trực tiếp','Groups and knockouts',6),
  ('cau-long','doi-nam-duoi-30','Đôi nam dưới 30 tuổi','Men’s Doubles Under 30','Dưới 30 tuổi','Under 30','male','Đôi','Doubles',1),
  ('cau-long','doi-nam-31-40','Đôi nam 31–40 tuổi','Men’s Doubles 31–40','31–40 tuổi','Ages 31–40','male','Đôi','Doubles',2),
  ('cau-long','doi-nam-41-50','Đôi nam 41–50 tuổi','Men’s Doubles 41–50','41–50 tuổi','Ages 41–50','male','Đôi','Doubles',3),
  ('cau-long','doi-nam-tren-51','Đôi nam từ 51 tuổi','Men’s Doubles 51+','Từ 51 tuổi','Ages 51+','male','Đôi','Doubles',4),
  ('cau-long','doi-nam-nu-duoi-30','Đôi nam nữ dưới 30 tuổi','Mixed Doubles Under 30','Dưới 30 tuổi','Under 30','mixed','Đôi','Doubles',5),
  ('cau-long','doi-nam-nu-31-40','Đôi nam nữ 31–40 tuổi','Mixed Doubles 31–40','31–40 tuổi','Ages 31–40','mixed','Đôi','Doubles',6),
  ('cau-long','doi-nam-nu-41-50','Đôi nam nữ 41–50 tuổi','Mixed Doubles 41–50','41–50 tuổi','Ages 41–50','mixed','Đôi','Doubles',7),
  ('cau-long','doi-nu-duoi-30','Đôi nữ dưới 30 tuổi','Women’s Doubles Under 30','Dưới 30 tuổi','Under 30','female','Đôi','Doubles',8),
  ('cau-long','doi-nu-31-40','Đôi nữ 31–40 tuổi','Women’s Doubles 31–40','31–40 tuổi','Ages 31–40','female','Đôi','Doubles',9),
  ('boi-loi','50m-nam','50m tự do nam','Men’s 50m Freestyle','Các nhóm tuổi','Age groups','male','Cá nhân','Individual',1),
  ('boi-loi','50m-nu','50m tự do nữ','Women’s 50m Freestyle','Các nhóm tuổi','Age groups','female','Cá nhân','Individual',2),
  ('boi-loi','100m-nam','100m tự do nam','Men’s 100m Freestyle','Các nhóm tuổi','Age groups','male','Cá nhân','Individual',3),
  ('boi-loi','100m-nu','100m tự do nữ','Women’s 100m Freestyle','Các nhóm tuổi','Age groups','female','Cá nhân','Individual',4),
  ('boi-loi','4x50m-nam','Tiếp sức nam 4×50m','Men’s 4×50m Relay','Đồng đội','Team','male','Tiếp sức','Relay',5),
  ('boi-loi','4x50m-nu','Tiếp sức nữ 4×50m','Women’s 4×50m Relay','Đồng đội','Team','female','Tiếp sức','Relay',6),
  ('keo-co','nam','Kéo co nam','Men’s Tug of War','Nam','Men','male','Đồng đội','Team',1),
  ('keo-co','nu','Kéo co nữ','Women’s Tug of War','Nữ','Women','female','Đồng đội','Team',2),
  ('dien-kinh','400m-nu','400m nữ','Women’s 400m','Các nhóm tuổi','Age groups','female','Cá nhân','Individual',1),
  ('dien-kinh','800m-nam','800m nam','Men’s 800m','Các nhóm tuổi','Age groups','male','Cá nhân','Individual',2),
  ('dien-kinh','4x100m-nu','Tiếp sức nữ 4×100m','Women’s 4×100m Relay','Đồng đội','Team','female','Tiếp sức','Relay',3),
  ('dien-kinh','4x100m-nam','Tiếp sức nam 4×100m','Men’s 4×100m Relay','Đồng đội','Team','male','Tiếp sức','Relay',4),
  ('dien-kinh','3000m-nu','3.000m nữ','Women’s 3,000m','Các nhóm tuổi','Age groups','female','Cá nhân','Individual',5),
  ('dien-kinh','5000m-nam','5.000m nam','Men’s 5,000m','Các nhóm tuổi','Age groups','male','Cá nhân','Individual',6),
  ('co-vua','nu','Cờ vua nữ','Women’s Chess','Nữ','Women','female','Hệ Thụy Sĩ cá nhân','Individual Swiss system',1),
  ('co-vua','nam-duoi-45','Cờ vua nam dưới 45 tuổi','Men’s Chess Under 45','Dưới 45 tuổi','Under 45','male','Hệ Thụy Sĩ cá nhân','Individual Swiss system',2),
  ('co-vua','nam-tren-45','Cờ vua nam trên 45 tuổi','Men’s Chess Over 45','Trên 45 tuổi','Over 45','male','Hệ Thụy Sĩ cá nhân','Individual Swiss system',3),
  ('co-tuong','nam-duoi-45','Cờ tướng nam dưới 45 tuổi','Men’s Xiangqi Under 45','Dưới 45 tuổi','Under 45','male','Hệ Thụy Sĩ cá nhân','Individual Swiss system',1),
  ('co-tuong','nam-tren-45','Cờ tướng nam trên 45 tuổi','Men’s Xiangqi Over 45','Trên 45 tuổi','Over 45','male','Hệ Thụy Sĩ cá nhân','Individual Swiss system',2)
) as v(sport_slug, slug, name_vi, name_en, category_vi, category_en, gender, format_vi, format_en, sort_order)
  on s.slug = v.sport_slug
where s.tenant_id = private.seed_tenant_id()
on conflict (tenant_id, sport_id, slug) do update set
  name_vi = excluded.name_vi, name_en = excluded.name_en,
  category_vi = excluded.category_vi, category_en = excluded.category_en,
  gender = excluded.gender, format_vi = excluded.format_vi, format_en = excluded.format_en,
  sort_order = excluded.sort_order, archived_at = null;

insert into public.organizations (code, name_vi, name_en, sort_order) values
  ('BĐPOC','BĐPOC','BĐPOC',1), ('BMĐH','BMĐH Petrovietnam','Petrovietnam Executive Board',2),
  ('LP1PP','LP1PP','LP1PP',3), ('NCKHĐT','NCKHĐT','NCKHĐT',4), ('PETROSETCO','PETROSETCO','PETROSETCO',5),
  ('PQPOC','PQPOC','PQPOC',6), ('PTSC','PTSC','PTSC',7), ('PV DRILLING','PV Drilling','PV Drilling',8),
  ('PVCFC','PVCFC','PVCFC',9), ('PVCHEM','PVChem','PVChem',10), ('PVCOMBANK','PVcomBank','PVcomBank',11),
  ('PVE','PVE','PVE',12), ('PVEP','PVEP','PVEP',13), ('PVFCCO','PVFCCo','PVFCCo',14),
  ('PV GAS','PV GAS','PV GAS',15), ('PVMR','PVMR','PVMR',16), ('PVOIL','PVOIL','PVOIL',17),
  ('PVPMB','PVPMB','PVPMB',18), ('PVTRANS','PVTrans','PVTrans',19), ('SWPOC','SWPOC','SWPOC',20), ('VSP','Vietsovpetro','Vietsovpetro',21)
on conflict (tenant_id, code) do update set name_vi = excluded.name_vi, name_en = excluded.name_en, sort_order = excluded.sort_order, archived_at = null;

insert into public.venues (id, name_vi, name_en, address_vi, address_en, sort_order) values
  ('30000000-0000-0000-0000-000000000001','Địa điểm đang cập nhật','Venue to be confirmed','','',1)
on conflict (id) do update set name_vi = excluded.name_vi, name_en = excluded.name_en, archived_at = null;

-- Only source-explicit times are seeded; blank courts and results are not inferred.
insert into public.fixtures (tournament_id, starts_at, status, round_vi, round_en)
select t.id, v.starts_at::timestamptz, 'scheduled', 'Thi đấu', 'Competition'
from public.tournaments t
join public.sports s on s.id = t.sport_id
join (values
  ('bong-ban','doi-nam-41-50','2026-09-05 07:30:00+07'),
  ('bong-ban','doi-nam-31-40','2026-09-05 07:30:00+07'),
  ('bong-ban','doi-nam-duoi-30','2026-09-05 08:30:00+07'),
  ('bong-ban','doi-nam-41-50','2026-09-05 13:30:00+07'),
  ('bong-ban','doi-nam-31-40','2026-09-05 13:30:00+07'),
  ('bong-ban','doi-nam-duoi-30','2026-09-05 13:30:00+07'),
  ('bong-ban','doi-nam-nu-31-40','2026-09-05 14:30:00+07'),
  ('bong-ban','doi-nam-nu-41-50','2026-09-05 14:30:00+07'),
  ('bong-ban','doi-nu','2026-09-05 14:30:00+07'),
  ('bong-ban','doi-nam-nu-31-40','2026-09-06 07:30:00+07'),
  ('bong-ban','doi-nam-nu-41-50','2026-09-06 07:30:00+07'),
  ('bong-ban','doi-nu','2026-09-06 08:30:00+07'),
  ('cau-long','doi-nam-duoi-30','2026-09-05 07:30:00+07'),
  ('cau-long','doi-nam-41-50','2026-09-05 07:30:00+07'),
  ('cau-long','doi-nu-duoi-30','2026-09-05 08:30:00+07'),
  ('cau-long','doi-nu-31-40','2026-09-05 08:30:00+07'),
  ('cau-long','doi-nam-nu-31-40','2026-09-05 09:00:00+07'),
  ('cau-long','doi-nam-31-40','2026-09-05 09:00:00+07'),
  ('cau-long','doi-nam-duoi-30','2026-09-05 13:30:00+07'),
  ('cau-long','doi-nam-nu-duoi-30','2026-09-05 13:30:00+07'),
  ('cau-long','doi-nam-41-50','2026-09-05 13:30:00+07'),
  ('cau-long','doi-nu-duoi-30','2026-09-05 14:00:00+07'),
  ('cau-long','doi-nu-31-40','2026-09-05 14:00:00+07'),
  ('cau-long','doi-nam-nu-41-50','2026-09-05 14:00:00+07'),
  ('cau-long','doi-nam-tren-51','2026-09-05 15:00:00+07'),
  ('cau-long','doi-nu-duoi-30','2026-09-05 15:30:00+07'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07'),
  ('boi-loi','50m-nu','2026-09-05 08:15:00+07'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07'),
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07'),
  ('boi-loi','4x50m-nu','2026-09-05 15:30:00+07'),
  ('keo-co','nam','2026-09-04 16:00:00+07'),
  ('keo-co','nu','2026-09-04 16:00:00+07'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07'),
  ('dien-kinh','400m-nu','2026-09-06 06:00:00+07'),
  ('dien-kinh','4x100m-nu','2026-09-06 07:00:00+07'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07')
) as v(sport_slug, tournament_slug, starts_at)
  on s.slug = v.sport_slug and t.slug = v.tournament_slug
where not exists (
  select 1 from public.fixtures f where f.tournament_id = t.id and f.starts_at = v.starts_at::timestamptz
);
