export function standingDifference(row: { score_for: number | string | null | undefined; score_against: number | string | null | undefined }) {
  const scoreFor = Number(row.score_for ?? 0);
  const scoreAgainst = Number(row.score_against ?? 0);
  return (Number.isFinite(scoreFor) ? scoreFor : 0) - (Number.isFinite(scoreAgainst) ? scoreAgainst : 0);
}

type ScoreValue = string | number | null | undefined;

export function formatMatchResult(homeName: string, homeScore: ScoreValue, awayScore: ScoreValue, awayName: string) {
  const names = [homeName.trim(), awayName.trim()];
  const scores = [homeScore, awayScore].map((score) => score == null ? "" : String(score).trim());
  return names.every(Boolean) && scores.every(Boolean) ? `${names[0]} ${scores[0]} - ${scores[1]} ${names[1]}` : "";
}

export function normalizeLegacyMatchResult(summary: string, homeName: string, awayName: string) {
  const home = homeName.trim();
  const away = awayName.trim();
  const generic = summary.match(/^(.*?)\s+(\d+(?:[.,]\d+)?)\s*-\s+(.*?)\s+(\d+(?:[.,]\d+)?)$/);
  if ((!home || !away) && generic) return `${generic[1]} ${generic[2]} - ${generic[4]} ${generic[3]}`;
  const homeStart = summary.indexOf(home);
  const awayStart = summary.indexOf(away, homeStart + home.length);
  if (!summary || !home || !away || homeStart < 0 || awayStart < 0) return summary;
  const homeScore = summary.slice(homeStart + home.length, awayStart).match(/(\d+(?:[.,]\d+)?)\s*-\s*$/)?.[1];
  const awayScore = summary.slice(awayStart + away.length).match(/^\s*(\d+(?:[.,]\d+)?)/)?.[1];
  return formatMatchResult(home, homeScore, awayScore, away) || summary;
}
