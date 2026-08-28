"use server";

import { randomUUID } from "node:crypto";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { adminEntities, type AdminEntity } from "@/lib/admin-config";
import { formValue as valueOf } from "@/lib/admin-form";
import { eventFieldNames } from "@/lib/admin-event";
import { assertImageFile, heroStoragePath } from "@/lib/admin-media";
import { relationEntity } from "@/lib/admin-relations";
import { deriveStandings, headToHeadRule } from "@/lib/standings";
import { createSupabaseServerClient } from "@/lib/supabase/server";

async function adminClient() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase.auth.getClaims();
  const userId = data?.claims?.sub;
  if (!userId) redirect("/login?error=session");
  const { data: admin } = await supabase.from("admin_users").select("user_id").eq("user_id", userId).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");
  return supabase;
}

async function validateRelations(supabase: Awaited<ReturnType<typeof adminClient>>, payload: Record<string, unknown>) {
  for (const [field, value] of Object.entries(payload)) {
    const entity = relationEntity(field);
    if (!entity || value === null || value === "") continue;
    if (typeof value !== "string") throw new Error("Liên kết không hợp lệ");
    const { data, error } = await supabase.from(entity).select("id").eq("id", value).is("archived_at", null).maybeSingle();
    if (error || !data) throw new Error("Liên kết không hợp lệ");
  }
}

export async function saveEvent(formData: FormData) {
  const supabase = await adminClient();
  const payload = Object.fromEntries(eventFieldNames.map((name) => [name, valueOf(formData, name, name.endsWith("_at") ? "datetime-local" : undefined)]));
  const { error } = await supabase.from("event_settings").update(payload).eq("singleton_key", "main");
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
}

export async function saveRecord(formData: FormData) {
  const entity = String(formData.get("entity")) as AdminEntity;
  if (!(entity in adminEntities)) throw new Error("Entity không hợp lệ");
  const supabase = await adminClient();
  const config = adminEntities[entity];
  const payload = Object.fromEntries(config.fields.map((field) => [field.name, valueOf(formData, field.name, "type" in field ? field.type : undefined)]));
  await validateRelations(supabase, payload);
  const id = String(formData.get("id") ?? "");
  const query = id ? supabase.from(entity).update(payload).eq("id", id) : supabase.from(entity).insert(payload);
  const { error } = await query;
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function setArchived(formData: FormData) {
  const entity = String(formData.get("entity")) as AdminEntity;
  const id = String(formData.get("id") ?? "");
  if (!(entity in adminEntities) || !id) throw new Error("Yêu cầu không hợp lệ");
  const supabase = await adminClient();
  const archived = formData.get("archived") === "true";
  const { error } = await supabase.from(entity).update({ archived_at: archived ? new Date().toISOString() : null }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function uploadMedia(formData: FormData) {
  const file = formData.get("file");
  if (!(file instanceof File) || !file.size) throw new Error("Chưa chọn ảnh");
  const supabase = await adminClient();
  const extension = assertImageFile(file);
  const requestedTag = String(formData.get("filter_tag") ?? "all").trim();
  let sportId = String(formData.get("sport_id") ?? "").trim() || null;
  let filterTag = /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(requestedTag) ? requestedTag : "all";
  if (sportId) {
    const { data: sport, error: sportError } = await supabase.from("sports").select("id,slug").eq("id", sportId).is("archived_at", null).maybeSingle();
    if (sportError || !sport) throw new Error("Môn thể thao không hợp lệ");
    sportId = sport.id;
    filterTag = sport.slug;
  }
  const path = `gallery/${randomUUID()}.${extension}`;
  const { error: uploadError } = await supabase.storage.from("event-media").upload(path, file, { contentType: file.type, upsert: false });
  if (uploadError) throw new Error(uploadError.message);
  const { error } = await supabase.from("media").insert({ storage_path: path, kind: "gallery", sport_id: sportId, filter_tag: filterTag, album_vi: String(formData.get("album_vi") ?? "").trim(), album_en: String(formData.get("album_en") ?? "").trim(), title_vi: String(formData.get("title_vi") ?? "").trim(), title_en: String(formData.get("title_en") ?? "").trim(), alt_vi: String(formData.get("alt_vi") ?? "").trim(), alt_en: String(formData.get("alt_en") ?? "").trim() });
  if (error) throw new Error(error.message);
  revalidatePath("/gallery");
  revalidatePath("/en/gallery");
  revalidatePath("/admin");
}

export async function uploadHero(formData: FormData) {
  const file = formData.get("file");
  const variant = String(formData.get("variant"));
  if (!(file instanceof File)) throw new Error("Chưa chọn ảnh");
  const supabase = await adminClient();
  assertImageFile(file);
  const path = heroStoragePath(variant, file.type, randomUUID());
  const { error: uploadError } = await supabase.storage.from("event-media").upload(path, file, { contentType: file.type, upsert: false });
  if (uploadError) throw new Error(uploadError.message);
  const column = variant === "mobile" ? "hero_mobile_path" : "hero_path";
  const { error } = await supabase.from("event_settings").update({ [column]: supabase.storage.from("event-media").getPublicUrl(path).data.publicUrl }).eq("singleton_key", "main");
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function saveFixtureResult(formData: FormData) {
  const fixtureId = String(formData.get("fixture_id") ?? "");
  const status = String(formData.get("status") ?? "completed");
  const selected = [1, 2].map((index) => ({ entry_id: String(formData.get(`entry_${index}`) ?? ""), score: String(formData.get(`score_${index}`) ?? "").trim() }));
  if (!fixtureId || selected.some((item) => !item.entry_id) || selected[0].entry_id === selected[1].entry_id) throw new Error("Chọn hai đội khác nhau");
  const entries = selected.map((item, index) => {
    const scoreNumeric = item.score === "" ? null : Number(item.score);
    if (scoreNumeric !== null && (!Number.isFinite(scoreNumeric) || scoreNumeric < 0)) throw new Error("Tỷ số không hợp lệ");
    return { entry_id: item.entry_id, side: index === 0 ? "home" : "away", score: item.score || null, score_numeric: scoreNumeric, rank: null, result_detail: {} };
  });
  const supabase = await adminClient();
  const { data: fixture, error: fixtureError } = await supabase.from("fixtures").select("id,tournament_id,group_id").eq("id", fixtureId).is("archived_at", null).single();
  if (fixtureError || !fixture) throw new Error("Không tìm thấy trận đấu");
  const { data: tournament, error: tournamentError } = await supabase.from("tournaments").select("scoring_rule").eq("id", fixture.tournament_id).is("archived_at", null).single();
  if (tournamentError || !tournament) throw new Error("Không tìm thấy hạng mục");
  const { data: relatedFixtures } = await supabase.from("fixtures").select("id,status").eq("tournament_id", fixture.tournament_id).is("group_id", fixture.group_id).is("archived_at", null);
  const fixtureIds = (relatedFixtures ?? []).map((item) => item.id);
  const { data: relatedEntries } = fixtureIds.length ? await supabase.from("fixture_entries").select("fixture_id,entry_id,score_numeric").in("fixture_id", fixtureIds).is("archived_at", null) : { data: [] };
  const allFixtures = (relatedFixtures ?? []).map((item) => ({ status: item.id === fixtureId ? status : item.status, entries: item.id === fixtureId ? entries : (relatedEntries ?? []).filter((entry) => entry.fixture_id === item.id).map((entry) => ({ entry_id: entry.entry_id, score_numeric: entry.score_numeric === null ? null : Number(entry.score_numeric) })) }));
  const scoringRule = tournament.scoring_rule && typeof tournament.scoring_rule === "object" ? tournament.scoring_rule : {};
  const standings = deriveStandings(allFixtures, scoringRule);
  const requestedWinner = String(formData.get("winner_entry_id") ?? "");
  const automaticWinner = status === "completed" && entries[0].score_numeric !== null && entries[1].score_numeric !== null && entries[0].score_numeric !== entries[1].score_numeric ? entries[entries[0].score_numeric > entries[1].score_numeric ? 0 : 1].entry_id : null;
  const winnerEntryId = requestedWinner || automaticWinner;
  const { data: labels } = await supabase.from("entries").select("id,name_vi,name_en").in("id", entries.map((item) => item.entry_id));
  const labelsById = new Map((labels ?? []).map((item) => [item.id, item]));
  const summary = (field: "name_vi" | "name_en") => entries.map((item) => `${labelsById.get(item.entry_id)?.[field] ?? ""} ${item.score ?? ""}`.trim()).join(" - ");
  const { error } = await supabase.rpc("save_fixture_result", { p_fixture_id: fixtureId, p_status: status, p_winner_entry_id: winnerEntryId || null, p_result_summary_vi: summary("name_vi"), p_result_summary_en: summary("name_en"), p_entries: entries, p_standings: standings.length ? standings : null });
  if (error) throw new Error(error.message);
  revalidatePath("/", "layout");
  revalidatePath("/admin");
}

export async function saveScoringRule(formData: FormData) {
  const tournamentId = String(formData.get("tournament_id") ?? "");
  if (!tournamentId) throw new Error("Hạng mục không hợp lệ");
  const rule = headToHeadRule(String(formData.get("scoring_type") ?? "manual"), String(formData.get("win_points") ?? ""), String(formData.get("draw_points") ?? ""), String(formData.get("loss_points") ?? ""));
  const supabase = await adminClient();
  const { error } = await supabase.from("tournaments").update({ scoring_rule: rule }).eq("id", tournamentId).is("archived_at", null);
  if (error) throw new Error(error.message);
  revalidatePath("/admin");
}

export async function logout() {
  const supabase = await createSupabaseServerClient();
  await supabase.auth.signOut();
  redirect("/login");
}
