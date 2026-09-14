import Link from "next/link";
import { redirect } from "next/navigation";
import { PtscImportPreview } from "@/components/ptsc-import-preview";
import { SubmitButton } from "@/components/submit-button";
import { withTimeout } from "@/lib/auth-timeout";
import { hasSupabaseConfig, createSupabaseServerClient } from "@/lib/supabase/server";
import { getTenantId } from "@/lib/tenant";
import { commitPtscTemplateImport, preparePtscTemplateImport, rollbackPtscTemplateImport } from "../actions";

type Params = Promise<{ batch?: string; error?: string }>;
type Preview = { blockers?: string[]; warnings?: string[]; stats?: Record<string, number>; rows?: Array<{ sheet?: string; row_number?: number; category_code?: string; natural_key?: string; status?: string; action?: string }> };

export default async function PtscExcelAdminPage({ searchParams }: { searchParams: Params }) {
  if (!hasSupabaseConfig()) return <main className="admin-page"><section className="admin-card"><h1>Supabase chưa cấu hình</h1></section></main>;
  const query = await searchParams;
  const supabase = await createSupabaseServerClient();
  const tenantId = await getTenantId(supabase);
  let claims;
  try { ({ data: claims } = await withTimeout(() => supabase.auth.getClaims())); } catch { redirect("/login?error=session"); }
  const userId = claims?.claims?.sub;
  if (!userId) redirect("/login");
  const { data: admin } = await supabase.from("admin_users").select("display_name").eq("tenant_id", tenantId).eq("user_id", userId).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");
  const { data: batches } = await supabase.from("import_batches").select("id,file_name,status,created_at,applied_at").eq("tenant_id", tenantId).order("created_at", { ascending: false }).limit(20);
  const batch = query.batch ? (await supabase.from("import_batches").select("id,file_name,status,created_at,applied_at,preview").eq("tenant_id", tenantId).eq("id", query.batch).maybeSingle()).data : null;
  const preview = (batch?.preview ?? {}) as Preview;
  const blockers = preview.blockers ?? [];
  return <main className="admin-page"><header className="admin-header"><div><b>PTSC 2026</b><small>Excel import / Quản trị</small></div><Link href="/admin">← Dashboard</Link></header><div className="admin-layout"><aside><a href="#upload">Nạp workbook</a><a href="#batches">Lịch sử import</a></aside><div className="admin-main"><section id="upload" className="admin-card"><h1>Template Excel PTSC 11 môn</h1><p>Nạp workbook 13 sheet. Hệ thống kiểm tra toàn bộ trước khi ghi dữ liệu vào tenant <code>ptsc2026</code>.</p>{query.error && <p className="form-error">{query.error}</p>}<form action={preparePtscTemplateImport} className="admin-upload-form"><label><span>File .xlsx</span><input type="file" name="file" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" required/></label><label><span>Idempotency-Key (tùy chọn)</span><input name="idempotency_key" placeholder="Tự sinh nếu bỏ trống" maxLength={200}/></label><SubmitButton className="gold-button">Kiểm tra & xem trước</SubmitButton></form></section>{batch && <section className="admin-card"><div className="admin-title"><div><h2>Batch {batch.id}</h2><p>{batch.file_name} · {batch.status}</p></div><a href={`/admin/excel/report/${batch.id}`}>Tải báo cáo CSV ↗</a></div><div className="ptsc-import-stats">{Object.entries(preview.stats ?? {}).map(([key, value]) => <span key={key}><b>{value}</b><small>{key}</small></span>)}</div>{blockers.length > 0 && <div className="form-error"><b>Blocker ({blockers.length})</b>{blockers.slice(0, 20).map((message) => <div key={message}>{message}</div>)}</div>}{(preview.warnings ?? []).length > 0 && <div className="form-warning"><b>Cảnh báo ({preview.warnings?.length})</b>{preview.warnings?.slice(0, 20).map((message) => <div key={message}>{message}</div>)}</div>}<PtscImportPreview rows={preview.rows ?? []}/><div className="admin-actions">{batch.status === "prepared" && blockers.length === 0 && <form action={commitPtscTemplateImport}><input type="hidden" name="import_id" value={batch.id}/><input type="hidden" name="confirm" value="yes"/><SubmitButton className="gold-button">Xác nhận ghi dữ liệu</SubmitButton></form>}{batch.status === "applied" && <form action={rollbackPtscTemplateImport}><input type="hidden" name="import_id" value={batch.id}/><SubmitButton className="archive-button">Rollback batch</SubmitButton></form>}</div></section>}<section id="batches" className="admin-card"><h2>Lịch sử import</h2><div className="record-list">{(batches ?? []).map((item) => <Link className="record" href={`/admin/excel?batch=${item.id}`} key={item.id}><span>{item.file_name}</span><small>{item.status} · {new Date(item.created_at).toLocaleString("vi-VN")}</small></Link>)}</div></section></div></div></main>;
}
