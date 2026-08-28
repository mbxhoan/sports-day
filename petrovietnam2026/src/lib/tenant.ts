import type { SupabaseClient } from "@supabase/supabase-js";

export const tenantSlug = process.env.NEXT_PUBLIC_TENANT_SLUG?.trim() ?? "";

export function tenantHeaders(): Record<string, string> {
  return tenantSlug ? { "x-tenant-slug": tenantSlug } : {};
}

export async function getTenantId(supabase: SupabaseClient) {
  if (!tenantSlug) throw new Error("Tenant chưa được cấu hình");
  const { data, error } = await supabase.from("tenants").select("id").eq("slug", tenantSlug).maybeSingle();
  if (error || !data) throw new Error("Tenant không hợp lệ");
  return data.id as string;
}
