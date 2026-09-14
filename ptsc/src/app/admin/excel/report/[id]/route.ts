import { NextResponse } from "next/server";
import { withTimeout } from "@/lib/auth-timeout";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getTenantId } from "@/lib/tenant";

function csvCell(value: unknown) {
  const text = String(value ?? "").replace(/\r?\n/gu, " ");
  return /[",]/u.test(text) ? `"${text.replace(/"/gu, '""')}"` : text;
}

export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const tenantId = await getTenantId(supabase);
  let claims;
  try { ({ data: claims } = await withTimeout(() => supabase.auth.getClaims())); } catch { return new NextResponse("Unauthorized", { status: 401 }); }
  const userId = claims?.claims?.sub;
  if (!userId) return new NextResponse("Unauthorized", { status: 401 });
  const { data: admin } = await supabase.from("admin_users").select("user_id").eq("tenant_id", tenantId).eq("user_id", userId).maybeSingle();
  if (!admin) return new NextResponse("Forbidden", { status: 403 });
  const { data: batch, error: batchError } = await supabase.from("import_batches").select("file_name,preview").eq("tenant_id", tenantId).eq("id", id).maybeSingle();
  if (batchError || !batch) return new NextResponse("Not found", { status: 404 });
  const { data: rows, error } = await supabase.from("import_rows").select("sheet_name,excel_row,category_code,natural_key,source_status,status,errors,warnings").eq("tenant_id", tenantId).eq("batch_id", id).order("excel_row");
  if (error) return new NextResponse(error.message, { status: 500 });
  const lines = [["Sheet", "Dòng", "Mã hạng mục", "Khóa tự nhiên", "Nguồn", "Thao tác", "Lỗi", "Cảnh báo"], ...(rows ?? []).map((row) => [row.sheet_name, row.excel_row, row.category_code, row.natural_key, row.source_status, row.status, JSON.stringify(row.errors ?? []), JSON.stringify(row.warnings ?? [])])].map((row) => row.map(csvCell).join(","));
  return new NextResponse(`\ufeff${lines.join("\n")}`, { headers: { "content-type": "text/csv; charset=utf-8", "content-disposition": `attachment; filename="ptsc-import-${id}.csv"` } });
}
