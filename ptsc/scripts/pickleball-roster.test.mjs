import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const migration = readFileSync(new URL("../../supabase/migrations/20260914130000_ptsc_pickleball_rosters.sql", import.meta.url), "utf8");
const payload = JSON.parse(migration.match(/\$pickleball_rows\$(.*?)\$pickleball_rows\$/s)[1]);
const templateImport = readFileSync(new URL("../../supabase/migrations/20260913122010_ptsc_template_import.sql", import.meta.url), "utf8");
const baseline = JSON.parse(templateImport.slice(templateImport.indexOf("v_positions jsonb := $positions$") + "v_positions jsonb := $positions$".length, templateImport.indexOf("$positions$::jsonb")));

test("PTSC pickleball roster payload covers the ten normal categories", () => {
  const expected = {
    "PB-DON-NAM45": 28,
    "PB-DON-NAM46": 12,
    "PB-DON-NU45": 12,
    "PB-DON-NU46": 4,
    "PB-DOI-NAM45": 33,
    "PB-DOI-NAM46": 18,
    "PB-DOI-NU45": 15,
    "PB-DOI-NU46": 5,
    "PB-DOI-NAMNU45": 26,
    "PB-DOI-NAMNU46": 13,
  };
  const counts = Object.groupBy(payload, (row) => row.category_code);
  assert.deepEqual(Object.fromEntries(Object.entries(counts).map(([code, rows]) => [code, rows.length])), expected);
  assert.equal(payload.length, 166);
  assert.equal(new Set(payload.map((row) => `${row.category_code}|${row.normalized_group}|${row.slot_no}`)).size, 166);
  const baselineByKey = new Map(baseline.filter((row) => row.sport_code === "PB").map((row) => [`${row.category_code}|${row.normalized_group}|${row.slot_no}`, row]));
  for (const row of payload) {
    const source = baselineByKey.get(`${row.category_code}|${row.normalized_group}|${row.slot_no}`);
    assert.equal(source?.kind, row.kind);
    assert.equal(source?.status, row.status);
  }
});

test("PTSC pickleball roster rows contain reviewed names, units, pages, and valid sizes", () => {
  const expectedPages = {
    "PB-DON-NAM45": new Set([1, 2, 3, 4]),
    "PB-DON-NAM46": new Set([6, 7]),
    "PB-DON-NU45": new Set([9, 10]),
    "PB-DON-NU46": new Set([12]),
    "PB-DOI-NAM45": new Set([13, 14, 15, 16]),
    "PB-DOI-NAM46": new Set([18, 19, 20]),
    "PB-DOI-NU45": new Set([22, 23]),
    "PB-DOI-NU46": new Set([25]),
    "PB-DOI-NAMNU45": new Set([26, 27, 28, 29]),
    "PB-DOI-NAMNU46": new Set([31, 32]),
  };
  assert.equal(payload.every((row) => row.unit && Number.isInteger(row.pdf_page) && row.pdf_page >= 1 && row.pdf_page <= 33), true);
  assert.equal(payload.every((row) => row.members.length === (row.kind === "individual" ? 1 : 2)), true);
  assert.equal(payload.every((row) => row.members.every((name) => name.trim())), true);
  for (const [category, pages] of Object.entries(expectedPages)) assert.deepEqual(new Set(payload.filter((row) => row.category_code === category).map((row) => row.pdf_page)), pages);
  assert.equal(payload.some((row) => row.status === "pending_confirmation"), true);
  assert.match(migration, /name_vi not like 'Chờ nhập · %'/);
  assert.match(migration, /PICKLEBALL PTSC\.pdf/);
  assert.doesNotMatch(migration, /update public\.fixture_entries/);
  assert.doesNotMatch(migration, /PBLD-/);
});
