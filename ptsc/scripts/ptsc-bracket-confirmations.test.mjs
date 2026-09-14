import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

const migration = readFileSync(new URL("../../supabase/migrations/20260914110000_ptsc_pdf_brackets.sql", import.meta.url), "utf8");

test("PTSC PDF bracket migration keeps the confirmed source decisions", () => {
  assert.match(migration, /set app\.tenant_slug = 'ptsc2026'/);
  assert.match(migration, /v_tenant_id uuid := private\.seed_tenant_id\(\)/);
  assert.match(migration, /DK-NU45-5K\|X\|16/);
  assert.match(migration, /Hà Thị Thảo Trinh/);
  assert.match(migration, /PB-DOI-NAM46.*PB-DOI-NU45/s);
  assert.match(migration, /'QF3', 'home', 'bye'.*'Seed 2'/s);
  assert.match(migration, /'QF3', 'away', 'bye'.*'Seed 7'/s);
  assert.doesNotMatch(migration, /petrovietnam2026/);
});
