Bạn không thể giảm con số `10.572 GB` đã ghi nhận xuống lại 5.5 GB trong kỳ hiện tại. Supabase cộng dồn egress theo billing cycle và chỉ reset đầu kỳ tiếp theo. Việc cần làm là giảm tốc độ phát sinh trước ngày 07/10 để kỳ tiếp theo nằm dưới 5.5 GB. [Supabase – Manage Egress](https://supabase.com/docs/guides/platform/manage-your-usage/egress)

## Đọc tình trạng hiện tại

Từ ảnh:

* Toàn organization: `10.572 GB / 5 GB` — 211%.
* Riêng `sports-day`: `9.559 GB`.
* `sports-day` chiếm khoảng 90% egress toàn organization.
* Cached Egress chỉ `0.104 GB`.
* Realtime chỉ 163 messages, Edge Functions bằng 0.
* Storage chỉ 19 MB nhưng chưa loại trừ trường hợp file nhỏ bị tải lặp lại nhiều lần.

Nếu 9.559 GB phát sinh trong 7 ngày đầu tháng thì tốc độ hiện tại khoảng:

* `1.37 GB/ngày`.
* Muốn dưới 5.5 GB/tháng: trung bình tối đa khoảng `183 MB/ngày`.
* Cần giảm khoảng 87%.

Gần 99% traffic đang là uncached egress. Khả năng cao nhất là:

1. Database/PostgREST trả dữ liệu nhiều lần.
2. Frontend polling/refetch liên tục.
3. Query trả quá nhiều dòng hoặc quá nhiều cột.
4. Ảnh/file dùng private hoặc signed URL nên không được CDN cache.
5. Bot đang gọi trực tiếp endpoint Supabase.

## Bước 1: Xác định dịch vụ gây egress

Vào:

`Organization → Usage → sports-day → click Egress`

Sau đó hover từng ngày trên biểu đồ. Supabase sẽ chia theo:

* Database Egress
* Storage Egress
* Auth Egress
* Realtime Egress
* Shared Pooler Egress
* Edge Functions Egress

Đây là bước quan trọng nhất. Supabase tính egress cho dữ liệu truyền từ Database, Auth, Storage, Functions và Realtime ra client. [Cách Supabase tính egress](https://supabase.com/docs/guides/platform/manage-your-usage/egress)

Với số liệu hiện tại, tôi nghiêng nhiều về `Database Egress`, vì Cached Egress rất thấp và trước đó Vercel cũng ghi nhận khoảng 41K Function Invocations.

## Bước 2: Tìm endpoint bị gọi nhiều nhất

Vào:

`Supabase project → Logs → Logs Explorer`

Chọn khoảng thời gian 1–3 giờ gần nhất rồi chạy:

```sql
select
  log_attributes['request.method'] as method,
  log_attributes['request.path'] as path,
  log_attributes['response.status_code'] as status,
  count() as requests
from logs
where source = 'edge_logs'
group by method, path, status
order by requests desc
limit 100;
```

Chú ý các path:

* `/rest/v1/...`: Database/PostgREST.
* `/storage/v1/object/...`: Storage.
* `/auth/v1/...`: Auth.
* `/realtime/v1/...`: Realtime.
* `/functions/v1/...`: Edge Functions.

Supabase Logs hiện chưa cung cấp response byte cho từng endpoint, nên số request chỉ là chỉ báo. Sau khi tìm được endpoint bị gọi nhiều, đối chiếu với query và payload của endpoint đó. [Supabase Logs](https://supabase.com/docs/guides/observability/logs)

## Bước 3: Nếu nguyên nhân là Database/PostgREST

### Không dùng `select('*')`

Ví dụ không tốt:

```ts
const { data } = await supabase
  .from('athletes')
  .select('*')
```

Nên đổi thành:

```ts
const { data } = await supabase
  .from('athletes')
  .select('id,name,team,avatar_url')
  .range(0, 49)
```

Áp dụng:

* Chỉ lấy cột giao diện thực sự sử dụng.
* Luôn phân trang bằng `.range()`.
* Thêm `.eq()`, `.in()`, `.order()` trước khi lấy dữ liệu.
* Không tải toàn bộ bảng rồi filter bằng JavaScript.
* Với danh sách dropdown, chỉ lấy `id,name`.
* Với trang chi tiết, chỉ query đúng một record.

### Không trả lại toàn bộ row sau write

Kiểm tra các đoạn:

```ts
.insert(...).select()
.update(...).select()
.upsert(...).select()
```

Nếu không cần dữ liệu trả về, bỏ `.select()`. Supabase cũng khuyến nghị write operation không trả toàn bộ row khi không cần thiết. [Supabase Egress optimization](https://supabase.com/docs/guides/platform/manage-your-usage/egress)

### Tìm query chạy quá nhiều

Vào `Advisors → Query Performance`, xem:

* Calls
* Average rows
* Mean time
* Total time

Hoặc SQL Editor:

```sql
select
  calls,
  rows,
  round((rows::numeric / nullif(calls, 0)), 2) as avg_rows_per_call,
  round(total_exec_time::numeric, 2) as total_ms,
  round(mean_exec_time::numeric, 2) as mean_ms,
  query
from pg_stat_statements
order by calls desc
limit 30;
```

Query có `calls` cao và `avg_rows_per_call` cao là ứng viên gây egress lớn nhất.

## Bước 4: Tắt polling/refetch dư thừa

Tìm trong code:

```bash
rg "setInterval|refreshInterval|refetchInterval|router.refresh|revalidate" .
```

Đặc biệt kiểm tra:

* `setInterval(..., 1000)`
* SWR `refreshInterval`
* React Query `refetchInterval`
* `refetchOnWindowFocus`
* Component render lại rồi gọi Supabase lần nữa.
* Dependency của `useEffect` thay đổi liên tục.
* Mỗi item trong danh sách tự chạy một query — N+1 query.
* Dashboard đang mở nhiều tab và mỗi tab polling riêng.

Ví dụ:

```ts
useEffect(() => {
  loadData()
}, [filters])
```

Nếu `filters` là object được tạo lại mỗi render, effect có thể chạy liên tục.

Đối với dữ liệu lịch thi đấu/danh sách vận động viên không đổi từng giây, refresh 5–15 phút thường hợp lý hơn polling mỗi vài giây.

## Bước 5: Cache dữ liệu công khai tại Vercel

Đây có thể đồng thời giảm:

* Supabase Database Egress.
* Vercel Function Invocations.
* Vercel Fast Origin Transfer.
* Số lần query Postgres.

Ví dụ route công khai:

```ts
export async function GET() {
  const data = await loadPublicSportsData()

  return Response.json(data, {
    headers: {
      'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
    },
  })
}
```

Sau lần đầu, CDN có thể phục vụ response cache trong 5 phút thay vì mỗi visitor đều chạy Function và query Supabase.

Chỉ cache dữ liệu công khai. Không dùng shared cache cho dữ liệu chứa thông tin người dùng, quyền truy cập hoặc session.

Nếu frontend hiện gọi thẳng `supabase.from(...)`, Vercel không thể cache response đó. Với các dataset công khai được truy cập nhiều, có thể đưa chúng qua một Vercel API route có CDN cache.

## Bước 6: Nếu nguyên nhân là Supabase Storage

Chạy query sau trong Logs Explorer:

```sql
select
  log_attributes['request.path'] as filepath,
  (log_attributes['response.headers.cf_cache_status'] = 'HIT') as cached,
  count() as requests
from logs
where source = 'edge_logs'
  and (
    log_attributes['request.path'] like '%storage/v1/object/%'
    or log_attributes['request.path'] like '%storage/v1/render/%'
  )
  and log_attributes['request.method'] = 'GET'
group by filepath, cached
order by requests desc
limit 100;
```

Supabase đưa chính query này để tìm file bị tải nhiều. [Supabase Storage bandwidth](https://supabase.com/docs/guides/storage/serving/bandwidth)

Nếu Storage là nguyên nhân:

* Chuyển ảnh sang WebP/AVIF.
* Resize ảnh đúng kích thước hiển thị.
* Không tải ảnh gốc vài MB cho thumbnail.
* Đặt `cacheControl` dài khi upload.
* Dùng public URL cho tài nguyên thực sự công khai.
* Tránh tạo signed URL mới mỗi lần render.
* Không dùng base64 ảnh trong JSON/database.
* Lazy-load ảnh ngoài viewport.
* Đảm bảo component ảnh không remount và tải lại liên tục.

Storage chỉ có 19 MB nhưng nếu 20 MB bị tải 500 lần thì đã thành khoảng 10 GB egress.

## Việc nên làm ngay hôm nay

1. Mở chi tiết `Egress` để xác định Database hay Storage.
2. Chạy query top endpoint trong Logs Explorer.
3. Tạm tắt polling/refetch ở route đứng đầu.
4. Giảm `.select('*')`, thêm pagination.
5. Cache dữ liệu công khai 5–15 phút.
6. Theo dõi mức tăng trong 1 giờ; dashboard có thể cập nhật chậm tối đa khoảng một giờ.
7. Đến đầu kỳ `01/10–01/11`, theo dõi để giữ trung bình dưới khoảng `183 MB/ngày`.

Xóa hoặc tạo lại Supabase project cũng không giảm egress đã ghi nhận của organization trong kỳ hiện tại. Quan trọng là chặn nguồn traffic trước, rồi chờ counter reset đầu kỳ mới.
