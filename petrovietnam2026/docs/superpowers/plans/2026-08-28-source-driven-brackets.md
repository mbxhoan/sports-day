# Source-Driven Brackets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seed and render every competition model from supplied sports files, then let admin safely update scores, rankings, and dependent bracket slots.

**Architecture:** Keep `fixtures`, `fixture_entries`, and `standings`; add source-defined `fixture_slots` and one `competition_mode` per tournament. Database RPCs own atomic result propagation/reset, while one shared competition-board renderer serves public and admin layouts without a bracket dependency.

**Tech Stack:** PostgreSQL/Supabase migrations and RLS, Python 3/PyMuPDF source builder, Next.js 16 App Router, React 19, TypeScript 6, CSS/SVG, Node built-in tests.

**Spec:** `docs/superpowers/specs/2026-08-28-source-driven-brackets-design.md`

## Global Constraints

- PDF wins for published names, positions, and bracket shape; Excel fills unreadable PDF data.
- Import source conflicts to production with admin-visible notes; never invent missing schedule, result, ranking, or tie-break data.
- Keep all categories on one long public board page; each bracket owns horizontal scrolling on mobile.
- Support `knockout`, `group_knockout`, `round_robin`, `swiss`, and `race` without forcing non-knockout sports into branches.
- Use final two-score input only; no per-set editor, Supabase Realtime, or new runtime dependency.
- Preserve tenant isolation, RLS, archive behavior, VI/EN copy, and current dark navy/gold UI.
- Never overwrite admin-adjusted bracket rows when seed runs again.
- Preserve unrelated working-tree changes in `petrovietnam2026/AGENTS.md` and `petrovietnam2026/next-env.d.ts`.

## File Map

- `supabase/migrations/20260828170000_source_driven_brackets.sql`: topology schema, constraints, RLS, propagation/reset RPCs.
- `supabase/tests/source_driven_brackets.sql`: executable DB behavior checks inside a rollback transaction.
- `petrovietnam2026/data/source-brackets.json`: reviewed topology manifest for every source category.
- `petrovietnam2026/scripts/build_source_brackets.py`: validate manifest and generate deterministic SQL.
- `supabase/seeds/051_source_brackets.sql`: generated competition modes, fixtures, slots, source notes.
- `petrovietnam2026/src/lib/site.ts`: public types and Supabase reads.
- `petrovietnam2026/src/lib/brackets.ts`: pure slot labels, bracket topology, race ranking helpers.
- `petrovietnam2026/src/components/competition-board.tsx`: shared public/admin board renderer.
- `petrovietnam2026/src/components/schedule-view.tsx`: three schedule modes, filters, refresh.
- `petrovietnam2026/src/components/sport-tabs.tsx`: sport board integration.
- `petrovietnam2026/src/app/admin/sports/[slug]/page.tsx`: board-first admin page and edit panels.
- `petrovietnam2026/src/app/admin/actions.ts`: result, structure, race, rank, reset actions.
- `petrovietnam2026/src/app/globals.css`: bracket coordinates, tables, responsive, print.
- `petrovietnam2026/scripts/data.test.mjs`: source/schema/UI contract checks.
- `petrovietnam2026/scripts/brackets.test.mjs`: pure topology and ranking checks.

---

### Task 1: Add competition modes and source slots

**Files:**
- Create: `supabase/migrations/20260828170000_source_driven_brackets.sql`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- Produces: `tournaments.competition_mode`, `fixture_slots`, `fixture_entries.result_status`.
- Consumes: current tenant helpers `private.current_tenant_id()`, `private.seed_tenant_id()`, `private.is_admin(uuid)`, `private.enforce_same_tenant()`.

- [ ] **Step 1: Write failing schema contract test**

Append exact assertions:

```js
const bracketMigration = readFileSync(new URL("../../supabase/migrations/20260828170000_source_driven_brackets.sql", import.meta.url), "utf8");

test("database models source-driven competition slots", () => {
  assert.match(bracketMigration, /competition_mode text not null default 'round_robin'/);
  assert.match(bracketMigration, /create table public\.fixture_slots/);
  assert.match(bracketMigration, /unique \(fixture_id, side\)/);
  assert.match(bracketMigration, /source_kind in \('entry', 'group_rank', 'fixture_winner', 'fixture_loser', 'bye'\)/);
  assert.match(bracketMigration, /result_status text/);
  assert.match(bracketMigration, /fixture_slots_public_read/);
});
```

- [ ] **Step 2: Run test; confirm missing migration failure**

Run: `rtk npm test -- --test-name-pattern='source-driven competition slots'`

Expected: FAIL with `ENOENT` for migration file.

- [ ] **Step 3: Create minimal schema migration**

Use text checks, not PostgreSQL enums, so later migrations stay simple:

```sql
alter table public.tournaments
  add column competition_mode text not null default 'round_robin'
  check (competition_mode in ('knockout','group_knockout','round_robin','swiss','race'));

alter table public.fixture_entries
  add column result_status text
  check (result_status is null or result_status in ('finished','dns','dnf','dsq'));

create unique index fixture_entries_side_key
  on public.fixture_entries (fixture_id, side)
  where side is not null and archived_at is null;

create table public.fixture_slots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null default coalesce(private.current_tenant_id(), private.seed_tenant_id()) references public.tenants(id),
  fixture_id uuid not null references public.fixtures(id),
  side text not null check (side in ('home','away')),
  source_kind text not null check (source_kind in ('entry','group_rank','fixture_winner','fixture_loser','bye')),
  source_entry_id uuid references public.entries(id),
  source_group_id uuid references public.groups(id),
  source_fixture_id uuid references public.fixtures(id),
  source_rank integer check (source_rank > 0),
  label_vi text not null default '',
  label_en text not null default '',
  archived_at timestamptz,
  unique (fixture_id, side),
  check (
    (source_kind = 'entry' and source_entry_id is not null and source_group_id is null and source_fixture_id is null and source_rank is null) or
    (source_kind = 'group_rank' and source_entry_id is null and source_group_id is not null and source_fixture_id is null and source_rank is not null) or
    (source_kind in ('fixture_winner','fixture_loser') and source_entry_id is null and source_group_id is null and source_fixture_id is not null and source_rank is null) or
    (source_kind = 'bye' and source_entry_id is null and source_group_id is null and source_fixture_id is null and source_rank is null)
  )
);
```

Add same-tenant trigger for all four FKs, active indexes, RLS, public/admin select, admin insert/update, and DELETE revoke matching existing migration patterns. Add trigger validation that source and destination fixtures share `tournament_id` and recursive CTE rejects dependency cycles.

- [ ] **Step 4: Reset local database and rerun contract test**

Run: `rtk supabase db reset`

Run: `rtk npm test -- --test-name-pattern='source-driven competition slots'`

Expected: reset succeeds; test PASS.

- [ ] **Step 5: Commit schema**

```bash
rtk git add supabase/migrations/20260828170000_source_driven_brackets.sql petrovietnam2026/scripts/data.test.mjs
rtk git commit -m "feat: add source-driven bracket slots"
```

---

### Task 2: Propagate and reset results atomically

**Files:**
- Modify: `supabase/migrations/20260828170000_source_driven_brackets.sql`
- Create: `supabase/tests/source_driven_brackets.sql`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- Produces: `private.sync_fixture_slots(uuid) returns void`.
- Produces: replacement `public.save_fixture_result(uuid,text,uuid,text,text,jsonb,jsonb) returns void` with existing signature.
- Produces: `public.reset_fixture_dependents(uuid,boolean) returns jsonb` for preview/confirmed reset.
- Consumes: `fixture_slots`, `fixtures`, `fixture_entries`, `standings`, `awards`.

- [ ] **Step 1: Write failing RPC contract assertions**

```js
test("result RPC propagates and previews dependent reset", () => {
  assert.match(bracketMigration, /private\.sync_fixture_slots/);
  assert.match(bracketMigration, /create or replace function public\.reset_fixture_dependents/);
  assert.match(bracketMigration, /for update/);
  assert.match(bracketMigration, /Trận phụ thuộc đã có kết quả/);
});
```

Run: `rtk npm test -- --test-name-pattern='propagates and previews'`

Expected: FAIL because functions do not exist.

- [ ] **Step 2: Add executable rollback test**

`supabase/tests/source_driven_brackets.sql` starts with exact isolated data:

```sql
begin;
set local app.tenant_slug = 'petrovietnam2026';
set local role postgres;

insert into public.sports (id, tenant_id, slug, name_vi, name_en, emoji)
values ('71000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'bracket-test', 'Bracket test', 'Bracket test', 'T');

insert into public.tournaments (id, tenant_id, sport_id, slug, name_vi, name_en, competition_mode)
values ('71000000-0000-0000-0000-000000000010', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000001', 'knockout', 'Loại trực tiếp', 'Knockout', 'knockout');

insert into public.entries (id, tenant_id, tournament_id, kind, name_vi, name_en) values
  ('71000000-0000-0000-0000-000000000021', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'individual', 'A', 'A'),
  ('71000000-0000-0000-0000-000000000022', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'individual', 'B', 'B'),
  ('71000000-0000-0000-0000-000000000023', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'individual', 'C', 'C'),
  ('71000000-0000-0000-0000-000000000024', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'individual', 'D', 'D');

insert into public.fixtures (id, tenant_id, tournament_id, status, round_vi, round_en, round_order, bracket_position, winner_entry_id) values
  ('71000000-0000-0000-0000-000000000031', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'completed', 'Bán kết 1', 'Semifinal 1', 1, 1, '71000000-0000-0000-0000-000000000021'),
  ('71000000-0000-0000-0000-000000000032', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'completed', 'Bán kết 2', 'Semifinal 2', 1, 2, '71000000-0000-0000-0000-000000000023'),
  ('71000000-0000-0000-0000-000000000033', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000010', 'scheduled', 'Chung kết', 'Final', 2, 1, null);

insert into public.fixture_slots (id, tenant_id, fixture_id, side, source_kind, source_fixture_id, label_vi, label_en) values
  ('71000000-0000-0000-0000-000000000041', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000033', 'home', 'fixture_winner', '71000000-0000-0000-0000-000000000031', 'Thắng BK1', 'Winner SF1'),
  ('71000000-0000-0000-0000-000000000042', '11111111-1111-1111-1111-111111111111', '71000000-0000-0000-0000-000000000033', 'away', 'fixture_winner', '71000000-0000-0000-0000-000000000032', 'Thắng BK2', 'Winner SF2');

select private.sync_fixture_slots('71000000-0000-0000-0000-000000000031');
select private.sync_fixture_slots('71000000-0000-0000-0000-000000000032');

do $$
begin
  if not exists (select 1 from public.fixture_entries where side = 'home' and archived_at is null) then
    raise exception 'winner propagation failed';
  end if;
end $$;

rollback;
```

Continue same transaction by setting `request.headers` and `request.jwt.claims` from active seeded `admin_users`, switching to `authenticated`, then asserting `reset_fixture_dependents(id,false)` does not mutate, `reset_fixture_dependents(id,true)` resets only recursive dependents, and completed dependent blocks normal save.

- [ ] **Step 3: Implement shared slot resolver**

`private.sync_fixture_slots(p_source_fixture_id)` resolves `fixture_winner` and `fixture_loser` slots, upserts active `fixture_entries` by `(fixture_id, side)`, and clears stale dynamic rows when winner becomes null. A second branch resolves `group_rank` only when every group fixture is `completed` and requested `standings.rank` occurs once.

Add one deliberate ceiling comment:

```sql
-- ponytail: recursive tournament graph is small; move to queued propagation only if tournament writes become high-volume.
```

- [ ] **Step 4: Replace result RPC and add reset RPC**

Keep current validation and standings update. Add row locks, `result_status`, resolver call, downstream-state guard, and reset preview JSON:

```json
{"blocked": true, "fixtures": [{"id": "71000000-0000-0000-0000-000000000033", "round_vi": "Chung kết", "status": "completed"}]}
```

`p_confirm = false` never mutates. `p_confirm = true` archives dependent dynamic `fixture_entries`, clears scores/winners/status back to `scheduled`, then resyncs slots.

- [ ] **Step 5: Verify database behavior**

Run: `rtk supabase db reset`

Run: `rtk psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -v ON_ERROR_STOP=1 -f supabase/tests/source_driven_brackets.sql`

Run: `rtk npm test -- --test-name-pattern='propagates and previews'`

Expected: all PASS.

- [ ] **Step 6: Commit atomic result flow**

```bash
rtk git add supabase/migrations/20260828170000_source_driven_brackets.sql supabase/tests/source_driven_brackets.sql petrovietnam2026/scripts/data.test.mjs
rtk git commit -m "feat: propagate bracket results atomically"
```

---

### Task 3: Build reviewed source topology and deterministic seed

**Files:**
- Create: `petrovietnam2026/data/source-brackets.json`
- Create: `petrovietnam2026/scripts/build_source_brackets.py`
- Create: `supabase/seeds/051_source_brackets.sql`
- Modify: `petrovietnam2026/scripts/data.test.mjs`
- Modify: `supabase/seeds/030_sources.sql`

**Interfaces:**
- Produces: `load_manifest(path: Path) -> dict`.
- Produces: `validate_manifest(data: dict) -> None`.
- Produces: `build_sql(data: dict) -> str`.
- CLI: `python3 scripts/build_source_brackets.py --check` validates committed JSON and SQL equality.
- CLI: `python3 scripts/build_source_brackets.py --write` regenerates `supabase/seeds/051_source_brackets.sql`.

- [ ] **Step 1: Add failing manifest coverage test**

```js
test("source topology covers every supplied category", () => {
  const manifest = JSON.parse(readFileSync(new URL("../data/source-brackets.json", import.meta.url), "utf8"));
  assert.deepEqual(new Set(manifest.tournaments.map((row) => row.competition_mode)), new Set(["knockout","group_knockout","round_robin","swiss","race"]));
  assert.equal(manifest.tournaments.every((row) => row.source.file && Number.isInteger(row.source.page_or_sheet)), true);
  assert.equal(manifest.tournaments.flatMap((row) => row.fixtures ?? []).every((fixture) => fixture.slots?.length === 2), true);
});
```

Run: `rtk npm test -- --test-name-pattern='source topology covers'`

Expected: FAIL because manifest is absent.

- [ ] **Step 2: Implement validator first**

Manifest shape:

```json
{
  "version": 1,
  "tournaments": [{
    "sport_slug": "pickleball",
    "tournament_slug": "doi-nam-41-50",
    "competition_mode": "group_knockout",
    "source": {"file": "PICKLEBALL/PDF/DÔI NAM 41-50T-40.pdf", "page_or_sheet": 12, "warnings": []},
    "fixtures": [{
      "key": "match-1",
      "round_order": 1,
      "bracket_position": 1,
      "round_vi": "Vòng 1/16",
      "round_en": "Round of 32",
      "slots": [
        {"side": "home", "kind": "group_rank", "group": "Bảng J", "rank": 1, "label_vi": "1J", "label_en": "1J"},
        {"side": "away", "kind": "group_rank", "group": "Bảng I", "rank": 2, "label_vi": "2I", "label_en": "2I"}
      ]
    }]
  }]
}
```

Validator rejects duplicate tournament keys, fixture keys, sides, nonexistent fixture references, cycles, missing source assets, missing two slots, and non-contiguous bracket positions. `round_robin`, `swiss`, and `race` may have empty `fixtures` because existing schedules/entries remain canonical.

- [ ] **Step 3: Transcribe and visually reconcile sources**

Populate every tournament from 23 PDFs and 21 workbooks. For each elimination category, inspect final bracket PDF page plus paired Excel sheet. Record every match number, source slot, round, bye, H3, and two-bronze rule. PDF values win; append mismatch text to `source.warnings`. Record Swiss, race, and round-robin modes even when no branch exists.

Required source families:

```text
PICKLEBALL: 11 PDF/11 XLSX categories
BÓNG BÀN: 6 categories
CẦU LÔNG: 9 categories
KÉO CO: nam, nữ
CỜ VUA: nữ, nam dưới 45, nam trên 45
CỜ TƯỚNG: nam dưới 45, nam trên 45
BƠI LỘI: 6 events
ĐIỀN KINH: 6 events
```

- [ ] **Step 4: Generate idempotent SQL**

Use deterministic UUIDv5 from `sport_slug/tournament_slug/fixture-key/side`. SQL updates `competition_mode`, inserts missing fixtures/slots with `on conflict do nothing`, and appends warnings to `source_documents.notes` without overwriting admin-edited topology.

```python
FIXTURE_NAMESPACE = UUID("7a3e2a95-78f2-4c70-90e7-0c4706bc2026")
fixture_id = uuid5(FIXTURE_NAMESPACE, f"{sport}/{tournament}/{fixture['key']}")
```

- [ ] **Step 5: Verify manifest, generated seed, and clean reset**

Run: `rtk python3 scripts/build_source_brackets.py --write`

Run: `rtk python3 scripts/build_source_brackets.py --check`

Run: `rtk supabase db reset`

Run: `rtk npm test -- --test-name-pattern='source topology|PDF inventory|workbook source'`

Expected: all source assets covered; builder produces no diff; reset succeeds.

- [ ] **Step 6: Commit reviewed topology**

```bash
rtk git add petrovietnam2026/data/source-brackets.json petrovietnam2026/scripts/build_source_brackets.py supabase/seeds/051_source_brackets.sql supabase/seeds/030_sources.sql petrovietnam2026/scripts/data.test.mjs
rtk git commit -m "feat: seed reviewed competition topology"
```

---

### Task 4: Add shared bracket domain and layout

**Files:**
- Create: `petrovietnam2026/src/lib/brackets.ts`
- Create: `petrovietnam2026/scripts/brackets.test.mjs`
- Modify: `petrovietnam2026/src/lib/site.ts:18-95,202-249`

**Interfaces:**
- Produces: `CompetitionMode` union.
- Produces: `FixtureSlot` type.
- Produces: `slotLabel(slot, resolvedEntry, locale) -> string`.
- Produces: `layoutBracket(fixtures, slots) -> { width, height, nodes, connectors }`.
- Produces: `deriveRaceRanks(rows) -> Array<{ entry_id: string; rank: number | null }>`.

- [ ] **Step 1: Write failing pure tests**

```js
import { deriveRaceRanks, layoutBracket, slotLabel } from "../src/lib/brackets.ts";

test("layout centers parent between source matches", () => {
  const result = layoutBracket(fixtures, slots);
  assert.equal(result.nodes.find((node) => node.id === "final").y, 100);
  assert.equal(result.connectors.length, 2);
});

test("slot label preserves unresolved source", () => {
  assert.equal(slotLabel({ source_kind: "group_rank", label_vi: "Nhất A", label_en: "Group A winner" }, undefined, "vi"), "Nhất A");
});

test("race ranks valid times before non-finishers", () => {
  assert.deepEqual(deriveRaceRanks([{ entry_id: "a", score_numeric: 65.2, result_status: "finished" }, { entry_id: "b", score_numeric: null, result_status: "dnf" }]), [{ entry_id: "a", rank: 1 }, { entry_id: "b", rank: null }]);
});
```

Run: `rtk npm test -- --test-name-pattern='layout centers|slot label|race ranks'`

Expected: FAIL because module is absent.

- [ ] **Step 2: Extend public data types and query**

Add `competition_mode` to `Tournament`, `result_status`, `score_numeric`, `seed_order` to `FixtureEntry`, `fixtureSlots` to `SiteData`, and Supabase select:

```ts
db.from("fixture_slots").select("id,fixture_id,side,source_kind,source_entry_id,source_group_id,source_fixture_id,source_rank,label_vi,label_en").eq("tenant_id", tenantId)
```

- [ ] **Step 3: Implement minimal pure layout**

Use fixed constants `CARD_WIDTH = 250`, `COLUMN_GAP = 52`, `ROW_GAP = 118`. First-round `y` comes from `bracket_position`; dependent match `y` is average source match centers. Emit SVG orthogonal connector paths; no DOM measurement or dependency.

- [ ] **Step 4: Run pure and existing tests**

Run: `rtk npm test`

Run: `rtk npm run typecheck`

Expected: PASS.

- [ ] **Step 5: Commit domain layer**

```bash
rtk git add petrovietnam2026/src/lib/brackets.ts petrovietnam2026/src/lib/site.ts petrovietnam2026/scripts/brackets.test.mjs
rtk git commit -m "feat: add bracket topology layout"
```

---

### Task 5: Render complete public competition boards

**Files:**
- Create: `petrovietnam2026/src/components/competition-board.tsx`
- Modify: `petrovietnam2026/src/components/schedule-view.tsx`
- Modify: `petrovietnam2026/src/components/sport-tabs.tsx`
- Modify: `petrovietnam2026/src/components/public-pages.tsx`
- Modify: `petrovietnam2026/src/lib/site.ts`
- Modify: `petrovietnam2026/src/app/globals.css:173-247,386-480`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- Produces: `CompetitionBoard({ locale, tournaments, groups, entries, fixtures, fixtureEntries, fixtureSlots, standings, editHrefBase? })`.
- Consumes: `layoutBracket`, `slotLabel`, existing `localized`, existing navy/gold tokens.

- [ ] **Step 1: Read Next 16 client/server composition docs**

Run: `rtk rg -n "Client Components|Server Components" node_modules/next/dist/docs -g '*.md' | head -n 20`

Read matching current bundled guide before changing component boundaries.

- [ ] **Step 2: Add failing UI contract tests**

```js
const board = readFileSync(new URL("../src/components/competition-board.tsx", import.meta.url), "utf8");

test("public schedule exposes three modes and full source board", () => {
  assert.match(scheduleView, /"calendar" \| "team" \| "bracket"/);
  assert.match(board, /layoutBracket/);
  assert.match(board, /fixtureSlots/);
  assert.match(board, /competition_mode/);
  assert.match(siteLib, /board: "Bảng đấu"/);
});
```

Run: `rtk npm test -- --test-name-pattern='three modes and full source board'`

Expected: FAIL because board component is absent.

- [ ] **Step 3: Implement shared board renderer**

Render modes directly:

```tsx
switch (tournament.competition_mode) {
  case "knockout":
  case "group_knockout": return <BracketBoard locale={locale} tournament={tournament} groups={groups} entries={entries} fixtures={fixtures} fixtureEntries={fixtureEntries} fixtureSlots={fixtureSlots} standings={standings} editHrefBase={editHrefBase}/>;
  case "swiss": return <SwissBoard locale={locale} tournament={tournament} entries={entries} fixtures={fixtures} fixtureEntries={fixtureEntries} standings={standings} editHrefBase={editHrefBase}/>;
  case "race": return <RaceBoard locale={locale} tournament={tournament} entries={entries} fixtures={fixtures} fixtureEntries={fixtureEntries} editHrefBase={editHrefBase}/>;
  default: return <RoundRobinBoard locale={locale} tournament={tournament} groups={groups} entries={entries} fixtures={fixtures} fixtureEntries={fixtureEntries} standings={standings} editHrefBase={editHrefBase}/>;
}
```

Bracket uses one positioned container, SVG connectors, fixed-size cards, source labels for unresolved slots, `Chờ xếp lịch` for missing time/court, full names with wrapping, winner gold highlight, and optional `${editHrefBase}${fixture.id}#fixture-editor` link. String prop stays serializable when component is imported by client `ScheduleView`.

- [ ] **Step 4: Correct schedule modes**

Keep calendar table. Implement `team` as fixtures grouped by entry. Add `bracket` mode rendering all filtered tournaments in source order; remove current misuse where `team` renders bracket columns. Sport board tab reuses same component.

- [ ] **Step 5: Add responsive and print CSS**

Use `.competition-board-scroll { overflow-x:auto }`; board width comes from layout. At print, landscape page rule, each `.tournament-block` starts new page, cards avoid breaks, controls hidden.

- [ ] **Step 6: Run tests and production build**

Run: `rtk npm test`

Run: `rtk npm run typecheck`

Run: `rtk npm run build`

Expected: PASS; no runtime dependency added.

- [ ] **Step 7: Commit public board**

```bash
rtk git add petrovietnam2026/src/components/competition-board.tsx petrovietnam2026/src/components/schedule-view.tsx petrovietnam2026/src/components/sport-tabs.tsx petrovietnam2026/src/components/public-pages.tsx petrovietnam2026/src/lib/site.ts petrovietnam2026/src/app/globals.css petrovietnam2026/scripts/data.test.mjs
rtk git commit -m "feat: render complete competition boards"
```

---

### Task 6: Make admin board-first and safe to edit

**Files:**
- Modify: `petrovietnam2026/src/app/admin/sports/[slug]/page.tsx`
- Modify: `petrovietnam2026/src/app/admin/actions.ts`
- Modify: `petrovietnam2026/src/lib/admin-config.ts`
- Modify: `petrovietnam2026/src/lib/admin-relations.ts`
- Modify: `petrovietnam2026/src/app/globals.css`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- Produces server actions: `saveFixtureResult`, `saveFixtureSlot`, `saveConfirmedRank`, `resetFixtureDependents`.
- Consumes RPCs from Task 2 and shared `CompetitionBoard` from Task 5.

- [ ] **Step 1: Add failing admin contract test**

```js
test("admin edits results from source-shaped board", () => {
  assert.match(adminSportPage, /section="brackets"/);
  assert.match(adminSportPage, /CompetitionBoard/);
  assert.match(adminActions, /export async function saveFixtureSlot/);
  assert.match(adminActions, /export async function resetFixtureDependents/);
  assert.doesNotMatch(adminConfig, /next_fixture_id.*label/);
});
```

Run: `rtk npm test -- --test-name-pattern='source-shaped board'`

Expected: FAIL.

- [ ] **Step 2: Load and scope slots/source notes**

Add `fixture_slots` and `source_documents` queries only for `schedule`, `results`, and new `brackets` sections. Keep timeout behavior. Do not load every row for unrelated admin sections.

- [ ] **Step 3: Render board and native edit panel**

Add `Bảng đấu & kết quả` navigation. Pass `editHrefBase="?section=brackets&edit=fixture-result:"` to `CompetitionBoard`; board appends fixture ID and `#fixture-editor`. Below board, render one compact form for selected fixture. Use current Server Action and `SubmitButton`; no modal library or new client state.

- [ ] **Step 4: Implement structure edit and locking**

`saveFixtureSlot` accepts friendly values (`source_kind`, source entry/group/fixture, rank, labels) and rejects structure changes when tournament has any active fixture `live`, `completed`, scored, or won. UI uses selects, never UUID text/JSON fields.

- [ ] **Step 5: Implement reset preview/confirm**

First form submits `confirm=false`, serializes returned affected fixture summary into query state, and renders warning list. Second form posts `confirm=true` with fixture ID. Keep clear warning prose; Caveman compression does not apply to destructive confirmation copy.

- [ ] **Step 6: Run admin tests and build**

Run: `rtk npm test -- --test-name-pattern='source-shaped board|bounded wait|admin relation'`

Run: `rtk npm run typecheck`

Run: `rtk npm run build`

Expected: PASS.

- [ ] **Step 7: Commit admin board**

```bash
rtk git add petrovietnam2026/src/app/admin/sports/[slug]/page.tsx petrovietnam2026/src/app/admin/actions.ts petrovietnam2026/src/lib/admin-config.ts petrovietnam2026/src/lib/admin-relations.ts petrovietnam2026/src/app/globals.css petrovietnam2026/scripts/data.test.mjs
rtk git commit -m "feat: edit results from competition boards"
```

---

### Task 7: Complete Swiss, race, and ranking workflows

**Files:**
- Modify: `petrovietnam2026/src/lib/standings.ts`
- Modify: `petrovietnam2026/src/lib/brackets.ts`
- Modify: `petrovietnam2026/src/components/competition-board.tsx`
- Modify: `petrovietnam2026/src/app/admin/sports/[slug]/page.tsx`
- Modify: `petrovietnam2026/src/app/admin/actions.ts`
- Modify: `petrovietnam2026/scripts/brackets.test.mjs`

**Interfaces:**
- Produces: `saveRaceResults(formData)` and `saveSwissPairing(formData)`.
- Produces: `deriveRaceRanks` with tie detection.
- Reuses: current `deriveStandings` for Swiss and round-robin scoring.

- [ ] **Step 1: Extend failing behavior tests**

```js
test("race ties require confirmation", () => {
  assert.deepEqual(deriveRaceRanks([
    { entry_id: "a", score_numeric: 60, result_status: "finished" },
    { entry_id: "b", score_numeric: 60, result_status: "finished" }
  ]), [
    { entry_id: "a", rank: null },
    { entry_id: "b", rank: null }
  ]);
});

test("Swiss standings never create pairings", () => {
  assert.doesNotMatch(standingsLib, /generate.*pair/i);
});
```

Run: `rtk npm test -- --test-name-pattern='race ties|Swiss standings'`

Expected: race tie test FAIL.

- [ ] **Step 2: Implement race save path**

Parse repeated entry IDs, display times, numeric seconds, result status, lane, and optional confirmed rank. Auto-rank only unique `finished` times; DNS/DNF/DSQ rank null. Save all rows through `save_fixture_result` with `winner_entry_id = null` and explicit ranks.

- [ ] **Step 3: Implement Swiss save path**

Admin selects two entries for a scheduled round and records two numeric scores. Reuse `saveFixtureResult` and scoring rule. Never generate next pairings. Allow admin to set final rank and tie-break note through `saveConfirmedRank`.

- [ ] **Step 4: Render source tables**

Race board columns: lane, participant/team, organization, achievement, status, rank. Swiss board: round, board, two players, score; standings below. Round-robin renders match table and rankings.

- [ ] **Step 5: Verify**

Run: `rtk npm test`

Run: `rtk npm run lint`

Run: `rtk npm run typecheck`

Expected: PASS.

- [ ] **Step 6: Commit non-knockout workflows**

```bash
rtk git add petrovietnam2026/src/lib/standings.ts petrovietnam2026/src/lib/brackets.ts petrovietnam2026/src/components/competition-board.tsx petrovietnam2026/src/app/admin/sports/[slug]/page.tsx petrovietnam2026/src/app/admin/actions.ts petrovietnam2026/scripts/brackets.test.mjs
rtk git commit -m "feat: support Swiss and timed events"
```

---

### Task 8: Add refresh, print, and visual verification

**Files:**
- Modify: `petrovietnam2026/src/components/schedule-view.tsx`
- Modify: `petrovietnam2026/src/app/globals.css`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- Public schedule refreshes through `router.refresh()` every 30,000 ms while document is visible.
- Manual refresh button calls same function.
- Print uses native `window.print()`.

- [ ] **Step 1: Write failing refresh/print contract test**

```js
test("public boards refresh and print without extra dependencies", () => {
  assert.match(scheduleView, /30_000/);
  assert.match(scheduleView, /visibilityState/);
  assert.match(scheduleView, /router\.refresh\(\)/);
  assert.match(scheduleView, /window\.print\(\)/);
  assert.match(adminCss, /break-before:\s*page/);
});
```

Run: `rtk npm test -- --test-name-pattern='refresh and print'`

Expected: FAIL.

- [ ] **Step 2: Implement minimal refresh**

Use one `useEffect`, native `setInterval`, visibility guard, and cleanup. No polling library.

- [ ] **Step 3: Verify visual layouts**

Start local app: `rtk npm run dev`

Inspect `/schedule?mode=bracket` and one admin sport at 1440×1200, 1024×1366, and 390×844. Confirm all categories stack vertically, bracket connectors land on correct cards, names wrap, only bracket containers scroll horizontally, destructive reset warning is clear, and race/Swiss tables fit.

- [ ] **Step 4: Verify print**

Print to PDF. Render every output page with `pdftoppm`; inspect no card splits, clipped text, black squares, or missing connectors.

- [ ] **Step 5: Run full local gate**

```bash
rtk supabase db reset
rtk psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -v ON_ERROR_STOP=1 -f supabase/tests/source_driven_brackets.sql
rtk npm test
rtk npm run lint
rtk npm run typecheck
rtk npm run build
```

Expected: all PASS.

- [ ] **Step 6: Commit visual/refresh work**

```bash
rtk git add petrovietnam2026/src/components/schedule-view.tsx petrovietnam2026/src/app/globals.css petrovietnam2026/scripts/data.test.mjs
rtk git commit -m "feat: refresh and print competition boards"
```

---

### Task 9: Production migration and smoke test

**Files:**
- Modify only files with defects proven by production dry-run or smoke test.

**Interfaces:**
- Consumes: linked Supabase production project and existing production environment.
- Produces: migrated production schema/data; no code artifact beyond proven repair.

- [ ] **Step 1: Confirm exact production target without mutation**

Run: `rtk supabase projects list`

Run: `rtk supabase migration list --linked`

Verify linked project ID matches Petrovietnam production. Stop if ambiguous.

- [ ] **Step 2: Create recoverable backup**

Run:

```bash
rtk supabase db dump --linked -f /private/tmp/petrovietnam2026-pre-brackets-schema.sql
rtk supabase db dump --linked --data-only -f /private/tmp/petrovietnam2026-pre-brackets-data.sql
rtk test -s /private/tmp/petrovietnam2026-pre-brackets-schema.sql
rtk test -s /private/tmp/petrovietnam2026-pre-brackets-data.sql
```

Expected: both backup files non-empty; keep outside git until smoke test passes.

- [ ] **Step 3: Dry-run migration**

Run: `rtk supabase db push --linked --dry-run`

Expected: only `20260828170000_source_driven_brackets.sql` pending; no destructive drop.

- [ ] **Step 4: Apply migration and seed**

Run: `rtk supabase db push --linked`

Require task-specific secret `PETROVIETNAM_PROD_DATABASE_URL`, then run:

```bash
rtk psql "$PETROVIETNAM_PROD_DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/seeds/051_source_brackets.sql
```

Do not run `supabase db reset --linked`.

- [ ] **Step 5: Reconcile production counts**

Query active tournaments by `competition_mode`, fixtures per round, two slots per bracket fixture, missing source references, cycles, and orphaned fixture entries. Expected: zero integrity errors; counts equal manifest.

- [ ] **Step 6: Smoke test public/admin**

Verify public long board, one knockout result propagation, one group-rank block, one race update, one Swiss result, reset preview without confirm, mobile layout, and print. Restore test values immediately if production data was used.

- [ ] **Step 7: Final verification and repair handling**

Run local full gate again after any production-proven repair. Return to task owning changed file, repeat its exact test and commit step. Skip repair commit when no defect exists.
