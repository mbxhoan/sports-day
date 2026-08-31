# Competition Operations Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hiển thị đầy đủ bảng điểm, khôi phục lịch 8 môn, thêm search tenant-scoped, và cho admin sửa kết quả trực tiếp trên bracket.

**Architecture:** Mở rộng RPC `save_manual_standings` hiện có bằng migration additive, không thêm cột vì `standings` đã có đủ dữ liệu nguồn. Public và admin dùng cùng helper tính `+/-`; lịch dùng fixture hiện hữu; search dùng combobox client nhẹ; bracket dùng native `<dialog>` và server action `saveFixtureResult` hiện có.

**Tech Stack:** Next.js 16 App Router, React 19, TypeScript, Supabase/Postgres, Node test runner, native HTML `<dialog>`.

**Spec:** `docs/superpowers/specs/2026-08-31-competition-operations-feedback-design.md`

## Global Constraints

- Chỉ sửa tenant `petrovietnam2026`; PTSC giữ nguyên dữ liệu và hành vi.
- Không xoá dữ liệu, không sửa migration cũ, không tự tạo fixture, không thêm dependency.
- `+/-` luôn bằng `score_for - score_against`.
- `rank` thủ công không bị kết quả fixture ghi đè.
- Ghi dữ liệu admin vẫn qua auth, tenant checks, server action và RPC hiện có.
- Fixture thiếu giờ/sân hiển thị `Chưa xếp lịch`; không suy đoán.
- Chạy test/lint/typecheck/build trước khi chụp screenshot.

---

### Task 1: Add regression tests and search/standings pure helpers

**Files:**
- Create: `petrovietnam2026/src/lib/competition-display.ts`
- Create: `petrovietnam2026/src/lib/search.ts`
- Modify: `petrovietnam2026/scripts/data.test.mjs`
- Modify: `petrovietnam2026/scripts/brackets.test.mjs`

**Interfaces:**
- `standingDifference(row: { score_for: number | string | null; score_against: number | string | null }): number`
- `normalizeSearch(value: string): string`
- `matchesSearch(value: string, query: string): boolean`
- `type SearchSuggestion = { id: string; kind: "participant" | "entry" | "fixture"; label: string; detail: string; searchText: string }`
- `buildSearchSuggestions(input: { participants: Array<{id: string; full_name: string; organization?: string}>; entries: Array<{id: string; name: string; tournament?: string}>; fixtures: Array<{id: string; label: string; detail: string}> }): SearchSuggestion[]`

- [ ] **Step 1: Write failing pure-helper tests**

Add to `data.test.mjs`:

```js
import { standingDifference } from "../src/lib/competition-display.ts";
import { buildSearchSuggestions, matchesSearch } from "../src/lib/search.ts";

test("standing difference uses score for minus score against", () => {
  assert.equal(standingDifference({ score_for: 8, score_against: 3 }), 5);
  assert.equal(standingDifference({ score_for: null, score_against: null }), 0);
});

test("search suggestions cover participants, entries, and fixtures", () => {
  const suggestions = buildSearchSuggestions({
    participants: [{ id: "p1", full_name: "Nguyễn An", organization: "PVN" }],
    entries: [{ id: "e1", name: "Nguyễn An / Trần Bình", tournament: "Bảng A" }],
    fixtures: [{ id: "f1", label: "Trận 1", detail: "Bảng A · Nguyễn An / Trần Bình" }],
  });
  assert.deepEqual(suggestions.map((item) => item.kind), ["participant", "entry", "fixture"]);
  assert.equal(matchesSearch("Nguyễn An / Trần Bình", "nguyen an"), true);
});
```

Add source assertions to `data.test.mjs`:

```js
assert.match(competitionBoard, /<dialog/);
assert.match(scheduleView, /search/);
assert.match(publicPages, /standingDifference/);
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `npm test -- --test-name-pattern="standing difference|search suggestions"`

Expected: FAIL because helper modules and new UI contracts do not exist yet.

- [ ] **Step 3: Implement the two pure helpers**

Keep normalization dependency-free: lowercase, Unicode NFD, remove combining marks, replace non-alphanumeric runs with spaces, trim. `standingDifference` converts finite numeric values and returns `score_for - score_against`, otherwise treating missing values as zero. `buildSearchSuggestions` returns input order, one suggestion per supplied item, and uses `label + detail` as `searchText`.

- [ ] **Step 4: Run focused tests**

Run: `npm test -- --test-name-pattern="standing difference|search suggestions"`

Expected: PASS.

- [ ] **Step 5: Commit only helper and test files**

```bash
git add petrovietnam2026/src/lib/competition-display.ts petrovietnam2026/src/lib/search.ts petrovietnam2026/scripts/data.test.mjs petrovietnam2026/scripts/brackets.test.mjs
git commit -m "test: cover competition display and search behavior"
```

---

### Task 2: Extend manual standings RPC without changing its signature

**Files:**
- Create: `supabase/migrations/20260831100000_full_manual_standings.sql`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- Existing RPC remains `public.save_manual_standings(p_tournament_id uuid, p_group_id uuid, p_rows jsonb)`.
- Each row accepts `entry_id`, `played`, `won`, `drawn`, `lost`, `score_for`, `score_against`, `points`, `rank`.

- [ ] **Step 1: Add migration contract test**

Add to `data.test.mjs`:

```js
test("manual standings RPC accepts and persists all display fields", () => {
  assert.match(migrations, /create or replace function public\.save_manual_standings\(/);
  assert.match(migrations, /played integer/);
  assert.match(migrations, /score_for numeric/);
  assert.match(migrations, /score_against numeric/);
  assert.match(migrations, /points numeric/);
  assert.match(migrations, /rank integer/);
});
```

- [ ] **Step 2: Run contract test and verify failure**

Run: `npm test -- --test-name-pattern="manual standings RPC accepts"`

Expected: FAIL because the new migration is absent.

- [ ] **Step 3: Create additive migration**

Create `20260831100000_full_manual_standings.sql` with `create or replace function` and the existing signature. Preserve the current admin guard, tenant lookup, tournament/group membership validation, duplicate-entry validation, duplicate-rank validation for groups, archive-of-omitted-rows behavior, and group confirmation reset. Change the JSON record definition and upsert to this exact field set:

```sql
jsonb_to_recordset(p_rows) as row(
  entry_id uuid,
  played integer,
  won integer,
  drawn integer,
  lost integer,
  score_for numeric,
  score_against numeric,
  points numeric,
  rank integer
)
```

Reject any row where `played`, `won`, `drawn`, or `lost` is negative/non-integer; `score_for`, `score_against`, or `points` is non-finite/negative; or `rank` is non-null and less than 1. Upsert all eight values and keep `archived_at = null`. Keep `security invoker`, `set search_path = ''`, and grants for `authenticated`; keep public/anon revoked.

- [ ] **Step 4: Reset local DB and verify both tenants**

Run: `supabase db reset`

Then run:

```bash
psql postgresql://postgres:postgres@127.0.0.1:55322/postgres -c "select t.slug, count(*) from public.standings s join public.tenants t on t.id=s.tenant_id group by t.slug order by t.slug;"
```

Expected: migration applies without error; both tenant rows remain present; no delete or destructive migration runs.

- [ ] **Step 5: Run tests and commit migration**

Run: `npm test -- --test-name-pattern="manual standings RPC accepts"`

Expected: PASS.

```bash
git add supabase/migrations/20260831100000_full_manual_standings.sql petrovietnam2026/scripts/data.test.mjs
git commit -m "feat: persist complete manual standings"
```

---

### Task 3: Render and edit complete standings

**Files:**
- Modify: `petrovietnam2026/src/lib/site.ts`
- Modify: `petrovietnam2026/src/components/competition-board.tsx`
- Modify: `petrovietnam2026/src/app/admin/actions.ts`
- Modify: `petrovietnam2026/src/app/admin/sports/[slug]/page.tsx`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- `Standing` includes `score_for: number`, `score_against: number`.
- `standingDifference` from Task 1 is the only source for public/admin `+/-`.
- `saveManualStandings` sends the complete row payload to the unchanged RPC signature.

- [ ] **Step 1: Add UI contract assertions**

Add to `data.test.mjs`:

```js
test("standings tables expose complete manual score columns", () => {
  for (const source of [competitionBoard, adminSportPage]) {
    assert.match(source, /played/);
    assert.match(source, /score_for/);
    assert.match(source, /score_against/);
    assert.match(source, /standingDifference/);
  }
});
```

- [ ] **Step 2: Run focused test and verify failure**

Run: `npm test -- --test-name-pattern="complete manual score columns"`

Expected: FAIL because public table and manual editor do not yet render all fields.

- [ ] **Step 3: Add display type/helper usage**

Update `Standing` in `site.ts` with `score_for` and `score_against`. In `competition-board.tsx`, render group and manual tables with:

```tsx
<th>{t.rank}</th><th>{t.teams}</th><th>P</th><th>{t.wins}</th><th>{t.draws}</th><th>{t.losses}</th><th>+/-</th><th>{t.points}</th>
```

For each row, show `played`, `won`, `drawn`, `lost`, `standingDifference(row)`, and `points`. Keep source order for unranked entries and use `—` only for absent rank; numeric stat defaults remain zero. Add Vietnamese and English labels for P/W/D/L if not already present.

- [ ] **Step 4: Expand admin editor payload and controls**

In `ManualStandingsEditor`, add inputs named `played`, `won`, `drawn`, `lost`, `score_for`, `score_against`, `points`, and `rank` for every entry. Keep race-specific lane/performance/status controls. In `saveManualStandings`, read all arrays by index, parse integer fields with `Number`, parse score/points as finite numbers, reject negative values and duplicate ranks, and send:

```ts
{
  entry_id,
  played,
  won,
  drawn,
  lost,
  score_for,
  score_against,
  points,
  rank,
}
```

Do not call a standings derivation function. Keep the existing race fixture save after the standings RPC and keep result fixture saves from passing `p_standings`, so manual ranks stay intact.

- [ ] **Step 5: Run tests and typecheck**

Run: `npm test -- --test-name-pattern="complete manual score columns|manual standings"` and `npm run typecheck`

Expected: PASS.

- [ ] **Step 6: Commit standings UI/action changes**

```bash
git add petrovietnam2026/src/lib/site.ts petrovietnam2026/src/components/competition-board.tsx petrovietnam2026/src/app/admin/actions.ts petrovietnam2026/src/app/admin/sports/[slug]/page.tsx petrovietnam2026/scripts/data.test.mjs
git commit -m "feat: show and edit complete standings"
```

---

### Task 4: Restore schedule and results tabs for all sports

**Files:**
- Modify: `petrovietnam2026/src/components/schedule-view.tsx`
- Modify: `petrovietnam2026/src/components/sport-tabs.tsx`
- Modify: `petrovietnam2026/src/components/public-pages.tsx`
- Modify: `petrovietnam2026/src/app/admin/sports/[slug]/page.tsx`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- `ScheduleView` receives same arrays and includes fixture data regardless of sport mode.
- Manual sports keep manual/race/Swiss standings rendering, but their schedule uses existing fixtures.

- [ ] **Step 1: Add schedule regression assertions**

Add to `data.test.mjs`:

```js
test("all sports keep schedule visibility", () => {
  assert.doesNotMatch(scheduleView, /visibleFixtures = useMemo\(.*isManualSport/s);
  assert.doesNotMatch(sportTabs, /const sportFixtures = manual \? \[\] :/);
  assert.doesNotMatch(sportTabs, /\.\.\.\(!manual \?/);
  assert.doesNotMatch(adminSportPage, /\{!manual && <SportNavLink[\s\S]*Lịch & trận/);
});
```

- [ ] **Step 2: Run focused test and verify failure**

Run: `npm test -- --test-name-pattern="all sports keep schedule visibility"`

Expected: FAIL against current `isManualSport` exclusions.

- [ ] **Step 3: Remove manual-sport schedule exclusions**

In `schedule-view.tsx`, build `visibleFixtures` from all fixtures and `availableSports` from all sports. Keep `isManualSport` only where it controls sport-specific presentation, not schedule visibility. In `sport-tabs.tsx`, set `sportFixtures` to fixtures belonging to current sport, always add `times` and `fixtures` tabs, and pass all fixture rows to `ScheduleView`. In `public-pages.tsx`, count manual fixtures from actual data rather than forcing zero.

- [ ] **Step 4: Enable admin schedule navigation for every sport**

Remove the `!manual` guard around the admin `Lịch & trận` navigation and schedule section. Keep the existing section-specific queries and CRUD forms; do not create fixture rows. Ensure results editor remains available for manual sports through the existing manual standings flow.

- [ ] **Step 5: Run tests and build**

Run: `npm test -- --test-name-pattern="all sports keep schedule visibility|schedule"` and `npm run build`

Expected: PASS; routes build successfully.

- [ ] **Step 6: Commit schedule changes**

```bash
git add petrovietnam2026/src/components/schedule-view.tsx petrovietnam2026/src/components/sport-tabs.tsx petrovietnam2026/src/components/public-pages.tsx petrovietnam2026/src/app/admin/sports/[slug]/page.tsx petrovietnam2026/scripts/data.test.mjs
git commit -m "fix: restore schedules for manual sports"
```

---

### Task 5: Add tenant-scoped auto-suggest search

**Files:**
- Create: `petrovietnam2026/src/components/search-combobox.tsx`
- Modify: `petrovietnam2026/src/components/schedule-view.tsx`
- Modify: `petrovietnam2026/src/app/admin/sports/[slug]/page.tsx`
- Modify: `petrovietnam2026/src/app/globals.css`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- `SearchCombobox({ suggestions, value, onChange, onSelect, placeholder, label })` is a client component.
- It exposes `role="combobox"`, `aria-expanded`, `aria-controls`, and a suggestion list with keyboard navigation.
- Suggestions are created only from already tenant-scoped server props.

- [ ] **Step 1: Add search UI contract tests**

Add to `data.test.mjs`:

```js
test("search uses an accessible combobox on public schedule and admin sport pages", () => {
  const search = readFileSync(new URL("../src/components/search-combobox.tsx", import.meta.url), "utf8");
  assert.match(search, /role="combobox"/);
  assert.match(search, /aria-expanded/);
  assert.match(scheduleView, /SearchCombobox/);
  assert.match(adminSportPage, /SearchCombobox/);
});
```

- [ ] **Step 2: Run focused test and verify failure**

Run: `npm test -- --test-name-pattern="accessible combobox"`

Expected: FAIL because component and integrations do not exist.

- [ ] **Step 3: Implement native client combobox**

Create `SearchCombobox` with one text input, filtered suggestions capped at 8 visible items, active-index state, ArrowUp/ArrowDown, Enter, Escape, click selection, and click-outside close. Use suggestion `id` as React key. Do not install Select2 or another package.

- [ ] **Step 4: Integrate public schedule search**

Build suggestions from tenant-scoped `entries`, tournament names, sport names, and fixture labels. In `ScheduleView`, keep `searchTerm` state and filter `visibleFixtures` by fixture match text, tournament, sport, group, and entry names. Selecting a suggestion sets the search term and immediately filters; clearing input restores all fixtures.

- [ ] **Step 5: Integrate admin sport search**

Place the combobox in the sport admin workspace. Build suggestions from the current sport's loaded entries, participants, and fixtures. Apply selection to the relevant teams/results section using the existing query/section anchor; never query another tenant and never expose hidden fields in suggestion text. Keep existing server-side tenant filters as the authority.

- [ ] **Step 6: Add compact responsive styles**

Add only the combobox wrapper, input, suggestion list, active item, and type badge styles to `globals.css`. Ensure list overlays the toolbar with a positioned container and remains usable on mobile.

- [ ] **Step 7: Run tests and typecheck**

Run: `npm test -- --test-name-pattern="accessible combobox|search suggestions"` and `npm run typecheck`

Expected: PASS.

- [ ] **Step 8: Commit search changes**

```bash
git add petrovietnam2026/src/components/search-combobox.tsx petrovietnam2026/src/components/schedule-view.tsx petrovietnam2026/src/app/admin/sports/[slug]/page.tsx petrovietnam2026/src/app/globals.css petrovietnam2026/scripts/data.test.mjs
git commit -m "feat: add public and admin competition search"
```

---

### Task 6: Edit bracket results from an admin popup

**Files:**
- Modify: `petrovietnam2026/src/components/competition-board.tsx`
- Modify: `petrovietnam2026/src/app/admin/sports/[slug]/page.tsx`
- Modify: `petrovietnam2026/src/app/globals.css`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

**Interfaces:**
- `CompetitionBoard` accepts optional `resultAction?: (formData: FormData) => void | Promise<void>`.
- Public passes no action and remains read-only.
- Admin passes existing `saveFixtureResult`; no second write endpoint is introduced.

- [ ] **Step 1: Add popup contract assertions**

Add to `data.test.mjs`:

```js
test("admin bracket uses popup result editor and existing save action", () => {
  assert.match(competitionBoard, /<dialog/);
  assert.match(competitionBoard, /resultAction/);
  assert.match(competitionBoard, /name="score_1"/);
  assert.match(competitionBoard, /name="score_2"/);
  assert.match(adminSportPage, /resultAction=\{saveFixtureResult\}/);
});
```

- [ ] **Step 2: Run focused test and verify failure**

Run: `npm test -- --test-name-pattern="admin bracket uses popup"`

Expected: FAIL because bracket currently links to the lower editor.

- [ ] **Step 3: Add controlled native dialog**

In `CompetitionBoard`, keep selected fixture state. When `resultAction` exists, render each bracket card as a button that opens a `<dialog>` containing the current fixture's two entries, score inputs, status select, winner radio options, note input, hidden `fixture_id`, and submit button with `formAction={resultAction}`. Add close/cancel controls and close on backdrop click. Keep public card rendering unchanged when `resultAction` is absent.

- [ ] **Step 4: Pass existing server action from admin**

Pass `resultAction={saveFixtureResult}` to the admin `CompetitionBoard` call. Keep the lower result editor as a fallback/audit view so existing deep links and accessibility remain intact. The popup and lower form must use identical field names and validation behavior.

- [ ] **Step 5: Add safe pending/error behavior**

Disable popup submit while pending, keep the dialog open when validation/RPC fails, and close only after successful form action navigation/revalidation. Do not bypass `saveFixtureResult` validation or dependent-fixture reset confirmation.

- [ ] **Step 6: Style and test**

Add dialog backdrop, panel, form grid, mobile layout, and bracket button styles. Run:

```bash
npm test -- --test-name-pattern="admin bracket uses popup"
npm run lint
npm run typecheck
```

Expected: PASS with no lint/type errors.

- [ ] **Step 7: Commit bracket changes**

```bash
git add petrovietnam2026/src/components/competition-board.tsx petrovietnam2026/src/app/admin/sports/[slug]/page.tsx petrovietnam2026/src/app/globals.css petrovietnam2026/scripts/data.test.mjs
git commit -m "feat: edit bracket results in admin dialog"
```

---

### Task 7: Full verification and screenshots

**Files:**
- Create: `screenshots/feedback/competition-operations-schedule-vi.png`
- Create: `screenshots/feedback/competition-operations-standings-vi.png`
- Create: `screenshots/feedback/competition-operations-admin-bracket-vi.png`

- [ ] **Step 1: Run complete checks**

From `petrovietnam2026` run:

```bash
npm test
npm run lint
npm run typecheck
npm run build
```

From repository root run: `git diff --check`.

Expected: all commands exit 0; all tests pass; no whitespace errors.

- [ ] **Step 2: Run local browser smoke test**

Start PVN app with local Supabase variables on port `3200`. Verify:

1. `/schedule` lists Pickleball, Bóng bàn, Cầu lông, Kéo co, Cờ vua, Cờ tướng, Bơi lội, Điền kinh.
2. `/sports/co-vua`, `/sports/co-tuong`, `/sports/boi-loi`, `/sports/dien-kinh` each shows schedule tab and existing fixtures.
3. A standings table shows `Hạng`, `Đội/VĐV`, `P`, `Thắng`, `Hòa`, `Thua`, `+/-`, `Điểm`.
4. Admin sport results opens a bracket match in a dialog; public bracket has no edit controls.
5. Search suggestions show VĐV/Đội-cặp/Trận đấu and filter matching rows.
6. Browser console has no errors.

- [ ] **Step 3: Save and visually inspect screenshots**

Capture the public schedule, public standings, and admin bracket dialog at the viewport used for verification. Read each image back and inspect for clipped columns, hidden suggestions, broken modal layout, or accidental data changes before handoff.

- [ ] **Step 4: Record final status without production deployment**

Report changed files, migration name, test results, local smoke-test result, and screenshot paths. Do not claim production deployment; production migration/application remains a separate release action.
