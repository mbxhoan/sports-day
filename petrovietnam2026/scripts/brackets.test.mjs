import assert from "node:assert/strict";
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
