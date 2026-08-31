export function standingDifference(row: { score_for: number | string | null | undefined; score_against: number | string | null | undefined }) {
  const scoreFor = Number(row.score_for ?? 0);
  const scoreAgainst = Number(row.score_against ?? 0);
  return (Number.isFinite(scoreFor) ? scoreFor : 0) - (Number.isFinite(scoreAgainst) ? scoreAgainst : 0);
}
