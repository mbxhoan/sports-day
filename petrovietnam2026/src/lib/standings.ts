type FixtureEntry = { entry_id: string; score_numeric: number | null };
type Fixture = { status: string; entries: FixtureEntry[] };
type Rule = { type?: string; win?: number; draw?: number; loss?: number };
type Standing = { entry_id: string; played: number; won: number; drawn: number; lost: number; score_for: number; score_against: number; points: number; rank: number };

export function headToHeadRule(type: string, win: string, draw: string, loss: string): Rule {
  if (type !== "head-to-head") return {};
  const values = [win, draw, loss].map(Number);
  if (values.some((value) => !Number.isFinite(value))) throw new Error("Điểm tính không hợp lệ");
  return { type, win: values[0], draw: values[1], loss: values[2] };
}

export function deriveStandings(fixtures: Fixture[], rule: Rule): Standing[] {
  if (rule.type !== "head-to-head" || ![rule.win, rule.draw, rule.loss].every(Number.isFinite)) return [];
  const rows = new Map<string, Omit<Standing, "rank">>();
  const row = (entryId: string) => rows.get(entryId) ?? (rows.set(entryId, { entry_id: entryId, played: 0, won: 0, drawn: 0, lost: 0, score_for: 0, score_against: 0, points: 0 }).get(entryId)!);
  for (const fixture of fixtures) {
    if (fixture.status !== "completed" || fixture.entries.length !== 2) continue;
    const [home, away] = fixture.entries;
    if (!Number.isFinite(home.score_numeric) || !Number.isFinite(away.score_numeric)) continue;
    const a = row(home.entry_id), b = row(away.entry_id), homeScore = Number(home.score_numeric), awayScore = Number(away.score_numeric);
    a.played++; b.played++; a.score_for += homeScore; a.score_against += awayScore; b.score_for += awayScore; b.score_against += homeScore;
    if (homeScore === awayScore) { a.drawn++; b.drawn++; a.points += Number(rule.draw); b.points += Number(rule.draw); }
    else { const winner = homeScore > awayScore ? a : b, loser = homeScore > awayScore ? b : a; winner.won++; loser.lost++; winner.points += Number(rule.win); loser.points += Number(rule.loss); }
  }
  return [...rows.values()]
    .sort((a, b) => b.points - a.points || (b.score_for - b.score_against) - (a.score_for - a.score_against) || b.score_for - a.score_for || a.entry_id.localeCompare(b.entry_id))
    .map((item, index) => ({ ...item, rank: index + 1 }));
}
