import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { deriveRaceRanks, layoutBracket, slotLabel } from "../src/lib/brackets.ts";

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
  assert.equal(result.nodes.find((node) => node.id === "final").y, 100);
  assert.equal(result.connectors.length, 2);
});

test("slot label preserves unresolved source", () => {
  assert.equal(slotLabel({ source_kind: "group_rank", label_vi: "Nhất A", label_en: "Group A winner" }, undefined, "vi"), "Nhất A");
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
