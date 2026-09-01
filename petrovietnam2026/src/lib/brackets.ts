import type { Entry, Fixture, FixtureEntry, FixtureSlot, GroupEntry, Locale, Standing } from "./site.ts";

export const CARD_WIDTH = 300;
export const COLUMN_GAP = 64;
export const ROW_GAP = 182;
const CARD_HEIGHT = 134;
const FIRST_ROW_Y = 41;

type LayoutFixture = Pick<Fixture, "id" | "round_order" | "bracket_position">;
type LayoutSlot = Pick<FixtureSlot, "fixture_id" | "source_kind" | "source_fixture_id">;

export function slotLabel(slot: Pick<FixtureSlot, "label_vi" | "label_en" | "source_kind">, resolvedEntry: Entry | undefined, locale: Locale) {
  return resolvedEntry?.[`name_${locale}`] || slot[`label_${locale}`] || (locale === "vi" ? "Chờ xác định" : "To be determined");
}

export function slotSourceLabel(slot: Pick<FixtureSlot, "source_kind" | "source_rank">, groupName: string, locale: Locale) {
  if (slot.source_kind !== "group_rank" || !groupName || !slot.source_rank) return "";
  const rank = slot.source_rank === 1 ? (locale === "vi" ? "Nhất" : "1st") : slot.source_rank === 2 ? (locale === "vi" ? "Nhì" : "2nd") : `${locale === "vi" ? "Hạng" : "Rank"} ${slot.source_rank}`;
  return `${rank} ${groupName}`;
}

export function slotCandidateLabel(candidates: Entry[], locale: Locale) {
  return candidates.map((entry) => entry[`name_${locale}`] || entry.name_vi).join(" · ");
}

type SlotResolutionContext = {
  entries: Entry[];
  standings: Standing[];
  fixtures: Fixture[];
  fixtureEntries: FixtureEntry[];
};

export function resolveSlotEntry(slot: Pick<FixtureSlot, "source_kind" | "source_entry_id" | "source_group_id" | "source_fixture_id" | "source_rank">, context: SlotResolutionContext) {
  const entriesById = new Map(context.entries.map((entry) => [entry.id, entry]));
  if (slot.source_kind === "entry") return entriesById.get(slot.source_entry_id ?? "");
  if (slot.source_kind === "group_rank") {
    const standing = context.standings.find((row) => row.group_id === slot.source_group_id && row.rank === slot.source_rank);
    return entriesById.get(standing?.entry_id ?? "");
  }
  if (slot.source_kind === "fixture_winner") {
    const fixture = context.fixtures.find((item) => item.id === slot.source_fixture_id);
    return entriesById.get(fixture?.winner_entry_id ?? "");
  }
  if (slot.source_kind === "fixture_loser") {
    const fixture = context.fixtures.find((item) => item.id === slot.source_fixture_id);
    if (!fixture?.winner_entry_id) return undefined;
    const loser = context.fixtureEntries.filter((item) => item.fixture_id === slot.source_fixture_id).find((item) => item.entry_id !== fixture.winner_entry_id);
    return entriesById.get(loser?.entry_id ?? "");
  }
  return undefined;
}

export function slotGroupCandidates(slot: Pick<FixtureSlot, "source_kind" | "source_group_id">, groupEntries: GroupEntry[], entries: Entry[]) {
  if (slot.source_kind !== "group_rank" || !slot.source_group_id) return [];
  const entriesById = new Map(entries.map((entry) => [entry.id, entry]));
  return groupEntries.filter((item) => item.group_id === slot.source_group_id).sort((a, b) => (a.seed_order ?? Number.MAX_SAFE_INTEGER) - (b.seed_order ?? Number.MAX_SAFE_INTEGER)).map((item) => entriesById.get(item.entry_id)).filter((entry): entry is Entry => Boolean(entry));
}

export function layoutBracket(fixtures: LayoutFixture[], slots: LayoutSlot[], cardHeight = CARD_HEIGHT) {
  const rowGap = Math.max(ROW_GAP, cardHeight + 48);
  const ordered = [...fixtures].sort((a, b) => (a.round_order ?? 0) - (b.round_order ?? 0) || (a.bracket_position ?? 0) - (b.bracket_position ?? 0));
  const nodes: Array<{ id: string; x: number; y: number }> = [];
  const byId = new Map<string, { id: string; x: number; y: number }>();
  for (const fixture of ordered) {
    const round = Math.max(fixture.round_order ?? 1, 1);
    const sources = slots.filter((slot) => slot.fixture_id === fixture.id && slot.source_fixture_id).map((slot) => byId.get(slot.source_fixture_id!)).filter(Boolean) as Array<{ y: number }>;
    const sourceY = sources.length ? sources.reduce((sum, source) => sum + source.y, 0) / sources.length : null;
    const positionY = FIRST_ROW_Y + Math.max((fixture.bracket_position ?? 1) - 1, 0) * rowGap;
    const occupied = nodes.filter((node) => node.x === (round - 1) * (CARD_WIDTH + COLUMN_GAP)).map((node) => node.y);
    let y = sourceY ?? positionY;
    if (occupied.some((value) => Math.abs(value - y) < cardHeight)) y = positionY;
    while (occupied.some((value) => Math.abs(value - y) < cardHeight)) y += rowGap;
    const node = { id: fixture.id, x: (round - 1) * (CARD_WIDTH + COLUMN_GAP), y };
    nodes.push(node);
    byId.set(node.id, node);
  }
  const connectors = slots.flatMap((slot) => {
    const source = slot.source_fixture_id ? byId.get(slot.source_fixture_id) : undefined;
    const target = byId.get(slot.fixture_id);
    if (!source || !target) return [];
    const x1 = source.x + CARD_WIDTH;
    const y1 = source.y + cardHeight / 2;
    const x2 = target.x;
    const y2 = target.y + cardHeight / 2;
    const middle = x1 + COLUMN_GAP / 2;
    return [{ sourceId: source.id, targetId: target.id, path: `M${x1} ${y1} H${middle} V${y2} H${x2}` }];
  });
  const rounds = Math.max(1, ...nodes.map((node) => Math.round(node.x / (CARD_WIDTH + COLUMN_GAP)) + 1));
  return {
    width: rounds * CARD_WIDTH + Math.max(rounds - 1, 0) * COLUMN_GAP,
    height: Math.max(cardHeight, ...nodes.map((node) => node.y + cardHeight)),
    nodes,
    connectors,
  };
}

export function deriveRaceRanks(rows: Array<{ entry_id: string; score_numeric: number | null; result_status: string | null }>) {
  const valid = rows.filter((row) => row.result_status === "finished" && row.score_numeric !== null).sort((a, b) => a.score_numeric! - b.score_numeric!);
  const ranks = new Map(valid.map((row, index) => [row.entry_id, index && row.score_numeric === valid[index - 1].score_numeric ? index : index + 1]));
  return rows.map((row) => ({ entry_id: row.entry_id, rank: ranks.get(row.entry_id) ?? null }));
}
