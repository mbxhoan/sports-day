# PTSC application parity design

## Goal

Port the reusable UI and application logic added in `petrovietnam2026` to `ptsc2026`, while retaining PTSC's event identity and all PTSC data.

## Included

- Public schedule improvements: venue/court details, grouped schedule rows, and knockout bracket view.
- Admin improvements: scoped sport workspace, readable result cards, gallery upload queue, multi-file upload, and auth request timeouts.
- Shared UI support: loading feedback, site shell, sport tabs, global styling, and Next server-action upload size configuration.
- Matching unit/static checks for the ported behavior.

## Excluded

- `supabase/`, migrations, seeds, storage objects, environment files, extracted source files, and event assets.
- PTSC names, English/Vietnamese event copy, fallback sport/event records, and package identity.
- Permanent gallery deletion and its UI: it requires a new database `DELETE` RLS policy, which is outside this code-only scope. Existing archive behavior remains.

## Integration rules

- Apply source changes selectively rather than copying whole files when the file contains PTSC content or fallback data.
- Do not modify the deployed/local database or run Supabase commands.
- Keep the existing dependency set; add the server-action body-size setting only.

## Verification

- Run the PTSC app tests, TypeScript check, lint, and production build.
- Confirm no file changes under Supabase, seeds, environment files, or PTSC public assets.
