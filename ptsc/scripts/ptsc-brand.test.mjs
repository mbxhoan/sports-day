import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const files = {
  env: readFileSync(new URL("../.env.example", import.meta.url), "utf8"),
  layout: readFileSync(new URL("../src/app/layout.tsx", import.meta.url), "utf8"),
  shell: readFileSync(new URL("../src/components/site-shell.tsx", import.meta.url), "utf8"),
  site: readFileSync(new URL("../src/lib/site.ts", import.meta.url), "utf8"),
};

test("PTSC runtime defaults use the PTSC tenant and brand", () => {
  assert.match(files.env, /NEXT_PUBLIC_TENANT_SLUG=ptsc2026/);
  assert.match(files.layout, /PTSC/);
  assert.doesNotMatch(files.layout, /Petrovietnam/);
  assert.match(files.shell, /PTSC/);
  assert.doesNotMatch(files.shell, /PETROVIETNAM SPORTS DAY/);
  assert.match(files.site, /pickleball-lanh-dao/);
  assert.match(files.site, /bong-da-nam-a/);
  assert.match(files.site, /bong-da-nam-b/);
});
