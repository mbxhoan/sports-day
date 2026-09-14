import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const page = readFileSync(new URL("../src/app/admin/sports/[slug]/page.tsx", import.meta.url), "utf8");
const actions = readFileSync(new URL("../src/app/admin/actions.ts", import.meta.url), "utf8");
const board = readFileSync(new URL("../src/components/competition-board.tsx", import.meta.url), "utf8");

test("PTSC ranking editor keeps only rank, performance and status", () => {
  const editor = page.slice(page.indexOf("function RaceResultsEditor"), page.indexOf("function SportNavLink"));
  assert.match(editor, /Nhập hạng, thành tích và trạng thái/);
  assert.doesNotMatch(editor, /name="lane"/);
  assert.match(editor, /name="score"/);
  assert.match(editor, /name="result_status"/);
});

test("PTSC race actions do not require or persist lanes", () => {
  const raceAction = actions.slice(actions.indexOf("export async function saveRaceResult"), actions.indexOf("export async function saveFixtureSlot"));
  const manualAction = actions.slice(actions.indexOf("export async function saveManualStandings"), actions.indexOf("export async function confirmGroupStandings"));
  assert.doesNotMatch(raceAction, /getAll\("lane"\)/);
  assert.match(raceAction, /lane: null/);
  assert.doesNotMatch(manualAction, /const lanes =/);
  assert.match(manualAction, /race \? \[ranks, performances, statuses\]/);
  assert.match(manualAction, /lane: null/);
});

test("public race table renders the four PTSC result fields", () => {
  const table = board.slice(board.indexOf("const manualTable"), board.indexOf("const table =", board.indexOf("const manualTable")));
  assert.match(table, /raceMode \? <><th>\{t\.performance\}<\/th><th>\{t\.status\}<\/th><\/> :/);
  assert.match(table, /raceMode \? <><td>\{race\?\.score/);
  assert.doesNotMatch(table, /raceMode && <><th>\{t\.lane\}/);
});
