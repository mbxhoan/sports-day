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

test("single play-in keeps its source row and routes to its bottom-branch target", () => {
  const result = layoutBracket(
    [{ id: "match-1", round_order: 1, bracket_position: 1 }, { id: "match-2", round_order: 2, bracket_position: 1 }, { id: "match-9", round_order: 2, bracket_position: 8 }],
    [{ fixture_id: "match-9", source_kind: "fixture_winner", source_fixture_id: "match-1" }],
    84,
    100,
  );
  const nodes = new Map(result.nodes.map((node) => [node.id, node]));
  assert.ok(nodes.get("match-1").y < nodes.get("match-9").y);
  assert.match(result.connectors.find((connector) => connector.sourceId === "match-1").path, /V/);
});

test("bracket layout works without Map.groupBy", () => {
  const original = Map.groupBy;
  Map.groupBy = undefined;
  try {
    assert.equal(layoutBracket(fixtures, slots).nodes.length, 3);
  } finally {
    Map.groupBy = original;
  }
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

test("source slots override stale legacy fixture rows", () => {
  const resolved = bracketHelpers.resolveMatchEntry(
    { source_kind: "fixture_winner", source_fixture_id: "semi-1", source_group_id: null, source_entry_id: null, source_rank: null },
    { entry_id: "stale-entry" },
    { entries: [], standings: [], fixtures: [{ id: "semi-1", winner_entry_id: null }], fixtureEntries: [] },
    true,
  );
  assert.equal(resolved, undefined);
});

test("fixture winners stay unresolved until a valid source result exists", () => {
  const sourceEntry = { id: "source-entry", tournament_id: "tournament-1", organization_id: null, kind: "pair", name_vi: "Đội nguồn", name_en: "Source team" };
  const staleEntry = { id: "stale-entry", tournament_id: "tournament-1", organization_id: null, kind: "pair", name_vi: "Đội cũ", name_en: "Stale team" };
  const slot = { source_kind: "fixture_winner", source_fixture_id: "semi-1", source_group_id: null, source_entry_id: null, source_rank: null };
  const base = { entries: [sourceEntry, staleEntry], standings: [], fixtureEntries: [{ fixture_id: "semi-1", entry_id: "source-entry" }] };
  assert.equal(resolveSlotEntry(slot, { ...base, fixtures: [{ id: "semi-1", status: "scheduled", winner_entry_id: "source-entry" }] }), undefined);
  assert.equal(resolveSlotEntry(slot, { ...base, fixtures: [{ id: "semi-1", status: "completed", winner_entry_id: "stale-entry" }] }), undefined);
  assert.equal(resolveSlotEntry(slot, { ...base, fixtures: [{ id: "semi-1", status: "completed", winner_entry_id: "source-entry" }] })?.id, "source-entry");
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
const pathSegments = (path) => {
  const tokens = path.match(/[A-Z]|-?\d+(?:\.\d+)?/g) ?? [];
  const segments = [];
  let x = 0;
  let y = 0;
  for (let index = 0; index < tokens.length;) {
    const command = tokens[index++];
    if (command === "M") {
      x = Number(tokens[index++]);
      y = Number(tokens[index++]);
    } else if (command === "H") {
      const nextX = Number(tokens[index++]);
      segments.push({ x1: x, y1: y, x2: nextX, y2: y });
      x = nextX;
    } else if (command === "V") {
      const nextY = Number(tokens[index++]);
      segments.push({ x1: x, y1: y, x2: x, y2: nextY });
      y = nextY;
    }
  }
  return segments;
};
const segmentsTouch = (a, b) => {
  const rangeOverlaps = (a1, a2, b1, b2) => Math.max(Math.min(a1, a2), Math.min(b1, b2)) <= Math.min(Math.max(a1, a2), Math.max(b1, b2));
  const horizontalA = a.y1 === a.y2;
  const horizontalB = b.y1 === b.y2;
  if (horizontalA && horizontalB) return a.y1 === b.y1 && rangeOverlaps(a.x1, a.x2, b.x1, b.x2);
  if (!horizontalA && !horizontalB) return a.x1 === b.x1 && rangeOverlaps(a.y1, a.y2, b.y1, b.y2);
  const horizontal = horizontalA ? a : b;
  const vertical = horizontalA ? b : a;
  return rangeOverlaps(horizontal.x1, horizontal.x2, vertical.x1, vertical.x1) && rangeOverlaps(vertical.y1, vertical.y2, horizontal.y1, horizontal.y1);
};

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

test("badminton men's PDF branches keep the approved pairings", () => {
  const expected = {
    "doi-nam-31-40": [
      ["Đoàn Văn Đặng / Nguyễn Hoàng Nam-PVCOM", "Bùi Thái Sơn / Lê Tuấn Anh-VSP"],
      ["Lê Nguyễn Hoàng Dương / Vũ Khoa Huân-PVI", "Đào Quốc Dũng / Võ Văn Thịnh-PVG"],
      ["Chung Bảo Hiếu / Lê Tiến Bảo-PVFCCo", "Nguyễn Đình Toàn / Võ Quang Khải-PVG"],
      ["Đặng Vũ Khởi / Hồ Tuấn Anh-BMĐH", "Thắng 1"],
      ["Thắng 2", "Dương Trí Quả / Trịnh Văn Thành"],
      ["Lê Minh Đức / Nguyễn Khánh Phong-PVOIL", "Đỗ Đức Thọ / Nguyễn Việt Thắng-PVD"],
      ["Thắng 3", "Nguyễn Minh Hoàng / Nguyễn Văn Hiếu-PQPOC"],
    ],
    "doi-nam-41-50": [
      ["Đào Công Thiện / Trần Xuân Ngọc", "Nguyễn Chí Trung / Nguyễn Văn Mười"],
      ["Ngô Thế Quỳnh / Nguyễn Đăng Khoa", "Nguyễn Đình Phong / Nguyễn Ngọc Ánh"],
      ["Hồ Viết Tập / Phạm Tất Lộc", "Phạm Văn Hiệu / Vũ Văn Dũng"],
      ["Bùi Anh Võ / Hồ Ngọc Hưng", "Thắng 1"],
      ["Thắng 2", "Nguyễn Trung Hải / Tất Phi Hải"],
      ["Đỗ Văn Toàn / Trần Quốc Huy", "Đặng Đình Bình / Nguyễn Hải Long"],
      ["Thắng 3", "Hoàng Quang Chính / Ng Công Anh Anh"],
    ],
  };

  for (const [slug, rounds] of Object.entries(expected)) {
    const fixtures = tournament("cau-long", slug).fixtures;
    assert.deepEqual(fixtures.slice(0, 7).map((fixture) => fixture.slots.map((slot) => slot.entry_name ?? slot.label_vi)), rounds);
  }
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

test("bracket connectors keep unrelated routes from touching", () => {
  for (const bracket of source.tournaments.filter((item) => item.fixtures?.some((fixture) => fixture.round_order !== null && fixture.bracket_position !== null))) {
    const fixtures = bracket.fixtures.map((fixture) => ({ id: fixture.key, round_order: fixture.round_order, bracket_position: fixture.bracket_position }));
    const slots = bracket.fixtures.flatMap((fixture) => fixture.slots.map((slot) => ({ fixture_id: fixture.key, source_kind: slot.kind, source_fixture_id: slot.fixture ?? null })));
    const connectors = layoutBracket(fixtures, slots, 84, 100).connectors.map((connector) => ({ ...connector, segments: pathSegments(connector.path) }));
    for (let left = 0; left < connectors.length; left += 1) {
      for (let right = left + 1; right < connectors.length; right += 1) {
        if (connectors[left].sourceId === connectors[right].sourceId || connectors[left].targetId === connectors[right].targetId) continue;
        assert.equal(connectors[left].segments.some((a) => connectors[right].segments.some((b) => segmentsTouch(a, b))), false, `${bracket.tournament_slug}: ${connectors[left].sourceId} -> ${connectors[left].targetId} / ${connectors[right].sourceId} -> ${connectors[right].targetId}`);
      }
    }
  }
});

test("badminton match 3 connector reaches match 7", () => {
  for (const slug of ["doi-nam-31-40", "doi-nam-41-50"]) {
    const bracket = tournament("cau-long", slug);
    const result = layoutBracket(
      bracket.fixtures.map((fixture) => ({ id: fixture.key, round_order: fixture.round_order, bracket_position: fixture.bracket_position })),
      bracket.fixtures.flatMap((fixture) => fixture.slots.map((slot) => ({ fixture_id: fixture.key, source_kind: slot.kind, source_fixture_id: slot.fixture ?? null }))),
      84,
      100,
    );
    const match3To7 = result.connectors.find((connector) => connector.sourceId === "match-3" && connector.targetId === "match-7");
    assert.ok(match3To7);
    assert.match(match3To7.path, /V/);
    assert.equal(result.connectors.some((connector) => connector.sourceId === "match-3" && connector.targetId === "match-6"), false);
  }
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
