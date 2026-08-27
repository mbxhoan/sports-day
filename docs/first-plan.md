# Clone Hội thao Petrovietnam 2026

## Tóm tắt

- Clone luồng, component, font Lexend, icon, spacing và token màu từ [web gốc](https://ptsc.pikoclub.com/): `#01081D`, `#02183F`, `#C5A35A`, `#0B3382`, border `#162C55`, radius `8px`.
- Dùng [KV mới](/Users/leviackerman/Codes/sports-day/assets/kv.png), brand “Hội thao Petrovietnam 2026”.
- Giữ style gốc nhưng sửa overflow, bảng mobile, ảnh lỗi và touch target.
- Stack: Node 22, Next.js 16 App Router, TypeScript, Tailwind CSS, Supabase local, Vercel sau. Source gốc đã xác nhận Next.js/Turbopack + Vercel qua response headers.
- Không thêm page builder, ORM, bracket/PDF/UI framework. Dùng Server Components, Server Actions, CSS Grid, native print.

## Các giai đoạn

### Phase 1 — Public preview + seed

- Route VI giữ nguyên: `/`, `/leaderboard`, `/gallery`, `/sports`, `/sports/[slug]`, `/schedule`, `/login`.
- Route EN tương ứng dưới `/en`; wrapper mỏng dùng chung Server Components, không thêm thư viện i18n.
- Trang chủ: KV full-width, countdown tới `2026-09-04 07:00 Asia/Ho_Chi_Minh`, thống kê DB, card 8 môn, footer.
- Trang môn giữ 5 tab: Thông tin, Đội/VĐV, Khung giờ, Lịch đấu, Bảng đấu.
- Schedule có filter trạng thái/môn, chế độ lịch/theo đội, bản in để “Xuất PDF” bằng native print.
- Gallery giữ route/filter và empty state; không copy ảnh PTSC cũ.
- Responsive: max-width `1280px`, header `64px`, grid 4/3/2 cột; bảng/bracket cuộn ngang có kiểm soát trên mobile.

### Phase 2 — Admin song ngữ

- Supabase Auth email/password, một `super-admin`.
- `/admin` gồm dashboard và form cố định cho:
  - Hero, countdown, thống kê, footer, liên hệ, gallery.
  - Môn, giải/hạng mục, đơn vị, đội/cặp/cá nhân, thành viên.
  - Địa điểm, sân/làn, bảng đấu, lịch, trận, kết quả, standings, bracket.
  - Leaderboard, huy chương và giải phụ.
- Trường nội dung có VI/EN; nội dung dài dùng Markdown textarea + preview.
- “Xóa” đặt `archived_at`; có khôi phục. Không xóa cứng hay xóa Storage object trong luồng thường.
- Upload PNG/JPEG/WebP vào public Storage bucket; public chỉ đọc, admin mới upload/thay thế.

### Phase 3 — Online

- Tạo Supabase project, đẩy migration sau `db push --dry-run`; không dùng `db reset --linked`.
- Import dữ liệu ban đầu bằng transaction/idempotent upsert, không dùng production như database thử nghiệm.
- Deploy Vercel preview, kiểm tra toàn luồng rồi mới gắn production domain.

## Dữ liệu và interface

- 8 môn: Pickleball, Bóng bàn, Cầu lông, Bơi lội, Kéo co, Điền kinh, Cờ vua, Cờ tướng.
- Schema chuẩn hóa:
  - Nội dung: `event_settings`, `contacts`, `footer_links`, `media`.
  - Thi đấu: `sports`, `tournaments`, `organizations`, `participants`, `entries`, `entry_members`.
  - Vận hành: `venues`, `courts`, `groups`, `group_entries`, `fixtures`, `fixture_entries`, `standings`, `awards`.
  - Quản trị/nguồn: `admin_users`, `source_documents`.
- `entries` thống nhất đội, cặp và cá nhân. `fixture_entries` hỗ trợ trận hai bên, nhiều làn bơi và lượt điền kinh.
- Bracket dùng `round_order`, `bracket_position`, `next_fixture_id`; standings lưu P/W/D/L/điểm vì luật từng môn khác nhau.
- Homepage stats tính từ dữ liệu, không lưu số tổng trùng lặp.
- Public đọc trực tiếp bằng Server Components; mutation qua Server Actions; không dựng REST API thừa.
- RLS mọi bảng: `anon` chỉ SELECT dữ liệu chưa archive; admin được INSERT/UPDATE. Không đưa secret/service-role vào client.
- Auth SSR dùng `@supabase/ssr`, Next.js `proxy.ts` refresh token; từng trang/action vẫn xác minh `getClaims()` và `admin_users`. Theo [Supabase SSR hiện hành](https://supabase.com/docs/guides/auth/server-side/creating-a-client).
- Migration imperative, seed SQL tách theo thứ tự trong `supabase/seeds/`; `supabase db reset` phải dựng lại hoàn toàn. Theo [Supabase local workflow](https://supabase.com/docs/guides/local-development/cli-workflows) và [seeding guide](https://supabase.com/docs/guides/local-development/seeding-your-database).

## Seed và kiểm soát chất lượng

- KV thắng khi ngày/tên sự kiện mâu thuẫn. Raw filename, checksum, page và ghi chú hiệu chỉnh lưu trong `source_documents`.
- Đọc đủ mọi trang PDF, tạo dataset đã rà soát; không chạy parser PDF trong production.
- `Schedule_All_Sports_2026-08-27.pdf` loại khỏi seed vì là export PTSC cũ ngày 19/04/2026.
- Môn thiếu thể lệ hiển thị “Đang cập nhật”; không copy thể lệ PTSC sai giải.
- Chỉ tạo trận, giờ, sân và huy chương khi nguồn thể hiện rõ. Không đoán dữ liệu trống.
- Tên người giữ nguyên; UI, taxonomy, mô tả và trạng thái có EN đầy đủ.

## Test và tiêu chí nghiệm thu

- `supabase db reset` chạy sạch; kiểm tra FK, unique slug, index, seed count và RLS cho anon/admin.
- Visual regression tại 1440px, iPad 1024px, iPhone 390px so với screenshot; mask countdown động.
- Mọi route VI/EN, menu, mobile drawer, filter, tab, bracket, schedule và empty state hoạt động.
- Không có horizontal overflow ngoài container bảng/bracket chủ ý.
- Phase 2: test login sai/đúng, chặn `/admin`, CRUD song ngữ, archive/restore, upload và RLS.
- Build production, TypeScript và console browser không lỗi.

## Giả định và rủi ro

- Phase 1 có giao diện `/login`; Auth/admin CRUD kích hoạt ở Phase 2.
- Footer chưa có contact thật: để trống, không tạo dữ liệu giả.
- Pixel tuyệt đối giữa mọi browser không khả thi; nghiệm thu theo viewport screenshot đã cung cấp và token/layout gốc.
- PDF có text encoding kém, typo và ô kết quả trống; cần manifest đối soát thủ công trước khi chốt seed.
- Giả định đơn vị sở hữu quyền dùng KV, logo và công khai tên VĐV trong PDF.
- Node 22 bắt buộc vì Supabase client đã ngừng Node 20 từ 30/06/2026 theo [changelog](https://supabase.com/changelog?types=deprecation).
