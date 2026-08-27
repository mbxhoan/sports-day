# Admin sport operations and teal theme

## Scope

Replace the flat `/admin` record editor with an authenticated, bilingual operations UI. Preserve archive-only writes, current Supabase SSR authorization, and public routes. Restyle public and admin surfaces from `public/theme.png`; use `public/kv-mobile.png` at mobile breakpoints.

## Information architecture

`/admin` becomes a compact dashboard: event content, contacts/footer, global gallery, and sport cards. `/admin/sports/[slug]` scopes all work to one sport and shows tabs: overview/rules, categories, teams and athletes, venues/sessions, fixtures/results, standings/awards, gallery. Forms use selects populated from active parent records; no UUID input is exposed. The existing normalized tables remain the core hierarchy: sport -> tournament -> entry -> members; tournament -> group/fixture -> fixture entries -> standings/awards.

## Media

Add desktop and mobile hero storage paths to `event_settings`. Admin uploads PNG/JPEG/WebP (10 MB existing limit) to the existing public bucket, previews the file, and replaces only the database reference. Gallery media gains optional `sport_id` and bilingual album fields; public gallery filters by sport/album and opens a native dialog with zoom and download link. No storage deletion in normal flows.

## Results and rankings

An admin edits a fixture by selecting entries and entering actual scores/ranks. Each tournament stores its bilingual PDF-derived scoring rule. A server action updates the fixture atomically, derives standings only where the rule is structured and known, then permits direct correction of played/won/drawn/lost/points/rank and awards. Unknown or individual-event rules never receive invented calculations.

## PDF seed pipeline

A development-only extractor reads every source PDF, renders table pages for visual verification, emits a reviewed idempotent seed, and records source filename/checksum/pages/notes. Preserve source organization labels; create missing organizations. Exclude `Schedule_All_Sports_2026-08-27.pdf`. Ambiguous rows remain explicitly marked in the source manifest rather than guessed; no parser runs in production.

## Security and verification

New columns/tables receive RLS, explicit grants, archive filters, indexes for parent/filter paths, and admin-only Storage writes. Tests cover score derivation and selector validation. Final checks: `supabase db reset`, RLS anon/admin queries, unit tests, lint, typecheck, two clean builds, and desktop/tablet/mobile visual/overflow checks.

## Deliberate limits

No page builder, ORM, REST API, hard deletion, or automatic scoring for rules not encoded from a source PDF. Admin corrections are the safe fallback for every exceptional format.
