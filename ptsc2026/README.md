# Hội thao PTSC lần thứ 15

Next.js 16 + Supabase. Node.js 22+ bắt buộc. Database dùng chung nằm ở `../supabase/`.

## Chạy local

```bash
npm install
cp .env.example .env.local
npm run dev
```

Chạy `supabase start` và `supabase db reset` từ repo root trước. `.env.local` cần có `NEXT_PUBLIC_TENANT_SLUG=ptsc2026`.

- Website: `http://127.0.0.1:3000`
- Supabase Studio: `http://127.0.0.1:55323`
- Admin local: `admin@ptsc.vn` / `PTSC2026!`

## Kiểm tra

```bash
npm test
npm run lint
npm run typecheck
npm run build
```

Seed PTSC chỉ tạo 8 môn thể thao; giải đấu, đội, vận động viên, lịch và nguồn dữ liệu để trống. Production dùng user/mật khẩu riêng; không chạy `040_local_admin.sql` trên project online.
