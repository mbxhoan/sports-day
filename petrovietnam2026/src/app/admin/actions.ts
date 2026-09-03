"use server";

import { randomUUID } from "node:crypto";
import { createHash } from "node:crypto";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { adminEntities, type AdminEntity } from "@/lib/admin-config";
import { formValue as valueOf } from "@/lib/admin-form";
import { eventFieldNames } from "@/lib/admin-event";
import { assertImageFile, heroStoragePath, mediaDeletionIds } from "@/lib/admin-media";
import { relationEntity } from "@/lib/admin-relations";
import { headToHeadRule } from "@/lib/standings";
import { formatMatchResult } from "@/lib/competition-display";
import { validateGalleryDriveUrl } from "@/lib/manual-competition";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getTenantId, tenantSlug } from "@/lib/tenant";
import { withTimeout } from "@/lib/auth-timeout";
import { buildOperations, parseSportWorkbook, previewOperations, SPORT_EXCEL_MAX_BYTES, SPORT_EXCEL_VERSION, type SportExcelSnapshot } from "@/lib/sport-excel";
import { fixtureSides } from "@/lib/brackets";
export type AdminActionState = import("@/lib/admin-action").AdminActionState;

async function adminClient() {
  const supabase = await createSupabaseServerClient();
  const tenantId = await getTenantId(supabase);
  let data;
  try { ({ data } = await withTimeout(() => supabase.auth.getClaims())); } catch { redirect("/login?error=session"); }
  const userId = data?.claims?.sub;
  if (!userId) redirect("/login?error=session");
  const { data: admin } = await supabase.from("admin_users").select("user_id").eq("tenant_id", tenantId).eq("user_id", userId).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");
  return { supabase, tenantId };
}

async function validateRelations(supabase: Awaited<ReturnType<typeof adminClient>>["supabase"], tenantId: string, payload: Record<string, unknown>) {
  for (const [field, value] of Object.entries(payload)) {
    const entity = relationEntity(field);
    if (!entity || value === null || value === "") continue;
    if (typeof value !== "string") throw new Error("Liên kết không hợp lệ");
    const { data, error } = await supabase.from(entity).select("id").eq("tenant_id", tenantId).eq("id", value).is("archived_at", null).maybeSingle();
    if (error || !data) throw new Error("Liên kết không hợp lệ");
  }
}

export async function saveEvent(formData: FormData) {
  const { supabase, tenantId } = await adminClient();
  const payload = Object.fromEntries(eventFieldNames.map((name) => [name, valueOf(formData, name, name.endsWith("_at") ? "datetime-local" : undefined)]));
  if (!validateGalleryDriveUrl(String(payload.gallery_drive_url ?? ""))) throw new Error("URL Google Drive không hợp lệ");
  const { error } = await supabase.from("event_settings").update(payload).eq("tenant_id", tenantId).eq("singleton_key", "main");
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
}

export async function saveRecord(formData: FormData) {
  const entity = String(formData.get("entity")) as AdminEntity;
  if (!(entity in adminEntities)) throw new Error("Entity không hợp lệ");
  const { supabase, tenantId } = await adminClient();
  const config = adminEntities[entity];
  const payload = Object.fromEntries(config.fields.map((field) => [field.name, valueOf(formData, field.name, "type" in field ? field.type : undefined)]));
  await validateRelations(supabase, tenantId, payload);
  const id = String(formData.get("id") ?? "");
  const query = id ? supabase.from(entity).update(payload).eq("tenant_id", tenantId).eq("id", id) : supabase.from(entity).insert({ ...payload, tenant_id: tenantId });
  const { error } = await query;
  if (error) throw new Error(error.message);
  if (entity === "standings" && payload.tournament_id) {
    const { error: syncError } = await supabase.rpc("sync_tournament_slots", { p_tournament_id: payload.tournament_id });
    if (syncError) throw new Error(syncError.message);
  }
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function setArchived(formData: FormData) {
  const entity = String(formData.get("entity")) as AdminEntity;
  const id = String(formData.get("id") ?? "");
  if (!(entity in adminEntities) || !id) throw new Error("Yêu cầu không hợp lệ");
  const { supabase, tenantId } = await adminClient();
  const archived = formData.get("archived") === "true";
  const { error } = await supabase.from(entity).update({ archived_at: archived ? new Date().toISOString() : null }).eq("tenant_id", tenantId).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function deleteMedia(formData: FormData) {
  const ids = mediaDeletionIds(formData);
  if (!ids.length) throw new Error("Chọn ít nhất một ảnh");
  const { supabase, tenantId } = await adminClient();
  const { data: media, error: mediaError } = await supabase.from("media").select("id,storage_path").eq("tenant_id", tenantId).in("id", ids).is("archived_at", null);
  if (mediaError || !media || media.length !== ids.length) throw new Error("Không tìm thấy ảnh");
  const paths = media.map((item) => item.storage_path).filter(Boolean);
  if (paths.length) {
    const { error: storageError } = await supabase.storage.from("event-media").remove(paths);
    if (storageError && !/not found/i.test(storageError.message)) throw new Error(storageError.message);
  }
  const { error } = await supabase.from("media").delete().eq("tenant_id", tenantId).in("id", ids);
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
  revalidatePath("/gallery");
  revalidatePath("/en/gallery");
}

export async function uploadMedia(formData: FormData) {
  const files = formData.getAll("file");
  const imageFiles = files.filter((file): file is File => file instanceof File && file.size > 0);
  if (!imageFiles.length || imageFiles.length !== files.length) throw new Error("Chưa chọn ảnh");
  imageFiles.forEach((file) => assertImageFile(file, 10 * 1024 * 1024));
  const { supabase, tenantId } = await adminClient();
  const requestedTag = String(formData.get("filter_tag") ?? "all").trim();
  let sportId = String(formData.get("sport_id") ?? "").trim() || null;
  let filterTag = /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(requestedTag) ? requestedTag : "all";
  let sportSlug = "";
  if (sportId) {
    const { data: sport, error: sportError } = await supabase.from("sports").select("id,slug").eq("tenant_id", tenantId).eq("id", sportId).is("archived_at", null).maybeSingle();
    if (sportError || !sport) throw new Error("Môn thể thao không hợp lệ");
    sportId = sport.id;
    filterTag = sport.slug;
    sportSlug = sport.slug;
  }
  const metadata = { tenant_id: tenantId, kind: "gallery", sport_id: sportId, filter_tag: filterTag, album_vi: String(formData.get("album_vi") ?? "").trim(), album_en: String(formData.get("album_en") ?? "").trim(), title_vi: String(formData.get("title_vi") ?? "").trim(), title_en: String(formData.get("title_en") ?? "").trim(), alt_vi: String(formData.get("alt_vi") ?? "").trim(), alt_en: String(formData.get("alt_en") ?? "").trim() };
  const mediaRows = [];
  for (const file of imageFiles) {
    const extension = assertImageFile(file, 10 * 1024 * 1024);
    const path = `${tenantSlug}/gallery/${randomUUID()}.${extension}`;
    const { error: uploadError } = await supabase.storage.from("event-media").upload(path, file, { contentType: file.type, upsert: false });
    if (uploadError) throw new Error(uploadError.message);
    mediaRows.push({ ...metadata, storage_path: path });
  }
  const { error } = await supabase.from("media").insert(mediaRows);
  if (error) throw new Error(error.message);
  revalidatePath("/gallery");
  revalidatePath("/en/gallery");
  revalidatePath("/admin");
  if (sportSlug) revalidatePath(`/admin/sports/${sportSlug}`);
}

export async function uploadHero(formData: FormData) {
  const file = formData.get("file");
  const variant = String(formData.get("variant"));
  if (!(file instanceof File)) throw new Error("Chưa chọn ảnh");
  const { supabase, tenantId } = await adminClient();
  assertImageFile(file);
  const path = `${tenantSlug}/${heroStoragePath(variant, file.type, randomUUID())}`;
  const { error: uploadError } = await supabase.storage.from("event-media").upload(path, file, { contentType: file.type, upsert: false });
  if (uploadError) throw new Error(uploadError.message);
  const column = variant === "mobile" ? "hero_mobile_path" : "hero_path";
  const { error } = await supabase.from("event_settings").update({ [column]: supabase.storage.from("event-media").getPublicUrl(path).data.publicUrl }).eq("tenant_id", tenantId).eq("singleton_key", "main");
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

function actionFailure(error: unknown): AdminActionState {
  const message = error instanceof Error ? error.message : "Không thể lưu dữ liệu";
  return { ok: false, message, code: /phụ thuộc|reset|vòng sau/i.test(message) ? "DEPENDENT_RESULTS" : "VALIDATION" };
}

export async function saveFixtureResult(_previousState: AdminActionState, formData: FormData): Promise<AdminActionState> {
  const { supabase, tenantId } = await adminClient();
  try {
    const fixtureId = String(formData.get("fixture_id") ?? "");
    const status = String(formData.get("status") ?? "completed");
    if (!fixtureId) return actionFailure(new Error("Không tìm thấy trận đấu"));
    if (!["scheduled", "live", "completed", "postponed", "cancelled"].includes(status)) return actionFailure(new Error("Trạng thái trận đấu không hợp lệ"));

    const { data: fixture, error: fixtureError } = await supabase.from("fixtures").select("id,tournament_id,group_id,bracket_position").eq("tenant_id", tenantId).eq("id", fixtureId).is("archived_at", null).single();
    if (fixtureError || !fixture) return actionFailure(new Error("Không tìm thấy trận đấu"));
    const { data: tournament, error: tournamentError } = await supabase.from("tournaments").select("sport_id").eq("tenant_id", tenantId).eq("id", fixture.tournament_id).is("archived_at", null).single();
    if (tournamentError || !tournament) return actionFailure(new Error("Không tìm thấy hạng mục"));
    const { data: sport, error: sportError } = await supabase.from("sports").select("slug").eq("tenant_id", tenantId).eq("id", tournament.sport_id).is("archived_at", null).single();
    if (sportError || !sport) return actionFailure(new Error("Không tìm thấy môn thi"));
    const manualWinner = sport.slug === "keo-co";
    const { error: syncError } = await supabase.rpc("sync_tournament_slots", { p_tournament_id: fixture.tournament_id });
    if (syncError) return actionFailure(new Error(syncError.message));
    const { data: currentRows, error: rowsError } = await supabase.from("fixture_entries").select("entry_id,side,score,result_detail").eq("tenant_id", tenantId).eq("fixture_id", fixtureId).is("archived_at", null).order("id");
    if (rowsError) return actionFailure(new Error(rowsError.message));
    const sides = fixtureSides(currentRows ?? []);
    if (sides.some((row) => !row) || new Set(sides.map((row) => row?.entry_id)).size !== 2) return actionFailure(new Error("Trận chưa đủ hai đội; hãy hoàn tất cấu trúc nguồn nhánh trước"));

    const entryIds = sides.map((row) => row!.entry_id);
    const { data: labels, error: labelsError } = await supabase.from("entries").select("id,name_vi,name_en").eq("tenant_id", tenantId).eq("tournament_id", fixture.tournament_id).is("archived_at", null).in("id", entryIds);
    if (labelsError) return actionFailure(new Error(labelsError.message));
    const labelsById = new Map((labels ?? []).map((item) => [item.id, item]));
    if (entryIds.some((id) => !labelsById.has(id))) return actionFailure(new Error("Đội thi không thuộc hạng mục"));

    const scores = [1, 2].map((index) => String(formData.get(`score_${index}`) ?? "").trim());
    const parsedScores = scores.map((score) => score === "" ? null : Number(score));
    if (parsedScores.some((score) => score !== null && (!Number.isFinite(score) || score < 0))) return actionFailure(new Error("Tỷ số không hợp lệ"));
    if (status === "completed" && parsedScores.some((score) => score === null)) return actionFailure(new Error("Trận hoàn tất phải có đủ hai tỷ số"));
    const isKnockout = fixture.group_id === null && fixture.bracket_position !== null;
    if (status === "completed" && parsedScores[0] !== null && parsedScores[0] === parsedScores[1] && isKnockout) return actionFailure(new Error("Vòng loại trực tiếp không được hòa; hãy nhập tỷ số phân định"));
    const requestedWinner = String(formData.get("winner_entry_id") ?? "").trim() || null;
    if (manualWinner && status === "completed" && !requestedWinner) return actionFailure(new Error("Kéo co phải chọn đội thắng"));
    if (requestedWinner && !entryIds.includes(requestedWinner)) return actionFailure(new Error("Đội thắng không thuộc trận đấu"));
    const derivedWinner = status === "completed" && parsedScores[0] !== null && parsedScores[1] !== null && parsedScores[0] !== parsedScores[1] ? entryIds[parsedScores[0] > parsedScores[1] ? 0 : 1] : null;
    const winnerEntryId = manualWinner ? (status === "completed" ? requestedWinner : null) : derivedWinner;
    const note = String(formData.get("note") ?? "").trim();
    const entries = sides.map((row, index) => ({ entry_id: row!.entry_id, side: index === 0 ? "home" : "away", score: scores[index] || null, score_numeric: parsedScores[index], rank: null, result_detail: note ? { note } : row!.result_detail ?? {} }));
    const summary = (field: "name_vi" | "name_en") => formatMatchResult(labelsById.get(entryIds[0])?.[field] ?? "", scores[0], scores[1], labelsById.get(entryIds[1])?.[field] ?? "");
    const { error } = await supabase.rpc("save_fixture_result", { p_fixture_id: fixtureId, p_status: status, p_winner_entry_id: winnerEntryId, p_result_summary_vi: summary("name_vi"), p_result_summary_en: summary("name_en"), p_entries: entries, p_standings: null });
    if (error) return actionFailure(new Error(error.message));
    revalidatePath("/", "layout");
    revalidatePath("/admin");
    revalidatePath(`/admin/sports/${sport.slug}`);
    return { ok: true, message: "Đã lưu kết quả" };
  } catch (error) {
    return actionFailure(error);
  }
}

export async function saveRaceResult(formData: FormData) {
  const fixtureId = String(formData.get("fixture_id") ?? "");
  const entryIds = formData.getAll("entry_id").map(String);
  const lanes = formData.getAll("lane").map(String);
  const ranks = formData.getAll("rank").map(String);
  const scores = formData.getAll("score").map(String);
  const statuses = formData.getAll("result_status").map(String);
  if (!fixtureId || !entryIds.length || new Set(entryIds).size !== entryIds.length || lanes.length !== entryIds.length || ranks.length !== entryIds.length || scores.length !== entryIds.length || statuses.length !== entryIds.length) throw new Error("Danh sách thi đấu không hợp lệ");
  const raw = entryIds.map((entryId, index) => {
    const rank = ranks[index]?.trim() ?? "";
    const lane = lanes[index]?.trim() ?? "";
    const score = scores[index]?.trim() ?? "";
    const rankNumber = rank ? Number(rank) : null;
    const laneNumber = lane ? Number(lane) : null;
    if ((rankNumber !== null && (!Number.isInteger(rankNumber) || rankNumber < 1)) || (laneNumber !== null && (!Number.isInteger(laneNumber) || laneNumber < 1))) throw new Error("Hạng hoặc làn không hợp lệ");
    const scoreNumeric = score && Number.isFinite(Number(score)) ? Number(score) : null;
    return { entry_id: entryId, side: null, lane: laneNumber, score: score || null, score_numeric: scoreNumeric, rank: rankNumber, result_status: statuses[index]?.trim() || null };
  });
  const entries = raw.map((row) => ({ ...row, result_detail: {} }));
  const { supabase, tenantId } = await adminClient();
  const { data: fixture, error: fixtureError } = await supabase.from("fixtures").select("id").eq("tenant_id", tenantId).eq("id", fixtureId).is("archived_at", null).single();
  if (fixtureError || !fixture) throw new Error("Không tìm thấy lượt thi");
  const { error } = await supabase.rpc("save_fixture_result", { p_fixture_id: fixtureId, p_status: "scheduled", p_winner_entry_id: null, p_result_summary_vi: "", p_result_summary_en: "", p_entries: entries, p_standings: null });
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function saveFixtureSlot(_previousState: AdminActionState, formData: FormData): Promise<AdminActionState> {
  const { supabase, tenantId } = await adminClient();
  try {
    const slotId = String(formData.get("slot_id") ?? "");
    const sourceKind = String(formData.get("source_kind") ?? "");
    if (!slotId || !["entry", "group_rank", "fixture_winner", "fixture_loser", "bye"].includes(sourceKind)) return actionFailure(new Error("Nguồn nhánh không hợp lệ"));
    const sourceEntryId = sourceKind === "entry" ? String(formData.get("source_entry_id") ?? "") || null : null;
    const sourceGroupId = sourceKind === "group_rank" ? String(formData.get("source_group_id") ?? "") || null : null;
    const sourceFixtureId = ["fixture_winner", "fixture_loser"].includes(sourceKind) ? String(formData.get("source_fixture_id") ?? "") || null : null;
    const sourceRankValue = String(formData.get("source_rank") ?? "").trim();
    const sourceRank = sourceKind === "group_rank" && sourceRankValue ? Number(sourceRankValue) : null;
    if ((sourceKind === "entry" && !sourceEntryId) || (sourceKind === "group_rank" && (!sourceGroupId || !Number.isInteger(sourceRank) || sourceRank! < 1)) || (["fixture_winner", "fixture_loser"].includes(sourceKind) && !sourceFixtureId)) return actionFailure(new Error("Chưa chọn nguồn nhánh"));
    const { data: slot, error: slotError } = await supabase.from("fixture_slots").select("id,fixture_id").eq("tenant_id", tenantId).eq("id", slotId).is("archived_at", null).single();
    if (slotError || !slot) return actionFailure(new Error("Không tìm thấy ô nhánh"));
    const { data: fixture, error: fixtureError } = await supabase.from("fixtures").select("id,tournament_id,group_id").eq("tenant_id", tenantId).eq("id", slot.fixture_id).is("archived_at", null).single();
    if (fixtureError || !fixture) return actionFailure(new Error("Không tìm thấy trận đấu"));
    if (sourceKind === "entry") {
      const { data: sourceEntry } = await supabase.from("entries").select("id").eq("tenant_id", tenantId).eq("tournament_id", fixture.tournament_id).eq("id", sourceEntryId).is("archived_at", null).maybeSingle();
      if (!sourceEntry) return actionFailure(new Error("Đội/cặp không thuộc hạng mục"));
    }
    if (sourceKind === "group_rank") {
      const { data: sourceGroup } = await supabase.from("groups").select("id").eq("tenant_id", tenantId).eq("tournament_id", fixture.tournament_id).eq("id", sourceGroupId).is("archived_at", null).maybeSingle();
      if (!sourceGroup) return actionFailure(new Error("Bảng nguồn không thuộc hạng mục"));
    }
    if (sourceFixtureId) {
      const { data: sourceFixture } = await supabase.from("fixtures").select("id").eq("tenant_id", tenantId).eq("tournament_id", fixture.tournament_id).eq("id", sourceFixtureId).is("archived_at", null).maybeSingle();
      if (!sourceFixture) return actionFailure(new Error("Trận nguồn không thuộc hạng mục"));
    }
    const { error: syncError } = await supabase.rpc("save_fixture_slot_and_sync", { p_slot_id: slotId, p_source_kind: sourceKind, p_source_entry_id: sourceEntryId, p_source_group_id: sourceGroupId, p_source_fixture_id: sourceFixtureId, p_source_rank: sourceRank, p_label_vi: String(formData.get("label_vi") ?? "").trim(), p_label_en: String(formData.get("label_en") ?? "").trim() });
    if (syncError) return actionFailure(new Error(syncError.message));
    revalidatePath("/", "layout");
    revalidatePath("/admin");
    return { ok: true, message: "Đã lưu cấu trúc nhánh" };
  } catch (error) {
    return actionFailure(error);
  }
}

export async function saveManualStandings(formData: FormData) {
  const tournamentId = String(formData.get("tournament_id") ?? "");
  const groupId = String(formData.get("group_id") ?? "") || null;
  const entryIds = formData.getAll("entry_id").map(String);
  const ranks = formData.getAll("rank").map(String);
  const played = formData.getAll("played").map(String);
  const won = formData.getAll("won").map(String);
  const drawn = formData.getAll("drawn").map(String);
  const lost = formData.getAll("lost").map(String);
  const scoreFor = formData.getAll("score_for").map(String);
  const scoreAgainst = formData.getAll("score_against").map(String);
  const points = formData.getAll("points").map(String);
  const race = formData.get("manual_mode") === "race";
  const lanes = formData.getAll("lane").map(String);
  const performances = formData.getAll("score").map(String);
  const statuses = formData.getAll("result_status").map(String);
  if (!tournamentId || !entryIds.length || [played, won, drawn, lost, scoreFor, scoreAgainst, points].some((items) => items.length !== entryIds.length) || (race && [ranks, lanes, performances, statuses].some((items) => items.length !== entryIds.length))) throw new Error("Bảng xếp hạng không hợp lệ");
  const integerValue = (value: string) => value.trim() ? Number(value) : 0;
  const numericValue = (value: string) => value.trim() ? Number(value) : 0;
  const rows = entryIds.map((entryId, index) => {
    const rank = race ? ranks[index].trim() : "";
    return {
      entry_id: entryId,
      played: integerValue(played[index]),
      won: integerValue(won[index]),
      drawn: integerValue(drawn[index]),
      lost: integerValue(lost[index]),
      score_for: numericValue(scoreFor[index]),
      score_against: numericValue(scoreAgainst[index]),
      points: numericValue(points[index]),
      rank: rank ? Number(rank) : null,
    };
  });
  if (rows.some((row) => !row.entry_id || [row.played, row.won, row.drawn, row.lost].some((value) => !Number.isInteger(value) || value < 0) || [row.score_for, row.score_against, row.points].some((value) => !Number.isFinite(value) || value < 0) || (row.rank !== null && (!Number.isInteger(row.rank) || row.rank < 1)))) throw new Error("Hạng hoặc chỉ số bảng không hợp lệ");
  const explicitRanks = rows.filter((row) => row.rank !== null).map((row) => row.rank);
  if (new Set(explicitRanks).size !== explicitRanks.length) throw new Error("Hạng trong bảng không được trùng");
  const automaticRanks = new Map([...rows].sort((a, b) => b.points - a.points || (b.score_for - b.score_against) - (a.score_for - a.score_against) || b.score_for - a.score_for || a.entry_id.localeCompare(b.entry_id)).map((row, index) => [row.entry_id, index + 1]));
  const persistedRows = race ? rows : rows.map((row) => ({ ...row, rank: automaticRanks.get(row.entry_id) ?? null }));
  const { supabase, tenantId } = await adminClient();
  const { error } = await supabase.rpc("save_manual_standings", { p_tournament_id: tournamentId, p_group_id: groupId, p_rows: persistedRows });
  if (error) throw new Error(error.message);
  if (groupId) {
    const { error: syncError } = await supabase.rpc("confirm_group_standings", { p_group_id: groupId });
    if (syncError) throw new Error(syncError.message);
  }
  if (race) {
    const { data: fixture, error: fixtureError } = await supabase.from("fixtures").select("id").eq("tenant_id", tenantId).eq("tournament_id", tournamentId).is("archived_at", null).order("round_order").limit(1).maybeSingle();
    if (fixtureError || !fixture) throw new Error("Không tìm thấy lượt thi");
    const entries = entryIds.map((entryId, index) => {
      const lane = lanes[index].trim();
      const performance = performances[index].trim();
      const rank = ranks[index].trim();
      const laneNumber = lane ? Number(lane) : null;
      const rankNumber = rank ? Number(rank) : null;
      const scoreNumeric = performance && Number.isFinite(Number(performance)) ? Number(performance) : null;
      if ((laneNumber !== null && (!Number.isInteger(laneNumber) || laneNumber < 1)) || (rankNumber !== null && (!Number.isInteger(rankNumber) || rankNumber < 1))) throw new Error("Hạng hoặc làn không hợp lệ");
      return { entry_id: entryId, side: null, lane: laneNumber, score: performance || null, score_numeric: scoreNumeric, rank: rankNumber, result_status: statuses[index].trim() || null, result_detail: {} };
    });
    const { error: raceError } = await supabase.rpc("save_fixture_result", { p_fixture_id: fixture.id, p_status: "scheduled", p_winner_entry_id: null, p_result_summary_vi: "", p_result_summary_en: "", p_entries: entries, p_standings: null });
    if (raceError) throw new Error(raceError.message);
  }
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function confirmGroupStandings(formData: FormData) {
  const groupId = String(formData.get("group_id") ?? "");
  if (!groupId) throw new Error("Bảng đấu không hợp lệ");
  const { supabase } = await adminClient();
  const { error } = await supabase.rpc("confirm_group_standings", { p_group_id: groupId });
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function saveManualLeaderboard(formData: FormData) {
  const organizationIds = formData.getAll("organization_id").map(String);
  const ranks = formData.getAll("leaderboard_rank").map(String);
  const gold = formData.getAll("gold_medals").map(String);
  const silver = formData.getAll("silver_medals").map(String);
  const bronze = formData.getAll("bronze_medals").map(String);
  if (!organizationIds.length || new Set(organizationIds).size !== organizationIds.length || [ranks, gold, silver, bronze].some((items) => items.length !== organizationIds.length)) throw new Error("Bảng xếp hạng không hợp lệ");
  const rows = organizationIds.map((organizationId, index) => ({ organization_id: organizationId, rank: ranks[index] ? Number(ranks[index]) : null, gold: Number(gold[index] || 0), silver: Number(silver[index] || 0), bronze: Number(bronze[index] || 0) }));
  if (rows.some((row) => (row.rank !== null && (!Number.isInteger(row.rank) || row.rank < 1)) || [row.gold, row.silver, row.bronze].some((value) => !Number.isInteger(value) || value < 0))) throw new Error("Hạng hoặc huy chương không hợp lệ");
  const { supabase } = await adminClient();
  const { error } = await supabase.rpc("save_manual_leaderboard", { p_rows: rows });
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function previewFixtureReset(formData: FormData) {
  const fixtureId = String(formData.get("fixture_id") ?? "");
  const slug = String(formData.get("sport_slug") ?? "");
  const { supabase } = await adminClient();
  const { data, error } = await supabase.rpc("reset_fixture_dependents", { p_fixture_id: fixtureId, p_confirm: false });
  if (error) throw new Error(error.message);
  const count = Array.isArray(data?.fixtures) ? data.fixtures.length : 0;
  redirect(`/admin/sports/${encodeURIComponent(slug)}?section=results&reset=${encodeURIComponent(fixtureId)}&affected=${count}#results`);
}

export async function confirmFixtureReset(formData: FormData) {
  const fixtureId = String(formData.get("fixture_id") ?? "");
  if (formData.get("confirm") !== "yes") throw new Error("Cần xác nhận đặt lại vòng sau");
  const { supabase } = await adminClient();
  const { error } = await supabase.rpc("reset_fixture_dependents", { p_fixture_id: fixtureId, p_confirm: true });
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function saveScoringRule(formData: FormData) {
  const tournamentId = String(formData.get("tournament_id") ?? "");
  if (!tournamentId) throw new Error("Hạng mục không hợp lệ");
  const rule = headToHeadRule(String(formData.get("scoring_type") ?? "manual"), String(formData.get("win_points") ?? ""), String(formData.get("draw_points") ?? ""), String(formData.get("loss_points") ?? ""));
  const { supabase, tenantId } = await adminClient();
  const { error } = await supabase.from("tournaments").update({ scoring_rule: rule }).eq("tenant_id", tenantId).eq("id", tournamentId).is("archived_at", null);
  if (error) throw new Error(error.message);
  revalidatePath("/admin");
}

function excelAdminPath(slug: string, params: string) { return `/admin/sports/${encodeURIComponent(slug)}?section=excel&${params}#excel`; }

export async function prepareSportExcelImport(formData: FormData) {
  const slug = String(formData.get("sport_slug") ?? "").trim();
  const fail = (message: string): never => redirect(excelAdminPath(slug || "", `error=${encodeURIComponent(message)}`));
  let importId = "";
  try {
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) fail("Môn thể thao không hợp lệ");
    const file = formData.get("file");
    if (!(file instanceof File) || !file.size || file.size > SPORT_EXCEL_MAX_BYTES || !file.name.toLowerCase().endsWith(".xlsx")) fail("Chỉ nhận file .xlsx từ 1 byte đến 10 MB");
    const uploadFile = file as File;
    const { supabase, tenantId } = await adminClient();
    const { data: sport, error: sportError } = await supabase.from("sports").select("id,slug").eq("tenant_id", tenantId).eq("slug", slug).is("archived_at", null).maybeSingle();
    if (sportError || !sport) fail("Môn thể thao không hợp lệ");
    const currentSport = sport as { id: string; slug: string };
    const buffer = Buffer.from(await uploadFile.arrayBuffer());
    const parsed = await parseSportWorkbook(buffer);
    if (parsed.meta.tenant_slug !== tenantSlug || parsed.meta.sport_slug !== slug || parsed.meta.sport_id !== currentSport.id) fail("Workbook không thuộc tenant hoặc môn đang mở");
    const exportId = parsed.meta.export_id;
    const { data: exportRow, error: exportError } = await supabase.from("sport_excel_exports").select("id,sport_id,template_version,mode,payload").eq("tenant_id", tenantId).eq("id", exportId).eq("sport_id", currentSport.id).is("archived_at", null).maybeSingle();
    if (exportError || !exportRow || exportRow.template_version !== SPORT_EXCEL_VERSION || exportRow.mode !== parsed.meta.mode) fail("Snapshot export không hợp lệ hoặc đã hết hiệu lực");
    const currentExport = exportRow as { payload: unknown; mode: string; template_version: number };
    const snapshot = currentExport.payload as SportExcelSnapshot;
    const operationPayload = buildOperations(parsed, snapshot, currentSport.id);
    const preview = previewOperations(operationPayload.operations);
    const { data, error } = await supabase.rpc("prepare_sport_excel_import", { p_sport_id: currentSport.id, p_export_id: exportId, p_template_version: SPORT_EXCEL_VERSION, p_mode: parsed.meta.mode, p_file_sha256: createHash("sha256").update(buffer).digest("hex"), p_payload: operationPayload, p_preview: preview });
    if (error) fail(error.message);
    importId = String((data as { import_id?: string } | null)?.import_id ?? "");
    if (!importId) fail("Không tạo được phiên import");
  } catch (error) {
    if (error instanceof Error && error.message) fail(error.message);
    fail("Không thể đọc file Excel");
  }
  redirect(excelAdminPath(slug, `import=${encodeURIComponent(importId)}`));
}

export async function applySportExcelImport(formData: FormData) {
  const slug = String(formData.get("sport_slug") ?? "").trim();
  const importId = String(formData.get("import_id") ?? "").trim();
  try {
    if (!importId || !/^[a-z0-9]+(?:-[a-z0-9]*[a-z0-9])?$/.test(slug)) throw new Error("Yêu cầu import không hợp lệ");
    const { supabase } = await adminClient();
    const { error } = await supabase.rpc("apply_sport_excel_import", { p_import_id: importId, p_confirm: formData.get("confirm") === "yes" });
    if (error) throw new Error(error.message);
    revalidatePath("/", "layout");
    revalidatePath(`/admin/sports/${slug}`);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Không thể áp dụng import";
    redirect(excelAdminPath(slug, `import=${encodeURIComponent(importId)}&error=${encodeURIComponent(message)}`));
  }
  redirect(excelAdminPath(slug, `import=${encodeURIComponent(importId)}`));
}

export async function rollbackSportExcelImport(formData: FormData) {
  const slug = String(formData.get("sport_slug") ?? "").trim();
  const importId = String(formData.get("import_id") ?? "").trim();
  try {
    if (!importId || !/^[a-z0-9]+(?:-[a-z0-9]*[a-z0-9])?$/.test(slug)) throw new Error("Yêu cầu rollback không hợp lệ");
    const { supabase } = await adminClient();
    const { error } = await supabase.rpc("rollback_sport_excel_import", { p_import_id: importId });
    if (error) throw new Error(error.message);
    revalidatePath("/", "layout");
    revalidatePath(`/admin/sports/${slug}`);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Không thể rollback import";
    redirect(excelAdminPath(slug, `import=${encodeURIComponent(importId)}&error=${encodeURIComponent(message)}`));
  }
  redirect(excelAdminPath(slug, `import=${encodeURIComponent(importId)}`));
}

export async function logout() {
  const supabase = await createSupabaseServerClient();
  await supabase.auth.signOut();
  redirect("/login");
}
