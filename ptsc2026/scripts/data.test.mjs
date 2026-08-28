import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const root = new URL("..", import.meta.url);
const content = readFileSync(new URL("supabase/seeds/010_content.sql", root), "utf8");
const competition = readFileSync(new URL("supabase/seeds/020_competition.sql", root), "utf8");
const publicPages = readFileSync(new URL("src/components/public-pages.tsx", root), "utf8");

test("PTSC clone keeps event identity and empty hero", () => {
  assert.match(content, /Hội Thao Tổng Công Ty Cổ Phần Dịch Vụ Kỹ Thuật Dầu Khí Việt Nam Lần Thứ 15/);
  assert.match(content, /PTSC 15th Sports Festival/);
  assert.match(content, /null, null/);
});

test("PTSC clone seeds sports only", () => {
  assert.equal((competition.match(/insert into public\.sports/g) ?? []).length, 1);
  assert.doesNotMatch(competition, /insert into public\.(tournaments|organizations|participants|entries|fixtures)/);
});

test("home skips missing KV and countdown", () => {
  assert.match(publicPages, /data\.event\.hero_path \|\| data\.event\.hero_mobile_path/);
  assert.match(publicPages, /data\.event\.start_at && <Countdown/);
});
