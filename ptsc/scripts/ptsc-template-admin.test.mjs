import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";
import { countPtscImportRows, filterPtscImportRows } from "../src/lib/ptsc-import-preview.ts";
import { validateGalleryDriveUrl } from "../src/lib/manual-competition.ts";

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

test("PTSC preview filters default to actionable rows and expose counted states", () => {
  const rows = [
    { natural_key: "tennis-a", action: "created", status: "draft" },
    { natural_key: "tennis-b", action: "updated", status: "active" },
    { natural_key: "tennis-c", action: "unchanged", status: "active" },
    { natural_key: "tennis-d", action: "unchanged", status: "pending_confirmation" },
  ];
  assert.deepEqual(filterPtscImportRows(rows, "", "needs_review").map((row) => row.natural_key), ["tennis-a", "tennis-b", "tennis-d"]);
  assert.deepEqual(filterPtscImportRows(rows, "b", "needs_review").map((row) => row.natural_key), ["tennis-b"]);
  assert.equal(countPtscImportRows(rows, "unchanged"), 2);
  assert.equal(countPtscImportRows(rows, "all"), 4);
});

test("PTSC Drive links accept HTTPS drive.google.com only", () => {
  assert.equal(validateGalleryDriveUrl(""), true);
  assert.equal(validateGalleryDriveUrl("https://drive.google.com/drive/folders/ptsc"), true);
  assert.equal(validateGalleryDriveUrl("http://drive.google.com/drive/folders/ptsc"), false);
  assert.equal(validateGalleryDriveUrl("https://example.com/ptsc"), false);
});

test("PTSC media migration is tenant-scoped and adds the sport gallery read model", () => {
  const migration = readFileSync(new URL("../../supabase/migrations/20260914100000_ptsc_gallery_and_kv.sql", import.meta.url), "utf8");
  assert.match(migration, /set app\.tenant_slug = 'ptsc2026'/);
  assert.match(migration, /add column if not exists gallery_drive_url/);
  assert.match(migration, /get_public_sport_gallery/);
  assert.match(migration, /kv-ptsc-placeholder\.png/);
});
