import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import * as bracketHelpers from "../src/lib/brackets.ts";

const { deriveRaceRanks, layoutBracket, resolveSlotEntry, slotCandidateLabel, slotLabel, slotSourceLabel } = bracketHelpers;

const fixtures = [
  { id: "semi-1", round_order: 1, bracket_position: 1 },
  { id: "semi-2", round_order: 1, bracket_position: 2 },
  { id: "final", round_order: 2, bracket_position: 1 },
];
const slots = [
  { fixture_id: "final", source_kind: "fixture_winner", source_fixture_id: "semi-1" },
  { fixture_id: "final", source_kind: "fixture_winner", source_fixture_id: "semi-2" },
];

test("layout centers parent between source matches", () => {
  const result = layoutBracket(fixtures, slots);
  assert.equal(result.nodes.find((node) => node.id === "final").y, 132);
  assert.equal(result.connectors.length, 2);
  assert.equal(result.connectors.filter((connector) => connector.targetId === "final").filter((connector) => connector.path.includes("V")).length, 1);
});

test("slot label preserves unresolved source", () => {
  assert.equal(slotLabel({ source_kind: "group_rank", label_vi: "Nhất A", label_en: "Group A winner" }, undefined, "vi"), "Nhất A");
});

test("slot resolution replaces group rank with the mapped entry", () => {
  const entry = { id: "entry-a", tournament_id: "tournament-1", organization_id: null, kind: "pair", name_vi: "Đội A / Đội B", name_en: "Team A / Team B" };
  const resolved = resolveSlotEntry(
    { source_kind: "group_rank", source_group_id: "group-k", source_rank: 2, source_entry_id: null, source_fixture_id: null },
    { entries: [entry], standings: [{ id: "standing-1", tournament_id: "tournament-1", group_id: "group-k", entry_id: "entry-a", played: 3, won: 2, drawn: 0, lost: 1, score_for: 6, score_against: 2, points: 6, rank: 2 }], fixtures: [], fixtureEntries: [] },
  );
  assert.equal(resolved?.name_vi, "Đội A / Đội B");
});

test("fixture sides recover legacy rows without side labels", () => {
  const rows = [
    { entry_id: "a", side: null },
    { entry_id: "b", side: null },
  ];
  const resolved = bracketHelpers.fixtureSides?.(rows);
  assert.deepEqual(resolved?.map((row) => row?.entry_id), ["a", "b"]);
});

test("slot candidate label shows the real teams behind an unresolved group rank", () => {
  assert.equal(slotCandidateLabel([
    { name_vi: "Đội A / VĐV A", name_en: "Team A / Athlete A" },
    { name_vi: "Đội B / VĐV B", name_en: "Team B / Athlete B" },
  ], "vi"), "Đội A / VĐV A · Đội B / VĐV B");
});

test("group rank label explains the source without opaque bracket codes", () => {
  assert.equal(slotSourceLabel({ source_kind: "group_rank", source_rank: 2 }, "Bảng K", "vi"), "Nhì Bảng K");
});

test("race ranks valid times before non-finishers", () => {
  assert.deepEqual(deriveRaceRanks([
    { entry_id: "a", score_numeric: 65.2, result_status: "finished" },
    { entry_id: "b", score_numeric: null, result_status: "dnf" },
  ]), [{ entry_id: "a", rank: 1 }, { entry_id: "b", rank: null }]);
});

const source = JSON.parse(readFileSync(new URL("../data/source-brackets.json", import.meta.url), "utf8"));
const tournament = (sport, slug) => source.tournaments.find((item) => item.sport_slug === sport && item.tournament_slug === slug);

test("source topology preserves approved PDF decisions", () => {
  const men4150 = tournament("pickleball", "doi-nam-41-50");
  assert.deepEqual(men4150.fixtures[0].slots.map((slot) => slot.label_vi), ["1J", "2I"]);
  assert.deepEqual(men4150.fixtures.find((fixture) => fixture.source_code === "5").slots.map((slot) => slot.label_vi), ["Thắng 1", "1A"]);
  const women4150 = tournament("pickleball", "doi-nu-41-50");
  assert.equal(women4150.source.page_or_sheet, 3);
  assert.equal(women4150.fixtures.length, 7);
  const women50 = tournament("pickleball", "doi-nu-tren-50");
  assert.equal(women50.competition_mode, "round_robin");
  assert.equal(women50.fixtures.length, 0);
});

test("under-30 pickleball bracket keeps source-fed rounds aligned", () => {
  const under30 = tournament("pickleball", "doi-nam-nu-duoi-30");
  const result = layoutBracket(
    under30.fixtures.map((fixture) => ({ id: fixture.key, round_order: fixture.round_order, bracket_position: fixture.bracket_position })),
    under30.fixtures.flatMap((fixture) => fixture.slots.map((slot) => ({ fixture_id: fixture.key, source_kind: slot.kind, source_fixture_id: slot.fixture ?? null }))),
  );
  const nodes = new Map(result.nodes.map((node) => [node.id, node]));
  assert.equal(nodes.get("match-10").y, nodes.get("match-6").y);
  assert.equal(nodes.get("match-9").y, (nodes.get("match-4").y + nodes.get("match-5").y) / 2);
  assert.equal(result.connectors.filter((connector) => connector.targetId === "match-9").filter((connector) => connector.path.includes("V")).length, 1);
});

test("bronze match does not overlap final", () => {
  const bracketFixtures = [
    { id: "semi-1", round_order: 1, bracket_position: 1 },
    { id: "semi-2", round_order: 1, bracket_position: 2 },
    { id: "final", round_order: 2, bracket_position: 1 },
    { id: "bronze", round_order: 2, bracket_position: 2 },
  ];
  const bracketSlots = [
    { fixture_id: "final", source_fixture_id: "semi-1" }, { fixture_id: "final", source_fixture_id: "semi-2" },
    { fixture_id: "bronze", source_fixture_id: "semi-1" }, { fixture_id: "bronze", source_fixture_id: "semi-2" },
  ];
  const result = layoutBracket(bracketFixtures, bracketSlots);
  assert.notEqual(result.nodes.find((node) => node.id === "final").y, result.nodes.find((node) => node.id === "bronze").y);
});
