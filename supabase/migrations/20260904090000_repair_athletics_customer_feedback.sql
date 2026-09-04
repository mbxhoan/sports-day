create or replace function private.repair_athletics_customer_feedback(p_tenant_id uuid)
returns void
language plpgsql
as $function$
begin
  create temporary table repair_athletics_entries (
    tournament_slug text not null,
    section_slug text not null,
    section_vi text not null,
    section_en text not null,
    source_code text not null,
    entry_name text not null,
    organization_code text not null,
    seed_order integer not null,
    bib_number text,
    primary key (tournament_slug, section_slug, entry_name)
  ) on commit drop;

  insert into repair_athletics_entries values
  ('400m-nu','400m-nu','Danh sách vận động viên','Athletes','400M-NU','Nguyễn Thị Thúy','PETROSETCO',1,'00-001'),
  ('400m-nu','400m-nu','Danh sách vận động viên','Athletes','400M-NU','Nguyễn Thị Liên','VSP',2,'00-006'),
  ('400m-nu','400m-nu','Danh sách vận động viên','Athletes','400M-NU','Vũ Thị Huệ','PV DRILLING',3,'00-003'),
  ('400m-nu','400m-nu','Danh sách vận động viên','Athletes','400M-NU','Hoàng Thị Hà','PV GAS',4,'00-004'),
  ('400m-nu','400m-nu','Danh sách vận động viên','Athletes','400M-NU','Phạm Quỳnh Nga','VSP',5,'00-008'),
  ('400m-nu','400m-nu','Danh sách vận động viên','Athletes','400M-NU','Đinh Thị Thúy Nga','PTSC',6,'00-008'),
  ('400m-nu','400m-nu','Danh sách vận động viên','Athletes','400M-NU','Nguyễn Thị Thanh Nhàn','VSP',7,'00-007'),
  ('400m-nu','400m-nu','Danh sách vận động viên','Athletes','400M-NU','Hoàng Thị Hoài','PV GAS',8,'00-005'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Anh Dũng','PV DRILLING',1,'00-017'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Trung Dũng','PVPMB',2,'00-032'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Lê Hùng Cường','VSP',3,'00-033'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Trần Văn Cường','PV GAS',4,'00-021'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Đức Chính','PVCFC',5,'00-022'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Đậu Đăng Bút','NCKHĐT',6,'00-011'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Ngô Văn Cường','PV GAS',7,'00-020'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Trần Hoàng','PVEP',8,'00-027'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Mai Hoàng Hiệp','VSP',9,'00-034'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Phạm Hoàng Nam','PVCFC',10,'00-023'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Ngọc Lạp','PTSC',11,'00-015'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Văn Hưng','VSP',12,'00-035'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Phạm Hiếu Nhân','PVOIL',13,'00-030'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Phan Văn Thịnh','PETROSETCO',14,'00-013'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Văn Mạnh','VSP',15,'00-036'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Trần Văn Thắng','PVOIL',16,'00-031'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Quốc Thắng','PVCHEM',17,'00-025'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Trần Huy','VSP',18,'00-039'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Hoàng Văn Lâm','PVOIL',19,'00-028'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Trần Tuấn Trực','PV DRILLING',20,'00-019'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Võ Xuân Tuấn','VSP',21,'00-040'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Phan Sơn Tùng','LP1PP',22,'00-010'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Hoàng Đình Trúc','PV DRILLING',23,'00-016'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Phạm Văn Thao','VSP',24,'00-038'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Văn Tiến','PVCHEM',25,'00-026'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Đinh Hồng Phong','PTSC',26,'00-014'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Phan Minh Tùng','PETROSETCO',27,'00-012'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Xuân Phượng','VSP',28,'00-037'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Vương Ngọc Trìu','PVCFC',29,'00-024'),
  ('800m-nam','800m-nam-duoi-45','Dưới 45 tuổi','Under 45','800M-NAM-DUOI-45','Nguyễn Hữu Tuấn','PV DRILLING',30,'00-018'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Lê Tiến Dũng','PV GAS',1,'00-046'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Vũ Kim Mạnh','PV DRILLING',2,'00-045'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Nguyễn Viết Hùng','VSP',3,'00-049'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Vũ Hoàng Tiến','PTSC',4,'00-043'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Nguyễn Đình Thứ','VSP',5,'00-048'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Nguyễn Văn Hải','PV GAS',6,'00-047'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Phạm Đức Hinh','PETROCONs',7,'00-041'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Phạm Thành Trung','PTSC',8,'00-042'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Nguyễn Khắc Tuấn','PV DRILLING',9,'00-044'),
  ('800m-nam','800m-nam-tren-46','Trên 46 tuổi','Over 46','800M-NAM-TREN-46','Nguyễn Thành Chung','PVOIL',10,'00-029'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Nguyễn Thị Ngân Anh','VSP',1,'00-076'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Bùi Thị Hậu','PVOIL',2,'00-072'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Nguyễn Thị Hà','NCKHĐT',3,'00-058'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Nguyễn Thị Huệ','PV DRILLING',4,'00-064'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Nguyễn Thu Hiền','PVCHEM',5,'00-069'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Vương Thị Hiền','PV DRILLING',6,'00-066'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Phạm Thị Nụ','NCKHĐT',7,'00-061'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Võ Thị Lý','PV GAS',8,'00-068'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Phạm Thùy Linh','PVOIL',9,'00-073'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Nguyễn Thị Minh Hiền','PVFCCO',10,'00-070'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Nguyễn Thị Thu Vân','NCKHĐT',11,'00-060'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Đỗ Thị Phương Thảo','BĐPOC',12,'00-056'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Trần Thị Thảo','NCKHĐT',13,'00-062'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Cao Thị Thanh Thúy','PVI',14,'00-071'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Trần Phương Thúy','PVOIL',15,'00-075'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Nguyễn Thị Hồng Thúy','PV DRILLING',16,'00-063'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Đinh Nguyễn Phương Thanh','NCKHĐT',17,'00-057'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Trần Thị Hồng Thu','PV GAS',18,'00-067'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Nguyễn Thị Kim Trúc','NCKHĐT',19,'00-059'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Phan Thị Bích Tuyết','PVOIL',20,'00-074'),
  ('3000m-nu','3000m-nu-duoi-45','Dưới 45 tuổi','Under 45','3000M-NU-DUOI-45','Phan Thùy Trúc Quyên','PV DRILLING',21,'00-065'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Trần Thị Hoài An','PVOIL',1,'00-086'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Bùi Hồng Diễm','NCKHĐT',2,'00-077'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Cao Thị Huế','VSP',3,'00-087'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Nguyễn Thị Thúy Hiền','PETROSETCO',4,'00-081'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Trần Thị Nhiên','PV GAS',5,'00-083'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Quách Thị Hoa','PV DRILLING',6,'00-088'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Bùi Thị Ngọc Phương','NCKHĐT',7,'00-078'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Lê Thị Phượng','PVFCCO',8,'00-085'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Đỗ Thị Kim Thu','PV DRILLING',9,'00-082'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Nguyễn Thị Anh Thư','NCKHĐT',10,'00-079'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Trần Thị Thành','VSP',11,'00-089'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Phạm Thi Trang Vân','NCKHĐT',12,'00-080'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Chu Thị Hồng Vân','PVFCCO',13,'00-084'),
  ('3000m-nu','3000m-nu-tren-46','Trên 46 tuổi','Over 46','3000M-NU-TREN-46','Nguyễn Thị Thủy','PVEP',14,'00-090'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Hoàng Anh','BĐPOC',1,'00-089'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phạm Đức Anh','PQPOC',2,'00-101'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phạm Ngọc Anh','PVEP',3,'00-121'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Văn Bằng','PTSC',4,'00-103'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Lâm Quốc Cường','NCKHĐT',5,'00-094'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Tô Mạnh Cường','PTSC',6,'00-104'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Lê Quang Cường','PVFCCO',7,'00-122'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Đàm Thành Công','PVOIL',8,'00-126'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Vũ Văn Cường','PVOIL',9,'00-131'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Văn Chiến','PVEP',10,'00-120'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Đậu Danh','PVOIL',11,'00-127'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phạm Đình Danh','PVOIL',12,'00-129'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Trương Văn Chất','NCKHĐT',13,'00-098'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Đặng Văn Dũng','PETROCONs',14,'00-099'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Đinh Công Duyệt','PV DRILLING',15,'00-105'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Chử Văn Dũng','PV GAS',16,'00-108'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Bùi Minh Dũng','PVCHEM',17,'00-116'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Bùi Xuân Điền','PVOIL',18,'00-125'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Võ Duy Hoàng','PQPOC',19,'00-102'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Lê Văn Hiếu','PVFCCO',20,'00-123'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Chế Linh','PV POWER',21,'00-111'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Công Minh','BĐPOC',22,'00-088'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phạm Hải Nam','PV POWER',23,'00-112'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Minh Nhật','PETROSETCO',24,'00-100'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Vũ Mạnh Nhất','PV GAS',25,'00-110'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phan Thanh Nhân','PVCHEM',26,'00-118'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Đỗ Khắc Minh','PVEP',27,'00-119'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Bạch Thiện Hoài Nhân','PVCHEM',28,'00-115'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Lê Thanh Linh','PVCHEM',29,'00-117'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Qúy Minh','PVFCCO',30,'00-124'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Hoàng Đức Niên','BMĐH',31,'00-092'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Đinh Hồng Em','PVCFC',32,'00-114'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phạm Hữu Tài','NCKHĐT',33,'00-096'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Trần Hữu Thể','PV GAS',34,'00-109'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Hữu Tuệ','BĐPOC',35,'00-090'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Ngọc Tuân','NCKHĐT',36,'00-095'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Bảo Trung','PV DRILLING',37,'00-106'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Văn Triệu','BĐPOC',38,'00-091'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Lê Văn Tiệp','VSP',39,'00-132'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Vũ Quốc Thịnh','PVOIL',40,'00-130'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phan Ngọc Quốc','NCKHĐT',41,'00-097'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Trịnh Thanh Hoàng','VSP',42,'00-133'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Đinh Ngọc Trung','PVOIL',43,'00-128'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phan Kế Toại','PV DRILLING',44,'00-107'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Phan Tùng Sơn','PV POWER',45,'00-113'),
  ('5000m-nam','5000m-nam-duoi-45','Dưới 45 tuổi','Under 45','5000M-NAM-DUOI-45','Nguyễn Anh Khoa','NCKHĐT',46,'00-093'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Hoàng Như Chương','PETROCONs',1,'00-139'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Mai Nhân Dương','PV DRILLING',2,'00-150'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Đoàn Trung Dũng','PVEP',3,'00-160'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Võ Tấn Đạt','PVCFC',4,'00-159'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Nguyễn Văn Diên','BMĐH',5,'00-134'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Dương Trường Giang','PQPOC',6,'00-145'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Phạm Văn Hưng','PVOIL',7,'00-164'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Lê Viết Hưng','PETROCONs',8,'00-140'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Lê Dương Hải','NCKHĐT',9,'00-135'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Lưu Đức Hà','NCKHĐT',10,'00-136'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Nguyễn Bình Hợp','PV DRILLING',11,'00-151'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Tô Quang Hanh','PVPMB',12,'00-165'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Đỗ Hữu Nguyên','VSP',13,'00-166'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Nguyễn Văn Tâm','PQPOC',14,'00-147'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Phạm Văn Thật','PETROSETCO',15,'00-143'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Trần Xuân Thiên','VSP',16,'00-167'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Nguyễn Quốc Tuyển','PV DRILLING',17,'00-153'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Nguyễn Hữu Thức','PV GAS',18,'00-157'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Nguyễn Hoàng Long','PVOIL',19,'00-163'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Lê Nhân Thịnh','PQPOC',20,'00-146'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Tạ Ngoc Thắng','NCKHĐT',21,'00-137'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Trần Văn Trung','PV POWER',22,'00-158'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Giáp Văn Tỉnh','PV DRILLING',23,'00-149'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Vũ Xuân Tĩnh','PETROCONs',24,'00-141'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Lê Công Thế','PV GAS',25,'00-155'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Võ Văn Ngọc','PVFCCO',26,'00-162'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Trần Hữu Phong','PV DRILLING',27,'00-154'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Nguyễn Đăng Khoa','PV DRILLING',28,'00-152'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Đào Ngọc Kết','PETROCONs',29,'00-138'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Mai Xuân Trí','PV GAS',30,'00-156'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Lê Văn Quyền','PETROSETCO',31,'00-142'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Hứa Viết Sơn','PVFCCO',32,'00-161'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Trương Văn Quốc','PETROSETCO',33,'00-144'),
  ('5000m-nam','5000m-nam-tren-46','Trên 46 tuổi','Over 46','5000M-NAM-TREN-46','Lương Ngọc Phúc','PTSC',34,'00-148');

  insert into public.organizations (tenant_id, code, name_vi, name_en)
  select distinct p_tenant_id, organization_code, organization_code, organization_code
  from repair_athletics_entries
  on conflict (tenant_id, code) do update set archived_at = null;

  insert into public.participants (tenant_id, organization_id, full_name, full_name_en)
  select p_tenant_id, organization.id, source.entry_name, source.entry_name
  from (
    select distinct on (entry_name) entry_name, organization_code
    from repair_athletics_entries
    order by entry_name, section_slug
  ) source
  join public.organizations organization on organization.tenant_id = p_tenant_id and organization.code = source.organization_code
  where not exists (
    select 1
    from public.participants existing
    where existing.tenant_id = p_tenant_id
      and private.entry_identity(existing.full_name, 'individual') = private.entry_identity(source.entry_name, 'individual')
  );

  update public.entries entry
  set organization_id = organization.id,
      seed_number = source.seed_order,
      bib_number = source.bib_number,
      archived_at = null
  from repair_athletics_entries source
  join public.tournaments tournament on tournament.tenant_id = p_tenant_id and tournament.slug = source.tournament_slug
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'dien-kinh'
  join public.organizations organization on organization.tenant_id = p_tenant_id and organization.code = source.organization_code
  where entry.id = (
    select candidate.id
    from public.entries candidate
    where candidate.tenant_id = p_tenant_id
      and candidate.tournament_id = tournament.id
      and candidate.kind = 'individual'
      and candidate.archived_at is null
      and private.entry_identity(candidate.name_vi, candidate.kind) = private.entry_identity(source.entry_name, candidate.kind)
    order by (candidate.name_vi = source.entry_name) desc, candidate.id
    limit 1
  );

  insert into public.entries (tenant_id, tournament_id, organization_id, kind, name_vi, name_en, seed_number, bib_number)
  select p_tenant_id, tournament.id, organization.id, 'individual', source.entry_name, source.entry_name, source.seed_order, source.bib_number
  from repair_athletics_entries source
  join public.tournaments tournament on tournament.tenant_id = p_tenant_id and tournament.slug = source.tournament_slug
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'dien-kinh'
  join public.organizations organization on organization.tenant_id = p_tenant_id and organization.code = source.organization_code
  where not exists (
    select 1
    from public.entries existing
    where existing.tenant_id = p_tenant_id
      and existing.tournament_id = tournament.id
      and existing.kind = 'individual'
      and existing.archived_at is null
      and private.entry_identity(existing.name_vi, existing.kind) = private.entry_identity(source.entry_name, existing.kind)
  );

  insert into public.entry_members (tenant_id, entry_id, participant_id, sort_order)
  select p_tenant_id, entry.id, participant.id, 1
  from repair_athletics_entries source
  join public.tournaments tournament on tournament.tenant_id = p_tenant_id and tournament.slug = source.tournament_slug
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'dien-kinh'
  join lateral (
    select candidate.id
    from public.entries candidate
    where candidate.tenant_id = p_tenant_id
      and candidate.tournament_id = tournament.id
      and candidate.kind = 'individual'
      and candidate.archived_at is null
      and private.entry_identity(candidate.name_vi, candidate.kind) = private.entry_identity(source.entry_name, candidate.kind)
    order by (candidate.name_vi = source.entry_name) desc, candidate.id
    limit 1
  ) entry on true
  join lateral (
    select candidate.id
    from public.participants candidate
    where candidate.tenant_id = p_tenant_id
      and private.entry_identity(candidate.full_name, 'individual') = private.entry_identity(source.entry_name, 'individual')
    order by candidate.archived_at nulls first, candidate.id
    limit 1
  ) participant on true
  on conflict (entry_id, participant_id) do update set sort_order = excluded.sort_order, archived_at = null;

  update public.fixtures fixture
  set round_vi = source.section_vi,
      round_en = source.section_en,
      source_code = source.source_code
  from (
    select distinct on (tournament_slug) tournament_slug, section_slug, section_vi, section_en, source_code
    from repair_athletics_entries
    where section_slug !~ '-tren-46$'
    order by tournament_slug, section_slug
  ) source
  join public.tournaments tournament on tournament.tenant_id = p_tenant_id and tournament.slug = source.tournament_slug
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'dien-kinh'
  where fixture.id = (
    select candidate.id
    from public.fixtures candidate
    where candidate.tenant_id = p_tenant_id
      and candidate.tournament_id = tournament.id
      and candidate.archived_at is null
      and (candidate.source_code is null or candidate.source_code = '')
      and candidate.round_vi = 'Thi đấu'
    order by candidate.id
    limit 1
  );

  insert into public.fixtures (tenant_id, tournament_id, status, starts_at, round_vi, round_en, source_code)
  select p_tenant_id, tournament.id, 'scheduled',
         (select min(candidate.starts_at) from public.fixtures candidate where candidate.tournament_id = tournament.id and candidate.archived_at is null),
         source.section_vi, source.section_en, source.source_code
  from (
    select distinct on (tournament_slug, section_slug) tournament_slug, section_slug, section_vi, section_en, source_code
    from repair_athletics_entries
    order by tournament_slug, section_slug
  ) source
  join public.tournaments tournament on tournament.tenant_id = p_tenant_id and tournament.slug = source.tournament_slug
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'dien-kinh'
  where not exists (
    select 1 from public.fixtures existing
    where existing.tenant_id = p_tenant_id
      and existing.tournament_id = tournament.id
      and existing.source_code = source.source_code
      and existing.archived_at is null
  );

  insert into public.fixture_entries (tenant_id, fixture_id, entry_id, lane, seed_order, score, score_numeric, rank, result_detail, result_status)
  select p_tenant_id, destination.id, entry.id, previous.lane, source.seed_order, previous.score, previous.score_numeric, previous.rank, coalesce(previous.result_detail, '{}'::jsonb), previous.result_status
  from repair_athletics_entries source
  join public.tournaments tournament on tournament.tenant_id = p_tenant_id and tournament.slug = source.tournament_slug
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'dien-kinh'
  join public.fixtures destination on destination.tenant_id = p_tenant_id and destination.tournament_id = tournament.id and destination.source_code = source.source_code and destination.archived_at is null
  join lateral (
    select candidate.id
    from public.entries candidate
    where candidate.tenant_id = p_tenant_id
      and candidate.tournament_id = tournament.id
      and candidate.kind = 'individual'
      and candidate.archived_at is null
      and private.entry_identity(candidate.name_vi, candidate.kind) = private.entry_identity(source.entry_name, candidate.kind)
    order by (candidate.name_vi = source.entry_name) desc, candidate.id
    limit 1
  ) entry on true
  left join lateral (
    select old.lane, old.score, old.score_numeric, old.rank, old.result_detail, old.result_status
    from public.fixture_entries old
    join public.fixtures old_fixture on old_fixture.id = old.fixture_id
    where old.tenant_id = p_tenant_id
      and old.entry_id = entry.id
      and old.archived_at is null
      and old_fixture.tournament_id = tournament.id
      and old_fixture.id <> destination.id
    order by old_fixture.id
    limit 1
  ) previous on true
  on conflict (fixture_id, entry_id) do update set
    seed_order = excluded.seed_order,
    lane = coalesce(fixture_entries.lane, excluded.lane),
    score = coalesce(fixture_entries.score, excluded.score),
    score_numeric = coalesce(fixture_entries.score_numeric, excluded.score_numeric),
    rank = coalesce(fixture_entries.rank, excluded.rank),
    result_detail = case when fixture_entries.result_detail = '{}'::jsonb then excluded.result_detail else fixture_entries.result_detail end,
    result_status = coalesce(fixture_entries.result_status, excluded.result_status),
    archived_at = null;

  update public.fixture_entries item
  set archived_at = now()
  from public.fixtures fixture
  join public.tournaments tournament on tournament.id = fixture.tournament_id and tournament.tenant_id = p_tenant_id
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'dien-kinh'
  cross join public.entries old_entry
  join (
    select distinct on (tournament_slug, section_slug) tournament_slug, section_slug, source_code
    from repair_athletics_entries
    order by tournament_slug, section_slug
  ) section on section.tournament_slug = tournament.slug and section.source_code = fixture.source_code
  where item.fixture_id = fixture.id
    and old_entry.id = item.entry_id
    and item.tenant_id = p_tenant_id
    and item.archived_at is null
    and not exists (
      select 1
      from repair_athletics_entries source
      where source.tournament_slug = tournament.slug
        and source.section_slug = section.section_slug
        and private.entry_identity(source.entry_name, 'individual') = private.entry_identity(old_entry.name_vi, 'individual')
    );

  insert into public.standings (tenant_id, tournament_id, entry_id)
  select p_tenant_id, tournament.id, entry.id
  from repair_athletics_entries source
  join public.tournaments tournament on tournament.tenant_id = p_tenant_id and tournament.slug = source.tournament_slug
  join public.sports sport on sport.id = tournament.sport_id and sport.tenant_id = p_tenant_id and sport.slug = 'dien-kinh'
  join lateral (
    select candidate.id
    from public.entries candidate
    where candidate.tenant_id = p_tenant_id
      and candidate.tournament_id = tournament.id
      and candidate.kind = 'individual'
      and candidate.archived_at is null
      and private.entry_identity(candidate.name_vi, candidate.kind) = private.entry_identity(source.entry_name, candidate.kind)
    order by (candidate.name_vi = source.entry_name) desc, candidate.id
    limit 1
  ) entry on true
  on conflict (tournament_id, group_id, entry_id) do update set archived_at = null;
end;
$function$;

do $$
begin
  if exists (
    select 1
    from public.tournaments tournament
    join public.sports sport on sport.id = tournament.sport_id
    where tournament.tenant_id = private.seed_tenant_id()
      and sport.tenant_id = tournament.tenant_id
      and sport.slug = 'dien-kinh'
  ) then
    perform private.repair_athletics_customer_feedback(private.seed_tenant_id());
  end if;
end
$$;
