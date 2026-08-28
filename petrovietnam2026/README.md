# Hội thao Petrovietnam 2026

Next.js 16 + Supabase. Node.js 22+ bắt buộc. Database dùng chung nằm ở `../supabase/`.

## Chạy local

```bash
npm install
cp .env.example .env.local
npm run dev
```

Chạy `supabase start` và `supabase db reset` từ repo root trước. `.env.local` cần có `NEXT_PUBLIC_TENANT_SLUG=petrovietnam2026`.

- Website: `http://127.0.0.1:3000`
- Supabase Studio: `http://127.0.0.1:55323`
- Admin local: `admin@petrovietnam.vn` / `Petrovietnam2026!`

## Kiểm tra

```bash
npm test
npm run lint
npm run typecheck
npm run build
```

Seed chạy theo thứ tự trong `../supabase/seeds/`. File lịch PTSC cũ chỉ lưu manifest, không import. Production dùng user/mật khẩu riêng; không chạy `040_local_admin.sql` trên project online.
