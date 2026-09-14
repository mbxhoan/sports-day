import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";

const actionsPath = new URL("../src/app/admin/actions.ts", import.meta.url);
const actions = readFileSync(actionsPath, "utf8");

test("PTSC global importer exposes the preview, commit, and rollback actions", () => {
  for (const name of ["preparePtscTemplateImport", "commitPtscTemplateImport", "rollbackPtscTemplateImport"]) assert.match(actions, new RegExp(`export async function ${name}`));
  assert.match(actions, /parsePtscWorkbook/);
  assert.match(actions, /prepare_ptsc_template_import/);
  assert.match(actions, /commit_ptsc_template_import/);
  assert.match(actions, /rollback_ptsc_template_import/);
});

test("PTSC admin page and downloadable report route exist", () => {
  assert.equal(existsSync(new URL("../src/app/admin/excel/page.tsx", import.meta.url)), true);
  assert.equal(existsSync(new URL("../src/app/admin/excel/report/[id]/route.ts", import.meta.url)), true);
});
