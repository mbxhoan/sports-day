import { notFound, redirect } from "next/navigation";
import { buildSportWorkbook, SPORT_EXCEL_SPORTS, SPORT_EXCEL_VERSION, type SportExcelMode, type SportExcelSnapshot, type SportExcelView } from "@/lib/sport-excel";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getTenantId, tenantSlug } from "@/lib/tenant";
import { withTimeout } from "@/lib/auth-timeout";

export const runtime = "nodejs";

export async function GET(request: Request, { params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const searchParams = new URL(request.url).searchParams;
  const requestedMode = searchParams.get("mode");
  const view = searchParams.get("view") === "results" ? "results" as SportExcelView : "full" as SportExcelView;
  const mode = (view === "results" ? "current" : requestedMode) as SportExcelMode | null;
  if (mode !== "current" && mode !== "blank") return new Response("mode không hợp lệ", { status: 400 });
  if (!SPORT_EXCEL_SPORTS.includes(slug as (typeof SPORT_EXCEL_SPORTS)[number])) return new Response("Môn thể thao không được hỗ trợ", { status: 422 });
  const supabase = await createSupabaseServerClient();
  const tenantId = await getTenantId(supabase);
  let claims;
  try { ({ data: claims } = await withTimeout(() => supabase.auth.getClaims())); } catch { redirect("/login?error=session"); }
  const userId = claims?.claims?.sub;
  if (!userId) redirect("/login?error=session");
  const { data: admin } = await supabase.from("admin_users").select("user_id").eq("tenant_id", tenantId).eq("user_id", userId).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");
  const { data: sport, error: sportError } = await supabase.from("sports").select("id,slug").eq("tenant_id", tenantId).eq("slug", slug).is("archived_at", null).maybeSingle();
  if (sportError || !sport) notFound();
  const { data, error } = await supabase.rpc("create_sport_excel_export", { p_sport_id: sport.id, p_mode: mode, p_template_version: SPORT_EXCEL_VERSION });
  if (error || !data) return new Response(error?.message ?? "Không thể tạo template Excel", { status: 422 });
  const result = data as { export_id?: string; snapshot?: SportExcelSnapshot };
  if (!result.export_id || !result.snapshot || result.snapshot.sport_slug !== slug || result.snapshot.sport_id !== sport.id || tenantSlug !== "petrovietnam2026") return new Response("Snapshot Excel không hợp lệ", { status: 422 });
  const workbook = await buildSportWorkbook(result.snapshot, mode, result.export_id, view);
  return new Response(workbook, { headers: { "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Content-Disposition": `attachment; filename="${slug}-${view === "results" ? "ket-qua" : mode}.xlsx"`, "Cache-Control": "private, no-store" } });
}
