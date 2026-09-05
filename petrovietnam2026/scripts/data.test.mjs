import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import test from "node:test";
import { rankOrganizations } from "../src/lib/site.ts";
import * as site from "../src/lib/site.ts";
import { formatVietnamDateTime, fromVietnamLocalInput, toVietnamLocalInput } from "../src/lib/datetime.ts";
import { formValue } from "../src/lib/admin-form.ts";
import { assertImageFile, heroStoragePath } from "../src/lib/admin-media.ts";
import * as adminMedia from "../src/lib/admin-media.ts";
import { eventFieldNames } from "../src/lib/admin-event.ts";
import { relationEntity } from "../src/lib/admin-relations.ts";
import { adminEntities } from "../src/lib/admin-config.ts";
import { deriveStandings, headToHeadRule } from "../src/lib/standings.ts";
import { isManualSport, orderManualStandings, validateGalleryDriveUrl } from "../src/lib/manual-competition.ts";
import { formatMatchResult, normalizeLegacyMatchResult, scoresFromMatchResult, standingDifference } from "../src/lib/competition-display.ts";
import { buildSearchSuggestions, matchesSearch } from "../src/lib/search.ts";

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
const scheduleView = readFileSync(new URL("../src/components/schedule-view.tsx", import.meta.url), "utf8");
const adminSearch = readFileSync(new URL("../src/components/admin-search.tsx", import.meta.url), "utf8");
const searchLib = readFileSync(new URL("../src/lib/search.ts", import.meta.url), "utf8");
const siteLib = readFileSync(new URL("../src/lib/site.ts", import.meta.url), "utf8");
const nextConfig = readFileSync(new URL("../next.config.ts", import.meta.url), "utf8");
const mediaUploadForm = readFileSync(new URL("../src/components/media-upload-form.tsx", import.meta.url), "utf8");
const loadingFeedback = readFileSync(new URL("../src/components/loading-feedback.tsx", import.meta.url), "utf8");
const appLayout = readFileSync(new URL("../src/app/layout.tsx", import.meta.url), "utf8");
const adminSportPage = readFileSync(new URL("../src/app/admin/sports/[slug]/page.tsx", import.meta.url), "utf8");
const adminActions = readFileSync(new URL("../src/app/admin/actions.ts", import.meta.url), "utf8");
const adminCss = readFileSync(new URL("../src/app/globals.css", import.meta.url), "utf8");
const authTimeout = readFileSync(new URL("../src/lib/auth-timeout.ts", import.meta.url), "utf8");
const tugIcon = new URL("../public/icons/tug-of-war.png", import.meta.url);
const xiangqiIcon = new URL("../public/icons/xiangqi.png", import.meta.url);
const migrations = readdirSync(new URL("migrations/", supabaseRoot))
  .sort()
  .map((file) => readFileSync(new URL(`migrations/${file}`, supabaseRoot), "utf8"))
  .join("\n");
const bracketMigration = readFileSync(new URL("migrations/20260828170000_source_driven_brackets.sql", supabaseRoot), "utf8");
const bracketControlsMigration = readFileSync(new URL("migrations/20260828173024_source_bracket_admin_controls.sql", supabaseRoot), "utf8");
const feedbackMigration = readFileSync(new URL("migrations/20260830090000_feedback_safe_admin_flow.sql", supabaseRoot), "utf8");
const fullStandingsMigration = readFileSync(new URL("migrations/20260831100000_full_manual_standings.sql", supabaseRoot), "utf8");
const sportExcelMigration = readFileSync(new URL("migrations/20260831120000_sport_excel_admin.sql", supabaseRoot), "utf8");
const updateWorkbookSeed = readFileSync(new URL("../../supabase/seeds/052_updates_workbooks.sql", import.meta.url), "utf8");
const chessRosterSeed = readFileSync(new URL("../../supabase/seeds/025_chess_rosters.sql", import.meta.url), "utf8");
const customerFeedbackMigration = readFileSync(new URL("../../supabase/migrations/20260904100000_repair_chess_swimming_customer_feedback.sql", import.meta.url), "utf8");
const relayRepairMigration = readFileSync(new URL("../../supabase/migrations/20260904230000_retry_athletics_relay_repairs.sql", import.meta.url), "utf8");
const competitionBoard = readFileSync(new URL("../src/components/competition-board.tsx", import.meta.url), "utf8");
const refreshDataButton = readFileSync(new URL("../src/components/refresh-data-button.tsx", import.meta.url), "utf8");
const searchCombobox = existsSync(new URL("../src/components/search-combobox.tsx", import.meta.url)) ? readFileSync(new URL("../src/components/search-combobox.tsx", import.meta.url), "utf8") : "";

test("database models source-driven competition slots", () => {
  assert.match(bracketMigration, /competition_mode text not null default 'round_robin'/);
  assert.match(bracketMigration, /create table public\.fixture_slots/);
  assert.match(bracketMigration, /unique \(fixture_id, side\)/);
  assert.match(bracketMigration, /source_kind in \('entry', 'group_rank', 'fixture_winner', 'fixture_loser', 'bye'\)/);
  assert.match(bracketMigration, /result_status text/);
  assert.match(bracketMigration, /fixture_slots_public_read/);
});

test("result RPC propagates and previews dependent reset", () => {
  assert.match(bracketMigration, /private\.sync_fixture_slots/);
  assert.match(bracketMigration, /create or replace function public\.reset_fixture_dependents/);
  assert.match(bracketMigration, /for update/);
  assert.match(bracketMigration, /Trận phụ thuộc đã có kết quả/);
});

test("started brackets lock structure and admin board uses source slots", () => {
  assert.match(bracketControlsMigration, /fixture_slots_lock_started/);
  assert.match(bracketControlsMigration, /sync_tournament_slots/);
  assert.match(bracketControlsMigration, /source_metadata jsonb/);
  assert.match(competitionBoard, /layoutBracket/);
  assert.match(competitionBoard, /slotLabel/);
  assert.match(competitionBoard, /ZoomableBracket/);
  assert.match(competitionBoard, /setZoom/);
  assert.ok(competitionBoard.indexOf("{isBracket &&") < competitionBoard.indexOf("{tournament.competition_mode === \"group_knockout\" && table"));
  assert.match(adminActions, /saveFixtureSlot/);
  assert.match(adminActions, /previewFixtureReset/);
});

test("admin bracket exposes mapped names and inline score editing", () => {
  assert.match(competitionBoard, /slotCandidateLabel/);
  assert.match(competitionBoard, /bracket-inline-result/);
  assert.match(competitionBoard, /name="score_1"/);
  assert.match(competitionBoard, /name="score_2"/);
  assert.match(competitionBoard, /bracket-round-headings/);
  assert.match(competitionBoard, /bracket-round-heading/);
  assert.match(competitionBoard, /auto-winner-note/);
});

test("public bracket shows source rank labels without candidate predictions", () => {
  assert.match(competitionBoard, /slotDisplayLabel/);
  assert.doesNotMatch(competitionBoard, /label\}\{candidateLabel && <small className="bracket-candidates">\{candidateLabel\}<\/small>\}/);
  assert.match(competitionBoard, /item\.candidateLabel \? `Có thể: \$\{item\.candidateLabel\}`/);
});

test("public pages refresh live competition data", () => {
  assert.match(refreshDataButton, /setInterval/);
  assert.match(refreshDataButton, /30000/);
  assert.match(refreshDataButton, /router\.refresh\(\)/);
  assert.match(siteLib, /unstable_cache/);
  assert.match(siteLib, /revalidate: 60/);
  assert.match(siteLib, /tags: \["site-data"\]/);
  assert.match(siteLib, /\.range\(offset, offset \+ 999\)/);
});

test("source topology covers every supplied category", () => {
  const manifest = JSON.parse(readFileSync(new URL("../data/source-brackets.json", import.meta.url), "utf8"));
  assert.deepEqual(new Set(manifest.tournaments.map((row) => row.competition_mode)), new Set(["knockout", "group_knockout", "round_robin", "swiss", "race"]));
  assert.equal(manifest.tournaments.every((row) => row.source.file && Number.isInteger(row.source.page_or_sheet)), true);
  assert.equal(manifest.tournaments.flatMap((row) => row.fixtures ?? []).every((fixture) => fixture.slots?.length === 2), true);
});

test("seed keeps the approved eight sports", () => {
  for (const slug of ["pickleball","bong-ban","cau-long","boi-loi","keo-co","dien-kinh","co-vua","co-tuong"]) assert.match(competition, new RegExp(`'${slug}'`));
  assert.equal((competition.match(/'10000000-0000-0000-0000-00000000000[1-8]'/g) ?? []).length, 8);
});

test("sports with supplied artwork use dedicated image icons", () => {
  assert.equal(existsSync(tugIcon), true);
  assert.equal(existsSync(xiangqiIcon), true);
  assert.match(competition, /'keo-co',[^\n]*'\/icons\/tug-of-war\.png'/);
  assert.match(competition, /'co-tuong',[^\n]*'\/icons\/xiangqi\.png'/);
  assert.match(siteLib, /"co-tuong", "Cờ tướng", "Xiangqi", "\/icons\/xiangqi\.png"/);
  assert.match(migrations, /update public\.sports[\s\S]*set emoji = '\/icons\/xiangqi\.png'[\s\S]*where slug = 'co-tuong'/);
});

test("public sport renderers treat uploaded absolute URLs as images", () => {
  assert.match(publicPages, /emoji\?\.startsWith\("\/"\) \|\| emoji\?\.startsWith\("http"\)/);
  assert.match(publicPages, /value\.startsWith\("\/"\) \|\| value\.startsWith\("http"\)/);
});

test("standing difference uses score for minus score against", () => {
  assert.equal(standingDifference({ score_for: 8, score_against: 3 }), 5);
  assert.equal(standingDifference({ score_for: null, score_against: null }), 0);
});

test("public standings query includes both score sources", () => {
  assert.match(siteLib, /standings.*select\([^\n]*score_for,score_against/);
});

test("fixture actions use database sides and return inline state", () => {
  assert.match(adminActions, /export type AdminActionState/);
  assert.match(adminActions, /saveFixtureResult\(_previousState: AdminActionState, formData: FormData\)/);
  assert.match(adminActions, /fixture_entries/);
  assert.match(adminActions, /return \{ ok: false, message[,}]/);
  assert.doesNotMatch(adminActions, /formData\.get\(`entry_\$\{index\}`\)/);
});

test("bracket has one read-only-side dialog and no duplicate result form", () => {
  assert.doesNotMatch(competitionBoard, /name="entry_1"|name="entry_2"/);
  assert.match(competitionBoard, /source_kind/);
  assert.doesNotMatch(adminSportPage, /form action=\{saveFixtureResult\}/);
});

test("full standings migration rejects non-finite numeric values", () => {
  assert.match(fullStandingsMigration, /NaN/);
  assert.match(fullStandingsMigration, /Infinity/);
});

test("Excel admin keeps imports atomic and bracket sources read-only", () => {
  assert.match(sportExcelMigration, /create table public\.sport_excel_exports/);
  assert.match(sportExcelMigration, /create table public\.sport_excel_imports/);
  assert.match(sportExcelMigration, /create or replace function public\.apply_sport_excel_import/);
  assert.match(sportExcelMigration, /create or replace function public\.rollback_sport_excel_import/);
  assert.match(sportExcelMigration, /NGUỒN_NHÁNH chỉ đọc trong Excel/);
  assert.match(sportExcelMigration, /Rollback không khôi phục đúng snapshot ban đầu/);
});

test("search suggestions cover participants, entries, and fixtures", () => {
  const suggestions = buildSearchSuggestions({
    participants: [{ id: "p1", full_name: "Nguyễn An", organization: "PVN" }],
    entries: [{ id: "e1", name: "Nguyễn An / Trần Bình", tournament: "Bảng A" }],
    fixtures: [{ id: "f1", label: "Trận 1", detail: "Bảng A · Nguyễn An / Trần Bình" }],
  });
  assert.deepEqual(suggestions.map((item) => item.kind), ["participant", "entry", "fixture"]);
  assert.equal(matchesSearch("Nguyễn An / Trần Bình", "nguyen an"), true);
});

test("admin quick search includes competition categories and toolbar label stays accessible", () => {
  const suggestions = buildSearchSuggestions({
    participants: [],
    entries: [],
    fixtures: [],
    tournaments: [{ id: "t1", name: "Đôi nam dưới 45", detail: "Hạng mục" }],
  });
  assert.deepEqual(suggestions.map((item) => item.kind), ["tournament"]);
  assert.match(adminSearch, /suggestion\.kind === "tournament"/);
  assert.match(adminSportPage, /tournaments: scopedRows\.tournaments\.map/);
  assert.match(searchCombobox, /hideLabel/);
  assert.match(scheduleView, /hideLabel/);
  assert.match(adminCss, /search-combobox-compact/);
  assert.match(adminCss, /\.admin-search-card \.results-help\s*\{[^}]*margin:\s*10px 0 0/);
  assert.match(searchLib, /kind: "tournament"/);
});

test("search controls expose accessible autocomplete on public and admin views", () => {
  assert.match(searchCombobox, /role="combobox"/);
  assert.match(searchCombobox, /aria-activedescendant/);
  assert.match(searchCombobox, /role="option"/);
  assert.match(scheduleView, /SearchCombobox/);
  assert.match(adminSportPage, /AdminSearch/);
});

test("admin schedule renders relationship labels instead of UUIDs", () => {
  assert.match(adminSportPage, /function summary\(row: Row, entity\?: AdminEntity/);
  assert.match(adminSportPage, /entity === "fixture_entries"/);
  assert.match(adminSportPage, /all\("entries"\)/);
  assert.match(adminSportPage, /summary\(item, relation, rows\)/);
  assert.doesNotMatch(adminSportPage, /\{summary\(item\)\}<\/option>/);
});

test("admin bracket opens an inline result editor", () => {
  assert.match(competitionBoard, /resultAction/);
  assert.match(competitionBoard, /<dialog/);
  assert.match(competitionBoard, /name="score_1"/);
  assert.match(competitionBoard, /name="score_2"/);
  assert.match(adminSportPage, /resultAction=\{saveFixtureResult\}/);
  assert.match(adminCss, /\.source-bracket-node\s*\{[^}]*z-index:\s*1/);
  assert.match(competitionBoard, /className="bracket-edit-button"[^>]*aria-label=/);
  assert.match(competitionBoard, /<Pencil size=\{13\}/);
  assert.match(adminCss, /\.bracket-edit-button\s*\{[^}]*position:\s*absolute[^}]*display:\s*inline-flex/);
  assert.match(competitionBoard, /className="gold-button bracket-inline-save"/);
  assert.match(adminCss, /\.bracket-inline-save\s*\{[^}]*display:\s*inline-flex/);
  assert.match(competitionBoard, /resolveMatchEntry/);
  assert.match(competitionBoard, /slots\.length > 0 \? \(entry \? rows\.find/);
});

test("result editor accepts teams resolved from bracket slots", () => {
  assert.match(competitionBoard, /const editingReady = Boolean\(editingRows\[0\]\?\.entry && editingRows\[1\]\?\.entry/);
  assert.match(competitionBoard, /disabled=\{resultPending \|\| !editingReady\}/);
  assert.match(adminActions, /rpc\("sync_tournament_slots"/);
});

test("runtime standings recalculation does not call seed-only tenant helper", () => {
  const runtimeFix = readdirSync(new URL("migrations/", supabaseRoot)).find((file) => file.includes("runtime_tenant"));
  assert.ok(runtimeFix, "missing runtime tenant migration");
  const source = readFileSync(new URL(`migrations/${runtimeFix}`, supabaseRoot), "utf8");
  assert.doesNotMatch(source, /seed_tenant_id\(\)/);
  assert.match(source, /private\.current_tenant_id\(\)/);
});

test("category quick search filters the selected admin category context", () => {
  assert.match(adminSearch, /params\.set\("tournament"/);
  assert.match(adminSportPage, /tournament\?: string/);
  assert.match(adminSportPage, /requested\.tournament/);
  assert.match(adminSportPage, /tournamentRows\.filter/);
});

test("entry variants are merged without leaving duplicate group rows", () => {
  const dedupeMigration = readdirSync(new URL("migrations/", supabaseRoot)).find((file) => file.includes("merge_entry_variants"));
  assert.ok(dedupeMigration, "missing entry variant migration");
  const source = readFileSync(new URL(`migrations/${dedupeMigration}`, supabaseRoot), "utf8");
  assert.match(updateWorkbookSeed, /merge_entry_variants/);
  assert.match(source, /group_entries/);
  assert.match(source, /fixture_entries/);
  assert.match(source, /standings/);
  assert.match(source, /archived_at/);
  assert.match(source, /select distinct on \(merge\.keeper_id, member\.participant_id\)/);
  assert.match(source, /select distinct on \(member\.group_id, merge\.keeper_id\)/);
});

test("customer feedback keeps chess rosters exact and splits swimming age groups", () => {
  assert.match(chessRosterSeed, /'co-vua','nu','Phạm Nguyễn Như Thường','PVE'/);
  assert.doesNotMatch(chessRosterSeed, /'co-vua','nu','Phạm Nguyễn Như','PVE'/);
  assert.match(chessRosterSeed, /'co-tuong','nam-tren-45','Đái Quốc Triều','PVCFC'/);
  assert.match(chessRosterSeed, /'co-tuong','nam-tren-45','Nguyễn Bá Phượng','PVFCCO'/);
  assert.doesNotMatch(updateWorkbookSeed, /Chu Ðình Quang Vinh/);
  assert.doesNotMatch(updateWorkbookSeed, /Nguyễn Bá Phương/);
  for (const slug of ["50m-nam-duoi-30", "50m-nam-31-40", "50m-nam-41-50", "50m-nam-tren-50", "50m-nu-duoi-30", "50m-nu-31-40", "100m-nam-duoi-30", "100m-nam-41-50"]) {
    assert.match(competition, new RegExp(`'boi-loi','${slug}'`));
    assert.match(updateWorkbookSeed, new RegExp(`'${slug}'`));
  }
  assert.match(updateWorkbookSeed, /'boi-loi','4x50m-nu','team','VSP02'/);
  assert.match(updateWorkbookSeed, /'boi-loi','4x50m-nu','VSP02','Trần Linh Vương'/);
  assert.match(customerFeedbackMigration, /repair_chess_swimming_customer_feedback/);
  assert.match(customerFeedbackMigration, /UPD-BOI-/);
  assert.match(siteLib, /from\("entries"\)[\s\S]*is\("archived_at", null\)/);
  assert.match(siteLib, /entry_members!inner\(entries!inner\(kind\)\)/);
  assert.match(siteLib, /teamParticipants/);
  assert.match(competitionBoard, /entry-member-list/);
});

test("dedupe handles Vietnamese Unicode variants and removes teams or athletes from the event", () => {
  const dedupeMigration = readdirSync(new URL("migrations/", supabaseRoot)).find((file) => file.includes("dedupe_entry_variants"));
  assert.ok(dedupeMigration, "missing Unicode entry dedupe migration");
  const source = readFileSync(new URL(`migrations/${dedupeMigration}`, supabaseRoot), "utf8");
  assert.match(source, /chr\(768\)/);
  assert.match(source, /merge_participant_variants/);
  assert.match(source, /merge_entry_variants/);
  assert.match(source, /first_value\(name_vi\)/);
  assert.match(source, /participant\.full_name,\s+private\.entry_identity\(participant\.full_name/s);
  assert.match(source, /entry\.name_vi,\s+private\.entry_identity\(entry\.name_vi/s);
  assert.match(source, /left\(normalized, length\(normalized\) - length\(organization_code\)\) ~ '\[-\[:space:\]\]\$'/);
  assert.doesNotMatch(source, /regexp_replace\(normalized, '\\s\*-\[\^-\]\*\$'/);
  assert.match(source, /participants_prevent_duplicate_identity/);
  assert.match(adminSportPage, /entity === "entries" \|\| entity === "participants"/);
  assert.match(adminSportPage, /Xoá khỏi giải/);
});

test("admin roster inserts can run the duplicate identity trigger", () => {
  const permissionMigration = readdirSync(new URL("migrations/", supabaseRoot)).find((file) => file.includes("grant_entry_identity_to_authenticated"));
  assert.ok(permissionMigration, "missing roster identity permission migration");
  const source = readFileSync(new URL(`migrations/${permissionMigration}`, supabaseRoot), "utf8");
  assert.match(source, /grant execute on function private\.entry_identity\(text, text\) to authenticated/);
  assert.match(adminActions, /saveRosterRecord/);
});

test("competitor identity repairs attached organization suffixes and reversed pairs", () => {
  const repairMigration = readdirSync(new URL("migrations/", supabaseRoot)).find((file) => file.includes("repair_competitor_identity"));
  assert.ok(repairMigration, "missing competitor identity repair migration");
  const source = readFileSync(new URL(`migrations/${repairMigration}`, supabaseRoot), "utf8");
  assert.match(source, /regexp_split_to_table\(normalized, '\/'\)/);
  assert.match(source, /string_agg\(part_identity, '' order by part_identity\)/);
  assert.match(source, /right\(identity, length\(organization_code\)\) = organization_code/);
  assert.match(source, /perform private\.merge_entry_variants\(tenant\.id\)/);
});

test("bracket result input accepts concrete source slots before fixture rows exist", () => {
  assert.match(competitionBoard, /const ready = Boolean\(rows\[0\]\?\.entry && rows\[1\]\?\.entry/);
  assert.doesNotMatch(competitionBoard, /const ready = Boolean\(rows\[0\]\?\.row && rows\[1\]\?\.row/);
});

test("latest pickleball roster archives the superseded PDF pair", () => {
  assert.match(updateWorkbookSeed, /archive_obsolete_pickleball_pair\(private\.seed_tenant_id\(\)\)/);
  const repairMigration = readdirSync(new URL("migrations/", supabaseRoot)).find((file) => file.includes("repair_competitor_identity"));
  assert.ok(repairMigration, "missing competitor identity repair migration");
  const source = readFileSync(new URL(`migrations/${repairMigration}`, supabaseRoot), "utf8");
  assert.match(source, /Hoàng Ngọc Quý \/ Nguyễn Minh Tú-PVG/);
  assert.match(source, /archive_obsolete_pickleball_pair/);
  assert.match(source, /set archived_at = now\(\)/);
});

test("latest pickleball group D keeps workbook fixtures instead of PDF duplicates", () => {
  const repairMigration = readdirSync(new URL("migrations/", supabaseRoot)).find((file) => file.includes("repair_pickleball_group_d_fixtures"));
  assert.ok(repairMigration, "missing pickleball group D repair migration");
  const source = readFileSync(new URL(`migrations/${repairMigration}`, supabaseRoot), "utf8");
  assert.match(source, /fixture\.source_code is null/);
  assert.match(source, /fixture\.round_order between 10 and 12/);
  assert.match(source, /UPD-DOI-NAM-31-40-BANG-D-02/);
  assert.match(source, /UPD-DOI-NAM-31-40-BANG-D-03/);
  assert.match(source, /doi-nam-duoi-30/);
  assert.match(source, /round_order >= 200/);
  assert.match(source, /set archived_at = coalesce\(archived_at, now\(\)\)/);
  assert.match(source, /set score = null,[\s\S]*score_numeric = null/);
  assert.match(updateWorkbookSeed, /archive_legacy_pickleball_group_d_fixtures/);
});

test("workbook updates reuse pair identity instead of creating suffix variants", () => {
  assert.match(migrations, /create or replace function private\.entry_identity/);
  assert.match(updateWorkbookSeed, /private\.entry_identity\(existing\.name_vi, existing\.kind\)/);
  assert.match(updateWorkbookSeed, /private\.entry_identity\(source\.name_vi, source\.kind\)/);
  assert.match(updateWorkbookSeed, /name_vi = source\.name_vi/);
});

test("results derive winners and recalculate unique standings ranks", () => {
  assert.match(migrations, /create or replace function private\.recalculate_group_standings\(/);
  assert.match(migrations, /row_number\(\) over \(order by/);
  assert.match(migrations, /winner_entry_id := case/);
  assert.match(migrations, /Hạng trong bảng không được trùng/);
  assert.match(competitionBoard, /name="winner_entry_id"/);
  assert.match(competitionBoard, /tỷ số.*đội thắng|đội thắng.*tỷ số/i);
  assert.match(adminActions, /p_winner_entry_id: winnerEntryId/);
  assert.match(adminActions, /winner_entry_id/);
  assert.match(adminActions, /Số trận phải bằng Thắng \+ Hòa \+ Thua/);
  assert.match(adminActions, /Đội thắng phải khớp với tỷ số/);
  assert.match(adminActions, /row\.won \* ruleValues\[0\] \+ row\.drawn \* ruleValues\[1\] \+ row\.lost \* ruleValues\[2\]/);
  assert.match(competitionBoard, /sportSlug === "keo-co"/);
  assert.match(competitionBoard, /manualWinner/);
  assert.match(competitionBoard, /deriveStandings/);
  assert.match(competitionBoard, /standings-guide/);
  assert.match(competitionBoard, /Ghi\/Thua \(\+\/-\)/);
  assert.match(migrations, /keo-co/);
  assert.match(migrations, /create trigger tournaments_recalculate_standings/);
  assert.match(migrations, /Kéo co không được hòa/);
  assert.match(migrations, /Đội thắng phải khớp với tỷ số/);
  assert.match(migrations, /perform private\.recalculate_group_standings\(fixture_row\.tournament_id, fixture_row\.group_id\);/);
  assert.doesNotMatch(adminSportPage, /Không tự tính lại/);
  assert.match(adminActions, /Hạng trong bảng không được trùng/);
  assert.match(migrations, /update public\.standings existing\s+set rank = null/);
  assert.match(adminSportPage, /auto-rank-cell/);
  assert.match(siteLib, /played: "Trận"/);
});

test("result editor uses source slots before stale persisted fixture rows", () => {
  assert.match(competitionBoard, /const entry = resolveMatchEntry/);
  assert.match(competitionBoard, /const row = slots\.length > 0 \? \(entry \? rows\.find/);
});

test("result scores auto-select the higher-scoring winner", () => {
  assert.match(competitionBoard, /function updateWinnerFromScores\(/);
  assert.match(competitionBoard, /onChange=\{\(event\) => updateWinnerFromScores\(event\.currentTarget\.form!/);
});

test("fixture result summaries keep score formatting and bracket rows", () => {
  assert.equal(formatMatchResult("PQPOC", "1", "2", "BỘ MÁY QL&ĐH PETROVN"), "PQPOC 1 - 2 BỘ MÁY QL&ĐH PETROVN");
  assert.equal(normalizeLegacyMatchResult("PQPOC 1 - BỘ MÁY QL&ĐH PETROVN 2", "PQPOC", "BỘ MÁY QL&ĐH PETROVN"), "PQPOC 1 - 2 BỘ MÁY QL&ĐH PETROVN");
  assert.equal(normalizeLegacyMatchResult("PQPOC 1 - BỘ MÁY QL&ĐH PETROVN 2", "", ""), "PQPOC 1 - 2 BỘ MÁY QL&ĐH PETROVN");
  assert.deepEqual(scoresFromMatchResult("PQPOC 1 - 2 BỘ MÁY QL&ĐH PETROVN", "PQPOC", "BỘ MÁY QL&ĐH PETROVN"), ["1", "2"]);
  assert.deepEqual(scoresFromMatchResult("PQPOC 1 - BỘ MÁY QL&ĐH PETROVN 2", "PQPOC", "BỘ MÁY QL&ĐH PETROVN"), ["1", "2"]);
  assert.match(adminActions, /labelsById\.get\(entryIds\[0\]\).*scores\[0\].*scores\[1\].*labelsById\.get\(entryIds\[1\]\)/s);
  assert.match(competitionBoard, /className="bracket-teams"/);
  assert.match(competitionBoard, /scoresFromMatchResult/);
  assert.match(competitionBoard, /entry\?\.id === fixture\.winner_entry_id/);
});

test("bracket resolves mapped names and exposes standings editing below", () => {
  assert.match(competitionBoard, /resolveMatchEntry/);
  assert.match(competitionBoard, /standingsAction/);
  assert.match(competitionBoard, /scoreLabel/);
  assert.match(adminSportPage, /standingsAction: saveManualStandings/);
  assert.match(adminActions, /confirm_group_standings/);
  assert.match(migrations, /standings_confirmed_at is not null/);
});

test("manual standings RPC accepts and persists all display fields", () => {
  const rpc = [...migrations.matchAll(/create or replace function public\.save_manual_standings\([\s\S]*?revoke execute on function public\.save_manual_standings/g)].at(-1)?.[0] ?? "";
  assert.match(rpc, /entry_id uuid,\s*played integer/);
  assert.match(rpc, /score_for numeric/);
  assert.match(rpc, /score_against numeric/);
  assert.match(rpc, /points numeric/);
  assert.match(rpc, /rank integer/);
});

test("standings tables expose complete manual score columns", () => {
  for (const source of [competitionBoard, adminSportPage]) {
    assert.match(source, /played/);
    assert.match(source, /score_for/);
    assert.match(source, /score_against/);
    assert.match(source, /standingDifference/);
  }
});

test("all sports keep schedule visibility", () => {
  assert.doesNotMatch(scheduleView, /visibleFixtures = useMemo\(.*isManualSport/s);
  assert.doesNotMatch(sportTabs, /const sportFixtures = manual \? \[\] :/);
  assert.doesNotMatch(sportTabs, /\.\.\.\(!manual \?/);
  assert.doesNotMatch(adminSportPage, /\{!manual && <SportNavLink[\s\S]*Lịch & trận/);
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
  assert.match(migrations, /file_size_limit = 10485760/);
});

test("home renders separate desktop and mobile KV sources", () => {
  assert.match(publicPages, /hero-mobile/);
  assert.match(publicPages, /hero_mobile_path/);
});

test("sport detail tabs keep untimed fixtures and bracket category filter", () => {
  assert.match(sportTabs, /useState/);
  assert.match(sportTabs, /\?tab=\$\{key\}/);
  assert.match(sportTabs, /ScheduleView/);
});

test("hero upload paths keep desktop and mobile files separate", () => {
  assert.equal(heroStoragePath("desktop", "image/png", "fixed"), "hero/desktop/fixed.png");
  assert.equal(heroStoragePath("mobile", "image/webp", "fixed"), "hero/mobile/fixed.webp");
  assert.throws(() => heroStoragePath("wide", "image/png", "fixed"), /Hero không hợp lệ/);
});

test("sport gallery keeps legacy media but removes new uploads", () => {
  const gallery = readFileSync(new URL("../src/app/admin/sports/[slug]/page.tsx", import.meta.url), "utf8");
  assert.doesNotMatch(gallery, /MediaUploadForm/);
  assert.match(gallery, /Media cũ \/ Legacy media/);
  assert.doesNotThrow(() => assertImageFile(new File([new Uint8Array(2 * 1024 * 1024)], "ok.png", { type: "image/png" }), 2 * 1024 * 1024));
  assert.doesNotThrow(() => assertImageFile(new File([new Uint8Array(10 * 1024 * 1024)], "large.png", { type: "image/png" }), 10 * 1024 * 1024));
  assert.throws(() => assertImageFile(new File([new Uint8Array(10 * 1024 * 1024 + 1)], "too-large.png", { type: "image/png" }), 10 * 1024 * 1024), /tối đa 10MB/);
});

test("media deletion uses the trash target alone or every selected image", () => {
  assert.equal(typeof adminMedia.mediaDeletionIds, "function");
  const selected = new FormData();
  selected.append("id", "image-1");
  selected.append("id", "image-2");
  selected.append("id", "image-1");
  assert.deepEqual(adminMedia.mediaDeletionIds(selected), ["image-1", "image-2"]);
  selected.set("single_id", "image-3");
  assert.deepEqual(adminMedia.mediaDeletionIds(selected), ["image-3"]);
});

test("media selection toggles every visible image", () => {
  const inputs = [{ checked: false }, { checked: false }];
  adminMedia.setMediaSelection(inputs, true);
  assert.deepEqual(inputs, [{ checked: true }, { checked: true }]);
  adminMedia.setMediaSelection(inputs, false);
  assert.deepEqual(inputs, [{ checked: false }, { checked: false }]);
});

test("server actions allow multipart gallery payloads above the 1MB default", () => {
  assert.match(nextConfig, /bodySizeLimit:\s*["']12mb["']/);
});

test("gallery upload blocks oversized files before submitting", () => {
  assert.match(mediaUploadForm, /10 \* 1024 \* 1024/);
  assert.match(mediaUploadForm, /event\.preventDefault\(\)/);
  assert.match(loadingFeedback, /const handleSubmit[\s\S]*event\.defaultPrevented/);
});

test("gallery upload queues files and supports admin deletion", () => {
  assert.match(mediaUploadForm, /upload-queue/);
  assert.match(mediaUploadForm, /await action\(payload\)/);
  assert.match(adminActions, /export async function deleteMedia/);
  assert.match(adminActions, /mediaDeletionIds/);
  assert.match(adminActions, /storage[\s\S]*remove\(paths\)/);
  assert.match(adminActions, /from\("media"\)\.delete\(\)/);
  assert.match(migrations, /event_media_admin_delete/);
  assert.match(migrations, /media_admin_delete/);
  assert.match(adminSportPage, /ConfirmedMediaDeleteForm/);
  assert.match(adminSportPage, /single_id/);
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

test("sport admin gallery renders as a media grid and highlights the active section", () => {
  assert.match(adminSportPage, /admin-media-grid/);
  assert.match(adminSportPage, /SportNavLink/);
  assert.match(adminSportPage, /aria-current=\{active \? "page"/);
  assert.match(adminCss, /\.admin-media-grid\s*\{/);
  assert.match(adminCss, /\.admin-sport-nav a\.active/);
});

test("sport admin results show readable match cards that open their editor", () => {
  assert.match(competitionBoard, /source-bracket-match/);
  assert.match(competitionBoard, /resultAction/);
  assert.match(competitionBoard, /form key=\{editingFixture\.id\} action=\{resultFormAction\}/);
  assert.doesNotMatch(adminSportPage, /form action=\{saveFixtureResult\}/);
  assert.match(adminCss, /\.admin-sport-panels > section:has\(:target\)/);
});

test("admin standings use full-width group panels", () => {
  assert.match(adminCss, /\.admin-board-card \.group-grid\s*\{[^}]*grid-template-columns:\s*minmax\(0, 1fr\)/);
});

test("route loading clears after query-only navigation", () => {
  assert.match(loadingFeedback, /useSearchParams/);
  assert.match(loadingFeedback, /searchParams\.toString\(\)/);
  assert.match(appLayout, /Suspense/);
});

test("admin auth has a bounded wait instead of an infinite loading shell", async () => {
  assert.match(authTimeout, /Promise\.race/);
  assert.match(adminSportPage, /results-error/);
  await assert.rejects(() => import("../src/lib/auth-timeout.ts").then(({ withTimeout }) => withTimeout(() => new Promise(() => {}), 5)), /timeout/);
});

test("admin results scope database reads before loading competition data", () => {
  assert.match(adminSportPage, /scoped\("entries", "tournament_id", tournamentIds\)/);
  assert.match(adminSportPage, /scoped\("fixtures", "tournament_id", tournamentIds\)/);
  assert.match(adminSportPage, /all\("fixture_entries"\)/);
  assert.match(adminSportPage, /all\("group_entries"\)/);
  assert.match(adminSportPage, /!item\.archived_at && resultEntryIds\.has\(String\(item\.entry_id\)\)/);
  assert.match(adminSportPage, /\.in\("fixture_id", fixtureIds\)/);
});

test("schedule uses grouped match rows for the global page and each sport", () => {
  assert.match(scheduleView, /schedule-day/);
  assert.match(scheduleView, /venue_id/);
  assert.match(scheduleView, /court_id/);
  assert.match(scheduleView, /Theo lịch|calendar/);
  assert.match(sportTabs, /ScheduleView/);
  assert.match(siteLib, /venues: Venue\[\]/);
  assert.match(siteLib, /courts: Court\[\]/);
});

test("schedule labels unassigned teams and renders source-driven boards", () => {
  assert.match(scheduleView, /teamsNotAssigned/);
  assert.match(siteLib, /teamsNotAssigned: "Chưa xếp đội"/);
  assert.match(scheduleView, /CompetitionBoard/);
  assert.match(scheduleView, /fixtureSlots/);
  assert.match(scheduleView, /score_numeric/);
  assert.match(sportTabs, /CompetitionBoard/);
  assert.match(sportTabs, /bracket-overview/);
  assert.match(publicPages, /schedule-page/);
  assert.match(adminCss, /\.schedule-page/);
  assert.match(competitionBoard, /tournament-stack/);
  assert.match(competitionBoard, /board-selector/);
  assert.match(competitionBoard, /selectedTournamentId/);
  assert.match(sportTabs, /bracket-category-filter/);
  assert.match(sportTabs, /setSelectedTournamentId/);
  assert.match(sportTabs, /showTournamentSelector=\{false\}/);
  assert.match(adminCss, /\.bracket-category-filter select/);
  assert.match(competitionBoard, /contentVisibility/);
  assert.match(competitionBoard, /matchLabel/);
  assert.match(adminCss, /@media \(max-width: 600px\)/);
  assert.match(adminCss, /\.bracket-canvas-viewport \{/);
  assert.match(adminCss, /\.schedule-day td:nth-child\(1\)::before/);
  assert.match(publicPages, /leaderboard-table/);
});

test("knockout brackets include explicit bracket matches and ungrouped ordered rounds", () => {
  assert.equal(typeof site.isKnockoutFixture, "function");
  assert.equal(site.isKnockoutFixture({ group_id: "group-a", bracket_position: null, round_order: 1 }), false);
  assert.equal(site.isKnockoutFixture({ group_id: null, bracket_position: null, round_order: 2 }), true);
  assert.equal(site.isKnockoutFixture({ group_id: "group-a", bracket_position: 4, round_order: null }), true);
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
  assert.throws(() => headToHeadRule("head-to-head", "-1", "1", "0"), /Điểm tính không hợp lệ/);
});

test("manual competition keeps source order while ranked rows move first", () => {
  assert.equal(isManualSport("co-vua"), true);
  assert.equal(isManualSport("pickleball"), false);
  assert.deepEqual(orderManualStandings([
    { entry_id: "b", rank: null },
    { entry_id: "a", rank: 2 },
    { entry_id: "c", rank: 1 },
  ], ["b", "a", "c"]).map((row) => row.entry_id), ["c", "a", "b"]);
  assert.doesNotMatch(sportTabs, /const sportFixtures = manual \? \[\] :/);
  assert.doesNotMatch(sportTabs, /!manual && active === "brackets"/);
  assert.match(scheduleView, /availableSports/);
  assert.match(adminSportPage, /manual_mode/);
  assert.match(adminSportPage, /name="lane"/);
  assert.match(adminSportPage, /name="result_status"/);
  assert.match(adminActions, /p_status: "scheduled"/);
  assert.doesNotMatch(adminActions, /const ranks = new Map\(deriveRaceRanks/);
});

test("gallery Drive URL accepts only HTTPS drive.google.com folders", () => {
  assert.equal(validateGalleryDriveUrl("https://drive.google.com/drive/folders/demo"), true);
  assert.equal(validateGalleryDriveUrl("http://drive.google.com/drive/folders/demo"), false);
  assert.equal(validateGalleryDriveUrl("https://docs.google.com/document/d/demo"), false);
  assert.equal(validateGalleryDriveUrl(""), true);
});

test("feedback migration adds additive safe admin flow", () => {
  assert.match(feedbackMigration, /gallery_drive_url text/);
  assert.match(feedbackMigration, /leaderboard_rank/);
  assert.match(feedbackMigration, /standings_confirmed_at/);
  assert.match(feedbackMigration, /save_manual_standings/);
  assert.match(feedbackMigration, /confirm_group_standings/);
  assert.match(feedbackMigration, /save_manual_leaderboard/);
  assert.match(feedbackMigration, /save_fixture_slot_and_sync/);
  assert.match(feedbackMigration, /winner_entry_id is null/);
  assert.match(feedbackMigration, /winner_entry_id[\s\S]*score_numeric/);
});

test("admin results avoid oversized fixture-id filters", () => {
  const page = readFileSync(new URL("../src/app/admin/sports/[slug]/page.tsx", import.meta.url), "utf8");
  assert.doesNotMatch(page, /scoped\("fixture_entries",\s*"fixture_id",\s*fixtureIds\)/);
  assert.doesNotMatch(page, /fixtureSlotsQuery\.in\("fixture_id",\s*fixtureIds\)/);
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
  assert.doesNotMatch(pairSportsSeed, /'Bảng 6'/);
  assert.match(pairSportsSeed, /'bong-ban','doi-nam-41-50','Bảng D'/);
  assert.doesNotMatch(pairSportsSeed, /Vũ Văn Sỹ--VSP/);
  assert.match(migrations, /repair_table_tennis_source_data|Unplayed 31-40 Bảng B/);
});

test("master schedule seeds pickleball and chess blocks", () => {
  for (const row of ["('co-vua','nu'", "('co-tuong','nam-duoi-45'", "('pickleball','doi-nam-duoi-30'", "('pickleball','doi-nam-nu-41-50'"]) assert.ok(scheduleBlocks.includes(row), row);
  assert.match(scheduleBlocks, /2026-09-06 13:30:00\+07/);
});

test("PDF individual seed keeps source-explicit swimming and athletics rosters", () => {
  for (const row of ["('boi-loi','50m-nam'", "('boi-loi','100m-nu'", "('dien-kinh','800m-nam'", "('dien-kinh','5000m-nam'"]) assert.ok(individualSportsSeed.includes(row), row);
  assert.match(individualSportsSeed, /insert into public\.entry_members/);
  assert.match(individualSportsSeed, /p\.organization_id = o\.id\s+and private\.entry_identity\(p\.full_name, 'individual'\)/);
  assert.match(individualSportsSeed, /e\.tournament_id = t\.id\s+and e\.kind = r\.kind[\s\S]*private\.entry_identity\(e\.name_vi, e\.kind\)/);
  assert.doesNotMatch(individualSportsSeed, /p\.full_name = names\.full_name/);
  assert.doesNotMatch(individualSportsSeed, /e\.name_vi = r\.entry_name/);
  assert.doesNotMatch(individualSportsSeed, /insert into public\.fixture_entries/);
});

test("relay repair migration pins the tenant and splits reviewed teams", () => {
  assert.match(relayRepairMigration, /set app\.tenant_slug = 'petrovietnam2026';/);
  assert.match(relayRepairMigration, /'PV GAS 1'/);
  assert.match(relayRepairMigration, /'PV GAS 2'/);
  assert.match(relayRepairMigration, /desired_womens_relay_members/);
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

test("manual leaderboard keeps explicit rank and puts unranked units last", () => {
  const organizations = [
    { id: "a", name_vi: "A", name_en: "A", code: "A", logo_path: null, sort_order: 1, leaderboard_rank: 2, gold_medals: 1, silver_medals: 0, bronze_medals: 1 },
    { id: "b", name_vi: "B", name_en: "B", code: "B", logo_path: null, sort_order: 2, leaderboard_rank: 1, gold_medals: 0, silver_medals: 2, bronze_medals: 0 },
    { id: "c", name_vi: "C", name_en: "C", code: "C", logo_path: null, sort_order: 3, leaderboard_rank: null, gold_medals: 0, silver_medals: 0, bronze_medals: 0 },
  ];
  assert.deepEqual(rankOrganizations([], organizations, []).map((row) => [row.organization.id, row.total]), [["b", 2], ["a", 2], ["c", 0]]);
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
