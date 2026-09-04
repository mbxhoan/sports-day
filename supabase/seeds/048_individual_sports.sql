set app.tenant_slug = 'petrovietnam2026';

create temporary table seed_individual_sports (
  sport_slug text, tournament_slug text, starts_at timestamptz, source_page integer,
  kind text, entry_name text, organization_code text, member_names text
) on commit drop;
insert into seed_individual_sports values
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07',2,'individual','Nguyễn Thị Ngọc Anh','VSP','Nguyễn Thị Ngọc Anh'),
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07',2,'individual','Đinh Thị Hà Phương','PTSC','Đinh Thị Hà Phương'),
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07',2,'individual','Phan Lê Na','SWPOC','Phan Lê Na'),
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07',2,'individual','Đặng Thị Hoàng Yến','LP1PP','Đặng Thị Hoàng Yến'),
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07',2,'individual','Trương Thị Ngọc Thịnh','PV GAS','Trương Thị Ngọc Thịnh'),
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07',2,'individual','Đào Thị Quỳnh Thoa','PVOIL','Đào Thị Quỳnh Thoa'),
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07',2,'individual','Nguyễn Thị Thùy','VSP','Nguyễn Thị Thùy'),
  ('boi-loi','100m-nu','2026-09-05 08:45:00+07',2,'individual','Đào Thị Hương Thủy','VSP','Đào Thị Hương Thủy'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Ngô Minh Chí Bảo','PVTRANS','Ngô Minh Chí Bảo'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Trịnh Xuân Cảnh','PTSC','Trịnh Xuân Cảnh'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Nguyễn Trường Giang','VSP','Nguyễn Trường Giang'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Nguyễn Quách Thanh Nam','PVCFC','Nguyễn Quách Thanh Nam'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Tokio DOSHITA','PVEP','Tokio DOSHITA'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Bùi Tuấn Minh','PVPMB','Bùi Tuấn Minh'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Bùi Cảnh Hưng','PVTRANS','Bùi Cảnh Hưng'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Nguyễn Mai Nam','PTSC','Nguyễn Mai Nam'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Vũ Hoàng Phúc','PVTRANS','Vũ Hoàng Phúc'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Điêu Lâm Thành','VSP','Điêu Lâm Thành'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Phạm Minh Tài','PV GAS','Phạm Minh Tài'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Đặng Trọng Dũng','VSP','Đặng Trọng Dũng'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Hồ Tấn Đạt','PV GAS','Hồ Tấn Đạt'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Trịnh Hữu Chung','VSP','Trịnh Hữu Chung'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Huỳnh Tấn Giang','PVOIL','Huỳnh Tấn Giang'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Bùi Sĩ Hồi','PTSC','Bùi Sĩ Hồi'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Ngô Cửu Long','VSP','Ngô Cửu Long'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Hoàng Nghĩa Ngọc','PVE','Hoàng Nghĩa Ngọc'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Trần Linh Vương','VSP','Trần Linh Vương'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Nguyễn Hoàng Tân','PETROSETCO','Nguyễn Hoàng Tân'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Nguyễn Duy Sơn','PVCFC','Nguyễn Duy Sơn'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Lê Minh Quyết','VSP','Lê Minh Quyết'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Trần Ngọc Minh','PVCFC','Trần Ngọc Minh'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',3,'individual','Nobuhiko MAKI','PVEP','Nobuhiko MAKI'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Lê Tiến Dũng','BMĐH','Lê Tiến Dũng'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Nguyễn Dương Bình','PVEP','Nguyễn Dương Bình'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Nguyễn Vân Nam','PV GAS','Nguyễn Vân Nam'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Phạm Văn Em','PVCFC','Phạm Văn Em'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Ngô Thế Lạc','PVMR','Ngô Thế Lạc'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Vũ Hoàng Lập','VSP','Vũ Hoàng Lập'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Lê Ngọc Linh','PV GAS','Lê Ngọc Linh'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Lê Tiến Trung','PV DRILLING','Lê Tiến Trung'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Vũ Trung Kiên','PTSC','Vũ Trung Kiên'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Hoàng Duy Thu','PV GAS','Hoàng Duy Thu'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Hà Thiếu Sang','PVMR','Hà Thiếu Sang'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Trần Văn Toàn','VSP','Trần Văn Toàn'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Nguyễn Công Khiên','PTSC','Nguyễn Công Khiên'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Nguyễn Văn Phong','BĐPOC','Nguyễn Văn Phong'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Phạm Ngọc Tuân','PV GAS','Phạm Ngọc Tuân'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Trần Song Hào','PV GAS','Trần Song Hào'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Nguyễn Như Thức','PVOIL','Nguyễn Như Thức'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Lê Huy','PVTRANS','Lê Huy'),
  ('boi-loi','50m-nam','2026-09-05 08:00:00+07',4,'individual','Đặng Trọng Thông','VSP','Đặng Trọng Thông'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Đặng Trần Anh Tuấn','PTSC','Đặng Trần Anh Tuấn'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Masakazu KAGANOI','PVEP','Masakazu KAGANOI'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Nguyễn Anh Tuấn','VSP','Nguyễn Anh Tuấn'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Trần Quốc Toản','PVCFC','Trần Quốc Toản'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Lý Gia Thành','PVE','Lý Gia Thành'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Tăng Hoàng Nhân','PTSC','Tăng Hoàng Nhân'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Shumpei YONETSU','PVEP','Shumpei YONETSU'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Nguyễn Phú Nam','PVPMB','Nguyễn Phú Nam'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Lê Minh Hoàng','VSP','Lê Minh Hoàng'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Trần Xuân Chánh','PTSC','Trần Xuân Chánh'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Trần Công Bằng','PV GAS','Trần Công Bằng'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Trần Văn Cường','PVTRANS','Trần Văn Cường'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Trương Trần Trung Tín','PVTRANS','Trương Trần Trung Tín'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Alexey','VSP','Alexey'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Phạm Ngọc Anh','PVEP','Phạm Ngọc Anh'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Phạm Hồng Minh','PV DRILLING','Phạm Hồng Minh'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Vũ Việt Bình','VSP','Vũ Việt Bình'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Lê Trọng Hiếu','PV DRILLING','Lê Trọng Hiếu'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Đỗ Công Hữu','PVCFC','Đỗ Công Hữu'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Nguyễn Văn Lếm','VSP','Nguyễn Văn Lếm'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Huỳnh Lương Sánh','PQPOC','Huỳnh Lương Sánh'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Fumitoshi SATO','PVEP','Fumitoshi SATO'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Shamil','VSP','Shamil'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Nguyễn Quang Trung','PVOIL','Nguyễn Quang Trung'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Ngô Minh Phú','PVCHEM','Ngô Minh Phú'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Lâm Tất Thắng','VSP','Lâm Tất Thắng'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Nguyễn Tiến Trình','PV GAS','Nguyễn Tiến Trình'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Phạm Văn Thuận','PVOIL','Phạm Văn Thuận'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Nguyễn Hồng Phúc','PV DRILLING','Nguyễn Hồng Phúc'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',5,'individual','Bùi Trung Kiên','PVTRANS','Bùi Trung Kiên'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Trần Ngọc Thùy Dương','BMĐH','Trần Ngọc Thùy Dương'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Đỗ Hồ Minh Phương','PETROSETCO','Đỗ Hồ Minh Phương'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Lữ Thị Nhung','PTSC','Lữ Thị Nhung'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Phương Thị Huyền','VSP','Phương Thị Huyền'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Nguyễn Thị Lý','PVCFC','Nguyễn Thị Lý'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Nguyễn Thị Thanh Thanh','PVCOMBANK','Nguyễn Thị Thanh Thanh'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Trần Thị Quỳnh Vân','PVEP','Trần Thị Quỳnh Vân'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Nguyễn Thị Ngọc Lan','PVOIL','Nguyễn Thị Ngọc Lan'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Lê Thị Phượng Uyển','PVTRANS','Lê Thị Phượng Uyển'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Nguyễn Thị Thanh Nhã','PTSC','Nguyễn Thị Thanh Nhã'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Châu Pha Diễm','VSP','Châu Pha Diễm'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Nguyễn Minh Nguyệt','PV DRILLING','Nguyễn Minh Nguyệt'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Hà Thị Trang','PVCFC','Hà Thị Trang'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Trịnh Thị Thanh','PV GAS','Trịnh Thị Thanh'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Nguyễn Ái Thanh Đan','PVEP','Nguyễn Ái Thanh Đan'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Lê Thị Hằng','PVMR','Lê Thị Hằng'),
  ('boi-loi','100m-nam','2026-09-05 08:30:00+07',6,'individual','Nguyễn Thị Thùy Dung','PTSC','Nguyễn Thị Thùy Dung'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07',7,'team','PTSC 01','PTSC','Nguyễn Mai Nam
Nguyễn Thị Thanh Nhã
Nguyễn Thị Thùy Dung
Trịnh Xuân Cảnh'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07',7,'team','PTSC 02','PTSC','Đinh Thị Hà Phương
Lữ Thị Nhung
Nguyễn Công Khiên
Trần Xuân Chánh'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07',7,'team','PV GAS','PV GAS','Phạm Minh Tài
Trần Kim Trung
Trịnh Thị Thanh
Trương Thị Ngọc Thịnh'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07',7,'team','PVCFC','PVCFC','Đỗ Công Hữu
Hà Thị Trang
Nguyễn Thị Lý
Trần Quốc Toản'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07',7,'team','PVEP','PVEP','Fumitoshi SATO
Nguyễn Ái Thanh Đan
Nguyễn Dương Bình
Trần Thị Quỳnh Vân'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07',7,'team','PVOIL','PVOIL','Đào Thị Quỳnh Thoa
Huỳnh Tấn Giang
Nguyễn Quang Trung
Nguyễn Thị Ngọc Lan'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07',7,'team','VSP','VSP','Lê Minh Hoàng
Nguyễn Thị Ngọc Anh
Nguyễn Thị Thùy
Trần Văn Toàn'),
  ('boi-loi','4x50m-nam','2026-09-05 15:30:00+07',7,'team','BMĐH','BMĐH','Lê Tiến Dũng
Trần Ngọc Thùy Dương'),
  ('boi-loi','4x50m-nu','2026-09-05 15:30:00+07',8,'team','PTSC','PTSC','Bùi Sĩ Hồi
Đặng Trần Anh Tuấn
Tăng Hoàng Nhân
Vũ Trung Kiên'),
  ('boi-loi','4x50m-nu','2026-09-05 15:30:00+07',8,'team','PVG','PV GAS','Hồ Tấn Đạt
Lê Ngọc Linh
Nguyễn Vân Nam
Trần Công Bằng'),
  ('boi-loi','4x50m-nu','2026-09-05 15:30:00+07',8,'team','PVCFC','PVCFC','Nguyễn Duy Sơn
Nguyễn Quách Thanh Nam
Phạm Văn Em
Trần Ngọc Minh'),
  ('boi-loi','4x50m-nu','2026-09-05 15:30:00+07',8,'team','VSP01','VSP','Alexey
Đặng Trọng Thông
Nguyễn Anh Tuấn
Vũ Việt Bình'),
  ('boi-loi','4x50m-nu','2026-09-05 15:30:00+07',8,'team','VSP02','VSP','Điêu Lâm Thành
Lâm Tất Thắng
Shamil
Trần Linh Vương'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','BĐPOC','BĐPOC','Nguyễn Công Minh
Nguyễn Hoàng Anh
Nguyễn Hữu Tuệ
Nguyễn Văn Triệu'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','NCKHĐT - 01','NCKHĐT','Nguyễn Văn Sử
Phạm Hữu Tài
Phan Ngọc Quốc
Tạ Ngoc Thắng'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','Đội 2 - VSP','VSP','Nguyễn Văn Hưng
Phạm Văn Thao
Trịnh Thanh Hoàng
Võ Xuân Tuấn'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','NCKHĐT - 02','NCKHĐT','Lê Dương Hải
Lưu Đức Hà
Nguyễn Lâm Quốc Cường
Nguyễn Mạnh Hùng'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','PETROCONs','PETROCONs','Đào Ngọc Kết
Đặng Văn Dũng
Hoàng Như Chương
Lê Viết Hưng'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','PETROSETCO','PETROSETCO','Lê Văn Quyền
Nguyễn Minh Nhật
Phan Minh Tùng
Phan Văn Thịnh'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','PTSC','PTSC','Đinh Hồng Phong
Nguyễn Ngọc Lạp
Nguyễn Văn Bằng
Tô Mạnh Cường'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','PV Drilling','PV Drilling','Hoàng Đình Trúc
Lê Thanh Tiến
Nguyễn Anh Dũng
Nguyễn Hữu Tuấn'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','PV GAS 1','PV GAS','Đỗ Minh Xuân
Ngô Phương Bắc
Trần Việt Dũng
Vũ Mạnh Nhất'),
  ('dien-kinh','4x100m-nam','2026-09-06 07:00:00+07',2,'team','PV GAS 2','PV GAS','Lê Tiến Dũng
Ngô Văn Cường
Nguyễn Hữu Thức
Nguyễn Xuân Tùng'),
  ('dien-kinh','4x100m-nu','2026-09-06 07:00:00+07',4,'team','PVD','PVD','Nguyễn Thị Hồng Thúy
Nguyễn Thị Thìn
Vũ Thị Huệ
Vương Thị Hiền'),
  ('dien-kinh','4x100m-nu','2026-09-06 07:00:00+07',4,'team','PVG','PVG','Hoàng Thị Hà
Hoàng Thị Hoài
Nguyễn Mỹ Thanh
Trần Thị Nhiên'),
  ('dien-kinh','4x100m-nu','2026-09-06 07:00:00+07',4,'team','PVCOMBANK','PVCOMBANK','Bùi Thị Mỹ Châu
Hoàng Thị Dung
Lê Thị Thu Hiền
Ngô Thị Chiển'),
  ('dien-kinh','4x100m-nu','2026-09-06 07:00:00+07',4,'team','PVFCCo','PVFCCo','Lê Thị Ánh Tuyết
Nguyễn Thị Minh Hiền
Phan Thị Hồng Thắm
Trương Thị Thanh Toàn'),
  ('dien-kinh','4x100m-nu','2026-09-06 07:00:00+07',4,'team','VSP','VSP','Nguyễn Thị Liên
Nguyễn Thị Ngân Anh
Phạm Quỳnh Nga
Trần Thị Thành'),
  ('dien-kinh','400m-nu','2026-09-06 06:00:00+07',5,'individual','Nguyễn Thị Thúy','PETROSETCO','Nguyễn Thị Thúy'),
  ('dien-kinh','400m-nu','2026-09-06 06:00:00+07',5,'individual','Nguyễn Thị Liên','VSP','Nguyễn Thị Liên'),
  ('dien-kinh','400m-nu','2026-09-06 06:00:00+07',5,'individual','Vũ Thị Huệ','PV Drilling','Vũ Thị Huệ'),
  ('dien-kinh','400m-nu','2026-09-06 06:00:00+07',5,'individual','Hoàng Thị Hà','PV GAS','Hoàng Thị Hà'),
  ('dien-kinh','400m-nu','2026-09-06 06:00:00+07',5,'individual','Phạm Quỳnh Nga','VSP','Phạm Quỳnh Nga'),
  ('dien-kinh','400m-nu','2026-09-06 06:00:00+07',5,'individual','Nguyễn Thị Thanh Nhàn','VSP','Nguyễn Thị Thanh Nhàn'),
  ('dien-kinh','400m-nu','2026-09-06 06:00:00+07',5,'individual','Hoàng Thị Hoài','PV GAS','Hoàng Thị Hoài'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Anh Dũng','PV Drilling','Nguyễn Anh Dũng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Thành Chung','PVOIL','Nguyễn Thành Chung'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Trung Dũng','PVPMB','Nguyễn Trung Dũng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Lê Hùng Cường','VSP','Lê Hùng Cường'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Trần Văn Cường','PV GAS','Trần Văn Cường'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Đức Chính','PVCFC','Nguyễn Đức Chính'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Đậu Đăng Bút','NCKHĐT','Đậu Đăng Bút'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Ngô Văn Cường','PV GAS','Ngô Văn Cường'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Trần Hoàng','PVEP','Nguyễn Trần Hoàng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Mai Hoàng Hiệp','VSP','Mai Hoàng Hiệp'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Phạm Hoàng Nam','PVCFC','Phạm Hoàng Nam'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Ngọc Lạp','PTSC','Nguyễn Ngọc Lạp'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Văn Hưng','VSP','Nguyễn Văn Hưng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Phạm Hiếu Nhân','PVOIL','Phạm Hiếu Nhân'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Phan Văn Thịnh','PETROSETCO','Phan Văn Thịnh'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Văn Mạnh','VSP','Nguyễn Văn Mạnh'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Trần Văn Thắng','PVOIL','Trần Văn Thắng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Quốc Thắng','PVCHEM','Nguyễn Quốc Thắng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Trần Huy','VSP','Trần Huy'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Hoàng Văn Lâm','PVOIL','Hoàng Văn Lâm'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Trần Tuấn Trực','PV Drilling','Trần Tuấn Trực'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Võ Xuân Tuấn','VSP','Võ Xuân Tuấn'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Phan Sơn Tùng','LP1PP','Phan Sơn Tùng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Hoàng Đình Trúc','PV Drilling','Hoàng Đình Trúc'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Phạm Văn Thao','VSP','Phạm Văn Thao'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Văn Tiến','PVCHEM','Nguyễn Văn Tiến'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Đinh Hồng Phong','PTSC','Đinh Hồng Phong'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Phan Minh Tùng','PETROSETCO','Phan Minh Tùng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Xuân Phượng','VSP','Nguyễn Xuân Phượng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Vương Ngọc Trìu','PVCFC','Vương Ngọc Trìu'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',6,'individual','Nguyễn Hữu Tuấn','PV Drilling','Nguyễn Hữu Tuấn'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Lê Tiến Dũng','PV GAS','Lê Tiến Dũng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Vũ Kim Mạnh','PV Drilling','Vũ Kim Mạnh'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Nguyễn Viết Hùng','VSP','Nguyễn Viết Hùng'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Vũ Hoàng Tiến','PTSC','Vũ Hoàng Tiến'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Nguyễn Đình Thứ','VSP','Nguyễn Đình Thứ'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Nguyễn Văn Hải','PV GAS','Nguyễn Văn Hải'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Phạm Đức Hinh','PETROCONs','Phạm Đức Hinh'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Phạm Thành Trung','PTSC','Phạm Thành Trung'),
  ('dien-kinh','800m-nam','2026-09-06 06:00:00+07',7,'individual','Nguyễn Khắc Tuấn','PV Drilling','Nguyễn Khắc Tuấn'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Nguyễn Thị Ngân Anh','VSP','Nguyễn Thị Ngân Anh'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Bùi Thị Hậu','PVOIL','Bùi Thị Hậu'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Nguyễn Thị Hà','NCKHĐT','Nguyễn Thị Hà'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Nguyễn Thị Huệ','PV Drilling','Nguyễn Thị Huệ'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Nguyễn Thu Hiền','PVCHEM','Nguyễn Thu Hiền'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Vương Thị Hiền','PV Drilling','Vương Thị Hiền'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Phạm Thị Nụ','NCKHĐT','Phạm Thị Nụ'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Võ Thị Lý','PV GAS','Võ Thị Lý'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Phạm Thùy Linh','PVOIL','Phạm Thùy Linh'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Nguyễn Thị Minh Hiền','PVFCCo','Nguyễn Thị Minh Hiền'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Nguyễn Thị Thu Vân','NCKHĐT','Nguyễn Thị Thu Vân'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Đỗ Thị Phương Thảo','BĐPOC','Đỗ Thị Phương Thảo'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Trần Thị Thảo','NCKHĐT','Trần Thị Thảo'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Cao Thị Thanh Thúy','PVI HOLDINGS','Cao Thị Thanh Thúy'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Trần Phương Thúy','PVOIL','Trần Phương Thúy'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Nguyễn Thị Hồng Thúy','PV Drilling','Nguyễn Thị Hồng Thúy'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Đinh Nguyễn Phương Thanh','NCKHĐT','Đinh Nguyễn Phương Thanh'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Trần Thị Hồng Thu','PV GAS','Trần Thị Hồng Thu'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Nguyễn Thị Kim Trúc','NCKHĐT','Nguyễn Thị Kim Trúc'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Phan Thị Bích Tuyết','PVOIL','Phan Thị Bích Tuyết'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',8,'individual','Phan Thùy Trúc Quyên','PV Drilling','Phan Thùy Trúc Quyên'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Trần Thị Hoài An','PVOIL','Trần Thị Hoài An'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Bùi Hồng Diễm','NCKHĐT','Bùi Hồng Diễm'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Cao Thị Huế','VSP','Cao Thị Huế'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Nguyễn Thị Thúy Hiền','PETROSETCO','Nguyễn Thị Thúy Hiền'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Trần Thị Nhiên','PV GAS','Trần Thị Nhiên'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Quách Thị Hoa','PV Drilling','Quách Thị Hoa'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Bùi Thị Ngọc Phương','NCKHĐT','Bùi Thị Ngọc Phương'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Lê Thị Phượng','PVFCCo','Lê Thị Phượng'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Đỗ Thị Kim Thu','PV Drilling','Đỗ Thị Kim Thu'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Nguyễn Thị Anh Thư','NCKHĐT','Nguyễn Thị Anh Thư'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Trần Thị Thành','VSP','Trần Thị Thành'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Phạm Thi Trang Vân','NCKHĐT','Phạm Thi Trang Vân'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Chu Thị Hồng Vân','PVFCCo','Chu Thị Hồng Vân'),
  ('dien-kinh','3000m-nu','2026-09-06 15:00:00+07',9,'individual','Nguyễn Thị Thủy','PVEP','Nguyễn Thị Thủy'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Nguyễn Hoàng Anh','BĐPOC','Nguyễn Hoàng Anh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Phạm Đức Anh','PQPOC','Phạm Đức Anh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Phạm Ngọc Anh','PVEP','Phạm Ngọc Anh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Nguyễn Văn Bằng','PTSC','Nguyễn Văn Bằng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Nguyễn Lâm Quốc Cường','NCKHĐT','Nguyễn Lâm Quốc Cường'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Tô Mạnh Cường','PTSC','Tô Mạnh Cường'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Lê Quang Cường','PVFCCo','Lê Quang Cường'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Đàm Thành Công','PVOIL','Đàm Thành Công'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Vũ Văn Cường','PVOIL','Vũ Văn Cường'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Nguyễn Văn Chiến','PVEP','Nguyễn Văn Chiến'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Đậu Danh','PVOIL','Đậu Danh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Phạm Đình Danh','PVOIL','Phạm Đình Danh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Trương Văn Chất','NCKHĐT','Trương Văn Chất'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Đặng Văn Dũng','PETROCONs','Đặng Văn Dũng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Đinh Công Duyệt','PV Drilling','Đinh Công Duyệt'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Chử Văn Dũng','PV GAS','Chử Văn Dũng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Bùi Minh Dũng','PVCHEM','Bùi Minh Dũng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Bùi Xuân Điền','PVOIL','Bùi Xuân Điền'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Võ Duy Hoàng','PQPOC','Võ Duy Hoàng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Lê Văn Hiếu','PVFCCo','Lê Văn Hiếu'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Nguyễn Chế Linh','PV POWER','Nguyễn Chế Linh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Nguyễn Công Minh','BĐPOC','Nguyễn Công Minh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Phạm Hải Nam','PV POWER','Phạm Hải Nam'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Nguyễn Minh Nhật','PETROSETCO','Nguyễn Minh Nhật'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Vũ Mạnh Nhất','PV GAS','Vũ Mạnh Nhất'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Phan Thanh Nhân','PVCHEM','Phan Thanh Nhân'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',10,'individual','Đỗ Khắc Minh','PVEP','Đỗ Khắc Minh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Hoàng Như Chương','PETROCONs','Hoàng Như Chương'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Mai Nhân Dương','PV Drilling','Mai Nhân Dương'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Đoàn Trung Dũng','PVEP','Đoàn Trung Dũng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Võ Tấn Đạt','PVCFC','Võ Tấn Đạt'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Nguyễn Văn Diên','BMĐH PETROVIETNAM','Nguyễn Văn Diên'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','DƯƠNG TRƯỜNG GIANG','PQPOC','DƯƠNG TRƯỜNG GIANG'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Phạm Văn Hưng','PVOIL','Phạm Văn Hưng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Lê Viết Hưng','PETROCONs','Lê Viết Hưng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Lê Dương Hải','NCKHĐT','Lê Dương Hải'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Lưu Đức Hà','NCKHĐT','Lưu Đức Hà'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Nguyễn Bình Hợp','PV Drilling','Nguyễn Bình Hợp'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Tô Quang Hanh','PVPMB','Tô Quang Hanh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Đỗ Hữu Nguyên','VSP','Đỗ Hữu Nguyên'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Nguyễn Văn Tâm','PQPOC','Nguyễn Văn Tâm'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Phạm Văn Thật','PETROSETCO','Phạm Văn Thật'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Trần Xuân Thiên','VSP','Trần Xuân Thiên'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Nguyễn Quốc Tuyển','PV Drilling','Nguyễn Quốc Tuyển'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Nguyễn Hữu Thức','PV GAS','Nguyễn Hữu Thức'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Nguyễn Hoàng Long','PVOIL','Nguyễn Hoàng Long'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Lê Nhân Thịnh','PQPOC','Lê Nhân Thịnh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Tạ Ngoc Thắng','NCKHĐT','Tạ Ngoc Thắng'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Trần Văn Trung','PV POWER','Trần Văn Trung'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Giáp Văn Tỉnh','PV Drilling','Giáp Văn Tỉnh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Vũ Xuân Tĩnh','PETROCONs','Vũ Xuân Tĩnh'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Lê Công Thế','PV GAS','Lê Công Thế'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Võ Văn Ngọc','PVFCCo','Võ Văn Ngọc'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Trần Hữu Phong','PV Drilling','Trần Hữu Phong'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Nguyễn Đăng Khoa','PV Drilling','Nguyễn Đăng Khoa'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Đào Ngọc Kết','PETROCONs','Đào Ngọc Kết'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Mai Xuân Trí','PV GAS','Mai Xuân Trí'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Lê Văn Quyền','PETROSETCO','Lê Văn Quyền'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Hứa Viết Sơn','PVFCCo','Hứa Viết Sơn'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Trương Văn Quốc','PETROSETCO','Trương Văn Quốc'),
  ('dien-kinh','5000m-nam','2026-09-06 15:00:00+07',12,'individual','Lương Ngọc Phúc','PTSC','Lương Ngọc Phúc');

insert into public.organizations (code, name_vi, name_en)
select distinct organization_code, organization_code, organization_code from seed_individual_sports
on conflict (tenant_id, code) do update set archived_at = null;

insert into public.participants (organization_id, full_name)
select distinct on (o.id, private.entry_identity(names.full_name, 'individual')) o.id, names.full_name
from seed_individual_sports r join public.organizations o on o.code = r.organization_code
cross join lateral unnest(string_to_array(r.member_names, E'\n')) names(full_name)
where names.full_name is not null
and not exists (
  select 1 from public.participants p
  where p.organization_id = o.id
    and private.entry_identity(p.full_name, 'individual') = private.entry_identity(names.full_name, 'individual')
)
order by o.id, private.entry_identity(names.full_name, 'individual'), names.full_name;

insert into public.entries (tournament_id, organization_id, kind, name_vi, name_en)
select distinct on (t.id, r.kind, private.entry_identity(r.entry_name, r.kind)) t.id, o.id, r.kind, r.entry_name, r.entry_name
from (select distinct sport_slug, tournament_slug, kind, entry_name, organization_code from seed_individual_sports) r
join public.sports s on s.slug = r.sport_slug join public.tournaments t on t.sport_id = s.id and t.slug = r.tournament_slug
join public.organizations o on o.code = r.organization_code
where not exists (
  select 1 from public.entries e
  where e.tournament_id = t.id
    and e.kind = r.kind
    and private.entry_identity(e.name_vi, e.kind) = private.entry_identity(r.entry_name, r.kind)
)
order by t.id, r.kind, private.entry_identity(r.entry_name, r.kind), r.entry_name;

insert into public.entry_members (entry_id, participant_id, sort_order)
select distinct e.id, p.id, names.sort_order
from seed_individual_sports r join public.sports s on s.slug = r.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = r.tournament_slug
join public.entries e on e.tournament_id = t.id and e.kind = r.kind and e.archived_at is null and private.entry_identity(e.name_vi, e.kind) = private.entry_identity(r.entry_name, r.kind)
join public.organizations o on o.code = r.organization_code
cross join lateral unnest(string_to_array(r.member_names, E'\n')) with ordinality names(full_name, sort_order)
join public.participants p on p.organization_id = o.id and p.archived_at is null and private.entry_identity(p.full_name, 'individual') = private.entry_identity(names.full_name, 'individual')
on conflict (entry_id, participant_id) do update set archived_at = null;
