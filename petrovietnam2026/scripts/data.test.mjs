import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import test from "node:test";
import { rankOrganizations } from "../src/lib/site.ts";
import { formatVietnamDateTime, fromVietnamLocalInput, toVietnamLocalInput } from "../src/lib/datetime.ts";
import { formValue } from "../src/lib/admin-form.ts";
import { assertImageFile, heroStoragePath } from "../src/lib/admin-media.ts";
import { eventFieldNames } from "../src/lib/admin-event.ts";
import { relationEntity } from "../src/lib/admin-relations.ts";
import { adminEntities } from "../src/lib/admin-config.ts";
import { deriveStandings, headToHeadRule } from "../src/lib/standings.ts";

const supabaseRoot = new URL("../../supabase/", import.meta.url);
const competition = readFileSync(new URL("seeds/020_competition.sql", supabaseRoot), "utf8");
const sources = readFileSync(new URL("seeds/030_sources.sql", supabaseRoot), "utf8");
const pickleballSeed = readFileSync(new URL("seeds/035_pickleball_source.sql", supabaseRoot), "utf8");
const pairSportsSeed = readFileSync(new URL("seeds/045_pdf_pair_sports.sql", supabaseRoot), "utf8");
const scheduleBlocks = readFileSync(new URL("seeds/046_schedule_blocks.sql", supabaseRoot), "utf8");
const individualSportsSeed = readFileSync(new URL("seeds/048_individual_sports.sql", supabaseRoot), "utf8");
const workbookSources = readFileSync(new URL("seeds/050_xlsx_sources.sql", supabaseRoot), "utf8");
const publicPages = readFileSync(new URL("../src/components/public-pages.tsx", import.meta.url), "utf8");
const galleryGrid = readFileSync(new URL("../src/components/gallery-grid.tsx", import.meta.url), "utf8");
const sportTabs = readFileSync(new URL("../src/components/sport-tabs.tsx", import.meta.url), "utf8");
const nextConfig = readFileSync(new URL("../next.config.ts", import.meta.url), "utf8");
const mediaUploadForm = readFileSync(new URL("../src/components/media-upload-form.tsx", import.meta.url), "utf8");
const loadingFeedback = readFileSync(new URL("../src/components/loading-feedback.tsx", import.meta.url), "utf8");
const migrations = readdirSync(new URL("migrations/", supabaseRoot))
  .sort()
  .map((file) => readFileSync(new URL(`migrations/${file}`, supabaseRoot), "utf8"))
  .join("\n");

test("seed keeps the approved eight sports", () => {
  for (const slug of ["pickleball","bong-ban","cau-long","boi-loi","keo-co","dien-kinh","co-vua","co-tuong"]) assert.match(competition, new RegExp(`'${slug}'`));
  assert.equal((competition.match(/'10000000-0000-0000-0000-00000000000[1-8]'/g) ?? []).length, 8);
});

test("source manifest tracks both supplied master schedules", () => {
  assert.match(sources, /'schedules\.pdf'[\s\S]*?null,true/);
  assert.match(sources, /'schedules-2\.pdf'[\s\S]*?null,true/);
});

test("seed includes source-explicit gender categories and relay events", () => {
  for (const row of [
    "('cau-long','doi-nu-duoi-30'",
    "('keo-co','nam'",
    "('keo-co','nu'",
    "('dien-kinh','4x100m-nam'",
    "('dien-kinh','4x100m-nu'",
  ]) assert.ok(competition.includes(row), row);
  assert.ok(!competition.includes("('keo-co','dong-doi'"));
});

test("database enforces archive workflow", () => {
  assert.match(migrations, /revoke delete on all tables in schema public from anon, authenticated/);
  assert.match(migrations, /archived_at is null/);
});

test("database supports mobile heroes, sport albums, and ungrouped standings", () => {
  assert.match(migrations, /hero_mobile_path text not null default '\/kv-mobile\.png'/);
  assert.match(migrations, /sport_id uuid references public\.sports\(id\)/);
  assert.match(migrations, /album_vi text not null default ''/);
  assert.match(migrations, /scoring_rule jsonb not null default '\{\}'::jsonb/);
  assert.match(migrations, /unique nulls not distinct \(tournament_id, group_id, entry_id\)/);
  assert.match(migrations, /create or replace function public\.save_fixture_result/);
  assert.match(migrations, /security invoker/);
  assert.match(migrations, /file_size_limit = 2097152/);
});

test("home renders separate desktop and mobile KV sources", () => {
  assert.match(publicPages, /hero-mobile/);
  assert.match(publicPages, /hero_mobile_path/);
});

test("sport detail tabs work without client state and keep untimed fixtures", () => {
  assert.doesNotMatch(sportTabs, /useState/);
  assert.match(sportTabs, /\?tab=\$\{key\}/);
  assert.match(sportTabs, /sortedFixtures = \[\.\.\.sportFixtures\]/);
});

test("hero upload paths keep desktop and mobile files separate", () => {
  assert.equal(heroStoragePath("desktop", "image/png", "fixed"), "hero/desktop/fixed.png");
  assert.equal(heroStoragePath("mobile", "image/webp", "fixed"), "hero/mobile/fixed.webp");
  assert.throws(() => heroStoragePath("wide", "image/png", "fixed"), /Hero không hợp lệ/);
});

test("sport gallery accepts multiple images but rejects images over 2MB", () => {
  const gallery = readFileSync(new URL("../src/app/admin/sports/[slug]/page.tsx", import.meta.url), "utf8");
  assert.match(gallery, /MediaUploadForm[\s\S]*multiple/);
  assert.doesNotThrow(() => assertImageFile(new File([new Uint8Array(2 * 1024 * 1024)], "ok.png", { type: "image/png" }), 2 * 1024 * 1024));
  assert.throws(() => assertImageFile(new File([new Uint8Array(2 * 1024 * 1024 + 1)], "large.png", { type: "image/png" }), 2 * 1024 * 1024), /tối đa 2MB/);
});

test("server actions allow multipart gallery payloads above the 1MB default", () => {
  assert.match(nextConfig, /bodySizeLimit:\s*["']10mb["']/);
});

test("gallery upload blocks oversized files before submitting", () => {
  assert.match(mediaUploadForm, /2 \* 1024 \* 1024/);
  assert.match(mediaUploadForm, /event\.preventDefault\(\)/);
  assert.match(loadingFeedback, /const handleSubmit[\s\S]*event\.defaultPrevented/);
});

test("event content save never overwrites uploaded KV paths", () => {
  assert.equal(eventFieldNames.includes("hero_path"), false);
  assert.equal(eventFieldNames.includes("hero_mobile_path"), false);
});

test("admin relation fields resolve to selectable active entities", () => {
  assert.equal(relationEntity("organization_id"), "organizations");
  assert.equal(relationEntity("winner_entry_id"), "entries");
  assert.equal(relationEntity("title_vi"), null);
});

test("sport admin route exists for scoped operations", () => {
  assert.equal(existsSync(new URL("../src/app/admin/sports/[slug]/page.tsx", import.meta.url)), true);
});

test("sport gallery records carry sport and bilingual album fields", () => {
  const fields = adminEntities.media.fields.map((field) => field.name);
  assert.equal(fields.includes("sport_id"), true);
  assert.equal(fields.includes("album_vi"), true);
  assert.equal(fields.includes("album_en"), true);
});

test("public gallery supports album filtering and native lightbox download", () => {
  assert.match(galleryGrid, /"album"/);
  assert.match(galleryGrid, /<dialog/);
  assert.match(galleryGrid, /download/);
});

test("head-to-head scoring derives ranked standings without guessing unknown rules", () => {
  const fixtures = [
    { status: "completed", entries: [{ entry_id: "a", score_numeric: 2 }, { entry_id: "b", score_numeric: 1 }] },
    { status: "completed", entries: [{ entry_id: "a", score_numeric: 1 }, { entry_id: "c", score_numeric: 1 }] },
  ];
  assert.deepEqual(deriveStandings(fixtures, { type: "head-to-head", win: 3, draw: 1, loss: 0 }), [
    { entry_id: "a", played: 2, won: 1, drawn: 1, lost: 0, score_for: 3, score_against: 2, points: 4, rank: 1 },
    { entry_id: "c", played: 1, won: 0, drawn: 1, lost: 0, score_for: 1, score_against: 1, points: 1, rank: 2 },
    { entry_id: "b", played: 1, won: 0, drawn: 0, lost: 1, score_for: 1, score_against: 2, points: 0, rank: 3 },
  ]);
  assert.deepEqual(deriveStandings(fixtures, {}), []);
});

test("scoring rule accepts valid point values and keeps unknown formats manual", () => {
  assert.deepEqual(headToHeadRule("head-to-head", "3", "1", "0"), { type: "head-to-head", win: 3, draw: 1, loss: 0 });
  assert.deepEqual(headToHeadRule("manual", "", "", ""), {});
  assert.throws(() => headToHeadRule("head-to-head", "bad", "1", "0"), /Điểm tính không hợp lệ/);
});

test("PDF inventory tracks current source set", () => {
  const inventory = JSON.parse(execFileSync("python3", ["scripts/extract_sports_pdf.py", "--inventory"], { cwd: new URL("..", import.meta.url), encoding: "utf8" }));
  assert.equal(inventory.length, 23);
  assert.equal(inventory.filter((item) => item.included).length, 23);
  assert.equal(inventory.some((item) => item.filename === "Schedule_All_Sports_2026-08-27.pdf" && !item.included), false);
});

test("PDF review renders evidence for every included source page", () => {
  const review = JSON.parse(execFileSync("python3", ["scripts/extract_sports_pdf.py", "--review"], { cwd: new URL("..", import.meta.url), encoding: "utf8" }));
  assert.equal(review.sources, 23);
  assert.equal(review.pages, 125);
  assert.equal(review.table_pages > 0, true);
});

test("pickleball review extracts source pairs without guessed rows", () => {
  const rows = JSON.parse(execFileSync("python3", ["scripts/extract_sports_pdf.py", "--pickleball"], { cwd: new URL("..", import.meta.url), encoding: "utf8" }));
  assert.equal(rows.length, 11);
  assert.equal(rows.every((row) => row.pairs.length > 0 && row.pairs.every((pair) => pair.source_page > 0)), true);
});

test("pickleball seed keeps reviewed pairs, groups, and untimed fixtures", () => {
  const pairRows = pickleballSeed.match(/insert into seed_pickleball_pairs values\n([\s\S]*?);\ninsert into public\.groups/)?.[1] ?? "";
  assert.equal((pairRows.match(/^  \('/gm) ?? []).length, 249);
  assert.match(pickleballSeed, /insert into public\.participants/);
  assert.match(pickleballSeed, /insert into public\.entry_members/);
  assert.match(pickleballSeed, /insert into public\.groups/);
  assert.match(pickleballSeed, /insert into public\.fixture_entries/);
  assert.match(pickleballSeed, /omit time\/court/);
});

test("PDF pair seed keeps source-explicit table-tennis and badminton pairs", () => {
  assert.match(pairSportsSeed, /'bong-ban'/);
  assert.match(pairSportsSeed, /'cau-long'/);
  assert.match(pairSportsSeed, /insert into public\.fixture_entries/);
  assert.ok(!pairSportsSeed.includes("home_name = away_name"));
});

test("master schedule seeds pickleball and chess blocks", () => {
  for (const row of ["('co-vua','nu'", "('co-tuong','nam-duoi-45'", "('pickleball','doi-nam-duoi-30'", "('pickleball','doi-nam-nu-41-50'"]) assert.ok(scheduleBlocks.includes(row), row);
  assert.match(scheduleBlocks, /2026-09-06 13:30:00\+07/);
});

test("PDF individual seed keeps source-explicit swimming and athletics rosters", () => {
  for (const row of ["('boi-loi','50m-nam'", "('boi-loi','100m-nu'", "('dien-kinh','800m-nam'", "('dien-kinh','5000m-nam'"]) assert.ok(individualSportsSeed.includes(row), row);
  assert.match(individualSportsSeed, /insert into public\.entry_members/);
  assert.doesNotMatch(individualSportsSeed, /insert into public\.fixture_entries/);
});

test("workbook source manifest covers every supplied XLSX", () => {
  assert.equal((workbookSources.match(/\.xlsx'/g) ?? []).length, 21);
  assert.match(workbookSources, /'B Bàn pn 26\.xlsx'/);
  assert.match(workbookSources, /'DIEN_KINH_CAP_NHAT_27_8_PVN_2026\.xlsx'/);
});

test("leaderboard ranks medal totals and resolves organization from entry", () => {
  const organizations = [
    { id: "a", name_vi: "A", name_en: "A", code: "A", logo_path: null, sort_order: 1 },
    { id: "b", name_vi: "B", name_en: "B", code: "B", logo_path: null, sort_order: 2 },
  ];
  const entries = [
    { id: "entry-b", tournament_id: "t", organization_id: "b", kind: "team", name_vi: "B", name_en: "B" },
  ];
  const participants = [{ id: "participant-b", organization_id: "b", full_name: "B", full_name_en: null }];
  const awards = [
    { id: "1", organization_id: "a", entry_id: null, medal: "gold", title_vi: "Vàng", title_en: "Gold" },
    { id: "2", organization_id: null, entry_id: "entry-b", medal: "gold", title_vi: "Vàng", title_en: "Gold" },
    { id: "3", organization_id: "a", entry_id: null, medal: "silver", title_vi: "Bạc", title_en: "Silver" },
    { id: "4", organization_id: null, entry_id: null, participant_id: "participant-b", medal: "silver", title_vi: "Bạc", title_en: "Silver" },
  ];

  assert.deepEqual(rankOrganizations(awards, organizations, entries, participants), [
    { organization: organizations[0], gold: 1, silver: 1, bronze: 0, special: 0, total: 2 },
    { organization: organizations[1], gold: 1, silver: 1, bronze: 0, special: 0, total: 2 },
  ]);
});

test("admin datetime-local round trips Asia/Ho_Chi_Minh without seven-hour drift", () => {
  const local = toVietnamLocalInput("2026-09-04T00:00:00.000Z");
  assert.equal(local, "2026-09-04T07:00");
  assert.equal(fromVietnamLocalInput(local), "2026-09-04T00:00:00.000Z");
});

test("public date formatting is deterministic across server and browser", () => {
  assert.equal(formatVietnamDateTime("2026-09-05T00:30:00.000Z", "vi"), "T7, 05/09/2026 07:30");
  assert.equal(formatVietnamDateTime("2026-09-05T00:30:00.000Z", "en"), "Sat, 05/09/2026 07:30");
});

test("admin form preserves blank text but nulls optional typed fields", () => {
  const data = new FormData();
  data.set("round_vi", "  ");
  data.set("group_id", "");
  data.set("rank", "");
  assert.equal(formValue(data, "round_vi"), "");
  assert.equal(formValue(data, "group_id"), null);
  assert.equal(formValue(data, "rank", "number"), null);
  data.set("rank", "nope");
  assert.throws(() => formValue(data, "rank", "number"), /không hợp lệ/);
});
