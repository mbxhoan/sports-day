import { revalidatePath, revalidateTag, updateTag } from "next/cache";

export type PublicDomain = "event" | "sport" | "roster" | "schedule" | "result" | "leaderboard" | "scoring" | "media" | "excel";

const pathsByTag: Record<string, string[]> = {
  home: ["/", "/en"],
  "sports-index": ["/sports", "/en/sports"],
  schedule: ["/schedule", "/en/schedule"],
  leaderboard: ["/leaderboard", "/en/leaderboard"],
  gallery: ["/gallery", "/en/gallery"],
};

export function invalidatePublic(domain: PublicDomain, sportSlug?: string) {
  if (domain === "leaderboard") updateTag("site-data");
  else revalidateTag("site-data", "max");
  const tags = new Set<string>();
  if (domain === "event") ["shell", "home", "sports-index", "schedule", "leaderboard", "gallery"].forEach((tag) => tags.add(tag));
  if (domain === "sport") ["home", "sports-index", "schedule"].forEach((tag) => tags.add(tag));
  if (domain === "roster") ["home", "schedule", "leaderboard"].forEach((tag) => tags.add(tag));
  if (domain === "schedule") tags.add("schedule");
  if (domain === "result") ["schedule", "leaderboard"].forEach((tag) => tags.add(tag));
  if (domain === "scoring") tags.add("schedule");
  if (domain === "leaderboard" || domain === "excel") tags.add("leaderboard");
  if (domain === "excel") ["home", "sports-index", "schedule"].forEach((tag) => tags.add(tag));
  if (domain === "media") tags.add("gallery");
  if (sportSlug) tags.add(`sport:${sportSlug}`);
  const paths = new Set<string>();
  for (const tag of tags) {
    if (domain === "leaderboard" && tag === "leaderboard") updateTag(tag);
    else revalidateTag(tag, "max");
    for (const path of pathsByTag[tag] ?? []) paths.add(path);
  }
  for (const path of paths) revalidatePath(path);
  if (sportSlug) {
    revalidatePath(`/sports/${sportSlug}`);
    revalidatePath(`/en/sports/${sportSlug}`);
  }
}

export function publicDomainForEntity(entity: string): PublicDomain {
  if (["sports", "tournaments"].includes(entity)) return "sport";
  if (["participants", "entries", "entry_members"].includes(entity)) return "roster";
  if (["groups", "group_entries", "venues", "courts"].includes(entity)) return "schedule";
  if (["fixtures", "fixture_entries", "fixture_slots", "standings"].includes(entity)) return "result";
  if (["awards", "organizations"].includes(entity)) return "leaderboard";
  if (entity === "media") return "media";
  return "event";
}
