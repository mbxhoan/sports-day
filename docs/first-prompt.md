@Ponytail $caveman Vibe Code Clone website gốc: "https://ptsc.pikoclub.com/" thành một web y chang 100% về giao diện và tính năng, có nội dung và KV khác (`assets/kv.png`), có trang admin đăng nhập cho phép Thêm/Xoá/Sửa nội dung.

1. Quét qua hết tất cả menu, trang menu, trang submenu, url, buttons, copy y chang về icons, buttons, font, màu sắc, size, style,...
2.1. xem thêm vài giao diện tham khảo từ screenshot web gốc trong `/assets/clone`.
2.2. phân tích cấu trúc dữ liệu và lên kiến trúc quản lý dữ liệu y chang, hãy xem tech stack của web gốc đang dùng là gì, hosting ở đâu, có thể dùng nextjs + supabase + vercel hosting để triển khai nhanh và hiệu quả, local dev thì run supabase local trước rồi setup supabase online sau. (tạo seeding đầy đủ).
3. triển khai UI responsive desktop, tablet/ipad, iphone/mobile mượt, không bể, không tràn UI, cân đối hài hào, y chang web gốc 100%.
4. đảm bảo giao diện thân thiện, dễ dùang (admin), tối ưu diện tích, font chữ nhỏ - vừa, hạn chế header lớn, tránh AI slop.
5. fill sẵn data môn thể thao (bảng đấu, thời gian, đội, thành viên,...) theo folder `/assets/sports` + thông tin môn thể thao hay các thông tin fixed thì copy từ web gốc vào lưu trên database. (ƯU TIÊN)
6. triển khai song ngữ.
7. tính năng cần có từ phía admin (CẦN SONG NGỮ):
- chỉnh sửa nội dung, hình ảnh web sites/dashboard/...
- CRUD thông tin footer, liên hệ
- CRUD môn thể thao (có thông tin, thể lệ, đội đấu, thành viên đội đấu, đội trường của đội đấu, lịch đấu, khung giờ đấu, bảng đấu, hạng mục thi đấu,..)
- CRUD leaderboard
- CRUD lịch đấu, trận đấu, giải (tournaments)
- chỉnh sửa bộ timer countdown trang chủ

#### => Ưu tiên chia giai đoạn xử lý an toàn, ổn định, đảm bảo vận hành và web look y chang web gốc 100%. Ưu tiên 1 -> 6 để cho khách hàng xem trước (seeding theo file), làm 7 sau vẫn được.

#### => Hãy đặt câu hỏi cho tôi khi nếu có điểm nào chưa rõ cho đến khi bạn tự tin 100% hiểu rõ về yêu cầu này. Nếu bất kì rủi ro nào thì cũng nên cho tôi biết, nếu bạn có đề xuất giải pháp xử lý an toàn thì cũng cho tôi biết để xử lý.
