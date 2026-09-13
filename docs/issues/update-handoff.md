Đã đọc và kiểm tra source `petrovietnam2026`. Kết luận chính: ứng dụng có nền tảng khá tốt và build được, nhưng nguyên nhân Supabase egress cao gần như chắc chắn đến từ chính kiến trúc tải dữ liệu cũ, chưa đủ bằng chứng để kết luận bị tấn công.

## Tổng quan kiến trúc

* Next.js 16.3.3, React 19, TypeScript strict.
* App Router, Server Components và Server Actions.
* Website public song ngữ Việt/Anh.
* Supabase:

  * PostgreSQL.
  * Auth cho admin.
  * Storage cho ảnh.
  * RLS và multi-tenant bằng header `x-tenant-slug`.
* 34 migration, 113 test.
* Có hệ thống nhập/xuất Excel, preview, apply và rollback khá hoàn chỉnh.

File trung tâm:

* [src/lib/site.ts](sandbox:/workspace/scratch/582662256a85/extracted/sports-day/petrovietnam2026/src/lib/site.ts)
* [src/app/admin/actions.ts](sandbox:/workspace/scratch/582662256a85/extracted/sports-day/petrovietnam2026/src/app/admin/actions.ts)
* [multi_tenant_isolation.sql](sandbox:/workspace/scratch/582662256a85/extracted/sports-day/supabase/migrations/20260828022820_multi_tenant_isolation.sql)

## Nguyên nhân Supabase egress cao

Đây là dấu hiệu rõ nhất trong source:

* Mỗi lần `getSiteData()` chạy, nó tải 18 nhóm dữ liệu song song.
* Cộng query lấy tenant và phân trang `fixture_entries`, một lần tải toàn site tạo khoảng 20–23 request PostgREST.
* Tất cả route public dùng chung full dataset này, kể cả trang chỉ cần vài trường.
* Sau đó mới lọc dữ liệu bằng JavaScript.

Log đi kèm source cho thấy:

* Các query `participants`, `fixtures`, `entries`, `standings`… đều có chính xác khoảng `22.692 calls`.
* `fixture_entries` có `45.041 calls` vì phải phân trang.
* Query khởi tạo request PostgREST có `528.099 calls`.

Mẫu số lượng bằng nhau này khớp gần như hoàn toàn với `getSiteData()`: khoảng 22.700 lần tải toàn bộ snapshot × hơn 20 endpoint ≈ nửa triệu request.

Git history cũng xác nhận phiên bản cũ từng:

* Dùng `noStore()`, tức mỗi request website đều query lại Supabase.
* Tự động `router.refresh()` mỗi 30 giây cho mỗi tab đang mở.

Đây mới là “smoking gun” của egress 9–10 GB.

### Tình trạng hiện tại

HEAD hiện tại đã cải thiện:

* Dùng `unstable_cache`, TTL 5 phút.
* Auto refresh giảm từ 30 giây xuống 5 phút.
* Auto refresh dừng sau `event.end_at`; dữ liệu seed kết thúc ngày 06/09/2026 nên hiện tại polling sẽ không còn chạy.
* Ảnh Supabase đi qua Next Image optimizer với cache dài.

Những thay đổi này có thể giảm mạnh traffic, nhưng chưa sửa tận gốc thiết kế full snapshot. Khi cache miss hoặc admin revalidate, hệ thống vẫn tải gần như toàn bộ database public.

## Các vấn đề cần ưu tiên

| Mức | Vấn đề                                                                             | Ảnh hưởng                                                                         |
| --- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| P0  | `anon` được `SELECT` toàn bộ cột bảng `participants`                               | Có thể đọc trực tiếp `birth_date`, `gender`, dù UI chỉ sử dụng tên VĐV            |
| P0  | Public loader tải toàn bộ 18 bảng                                                  | Egress, PostgREST calls và function execution vẫn cao khi cache miss              |
| P1  | `source_documents` cũng được public read                                           | Có thể lộ filename, hash, ghi chú và metadata nguồn                               |
| P1  | Trang Home, Gallery, Leaderboard vẫn tải dữ liệu không dùng                        | Lãng phí database egress                                                          |
| P1  | `media` được tải trong public snapshot nhưng `GalleryGrid` hiện không được sử dụng | Query hoàn toàn dư thừa                                                           |
| P1  | Admin nhiều chỗ tải toàn bảng rồi filter bằng JS                                   | Egress admin cao; `.limit(2000)` có thể cắt dữ liệu âm thầm                       |
| P1  | Không kiểm tra lỗi của tất cả 18 query                                             | Một bảng lỗi có thể biến thành mảng rỗng rồi bị cache 5 phút                      |
| P1  | Supabase lỗi sẽ trả fallback giống dữ liệu thật                                    | Có thể che giấu sự cố/misconfiguration                                            |
| P1  | Excel apply/rollback không `revalidateTag("site-data")`                            | Public có thể hiển thị dữ liệu cũ thêm 5 phút                                     |
| P1  | Upload Storage và insert/update DB không atomic                                    | DB lỗi có thể để lại file rác; DB delete lỗi có thể để record trỏ đến file đã xóa |
| P2  | Ảnh public khoảng 25,65 MiB                                                        | Deploy nặng; `theme.png` 15 MB hiện không được sử dụng                            |
| P2  | Hai `package-lock.json`                                                            | Next.js báo chọn nhầm workspace root/output tracing root                          |
| P2  | Hai test PDF phụ thuộc warning của PyMuPDF                                         | Làm CI fail dù dữ liệu vẫn parse được                                             |
| P2  | `exceljs → uuid` có 2 cảnh báo mức moderate                                        | Chưa có high/critical, nhưng cần theo dõi/nâng cấp                                |

### Vấn đề PII đáng chú ý

Migration hiện thực hiện:

```sql
grant select on public.participants to anon;
```

RLS chỉ hạn chế theo tenant và `archived_at`, không giới hạn cột. Vì vậy client có thể tự gọi REST:

```text
participants?select=id,full_name,birth_date,gender
```

Giải pháp tối thiểu:

```sql
revoke select on public.participants from anon;

grant select (
  id,
  organization_id,
  full_name,
  full_name_en
) on public.participants to anon;

revoke select on public.source_documents from anon;
```

Authenticated admin vẫn có thể được giữ quyền đọc đầy đủ.

## Điểm làm tốt

* Không tìm thấy `service_role` hoặc private secret nhúng trong source hiện tại.
* Admin action luôn kiểm tra Supabase claims và membership trong `admin_users`.
* RLS có `USING` và `WITH CHECK`, kết hợp kiểm tra tenant/admin.
* Các RPC public quan trọng đã revoke khỏi `anon`.
* Quan hệ cross-tenant được bảo vệ bằng trigger.
* Excel import:

  * Giới hạn kích thước, số dòng và số ô.
  * Chặn formula.
  * Kiểm tra snapshot.
  * Apply theo transaction.
  * Có rollback và conflict detection.
* TypeScript strict, build và lint sạch.
* Ảnh chỉ cho phép PNG/JPEG/WebP và giới hạn 10 MB.

## Kết quả kiểm tra

* `npm run lint`: đạt.
* `npm run typecheck`: đạt.
* `npm run build`: đạt, tạo đủ 15 route.
* Test: `111/113` đạt.
* Hai test PDF lỗi vì PyMuPDF in cảnh báo `Consider using the pymupdf_layout...` ra stdout trước JSON, không phải do dữ liệu test sai.
* `npm audit`: 2 cảnh báo moderate, không có high/critical.

## Hướng refactor khuyến nghị

Thứ tự nên triển khai:

1. Vá quyền đọc `participants` và `source_documents`.
2. Tách `getSiteData()` thành:

   * `getShellData()`
   * `getHomeData()`
   * `getSportData(slug)`
   * `getScheduleData()`
   * `getLeaderboardData()`
3. Bỏ query `media` khỏi public loader vì gallery đang dùng Google Drive.
4. Đưa filter `sport_id`, `tournament_id`, `fixture_id` xuống query Supabase.
5. Tách cache tag theo domain thay vì một tag `site-data`.
6. Bổ sung timeout và kiểm tra lỗi cho toàn bộ public queries.
7. Đồng bộ cache invalidation sau Excel apply/rollback.
8. Tối ưu hoặc xóa `theme.png`; resize hero về kích thước hợp lý.
9. Xóa root `package.json/package-lock.json` thừa hoặc cấu hình `outputFileTracingRoot`.

Đánh giá tổng thể: code nghiệp vụ và admin khá chắc, khoảng 7/10; điểm yếu lớn nhất là data-fetching và phân quyền cột public. Tạo lại Vercel/Supabase project sẽ không xử lý các nguyên nhân này—cần sửa query và RLS. Tôi chưa thay đổi source trong archive.

Đã hoàn thành kế hoạch nâng cấp toàn diện cho `petrovietnam2026`, có thứ tự ưu tiên, phạm vi từng PR, tiêu chí nghiệm thu và phương án rollback:

[](sandbox:/workspace/scratch/582662256a85/PETROVIETNAM2026-PERFORMANCE-SECURITY-UPGRADE-PLAN.md)

### Thứ tự triển khai đề xuất

| Ưu tiên | Hạng mục                                                                     |  Thời gian |
| ------- | ---------------------------------------------------------------------------- | ---------: |
| P0      | Chặn truy cập PII, siết RLS/quyền `anon`, bảo vệ tài liệu nguồn và upload    |     1 ngày |
| P1      | Tách `getSiteData()` thành loader theo từng trang, giảm số request Supabase  |   2–3 ngày |
| P1      | Cache theo tag và invalidation ngay sau thao tác quản trị                    | 0.5–1 ngày |
| P1      | Phân trang, lọc tại database, bỏ tải toàn bảng trong trang admin             | 1.5–2 ngày |
| P2      | Tối ưu ảnh hero, loại asset thừa, tránh tải đồng thời ảnh desktop/mobile     |     1 ngày |
| P2      | Tạo index dựa trên `EXPLAIN ANALYZE`, tối ưu upload và tính toàn vẹn dữ liệu |     1 ngày |
| P2      | Load test, kiểm thử bảo mật, theo dõi và rollout từng bước                   | 1–1.5 ngày |

Mục tiêu quan trọng:

* Giảm tối thiểu **90% request PostgREST**.
* Trang cache hit không phát sinh truy vấn Supabase.
* Cache miss trang chủ tối đa 4 truy vấn, mục tiêu 1–2.
* P75 TTFB dưới 300 ms và LCP dưới 2,5 giây.
* Supabase egress dưới 150 MB/ngày, mục tiêu dưới 100 MB/ngày.
* Không còn cột PII nào được truy cập ngoài allowlist.
* Không còn lỗi bị che bởi fallback hoặc dữ liệu giả bị lưu vào cache.

Ước lượng hoàn thành: **8–12 ngày với một senior developer**, hoặc **5–7 ngày làm việc với hai developer và BA/QA**, sau đó theo dõi production 7 ngày.

Source hiện chưa bị chỉnh sửa; đây là bản kế hoạch triển khai. Bước nên thực hiện đầu tiên là PR riêng cho **P0 Security Hotfix**, gồm migration thu hồi quyền PII và bộ kiểm thử xác nhận quyền truy cập.
