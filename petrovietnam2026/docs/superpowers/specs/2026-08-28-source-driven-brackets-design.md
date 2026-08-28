# Bracket và bảng đấu theo tài liệu nguồn

## Mục tiêu

Hiển thị đầy đủ mô hình thi đấu của từng hạng mục theo PDF/Excel trong `assets/sports`, đồng thời cho admin cập nhật kết quả trực tiếp trên cùng bố cục. Các vòng sau được tạo sẵn và tự điền đội/cặp/cá nhân khi kết quả hoặc thứ hạng nguồn đã được xác nhận.

Phạm vi gồm trang public, giao diện admin, dữ liệu seed, quy tắc thăng hạng, môn loại trực tiếp, môn hệ Thụy Sĩ và môn tính thành tích. Không thêm thư viện bracket, realtime hoặc nhập chi tiết từng set.

## Nguồn dữ liệu

- PDF là nguồn ưu tiên cho tên, vị trí và hình dạng đang công bố.
- Excel bổ sung cấu trúc ô hoặc dữ liệu PDF không đọc rõ.
- Khi hai nguồn mâu thuẫn, vẫn import lên production theo PDF và ghi cảnh báo vào metadata nguồn để admin tinh chỉnh sau.
- Mọi hạng mục phải lưu tên file, checksum, trang/sheet và ghi chú đối soát.
- Seed dùng ID ổn định và không ghi đè dữ liệu admin đã chỉnh khi chạy lại.
- Không tự đoán giờ, sân, người thắng, thứ hạng hoặc tiêu chí phụ không có trong nguồn.

## Mô hình thi đấu

Mỗi `tournament` có một `competition_mode`:

- `knockout`: loại trực tiếp.
- `group_knockout`: vòng bảng rồi loại trực tiếp.
- `round_robin`: thi đấu vòng tròn, không ép thành nhánh.
- `swiss`: hệ Thụy Sĩ cho Cờ vua/Cờ tướng.
- `race`: Bơi lội/Điền kinh theo làn, thành tích và thứ hạng.

Giữ `fixtures` và `fixture_entries` làm dữ liệu trận và kết quả. Thêm `fixture_slots`, mỗi trận tối đa hai ô `home` và `away`. Mỗi ô có đúng một loại nguồn:

- `entry`: đội/cặp/cá nhân cố định.
- `group_rank`: thứ hạng của một bảng, ví dụ `Nhất A` hoặc `Nhì B`.
- `fixture_winner`: người thắng một trận trước.
- `fixture_loser`: người thua một trận trước, dùng cho H3.
- `bye`: nhánh trống được công bố trong nguồn.

Một slot lưu `fixture_id`, `side`, `source_kind`, khóa nguồn tương ứng và nhãn VI/EN khi cần giữ nguyên ký hiệu nguồn. Ràng buộc database bảo đảm duy nhất `(fixture_id, side)`, cùng tenant, cùng hạng mục và không tạo chu trình. `fixture_entries` chỉ chứa đối thủ đã được xác định; khi chưa xác định, UI hiển thị nhãn nguồn của slot. `next_fixture_id` hiện có không còn là nguồn quan hệ chính nhưng chưa bị xóa trong migration này để tránh thay đổi phá vỡ dữ liệu cũ.

## Tạo và điền bracket

- Import tạo sẵn toàn bộ trận, vòng, vị trí, bye, H3 và đường nối theo tài liệu nguồn.
- Vòng sau luôn hiện dù chưa biết người thi đấu.
- Khi một trận hoàn tất với người thắng duy nhất, hệ thống điền người thắng hoặc người thua vào mọi slot phụ thuộc.
- Với `group_rank`, chỉ tự điền khi mọi trận thuộc bảng đã hoàn tất và thứ hạng cần dùng là duy nhất.
- Nếu bằng điểm, thiếu tiêu chí phụ hoặc dữ liệu chưa đủ, slot giữ nhãn nguồn và yêu cầu admin xác nhận thứ hạng.
- Có trận H3 trong nguồn thì hai người thua bán kết được đưa vào H3.
- Nguồn ghi hai giải ba nhưng không có H3 thì không tạo trận giả; hai người thua bán kết cùng nhận huy chương đồng.
- Bye được giữ đúng vị trí. Hệ thống chỉ tự chuyển người qua bye khi nguồn xác định rõ người ở nhánh còn lại.

## Lưu và sửa kết quả

Admin nhập hai tỷ số chung cuộc, trạng thái, giờ, sân và ghi chú tùy chọn. Không nhập chi tiết từng set trong phạm vi này. Người thắng được suy ra khi trận `completed` có hai tỷ số hợp lệ và khác nhau; admin có thể xác nhận thủ công khi thể thức yêu cầu.

Một RPC transaction thực hiện toàn bộ thao tác:

1. Khóa trận và các slot phụ thuộc.
2. Xác thực đối thủ thuộc đúng hạng mục.
3. Lưu tỷ số, trạng thái và người thắng.
4. Tính lại bảng xếp hạng nếu hạng mục có vòng bảng.
5. Điền hoặc gỡ các `fixture_entries` phụ thuộc.
6. Cập nhật huy chương khi kết quả đã đủ điều kiện.

Nếu sửa kết quả khi các trận phụ thuộc chưa bắt đầu và chưa có tỷ số, hệ thống tự đồng bộ lại nhánh. Nếu bất kỳ trận phụ thuộc nào đã `live`, `completed`, có tỷ số hoặc người thắng, thay đổi bị chặn. Admin phải dùng luồng mở lại/reset riêng, xem trước danh sách dữ liệu bị ảnh hưởng và xác nhận rõ ràng trước khi xóa kết quả vòng sau.

## Vòng bảng và xếp hạng

Mỗi hạng mục đối kháng có cấu hình điểm thắng/hòa/thua trước khi thi đấu. Hệ thống tự tính P/W/D/L, điểm ghi được, điểm bị ghi và tổng điểm. Khi bằng điểm hoặc thiếu luật phụ, admin xác nhận `rank`; hệ thống không tự suy diễn tiêu chí phụ.

Bracket chỉ nhận `Nhất/Nhì bảng` sau khi bảng hoàn tất và các hạng cần dùng đã xác định duy nhất.

## Cờ vua và Cờ tướng

- Không tự sinh cặp đấu hệ Thụy Sĩ.
- Admin nhập hoặc chỉnh cặp đấu từng vòng theo Ban tổ chức.
- Hệ thống tự cộng thắng, hòa, thua và điểm.
- Hệ số phụ và thứ hạng cuối do admin nhập hoặc xác nhận.
- Public và admin hiển thị bảng từng vòng cùng bảng xếp hạng, không vẽ bracket giả.

## Bơi lội và Điền kinh

- Admin nhập làn, thành tích hiển thị, giá trị thời gian chuẩn hóa và trạng thái `finished`, `DNS`, `DNF` hoặc `DSQ`.
- Thành tích hợp lệ tự xếp từ thấp đến cao.
- Hòa thành tích hoặc trường hợp có phạt cần admin xác nhận thứ hạng.
- Public và admin dùng bảng làn/thành tích/xếp hạng theo tài liệu nguồn.

## Giao diện public

Trang lịch có ba chế độ: `Lịch thi đấu`, `Theo đội` và `Bảng đấu`.

Chế độ `Bảng đấu` xếp toàn bộ hạng mục thành một trang dài theo thứ tự môn/hạng mục trong dữ liệu nguồn. Bộ lọc môn, hạng mục và trạng thái chỉ thu hẹp nội dung khi người dùng cần; không bắt buộc chọn từng hạng mục.

- `group_knockout`: bảng xếp hạng trước, bracket đầy đủ phía dưới.
- `knockout`: bracket đầy đủ.
- `round_robin`: bảng trận và xếp hạng.
- `swiss`: bảng vòng đấu và xếp hạng.
- `race`: bảng làn, thành tích và xếp hạng.

Card trận hiển thị mã trận/vòng, giờ, sân, hai đối thủ và tỷ số. Dữ liệu chưa xác định hiển thị nhãn nguồn như `Nhất A`, `Thắng trận 5`; giờ/sân chưa có hiển thị `Chờ xếp lịch`.

Desktop dùng các cột vòng và đường nối đúng quan hệ slot. Mobile cuộn dọc toàn trang và vuốt ngang trong từng bracket; không thu nhỏ chữ hoặc cắt mất tên. Bản in/PDF dùng bố cục ngang; mỗi hạng mục bắt đầu trên trang mới, bracket được scale vừa chiều ngang và không ngắt giữa một card trận.

Trang public đang mở tự làm mới dữ liệu mỗi 30 giây và có nút cập nhật thủ công. Không dùng Supabase Realtime trong giai đoạn này.

## Giao diện admin

Mỗi môn có mục `Bảng đấu & kết quả`, dùng cùng renderer với public và thêm điều khiển chỉnh sửa.

- Nhấn card trận mở panel gọn để sửa đối thủ, hai tỷ số, trạng thái, giờ, sân và ghi chú.
- Bảng vòng loại, hệ Thụy Sĩ và môn tính giờ cho phép nhập theo hàng rồi lưu rõ ràng.
- Chế độ `Sửa cấu trúc` cho phép đổi seed, nguồn slot, bye và đường đi khi hạng mục chưa có trận `live`, `completed`, tỷ số hoặc người thắng.
- Sau khi có kết quả, cấu trúc bị khóa. Mở lại/reset phải hiển thị tác động và yêu cầu xác nhận.
- Admin không nhập UUID, `next_fixture_id` hoặc JSON kỹ thuật.
- Sau khi lưu, giao diện admin cập nhật ngay và các route public được revalidate.

## Kiểm soát lỗi và tính nhất quán

- Transaction khóa hàng để tránh hai admin cập nhật cùng trận đồng thời.
- Database từ chối slot thiếu nguồn, nhiều nguồn, khác hạng mục hoặc tạo vòng lặp.
- Không cho hoàn tất trận khi hai đối thủ chưa xác định, tỷ số không hợp lệ hoặc người thắng không thuộc trận.
- Không tự điền slot khi thứ hạng bảng chưa duy nhất.
- Lỗi lưu phải giữ nguyên dữ liệu trước transaction và trả thông báo có thể hành động.
- Import nguồn có cảnh báo không chặn production nhưng phải hiển thị ghi chú cho admin.

## Kiểm thử và nghiệm thu

Kiểm thử dữ liệu tối thiểu bao phủ:

- Seed đủ mọi hạng mục và số trận/slot khớp PDF ưu tiên.
- Đội, cặp và cá nhân đều dùng được trong slot.
- Bye, `Nhất/Nhì bảng`, người thắng, người thua, H3 và hai huy chương đồng.
- Tự điền vòng sau và gỡ/điền lại khi sửa kết quả chưa có phụ thuộc đã thi đấu.
- Chặn sửa khi trận phụ thuộc đã có kết quả; reset chỉ xóa đúng phạm vi đã xác nhận.
- Hòa thứ hạng, thiếu luật phụ, DNS, DNF, DSQ và hòa thành tích.
- Cấm chu trình và cấm nối khác hạng mục/tenant.

Kiểm tra giao diện tại desktop, tablet và mobile cho trang dài, cuộn ngang từng bracket, tên dài, đường nối, trạng thái trống và bản in PDF. Kiểm tra admin nhập kết quả trên từng loại mô hình, tự làm mới public sau tối đa 30 giây, rồi chạy test, lint, typecheck và production build.

## Triển khai

1. Tạo migration và seed idempotent.
2. Reset database local, đối soát toàn bộ PDF/Excel và chạy kiểm thử.
3. Kiểm tra trực quan public/admin và bản in.
4. Backup production.
5. Chạy migration production, import seed và kiểm tra số lượng.
6. Smoke test luồng public, admin, kết quả, thăng hạng và reset.

Không xóa schema cũ hoặc dữ liệu production trong rollout này. Mọi thay đổi phá vỡ chỉ được xem xét sau khi dữ liệu mới đã vận hành ổn định.
