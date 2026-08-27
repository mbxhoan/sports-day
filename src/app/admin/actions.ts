"use server";

import { randomUUID } from "node:crypto";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { adminEntities, type AdminEntity } from "@/lib/admin-config";
import { formValue as valueOf } from "@/lib/admin-form";
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

export async function saveEvent(formData: FormData) {
  const supabase = await adminClient();
  const payload = Object.fromEntries([
    "event_name_vi", "event_name_en", "subtitle_vi", "subtitle_en", "about_vi", "about_en",
    "venue_vi", "venue_en", "hero_path", "start_at", "end_at",
  ].map((name) => [name, valueOf(formData, name, name.endsWith("_at") ? "datetime-local" : undefined)]));
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
  if (!['image/png','image/jpeg','image/webp'].includes(file.type) || file.size > 10 * 1024 * 1024) throw new Error("Chỉ nhận PNG/JPEG/WebP tối đa 10MB");
  const supabase = await adminClient();
  const extension = ({ "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp" } as Record<string, string>)[file.type];
  const path = `gallery/${randomUUID()}.${extension}`;
  const { error: uploadError } = await supabase.storage.from("event-media").upload(path, file, { contentType: file.type, upsert: false });
  if (uploadError) throw new Error(uploadError.message);
  const requestedTag = String(formData.get("filter_tag") ?? "all").trim();
  const filterTag = /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(requestedTag) ? requestedTag : "all";
  const { error } = await supabase.from("media").insert({ storage_path: path, kind: "gallery", filter_tag: filterTag, title_vi: String(formData.get("title_vi") ?? "").trim(), title_en: String(formData.get("title_en") ?? "").trim(), alt_vi: String(formData.get("alt_vi") ?? "").trim(), alt_en: String(formData.get("alt_en") ?? "").trim() });
  if (error) throw new Error(error.message);
  revalidatePath("/gallery");
  revalidatePath("/en/gallery");
  revalidatePath("/admin");
}

export async function logout() {
  const supabase = await createSupabaseServerClient();
  await supabase.auth.signOut();
  redirect("/login");
}
