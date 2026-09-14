import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import {
  PTSC_CATEGORY_COUNT,
  PTSC_POSITION_COUNT,
  PTSC_SHEET_NAMES,
  PTSC_SPORTS,
  buildNaturalKey,
  buildPtscImportPayload,
  canonicalCategoryCode,
  normalizePtscText,
  parsePtscWorkbook,
  validatePtscRows,
} from "../src/lib/ptsc-template-excel.ts";

const workbook = readFileSync(new URL("../../docs/PTSC-2026-Template-Quan-Ly-11-Mon.xlsx", import.meta.url));

test("parses the PTSC workbook without trusting formatted rows or formula text", async () => {
  const parsed = await parsePtscWorkbook(workbook);
  const payload = buildPtscImportPayload(parsed);

  assert.deepEqual(parsed.sheets, PTSC_SHEET_NAMES);
  assert.equal(parsed.sports.length, PTSC_SPORTS.length);
  assert.equal(parsed.categories.length, PTSC_CATEGORY_COUNT);
  assert.equal(parsed.positions.length, PTSC_POSITION_COUNT);
  assert.equal(new Set(parsed.positions.map((row) => row.natural_key)).size, PTSC_POSITION_COUNT);
  assert.equal(parsed.positions.filter((row) => row.sport_slug === "pickleball").length, 166);
  assert.equal(payload.positions.length, 490);
  assert.equal(payload.categories.length, 45);
  assert.equal(payload.stats.sports, 11);
  assert.equal(payload.stats.positions, 490);
  assert.ok(parsed.positions.filter((row) => row.sport_slug === "pickleball").every((row) => ["draft", "pending_confirmation"].includes(row.status)));
  assert.ok(parsed.categories.some((row) => row.code === "PB-DOI-NAM46" && row.status === "pending_confirmation"));
});

test("normalizes PTSC natural keys and Tennis aliases", () => {
  assert.equal(normalizePtscText("  Nhóm đ  "), "Nhóm đ");
  assert.equal(buildNaturalKey("TEN-DOI-NAM46-CHECK", "-", 7), "TEN-DOI-NAM46|X|7");
  assert.equal(canonicalCategoryCode("TEN-DOI-NAM46-CHECK"), "TEN-DOI-NAM46");
});

test("reports invalid categories, slots, and duplicate natural keys", () => {
  const report = validatePtscRows([
    { sheet: "01_Boi", row_number: 8, category_code: "NOT-A-CATEGORY", group: "A", slot_no: 1, kind: "individual" },
    { sheet: "01_Boi", row_number: 9, category_code: "BOI-NAM45-100", group: "A", slot_no: 0, kind: "individual" },
    { sheet: "01_Boi", row_number: 10, category_code: "BOI-NAM45-100", group: "A", slot_no: 1, kind: "pair" },
    { sheet: "01_Boi", row_number: 11, category_code: "BOI-NAM45-100", group: "A", slot_no: 1, kind: "individual" },
  ]);

  assert.ok(report.blockers.some((message) => message.includes("mã hạng mục")));
  assert.ok(report.blockers.some((message) => message.includes("slot")));
  assert.ok(report.blockers.some((message) => message.includes("khóa tự nhiên bị trùng")));
  assert.ok(report.blockers.some((message) => message.includes("loại entry")));
});
