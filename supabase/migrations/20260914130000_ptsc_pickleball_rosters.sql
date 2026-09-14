set app.tenant_slug = 'ptsc2026';

do $migration$
declare
  v_tenant_id uuid := '22222222-2222-2222-2222-222222222222';
  v_row jsonb;
  v_rows jsonb := $pickleball_rows$[
    {"category_code":"PB-DON-NAM45","normalized_group":"A","slot_no":1,"members":["Phạm Đức Dũng"],"unit":"PTSC Miền Trung","pdf_page":1,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"A","slot_no":2,"members":["Nguyễn Trung Hiếu"],"unit":"PTSC SAO MAI","pdf_page":1,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"A","slot_no":3,"members":["Nguyễn Thành Quang"],"unit":"PTSC HQ","pdf_page":1,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"A","slot_no":4,"members":["Đỗ Văn Duy"],"unit":"POS","pdf_page":1,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"B","slot_no":1,"members":["Dương Quốc Huân"],"unit":"PTSC HQ","pdf_page":1,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"B","slot_no":2,"members":["Nguyễn Việt Linh"],"unit":"PTSC M&C","pdf_page":1,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"B","slot_no":3,"members":["Phan Minh Tân"],"unit":"PTSC Long Phú","pdf_page":1,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"C","slot_no":1,"members":["Nguyễn Thiện Hoàng Quý"],"unit":"PTSC Thanh Hóa","pdf_page":2,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"C","slot_no":2,"members":["Trần Khắc Huy"],"unit":"POS","pdf_page":2,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"C","slot_no":3,"members":["Trần Bách Hải Cường"],"unit":"PVSHIPYARD","pdf_page":2,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"C","slot_no":4,"members":["Đoàn Khôi Nguyên"],"unit":"PTSC M&C","pdf_page":2,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"D","slot_no":1,"members":["Nguyễn Đức Của"],"unit":"PTSC Miền Trung","pdf_page":2,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"D","slot_no":2,"members":["Trần Vũ Yên"],"unit":"PTSC Long Phú","pdf_page":2,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"D","slot_no":3,"members":["Trần Văn Mạnh"],"unit":"PTSC M&C","pdf_page":2,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"D","slot_no":4,"members":["Lê Anh Thuần"],"unit":"PTSC Phú Mỹ","pdf_page":2,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"E","slot_no":1,"members":["Phạm Văn Dương"],"unit":"PTSC G&S","pdf_page":3,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"E","slot_no":2,"members":["Vũ Xuân Đạo"],"unit":"PPS","pdf_page":3,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"E","slot_no":3,"members":["Trần Văn Toản"],"unit":"PTSC HQ","pdf_page":3,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"F","slot_no":1,"members":["Đỗ Viết Hoa"],"unit":"PTSC Thanh Hóa","pdf_page":3,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"F","slot_no":2,"members":["Võ Hoàng Tấn"],"unit":"PVSHIPYARD","pdf_page":3,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"F","slot_no":3,"members":["Mạnh Trọng Phúc"],"unit":"Petro Hotel","pdf_page":3,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"F","slot_no":4,"members":["Nguyễn Đình Vũ Thịnh"],"unit":"PPS","pdf_page":3,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"G","slot_no":1,"members":["Bùi Khánh Dũng"],"unit":"PVSecurity","pdf_page":4,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"G","slot_no":2,"members":["Hồ Vũ Duy"],"unit":"PTSC Quảng Ngãi","pdf_page":4,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"G","slot_no":3,"members":["Đặng Thái Minh"],"unit":"PTSC Quảng Ngãi","pdf_page":4,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"H","slot_no":1,"members":["Lương Anh Tuấn"],"unit":"PPS","pdf_page":4,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"H","slot_no":2,"members":["Nguyễn Trung Tuấn"],"unit":"PTSC Đình Vũ","pdf_page":4,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM45","normalized_group":"H","slot_no":3,"members":["Huỳnh Trung Hiếu"],"unit":"PTSC Quảng Ngãi","pdf_page":4,"kind":"individual","status":"draft"},

    {"category_code":"PB-DON-NAM46","normalized_group":"A","slot_no":1,"members":["Nguyễn Minh Thăng"],"unit":"PTSC M&C","pdf_page":6,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"A","slot_no":2,"members":["Phạm Đình Dũng"],"unit":"PTSC HQ","pdf_page":6,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"A","slot_no":3,"members":["Nguyễn Hữu Hùng"],"unit":"PTSC Miền Trung","pdf_page":6,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"B","slot_no":1,"members":["Nguyễn Viết Thành"],"unit":"PTSC Quảng Ngãi","pdf_page":6,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"B","slot_no":2,"members":["Bùi Ngọc Nam"],"unit":"PPS","pdf_page":6,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"B","slot_no":3,"members":["Bùi Xuân Lộc"],"unit":"PTSC M&C","pdf_page":6,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"C","slot_no":1,"members":["Lê Quý Dũng"],"unit":"PTSC Thanh Hóa","pdf_page":7,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"C","slot_no":2,"members":["Phùng Phú Cường"],"unit":"PTSC Phú Mỹ","pdf_page":7,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"C","slot_no":3,"members":["Ngô Anh Đức"],"unit":"PTSC Supply Base","pdf_page":7,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"D","slot_no":1,"members":["Nguyễn Thanh Tân"],"unit":"PTSC HQ","pdf_page":7,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"D","slot_no":2,"members":["Bùi Trung Kiên"],"unit":"PTSC Marine","pdf_page":7,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NAM46","normalized_group":"D","slot_no":3,"members":["Lữ Đức Thắng"],"unit":"HCNS - POS","pdf_page":7,"kind":"individual","status":"draft"},

    {"category_code":"PB-DON-NU45","normalized_group":"A","slot_no":1,"members":["Trần Thị Thu Thảo"],"unit":"PPS","pdf_page":9,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"A","slot_no":2,"members":["Phạm Thu Hiền"],"unit":"POS","pdf_page":9,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"A","slot_no":3,"members":["Hồ Minh Nguyệt"],"unit":"PTSC Marine","pdf_page":9,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"B","slot_no":1,"members":["Đinh Thị Thu Huyền"],"unit":"PTSC Marine","pdf_page":9,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"B","slot_no":2,"members":["Trần Võ Phương Linh"],"unit":"PTSC M&C","pdf_page":9,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"B","slot_no":3,"members":["Trần Thị Minh Hương"],"unit":"POS","pdf_page":9,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"C","slot_no":1,"members":["Chu Quỳnh Anh"],"unit":"PTSC Marine","pdf_page":10,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"C","slot_no":2,"members":["Thái Hồng Thúy"],"unit":"PTSC Phú Mỹ","pdf_page":10,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"C","slot_no":3,"members":["Phan Thị Vân Anh"],"unit":"PTSC M&C","pdf_page":10,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"D","slot_no":1,"members":["Phạm Thị Xuân Phượng"],"unit":"PTSC Sao Mai","pdf_page":10,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"D","slot_no":2,"members":["Vũ Thị Huệ"],"unit":"PTSC Đình Vũ","pdf_page":10,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU45","normalized_group":"D","slot_no":3,"members":["Hồ Thúy Vy"],"unit":"PTSC HQ","pdf_page":10,"kind":"individual","status":"draft"},

    {"category_code":"PB-DON-NU46","normalized_group":"A","slot_no":1,"members":["Bùi Thị Ngọc Lan"],"unit":"PTSC Marine","pdf_page":12,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU46","normalized_group":"A","slot_no":2,"members":["Phạm Thị Hồng Hạnh"],"unit":"POS","pdf_page":12,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU46","normalized_group":"A","slot_no":3,"members":["Bùi Việt Nga"],"unit":"PTSC Supply Base","pdf_page":12,"kind":"individual","status":"draft"},
    {"category_code":"PB-DON-NU46","normalized_group":"A","slot_no":4,"members":["Hoàng Kỷ Hạnh"],"unit":"PTSC Marine","pdf_page":12,"kind":"individual","status":"draft"},

    {"category_code":"PB-DOI-NAM45","normalized_group":"A","slot_no":1,"members":["Lương Anh Tuấn","Nguyễn Tiến Độ"],"unit":"PPS","pdf_page":13,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"A","slot_no":2,"members":["Nguyễn Tiến Huy","Vũ Huy Trung"],"unit":"PTSC Supply Base","pdf_page":13,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"A","slot_no":3,"members":["Dương Minh Đức","Võ Duy Hùng"],"unit":"PTSC Quảng Ngãi","pdf_page":13,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"A","slot_no":4,"members":["Nguyễn Văn Vương","Phùng Xuân Hưng"],"unit":"PTSC Long Phú","pdf_page":13,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"B","slot_no":1,"members":["Nguyễn Chí Hiếu","Trần Hưng Thịnh"],"unit":"PTSC G&S","pdf_page":13,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"B","slot_no":2,"members":["Nguyễn Đức Của","Phùng Vĩ Bảo"],"unit":"PTSC Miền Trung","pdf_page":13,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"B","slot_no":3,"members":["Dương Văn Nhâm","Nguyễn Trường Giang"],"unit":"PTSC Phú Mỹ","pdf_page":13,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"B","slot_no":4,"members":["Nguyễn Quốc Chánh","Võ Xuân Thắng"],"unit":"PPS","pdf_page":13,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"C","slot_no":1,"members":["Phạm Giỏi","Huỳnh Trung Hiếu"],"unit":"PTSC Quảng Ngãi","pdf_page":14,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"C","slot_no":2,"members":["Bùi Ngọc Nam","Nguyễn Đình Vũ Thịnh"],"unit":"PPS","pdf_page":14,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"C","slot_no":3,"members":["Bùi Hồng Quân","Nguyễn Quang Đảng"],"unit":"PTSC Long Phú","pdf_page":14,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"C","slot_no":4,"members":["Đào Trường Linh","Lê Anh Thuần"],"unit":"PTSC Phú Mỹ","pdf_page":14,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"D","slot_no":1,"members":["Lê Mạnh Hùng","Phan Ngọc Hưng"],"unit":"PTSC Marine","pdf_page":14,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"D","slot_no":2,"members":["Nguyễn Thế Hà","Phạm Văn Toán"],"unit":"PTSC M&C","pdf_page":14,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"D","slot_no":3,"members":["Vũ Đình Tiến","Nguyễn Trọng Anh"],"unit":"PTSC Thanh Hóa","pdf_page":14,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"D","slot_no":4,"members":["Nguyễn Trung Hiếu","Hồ Sỹ Mạnh"],"unit":"PTSC Sao Mai","pdf_page":14,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"E","slot_no":1,"members":["Trần Vũ Yên","Phạm Văn Thưởng"],"unit":"PTSC Long Phú","pdf_page":15,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"E","slot_no":2,"members":["Phạm Đắc Tiến","Vũ Tuấn Hoàng"],"unit":"PTSC M&C","pdf_page":15,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"E","slot_no":3,"members":["Đỗ Thành Đạt","Đỗ Viết Hoa"],"unit":"PTSC Thanh Hóa","pdf_page":15,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"E","slot_no":4,"members":["Vũ Văn Lâm","Nguyễn Tiến Trường"],"unit":"PTSC HQ","pdf_page":15,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"F","slot_no":1,"members":["Nguyễn Việt Đức","Lê Văn Đức"],"unit":"PTSC Thanh Hóa","pdf_page":15,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"F","slot_no":2,"members":["Trần Bách Hải Cường","Nguyễn Quang Minh"],"unit":"PVSHIPYARD","pdf_page":15,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"F","slot_no":3,"members":["Nguyễn Hữu Tằng","Nguyễn Trọng Đông"],"unit":"PTSC Phú Mỹ","pdf_page":15,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"F","slot_no":4,"members":["Phạm Trường Minh","Nguyễn Anh Tuấn"],"unit":"PTSC M&C","pdf_page":15,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"G","slot_no":1,"members":["Phạm Văn Tuân","Lê Bá Thúc"],"unit":"POS","pdf_page":16,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"G","slot_no":2,"members":["Phạm Văn Kỷ","Nguyễn Hoàng Dương"],"unit":"PTSC Đình Vũ","pdf_page":16,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"G","slot_no":3,"members":["Nguyễn Thành Quang","Phạm Vũ Quang"],"unit":"PTSC HQ","pdf_page":16,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"G","slot_no":4,"members":["Dương Công Thành","Trương Văn Đặng"],"unit":"PTSC Sao Mai","pdf_page":16,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"H","slot_no":1,"members":["Trần Xuân Thành","Nguyễn Văn Đà"],"unit":"PTSC Miền Trung","pdf_page":16,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"H","slot_no":2,"members":["Ngô Thanh Sang","Phương Văn Tài"],"unit":"PVSecurity","pdf_page":16,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"H","slot_no":3,"members":["Đỗ Long Sơn","Võ Hoàng Tấn"],"unit":"PVSHIPYARD","pdf_page":16,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"H","slot_no":4,"members":["Nguyễn Tiến Dũng","Đoàn Trung Dũng"],"unit":"PTSC HQ","pdf_page":16,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAM45","normalized_group":"H","slot_no":5,"members":["Ngô Xuân Thao","Hồ Vũ Duy"],"unit":"PTSC Quảng Ngãi","pdf_page":16,"kind":"pair","status":"draft"},

    {"category_code":"PB-DOI-NAM46","normalized_group":"A","slot_no":1,"members":["Võ Phúc","Nguyễn Trọng Phúc"],"unit":"POS","pdf_page":18,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"A","slot_no":2,"members":["Đào Duy Dương","Nguyễn Sỹ Hà"],"unit":"PTSC Marine","pdf_page":18,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"A","slot_no":3,"members":["Lê Văn Quốc Duy","Đinh Mạnh Hùng"],"unit":"PTSC Phú Mỹ","pdf_page":18,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"B","slot_no":1,"members":["Hồ Tường Phát","Đào Văn Tuấn"],"unit":"PTSC Quảng Ngãi","pdf_page":18,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"B","slot_no":2,"members":["Nguyễn Việt Hà","Nguyễn Tiến Độ"],"unit":"PPS","pdf_page":18,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"B","slot_no":3,"members":["Lê Nguyễn Thanh Hùng","Nguyễn Thành Trung"],"unit":"PTSC M&C","pdf_page":18,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"C","slot_no":1,"members":["Phí Hải Hồng","Nguyễn Duy Thái"],"unit":"PTSC M&C","pdf_page":19,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"C","slot_no":2,"members":["Trần Hoàng Tám","Nguyễn Hữu Hùng"],"unit":"PTSC Miền Trung","pdf_page":19,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"C","slot_no":3,"members":["Tạ Bá Công","Phạm Đăng Lâm"],"unit":"PTSC Thanh Hóa","pdf_page":19,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"D","slot_no":1,"members":["Trần Thủy Thanh Tùng","Nguyễn Minh Thăng"],"unit":"PTSC M&C","pdf_page":19,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"D","slot_no":2,"members":["Hồ Sỹ Dũng","Lê Xuân Thủy"],"unit":"PTSC Marine","pdf_page":19,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"D","slot_no":3,"members":["Đỗ Đức Thân","Ngô Đình Kiên"],"unit":"PTSC Đình Vũ","pdf_page":19,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"E","slot_no":1,"members":["Nguyễn Thanh Tân","Trần Tuấn Khánh"],"unit":"PTSC HQ","pdf_page":20,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"E","slot_no":2,"members":["Nguyễn Ngọc Ánh","Nguyễn Ngọc Sơn"],"unit":"PTSC Supply Base","pdf_page":20,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"E","slot_no":3,"members":["Nguyễn Văn Tiến","Dương Cao Cường"],"unit":"POS","pdf_page":20,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"F","slot_no":1,"members":["Nguyễn Khánh","Đặng Văn Toản"],"unit":"PPS","pdf_page":20,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"F","slot_no":2,"members":["Lê Quý Dũng","Lê Văn Hữu"],"unit":"PTSC Thanh Hóa","pdf_page":20,"kind":"pair","status":"pending_confirmation"},
    {"category_code":"PB-DOI-NAM46","normalized_group":"F","slot_no":3,"members":["Bùi Trung Kiên","Nguyễn Văn Sang"],"unit":"PTSC Marine","pdf_page":20,"kind":"pair","status":"pending_confirmation"},

    {"category_code":"PB-DOI-NU45","normalized_group":"A","slot_no":1,"members":["Phạm Thị Tuyết Mai","Chu Thị Mai"],"unit":"PTSC Miền Trung","pdf_page":22,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"A","slot_no":2,"members":["Trần Ngọc Mai","Hoàng Thị Trang"],"unit":"PTSC Supply Base","pdf_page":22,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"A","slot_no":3,"members":["Nguyễn Thùy Linh","Phạm Thị Hồng"],"unit":"PPS","pdf_page":22,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"B","slot_no":1,"members":["Nguyễn Lệ Minh","Nguyễn Thanh Kim Vy"],"unit":"PTSC Quảng Ngãi","pdf_page":22,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"B","slot_no":2,"members":["Lê Thị Ngọc Anh","Đặng Thị Tuyết Anh"],"unit":"PTSC Marine","pdf_page":22,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"B","slot_no":3,"members":["Ngô Thị Thảo Vy","Đặng Thị Kim Thoa"],"unit":"PTSC M&C","pdf_page":22,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"C","slot_no":1,"members":["Đào Thị Kim Quyên","Phạm Thị Xuân Phượng"],"unit":"PTSC Sao Mai","pdf_page":23,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"C","slot_no":2,"members":["Phạm Thị Hoa","Nghiêm Thị Thúy Hằng"],"unit":"PTSC Marine","pdf_page":23,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"C","slot_no":3,"members":["Trịnh Thị Hiền","Phạm Minh Châu"],"unit":"PTSC M&C","pdf_page":23,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"D","slot_no":1,"members":["Đỗ Khánh Linh","Bùi Thanh Hương"],"unit":"PTSC M&C","pdf_page":23,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"D","slot_no":2,"members":["Khổng Thụy Thùy Dung","Lữ Thị Nhung"],"unit":"POS","pdf_page":23,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"D","slot_no":3,"members":["Trần Thu Trang","Dương Thị Thư"],"unit":"PTSC Long Phú","pdf_page":23,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"E","slot_no":1,"members":["Bùi Thị Ngọc Lan","Chu Quỳnh Anh"],"unit":"PTSC Marine","pdf_page":23,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"E","slot_no":2,"members":["Trần Thị Minh Hương","Đinh Thị Thúy Nga"],"unit":"POS","pdf_page":23,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU45","normalized_group":"E","slot_no":3,"members":["Nguyễn Thị Tố Tâm","Trần Thị Diệu Anh"],"unit":"PTSC HQ","pdf_page":23,"kind":"pair","status":"draft"},

    {"category_code":"PB-DOI-NU46","normalized_group":"A","slot_no":1,"members":["Nguyễn Thị Thu Thảo","Đoàn Thị Tuyến"],"unit":"PTSC Marine","pdf_page":25,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU46","normalized_group":"A","slot_no":2,"members":["Lê Anh Thư","Đào Thị Nga"],"unit":"PTSC HQ","pdf_page":25,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU46","normalized_group":"A","slot_no":3,"members":["Phạm Thị Khuyên","Hoàng Kỷ Hạnh"],"unit":"PTSC Marine","pdf_page":25,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU46","normalized_group":"A","slot_no":4,"members":["Nguyễn Thị Ngọc Lâm","Phạm Thị Nguyệt"],"unit":"PTSC Quảng Ngãi","pdf_page":25,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NU46","normalized_group":"A","slot_no":5,"members":["Hà Thị Ánh Huệ","Trần Thị Kim Hoa"],"unit":"PTSC Supply Base","pdf_page":25,"kind":"pair","status":"draft"},

    {"category_code":"PB-DOI-NAMNU45","normalized_group":"A","slot_no":1,"members":["Trịnh Thị Hiền","Mai Thanh Hải"],"unit":"PTSC M&C","pdf_page":26,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"A","slot_no":2,"members":["Võ Xuân Thắng","Trần Thị Thu Thảo"],"unit":"PPS","pdf_page":26,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"A","slot_no":3,"members":["Phan Minh Tân","Trần Thu Trang"],"unit":"PTSC Long Phú","pdf_page":26,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"B","slot_no":1,"members":["Ngô Quang Minh","Nguyễn Thị Tố Tâm"],"unit":"PTSC HQ","pdf_page":26,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"B","slot_no":2,"members":["Nguyễn Trần Bảo Trung","Chu Thị Thu"],"unit":"PTSC M&C","pdf_page":26,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"B","slot_no":3,"members":["Đỗ Văn Duy","Nguyễn Phương Linh"],"unit":"POS","pdf_page":26,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"C","slot_no":1,"members":["Nguyễn Thanh Kim Vy","Ngô Xuân Thao"],"unit":"PTSC Quảng Ngãi","pdf_page":27,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"C","slot_no":2,"members":["Bùi Việt Nga","Trần Trung Kiên"],"unit":"PTSC Supply Base","pdf_page":27,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"C","slot_no":3,"members":["Hồ Sỹ Mạnh","Đào Thị Kim Quyên"],"unit":"PTSC Sao Mai","pdf_page":27,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"D","slot_no":1,"members":["Võ Xuân Đạo","Nguyễn Thùy Linh"],"unit":"PPS","pdf_page":27,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"D","slot_no":2,"members":["Phạm Văn Dương","Đào Thị Hiểu"],"unit":"PTSC G&S","pdf_page":27,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"D","slot_no":3,"members":["Lê Bá Trúc","Trần Ngân Hà"],"unit":"POS","pdf_page":27,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"E","slot_no":1,"members":["Nguyễn Hoàng Tuấn Tú","Đào Thị Hợp"],"unit":"PTSC Marine","pdf_page":28,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"E","slot_no":2,"members":["Nguyễn Văn Vương","Trần Thị Thùy Trang"],"unit":"PTSC Long Phú","pdf_page":28,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"E","slot_no":3,"members":["Đặng Kiều Anh","Lê Hải Lâm"],"unit":"PTSC Đình Vũ","pdf_page":28,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"F","slot_no":1,"members":["Phạm Văn Tuân","Phạm Thị Hồng Hạnh"],"unit":"POS","pdf_page":28,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"F","slot_no":2,"members":["Lê Xuân Thủy","Lê Thị Hồng Nhung"],"unit":"PTSC Marine","pdf_page":28,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"F","slot_no":3,"members":["Dương Minh Đức","Nguyễn Lệ Minh"],"unit":"PTSC Quảng Ngãi","pdf_page":28,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"G","slot_no":1,"members":["Nguyễn Trọng Đông","Thái Hồng Thúy"],"unit":"PTSC Phú Mỹ","pdf_page":29,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"G","slot_no":2,"members":["Lê Văn Đức","Nguyễn Thị Duyên"],"unit":"PTSC Thanh Hóa","pdf_page":29,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"G","slot_no":3,"members":["Nguyễn Quốc Chánh","Lê Thị Hoài Thanh"],"unit":"PPS","pdf_page":29,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"G","slot_no":4,"members":["Nguyễn Chí Hiếu","Hoàng Thị Trang"],"unit":"PTSC Supply Base","pdf_page":29,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"H","slot_no":1,"members":["Nguyễn Thế Hà","Trịnh Thị Hòa"],"unit":"PTSC M&C","pdf_page":29,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"H","slot_no":2,"members":["Nguyễn Hồ Cẩm Vân","Trần Văn Toản"],"unit":"PTSC HQ","pdf_page":29,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"H","slot_no":3,"members":["Hồ Sĩ Nhật Thái","Dương Thị Thư"],"unit":"PTSC Long Phú","pdf_page":29,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU45","normalized_group":"H","slot_no":4,"members":["Nguyễn Sỹ Hà","Nghiêm Thị Thúy Hằng"],"unit":"PTSC Marine","pdf_page":29,"kind":"pair","status":"draft"},

    {"category_code":"PB-DOI-NAMNU46","normalized_group":"A","slot_no":1,"members":["Trần Thủy Thanh Tùng","Ngô Thị Ngọc Mỹ"],"unit":"PTSC M&C","pdf_page":31,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"A","slot_no":2,"members":["Ngô Anh Đức","Trần Thị Kim Hoa"],"unit":"PTSC Supply Base","pdf_page":31,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"A","slot_no":3,"members":["Đào Văn Tuấn","Nguyễn Thị Ngọc Lâm"],"unit":"PTSC Quảng Ngãi","pdf_page":31,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"A","slot_no":4,"members":["Nguyễn Khánh","Lê Thị Hoài Thanh"],"unit":"PPS","pdf_page":31,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"B","slot_no":1,"members":["Nguyễn Thị Thu Hà","Phạm Huy Dũng"],"unit":"PTSC Đình Vũ","pdf_page":31,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"B","slot_no":2,"members":["Nguyễn Thị Bảy","Nguyễn Duy Thái"],"unit":"PTSC M&C","pdf_page":31,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"B","slot_no":3,"members":["Phùng Hưng","Thái Thị Hải Yến"],"unit":"PTSC Marine","pdf_page":31,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"C","slot_no":1,"members":["Đặng Văn Toản","Phạm Thị Hồng"],"unit":"PPS","pdf_page":32,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"C","slot_no":2,"members":["Đào Duy Dương","Phạm Thị Khuyên"],"unit":"PTSC Marine","pdf_page":32,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"C","slot_no":3,"members":["Nguyễn Viết Thành","Phạm Thị Nguyệt"],"unit":"PTSC Quảng Ngãi","pdf_page":32,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"D","slot_no":1,"members":["Nguyễn Việt Hà","Lê Thị Phương"],"unit":"PPS","pdf_page":32,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"D","slot_no":2,"members":["Dương Công Thành","Ngô Thuý Hảo"],"unit":"PTSC Sao Mai","pdf_page":32,"kind":"pair","status":"draft"},
    {"category_code":"PB-DOI-NAMNU46","normalized_group":"D","slot_no":3,"members":["Hồ Sỹ Dũng","Trần Thị Mai Hương"],"unit":"PTSC Marine","pdf_page":32,"kind":"pair","status":"draft"}
  ]$pickleball_rows$::jsonb;
  v_pdf_sha256 text := 'b9c2e2c7fdb2b0b58eac479d905ac5b7e1241c22621c59ba318c0c97c0eac032';
begin
  if not exists (select 1 from public.tenants where id = v_tenant_id and slug = 'ptsc2026' and archived_at is null) then
    raise exception 'PTSC: không tìm thấy tenant';
  end if;
  if jsonb_array_length(v_rows) <> 166 then
    raise exception 'PTSC: roster pickleball phải có đúng 166 slot';
  end if;

  insert into public.source_files (tenant_id, raw_filename, sha256, source_kind, parser_version, template_version, metadata)
  values (
    v_tenant_id,
    'PICKLEBALL PTSC.pdf',
    v_pdf_sha256,
    'pdf',
    'ptsc-pickleball-pdf-manual-v1',
    1,
    jsonb_build_object(
      'pages', 33,
      'categories', 10,
      'slots', 166,
      'policy', 'fill_placeholders_only',
      'scope', 'pickleball thường; không bao gồm pickleball lãnh đạo'
    )
  )
  on conflict (tenant_id, raw_filename, sha256) do update set
    parser_version = excluded.parser_version,
    template_version = excluded.template_version,
    metadata = excluded.metadata;

  update public.tournaments
  set source_metadata = coalesce(source_metadata, '{}'::jsonb) || jsonb_build_object(
    'roster_source', jsonb_build_object(
      'file', 'PICKLEBALL PTSC.pdf',
      'sha256', v_pdf_sha256,
      'pages', 33,
      'slots', 166,
      'policy', 'fill_placeholders_only'
    )
  )
  where tenant_id = v_tenant_id
    and category_code in (
      'PB-DON-NAM45', 'PB-DON-NAM46', 'PB-DON-NU45', 'PB-DON-NU46',
      'PB-DOI-NAM45', 'PB-DOI-NAM46', 'PB-DOI-NU45', 'PB-DOI-NU46',
      'PB-DOI-NAMNU45', 'PB-DOI-NAMNU46'
    )
    and archived_at is null;

  for v_row in select value from jsonb_array_elements(v_rows) loop
    if not exists (
      select 1
      from public.entries
      where tenant_id = v_tenant_id
        and source_key = format('%s|%s|%s', v_row->>'category_code', upper(v_row->>'normalized_group'), v_row->>'slot_no')
        and archived_at is null
        and nullif(trim(name_vi), '') is not null
        and name_vi not like 'Chờ nhập · %'
    ) then
      perform private.upsert_ptsc_position(
        v_tenant_id,
        v_row || jsonb_build_object(
          'sport_slug', 'pickleball',
          'note', format('Nguồn: PICKLEBALL PTSC.pdf, trang %s', v_row->>'pdf_page')
        ),
        null
      );
    end if;
  end loop;

  update public.group_entries group_entry
  set source_page = (source_row.value->>'pdf_page')::integer,
      source_note = format('Nguồn: PICKLEBALL PTSC.pdf, trang %s', source_row.value->>'pdf_page')
  from jsonb_array_elements(v_rows) source_row(value)
  where group_entry.tenant_id = v_tenant_id
    and group_entry.source_key = format('%s|%s|%s', source_row.value->>'category_code', upper(source_row.value->>'normalized_group'), source_row.value->>'slot_no');
end
$migration$;
