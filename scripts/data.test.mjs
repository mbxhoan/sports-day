import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { rankOrganizations } from "../src/lib/site.ts";
import { formatVietnamDateTime, fromVietnamLocalInput, toVietnamLocalInput } from "../src/lib/datetime.ts";
import { formValue } from "../src/lib/admin-form.ts";

const competition = readFileSync(new URL("../supabase/seeds/020_competition.sql", import.meta.url), "utf8");
const sources = readFileSync(new URL("../supabase/seeds/030_sources.sql", import.meta.url), "utf8");
const migration = readFileSync(new URL("../supabase/migrations/20260827034412_initial_schema.sql", import.meta.url), "utf8");

test("seed keeps the approved eight sports", () => {
  for (const slug of ["pickleball","bong-ban","cau-long","boi-loi","keo-co","dien-kinh","co-vua","co-tuong"]) assert.match(competition, new RegExp(`'${slug}'`));
  assert.equal((competition.match(/'10000000-0000-0000-0000-00000000000[1-8]'/g) ?? []).length, 8);
});

test("old PTSC schedule is tracked but excluded", () => {
  assert.match(sources, /Schedule_All_Sports_2026-08-27\.pdf'[\s\S]*?null,false,'Loại khỏi seed/);
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
  assert.match(migration, /revoke delete on all tables in schema public from anon, authenticated/);
  assert.match(migration, /archived_at is null/);
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
