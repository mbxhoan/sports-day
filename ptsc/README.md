# Hội thao PTSC 2026

Next.js 16 + Supabase. Node.js 22+ bắt buộc. Database dùng chung nằm ở `../supabase/`.

## Chạy local

```bash
npm install
cp .env.example .env.local
npm run dev
```

`.env.local` cần có `NEXT_PUBLIC_TENANT_SLUG=ptsc2026`. Tenant này dùng database có dữ liệu thật: không chạy `supabase db reset`; chỉ tạo migration append-only và triển khai bằng `supabase db push` sau khi đã link đúng project.

- Website: `http://127.0.0.1:3000`
- Supabase Studio: `http://127.0.0.1:55323`
- Admin: dùng tài khoản PTSC đã được cấp quyền trong tenant `ptsc2026`.

## Kiểm tra

```bash
npm test
npm run lint
npm run typecheck
npm run build
```

Seed PTSC 2026 nằm trong migration append-only tổng hợp template Excel. Production dùng user/mật khẩu riêng; không chạy seed/reset local hoặc `040_local_admin.sql` trên project online.

## Hướng dẫn vận hành

Xem [bộ hướng dẫn vận hành duy nhất cho người xem và admin](./docs/HUONG-DAN-VAN-HANH.md). File có mục lục anchor và hướng dẫn riêng cho đủ 11 môn.
