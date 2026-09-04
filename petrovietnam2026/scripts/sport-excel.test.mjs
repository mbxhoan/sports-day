import assert from "node:assert/strict";
import test from "node:test";
import ExcelJS from "exceljs";
import { buildOperations, buildSportWorkbook, parseSportWorkbook, previewOperations, SPORT_EXCEL_SPORTS } from "../src/lib/sport-excel.ts";

const sportId = "10000000-0000-0000-0000-000000000001";
const orgId = "20000000-0000-0000-0000-000000000001";
const tournamentId = "30000000-0000-0000-0000-000000000001";
const entryId = "40000000-0000-0000-0000-000000000001";
const fixtureId = "50000000-0000-0000-0000-000000000001";
const fixtureEntryId = "60000000-0000-0000-0000-000000000001";
const snapshot = {
  sport_id: sportId,
  sport_slug: "pickleball",
  tables: {
    sports: [{ id: sportId, slug: "pickleball", name_vi: "Pickleball", name_en: "Pickleball", emoji: "🏓", sort_order: 1 }],
    organizations: [{ id: orgId, code: "PVN", name_vi: "Petrovietnam", name_en: "Petrovietnam", logo_path: null, leaderboard_rank: null, gold_medals: 0, silver_medals: 0, bronze_medals: 0, sort_order: 0 }],
    tournaments: [{ id: tournamentId, sport_id: sportId, slug: "nam", name_vi: "Nam", name_en: "Men", category_vi: "", category_en: "", gender: "male", format_vi: "", format_en: "", rules_vi: "", rules_en: "", competition_mode: "knockout", source_metadata: {}, scoring_rule: {}, sort_order: 0 }],
    entries: [{ id: entryId, tournament_id: tournamentId, organization_id: orgId, kind: "pair", name_vi: "A / B", name_en: "A / B", seed_number: null, bib_number: null }],
    fixtures: [{ id: fixtureId, tournament_id: tournamentId, group_id: null, venue_id: null, court_id: null, starts_at: null, ends_at: null, status: "scheduled", round_vi: "Vòng bảng", round_en: "Group", round_order: null, bracket_position: null, next_fixture_id: null, result_summary_vi: "", result_summary_en: "", winner_entry_id: null, source_code: null }],
    fixture_entries: [{ id: fixtureEntryId, fixture_id: fixtureId, entry_id: entryId, side: "home", lane: null, seed_order: null, score: null, score_numeric: null, rank: null, result_status: null, result_detail: {} }],
  },
};

test("Excel export round-trips all eight sport configurations", async () => {
  assert.equal(SPORT_EXCEL_SPORTS.length, 8);
  const buffer = await buildSportWorkbook(snapshot, "current", "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa");
  const parsed = await parseSportWorkbook(buffer);
  const operations = buildOperations(parsed, snapshot, sportId);
  assert.equal(parsed.meta.sport_slug, "pickleball");
  assert.equal(operations.operations.length, 0);
  parsed.tables.tournaments[0].values.name_vi = "Nam updated";
  parsed.tables.fixture_entries[0].values.score = "2";
  const changed = buildOperations(parsed, snapshot, sportId);
  assert.equal(changed.operations.length, 2);
  assert.equal(changed.operations[0].data.sport_id, sportId);
  assert.equal(changed.operations.find((item) => item.table === "fixture_entries")?.data.fixture_id, fixtureId);
  assert.equal(changed.operations.find((item) => item.table === "fixture_entries")?.data.score_numeric, 2);
  assert.equal(previewOperations(changed.operations).blockers.length, 0);
});

test("results view keeps only readable match sheets", async () => {
  const buffer = await buildSportWorkbook(snapshot, "current", "dddddddd-dddd-4ddd-8ddd-dddddddddddd", "results");
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);
  assert.deepEqual(workbook.worksheets.map((sheet) => sheet.name), ["HƯỚNG_DẪN", "TRẬN_ĐẤU", "KẾT_QUẢ", "_LOOKUP", "_META"]);
  const result = workbook.getWorksheet("KẾT_QUẢ");
  const headers = result.getRow(1).values;
  const scoreColumn = headers.indexOf("Tỷ số / Score");
  const numericScoreColumn = headers.indexOf("Điểm số / Numeric score");
  assert.ok(scoreColumn > 0);
  assert.equal(result.getColumn(numericScoreColumn).hidden, true);
  assert.equal(result.getCell(2, headers.indexOf("Trận / Fixture")).value, "Vòng bảng");
});

test("manual chess results use the standings sheet", async () => {
  const chess = { ...snapshot, sport_slug: "co-vua", tables: { ...snapshot.tables, standings: [{ id: "70000000-0000-4000-8000-000000000001", tournament_id: tournamentId, group_id: null, entry_id: entryId, played: 0, won: 0, drawn: 0, lost: 0, score_for: 0, score_against: 0, points: 0, rank: null, note_vi: null, note_en: null }] } };
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(await buildSportWorkbook(chess, "current", "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee", "results"));
  assert.deepEqual(workbook.worksheets.map((sheet) => sheet.name), ["HƯỚNG_DẪN", "BXH", "_LOOKUP", "_META"]);
  const standings = workbook.getWorksheet("BXH");
  assert.equal(standings.getCell(2, standings.getRow(1).values.indexOf("Đội / Entry")).value, "A / B");
  assert.equal(standings.getColumn(standings.getRow(1).values.indexOf("Điểm")).hidden, false);
});

test("Excel templates hide technical columns and show readable relation names", async () => {
  const buffer = await buildSportWorkbook(snapshot, "current", "cccccccc-cccc-4ccc-8ccc-cccccccccccc");
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);
  const entries = workbook.getWorksheet("ĐỘI");
  const headers = entries.getRow(1).values;
  const refColumn = headers.indexOf("Mã / Ref");
  const actionColumn = headers.indexOf("Thao tác / Action");
  const tournamentColumn = headers.indexOf("Hạng mục / Tournament");
  assert.ok(refColumn > tournamentColumn);
  assert.ok(actionColumn > tournamentColumn);
  assert.equal(entries.getCell(2, tournamentColumn).value, "Nam");

  entries.getCell(2, refColumn).value = null;
  entries.getCell(2, actionColumn).value = null;
  const parsed = await parseSportWorkbook(await workbook.xlsx.writeBuffer());
  assert.match(parsed.tables.entries[0].ref, /^NEW-entries-2$/);
  assert.equal(parsed.tables.entries[0].action, "UPSERT");
});

test("Excel import rejects formulas at the trust boundary", async () => {
  const buffer = await buildSportWorkbook(snapshot, "current", "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb");
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);
  workbook.getWorksheet("ĐƠN_VỊ").getCell("C2").value = { formula: "1+1" };
  const changed = await workbook.xlsx.writeBuffer();
  await assert.rejects(() => parseSportWorkbook(changed), /công thức/);
});
