<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# Sports Day Agent Guide

## Token-efficient workflow

- Start from the named file, route, symbol, or failing command. Read only that file and its nearest dependency/test first.
- State one local hypothesis and one cheap check before editing; then make the smallest focused change.
- Do not scan `assets/`, `node_modules/`, `.next/`, or all routes unless the task requires it.
- Reuse existing types, helpers, CSS classes, and components. Avoid broad refactors, new abstractions, and unrelated fixes.
- After each edit, run the narrowest relevant check before reading or changing another area. Finish with an executable validation.
- Keep this file authoritative and short; do not duplicate framework documentation or README content here.

## Repo map

- Stack: Next.js `16.3.3`, React `19`, TypeScript strict, Node `>=22`; `@/*` maps to `src/*`.
- Public routes: `/`, `/sports`, `/sports/[slug]`, `/schedule`, `/leaderboard`, `/gallery`, `/login`; English mirrors under `/en/*`.
- Admin: `/admin`; route pages are thin wrappers. Main public composition is in `src/components/public-pages.tsx`.
- Server by default. Client components: `countdown`, `gallery-grid`, `language-switch`, `markdown-input`, `schedule-view`, `sport-tabs`.
- Domain/data owner: `src/lib/site.ts` contains types, VI/EN localization, fallback data, Supabase reads, and leaderboard ranking. Prefer `getSiteData()`.
- Supabase server/auth: use `createSupabaseServerClient()` from `src/lib/supabase/server.ts`; auth refresh is in `proxy.ts`.
- Admin writes: `src/app/admin/actions.ts`; entity fields in `src/lib/admin-config.ts`; form conversion in `src/lib/admin-form.ts`; use `revalidatePath()` after writes.
- Database/RLS: `supabase/migrations/`; public data excludes archived rows. Archive with `archived_at`; do not delete records.
- Seeds load lexically from `supabase/seeds/`; do not import the old PTSC schedule. Media bucket is `event-media`; uploads are PNG/JPEG/WebP, max 10 MB.

## UI conventions

- Preserve the existing dark navy/gold visual system, Lexend Variable font, global CSS in `src/app/globals.css`, and Lucide icons.
- Reuse existing classes before adding CSS. Keep cards at `8px` radius or less and preserve breakpoints `1024`, `820`, `600px`.
- Use `next/image` for images; update `next.config.ts` remote patterns when adding a new image host.
- Keep public pages localized in both `vi` and `en`; use `localized()` and `copy` from `src/lib/site.ts`.

## Commands

```bash
npm run dev          # Next dev + Turbopack
npm test             # Node built-in tests
npm run lint
npm run typecheck
npm run build        # Webpack production build
supabase db reset    # reload local schema + seeds
```

Before changing Next.js APIs, read the matching docs under `node_modules/next/dist/docs/`. Preserve the generated block above; `next dev` may rewrite it.
