set app.tenant_slug = 'petrovietnam2026';

-- Generated from reviewed PDFs. Missing unit labels and self-pair extraction artifacts stay unseeded.
create temporary table seed_pair_sports (
  sport_slug text, tournament_slug text, group_name text, group_order integer, pair_name text,
  organization_code text, member_one text, member_two text, source_page integer
) on commit drop;
insert into seed_pair_sports values
  ('bong-ban','doi-nam-duoi-30','Bảng A',2,'Nguyễn Hữu Mạnh / Nguyễn Văn Khai-PVG','PVG','Nguyễn Hữu Mạnh','Nguyễn Văn Khai',2),
  ('bong-ban','doi-nam-duoi-30','Bảng A',2,'Chu Xuân Hải / Lê Hồng Thái-PVFCCo','PVFCCo','Chu Xuân Hải','Lê Hồng Thái',2),
  ('bong-ban','doi-nam-duoi-30','Bảng A',2,'Âu Công Phúc / Vũ Việt Hoàng-PTSC','PTSC','Âu Công Phúc','Vũ Việt Hoàng',2),
  ('bong-ban','doi-nam-duoi-30','Bảng A',2,'Hoàng Phương Nam / Phạm Văn Đồng-VSP','VSP','Hoàng Phương Nam','Phạm Văn Đồng',2),
  ('bong-ban','doi-nam-duoi-30','Bảng A',2,'Nguyễn Hữu Phương / Nguyễn Quang Trung-PVCFC','PVCFC','Nguyễn Hữu Phương','Nguyễn Quang Trung',2),
  ('bong-ban','doi-nam-duoi-30','Bảng B',3,'Huỳnh Bảo Xuyên / Trần Ngọc Thạch-PVG','PVG','Huỳnh Bảo Xuyên','Trần Ngọc Thạch',3),
  ('bong-ban','doi-nam-duoi-30','Bảng B',3,'Nguyễn Tuấn Anh / Trần Thanh Nam-VSP','VSP','Nguyễn Tuấn Anh','Trần Thanh Nam',3),
  ('bong-ban','doi-nam-duoi-30','Bảng B',3,'Lê Tiến Hào / Phạm Trung Kiên-PVFCCo','PVFCCo','Lê Tiến Hào','Phạm Trung Kiên',3),
  ('bong-ban','doi-nam-duoi-30','Bảng B',3,'Lê Văn Vui / Phương Công Anh-PVTRANS','PVTRANS','Lê Văn Vui','Phương Công Anh',3),
  ('bong-ban','doi-nam-duoi-30','Bảng B',3,'Cao Đức Hạnh / Cao Văn Tuân-PVOIL','PVOIL','Cao Đức Hạnh','Cao Văn Tuân',3),
  ('bong-ban','doi-nam-31-40','Bảng A',5,'Nguyễn Mạnh Hà / Võ Bá Anh Tuấn-PVD','PVD','Nguyễn Mạnh Hà','Võ Bá Anh Tuấn',5),
  ('bong-ban','doi-nam-31-40','Bảng A',5,'Nguyễn Mạnh Tùng / Phạm Tú Anh-VSP','VSP','Nguyễn Mạnh Tùng','Phạm Tú Anh',5),
  ('bong-ban','doi-nam-31-40','Bảng A',5,'Trần Ngọc Sơn / Vũ Hải Long PVPMB',null,null,null,5),
  ('bong-ban','doi-nam-31-40','Bảng A',5,'Nguyễn Vũ Chiến / Trần Tất Thắng-PVTRAS','PVTRAS','Nguyễn Vũ Chiến','Trần Tất Thắng',5),
  ('bong-ban','doi-nam-31-40','Bảng A',5,'Bùi Văn Thiện / Nguyễn Quốc Hưng-PVG','PVG','Bùi Văn Thiện','Nguyễn Quốc Hưng',5),
  ('bong-ban','doi-nam-31-40','Bảng B',2,'Trần Huy Bảo / Võ Văn Lung-PVFCCo','PVFCCo','Trần Huy Bảo','Võ Văn Lung',6),
  ('bong-ban','doi-nam-31-40','Bảng B',2,'Phạm Dương Ngọc Lợi / Trần Quốc Bình-PET','PET','Phạm Dương Ngọc Lợi','Trần Quốc Bình',6),
  ('bong-ban','doi-nam-31-40','Bảng B',2,'Phan Ngọc Lai / Nguyễn Văn Vinh - PVTRANS','PVTRANS',null,null,6),
  ('bong-ban','doi-nam-31-40','Bảng B',2,'Nguyễn Trọng Vĩnh / Trần Nhựt Duy-PVG','PVG','Nguyễn Trọng Vĩnh','Trần Nhựt Duy',6),
  ('bong-ban','doi-nam-31-40','Bảng B',2,'Phạm Đức Thư / Trần Việt Dũng-PTSC','PTSC','Phạm Đức Thư','Trần Việt Dũng',6),
  ('bong-ban','doi-nam-31-40','Bảng B',2,'Đặng Đình Phúc / Lê Anh Thoại-VSP','VSP','Đặng Đình Phúc','Lê Anh Thoại',6),
  ('bong-ban','doi-nam-41-50','Bảng A',8,'Lèng Văn Chi / Trần Xuân Mạnh-PVEP','PVEP','Lèng Văn Chi','Trần Xuân Mạnh',8),
  ('bong-ban','doi-nam-41-50','Bảng A',8,'Nguyễn Hải Sơn / Phạm Văn Bảy-VSP','VSP','Nguyễn Hải Sơn','Phạm Văn Bảy',8),
  ('bong-ban','doi-nam-41-50','Bảng A',8,'Đinh Xuân Hiền / Nguyễn Minh Thắng-PVTRANS','PVTRANS','Đinh Xuân Hiền','Nguyễn Minh Thắng',8),
  ('bong-ban','doi-nam-41-50','Bảng A',8,'Nguyễn Ngọc Lân / Phan Quốc Thắng-PVD','PVD','Nguyễn Ngọc Lân','Phan Quốc Thắng',8),
  ('bong-ban','doi-nam-41-50','Bảng B',9,'Đặng Xuân Đức / Lê Hoàng Vĩnh Thái-PET','PET','Đặng Xuân Đức','Lê Hoàng Vĩnh Thái',9),
  ('bong-ban','doi-nam-41-50','Bảng B',9,'Hồ Đức Kỳ / Trần Đình Nam-PTSC','PTSC','Hồ Đức Kỳ','Trần Đình Nam',9),
  ('bong-ban','doi-nam-41-50','Bảng B',9,'Phan Viết Hoàng / Võ Hồng Sơn-PVI','PVI','Phan Viết Hoàng','Võ Hồng Sơn',9),
  ('bong-ban','doi-nam-41-50','Bảng B',9,'Lê Thanh Châu / Phạm Công Điện',null,null,null,9),
  ('bong-ban','doi-nam-41-50','Bảng C',10,'Bùi Văn Dũng / Vũ Đình Chính',null,null,null,9),
  ('bong-ban','doi-nam-41-50','Bảng C',10,'Nguyễn Hà Hải / Nguyễn Văn Ánh-PTSC','PTSC','Nguyễn Hà Hải','Nguyễn Văn Ánh',9),
  ('bong-ban','doi-nam-41-50','Bảng C',10,'Đặng Thiệu Ích / Nguyễn Đồng Hiệp-PVCFC','PVCFC','Đặng Thiệu Ích','Nguyễn Đồng Hiệp',9),
  ('bong-ban','doi-nam-41-50','Bảng C',10,'Nguyễn Thành Nam / Nguyễn Tiến Dũng-VSP','VSP','Nguyễn Thành Nam','Nguyễn Tiến Dũng',9),
  ('bong-ban','doi-nam-41-50','Bảng D',11,'Đinh Chí Thanh / Nguyễn Ngọc Hòe-PVE','PVE','Đinh Chí Thanh','Nguyễn Ngọc Hòe',10),
  ('bong-ban','doi-nam-41-50','Bảng D',11,'Hoàng Quang Thịnh / Trần Quang Bình-VSP','VSP','Hoàng Quang Thịnh','Trần Quang Bình',10),
  ('bong-ban','doi-nam-41-50','Bảng D',11,'Đinh Quang Vinh / Lê Văn ChoPVFCCo',null,null,null,10),
  ('bong-ban','doi-nam-41-50','Bảng D',11,'Bùi Công Tâm / Nguyễn Vũ Hiệp-PVG','PVG','Bùi Công Tâm','Nguyễn Vũ Hiệp',10),
  ('bong-ban','doi-nam-41-50','Bảng E',12,'Đào Phú Hoàng / Đào Xuân Thu-PVG','PVG','Đào Phú Hoàng','Đào Xuân Thu',11),
  ('bong-ban','doi-nam-41-50','Bảng E',12,'Nguyễn Hữu Tùng / Trần Đức Ninh-BMĐH','BMĐH','Nguyễn Hữu Tùng','Trần Đức Ninh',11),
  ('bong-ban','doi-nam-41-50','Bảng E',12,'Doàn Quốc Quân / Vũ Tiến Dũng-PVFCCo','PVFCCo','Doàn Quốc Quân','Vũ Tiến Dũng',11),
  ('bong-ban','doi-nam-41-50','Bảng E',12,'Phạm Thành Trung / Vũ Anh Hữu',null,null,null,11),
  ('bong-ban','doi-nam-41-50','Bảng F',13,'Nguyễn Tấn Nam Phương / Phù Quang Thạch-PVTRANS','PVTRANS','Nguyễn Tấn Nam Phương','Phù Quang Thạch',12),
  ('bong-ban','doi-nam-41-50','Bảng F',13,'Dương Minh Bảo Phác / Đặng Văn Sơn-PVEP','PVEP','Dương Minh Bảo Phác','Đặng Văn Sơn',12),
  ('bong-ban','doi-nam-41-50','Bảng F',13,'Nguyễn Văn Hiếu / Vũ Văn Sỹ-VSP','VSP','Nguyễn Văn Hiếu','Vũ Văn Sỹ',12),
  ('bong-ban','doi-nam-41-50','Bảng F',13,'Đào Quang Thành / Hoàng Văn Tuấn-BĐPOC','BĐPOC','Đào Quang Thành','Hoàng Văn Tuấn',12),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Đào Quang Thành / Hoàng Văn Tuấn-BĐPOC','BĐPOC','Đào Quang Thành','Hoàng Văn Tuấn',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Nguyễn Hữu Tùng / Trần Đức Ninh-BMĐH','BMĐH','Nguyễn Hữu Tùng','Trần Đức Ninh',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Đặng Xuân Đức / Lê Hoàng Vĩnh Thái-PET','PET','Đặng Xuân Đức','Lê Hoàng Vĩnh Thái',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Lê Thanh Châu / Phạm Công Điện',null,null,null,14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Hồ Đức Kỳ / Trần Đình Nam-PTSC','PTSC','Hồ Đức Kỳ','Trần Đình Nam',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Nguyễn Hà Hải / Nguyễn Văn Ánh-PTSC','PTSC','Nguyễn Hà Hải','Nguyễn Văn Ánh',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Nguyễn Ngọc Lân / Phan Quốc Thắng-PVD','PVD','Nguyễn Ngọc Lân','Phan Quốc Thắng',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Bùi Công Tâm / Nguyễn Vũ Hiệp-PVG','PVG','Bùi Công Tâm','Nguyễn Vũ Hiệp',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Đào Phú Hoàng / Đào Xuân Thu-PVG','PVG','Đào Phú Hoàng','Đào Xuân Thu',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Đặng Thiệu Ích / Nguyễn Đồng Hiệp-PVCFC','PVCFC','Đặng Thiệu Ích','Nguyễn Đồng Hiệp',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Đinh Chí Thanh / Nguyễn Ngọc Hòe-PVE','PVE','Đinh Chí Thanh','Nguyễn Ngọc Hòe',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Lèng Văn Chi / Trần Xuân Mạnh-PVEP','PVEP','Lèng Văn Chi','Trần Xuân Mạnh',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Dương Minh Bảo Phác / Đặng Văn Sơn-PVEP','PVEP','Dương Minh Bảo Phác','Đặng Văn Sơn',14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Đinh Quang Vinh / Lê Văn ChoPVFCCo',null,null,null,14),
  ('bong-ban','doi-nam-41-50','Danh sách',15,'Bùi Văn Dũng / Vũ Đình Chính',null,null,null,14),
  ('bong-ban','doi-nu','Bảng A',16,'Lê Thanh Nga / Phạm Thuý Anh-VSP','VSP','Lê Thanh Nga','Phạm Thuý Anh',15),
  ('bong-ban','doi-nu','Bảng A',16,'Đào Thị Thanh Huyền / Đào Thị Thúy Hằng-VSP','VSP','Đào Thị Thanh Huyền','Đào Thị Thúy Hằng',15),
  ('bong-ban','doi-nu','Bảng A',16,'Nguyễn Thị Thúy Hằng / Phạm Thị Lương-PVG','PVG','Nguyễn Thị Thúy Hằng','Phạm Thị Lương',15),
  ('bong-ban','doi-nu','Bảng A',16,'Đinh Thị Lan Anh / Nguyễn Thị Ninh-VSP','VSP','Đinh Thị Lan Anh','Nguyễn Thị Ninh',15),
  ('bong-ban','doi-nu','Bảng B',17,'Nguyễn Thị Anh Thơ / Nguyễn Thị Thu Thủy-PVCOM','PVCOM','Nguyễn Thị Anh Thơ','Nguyễn Thị Thu Thủy',15),
  ('bong-ban','doi-nu','Bảng B',17,'Hoàng Thị Thơm / Nguyễn Thị Hiên-VSP','VSP','Hoàng Thị Thơm','Nguyễn Thị Hiên',15),
  ('bong-ban','doi-nu','Bảng B',17,'Nguyễn Thị Bạch Mai / Phan Thị Mai-VSP','VSP','Nguyễn Thị Bạch Mai','Phan Thị Mai',15),
  ('bong-ban','doi-nu','Bảng B',17,'Đào Thị Kim Anh / Trần Thị Thanh Huyền-PVFCCo','PVFCCo','Đào Thị Kim Anh','Trần Thị Thanh Huyền',16),
  ('bong-ban','doi-nu','Bảng B',17,'Nguyễn Thị Anh Thơ / Nguyễn Thị Thu Thủy-PVCOM','PVCOM','Nguyễn Thị Anh Thơ','Nguyễn Thị Thu Thủy',16),
  ('bong-ban','doi-nu','Bảng B',17,'Hoàng Thị Thơm / Nguyễn Thị Hiên-VSP','VSP','Hoàng Thị Thơm','Nguyễn Thị Hiên',16),
  ('bong-ban','doi-nu','Bảng B',17,'Nguyễn Thị Bạch Mai / Phan Thị Mai-VSP','VSP','Nguyễn Thị Bạch Mai','Phan Thị Mai',16),
  ('bong-ban','doi-nam-nu-31-40','Bảng A',19,'Phạm Phi Bảo / Tạ Ngọc Trâm-PVG','PVG','Phạm Phi Bảo','Tạ Ngọc Trâm',17),
  ('bong-ban','doi-nam-nu-31-40','Bảng A',19,'Nguyễn Trung Dũng / Vũ Thị Thúy Mơ-PCFCCo','PCFCCo','Nguyễn Trung Dũng','Vũ Thị Thúy Mơ',17),
  ('bong-ban','doi-nam-nu-31-40','Bảng A',19,'Mai Thùy Trang / Phạm Việt Hùng-PTSC','PTSC','Mai Thùy Trang','Phạm Việt Hùng',17),
  ('bong-ban','doi-nam-nu-31-40','Bảng A',19,'Đồng Văn Hoàng / Lương Thị Anh Cúc-VSP','VSP','Đồng Văn Hoàng','Lương Thị Anh Cúc',17),
  ('bong-ban','doi-nam-nu-31-40','Bảng B',20,'Nguyễn Ngọc Minh / Trần Thị Tuyết Mai-VSP','VSP','Nguyễn Ngọc Minh','Trần Thị Tuyết Mai',17),
  ('bong-ban','doi-nam-nu-31-40','Bảng B',20,'Phạm Ngọc Điều / Phan Thị Hải Phương-VSP','VSP','Phạm Ngọc Điều','Phan Thị Hải Phương',17),
  ('bong-ban','doi-nam-nu-31-40','Bảng B',20,'Lã Gia Quý / Trần Thảo Nguyên-PVFCCo','PVFCCo','Lã Gia Quý','Trần Thảo Nguyên',17),
  ('bong-ban','doi-nam-nu-31-40','Bảng B',20,'Huỳnh Thị Thanh Lan / Nguyễn Xuân LượngPVFCCo',null,null,null,18),
  ('bong-ban','doi-nam-nu-31-40','Bảng B',20,'Nguyễn Ngọc Minh / Trần Thị Tuyết Mai-VSP','VSP','Nguyễn Ngọc Minh','Trần Thị Tuyết Mai',18),
  ('bong-ban','doi-nam-nu-31-40','Bảng B',20,'Phạm Ngọc Điều / Phan Thị Hải Phương-VSP','VSP','Phạm Ngọc Điều','Phan Thị Hải Phương',18),
  ('bong-ban','doi-nam-nu-31-40','Bảng B',20,'Lã Gia Quý / Trần Thảo Nguyên-PVFCCo','PVFCCo','Lã Gia Quý','Trần Thảo Nguyên',18),
  ('bong-ban','doi-nam-nu-41-50','Bảng A',22,'Lê Thị Nga / Nguyễn Thanh PhươngPVFCCo',null,null,null,19),
  ('bong-ban','doi-nam-nu-41-50','Bảng A',22,'Huỳnh Thị Sim / Nguyễn Văn Thành-PVD','PVD','Huỳnh Thị Sim','Nguyễn Văn Thành',19),
  ('bong-ban','doi-nam-nu-41-50','Bảng A',22,'Nguyễn Thị Liên / Nguyễn Trung Kiên-VSP','VSP','Nguyễn Thị Liên','Nguyễn Trung Kiên',19),
  ('bong-ban','doi-nam-nu-41-50','Bảng A',22,'Bùi Sơn Hải / Lương Thùy Dương-VSP','VSP','Bùi Sơn Hải','Lương Thùy Dương',19),
  ('bong-ban','doi-nam-nu-41-50','Bảng B',23,'Nguyễn Thị Thu Trang / Vũ Duy Hải-PVFCCo','PVFCCo','Nguyễn Thị Thu Trang','Vũ Duy Hải',19),
  ('bong-ban','doi-nam-nu-41-50','Bảng B',23,'Đặng Thị Quyên / Lê Văn Thông-VSP','VSP','Đặng Thị Quyên','Lê Văn Thông',19),
  ('bong-ban','doi-nam-nu-41-50','Bảng B',23,'Ngô Thị Liên / Phạm Hồng Quang-NCKH','NCKH','Ngô Thị Liên','Phạm Hồng Quang',19),
  ('bong-ban','doi-nam-nu-41-50','Bảng B',23,'Dương Thị Ngọc Lan / Hồ Đức Minh-PTSC','PTSC','Dương Thị Ngọc Lan','Hồ Đức Minh',19),
  ('bong-ban','doi-nam-nu-41-50','Bảng B',23,'Nguyễn Thị Vinh / Trần Thế Long-VSP','VSP','Nguyễn Thị Vinh','Trần Thế Long',19),
  ('bong-ban','doi-nam-nu-41-50','Danh sách',24,'Nguyễn Thị Thu Trang / Vũ Duy Hải-PVFCCo','PVFCCo','Nguyễn Thị Thu Trang','Vũ Duy Hải',20),
  ('bong-ban','doi-nam-nu-41-50','Danh sách',24,'Nguyễn Thị Vinh / Trần Thế Long-VSP','VSP','Nguyễn Thị Vinh','Trần Thế Long',20),
  ('bong-ban','doi-nam-nu-41-50','Danh sách',24,'Đặng Thị Quyên / Lê Văn Thông-VSP','VSP','Đặng Thị Quyên','Lê Văn Thông',20),
  ('bong-ban','doi-nam-nu-41-50','Danh sách',24,'Dương Thị Ngọc Lan / Hồ Đức Minh-PTSC','PTSC','Dương Thị Ngọc Lan','Hồ Đức Minh',20),
  ('bong-ban','doi-nam-nu-41-50','Danh sách',24,'Ngô Thị Liên / Phạm Hồng Quang-NCKH','NCKH','Ngô Thị Liên','Phạm Hồng Quang',20),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Đặng Vũ Khởi / Hồ Tuấn Anh-BMĐH','BMĐH','Đặng Vũ Khởi','Hồ Tuấn Anh',2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Đoàn Văn Đặng / Nguyễn Hoàng Nam-PVCOM','PVCOM','Đoàn Văn Đặng','Nguyễn Hoàng Nam',2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Bùi Thái Sơn / Lê Tuấn Anh-VSP','VSP','Bùi Thái Sơn','Lê Tuấn Anh',2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Lê Nguyễn Hoàng Dương / Vũ Khoa Huân-PVI','PVI','Lê Nguyễn Hoàng Dương','Vũ Khoa Huân',2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Đào Quốc Dũng / Võ Văn Thịnh-PVG','PVG','Đào Quốc Dũng','Võ Văn Thịnh',2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Dương Trí Quả / Trịnh Văn Thành',null,null,null,2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Lê Minh Đức / Nguyễn Khánh Phong-PVOIL','PVOIL','Lê Minh Đức','Nguyễn Khánh Phong',2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Đỗ Đức Thọ / Nguyễn Việt Thắng-PVD','PVD','Đỗ Đức Thọ','Nguyễn Việt Thắng',2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Chung Bảo Hiếu / Lê Tiến Bảo-PVFCCo','PVFCCo','Chung Bảo Hiếu','Lê Tiến Bảo',2),
  ('cau-long','doi-nam-31-40','Danh sách',2,'Nguyễn Minh Hoàng / Nguyễn Văn Hiếu-PQPOC','PQPOC','Nguyễn Minh Hoàng','Nguyễn Văn Hiếu',2),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Bùi Hoàng Đức / Nguyễn Hiếu Trung',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Dương Hữu Chính / Lương Thế Vinh',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Ng Thanh Điền / Nguyễn Võ Xuân Huy',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Hoàng Minh Trí / Nguyễn Thế Anh',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Mai Thế Thắng / Nguyễn Hồ Anh Sơn',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Nguyễn Minh Tuấn / Phạm Văn Định',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Nguyễn Anh Dũng / Phạm Ngọc Hải',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Phạm Hồng Thái / Trần Đức Thuận',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Nguyễn Bá Phong / Trần Đức Minh',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Đỗ Tam Quốc / Hồ Vũ Hùng',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Nguyễn Đức Mẫn / Nguyễn Minh Đạt',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Mai Văn Tiến Thức / Vũ Đức Anh',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Đào Quốc Anh / Hồ Nguyễn Thành Trung',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Trần Hải Đăng / Trần Hoàng Chương',null,null,null,3),
  ('cau-long','doi-nam-duoi-30','Danh sách',3,'Nguyễn Xuân Cương / Trần Đăng Kết',null,null,null,3),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Bùi Anh Võ / Hồ Ngọc Hưng',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Đào Công Thiện / Trần Xuân Ngọc',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Nguyễn Chí Trung / Nguyễn Văn Mười',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Ngô Thế Quỳnh / Nguyễn Đăng Khoa',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Nguyễn Đình Phong / Nguyễn Ngọc Ánh',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Nguyễn Trung Hải / Tất Phi Hải',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Đỗ Văn Toàn / Trần Quốc Huy',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Đặng Đình Bình / Nguyễn Hải Long',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Hồ Viết Tập / Phạm Tất Lộc',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Phạm Văn Hiệu / Vũ Văn Dũng',null,null,null,4),
  ('cau-long','doi-nam-41-50','Danh sách',4,'Hoàng Quang Chính / Ng Công Anh Anh',null,null,null,4),
  ('cau-long','doi-nam-tren-51','Bảng 5',5,'Đỗ Đức Đồng / Phạm Trung Hiếu',null,null,null,5),
  ('cau-long','doi-nam-tren-51','Bảng 5',5,'Đoàn Anh Sơn/Đỗ Ngọc / Giang',null,null,null,5),
  ('cau-long','doi-nam-tren-51','Bảng 5',5,'Nguyễn Văn Truyền / Trần Hoàng Thái',null,null,null,5),
  ('cau-long','doi-nam-tren-51','Bảng 5',5,'Nguyễn Tường / Phạm Trí Dũng',null,null,null,5),
  ('cau-long','doi-nam-tren-51','Bảng 5',5,'Dương Trung Chương / Vũ Xuân Cường',null,null,null,5),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Nguyễn Thị Tuyết / Nguyễn Trung Hiếu',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Hoàng Minh Hiếu / Võ Châu Yên',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Nguyễn Duy Đông / Trịnh Thị Minh Anh',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Nguyễn Hoàng Anh Thư / Trịnh Quang Huy',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Đoàn Việt Bách / Nguyễn Thị Ngọc Duyên',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Bùi Minh Thảo / Ngô Ngọc Mỹ Duyên',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Lê Thành Công / Trịnh Ngọc Dung',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Nguyễn Trung Thanh Thảo / Phạm Tiến Dũng',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Đào Thị Mùa Thu / Ngọc Vũ Nhiệm',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Huỳnh Thu Hiền / Phạm Khắc Đạt',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Hà Thị Thanh Hương / Trần Quốc Hòa',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Ngn Huỳnh Hưng Thịnh / Nguyễn Thị Như Hải',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Nguyễn Văn Thành Vinh / Phan Thanh Trúc',null,null,null,6),
  ('cau-long','doi-nam-nu-duoi-30','Danh sách',6,'Nguyễn Thành Thịnh / Tăng Thụy Thanh Phương',null,null,null,6),
  ('cau-long','doi-nam-nu-31-40','Bảng A',7,'Phạm Văn Khang / Trần Thị Thu Mai-VSP','VSP','Phạm Văn Khang','Trần Thị Thu Mai',7),
  ('cau-long','doi-nam-nu-31-40','Bảng A',7,'Phan Xuân Hưng / Vũ Thị Hoài Thu-PVG','PVG','Phan Xuân Hưng','Vũ Thị Hoài Thu',7),
  ('cau-long','doi-nam-nu-31-40','Bảng A',7,'Biện Văn Tráng / Lê Thị Việt Phương-NCKH','NCKH','Biện Văn Tráng','Lê Thị Việt Phương',7),
  ('cau-long','doi-nam-nu-31-40','Bảng A',7,'Lê Hoài Anh / Nguyễn Thành Anh Duy',null,null,null,7),
  ('cau-long','doi-nam-nu-31-40','Bảng B',8,'Nguyễn Nhật Vũ / Phạm Thị Ánh Tuyết-PVG','PVG','Nguyễn Nhật Vũ','Phạm Thị Ánh Tuyết',7),
  ('cau-long','doi-nam-nu-31-40','Bảng B',8,'Nguyễn Thị Anh / Trần Ngọc Khanh-VSP','VSP','Nguyễn Thị Anh','Trần Ngọc Khanh',7),
  ('cau-long','doi-nam-nu-31-40','Bảng B',8,'Mai Thị Thu Huyền / Trần Tuấn Thành-PVCHEM','PVCHEM','Mai Thị Thu Huyền','Trần Tuấn Thành',7),
  ('cau-long','doi-nam-nu-31-40','Bảng B',8,'Lê Thị Nguyệt Nga / Vũ Việt Văn-PVCFC','PVCFC','Lê Thị Nguyệt Nga','Vũ Việt Văn',7),
  ('cau-long','doi-nam-nu-31-40','Danh sách',9,'Nguyễn Nhật Vũ / Phạm Thị Ánh Tuyết-PVG','PVG','Nguyễn Nhật Vũ','Phạm Thị Ánh Tuyết',8),
  ('cau-long','doi-nam-nu-31-40','Danh sách',9,'Lê Thị Nguyệt Nga / Vũ Việt Văn-PVCFC','PVCFC','Lê Thị Nguyệt Nga','Vũ Việt Văn',8),
  ('cau-long','doi-nam-nu-31-40','Danh sách',9,'Nguyễn Thị Anh / Trần Ngọc Khanh-VSP','VSP','Nguyễn Thị Anh','Trần Ngọc Khanh',8),
  ('cau-long','doi-nam-nu-31-40','Danh sách',9,'Mai Thị Thu Huyền / Trần Tuấn Thành-PVCHEM','PVCHEM','Mai Thị Thu Huyền','Trần Tuấn Thành',8),
  ('cau-long','doi-nam-nu-41-50','Bảng A',10,'Trần Bích Ngọc / Trần Xuân Lưu-PVD','PVD','Trần Bích Ngọc','Trần Xuân Lưu',9),
  ('cau-long','doi-nam-nu-41-50','Bảng A',10,'Hoàng Nhật Quang / Nguyễn Thị Hằng-VSP','VSP','Hoàng Nhật Quang','Nguyễn Thị Hằng',9),
  ('cau-long','doi-nam-nu-41-50','Bảng A',10,'Nguyễn Thị Thủy / Phạm Ngọc Thức-PVFCCo','PVFCCo','Nguyễn Thị Thủy','Phạm Ngọc Thức',9),
  ('cau-long','doi-nam-nu-41-50','Bảng A',10,'Nguyễn Phạm Quang / Ng Thị Kiều Anh-PVTRANS','PVTRANS','Nguyễn Phạm Quang','Ng Thị Kiều Anh',9),
  ('cau-long','doi-nam-nu-41-50','Bảng B',11,'Lương Hùng Triết / Thái Thị Ngân-VSP','VSP','Lương Hùng Triết','Thái Thị Ngân',9),
  ('cau-long','doi-nam-nu-41-50','Bảng B',11,'Đặng Hữu Huynh / Nguyễn Thị Thanh Xuân-PVG','PVG','Đặng Hữu Huynh','Nguyễn Thị Thanh Xuân',9),
  ('cau-long','doi-nam-nu-41-50','Bảng B',11,'Nguyễn Quốc Toản / Nguyễn Thị Hằng Nga-PVFCCo','PVFCCo','Nguyễn Quốc Toản','Nguyễn Thị Hằng Nga',9),
  ('cau-long','doi-nam-nu-41-50','Bảng B',11,'Đinh Quang Tuyến / Hồ Thị Thanh Bình-BMĐH','BMĐH','Đinh Quang Tuyến','Hồ Thị Thanh Bình',9),
  ('cau-long','doi-nu-duoi-30','Bảng 13',13,'Đoàn Ngọc Quỳnh Tiên / Phạm Thị Kiều Anh',null,null,null,11),
  ('cau-long','doi-nu-duoi-30','Bảng 13',13,'Nguyễn Thị Phương Anh / Vũ Thị Mỹ Hồng',null,null,null,11),
  ('cau-long','doi-nu-duoi-30','Bảng 13',13,'Phạm Anh Thư / Phạm Thị Chung',null,null,null,11),
  ('cau-long','doi-nu-duoi-30','Bảng 13',13,'Lê Ly An / Lê Thanh Hương',null,null,null,11),
  ('cau-long','doi-nu-duoi-30','Bảng 13',13,'Hoàng Thị Thanh Hương / Võ Thị Ngọc Loan',null,null,null,11),
  ('cau-long','doi-nu-31-40','Bảng A',14,'Lê Thị Huyền Trang / Võ Phan Lệ Thủy-PVG','PVG','Lê Thị Huyền Trang','Võ Phan Lệ Thủy',12),
  ('cau-long','doi-nu-31-40','Bảng A',14,'Ngô Thị Minh Huế / Nguyễn Thị Diệu Thuý-PVOIL','PVOIL','Ngô Thị Minh Huế','Nguyễn Thị Diệu Thuý',12),
  ('cau-long','doi-nu-31-40','Bảng A',14,'Trương Thị Hoàng Anh / Vũ Thu Hà-PVEP','PVEP','Trương Thị Hoàng Anh','Vũ Thu Hà',12),
  ('cau-long','doi-nu-31-40','Bảng B',15,'Phạm Thị Huyền Trang / Trần Thu Trang-PVOIL','PVOIL','Phạm Thị Huyền Trang','Trần Thu Trang',12),
  ('cau-long','doi-nu-31-40','Bảng B',15,'Lê Thảo Chi / Trần Thị Kim Hoa-PVG','PVG','Lê Thảo Chi','Trần Thị Kim Hoa',12),
  ('cau-long','doi-nu-31-40','Bảng B',15,'Đoàn Thị Mai Linh / Phạm Thị Kim Yến-PVMR','PVMR','Đoàn Thị Mai Linh','Phạm Thị Kim Yến',12);

insert into public.organizations (code, name_vi, name_en)
select distinct organization_code, organization_code, organization_code
from seed_pair_sports where organization_code is not null
on conflict (tenant_id, code) do update set archived_at = null;

insert into public.participants (organization_id, full_name)
select distinct on (o.id, private.entry_identity(names.full_name, 'individual')) o.id, names.full_name
from seed_pair_sports p join public.organizations o on o.code = p.organization_code
cross join lateral (values (p.member_one), (p.member_two)) names(full_name)
where names.full_name is not null
and not exists (select 1 from public.participants a where a.organization_id = o.id and private.entry_identity(a.full_name, 'individual') = private.entry_identity(names.full_name, 'individual'))
order by o.id, private.entry_identity(names.full_name, 'individual'), names.full_name;

insert into public.groups (tournament_id, name_vi, name_en, sort_order)
select t.id, p.group_name, replace(p.group_name, 'Bảng ', 'Group '), min(p.group_order)
from seed_pair_sports p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
where p.group_name <> 'Danh sách'
group by t.id, p.group_name
on conflict (tournament_id, name_vi) do update set archived_at = null;

insert into public.entries (tournament_id, organization_id, kind, name_vi, name_en)
select t.id, o.id, 'pair', p.pair_name, p.pair_name
from (select distinct sport_slug, tournament_slug, pair_name, organization_code from seed_pair_sports) p
join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
left join public.organizations o on o.code = p.organization_code
where not exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.pair_name);

insert into public.entry_members (entry_id, participant_id, sort_order)
select distinct e.id, a.id, names.sort_order
from seed_pair_sports p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
join public.entries e on e.tournament_id = t.id and e.name_vi = p.pair_name
join public.organizations o on o.code = p.organization_code
cross join lateral (values (p.member_one, 1), (p.member_two, 2)) names(full_name, sort_order)
join public.participants a on a.organization_id = o.id and a.full_name = names.full_name
where names.full_name is not null
on conflict (entry_id, participant_id) do update set archived_at = null;

insert into public.group_entries (group_id, entry_id)
select distinct g.id, e.id
from seed_pair_sports p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name
join public.entries e on e.tournament_id = t.id and e.name_vi = p.pair_name
where p.group_name <> 'Danh sách'
on conflict (group_id, entry_id) do update set archived_at = null;

create temporary table seed_pair_fixtures (
  sport_slug text, tournament_slug text, group_name text, home_name text, away_name text,
  sort_order integer, source_page integer
) on commit drop;
insert into seed_pair_fixtures values
  ('bong-ban','doi-nam-duoi-30','Bảng A','Nguyễn Hữu Mạnh / Nguyễn Văn Khai-PVG','Nguyễn Hữu Phương / Nguyễn Quang Trung-PVCFC',1,2),
  ('bong-ban','doi-nam-duoi-30','Bảng A','Chu Xuân Hải / Lê Hồng Thái-PVFCCo','Hoàng Phương Nam / Phạm Văn Đồng-VSP',2,2),
  ('bong-ban','doi-nam-duoi-30','Bảng A','Nguyễn Hữu Mạnh / Nguyễn Văn Khai-PVG','Hoàng Phương Nam / Phạm Văn Đồng-VSP',3,2),
  ('bong-ban','doi-nam-duoi-30','Bảng A','Âu Công Phúc / Vũ Việt Hoàng-PTSC','Nguyễn Hữu Phương / Nguyễn Quang Trung-PVCFC',4,2),
  ('bong-ban','doi-nam-duoi-30','Bảng A','Nguyễn Hữu Mạnh / Nguyễn Văn Khai-PVG','Chu Xuân Hải / Lê Hồng Thái-PVFCCo',5,2),
  ('bong-ban','doi-nam-duoi-30','Bảng A','Hoàng Phương Nam / Phạm Văn Đồng-VSP','Nguyễn Hữu Phương / Nguyễn Quang Trung-PVCFC',6,2),
  ('bong-ban','doi-nam-duoi-30','Bảng A','Chu Xuân Hải / Lê Hồng Thái-PVFCCo','Âu Công Phúc / Vũ Việt Hoàng-PTSC',7,2),
  ('bong-ban','doi-nam-duoi-30','Bảng A','Âu Công Phúc / Vũ Việt Hoàng-PTSC','Hoàng Phương Nam / Phạm Văn Đồng-VSP',8,2),
  ('bong-ban','doi-nam-duoi-30','Bảng A','Chu Xuân Hải / Lê Hồng Thái-PVFCCo','Nguyễn Hữu Phương / Nguyễn Quang Trung-PVCFC',9,2),
  ('bong-ban','doi-nam-31-40','Bảng A','Nguyễn Mạnh Hà / Võ Bá Anh Tuấn-PVD','Bùi Văn Thiện / Nguyễn Quốc Hưng-PVG',10,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Nguyễn Mạnh Tùng / Phạm Tú Anh-VSP','Nguyễn Vũ Chiến / Trần Tất Thắng-PVTRAS',11,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Nguyễn Mạnh Hà / Võ Bá Anh Tuấn-PVD','Nguyễn Vũ Chiến / Trần Tất Thắng-PVTRAS',12,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Trần Ngọc Sơn / Vũ Hải Long PVPMB','Bùi Văn Thiện / Nguyễn Quốc Hưng-PVG',13,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Nguyễn Mạnh Hà / Võ Bá Anh Tuấn-PVD','Nguyễn Mạnh Tùng / Phạm Tú Anh-VSP',14,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Nguyễn Vũ Chiến / Trần Tất Thắng-PVTRAS','Bùi Văn Thiện / Nguyễn Quốc Hưng-PVG',15,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Nguyễn Mạnh Tùng / Phạm Tú Anh-VSP','Trần Ngọc Sơn / Vũ Hải Long PVPMB',16,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Trần Ngọc Sơn / Vũ Hải Long PVPMB','Nguyễn Vũ Chiến / Trần Tất Thắng-PVTRAS',17,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Nguyễn Mạnh Hà / Võ Bá Anh Tuấn-PVD','Trần Ngọc Sơn / Vũ Hải Long PVPMB',18,5),
  ('bong-ban','doi-nam-31-40','Bảng A','Nguyễn Mạnh Tùng / Phạm Tú Anh-VSP','Bùi Văn Thiện / Nguyễn Quốc Hưng-PVG',19,5),
  ('bong-ban','doi-nam-41-50','Bảng A','Lèng Văn Chi / Trần Xuân Mạnh-PVEP','Nguyễn Ngọc Lân / Phan Quốc Thắng-PVD',20,8),
  ('bong-ban','doi-nam-41-50','Bảng A','Nguyễn Hải Sơn / Phạm Văn Bảy-VSP','Nguyễn Ngọc Lân / Phan Quốc Thắng-PVD',21,8),
  ('bong-ban','doi-nam-41-50','Bảng A','Lèng Văn Chi / Trần Xuân Mạnh-PVEP','Đinh Xuân Hiền / Nguyễn Minh Thắng-PVTRANS',22,8),
  ('bong-ban','doi-nam-41-50','Bảng A','Đinh Xuân Hiền / Nguyễn Minh Thắng-PVTRANS','Nguyễn Ngọc Lân / Phan Quốc Thắng-PVD',23,8),
  ('bong-ban','doi-nam-41-50','Bảng A','Lèng Văn Chi / Trần Xuân Mạnh-PVEP','Nguyễn Hải Sơn / Phạm Văn Bảy-VSP',24,8),
  ('bong-ban','doi-nam-41-50','Bảng C','Bùi Văn Dũng / Vũ Đình Chính - PVFCCo','Nguyễn Thành Nam / Nguyễn Tiến Dũng-VSP',25,10),
  ('bong-ban','doi-nam-41-50','Bảng C','Nguyễn Hà Hải / Nguyễn Văn Ánh-PTSC','Đặng Thiệu Ích / Nguyễn Đồng Hiệp-PVCFC',26,10),
  ('bong-ban','doi-nam-41-50','Bảng C','Bùi Văn Dũng / Vũ Đình Chính - PVFCCo','Đặng Thiệu Ích / Nguyễn Đồng Hiệp-PVCFC',27,10),
  ('bong-ban','doi-nam-41-50','Bảng C','Nguyễn Hà Hải / Nguyễn Văn Ánh-PTSC','Nguyễn Thành Nam / Nguyễn Tiến Dũng-VSP',28,10),
  ('bong-ban','doi-nam-41-50','Bảng C','Bùi Văn Dũng / Vũ Đình Chính - PVFCCo','Nguyễn Hà Hải / Nguyễn Văn Ánh-PTSC',29,10),
  ('bong-ban','doi-nam-41-50','Bảng C','Đặng Thiệu Ích / Nguyễn Đồng Hiệp-PVCFC','Nguyễn Thành Nam / Nguyễn Tiến Dũng-VSP',30,10),
  ('bong-ban','doi-nam-41-50','Bảng D','Đinh Chí Thanh / Nguyễn Ngọc Hòe-PVE','Bùi Công Tâm / Nguyễn Vũ Hiệp-PVG',31,10),
  ('bong-ban','doi-nam-41-50','Bảng D','Hoàng Quang Thịnh / Trần Quang Bình-VSP','Đinh Quang Vinh / Lê Văn ChoPVFCCo',32,10),
  ('bong-ban','doi-nam-41-50','Bảng D','Đinh Chí Thanh / Nguyễn Ngọc Hòe-PVE','Đinh Quang Vinh / Lê Văn ChoPVFCCo',33,10),
  ('bong-ban','doi-nam-41-50','Bảng D','Hoàng Quang Thịnh / Trần Quang Bình-VSP','Bùi Công Tâm / Nguyễn Vũ Hiệp-PVG',34,10),
  ('bong-ban','doi-nam-41-50','Bảng D','Đinh Chí Thanh / Nguyễn Ngọc Hòe-PVE','Hoàng Quang Thịnh / Trần Quang Bình-VSP',35,11),
  ('bong-ban','doi-nam-41-50','Bảng D','Đinh Quang Vinh / Lê Văn ChoPVFCCo','Bùi Công Tâm / Nguyễn Vũ Hiệp-PVG',36,11),
  ('bong-ban','doi-nam-41-50','Bảng E','Đào Phú Hoàng / Đào Xuân Thu-PVG','Phạm Thành Trung / Vũ Anh Hữu',25,11),
  ('bong-ban','doi-nam-41-50','Bảng E','Nguyễn Hữu Tùng / Trần Đức Ninh-BMĐH','Doàn Quốc Quân / Vũ Tiến Dũng-PVFCCo',26,11),
  ('bong-ban','doi-nam-41-50','Bảng E','Đào Phú Hoàng / Đào Xuân Thu-PVG','Doàn Quốc Quân / Vũ Tiến Dũng-PVFCCo',27,11),
  ('bong-ban','doi-nam-41-50','Bảng E','Nguyễn Hữu Tùng / Trần Đức Ninh-BMĐH','Phạm Thành Trung / Vũ Anh Hữu',28,11),
  ('bong-ban','doi-nam-41-50','Bảng E','Đào Phú Hoàng / Đào Xuân Thu-PVG','Nguyễn Hữu Tùng / Trần Đức Ninh-BMĐH',29,11),
  ('bong-ban','doi-nam-41-50','Bảng E','Doàn Quốc Quân / Vũ Tiến Dũng-PVFCCo','Phạm Thành Trung / Vũ Anh Hữu',30,11),
  ('bong-ban','doi-nam-41-50','Bảng F','Nguyễn Tấn Nam Phương / Phù Quang Thạch-PVTRANS','Đào Quang Thành / Hoàng Văn Tuấn-BĐPOC',37,12),
  ('bong-ban','doi-nam-41-50','Bảng F','Dương Minh Bảo Phác / Đặng Văn Sơn-PVEP','Nguyễn Văn Hiếu / Vũ Văn Sỹ-VSP',38,12),
  ('bong-ban','doi-nam-41-50','Bảng F','Nguyễn Tấn Nam Phương / Phù Quang Thạch-PVTRANS','Nguyễn Văn Hiếu / Vũ Văn Sỹ-VSP',39,12),
  ('bong-ban','doi-nam-41-50','Bảng F','Dương Minh Bảo Phác / Đặng Văn Sơn-PVEP','Đào Quang Thành / Hoàng Văn Tuấn-BĐPOC',40,12),
  ('bong-ban','doi-nam-41-50','Bảng F','Nguyễn Tấn Nam Phương / Phù Quang Thạch-PVTRANS','Dương Minh Bảo Phác / Đặng Văn Sơn-PVEP',41,12),
  ('bong-ban','doi-nam-41-50','Bảng F','Nguyễn Văn Hiếu / Vũ Văn Sỹ-VSP','Đào Quang Thành / Hoàng Văn Tuấn-BĐPOC',42,12),
  ('bong-ban','doi-nu','Bảng A','Lê Thanh Nga / Phạm Thuý Anh-VSP','Đinh Thị Lan Anh / Nguyễn Thị Ninh-VSP',37,15),
  ('bong-ban','doi-nu','Bảng A','Lê Thanh Nga / Phạm Thuý Anh-VSP','Nguyễn Thị Thúy Hằng / Phạm Thị Lương-PVG',38,15),
  ('bong-ban','doi-nu','Bảng A','Đào Thị Thanh Huyền / Đào Thị Thúy Hằng-VSP','Đinh Thị Lan Anh / Nguyễn Thị Ninh-VSP',39,15),
  ('bong-ban','doi-nu','Bảng A','Nguyễn Thị Thúy Hằng / Phạm Thị Lương-PVG','Đào Thị Thanh Huyền / Đào Thị Thúy Hằng-VSP',40,15),
  ('bong-ban','doi-nam-nu-31-40','Bảng A','Phạm Phi Bảo / Tạ Ngọc Trâm-PVG','Đồng Văn Hoàng / Lương Thị Anh Cúc-VSP',41,17),
  ('bong-ban','doi-nam-nu-31-40','Bảng A','Phạm Phi Bảo / Tạ Ngọc Trâm-PVG','Mai Thùy Trang / Phạm Việt Hùng-PTSC',42,17),
  ('bong-ban','doi-nam-nu-31-40','Bảng A','Nguyễn Trung Dũng / Vũ Thị Thúy Mơ-PCFCCo','Đồng Văn Hoàng / Lương Thị Anh Cúc-VSP',43,17),
  ('bong-ban','doi-nam-nu-31-40','Bảng A','Mai Thùy Trang / Phạm Việt Hùng-PTSC','Nguyễn Trung Dũng / Vũ Thị Thúy Mơ-PCFCCo',44,17),
  ('bong-ban','doi-nam-nu-41-50','Bảng A','Lê Thị Nga / Nguyễn Thanh PhươngPVFCCo','Bùi Sơn Hải / Lương Thùy Dương-VSP',45,19),
  ('bong-ban','doi-nam-nu-41-50','Bảng A','Lê Thị Nga / Nguyễn Thanh PhươngPVFCCo','Nguyễn Thị Liên / Nguyễn Trung Kiên-VSP',46,19),
  ('bong-ban','doi-nam-nu-41-50','Bảng A','Huỳnh Thị Sim / Nguyễn Văn Thành-PVD','Bùi Sơn Hải / Lương Thùy Dương-VSP',47,19),
  ('bong-ban','doi-nam-nu-41-50','Bảng A','Nguyễn Thị Liên / Nguyễn Trung Kiên-VSP','Huỳnh Thị Sim / Nguyễn Văn Thành-PVD',48,19),
  ('cau-long','doi-nam-nu-31-40','Bảng A','Phạm Văn Khang / Trần Thị Thu Mai-VSP','Lê Hoài Anh / Nguyễn Thành Anh Duy',1,7),
  ('cau-long','doi-nam-nu-31-40','Bảng A','Phạm Văn Khang / Trần Thị Thu Mai-VSP','Biện Văn Tráng / Lê Thị Việt Phương-NCKH',2,7),
  ('cau-long','doi-nam-nu-31-40','Bảng A','Phạm Văn Khang / Trần Thị Thu Mai-VSP','Phan Xuân Hưng / Vũ Thị Hoài Thu-PVG',3,7),
  ('cau-long','doi-nam-nu-31-40','Bảng A','Biện Văn Tráng / Lê Thị Việt Phương-NCKH','Phan Xuân Hưng / Vũ Thị Hoài Thu-PVG',4,7),
  ('cau-long','doi-nam-nu-41-50','Bảng A','Trần Bích Ngọc / Trần Xuân Lưu-PVD','Nguyễn Phạm Quang / Ng Thị Kiều Anh-PVTRANS',5,9),
  ('cau-long','doi-nam-nu-41-50','Bảng A','Trần Bích Ngọc / Trần Xuân Lưu-PVD','Nguyễn Thị Thủy / Phạm Ngọc Thức-PVFCCo',6,9),
  ('cau-long','doi-nam-nu-41-50','Bảng A','Nguyễn Phạm Quang / Ng Thị Kiều Anh-PVTRANS','Hoàng Nhật Quang / Nguyễn Thị Hằng-VSP',7,9),
  ('cau-long','doi-nam-nu-41-50','Bảng A','Nguyễn Thị Thủy / Phạm Ngọc Thức-PVFCCo','Hoàng Nhật Quang / Nguyễn Thị Hằng-VSP',8,9),
  ('cau-long','doi-nu-31-40','Bảng A','Lê Thị Huyền Trang / Võ Phan Lệ Thủy-PVG','Trương Thị Hoàng Anh / Vũ Thu Hà-PVEP',9,12),
  ('cau-long','doi-nu-31-40','Bảng A','Ngô Thị Minh Huế / Nguyễn Thị Diệu Thuý-PVOIL','Trương Thị Hoàng Anh / Vũ Thu Hà-PVEP',10,12),
  ('cau-long','doi-nu-31-40','Bảng A','Lê Thị Huyền Trang / Võ Phan Lệ Thủy-PVG','Ngô Thị Minh Huế / Nguyễn Thị Diệu Thuý-PVOIL',11,12),
  ('cau-long','doi-nu-31-40','Bảng B','Phạm Thị Huyền Trang / Trần Thu Trang-PVOIL','Đoàn Thị Mai Linh / Phạm Thị Kim Yến-PVMR',12,12),
  ('cau-long','doi-nu-31-40','Bảng B','Lê Thảo Chi / Trần Thị Kim Hoa-PVG','Đoàn Thị Mai Linh / Phạm Thị Kim Yến-PVMR',13,12),
  ('cau-long','doi-nu-31-40','Bảng B','Phạm Thị Huyền Trang / Trần Thu Trang-PVOIL','Lê Thảo Chi / Trần Thị Kim Hoa-PVG',14,12);

insert into public.fixtures (tournament_id, group_id, status, round_vi, round_en, round_order)
select t.id, g.id, 'scheduled', 'Vòng bảng', 'Group stage', p.sort_order
from seed_pair_fixtures p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name
where exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.home_name)
and exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = p.away_name)
and not exists (select 1 from public.fixtures f where f.tournament_id = t.id and f.group_id = g.id and f.round_order = p.sort_order);

insert into public.fixture_entries (fixture_id, entry_id, side)
select distinct f.id, e.id, x.side
from seed_pair_fixtures p join public.sports s on s.slug = p.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = p.tournament_slug
join public.groups g on g.tournament_id = t.id and g.name_vi = p.group_name
join public.fixtures f on f.tournament_id = t.id and f.group_id = g.id and f.round_order = p.sort_order
cross join lateral (values (p.home_name, 'home'), (p.away_name, 'away')) x(pair_name, side)
join public.entries e on e.tournament_id = t.id and e.name_vi = x.pair_name
on conflict (fixture_id, entry_id) do update set archived_at = null;
