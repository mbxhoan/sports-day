# Sports Day SaaS

Hai web dùng chung một Supabase database/schema multi-tenant:

- `petrovietnam2026/` → `NEXT_PUBLIC_TENANT_SLUG=petrovietnam2026`
- `ptsc2026/` → `NEXT_PUBLIC_TENANT_SLUG=ptsc2026`

## Local

Chạy Supabase từ thư mục repo root:

```bash
supabase start
supabase db reset
```

Sau đó, trong thư mục app cần chạy:

```bash
npm install
cp .env.example .env.local
npm run dev
```

Mỗi app dùng cùng `NEXT_PUBLIC_SUPABASE_URL` và `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, chỉ khác `NEXT_PUBLIC_TENANT_SLUG`.

## Vercel

Tạo hai Vercel Project cùng trỏ repo này:

- PVN: Root Directory `petrovietnam2026`
- PTSC: Root Directory `ptsc2026`

Trong mỗi project khai báo URL/key của cùng Supabase project và slug tenant tương ứng. Migration/seed chỉ chạy một lần từ `supabase/` ở root.
