# Hội thao PTSC lần thứ 15

Next.js 16 + Supabase local. Node.js 22+ bắt buộc.

## Chạy local

```bash
npm install
supabase start
supabase db reset
cp .env.example .env.local
supabase status
npm run dev
```

Copy `Publishable key` từ `supabase status` vào `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` trong `.env.local`.

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

Seed chỉ tạo 8 môn thể thao mẫu; giải đấu, đội, vận động viên, lịch và nguồn dữ liệu đang để trống. Production dùng user/mật khẩu riêng; không chạy `040_local_admin.sql` trên project online.
