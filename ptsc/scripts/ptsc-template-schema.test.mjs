import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const migration = readFileSync(new URL("../../supabase/migrations/20260913122010_ptsc_template_import.sql", import.meta.url), "utf8");

test("PTSC template migration is append-only, tenant-scoped, and auditable", () => {
  assert.match(migration, /set app\.tenant_slug\s*=\s*'ptsc2026'/i);
  assert.match(migration, /22222222-2222-2222-2222-222222222222/);
  assert.doesNotMatch(migration, /\bdelete\s+from\b/i);
  for (const table of ["source_files", "import_batches", "import_rows", "audit_logs"]) assert.match(migration, new RegExp(`create table (if not exists )?public\\.${table}`));
  for (const column of ["category_code", "group_code", "slot_no", "source_key", "row_fingerprint", "source_status", "source_sheet", "source_page", "source_note"]) assert.match(migration, new RegExp(`\\b${column}\\b`));
  assert.match(migration, /idempotency_key/);
  assert.match(migration, /unique[\s\S]*file_sha256/);
  assert.match(migration, /alter table public\.(source_files|import_batches|import_rows|audit_logs) enable row level security/);
  for (const fn of ["prepare_ptsc_template_import", "commit_ptsc_template_import", "rollback_ptsc_template_import"]) assert.match(migration, new RegExp(`create or replace function public\\.${fn}`));
});

test("PTSC migration declares the exact eleven-sport catalog", () => {
  const expected = ["Bóng bàn", "Cầu lông", "Tennis", "Điền kinh", "Pickleball", "Pickleball lãnh đạo", "Bơi lội", "Kéo co", "Bóng đá nữ", "Bóng đá nam A", "Bóng đá nam B"];
  for (const name of expected) assert.match(migration, new RegExp(name));
  assert.match(migration, /45/);
  assert.match(migration, /490/);
  assert.match(migration, /PB-DOI-NAM46/);
  assert.match(migration, /pending_confirmation/);
});

test("PTSC migration preserves source roles and backend validation", () => {
  assert.match(migration, /'Vận động viên'/);
  assert.match(migration, /'Dự bị'/);
  assert.match(migration, /update public\.entry_members[\s\S]*set archived_at/);
  assert.match(migration, /Xếp hạng trực tiếp/);
  assert.match(migration, /insert into public\.fixture_entries/);
  assert.match(migration, /p_template_version is distinct from 1/);
  assert.match(migration, /p_parser_version is distinct from 'ptsc-template-excel-v1'/);
  assert.match(migration, /Payload PTSC bị trùng khóa tự nhiên/);
  assert.match(migration, /insert into public\.source_files[\s\S]*p_file_sha256[\s\S]*on conflict \(tenant_id, raw_filename, sha256\) do nothing/);
  assert.match(migration, /status = case when row_data\.before_data is null then 'created'/);
  assert.match(migration, /Không thể rollback: dữ liệu đã có thay đổi mới hơn/);
  assert.match(migration, /on conflict do nothing/);
});
