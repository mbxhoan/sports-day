import { createClient } from "@supabase/supabase-js";
import { cache } from "react";
import { tenantHeaders, tenantSlug } from "./tenant.ts";

export type Locale = "vi" | "en";
export type CompetitionMode = "knockout" | "group_knockout" | "round_robin" | "swiss" | "race";
export type Sport = {
  id: string;
  slug: string;
  name_vi: string;
  name_en: string;
  emoji: string;
  description_vi: string;
  description_en: string;
  rules_vi: string;
  rules_en: string;
  sort_order: number;
};
export type Tournament = {
  id: string;
  sport_id: string;
  slug: string;
  name_vi: string;
  name_en: string;
  category_vi: string;
  category_en: string;
  format_vi: string;
  format_en: string;
  rules_vi: string;
  rules_en: string;
  competition_mode: CompetitionMode;
  scoring_rule?: { type?: string; win?: number; draw?: number; loss?: number };
  source_metadata: { file?: string; page_or_sheet?: number | string; warnings?: string[] };
  sort_order: number;
};
export type Fixture = {
  id: string;
  tournament_id: string;
  group_id: string | null;
  venue_id: string | null;
  court_id: string | null;
  starts_at: string | null;
  ends_at: string | null;
  status: string;
  round_vi: string;
  round_en: string;
  result_summary_vi: string;
  result_summary_en: string;
  round_order: number | null;
  bracket_position: number | null;
  next_fixture_id: string | null;
  winner_entry_id: string | null;
  source_code: string | null;
};
export type Organization = { id: string; code: string; name_vi: string; name_en: string; logo_path: string | null; sort_order: number; leaderboard_rank?: number | null; gold_medals?: number; silver_medals?: number; bronze_medals?: number };
export type Participant = { id: string; organization_id: string | null; full_name: string; full_name_en: string | null };
export type Entry = { id: string; tournament_id: string; organization_id: string | null; kind: string; name_vi: string; name_en: string };
export type EntryMember = { id: string; entry_id: string; participant_id: string; role_vi: string; role_en: string; sort_order: number };
export type Group = { id: string; tournament_id: string; name_vi: string; name_en: string; sort_order: number; standings_confirmed_at?: string | null };
export type GroupEntry = { id: string; group_id: string; entry_id: string; seed_order: number | null };
export type Venue = { id: string; name_vi: string; name_en: string; address_vi: string; address_en: string; sort_order: number };
export type Court = { id: string; venue_id: string; name_vi: string; name_en: string; sort_order: number };
export type FixtureEntry = { id: string; fixture_id: string; entry_id: string; side: string | null; lane: number | null; seed_order: number | null; score: string | null; score_numeric: number | null; rank: number | null; result_status: string | null; result_detail?: { note?: string } };
export type FixtureSlot = { id: string; fixture_id: string; side: "home" | "away"; source_kind: "entry" | "group_rank" | "fixture_winner" | "fixture_loser" | "bye"; source_entry_id: string | null; source_group_id: string | null; source_fixture_id: string | null; source_rank: number | null; label_vi: string; label_en: string };
export type Standing = { id: string; tournament_id: string; group_id: string | null; entry_id: string; played: number; won: number; drawn: number; lost: number; score_for: number; score_against: number; points: number; rank: number | null };
export type Award = { id: string; organization_id: string | null; entry_id: string | null; participant_id: string | null; medal: "gold" | "silver" | "bronze" | "special"; title_vi: string; title_en: string };
export type Media = { id: string; storage_path: string; public_url: string; sport_id: string | null; title_vi: string; title_en: string; alt_vi: string; alt_en: string; filter_tag: string; album_vi: string; album_en: string; sort_order: number };
export type Contact = { id: string; label_vi: string; label_en: string; value: string; href: string; sort_order: number };
export type FooterLink = { id: string; label_vi: string; label_en: string; href: string; sort_order: number };
export type LeaderboardRow = { organization: Organization; gold: number; silver: number; bronze: number; special: number; total: number };
export type SiteData = {
  event: {
    event_name_vi: string;
    event_name_en: string;
    subtitle_vi: string;
    subtitle_en: string;
    about_vi: string;
    about_en: string;
    venue_vi: string;
    venue_en: string;
    hero_path: string;
    hero_mobile_path: string;
    start_at: string | null;
    end_at: string | null;
    gallery_drive_url: string;
  };
  sports: Sport[];
  tournaments: Tournament[];
  organizations: Organization[];
  participants: Participant[];
  entries: Entry[];
  entryMembers: EntryMember[];
  groups: Group[];
  groupEntries: GroupEntry[];
  venues: Venue[];
  courts: Court[];
  fixtures: Fixture[];
  fixtureEntries: FixtureEntry[];
  fixtureSlots: FixtureSlot[];
  standings: Standing[];
  awards: Award[];
  media: Media[];
  contacts: Contact[];
  footerLinks: FooterLink[];
  counts: { sports: number; organizations: number; participants: number; fixtures: number };
};

export const copy = {
  vi: {
    home: "Trang chủ", leaderboard: "Bảng xếp hạng", gallery: "Thư viện ảnh", sports: "Môn thể thao", schedule: "Lịch thi đấu", login: "Đăng nhập",
    countdown: "ĐẾM NGƯỢC ĐẾN NGÀY THI ĐẤU", days: "Ngày", hours: "Giờ", minutes: "Phút", seconds: "Giây",
    sportCount: "Môn thi đấu", dayCount: "Ngày thi đấu", unitCount: "Đơn vị", athleteCount: "Tổng VĐV", matchCount: "Trận đấu",
    allSports: "Các môn thể thao", viewDetail: "Xem chi tiết", updating: "Đang cập nhật", teamsNotAssigned: "Chưa xếp đội", footer: "Hội thao Petrovietnam 2026",
    info: "Thông tin", teams: "Đội/VĐV", times: "Khung giờ", fixtures: "Lịch đấu", brackets: "Bảng đấu",
    description: "Mô tả", rules: "Thể lệ thi đấu", details: "Chi tiết", format: "Thể thức", categories: "Hạng mục", categoryUnit: "hạng mục", fixtureUnit: "trận", competitionDay: "Ngày thi đấu",
    empty: "Chưa có dữ liệu", galleryEmpty: "Hình ảnh sự kiện sẽ được cập nhật tại đây.", leaderboardEmpty: "Bảng xếp hạng sẽ được cập nhật sau khi có kết quả.",
    filterSport: "Tất cả môn", filterCategory: "Tất cả hạng mục", filterStatus: "Tất cả trạng thái", calendar: "Theo lịch", byTeam: "Theo đội", board: "Bảng đấu", print: "Xuất PDF", scheduled: "Sắp diễn ra", live: "Đang diễn ra", completed: "Đã kết thúc", postponed: "Tạm hoãn", cancelled: "Đã huỷ",
    organization: "Đơn vị", members: "Thành viên", group: "Bảng", rank: "Hạng", played: "Trận", wins: "Thắng", draws: "Hòa", losses: "Thua", points: "Điểm", total: "Tổng", medals: "huy chương", athlete: "VĐV", lane: "Làn", performance: "Thành tích", status: "Trạng thái", openDrive: "Mở thư mục Google Drive", searchLabel: "Tìm nhanh", searchPlaceholder: "Nhập tên VĐV, đội hoặc trận đấu...",
    venue: "Địa điểm", court: "Sân / làn", time: "Giờ", match: "Trận đấu", round: "Vòng", result: "Kết quả",
  },
  en: {
    home: "Home", leaderboard: "Leaderboard", gallery: "Gallery", sports: "Sports", schedule: "Schedule", login: "Sign in",
    countdown: "COUNTDOWN TO COMPETITION DAY", days: "Days", hours: "Hours", minutes: "Minutes", seconds: "Seconds",
    sportCount: "Sports", dayCount: "Competition days", unitCount: "Organizations", athleteCount: "Athletes", matchCount: "Matches",
    allSports: "Sports", viewDetail: "View details", updating: "Updating", teamsNotAssigned: "Teams TBD", footer: "Petrovietnam Sports Day 2026",
    info: "Information", teams: "Teams/Athletes", times: "Time slots", fixtures: "Fixtures", brackets: "Brackets",
    description: "Description", rules: "Competition rules", details: "Details", format: "Format", categories: "Categories", categoryUnit: "categories", fixtureUnit: "matches", competitionDay: "Competition day",
    empty: "No data yet", galleryEmpty: "Event photos will be published here.", leaderboardEmpty: "The leaderboard will be updated when results are available.",
    filterSport: "All sports", filterCategory: "All categories", filterStatus: "All statuses", calendar: "Calendar", byTeam: "By team", board: "Competition board", print: "Export PDF", scheduled: "Scheduled", live: "Live", completed: "Completed", postponed: "Postponed", cancelled: "Cancelled",
    organization: "Organization", members: "Members", group: "Group", rank: "Rank", played: "Played", wins: "Wins", draws: "Draws", losses: "Losses", points: "Points", total: "Total", medals: "medals", athlete: "Athlete", lane: "Lane", performance: "Performance", status: "Status", openDrive: "Open Google Drive folder", searchLabel: "Quick search", searchPlaceholder: "Search athlete, team or match...",
    venue: "Venue", court: "Court / lane", time: "Time", match: "Match", round: "Round", result: "Result",
  },
} as const;

const sportRows: Sport[] = [
  ["pickleball", "Pickleball", "Pickleball", "/icons/pickleball.png", "Thi đấu đôi theo nhóm tuổi.", "Doubles competition by age group.", "12 hạng mục đôi nam, đôi nữ và đôi nam nữ theo nhóm tuổi. Thi đấu theo vòng bảng và loại trực tiếp; lịch đấu, bảng đấu và kết quả cập nhật theo dữ liệu thực tế.", "12 men’s, women’s and mixed doubles age-group categories. Group and knockout stages; schedules, brackets and results follow the live competition data."],
  ["bong-ban", "Bóng bàn", "Table Tennis", "🏓", "Thi đấu đôi nam, đôi nữ và đôi nam nữ.", "Men’s, women’s and mixed doubles.", "Thi đấu đôi nam, đôi nữ và đôi nam nữ theo các hạng mục tuổi. Vòng bảng và loại trực tiếp; đội thắng được xác định theo tỷ số trận.", "Men’s, women’s and mixed doubles by age category. Group and knockout stages; winners are determined by match score."],
  ["cau-long", "Cầu lông", "Badminton", "🏸", "Thi đấu đôi theo giới tính và nhóm tuổi.", "Doubles competition by gender and age group.", "Thi đấu đôi theo giới tính và nhóm tuổi. Vận động viên thi đấu theo lịch và hạng mục đã đăng ký; kết quả được cập nhật sau từng trận.", "Doubles competition by gender and age group. Athletes compete in their registered category; results are updated after each match."],
  ["boi-loi", "Bơi lội", "Swimming", "🏊", "Các cự ly tự do cá nhân và tiếp sức 4×50m.", "Individual freestyle and 4×50m relays.", "Gồm các nội dung 50m, 100m tự do và tiếp sức 4×50m. Xếp hạng theo thành tích thời gian được ghi nhận tại lượt thi.", "Includes 50m, 100m freestyle and 4×50m relay events. Ranking follows the recorded time in each heat."],
  ["keo-co", "Kéo co", "Tug of War", "/icons/tug-of-war.png", "Thi đấu đồng đội nam và nữ.", "Men’s and women’s team competition.", "Thi đấu đồng đội nam và nữ theo hạng mục. Mỗi trận gồm các đội đối đầu trực tiếp; kết quả và lịch thi đấu do Ban Tổ chức cập nhật.", "Men’s and women’s team competition. Teams face each other directly; schedules and results are updated by the Organizing Committee."],
  ["dien-kinh", "Điền kinh", "Athletics", "🏃", "Các cự ly 400m, 800m, 3.000m, 5.000m và tiếp sức 4×100m.", "400m, 800m, 3,000m, 5,000m and 4×100m relay events.", "Gồm các nội dung chạy cá nhân và tiếp sức 4×100m. Vận động viên xuất phát theo lượt; thành tích được tính bằng thời gian hoàn thành.", "Includes individual running and 4×100m relay events. Athletes start in heats; performance is measured by finishing time."],
  ["co-vua", "Cờ vua", "Chess", "♟️", "Hệ Thụy Sĩ cá nhân.", "Individual Swiss system.", "Thi đấu cá nhân theo hệ Thụy Sĩ. Ghép cặp và xếp hạng căn cứ vào kết quả từng ván và các tiêu chí phụ theo điều lệ giải.", "Individual Swiss-system competition. Pairings and ranking follow game results and the tie-break criteria of the event rules."],
  ["co-tuong", "Cờ tướng", "Xiangqi", "/icons/xiangqi.png", "Hệ Thụy Sĩ cá nhân.", "Individual Swiss system.", "Thi đấu cá nhân theo hệ Thụy Sĩ. Mỗi ván được ghi nhận thắng, hòa hoặc thua; bảng xếp hạng cập nhật theo kết quả thi đấu.", "Individual Swiss-system competition. Each game records a win, draw or loss; standings update from competition results."],
].map(([slug, name_vi, name_en, emoji, description_vi, description_en, rules_vi, rules_en], index) => ({
  id: `sport-${index + 1}`, slug, name_vi, name_en, emoji, description_vi, description_en,
  rules_vi, rules_en, sort_order: index + 1,
}));

const defaultSportsBySlug = new Map(sportRows.map((sport) => [sport.slug, sport]));

const tournamentNames: Record<string, Array<[string, string]>> = {
  pickleball: [["Đôi nam dưới 30 tuổi","Men’s Doubles Under 30"],["Đôi nam 31–40 tuổi","Men’s Doubles 31–40"],["Đôi nam 41–50 tuổi","Men’s Doubles 41–50"],["Đôi nam từ 51 tuổi","Men’s Doubles 51+"],["Đôi nữ dưới 30 tuổi","Women’s Doubles Under 30"],["Đôi nữ 31–40 tuổi","Women’s Doubles 31–40"],["Đôi nữ 41–50 tuổi","Women’s Doubles 41–50"],["Đôi nữ từ 50 tuổi","Women’s Doubles 50+"],["Đôi nam nữ dưới 30 tuổi","Mixed Doubles Under 30"],["Đôi nam nữ 31–40 tuổi","Mixed Doubles 31–40"],["Đôi nam nữ 41–50 tuổi","Mixed Doubles 41–50"],["Đôi nam nữ từ 51 tuổi","Mixed Doubles 51+"]],
  "bong-ban": [["Đôi nam dưới 30 tuổi","Men’s Doubles Under 30"],["Đôi nam 31–40 tuổi","Men’s Doubles 31–40"],["Đôi nam 41–50 tuổi","Men’s Doubles 41–50"],["Đôi nữ","Women’s Doubles"],["Đôi nam nữ 31–40 tuổi","Mixed Doubles 31–40"],["Đôi nam nữ 41–50 tuổi","Mixed Doubles 41–50"]],
  "cau-long": [["Đôi nam dưới 30 tuổi","Men’s Doubles Under 30"],["Đôi nam 31–40 tuổi","Men’s Doubles 31–40"],["Đôi nam 41–50 tuổi","Men’s Doubles 41–50"],["Đôi nam từ 51 tuổi","Men’s Doubles 51+"],["Đôi nam nữ dưới 30 tuổi","Mixed Doubles Under 30"],["Đôi nam nữ 31–40 tuổi","Mixed Doubles 31–40"],["Đôi nam nữ 41–50 tuổi","Mixed Doubles 41–50"],["Đôi nữ dưới 30 tuổi","Women’s Doubles Under 30"],["Đôi nữ 31–40 tuổi","Women’s Doubles 31–40"]],
  "boi-loi": [["50m tự do nam dưới 30 tuổi","Men’s 50m Freestyle Under 30"],["50m tự do nam 31–40 tuổi","Men’s 50m Freestyle 31–40"],["50m tự do nam 41–50 tuổi","Men’s 50m Freestyle 41–50"],["50m tự do nam trên 50 tuổi","Men’s 50m Freestyle 50+"],["50m tự do nữ dưới 30 tuổi","Women’s 50m Freestyle Under 30"],["50m tự do nữ 31–40 tuổi","Women’s 50m Freestyle 31–40"],["100m tự do nam dưới 30 tuổi","Men’s 100m Freestyle Under 30"],["100m tự do nam 41–50 tuổi","Men’s 100m Freestyle 41–50"],["100m tự do nữ","Women’s 100m Freestyle"],["Tiếp sức nam 4×50m","Men’s 4×50m Relay"],["Tiếp sức nữ 4×50m","Women’s 4×50m Relay"]],
  "keo-co": [["Kéo co nam","Men’s Tug of War"],["Kéo co nữ","Women’s Tug of War"]],
  "dien-kinh": [["400m nữ","Women’s 400m"],["800m nam","Men’s 800m"],["Tiếp sức nữ 4×100m","Women’s 4×100m Relay"],["Tiếp sức nam 4×100m","Men’s 4×100m Relay"],["3.000m nữ","Women’s 3,000m"],["5.000m nam","Men’s 5,000m"]],
  "co-vua": [["Cờ vua nữ","Women’s Chess"],["Cờ vua nam dưới 45 tuổi","Men’s Chess Under 45"],["Cờ vua nam trên 45 tuổi","Men’s Chess Over 45"]],
  "co-tuong": [["Cờ tướng nam dưới 45 tuổi","Men’s Xiangqi Under 45"],["Cờ tướng nam trên 45 tuổi","Men’s Xiangqi Over 45"]],
};

const tournaments: Tournament[] = sportRows.flatMap((sport) => (tournamentNames[sport.slug] ?? []).map(([vi, en], index) => ({
  id: `${sport.slug}-${index + 1}`, sport_id: sport.id, slug: `${sport.slug}-${index + 1}`,
  name_vi: vi, name_en: en, category_vi: vi, category_en: en,
  format_vi: sport.slug.startsWith("co-") ? "Hệ Thụy Sĩ cá nhân" : "Theo hồ sơ thi đấu",
  format_en: sport.slug.startsWith("co-") ? "Individual Swiss system" : "Per competition source",
  rules_vi: "",
  rules_en: "",
  competition_mode: sport.slug.startsWith("co-") ? "swiss" : sport.slug === "boi-loi" || sport.slug === "dien-kinh" ? "race" : "round_robin",
  source_metadata: {},
  sort_order: index + 1,
})));

const fallback: SiteData = {
  event: {
    event_name_vi: "Hội thao Petrovietnam 2026", event_name_en: "Petrovietnam Southern Sports Day 2026",
    subtitle_vi: "Khu vực phía Nam", subtitle_en: "Southern Region",
    about_vi: "Sân chơi thể thao gắn kết người lao động Petrovietnam khu vực phía Nam.",
    about_en: "A sports festival connecting Petrovietnam employees in the Southern Region.",
    venue_vi: "", venue_en: "", hero_path: "/kv.png", hero_mobile_path: "/kv-mobile.png",
    start_at: "2026-09-04T00:00:00.000Z", end_at: "2026-09-06T11:00:00.000Z",
    gallery_drive_url: "",
  },
  sports: sportRows,
  tournaments,
  organizations: [],
  participants: [],
  entries: [],
  entryMembers: [],
  groups: [],
  groupEntries: [],
  venues: [],
  courts: [],
  fixtures: [],
  fixtureEntries: [],
  fixtureSlots: [],
  standings: [],
  awards: [],
  media: [],
  contacts: [],
  footerLinks: [],
  counts: { sports: 8, organizations: 21, participants: 0, fixtures: 10 },
};

export const getSiteData = cache(async function getSiteData(): Promise<SiteData> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key || !tenantSlug) return fallback;

  const db = createClient(url, key, { auth: { persistSession: false }, global: { headers: tenantHeaders() } });
  const { data: tenant, error: tenantError } = await db.from("tenants").select("id").eq("slug", tenantSlug).maybeSingle();
  if (tenantError || !tenant) return fallback;
  const tenantId = tenant.id;
  const [event, sports, tournamentsResult, organizations, participants, teamParticipants, entries, entryMembers, groups, groupEntries, venues, courts, fixtures, fixtureEntries, fixtureSlots, standings, awards, media, contacts, footerLinks] = await Promise.all([
    db.from("event_settings").select("event_name_vi,event_name_en,subtitle_vi,subtitle_en,about_vi,about_en,venue_vi,venue_en,hero_path,hero_mobile_path,start_at,end_at,gallery_drive_url").eq("tenant_id", tenantId).eq("singleton_key", "main").maybeSingle(),
    db.from("sports").select("id,slug,name_vi,name_en,emoji,description_vi,description_en,rules_vi,rules_en,sort_order").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
    db.from("tournaments").select("id,sport_id,slug,name_vi,name_en,category_vi,category_en,format_vi,format_en,rules_vi,rules_en,competition_mode,scoring_rule,source_metadata,sort_order").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
    db.from("organizations").select("id,code,name_vi,name_en,logo_path,sort_order,leaderboard_rank,gold_medals,silver_medals,bronze_medals").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
    db.from("participants").select("id,organization_id,full_name,full_name_en").eq("tenant_id", tenantId).is("archived_at", null).order("full_name"),
    db.from("participants").select("id,organization_id,full_name,full_name_en,entry_members!inner(entries!inner(kind))").eq("tenant_id", tenantId).eq("entry_members.entries.kind", "team").is("archived_at", null),
    db.from("entries").select("id,tournament_id,organization_id,kind,name_vi,name_en").eq("tenant_id", tenantId).is("archived_at", null).order("name_vi"),
    db.from("entry_members").select("id,entry_id,participant_id,role_vi,role_en,sort_order,entries!inner(kind)").eq("tenant_id", tenantId).eq("entries.kind", "team").is("archived_at", null).order("sort_order"),
    db.from("groups").select("id,tournament_id,name_vi,name_en,sort_order,standings_confirmed_at").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
    db.from("group_entries").select("id,group_id,entry_id,seed_order").eq("tenant_id", tenantId).is("archived_at", null).order("seed_order"),
    db.from("venues").select("id,name_vi,name_en,address_vi,address_en,sort_order").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
    db.from("courts").select("id,venue_id,name_vi,name_en,sort_order").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
    db.from("fixtures").select("id,tournament_id,group_id,venue_id,court_id,starts_at,ends_at,status,round_vi,round_en,result_summary_vi,result_summary_en,round_order,bracket_position,next_fixture_id,winner_entry_id,source_code").eq("tenant_id", tenantId).is("archived_at", null).order("starts_at"),
    db.from("fixture_entries").select("id,fixture_id,entry_id,side,lane,seed_order,score,score_numeric,rank,result_status").eq("tenant_id", tenantId).is("archived_at", null).order("seed_order"),
    db.from("fixture_slots").select("id,fixture_id,side,source_kind,source_entry_id,source_group_id,source_fixture_id,source_rank,label_vi,label_en").eq("tenant_id", tenantId).is("archived_at", null),
    db.from("standings").select("id,tournament_id,group_id,entry_id,played,won,drawn,lost,score_for,score_against,points,rank").eq("tenant_id", tenantId).is("archived_at", null).order("rank"),
    db.from("awards").select("id,organization_id,entry_id,participant_id,medal,title_vi,title_en").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
    db.from("media").select("id,storage_path,sport_id,title_vi,title_en,alt_vi,alt_en,filter_tag,album_vi,album_en,sort_order").eq("tenant_id", tenantId).eq("kind", "gallery").is("archived_at", null).order("sort_order"),
    db.from("contacts").select("id,label_vi,label_en,value,href,sort_order").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
    db.from("footer_links").select("id,label_vi,label_en,href,sort_order").eq("tenant_id", tenantId).is("archived_at", null).order("sort_order"),
  ]);

  if (event.error || sports.error || tournamentsResult.error || fixtures.error || !event.data) return fallback;
  return {
    event: event.data,
    sports: (sports.data as Sport[]).map((sport) => {
      const defaults = defaultSportsBySlug.get(sport.slug);
      return {
        ...sport,
        emoji: sport.slug === "pickleball" ? "/icons/pickleball.png" : sport.emoji,
        rules_vi: !sport.rules_vi || sport.rules_vi === "Đang cập nhật" ? defaults?.rules_vi ?? sport.rules_vi : sport.rules_vi,
        rules_en: !sport.rules_en || sport.rules_en === "Updating" ? defaults?.rules_en ?? sport.rules_en : sport.rules_en,
      };
    }),
    tournaments: tournamentsResult.data as Tournament[],
    organizations: (organizations.data ?? []) as Organization[],
    participants: [...new Map([...participants.data ?? [], ...teamParticipants.data ?? []].map((participant) => [participant.id, participant])).values()] as Participant[],
    entries: (entries.data ?? []) as Entry[],
    entryMembers: (entryMembers.data ?? []) as EntryMember[],
    groups: (groups.data ?? []) as Group[],
    groupEntries: (groupEntries.data ?? []) as GroupEntry[],
    venues: (venues.data ?? []) as Venue[],
    courts: (courts.data ?? []) as Court[],
    fixtures: fixtures.data as Fixture[],
    fixtureEntries: (fixtureEntries.data ?? []) as FixtureEntry[],
    fixtureSlots: (fixtureSlots.data ?? []) as FixtureSlot[],
    standings: (standings.data ?? []) as Standing[],
    awards: (awards.data ?? []) as Award[],
    media: ((media.data ?? []) as Omit<Media, "public_url">[]).map((item) => ({ ...item, public_url: db.storage.from("event-media").getPublicUrl(item.storage_path).data.publicUrl })),
    contacts: (contacts.data ?? []) as Contact[],
    footerLinks: (footerLinks.data ?? []) as FooterLink[],
    counts: {
      sports: sports.data.length,
      organizations: organizations.data?.length ?? 0,
      participants: new Set([...(participants.data ?? []), ...(teamParticipants.data ?? [])].map((participant) => participant.id)).size,
      fixtures: fixtures.data.length,
    },
  };
});

export function rankOrganizations(awards: Award[], organizations: Organization[], entries: Entry[], participants: Participant[] = []): LeaderboardRow[] {
  if (organizations.some((organization) => organization.gold_medals !== undefined || organization.leaderboard_rank !== undefined)) {
    return [...organizations]
      .map((organization) => ({ organization, gold: organization.gold_medals ?? 0, silver: organization.silver_medals ?? 0, bronze: organization.bronze_medals ?? 0, special: 0, total: (organization.gold_medals ?? 0) + (organization.silver_medals ?? 0) + (organization.bronze_medals ?? 0) }))
      .sort((a, b) => (a.organization.leaderboard_rank ?? Number.MAX_SAFE_INTEGER) - (b.organization.leaderboard_rank ?? Number.MAX_SAFE_INTEGER) || b.gold - a.gold || b.silver - a.silver || b.bronze - a.bronze || a.organization.sort_order - b.organization.sort_order);
  }
  const entriesById = new Map(entries.map((entry) => [entry.id, entry.organization_id]));
  const participantsById = new Map(participants.map((participant) => [participant.id, participant.organization_id]));
  const rows = new Map(organizations.map((organization) => [organization.id, { organization, gold: 0, silver: 0, bronze: 0, special: 0 }]));
  for (const award of awards) {
    const organizationId = award.organization_id ?? entriesById.get(award.entry_id ?? "") ?? participantsById.get(award.participant_id ?? "");
    const row = organizationId ? rows.get(organizationId) : undefined;
    if (row) row[award.medal] += 1;
  }
  return [...rows.values()]
    .map((row) => ({ ...row, total: row.gold + row.silver + row.bronze + row.special }))
    .filter((row) => row.total > 0)
    .sort((a, b) => b.gold - a.gold || b.silver - a.silver || b.bronze - a.bronze || b.total - a.total || a.organization.sort_order - b.organization.sort_order);
}

export function localized(row: Record<string, unknown>, field: string, locale: Locale): string {
  return String(row[`${field}_${locale}`] ?? row[`${field}_vi`] ?? "");
}

export function isKnockoutFixture(fixture: Pick<Fixture, "group_id" | "bracket_position" | "round_order">) {
  return fixture.bracket_position !== null || (!fixture.group_id && fixture.round_order !== null);
}
