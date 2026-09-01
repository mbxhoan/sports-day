# Automatic Results and Standings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every two-side result derive its winner from the scores and keep competition standings automatically ranked without duplicate ranks.

**Architecture:** Keep the existing `save_fixture_result` RPC as the single write path for GUI and Excel. An additive PostgreSQL migration will derive winners, reject invalid ties/results, recalculate head-to-head standings from completed fixtures, and assign unique ranks by deterministic tie-breaks. The shared admin result editor will collect scores only; the bracket will present real team names and scores in round columns.

**Tech Stack:** Next.js 16 App Router, React 19, TypeScript, Supabase/Postgres, native HTML forms, Node test runner.

**Spec:** User-approved requirements in the conversation and attached bracket/editor reference.

## Global Constraints

- Preserve tenant and admin authorization checks.
- Use additive migration only; do not rewrite or delete existing data.
- GUI and Excel must call the same result RPC.
- Winner is derived from numeric scores; knockout ties are rejected.
- Automatic rank order is points, score difference, score for, then entry id.
- Every assigned rank is unique within its tournament/group.
- Unknown/manual scoring formats remain manual until a scoring rule is configured.

### Task 1: Lock result and rank behavior with tests

**Files:**
- Modify: `petrovietnam2026/scripts/data.test.mjs`
- Modify: `petrovietnam2026/scripts/brackets.test.mjs`

- [ ] Add assertions for automatic winner derivation, score-only result forms, standings recalculation RPC, and duplicate-rank validation.
- [ ] Run the focused tests and confirm they fail against the current implementation.

### Task 2: Add atomic database result/ranking rules

**Files:**
- Create: `supabase/migrations/20260901090000_auto_results_and_standings.sql`

- [ ] Replace the latest `save_fixture_result` implementation additively so the trigger derives the winner from the two active side scores, permits draws only outside knockout fixtures, and rejects missing/invalid scores for completed head-to-head matches.
- [ ] Add a private recalculation function that aggregates completed group fixtures, applies configured `scoring_rule`, ranks deterministically with `row_number()`, and upserts one unique rank per group.
- [ ] Recalculate after GUI/Excel result writes and reject duplicate manual ranks in the existing manual standings RPC.
- [ ] Run local migration/reset checks and verify the migration is non-destructive.

### Task 3: Use score-only result editing and reference-style bracket cards

**Files:**
- Modify: `petrovietnam2026/src/app/admin/actions.ts`
- Modify: `petrovietnam2026/src/components/competition-board.tsx`
- Modify: `petrovietnam2026/src/app/globals.css`

- [ ] Remove manual winner selection from the common editor and show a clear automatic-winner note.
- [ ] Render bracket headings by round and compact cards with actual entry names, scores, and winner styling.
- [ ] Keep the native dialog and inline save action accessible on mobile and desktop.

### Task 4: Protect manual fallback standings and verify all input paths

**Files:**
- Modify: `petrovietnam2026/src/app/admin/actions.ts`
- Modify: `petrovietnam2026/src/lib/site.ts`
- Modify: `petrovietnam2026/src/lib/sport-excel.ts`
- Modify: `petrovietnam2026/scripts/data.test.mjs`

- [ ] Validate duplicate ranks server-side for manual/race standings and retain explicit manual rules where automatic derivation is not configured.
- [ ] Ensure scoring rules are loaded for display and remain round-trippable through Excel.
- [ ] Run `npm test`, `npm run lint`, `npm run typecheck`, `npm run build`, and `git diff --check`.
