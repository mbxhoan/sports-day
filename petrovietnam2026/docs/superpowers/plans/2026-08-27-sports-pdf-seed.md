# Sports PDF Seed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert every approved sports PDF into exact, idempotent operational seed data without inventing missing facts.

**Architecture:** A development-only PyMuPDF extractor writes review JSON and rendered evidence outside production paths. Reviewed data is converted to ordered SQL seeds and source-document status; application runtime reads only Supabase data.

**Tech Stack:** Python 3 with PyMuPDF/Poppler available locally, SQL seeds, Supabase CLI/Postgres, Node test runner.

**Spec:** `docs/superpowers/specs/2026-08-27-admin-sport-operations-design.md`

## Global Constraints

- Read every source page visually before marking it imported; preserve source names and create source-labeled organizations.
- Exclude `Schedule_All_Sports_2026-08-27.pdf`; no automatic parser or PDF reader ships to production.
- Seed in dependency order and use deterministic UUID/upsert data; leave ambiguous facts in `source_documents.notes`.

---

### Task 1: Build a reproducible source inventory

**Files:**
- Create: `scripts/extract_sports_pdf.py`, `docs/sports-source-manifest.md`
- Modify: `scripts/data.test.mjs`, `supabase/seeds/030_sources.sql`

**Interfaces:**
- `python3 scripts/extract_sports_pdf.py --inventory` writes `tmp/sports-pdf/inventory.json` containing filename, SHA-256, page count, sport, and page text/table candidates.

- [ ] **Step 1: Write failing inventory assertion**

```js
assert.equal(manifest.filter((row) => row.included).length, 21);
assert.equal(manifest.some((row) => row.filename === "Schedule_All_Sports_2026-08-27.pdf" && !row.included), true);
```

- [ ] **Step 2: Run it**

Run: `node --experimental-strip-types --test --test-name-pattern='PDF inventory' scripts/data.test.mjs`
Expected: FAIL because no manifest exists.

- [ ] **Step 3: Implement only inventory extraction**

```py
doc = fitz.open(path)
row = {"filename": path.name, "sha256": digest(path), "pages": len(doc), "included": path.name != EXCLUDED}
```

Write JSON beneath `tmp/` only; do not alter seeds. Record the same exact source metadata in SQL.

- [ ] **Step 4: Verify**

Run: `python3 scripts/extract_sports_pdf.py --inventory && node --experimental-strip-types --test --test-name-pattern='PDF inventory' scripts/data.test.mjs`
Expected: PASS; 22 files, 21 included, one excluded.

- [ ] **Step 5: Commit**

```bash
git add scripts/extract_sports_pdf.py docs/sports-source-manifest.md scripts/data.test.mjs supabase/seeds/030_sources.sql
git commit -m "feat: inventory sports PDF sources"
```

### Task 2: Extract and visually review each competition dataset

**Files:**
- Modify: `scripts/extract_sports_pdf.py`, `docs/sports-source-manifest.md`
- Create: `tmp/sports-pdf/review/*.json` (ignored; never commit raw extracted personal data unless user requests)

**Interfaces:**
- `--review` emits one JSON row per extracted organization, athlete, entry, group, fixture, venue, and source page; each row contains `source_page` and `confidence`.

- [ ] **Step 1: Add a failing source-location check**

```py
assert all(row["source_page"] >= 1 for row in rows)
assert not any(row["confidence"] == "guessed" for row in rows)
```

- [ ] **Step 2: Run it**

Run: `python3 scripts/extract_sports_pdf.py --review`
Expected: FAIL until every emitted row carries evidence.

- [ ] **Step 3: Implement table-first extraction and evidence rendering**

```py
for page_number, page in enumerate(doc, 1):
    tables = page.find_tables().tables
    page.get_pixmap(matrix=fitz.Matrix(1.5, 1.5)).save(render_path)
```

Extract roster/group/fixture tables by known column headers, retain raw text for malformed cells, and write ambiguity notes rather than normalizing names silently. Visually inspect every rendered page before changing a row from `review` to `verified` in the manifest.

- [ ] **Step 4: Verify review completeness**

Run: `python3 scripts/extract_sports_pdf.py --review --strict`
Expected: nonzero exit until all included PDF pages are reviewed; zero only with no guessed row.

- [ ] **Step 5: Commit extractor and reviewed manifest, never temp output**

```bash
git add scripts/extract_sports_pdf.py docs/sports-source-manifest.md
git commit -m "feat: extract reviewed sports source data"
```

### Task 3: Generate exact idempotent SQL seeds

**Files:**
- Create: `supabase/seeds/026_pdf_rosters.sql`, `supabase/seeds/027_pdf_competition.sql`
- Modify: `supabase/seeds/030_sources.sql`, `scripts/data.test.mjs`

**Interfaces:**
- `026` upserts source-labeled organizations, participants, entries, entry members.
- `027` upserts venues/courts/groups/group entries/fixtures/fixture entries/standings/awards only when verified by source; `030` sets `imported=true` only for fully seeded source.

- [ ] **Step 1: Add failing per-source seed count tests**

```js
assert.match(rosters, /insert into public\.participants/);
assert.match(competition, /insert into public\.fixtures/);
assert.ok(!competition.includes("Schedule_All_Sports_2026-08-27.pdf"));
```

- [ ] **Step 2: Run it**

Run: `node --experimental-strip-types --test --test-name-pattern='PDF seed' scripts/data.test.mjs`
Expected: FAIL.

- [ ] **Step 3: Generate ordered SQL from verified review JSON**

```sql
insert into public.organizations (id, code, name_vi, name_en)
values (...)
on conflict (code) do update set name_vi = excluded.name_vi, name_en = excluded.name_en;
```

Use deterministic IDs, dollar-quoted text where needed, and `on conflict` only against actual unique constraints. Preserve names verbatim; apply no inferred translation or result.

- [ ] **Step 4: Verify a clean full database reset**

Run: `supabase db reset && psql postgresql://postgres:postgres@127.0.0.1:55322/postgres -c "select count(*) from public.participants" && node --experimental-strip-types --test --test-name-pattern='PDF seed' scripts/data.test.mjs`
Expected: reset succeeds, count equals reviewed manifest total, tests pass.

- [ ] **Step 5: Commit**

```bash
git add supabase/seeds/026_pdf_rosters.sql supabase/seeds/027_pdf_competition.sql supabase/seeds/030_sources.sql scripts/data.test.mjs
git commit -m "feat: seed verified sports competition data"
```

### Task 4: Final data integrity audit

**Files:**
- Modify only proven defects in: `supabase/seeds/026_pdf_rosters.sql`, `supabase/seeds/027_pdf_competition.sql`, `supabase/seeds/030_sources.sql`, `docs/sports-source-manifest.md`

- [ ] **Step 1: Check foreign-key and source reconciliation**

Run: SQL queries for orphaned members, fixture entries, group entries, standings, awards, and `source_documents.imported` rows without verified manifest entries.
Expected: zero rows in each query.

- [ ] **Step 2: Check duplicate logical identities**

Run: SQL grouping by `(tournament_id, name_vi)`, `(group_id, entry_id)`, `(fixture_id, entry_id)`, and `organizations.code`.
Expected: no duplicate rows outside intentional, documented same-name source entities.

- [ ] **Step 3: Re-render and compare evidence**

Run: `python3 scripts/extract_sports_pdf.py --review --strict`
Expected: every source page signed off in manifest and all seeded names/counts exactly match review JSON.

- [ ] **Step 4: Run final checks**

Run: `supabase db reset && npm test && npm run lint && npm run typecheck && npm run build`
Expected: all pass.

- [ ] **Step 5: Commit verified repairs only**

```bash
git add supabase/seeds/026_pdf_rosters.sql supabase/seeds/027_pdf_competition.sql supabase/seeds/030_sources.sql docs/sports-source-manifest.md scripts/extract_sports_pdf.py scripts/data.test.mjs
git commit -m "fix: reconcile seeded sports source data"
```
