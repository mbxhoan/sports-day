import { createClient } from "@supabase/supabase-js";
import { unstable_cache } from "next/cache.js";
import { cache } from "react";
import {
  getSiteData,
  type Court,
  type Entry,
  type EntryMember,
  type Fixture,
  type FixtureEntry,
  type FixtureSlot,
  type Group,
  type GroupEntry,
  type Organization,
  type Participant,
  type SiteData,
  type Sport,
  type Standing,
  type Tournament,
  type Venue,
} from "./site.ts";
import { tenantHeaders, tenantSlug } from "./tenant.ts";

export type ShellData = Pick<SiteData, "event" | "contacts" | "footerLinks">;
export type HomeData = Pick<SiteData, "sports" | "tournaments" | "counts"> & { fixtureCounts: Record<string, number> };
export type SportsIndexData = Pick<SiteData, "sports" | "tournaments"> & { fixtureCounts: Record<string, number> };
export type SportData = {
  sport: Sport | null;
  tournaments: Tournament[];
  organizations: Organization[];
  participants: Participant[];
  entries: Entry[];
  entryMembers: EntryMember[];
  groups: Group[];
  groupEntries: GroupEntry[];
  fixtures: Fixture[];
  fixtureEntries: FixtureEntry[];
  fixtureSlots: FixtureSlot[];
  standings: Standing[];
  venues: Venue[];
  courts: Court[];
};
export type ScheduleData = Pick<SiteData, "sports" | "tournaments" | "entries" | "groups" | "groupEntries" | "fixtures" | "fixtureEntries" | "fixtureSlots" | "standings" | "venues" | "courts" | "participants" | "entryMembers">;
export type LeaderboardData = Pick<SiteData, "organizations" | "awards" | "entries" | "participants">;
export type GalleryData = { gallery_drive_url: string };
export type PageResult<T> = { shell: ShellData; data: T };

export const PUBLIC_CACHE_TAGS = ["shell", "home", "sports-index", "sport:{slug}", "schedule", "leaderboard", "gallery"] as const;
export const PUBLIC_ROUTE_TAGS = { home: "home", sportsIndex: "sports-index", sport: "sport", schedule: "schedule", leaderboard: "leaderboard", gallery: "gallery" } as const;
export const PUBLIC_QUERY_BUDGET = { home: 4, sport: 8, cacheHit: 0 } as const;
export const publicDataSource = "PUBLIC_DATA_LOADER=v1|v2; Supabase errors include a correlation ID";

type PublicPage = "shell" | "home" | "sports-index" | "sport" | "schedule" | "leaderboard" | "gallery";

export class PublicDataError extends Error {
  readonly correlationId: string;

  constructor(message: string, correlationId: string, options?: ErrorOptions) {
    super(`${message} (correlation ID: ${correlationId})`, options);
    this.name = "PublicDataError";
    this.correlationId = correlationId;
  }
}

function correlationId() {
  return globalThis.crypto?.randomUUID?.() ?? `public-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function supabaseClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key || !tenantSlug) throw new PublicDataError("Supabase public data is not configured", correlationId());
  return createClient(url, key, {
    auth: { persistSession: false },
    global: { headers: tenantHeaders(), fetch: (input, init) => fetch(input, { ...init, cache: "no-store" }) },
  });
}

async function readPublicPage(page: PublicPage, sportSlug?: string | null) {
  const id = correlationId();
  try {
    const { data, error } = await supabaseClient().rpc("get_public_page", { page, sport_slug: sportSlug ?? null });
    if (error) throw error;
    if (!data || typeof data !== "object") throw new Error("Invalid public page payload");
    return data as Record<string, unknown>;
  } catch (error) {
    if (error instanceof PublicDataError) throw error;
    throw new PublicDataError(`Unable to load public page '${page}'`, id, { cause: error });
  }
}

function shellFromSite(data: SiteData): ShellData {
  return { event: data.event, contacts: data.contacts, footerLinks: data.footerLinks };
}

function legacyData<T extends PublicPage>(data: SiteData, page: T, slug?: string): Record<string, unknown> {
  if (page === "shell") return shellFromSite(data) as unknown as Record<string, unknown>;
  if (page === "home") return { sports: data.sports, tournaments: data.tournaments, counts: data.counts, fixtureCounts: Object.fromEntries(data.sports.map((sport) => [sport.id, data.fixtures.filter((fixture) => data.tournaments.some((item) => item.id === fixture.tournament_id && item.sport_id === sport.id)).length])) };
  if (page === "sports-index") return { sports: data.sports, tournaments: data.tournaments, fixtureCounts: Object.fromEntries(data.sports.map((sport) => [sport.id, data.fixtures.filter((fixture) => data.tournaments.some((item) => item.id === fixture.tournament_id && item.sport_id === sport.id)).length])) };
  if (page === "gallery") return { gallery_drive_url: data.event.gallery_drive_url };
  if (page === "leaderboard") return { organizations: data.organizations, awards: data.awards, entries: data.entries, participants: data.participants };
  if (page === "schedule") return {
    sports: data.sports, tournaments: data.tournaments, entries: data.entries, groups: data.groups, groupEntries: data.groupEntries,
    fixtures: data.fixtures, fixtureEntries: data.fixtureEntries, fixtureSlots: data.fixtureSlots, standings: data.standings,
    venues: data.venues, courts: data.courts, participants: data.participants, entryMembers: data.entryMembers,
  };
  const sport = data.sports.find((item) => item.slug === slug) ?? null;
  const tournaments = sport ? data.tournaments.filter((item) => item.sport_id === sport.id) : [];
  const tournamentIds = new Set(tournaments.map((item) => item.id));
  const entries = data.entries.filter((item) => tournamentIds.has(item.tournament_id));
  const entryIds = new Set(entries.map((item) => item.id));
  const groups = data.groups.filter((item) => tournamentIds.has(item.tournament_id));
  const groupIds = new Set(groups.map((item) => item.id));
  const fixtures = data.fixtures.filter((item) => tournamentIds.has(item.tournament_id));
  const fixtureIds = new Set(fixtures.map((item) => item.id));
  const entryMembers = data.entryMembers.filter((item) => entryIds.has(item.entry_id));
  const participantIds = new Set(entryMembers.map((item) => item.participant_id));
  const organizationIds = new Set(entries.map((item) => item.organization_id).filter((id): id is string => Boolean(id)));
  return {
    sport, tournaments, organizations: data.organizations.filter((item) => organizationIds.has(item.id)),
    participants: data.participants.filter((item) => participantIds.has(item.id)), entries, entryMembers, groups,
    groupEntries: data.groupEntries.filter((item) => groupIds.has(item.group_id)), fixtures,
    fixtureEntries: data.fixtureEntries.filter((item) => fixtureIds.has(item.fixture_id)),
    fixtureSlots: data.fixtureSlots.filter((item) => fixtureIds.has(item.fixture_id)),
    standings: data.standings.filter((item) => tournamentIds.has(item.tournament_id)), venues: data.venues, courts: data.courts,
  };
}

function activeCompetition(shell: ShellData) {
  return !shell.event.end_at || Date.parse(shell.event.end_at) >= Date.now();
}

async function loadPage<T extends PublicPage>(page: T, slug?: string): Promise<PageResult<Record<string, unknown>>> {
  const version = process.env.PUBLIC_DATA_LOADER?.trim().toLowerCase() || "v2";
  if (version === "v1") {
    const snapshot = await getSiteData();
    return { shell: shellFromSite(snapshot), data: legacyData(snapshot, page, slug) };
  }
  if (version !== "v2") throw new PublicDataError(`Unsupported PUBLIC_DATA_LOADER '${version}'`, correlationId());
  const shell = await cachedRpc("shell", null, "shell", 3600);
  if (page === "shell") return { shell: shell as unknown as ShellData, data: shell };
  const tag = page === "sport" ? `sport:${slug ?? ""}` : page === "sports-index" ? PUBLIC_ROUTE_TAGS.sportsIndex : page;
  const revalidate = ["sports-index", "gallery"].includes(page) ? 3600 : activeCompetition(shell as unknown as ShellData) ? 60 : 3600;
  const data = await cachedRpc(page, slug ?? null, tag, revalidate);
  return { shell: shell as unknown as ShellData, data };
}

async function cachedRpc(page: PublicPage, slug: string | null, tag: string, revalidate: number) {
  return unstable_cache(
    () => readPublicPage(page, slug),
    ["public-data", tenantSlug || "missing", page, slug ?? ""],
    { revalidate, tags: [tag] },
  )();
}

export const getHomeData = cache(() => loadPage("home") as Promise<PageResult<HomeData>>);
export const getShellData = cache(() => loadPage("shell") as Promise<PageResult<ShellData>>);
export const getSportsIndexData = cache(() => loadPage("sports-index") as Promise<PageResult<SportsIndexData>>);
export const getSportData = cache((slug: string) => loadPage("sport", slug) as Promise<PageResult<SportData>>);
export const getScheduleData = cache(() => loadPage("schedule") as Promise<PageResult<ScheduleData>>);
export const getLeaderboardData = cache(() => loadPage("leaderboard") as Promise<PageResult<LeaderboardData>>);
export const getGalleryData = cache(() => loadPage("gallery") as Promise<PageResult<GalleryData>>);
