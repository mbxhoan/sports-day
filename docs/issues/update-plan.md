# Petrovietnam 2026 — Kế hoạch nâng cấp Performance, Reliability và Security

**Phiên bản:** 1.0  
**Ngày lập:** 2026-09-12  
**Phạm vi:** Next.js `petrovietnam2026`, Supabase PostgreSQL/Auth/Storage, Vercel deployment  
**Trạng thái:** Kế hoạch triển khai — chưa thay đổi production

## 1. Kết luận điều hành

Đợt nâng cấp cần đạt ba kết quả chính:

1. Chặn ngay nguy cơ đọc dữ liệu không cần công khai, đặc biệt `participants.birth_date`, `participants.gender` và `source_documents`.
2. Thay mô hình `getSiteData()` tải toàn bộ dữ liệu bằng các loader theo route/use case, có cache và invalidation riêng.
3. Thiết lập khả năng đo lường, kiểm thử tải, rollout và rollback để chứng minh mức giảm Supabase egress/Vercel Functions thay vì chỉ dựa trên cảm nhận.

Không tạo lại Vercel hoặc Supabase project. Việc đó không sửa nguyên nhân trong code và làm tăng rủi ro vận hành.

## 2. Mục tiêu đo lường

### 2.1 Production budgets

| Chỉ số | Mục tiêu bắt buộc | Mục tiêu tốt |
|---|---:|---:|
| Supabase egress trung bình | `< 150 MB/ngày` | `< 100 MB/ngày` |
| Supabase egress theo chu kỳ | `< 4.5 GB/tháng` | `< 3 GB/tháng` |
| PostgREST requests từ public traffic | Giảm `>= 90%` | Giảm `>= 97%` |
| Query trong một cache miss trang Home | `<= 4` | `1–2` |
| Query trong một cache miss trang sport detail | `<= 8` | `2–5` |
| Query trong một cache hit | `0` | `0` |
| P75 TTFB public route cached | `< 300 ms` | `< 150 ms` |
| P75 LCP mobile Home | `< 2.5 s` | `< 2.0 s` |
| Tỷ lệ lỗi public request | `< 0.5%` | `< 0.1%` |
| PII ngoài allowlist đọc được bởi `anon` | `0 cột` | `0 cột` |
| Vulnerability high/critical | `0` | `0` |

Ngân sách 150 MB/ngày tạo khoảng an toàn so với ngưỡng 5.5 GB/tháng, thay vì vận hành sát giới hạn khoảng 183 MB/ngày.

### 2.2 Functional invariants

- Không thay đổi luật tính điểm, bracket, thứ tự hạng, dữ liệu thi đấu hoặc tenant ownership.
- Public VI/EN phải giữ parity.
- Admin vẫn nhập kết quả, import/export/rollback Excel và quản lý nội dung bình thường.
- Không xóa dữ liệu production trong đợt nâng cấp.
- Mọi migration bảo mật phải có test cho `anon`, `authenticated admin`, user không phải admin và cross-tenant.

## 3. Kiến trúc đích

### 3.1 Loại bỏ full snapshot

Thay `getSiteData()` bằng các loader có payload tối thiểu:

| Loader | Dữ liệu được phép lấy | Cache tag gợi ý |
|---|---|---|
| `getShellData()` | event name/subtitle/end time, contacts, footer links | `shell` |
| `getHomeData()` | hero, thời gian, danh sách sport rút gọn, aggregate counts | `home`, `sports-index` |
| `getSportsIndex()` | sport và tournament labels/counts | `sports-index` |
| `getSportData(slug)` | đúng sport, tournament và quan hệ thuộc sport đó | `sport:{slug}` |
| `getScheduleData(filters)` | fixtures trong phạm vi cần hiển thị và quan hệ tương ứng | `schedule` |
| `getLeaderboardData()` | organization ranking và medal totals | `leaderboard` |
| `getGalleryData()` | `gallery_drive_url`; không đọc legacy media nếu UI không dùng | `gallery` |

Quy tắc:

- Filter bằng SQL/PostgREST trước khi dữ liệu rời Supabase.
- Không tải toàn tenant rồi `.filter()` bằng JavaScript.
- Chỉ select cột được render hoặc cần cho business logic.
- Không dùng `select('*')` ở public hoặc admin list.
- Mỗi list có giới hạn/pagination rõ ràng; không cắt âm thầm bằng `.limit(2000)`.
- Không cache auth/session/admin data trong shared cache.

### 3.2 Cache strategy

Triển khai hai bước để giảm rủi ro:

1. Giữ cơ chế cache hiện tại trong khi tách loader và kiểm chứng parity.
2. Sau khi ổn định, chuyển sang API cache chính thức của Next.js 16 (`use cache`, `cacheLife`, `cacheTag`) trong một PR riêng.

Cache profile đề xuất:

| Dữ liệu | Freshness | Revalidate | Invalidation |
|---|---:|---:|---|
| Shell/static event content | 1 giờ | 1 giờ | On-demand khi admin sửa |
| Sports catalog | 1 giờ | 1 giờ | On-demand |
| Schedule/results trong sự kiện | 1 phút | 1 phút | On-demand sau save/import |
| Schedule/results sau sự kiện | 1 giờ | 1 giờ | On-demand |
| Leaderboard trong sự kiện | 1 phút | 1 phút | On-demand |
| Gallery Drive URL | 1 giờ | 1 giờ | On-demand |

Tạo một module duy nhất, ví dụ `src/lib/data/invalidate.ts`, ánh xạ mutation sang cache tag. Không gọi rải rác `revalidatePath()`/`revalidateTag()` trong hàng chục action.

Admin save cần dùng invalidation cho read-your-own-write. Excel apply/rollback và scoring rule bắt buộc invalidation đúng tag dữ liệu public.

### 3.3 Read models

Ưu tiên query trực tiếp có filter trước. Chỉ tạo database view/RPC khi có lợi ích đo được:

- Home aggregate counts: một RPC hoặc view trả đúng một row.
- Leaderboard: một read model trả kết quả đã xếp hạng.
- Sport detail: có thể dùng một RPC trả JSON theo sport nếu nhiều round trip vẫn là bottleneck.

View public phải dùng `security_invoker = true`. RPC ưu tiên `SECURITY INVOKER`, có tenant predicate và quyền `EXECUTE` tường minh. Không dùng `SECURITY DEFINER` để né RLS.

## 4. Workstream A — Baseline và guardrails

**Ước lượng:** 0.5–1 ngày  
**Rủi ro:** Thấp

### Công việc

- Gắn release/tag cho production đang chạy và ghi lại deployment ID.
- Tạo staging/preview dùng dữ liệu đã ẩn thông tin nhạy cảm.
- Chụp baseline trong cùng một khung 60 phút và 24 giờ:
  - Supabase Database Egress, Storage Egress, Auth Egress.
  - Top PostgREST endpoints/calls.
  - `pg_stat_statements`: calls, mean time, total time.
  - Vercel function invocations, duration, fast origin transfer, error rate.
  - Web Vitals theo mobile/desktop.
- Thêm request correlation ID vào server logs, không log token/cookie/password/FormData.
- Ghi số row và thời gian của từng loader; chỉ log metadata, không log payload/PII.
- Tạo performance budget file và checklist release.

### Exit criteria

- Có baseline có timestamp và dashboard/saved query để đo lại sau deploy.
- Có thể phân biệt Database Egress với Storage Egress.
- Có deployment rollback target đã xác minh.

## 5. Workstream B — Security hotfix

**Ước lượng:** 1 ngày  
**Rủi ro:** Trung bình vì thay quyền DB  
**Triển khai:** Độc lập, trước refactor performance

### 5.1 Giới hạn Data API

Tạo migration bằng Supabase CLI, không tự đặt timestamp thủ công.

- Revoke table-level `SELECT` của `anon` trên `participants`.
- Chỉ grant các cột public cần thiết:
  - `id`
  - `organization_id`
  - `full_name`
  - `full_name_en`
- Revoke toàn bộ quyền `anon` trên `source_documents`.
- Lập ma trận quyền cho tất cả bảng trong exposed schema.
- Revoke `anon` khỏi bảng không được public UI hoặc public read model sử dụng.
- Kiểm tra mọi function mới/cũ: `EXECUTE` không được ngầm cấp cho `PUBLIC`.
- Chạy Supabase security advisors sau migration.

### 5.2 Storage

- Quyết định rõ bucket `event-media` có thực sự public hay không.
- Nếu ảnh là public:
  - Chỉ lưu asset được phép public.
  - Không coi RLS object là biện pháp bảo mật cho URL public.
  - Tách private/admin file sang bucket khác.
- Nếu ảnh cần hạn chế:
  - Chuyển sang private bucket.
  - Dùng signed URL có TTL phù hợp hoặc authenticated delivery.
- Kiểm tra path prefix tenant cho insert/update/delete.
- Thiết lập `cacheControl` dài cho asset immutable có UUID trong path.

### 5.3 Input/output hardening

- Validate `contacts.href`, `footer_links.href`, sport icon URL theo allowlist protocol/host.
- Chỉ cho phép `https:`, `mailto:` hoặc `tel:` theo loại field; chặn `javascript:` và URL bất hợp lệ.
- Image upload phải kiểm tra magic bytes, MIME thực, kích thước pixel và giới hạn megapixel, không chỉ tin `File.type`.
- Excel upload: kiểm tra ZIP structure/entry count/uncompressed-size trước khi `exceljs.load()` để giảm zip-bomb risk.
- Giới hạn chiều dài text/JSON ở server và database cho các field có thể nhập từ admin.
- Không trả raw database error cho URL query hoặc public response.

### 5.4 Auth và HTTP hardening

- Bật MFA cho tài khoản admin nếu production plan hỗ trợ.
- Rà JWT expiry, session revocation và quy trình thu hồi quyền admin.
- Giới hạn/rate-limit login và admin mutation endpoints.
- Thêm CSP, `frame-ancestors`, `Referrer-Policy`, `Permissions-Policy`, `X-Content-Type-Options`.
- Chỉ cho phép image optimizer truy cập đúng Supabase host/path; đặt `maximumRedirects: 0`.

### Security tests

- `anon` đọc được tên VĐV nhưng không đọc được ngày sinh/giới tính.
- `anon` không đọc được `source_documents`.
- `anon` không thể insert/update/delete.
- Admin tenant A không đọc/ghi tenant B.
- User authenticated không có `admin_users` không thể gọi admin RPC.
- File giả PNG/JPEG/WebP bị từ chối.
- URL `javascript:` và external image ngoài allowlist bị từ chối.

## 6. Workstream C — Public data refactor

**Ước lượng:** 2–3 ngày  
**Rủi ro:** Trung bình-cao vì chạm toàn bộ public routes

### 6.1 Cấu trúc file đề xuất

```text
src/lib/data/
  client.ts
  cache-tags.ts
  errors.ts
  shell.ts
  home.ts
  sports-index.ts
  sport-detail.ts
  schedule.ts
  leaderboard.ts
  gallery.ts
  invalidate.ts
```

Giữ types/domain calculation trong module riêng; không tiếp tục để types, fallback data, localization, database IO và ranking chung một file.

### 6.2 Thay đổi theo route

#### Home `/` và `/en`

- Không đọc participants, entries, members, groups, standings, awards, media.
- Chỉ lấy event/hero, sport cards và aggregate counts.
- Tính fixture count bằng aggregate DB hoặc summary read model.
- Dùng static image import cho hero mặc định.

#### Sports index

- Chỉ đọc sports và tournament summaries.
- Fixture count group theo sport tại DB, không lặp `.filter().some()` trong render.

#### Sport detail

- Resolve sport bằng slug trước.
- Mọi query sau đó phải filter `sport_id`, `tournament_id`, `fixture_id` ngay tại DB.
- Tách tab nếu payload còn lớn: info/teams/times/fixtures/brackets chỉ tải dữ liệu cần cho tab.
- Đưa tab quan trọng vào route segment hoặc giữ query param nhưng loader phải nhận tab làm input cache key.

#### Schedule

- Chỉ lấy khoảng ngày/venue/filter đang hiển thị nếu UX cho phép.
- Pagination hoặc windowing cho lịch lớn.
- Không tải athletes/team members nếu tên entry đã đủ cho lịch; chỉ lấy khi tính năng search thực sự cần.

#### Leaderboard

- Dùng manual medal columns nếu đó là source of truth.
- Không tải participants/entries/awards khi manual leaderboard đã tồn tại.
- Nếu cần fallback awards, aggregate ở DB rồi trả row đã tổng hợp.

#### Gallery

- Hiện UI chỉ dùng `gallery_drive_url`; loại bỏ hoàn toàn query `media` khỏi public flow.
- Xóa hoặc archive dead component `GalleryGrid` sau khi xác nhận không còn yêu cầu legacy gallery.

### 6.3 Error handling

- Không trả fallback trông giống dữ liệu production khi DB lỗi.
- Phân biệt:
  - Env chưa cấu hình: fail build/start có thông báo vận hành rõ ràng.
  - Supabase timeout: render trạng thái tạm thời và log correlation ID.
  - Not found: `notFound()` đúng nghĩa.
  - Partial query failure: không cache response thiếu dữ liệu như response hợp lệ.
- Tất cả Supabase public fetch có timeout và error check.
- Chỉ cache thành công; không cache outage fallback 5 phút.

### Exit criteria

- Snapshot/UI parity VI và EN đạt.
- Không còn `getSiteData()` full snapshot trong public routes.
- Không còn public query `media` khi gallery dùng Drive.
- Query count đạt budget ở mục 2.
- Supabase payload bytes giảm tối thiểu 80% trong kịch bản Home và Sport detail.

## 7. Workstream D — Admin/query efficiency

**Ước lượng:** 1.5–2 ngày  
**Rủi ro:** Trung bình

### Công việc

- Tách `src/app/admin/actions.ts` theo domain: auth, event, roster, competition, media, Excel.
- Mọi admin section query theo sport/tournament/entity ngay tại database.
- Loại bỏ pattern `all(entity) -> data.filter(...)`.
- Thay `.limit(2000)` bằng pagination/range rõ ràng.
- Thêm server-side search cho participant/entry lớn.
- Chỉ select cột cần cho list; tải detail khi mở editor nếu cần.
- Tránh query tất cả participants và entry members trong Results khi chỉ cần những record thuộc tournament.
- Centralize authorization/context resolution để tránh lặp tenant/admin queries trong cùng request.
- Kiểm tra error cho mọi query, không dùng `(result.data ?? [])` khi result có error.

### Excel

- Giữ apply/rollback ở database transaction.
- Invalidate `sport:{slug}`, `schedule`, `leaderboard`, `home` sau apply/rollback.
- Đặt retention cho export/import snapshots và change logs.
- Không giữ JSON snapshot vô hạn nếu không còn yêu cầu audit.
- Đo kích thước JSONB trước khi quyết định retention.

### Exit criteria

- Không section nào query toàn tenant rồi filter sport bằng JS.
- Admin lists hoạt động với hơn 2.000 records mà không mất dữ liệu.
- Excel apply/rollback phản ánh lên public ngay sau invalidation.

## 8. Workstream E — PostgreSQL tuning

**Ước lượng:** 1 ngày  
**Rủi ro:** Thấp-trung bình

Chỉ thêm index sau khi query mới đã ổn định. Với mỗi query:

1. Chạy `EXPLAIN (ANALYZE, BUFFERS)` trên staging có dữ liệu gần production.
2. Ghi plan trước/sau.
3. Chỉ giữ index được planner sử dụng hoặc phục vụ constraint rõ ràng.
4. Kiểm tra chi phí write/storage và index trùng lặp.

Các index ứng viên cần kiểm chứng:

- `participants (tenant_id, full_name) WHERE archived_at IS NULL`
- `entries (tenant_id, tournament_id, name_vi) WHERE archived_at IS NULL`
- `entry_members (tenant_id, entry_id, sort_order) WHERE archived_at IS NULL`
- `groups (tenant_id, tournament_id, sort_order) WHERE archived_at IS NULL`
- `group_entries (tenant_id, group_id, seed_order) WHERE archived_at IS NULL`
- `fixtures (tenant_id, tournament_id, starts_at) WHERE archived_at IS NULL`
- `fixture_entries (tenant_id, fixture_id, seed_order) WHERE archived_at IS NULL`
- `standings (tenant_id, tournament_id, group_id, rank) WHERE archived_at IS NULL`
- `media (tenant_id, sport_id, kind, sort_order) WHERE archived_at IS NULL`

Không thêm toàn bộ danh sách một cách máy móc; một số index hiện tại đã phủ prefix tương tự.

## 9. Workstream F — Image, asset và delivery

**Ước lượng:** 1 ngày  
**Rủi ro:** Thấp

### Hero

- `kv.png` hiện 12.833×6.398; resize source web về tối đa khoảng 2.560 px chiều rộng.
- `kv-mobile.png` hiện 4.033×7.151; resize về khoảng 1.440×2.550 hoặc theo DPR mục tiêu.
- Chuyển sang WebP/AVIF chất lượng đã visual-review.
- Xóa `theme.png` 15 MB nếu xác nhận không được sử dụng.
- Dùng static image import cho asset bundled để có hash, metadata kích thước và cache immutable.
- Không render đồng thời hai `<img>` desktop/mobile rồi ẩn bằng CSS. Dùng art-direction `<picture>`/`getImageProps` để browser chỉ tải đúng một hero.
- Preload đúng hero LCP theo breakpoint; không preload cả hai.

### Uploaded media

- Upload path có UUID/hash để immutable caching an toàn.
- Ghi `cacheControl` dài khi upload.
- Khi thay hero/icon, xóa object cũ sau khi DB update thành công hoặc đưa vào cleanup queue.
- Nếu DB insert/update thất bại sau upload, thực hiện compensating delete.
- Nếu xóa storage thành công nhưng DB delete thất bại, ghi reconciliation job thay vì để trạng thái hỏng im lặng.
- Với gallery upload nhiều file, ưu tiên signed upload/direct browser-to-Supabase để không truyền file qua Vercel Function.

### Next Image protection

- Giữ `remotePatterns` chính xác tới bucket/path.
- Giới hạn quality/size variants cần dùng.
- Đặt `maximumRedirects: 0`.
- Theo dõi `/_next/image` request volume để phát hiện optimizer abuse.

## 10. Workstream G — Reliability, tests và repository hygiene

**Ước lượng:** 1–1.5 ngày  
**Rủi ro:** Thấp

### Reliability

- Thêm `error.tsx`, `not-found.tsx` phù hợp cho public/admin.
- Thêm retry có giới hạn chỉ cho read idempotent và lỗi transient.
- Không retry mutation tự động nếu chưa có idempotency key.
- Đặt timeout cho public Supabase calls; tổng route timeout phải nhỏ hơn platform timeout.
- Đảm bảo cache stampede được coalesce; load test đúng lúc cache hết hạn.

### Tests

- Sửa PDF test để warning của PyMuPDF không trộn vào stdout JSON.
- Chuẩn hóa Unicode filename NFC trong repo để clone/CI trên Linux không báo delete/add giả.
- Thêm database tests cho grants/RLS/storage.
- Thêm contract tests cho từng loader và payload allowlist.
- Thêm parity tests so sánh loader cũ và V2 trên cùng fixture dataset.
- Thêm test cache invalidation cho mọi mutation.
- Thêm query-budget test bằng instrumented Supabase client.
- Thêm kịch bản load test:
  - Cold cache: 1 request.
  - Warm cache: 100–500 concurrent users.
  - Cache expiry herd.
  - Admin save trong khi public traffic cao.
  - Image optimizer request variants.

### Repository

- Xóa root `package.json/package-lock.json` thừa hoặc cấu hình workspace đúng chuẩn.
- Thiết lập `outputFileTracingRoot` nếu cấu trúc monorepo được giữ lại.
- Không đóng gói `.git`, outputs, screenshots, raw PDF/XLSX và tmp vào deployment artifact.
- Xác nhận Vercel Root Directory là `petrovietnam2026`.
- Pin dependency production; xử lý cảnh báo `exceljs -> uuid` bằng upgrade an toàn hoặc documented exception có thời hạn.

### CI gates

```text
lint
typecheck
unit tests
database reset + SQL/RLS tests
production build
dependency audit: fail high/critical
query budget tests
bundle/asset size budget
```

## 11. Rollout plan

### Phase 0 — Baseline

- Chưa đổi production.
- Thu baseline, tạo staging và xác minh rollback target.

### Phase 1 — Security hotfix

- Deploy code đã sử dụng explicit public columns trước.
- Chạy migration revoke/grant.
- Chạy smoke test bằng anon/admin/non-admin/cross-tenant.
- Theo dõi 30–60 phút.

### Phase 2 — Data Loader V2 sau feature flag

- Thêm `PUBLIC_DATA_LOADER=v2` ở Preview/Staging.
- Chạy parity, Lighthouse và load test.
- Canary production hoặc rollout trong giờ traffic thấp.
- So sánh 1 giờ đầu và 24 giờ với baseline.

### Phase 3 — Admin, image và DB tuning

- Deploy theo PR nhỏ, mỗi PR có metric/acceptance criteria riêng.
- Index tạo trong maintenance window phù hợp với kích thước bảng.

### Phase 4 — Cleanup

- Sau 3–7 ngày ổn định, xóa loader V1, dead gallery code và asset thừa.
- Không xóa rollback path trước khi đủ thời gian quan sát.

## 12. Rollback plan

### Application

- Rollback về deployment ID đã lưu ở Workstream A.
- Feature flag chuyển ngay `v2 -> v1` nếu lỗi chỉ nằm ở loader.
- Version cache key/tag khi rollout để tránh đọc cache cũ không tương thích.

### Database

- Migration chỉ revoke/grant và add index; không drop column/table/data.
- Chuẩn bị migration forward-fix để khôi phục grant trong tình huống khẩn cấp.
- Không dùng destructive rollback cho dữ liệu thi đấu.
- Nếu read model lỗi, revoke quyền view/RPC mới và chuyển app về loader cũ.

### Storage

- Không xóa object cũ ngay khi thay hero/icon; giữ grace period hoặc audit log.
- Cleanup job chỉ xóa object được xác nhận không còn reference.

## 13. Definition of Done

Một phase chỉ hoàn thành khi:

- Code review và migration review đã đạt.
- Lint, typecheck, tests, database tests và production build đạt.
- Không có regression VI/EN, mobile/desktop hoặc admin workflow.
- Security matrix test đạt.
- Query count/payload đạt budget.
- Có số liệu staging và production trước/sau.
- Runbook rollback đã thử trên staging.
- Tài liệu vận hành và biến môi trường được cập nhật.

Toàn chương trình hoàn thành khi production duy trì các budget mục 2 trong ít nhất 7 ngày.

## 14. Phân công đề xuất cho team 4 người

| Vai trò | Trách nhiệm |
|---|---|
| Dev A | Public loader/cache, route refactor, image delivery |
| Dev B | Supabase grants/RLS/read models/indexes, admin query refactor |
| BA/QA | Data parity, VI/EN, business rules, regression và UAT |
| Lead/Manager | Baseline, budgets, security approval, rollout/rollback và production monitoring |

Dev A và Dev B có thể làm song song sau khi thống nhất contract/types của loader. Migration security phải được review chéo trước production.

## 15. Ước lượng và thứ tự PR

| PR | Nội dung | Ước lượng |
|---|---|---:|
| PR-01 | Baseline instrumentation và budgets | 0.5–1 ngày |
| PR-02 | PII/Data API/Storage security hotfix + tests | 1 ngày |
| PR-03 | Loader contracts, cache tags, shell/home/gallery | 1 ngày |
| PR-04 | Sports index và sport detail V2 | 1–1.5 ngày |
| PR-05 | Schedule và leaderboard V2 | 1–1.5 ngày |
| PR-06 | Centralized invalidation + Excel/scoring fixes | 0.5–1 ngày |
| PR-07 | Admin scoped queries/pagination | 1–1.5 ngày |
| PR-08 | Image/assets/direct upload/cleanup | 1 ngày |
| PR-09 | Index tuning, load test, repository/CI cleanup | 1–1.5 ngày |

Tổng dự kiến:

- Một senior developer: khoảng 8–12 ngày làm việc.
- Hai developer + BA/QA phối hợp: khoảng 5–7 ngày làm việc, chưa tính thời gian quan sát production 7 ngày.

## 16. Quyết định kỹ thuật không được bỏ qua

1. Vá quyền PII trước khi tối ưu performance.
2. Giảm payload/query ở application trước khi thêm index.
3. Không cache admin/session data trong shared cache.
4. Không dùng fallback giả dữ liệu thật khi production DB lỗi.
5. Không deploy migration RLS nếu chưa có automated permission tests.
6. Không đánh giá thành công chỉ bằng build xanh; phải chứng minh bằng egress, query calls và Web Vitals.
7. Không tạo lại project để xử lý usage; sửa nguyên nhân và theo dõi billing cycle hiện tại.

