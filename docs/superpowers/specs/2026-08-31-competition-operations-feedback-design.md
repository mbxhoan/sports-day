# Competition Operations Feedback Design

## Goal

Khôi phục lịch thi đấu đầy đủ cho 8 môn, hiển thị bảng điểm dễ đọc, cho phép Ban Tổ chức nhập thứ hạng và chỉ số thủ công, thêm tìm kiếm nhanh cho public/admin, và sửa kết quả ngay trên bracket mà không làm sai dữ liệu đang public.

## Scope

- Áp dụng cho tenant `petrovietnam2026` trong app `petrovietnam2026`.
- Public: lịch toàn giải, trang từng môn, bảng đấu, bảng điểm và tìm kiếm.
- Admin: dữ liệu từng môn, bảng điểm, lịch, kết quả, tìm kiếm và chỉnh kết quả bracket.
- Không tự tạo fixture mới, không xoá dữ liệu, không sửa migration cũ, không thêm dependency.
- PTSC giữ nguyên hành vi và dữ liệu riêng.

## Current Findings

- `ScheduleView` loại các môn trong `isManualSport`, nên Cờ vua, Cờ tướng, Bơi lội và Điền kinh biến mất khỏi lịch.
- `SportPage` và trang admin cũng loại tab lịch của các môn này.
- Bảng `public.standings` đã có `played`, `won`, `drawn`, `lost`, `score_for`, `score_against`, `points`, `rank`, nhưng public chỉ hiển thị một phần và RPC manual chỉ lưu `points`, `rank`.
- `CompetitionBoard` đã có dữ liệu trận và link admin đến editor bên dưới; chưa có popup editor.
- Chưa có search control dùng chung.

## Approved Behavior

### Standings

Public hiển thị theo thứ tự:

`Hạng | Đội/VĐV | P | Thắng | Hòa | Thua | +/- | Điểm`

Trong đó `+/-` luôn được tính là `score_for - score_against`. Ban Tổ chức nhập các trường nguồn gồm P, Thắng, Hòa, Thua, `score_for`, `score_against`, Điểm và Hạng. Hạng thủ công là nguồn hiển thị chính; hệ thống không tự ghi đè hạng thủ công khi lưu kết quả trận.

### Schedule

- `/schedule` hiển thị fixture hiện có của cả 8 môn.
- Trang chi tiết cả 8 môn có tab lịch và bảng đấu/kết quả phù hợp.
- Admin có thể quản lý lịch và fixture của cả 8 môn.
- Fixture thiếu giờ hoặc sân hiển thị `Chưa xếp lịch`; hệ thống không suy đoán.

### Search

- Public đặt combobox tại `/schedule`.
- Admin đặt combobox trong trang quản lý từng môn.
- Gợi ý gồm `VĐV`, `Đội/cặp`, `Trận đấu`.
- Gõ và chọn gợi ý lọc danh sách hiện tại; hỗ trợ phím mũi tên, Enter và Escape.
- Dữ liệu được giới hạn theo tenant hiện tại trước khi lọc.
- Dùng control native/custom nhẹ, không thêm Select2 hoặc dependency mới.

### Bracket editing

- Chỉ admin được sửa trên bracket loại trực tiếp và vòng bảng + loại trực tiếp.
- Bấm trận mở native `<dialog>`.
- Popup cho sửa đội/cặp, điểm, trạng thái, đội thắng và ghi chú.
- Lưu qua `save_fixture_result` hiện có; đồng bộ nhánh sau qua RPC hiện có.
- Reset dữ liệu vòng sau vẫn yêu cầu xác nhận như hiện tại.
- Public chỉ xem bracket.

## Architecture

### Data layer

Mở rộng `save_manual_standings(uuid, uuid, jsonb)` bằng migration additive, giữ nguyên signature RPC để không phá client. Mỗi row JSON nhận `entry_id`, `played`, `won`, `drawn`, `lost`, `score_for`, `score_against`, `points`, `rank`; RPC kiểm tra số nguyên không âm, số điểm hợp lệ, entry đúng tournament/group, rank không trùng trong group, rồi upsert toàn bộ dữ liệu trong một transaction.

Không thêm trường cho `+/-`; public và admin tính từ `score_for` và `score_against` tại lúc render. Kết quả fixture vẫn đi qua `save_fixture_result`, không tự đồng bộ ngược vào standings manual.

### Public UI

Tách helper hiển thị standing để dùng cho bảng group, Swiss, race và bảng đấu. Bỏ bộ lọc `isManualSport` khỏi nguồn lịch public; giữ `isManualSport` chỉ cho logic format/render phù hợp của từng môn. Dùng dữ liệu fixture/tournament hiện có để dựng lịch.

### Admin UI

Mở tab schedule cho mọi môn. Manual standings editor hiển thị và gửi đủ các field standings. Bracket admin nhận server action `saveFixtureResult` qua boundary phù hợp để popup dùng lại validation/RPC hiện tại; không tạo endpoint ghi dữ liệu thứ hai.

### Search UI

Tạo một client combobox nhỏ nhận danh sách suggestion đã được tenant-scope từ server và callback lọc. Search không gọi DB theo từng phím, không dùng query string cho dữ liệu nhạy cảm, và không thay đổi quyền đọc.

## Safety and Error Handling

- Giữ nguyên tenant checks, admin authentication và server-side relation validation.
- Validate mọi số standings ở server; reject rank trùng, entry ngoài tournament/group và giá trị âm.
- Không cho popup lưu trận nếu thiếu hai entry khác nhau, điểm âm, trạng thái/winner không hợp lệ.
- Nếu RPC lỗi, giữ nguyên dữ liệu và hiển thị lỗi form hiện có.
- Không reset hoặc xoá fixture phụ thuộc tự động.
- Migration chỉ additive; rollback vận hành bằng migration kế tiếp nếu cần, không dùng destructive reset production.

## Verification

- Unit/regression tests cho `+/-`, full standings payload, rank priority, schedule inclusion, search suggestion filtering và popup payload.
- Local Supabase migration reset kiểm tra cả hai tenant: PVN có thay đổi, PTSC không thay đổi.
- Browser smoke test: `/schedule`, 4 trang manual sport, standings, admin sport results, bracket dialog; console không có error.
- Chạy `npm test`, `npm run lint`, `npm run typecheck`, `npm run build`, `git diff --check`.
- Chụp screenshot public schedule/standings và admin bracket popup sau khi test.

## Acceptance Criteria

1. Public hiển thị đủ cột `Hạng`, `Đội/VĐV`, `P`, `Thắng`, `Hòa`, `Thua`, `+/-`, `Điểm`.
2. Admin nhập và lưu được toàn bộ chỉ số; reload vẫn giữ đúng dữ liệu.
3. Hạng thủ công không bị kết quả trận ghi đè.
4. Lịch hiển thị fixture hiện có của Cờ vua, Cờ tướng, Bơi lội và Điền kinh.
5. Search public/admin gợi ý đúng loại và lọc đúng dữ liệu tenant.
6. Admin sửa được kết quả từ popup bracket; public không có quyền sửa.
7. Không có migration destructive, dependency mới, lỗi console hoặc test regression.
