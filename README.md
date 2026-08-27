# Hội thao Petrovietnam 2026

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
- Admin local: `admin@petrovietnam.local` / `Petrovietnam2026!`

## Kiểm tra

```bash
npm test
npm run lint
npm run typecheck
npm run build
```

Seed chạy theo thứ tự trong `supabase/seeds/`. File lịch PTSC cũ chỉ lưu manifest, không import. Production dùng user/mật khẩu riêng; không chạy `040_local_admin.sql` trên project online.
