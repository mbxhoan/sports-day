import type { Entry, Fixture, FixtureSlot, Locale } from "./site.ts";

export const CARD_WIDTH = 250;
export const COLUMN_GAP = 52;
export const ROW_GAP = 118;
const CARD_HEIGHT = 82;
const FIRST_ROW_Y = 41;

type LayoutFixture = Pick<Fixture, "id" | "round_order" | "bracket_position">;
type LayoutSlot = Pick<FixtureSlot, "fixture_id" | "source_kind" | "source_fixture_id">;

export function slotLabel(slot: Pick<FixtureSlot, "label_vi" | "label_en" | "source_kind">, resolvedEntry: Entry | undefined, locale: Locale) {
  return resolvedEntry?.[`name_${locale}`] || slot[`label_${locale}`] || (locale === "vi" ? "Chờ xác định" : "To be determined");
}

export function layoutBracket(fixtures: LayoutFixture[], slots: LayoutSlot[]) {
  const ordered = [...fixtures].sort((a, b) => (a.round_order ?? 0) - (b.round_order ?? 0) || (a.bracket_position ?? 0) - (b.bracket_position ?? 0));
  const nodes: Array<{ id: string; x: number; y: number }> = [];
  const byId = new Map<string, { id: string; x: number; y: number }>();
  for (const fixture of ordered) {
    const round = Math.max(fixture.round_order ?? 1, 1);
    const sources = slots.filter((slot) => slot.fixture_id === fixture.id && slot.source_fixture_id).map((slot) => byId.get(slot.source_fixture_id!)).filter(Boolean) as Array<{ y: number }>;
    const y = sources.length ? sources.reduce((sum, source) => sum + source.y, 0) / sources.length : FIRST_ROW_Y + Math.max((fixture.bracket_position ?? 1) - 1, 0) * ROW_GAP;
    const node = { id: fixture.id, x: (round - 1) * (CARD_WIDTH + COLUMN_GAP), y };
    nodes.push(node);
    byId.set(node.id, node);
  }
  const connectors = slots.flatMap((slot) => {
    const source = slot.source_fixture_id ? byId.get(slot.source_fixture_id) : undefined;
    const target = byId.get(slot.fixture_id);
    if (!source || !target) return [];
    const x1 = source.x + CARD_WIDTH;
    const y1 = source.y + CARD_HEIGHT / 2;
    const x2 = target.x;
    const y2 = target.y + CARD_HEIGHT / 2;
    const middle = x1 + COLUMN_GAP / 2;
    return [{ sourceId: source.id, targetId: target.id, path: `M${x1} ${y1} H${middle} V${y2} H${x2}` }];
  });
  const rounds = Math.max(1, ...nodes.map((node) => Math.round(node.x / (CARD_WIDTH + COLUMN_GAP)) + 1));
  return {
    width: rounds * CARD_WIDTH + Math.max(rounds - 1, 0) * COLUMN_GAP,
    height: Math.max(CARD_HEIGHT, ...nodes.map((node) => node.y + CARD_HEIGHT)),
    nodes,
    connectors,
  };
}

export function deriveRaceRanks(rows: Array<{ entry_id: string; score_numeric: number | null; result_status: string | null }>) {
  const valid = rows.filter((row) => row.result_status === "finished" && row.score_numeric !== null).sort((a, b) => a.score_numeric! - b.score_numeric!);
  const ranks = new Map(valid.map((row, index) => [row.entry_id, index && row.score_numeric === valid[index - 1].score_numeric ? index : index + 1]));
  return rows.map((row) => ({ entry_id: row.entry_id, rank: ranks.get(row.entry_id) ?? null }));
}
