export const manualSportSlugs = new Set(["co-vua", "co-tuong", "boi-loi", "dien-kinh"]);

export function isManualSport(slug: string) {
  return manualSportSlugs.has(slug);
}

export function validateGalleryDriveUrl(value: string) {
  if (!value) return true;
  try {
    const url = new URL(value);
    return url.protocol === "https:" && url.hostname === "drive.google.com";
  } catch {
    return false;
  }
}

export function orderManualStandings<T extends { entry_id: string; rank: number | null }>(rows: T[], sourceOrder: string[]) {
  const order = new Map(sourceOrder.map((id, index) => [id, index]));
  return [...rows].sort((a, b) => (a.rank ?? Number.MAX_SAFE_INTEGER) - (b.rank ?? Number.MAX_SAFE_INTEGER) || (order.get(a.entry_id) ?? Number.MAX_SAFE_INTEGER) - (order.get(b.entry_id) ?? Number.MAX_SAFE_INTEGER));
}
