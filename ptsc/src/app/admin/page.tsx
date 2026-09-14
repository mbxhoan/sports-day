import { Archive, LogOut, RotateCcw, Save, Settings, Trophy } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";
import { adminEntities, type AdminEntity, type AdminField } from "@/lib/admin-config";
import { hasSupabaseConfig, createSupabaseServerClient } from "@/lib/supabase/server";
import { MarkdownInput } from "@/components/markdown-input";
import { toVietnamLocalInput } from "@/lib/datetime";
import { relationEntity } from "@/lib/admin-relations";
import { SubmitButton } from "@/components/submit-button";
import { AdminRecordForm } from "@/components/admin-record-form";
import { getTenantId } from "@/lib/tenant";
import { withTimeout } from "@/lib/auth-timeout";
import { logout, saveEvent, saveManualLeaderboard, saveOrganizationName, saveRecordAction, setArchived, uploadHero } from "./actions";

type Row = Record<string, string | number | null> & { id: string; archived_at: string | null };

const dashboardColumns = {
  event_settings: "id,event_name_vi,event_name_en,subtitle_vi,subtitle_en,about_vi,about_en,venue_vi,venue_en,hero_path,hero_mobile_path,start_at,end_at,gallery_drive_url,archived_at",
  sports: "id,slug,name_vi,name_en,emoji,description_vi,description_en,rules_vi,rules_en,sort_order,archived_at",
  organizations: "id,code,name_vi,name_en,logo_path,sort_order,leaderboard_rank,gold_medals,silver_medals,bronze_medals,archived_at",
  contacts: "id,label_vi,label_en,value,href,sort_order,archived_at",
  footer_links: "id,label_vi,label_en,href,sort_order,archived_at",
} as const;

function Fields({ fields, row = {}, rows }: { fields: readonly AdminField[]; row?: Partial<Row>; rows: Record<AdminEntity, Row[]> }) {
  return <div className="admin-fields">{fields.map((field) => {
    const relation = relationEntity(field.name);
    const options = relation ? rows[relation].filter((item) => !item.archived_at) : [];
    return <label key={field.name}><span>{field.label}</span>{field.type === "textarea" ? <MarkdownInput name={field.name} defaultValue={String(row[field.name] ?? "")}/> : relation || field.options ? <select name={field.name} defaultValue={String(row[field.name] ?? "")} required={field.required}><option value="">Chọn / Select</option>{relation ? options.map((item) => <option value={item.id} key={item.id}>{summary(item)}</option>) : field.options?.map((option) => <option value={option.value} key={option.value}>{option.label}</option>)}</select> : <input name={field.name} type={field.type ?? "text"} defaultValue={String(row[field.name] ?? "")} required={field.required}/>}</label>;
  })}</div>;
}

function summary(row: Row) {
  return String(row.name_vi ?? row.title_vi ?? row.full_name ?? row.code ?? row.value ?? row.id);
}

function CrudSection({ entity, rows, allRows }: { entity: AdminEntity; rows: Row[]; allRows: Record<AdminEntity, Row[]> }) {
  const config = adminEntities[entity];
  return <details className="admin-section"><summary><span>{config.title}</span><small>{rows.length}</small></summary><div className="admin-section-body">
    <details className="record-form"><summary>＋ Thêm / Add</summary><AdminRecordForm action={saveRecordAction}><input type="hidden" name="entity" value={entity}/><Fields fields={config.fields} rows={allRows}/><SubmitButton className="gold-button"><Save size={15}/>Lưu / Save</SubmitButton></AdminRecordForm></details>
    <div className="record-list">{rows.map((row) => <details className={`record ${row.archived_at ? "archived" : ""}`} key={row.id}><summary><span>{summary(row)}</span>{row.archived_at && <em>Archived</em>}</summary><AdminRecordForm action={saveRecordAction}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><Fields fields={config.fields} row={row} rows={allRows}/><SubmitButton className="gold-button"><Save size={15}/>Lưu / Save</SubmitButton></AdminRecordForm><form action={setArchived}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="archived" value={row.archived_at ? "false" : "true"}/><SubmitButton className="archive-button">{row.archived_at ? <RotateCcw size={15}/> : <Archive size={15}/>} {row.archived_at ? "Khôi phục / Restore" : "Lưu trữ / Archive"}</SubmitButton></form></details>)}</div>
  </div></details>;
}

export default async function AdminPage() {
  if (!hasSupabaseConfig()) return <div className="admin-unavailable"><Settings/><h1>Supabase chưa cấu hình</h1><p>Copy `.env.example` thành `.env.local`, điền key từ `supabase status`, rồi chạy lại.</p></div>;
  const supabase = await createSupabaseServerClient();
  const tenantId = await getTenantId(supabase);
  let claims;
  try { ({ data: claims } = await withTimeout(() => supabase.auth.getClaims())); } catch { redirect("/login?error=session"); }
  const userId = claims?.claims?.sub;
  if (!userId) redirect("/login");
  const { data: admin } = await supabase.from("admin_users").select("display_name").eq("tenant_id", tenantId).eq("user_id", userId).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");

  const dashboardEntities = ["sports", "organizations", "contacts", "footer_links"] as const;
  const [eventResult, ...rowResults] = await Promise.all([
    supabase.from("event_settings").select(dashboardColumns.event_settings).eq("tenant_id", tenantId).eq("singleton_key", "main").single(),
    ...dashboardEntities.map((entity) => supabase.from(entity).select(dashboardColumns[entity]).eq("tenant_id", tenantId).order("archived_at", { ascending: true, nullsFirst: true }).range(0, 99)),
  ]);
  const event = eventResult.data as Row;
  const rows = Object.fromEntries(Object.keys(adminEntities).map((entity) => [entity, [] as Row[]])) as Record<AdminEntity, Row[]>;
  dashboardEntities.forEach((entity, index) => { rows[entity] = (rowResults[index].data ?? []) as unknown as Row[]; });

  return <main className="admin-page"><header className="admin-header"><div><Trophy/><span><b>PTSC 2026</b><small>Admin / Quản trị</small></span></div><form action={logout}><SubmitButton><LogOut size={16}/>Đăng xuất</SubmitButton></form></header><div className="admin-layout"><aside><a href="#content">Nội dung / Content</a><a href="#organizations">Đơn vị / Organizations</a><a href="#media">Hình ảnh / Media</a><a href="#data">Dữ liệu thi đấu / Competition</a><Link href="/admin/excel">Import template PTSC</Link></aside><div className="admin-main">
    <div className="admin-title"><div><h1>Dashboard</h1><p>Xin chào, {admin.display_name}</p></div><a href="/" target="_blank">Xem website ↗</a></div>
    <section id="sports" className="admin-quick-sports"><h2 className="section-label">Môn thể thao / Sports</h2><div className="admin-sport-grid">{rows.sports.filter((sport) => !sport.archived_at).map((sport) => <Link key={sport.id} href={`/admin/sports/${sport.slug}`}><b>{summary(sport)}</b><small>Hạng mục, đội, lịch, kết quả, thư viện</small></Link>)}</div></section>
    <section id="content" className="admin-card"><h2>Nội dung sự kiện / Event content</h2><form action={saveEvent}><div className="admin-fields"><label><span>Tên sự kiện VI</span><input name="event_name_vi" defaultValue={String(event.event_name_vi ?? "")}/></label><label><span>Event name EN</span><input name="event_name_en" defaultValue={String(event.event_name_en ?? "")}/></label><label><span>Phụ đề VI</span><input name="subtitle_vi" defaultValue={String(event.subtitle_vi ?? "")}/></label><label><span>Subtitle EN</span><input name="subtitle_en" defaultValue={String(event.subtitle_en ?? "")}/></label><label><span>Giới thiệu VI</span><MarkdownInput name="about_vi" defaultValue={String(event.about_vi ?? "")}/></label><label><span>About EN</span><MarkdownInput name="about_en" defaultValue={String(event.about_en ?? "")}/></label><label><span>Địa điểm VI</span><input name="venue_vi" defaultValue={String(event.venue_vi ?? "")}/></label><label><span>Venue EN</span><input name="venue_en" defaultValue={String(event.venue_en ?? "")}/></label><label><span>Bắt đầu</span><input type="datetime-local" name="start_at" defaultValue={event.start_at ? toVietnamLocalInput(String(event.start_at)) : ""}/></label><label><span>Kết thúc</span><input type="datetime-local" name="end_at" defaultValue={event.end_at ? toVietnamLocalInput(String(event.end_at)) : ""}/></label><label><span>Google Drive folder (HTTPS)</span><input name="gallery_drive_url" type="url" placeholder="https://drive.google.com/drive/folders/..." defaultValue={String(event.gallery_drive_url ?? "")}/></label></div><SubmitButton className="gold-button"><Save size={15}/>Lưu nội dung / Save</SubmitButton></form><div className="hero-upload-grid">{([['desktop','KV desktop',String(event.hero_path ?? '/kv.png')],['mobile','KV mobile',String(event.hero_mobile_path ?? '/kv-mobile.png')]] as const).map(([variant,label,path]) => <form action={uploadHero} key={variant} className="hero-upload"><b>{label}</b><div className="hero-upload-preview"><Image src={path} alt={label} fill sizes="320px" unoptimized={path.startsWith("http")}/></div><input type="hidden" name="variant" value={variant}/><input type="file" name="file" accept="image/png,image/jpeg,image/webp" required/><SubmitButton className="gold-button">Tải lên / Upload</SubmitButton></form>)}</div></section>
    <section id="organizations" className="admin-card organization-admin-card"><div className="organization-admin-heading"><div><h2>Danh mục đơn vị</h2><p className="upload-help">Chỉ sửa tên đầy đủ. Mã viết tắt được giữ nguyên và đơn vị không có thao tác xoá.</p></div><span className="readonly-badge">Mã viết tắt cố định</span></div><div className="organization-editor-list">{rows.organizations.filter((row) => !row.archived_at).map((row) => <div className="organization-editor-row" key={row.id}><div className="organization-identity"><span>{String(row.code ?? "—")}</span><div><b>{summary(row)}</b><small>Website sẽ hiển thị tên này</small></div></div><form action={saveOrganizationName} className="organization-name-form"><input type="hidden" name="id" value={row.id}/><label><span>Tên đầy đủ</span><input name="name_vi" defaultValue={String(row.name_vi ?? "")} maxLength={200} required/></label><SubmitButton className="gold-button"><Save size={15}/>Lưu tên</SubmitButton></form></div>)}</div></section>
    <section id="leaderboard" className="admin-card"><h2>Bảng xếp hạng đoàn / Organization leaderboard</h2><p className="upload-help">Nhập toàn bộ đoàn trong một lần lưu. Đoàn chưa có hạng nằm cuối.</p><form action={saveManualLeaderboard}><div className="leaderboard-admin-list">{rows.organizations.filter((row) => !row.archived_at).map((row) => <div className="leaderboard-admin-row" key={row.id}><input type="hidden" name="organization_id" value={row.id}/><b>{summary(row)}</b><label>Hạng<input name="leaderboard_rank" type="number" min="1" defaultValue={String(row.leaderboard_rank ?? "")}/></label><label>Vàng<input name="gold_medals" type="number" min="0" defaultValue={String(row.gold_medals ?? 0)}/></label><label>Bạc<input name="silver_medals" type="number" min="0" defaultValue={String(row.silver_medals ?? 0)}/></label><label>Đồng<input name="bronze_medals" type="number" min="0" defaultValue={String(row.bronze_medals ?? 0)}/></label><span>Tổng {Number(row.gold_medals ?? 0) + Number(row.silver_medals ?? 0) + Number(row.bronze_medals ?? 0)}</span></div>)}</div><SubmitButton className="gold-button"><Save size={15}/>Lưu BXH / Save leaderboard</SubmitButton></form></section>
    <section id="data"><h2 className="section-label">Dữ liệu dùng chung / Shared data</h2>{(["contacts", "footer_links"] as const).map((entity) => <CrudSection key={entity} entity={entity} rows={rows[entity]} allRows={rows}/>)}</section>
  </div></div></main>;
}
