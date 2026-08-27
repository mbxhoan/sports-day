Sau khi hoàn tất hãy chạy test cú pháp, cấu trúc, lập trình an toàn, tránh rủi ro hay phát sinh lỗi build/dev.
---
Đọc quét qua webapp cập nhật lại file @AGENTS.md giúp tôi sao để khi vibe code không tốn nhiều token, tối ưu đọc
---
1. Tôi vừa cập nhật @kv-mobile.png để làm KV cho mobile view, scale cho phù hợp mobile view và tôi muốn bạn thay đổi theme color, style của toàn bộ website theo @theme.png giúp tôi. 
2. Triển khai full tính năng admin giúp tôi, phía admin (CẦN SONG NGỮ):
- chỉnh sửa nội dung, hình ảnh web sites/dashboard/...
- CRUD thông tin footer, liên hệ
- CRUD môn thể thao (có thông tin, thể lệ, đội đấu, vận động viên đội đấu, đội trường của đội đấu, lịch đấu, khung giờ đấu, bảng đấu, hạng mục thi đấu,..)
- CRUD leaderboard
- CRUD lịch đấu, trận đấu, giải (tournaments)
- chỉnh sửa bộ timer countdown trang chủ
3. Kết quả giải đấu sẽ được admin cập nhật chọn đội tháng và tỉ số thực tế để tạo bảng xếp hạng.
4. hero path (kv) cho desktop và mobile nên cần cho phép upload và view dạng file thay vì text input @issue1.png.
5. Không biết organization ID là gì để nhập: @issue2.png nên cho select theo đội (select danh sách đội). 
6. Nên chi theo môn thể thao ví dụ môn A có những hạng mục A1, A2, A3, có các đội/đơn vị AA1 AA2 AA3,... trong mỗi đội đó có những vận động viên nào, cặp đấu nào, mỗi môn có những giải nào, mỗi giải có địa điểm nào, có lịch đấu như thế nào, giải đấu kết thúc thì có bảng xếp hạng và giải thưởng cho giải đó được admin cập nhật,... => nên ưu tiên giao diện lưới dạng quản lý có tổ chứ chứ không để tràn làn gộp hết lại như hiện tại rất khó quản lý và khó để thêm xoá sửa. ngoài ra mỗi môn thể thao còn có lưu hình ảnh nữa (Thư viện ảnh), ảnh thì public dạng lưới cho người dùng xem, popup, zoom và download xuống. admin có chỗ upload 1 hoặc nhiều ảnh vào thư viện ảnh của môn đó, có thể note thêm metadata/thêm nhóm ảnh để người dùng public có thể lọc theo nhóm xem dễ hơn.
7. [QUAN TRỌNG] Sau khi đã hoàn thiện kiến trúc rồi thì đọc vào trong các file (.pdf đa số) trong `/assets/sports` là file danh sách môn, đội thi của môn, hạng mục thi của môn, vận động viên từng đội, các cặp đấu, thể thức thi của môn, cách tính tỉ số, vị trí sân thi của giải, bảng đấu của giải,... tất tần tật, và tôi cần bạn đọc quét qua một cách chính xác và đầy đủ rồi bạn tạo seeding data để đưa tất tần tật một cách chính xác và đầy đủ vào trong phần mềm xài được ngay luôn. Fill vô đầy đủ thông tin của bộ môn luôn, như hiện tại ví dụ như môn "Pickleball" đã có thông tin đầy đủ rồi trong `/assets/sports` nhưng chưa có thông tin môn, đội/vđv đấu, khung giờ đấu, lịch đấu hay bảng đấu @issue3.png.
#### => Hãy đặt câu hỏi cho tôi khi nếu có điểm nào chưa rõ cho đến khi bạn tự tin 100% hiểu rõ về yêu cầu này. Nếu bất kì rủi ro nào thì cũng nên cho tôi biết, nếu bạn có đề xuất giải pháp xử lý an toàn thì cũng cho tôi biết để xử lý.
---
1. style nên có chút màu xanh lá sáng giống phía trên của @theme.png giúp tôi. 
2. tôi cần thể hiện các hạng mục trên ô môn thể thao ở grid lưới danh sách môn thể thao giống như @sports.png
3. tôi cần thông tin chi tiết, mô tả, thể lệ chi tiết theo chi tiết thông tin môn thể thao như là @sports-detail.png
---
