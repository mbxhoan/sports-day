# Prompt cho Codex: triển khai template Excel PTSC 2026 vào phần mềm

> Cách dùng: đính kèm workbook `/docs/PTSC-2026-Template-Quan-Ly-11-Mon.xlsx`, tài liệu `/ptsc/docs/THONG-TIN-11-MON-THI-2026-CAP-NHAT.md` và repository phần mềm, sau đó gửi nguyên prompt dưới đây cho Codex.

---

Bạn là senior full-stack engineer kiêm data architect. Hãy tích hợp hoàn chỉnh template Excel quản lý Hội thao PTSC 2026 vào phần mềm hiện có trong repository này. Mục tiêu là người dùng không có chuyên môn kỹ thuật có thể import, xem trước, sửa, bổ sung và quản lý dữ liệu 11 môn an toàn; thao tác import phải **idempotent**, có audit và không tạo dữ liệu trùng khi người dùng tải lại cùng file.

## 1. Tài liệu và thứ tự ưu tiên

Các đầu vào bắt buộc:

1. Workbook `/docs/PTSC-2026-Template-Quan-Ly-11-Mon.xlsx`.
2. Tài liệu nghiệp vụ `/ptsc/docs/THONG-TIN-11-MON-THI-2026-CAP-NHAT.md`.
3. Codebase, schema database, quy ước và tài liệu hiện có của repository.

Thứ tự ưu tiên khi có khác biệt:

1. Các xác nhận chính thức ghi trong tài liệu Markdown.
2. Danh mục và dữ liệu trong workbook phiên bản 13/09/2026.
3. PDF/sơ đồ nguồn.
4. Không tự suy đoán dữ liệu thi đấu còn mâu thuẫn; hiển thị trạng thái chờ xác nhận.

Các quy tắc nghiệp vụ đã chốt:

- Hạng mục Cầu lông chỉ có một bảng thi đấu vòng tròn và xếp hạng trực tiếp.
- Hà Thị Thảo Trinh thuộc Điền kinh Nữ từ 45 tuổi trở xuống - 5 km.
- Nhóm tuổi `46+`, “từ 46 tuổi trở lên” và “trên 46 tuổi” trong bộ nguồn này đều được hiểu là tuổi tối thiểu 46, bao gồm đúng 46 tuổi.
- Bóng đá nữ có 5 đội, thi đấu vòng tròn đủ 10 trận; lịch mới không còn cặp lặp.
- Tennis trang 6 là Đôi nam từ 46 tuổi trở lên. Mã chuẩn là `TEN-DOI-NAM46`; mã cũ `TEN-DOI-NAM46-CHECK` là alias phải được migrate/upsert vào cùng một hạng mục, tuyệt đối không tạo hạng mục thứ hai.
- Pickleball Đơn nam ≤45 và Đôi nam ≤45 dùng đủ bảng A-H theo nhánh mới.
- Pickleball Đôi nam 46+ đang có lỗi nguồn: sơ đồ ghi `Seed 7` hai lần tại Tứ kết 3. Không tự động phát hành nhánh này cho đến khi được xác nhận. Nếu cần hiển thị bản dự kiến, ghi rõ suy luận là `Seed 2 - Seed 7` và để trạng thái `pending_confirmation`.

## 2. Cách làm việc

Trước khi sửa code:

1. Đọc `AGENTS.md`, README, tài liệu kiến trúc, migration, schema, convention, test và CI của repository.
2. Xác định framework, database, ORM, authentication, phân quyền và pattern hiện tại. Tận dụng kiến trúc sẵn có; không dựng một hệ thống song song.
3. Kiểm tra working tree và giữ nguyên mọi thay đổi không liên quan của người dùng.
4. Trình bày ngắn gọn kế hoạch, schema/migration dự kiến, các file sẽ sửa và rủi ro dữ liệu.
5. Chỉ hỏi khi thiếu thông tin thực sự làm thay đổi kiến trúc hoặc quyền thao tác. Nếu chi tiết nhỏ có thể suy ra an toàn từ codebase thì tiếp tục và ghi lại giả định.

Sau đó triển khai trọn luồng, không dừng ở mockup hay pseudocode. Dùng migration có thể rollback, không xóa dữ liệu hiện hữu và không chạy thao tác production phá hủy dữ liệu.

## 3. Phạm vi nghiệp vụ cần hỗ trợ

Phần mềm phải quản lý được:

- Kỳ hội thao/sự kiện.
- 11 môn thi đấu.
- 45 hạng mục hiện tại và hạng mục bổ sung trong tương lai.
- Đơn vị, VĐV, đội, đôi và thành viên dự bị.
- Nhóm tuổi, giới tính, cự ly, loại suất thi đấu: cá nhân/đôi/đội.
- Bảng đấu, vị trí trong bảng, lịch, trận đấu, kết quả và bảng xếp hạng.
- Các thể thức:
  - xếp hạng trực tiếp theo thời gian/thành tích;
  - một bảng vòng tròn;
  - nhiều bảng vòng tròn rồi vào loại trực tiếp;
  - loại trực tiếp từ đầu;
  - nhánh có bye;
  - chọn nhất/nhì bảng hoặc chọn đội nhì có thành tích tốt nhất;
  - xếp seed rồi tạo tứ kết/bán kết/chung kết.
- Trạng thái dữ liệu: draft, active, pending_confirmation, archived.
- Nguồn dữ liệu, phiên import, lỗi từng dòng, người thực hiện và lịch sử thay đổi.

Không hard-code riêng 45 hạng mục trong UI. Thiết kế cấu hình để thêm hạng mục, bảng, số suất và quy tắc nhánh mà không phải sửa source code.

## 4. Mô hình dữ liệu tối thiểu

Điều chỉnh tên bảng theo convention của repository, nhưng cần thể hiện đầy đủ các khái niệm sau:

- `events`
- `sports`
- `categories`
- `units`
- `people` hoặc `athletes`
- `teams` nếu hệ thống đã phân biệt đội tổ chức với suất thi đấu
- `entries`: một suất cá nhân/đôi/đội trong một hạng mục
- `entry_members`: thành viên chính thức/dự bị, có thứ tự thành viên
- `groups` hoặc `pools`
- `group_entries`: vị trí STT của entry trong bảng
- `competition_formats` và/hoặc `qualification_rules`
- `brackets`, `bracket_rounds`, `matches`, `match_sources`
- `schedules` nếu lịch tách khỏi trận
- `results`/`standings`
- `source_files`
- `import_batches`
- `import_rows`
- `audit_logs`

Yêu cầu schema:

- Dùng khóa chính nội bộ ổn định, ưu tiên UUID nếu codebase đang dùng UUID.
- `categories.code` là duy nhất trong phạm vi event.
- Khóa tự nhiên của một suất từ Excel là `event + category_code + normalized_group + slot_no`.
- `normalized_group` chuyển trống hoặc `-` thành `X`; bảng chữ cái chuẩn hóa uppercase.
- Tạo unique constraint ở database cho khóa tự nhiên, không chỉ kiểm tra ở application.
- Một người có thể dự nhiều hạng mục; không gộp người chỉ dựa trên tên. Nếu chưa có mã nhân sự, dùng mã nội bộ và cơ chế gợi ý trùng, yêu cầu người dùng xác nhận trước khi merge.
- Lưu Unicode chuẩn NFC; trim khoảng trắng; không làm mất dấu tiếng Việt.
- Có `created_at`, `updated_at`, `created_by`, `updated_by` và cơ chế optimistic locking/version nếu hệ thống hỗ trợ.
- Dữ liệu bị bỏ khỏi file import không được tự động xóa. Mặc định chỉ báo `missing_from_source`; chỉ archive khi người dùng xác nhận trong UI.

## 5. Ánh xạ workbook

### Sheet `TONG_QUAN`

- Chỉ dùng để hiển thị/hướng dẫn; không import thành dữ liệu nghiệp vụ.

### Sheet `HANG_MUC`

- Header ở hàng 5; dữ liệu từ hàng 6.
- Cột:
  - A: Mã hạng mục
  - B: Mã môn
  - C: Môn
  - D: Tên hạng mục
  - E: Loại
  - F: Cự ly
  - G: Số bảng
  - H: Quy mô
  - I: Thể thức/nhánh
  - J: Trạng thái
  - K: Ghi chú nguồn
  - L: Kiểm tra

### 11 sheet môn

- Dữ liệu từ hàng 8; header ở hàng 7.
- Các sheet: `01_Boi`, `02_BongBan`, `03_BD_Nam_A`, `04_BD_Nam_B`, `05_BD_Nu`, `06_CauLong`, `07_DienKinh`, `08_KeoCo`, `09_PB_LanhDao`, `10_Pickleball`, `11_Tennis`.
- Cột:
  - A: ID tự động
  - B: Mã hạng mục
  - C: Bảng
  - D: STT
  - E-H: VĐV/đội/thành viên 1-4
  - I: Dự bị
  - J: Đơn vị
  - K: Ghi chú
  - L: Trang PDF
  - M: Trạng thái
  - N: Kiểm tra

Quy tắc đọc:

- Không dùng `maxRow` do Excel có các hàng định dạng dự phòng. Chỉ coi dòng là dữ liệu khi có ít nhất mã hạng mục hoặc nội dung nhập liệu.
- Không tin tuyệt đối vào giá trị cache của formula. Tự tính lại ID từ B+C+D rồi so với cột A nếu A có giá trị.
- Chấp nhận ô formula hoặc value, nhưng luôn validation lại ở backend.
- Tách cột I theo dấu `;` thành nhiều thành viên dự bị khi có.
- Với entry loại Đôi, cần đúng 2 thành viên chính thức; loại Đội có thể có tối đa 4 thành viên được biểu diễn trong workbook nhưng schema/API phải hỗ trợ số thành viên mở rộng.
- Các vị trí Pickleball đã có ID/bảng/STT nhưng tên có thể trống; được import ở trạng thái draft/chờ nhập, không coi là lỗi trùng.
- Từ chối commit nếu mã hạng mục không tồn tại, STT không hợp lệ, khóa tự nhiên bị lặp trong chính file, hoặc loại entry không phù hợp với số thành viên.
- Cho phép tải file lỗi về với cột lỗi rõ ràng, số dòng Excel và hướng dẫn sửa bằng tiếng Việt.

## 6. Idempotency bắt buộc

Thiết kế import theo hai lớp:

### Idempotency cấp file/request

- Tính SHA-256 trên bytes của file và lưu cùng event, phiên bản parser và người tải.
- API nhận `Idempotency-Key`; tạo unique constraint phù hợp.
- Nếu cùng `Idempotency-Key` hoặc cùng file hash được gửi lại cho cùng event và parser version, trả lại kết quả batch trước đó; không chạy lại mutation.
- Xử lý race condition bằng transaction và unique constraint, không dựa vào kiểm tra trước rồi insert.

### Idempotency cấp dòng

- Upsert theo khóa tự nhiên `event + category_code + normalized_group + slot_no`.
- Tên VĐV/đơn vị thay đổi phải update entry hiện hữu, không tạo entry mới.
- Chuẩn hóa alias `TEN-DOI-NAM46-CHECK` thành `TEN-DOI-NAM46` trước khi tạo khóa.
- Lưu `source_row_key`, `row_fingerprint` và trạng thái `created/updated/unchanged/error/missing_from_source`.
- Nếu fingerprint không đổi thì không phát sinh UPDATE vô ích và không ghi audit giả.
- Một batch phải chạy trong transaction. Có lỗi chặn thì rollback toàn bộ commit, nhưng vẫn lưu báo cáo validation/batch thất bại theo pattern an toàn của hệ thống.
- Retry sau timeout phải trả về cùng kết quả, không nhân đôi bản ghi, trận hoặc thành viên.

## 7. Luồng giao diện dành cho người không chuyên

Tạo hoặc hoàn thiện màn hình import với luồng:

1. Chọn kỳ hội thao.
2. Kéo-thả/chọn file `.xlsx`.
3. Hệ thống kiểm tra file và hiển thị phiên bản/template nhận diện được.
4. Trang preview chia rõ:
   - bản ghi mới;
   - bản ghi sẽ cập nhật;
   - không thay đổi;
   - cảnh báo;
   - lỗi chặn;
   - dòng có trong hệ thống nhưng thiếu khỏi file.
5. Cho phép lọc theo môn, hạng mục, sheet, trạng thái và tìm theo tên/đơn vị/ID.
6. Hiển thị diff trước/sau cho dòng cập nhật.
7. Nút `Xác nhận import` chỉ bật khi không còn lỗi chặn.
8. Sau import hiển thị thống kê, batch ID, người thực hiện, thời điểm và nút tải báo cáo.
9. Cho phép rollback một batch theo quyền quản trị; rollback phải có audit và không ghi đè thay đổi mới hơn mà không cảnh báo.

UI dùng tiếng Việt, thông báo ngắn, tránh thuật ngữ kỹ thuật. Có trạng thái loading, empty, error và success; hỗ trợ keyboard, focus, contrast và màn hình nhỏ theo design system hiện có.

## 8. API và bảo mật

Tạo/điều chỉnh API theo convention hiện hữu, tối thiểu có:

- upload/validate/preview;
- commit import;
- xem trạng thái và chi tiết batch;
- tải báo cáo;
- rollback batch;
- CRUD cấu hình môn/hạng mục/bảng/quy tắc nhánh với phân quyền.

Yêu cầu:

- Authentication và RBAC: viewer, editor/importer, competition_admin.
- Kiểm tra MIME, extension, kích thước file, tên sheet và workbook structure.
- Không thực thi macro, external link hoặc formula từ file.
- Chống formula injection khi xuất báo cáo Excel/CSV: escape giá trị bắt đầu bằng `=`, `+`, `-`, `@` khi cần.
- Log đủ để truy vết nhưng không log file nhị phân hay dữ liệu nhạy cảm không cần thiết.
- Giới hạn upload/rate limit theo convention của hệ thống.

## 9. Sinh bảng đấu và nhánh đấu

- Không hard-code tên VĐV/đội trong nhánh.
- Biểu diễn nguồn của một vị trí bằng tham chiếu có kiểu, ví dụ `POOL_RANK(A,1)`, `BEST_RUNNER_UP(1)`, `SEED(1)`, `WINNER(match_id)`, `BYE`.
- Chỉ sinh nhánh từ cấu hình hạng mục sau khi danh sách bảng hợp lệ.
- Có validation: mọi bảng được nhánh tham chiếu phải tồn tại; không được bỏ sót bảng G/H; một seed không xuất hiện hai lần trừ khi cấu hình chủ ý cho phép.
- Hạng mục một bảng vòng tròn không tạo bracket knockout.
- Nhánh Pickleball Đôi nam 46+ phải ở trạng thái chờ xác nhận vì lỗi Seed 7 lặp; không tự công bố lịch trận chính thức.
- Lưu version của bracket/rule để thay đổi cấu hình không âm thầm sửa các trận đã có kết quả.

## 10. Test và tiêu chí chấp nhận

Viết unit test, integration test và end-to-end test phù hợp với codebase. Tối thiểu phải chứng minh:

1. Import workbook lần đầu tạo đúng 45 hạng mục và 490 bản ghi/vị trí theo dữ liệu hiện tại, hoặc đưa ra con số tương ứng nếu hệ thống bỏ qua vị trí Pickleball chưa có tên và giải thích rõ.
2. Import lại cùng file và cùng `Idempotency-Key` trả cùng batch result, phát sinh 0 insert, 0 update, 0 duplicate.
3. Import lại cùng file với key mới nhưng hash giống nhau vẫn không mutation.
4. Đổi tên đúng một VĐV trong cùng ID rồi import tạo đúng 1 update, không tạo bản ghi mới.
5. Thêm một dòng có khóa mới tạo đúng 1 insert.
6. Hai dòng trùng `Mã hạng mục + Bảng + STT` trong file bị chặn và báo đúng hàng.
7. Mã hạng mục sai, STT thiếu, nhóm sai hoặc số thành viên không hợp lệ bị validation.
8. Alias Tennis cũ và mã mới luôn trỏ về một category/entry.
9. Hai request import đồng thời không tạo bản ghi trùng.
10. Lỗi giữa transaction rollback toàn bộ mutation.
11. Dòng bị bỏ khỏi file chỉ được báo `missing_from_source`, không tự xóa.
12. Cầu lông một bảng sinh vòng tròn, không sinh nhánh loại trực tiếp.
13. Nhánh Pickleball A-H sử dụng đủ nguồn; validator phát hiện Seed 7 bị lặp ở Đôi nam 46+.
14. Quy tắc tuổi 46+ bao gồm VĐV đúng 46 tuổi.
15. Hà Thị Thảo Trinh được import vào `DK-NU45-5K`, không nằm ở `DK-NAM46-5K` hoặc `DK-NU45-10K`.

Chạy formatter, lint, type-check, migration check, unit/integration/e2e test và build production. Nếu môi trường không cho chạy một bước, ghi rõ lệnh, lỗi và phần đã xác minh thay thế; không tuyên bố thành công nếu chưa kiểm tra.

## 11. Kết quả bàn giao

Sau khi triển khai, trả về:

1. Tóm tắt kiến trúc và luồng import.
2. Danh sách file đã thay đổi.
3. Schema/migration và cách rollback.
4. Mapping Excel → database/API.
5. Cách chạy local, migrate, test và deploy.
6. Kết quả test thực tế, đặc biệt test idempotency.
7. Tài liệu vận hành cho người dùng không chuyên bằng tiếng Việt.
8. Danh sách giả định và điểm còn chờ Ban tổ chức xác nhận.

Không kết thúc khi mới tạo giao diện hoặc parser rời rạc. Công việc chỉ hoàn tất khi luồng upload → preview/diff → validation → commit idempotent → audit/report → xem dữ liệu trong hệ thống hoạt động end-to-end và có test chứng minh.

---

Hãy bắt đầu bằng việc kiểm tra repository và hai file đính kèm, sau đó đưa ra kế hoạch ngắn gọn trước khi triển khai.
