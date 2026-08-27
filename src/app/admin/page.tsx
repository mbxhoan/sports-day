import { Archive, ImagePlus, LogOut, RotateCcw, Save, Settings, Trophy } from "lucide-react";
import { redirect } from "next/navigation";
import { adminEntities, type AdminEntity, type AdminField } from "@/lib/admin-config";
import { hasSupabaseConfig, createSupabaseServerClient } from "@/lib/supabase/server";
import { MarkdownInput } from "@/components/markdown-input";
import { toVietnamLocalInput } from "@/lib/datetime";
import { logout, saveEvent, saveRecord, setArchived, uploadMedia } from "./actions";

type Row = Record<string, string | number | null> & { id: string; archived_at: string | null };

function Fields({ fields, row = {} }: { fields: readonly AdminField[]; row?: Partial<Row> }) {
  return <div className="admin-fields">{fields.map((field) => <label key={field.name}><span>{field.label}</span>{field.type === "textarea" ? <MarkdownInput name={field.name} defaultValue={String(row[field.name] ?? "")}/> : <input name={field.name} type={field.type ?? "text"} defaultValue={String(row[field.name] ?? "")}/>}</label>)}</div>;
}

function summary(row: Row) {
  return String(row.name_vi ?? row.title_vi ?? row.full_name ?? row.code ?? row.value ?? row.id);
}

function CrudSection({ entity, rows }: { entity: AdminEntity; rows: Row[] }) {
  const config = adminEntities[entity];
  return <details className="admin-section"><summary><span>{config.title}</span><small>{rows.length}</small></summary><div className="admin-section-body">
    <details className="record-form"><summary>＋ Thêm / Add</summary><form action={saveRecord}><input type="hidden" name="entity" value={entity}/><Fields fields={config.fields}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></form></details>
    <div className="record-list">{rows.map((row) => <details className={`record ${row.archived_at ? "archived" : ""}`} key={row.id}><summary><span>{summary(row)}</span>{row.archived_at && <em>Archived</em>}</summary><form action={saveRecord}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><Fields fields={config.fields} row={row}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></form><form action={setArchived}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="archived" value={row.archived_at ? "false" : "true"}/><button className="archive-button">{row.archived_at ? <RotateCcw size={15}/> : <Archive size={15}/>} {row.archived_at ? "Khôi phục / Restore" : "Lưu trữ / Archive"}</button></form></details>)}</div>
  </div></details>;
}

export default async function AdminPage() {
  if (!hasSupabaseConfig()) return <div className="admin-unavailable"><Settings/><h1>Supabase chưa cấu hình</h1><p>Copy `.env.example` thành `.env.local`, điền key từ `supabase status`, rồi chạy lại.</p></div>;
  const supabase = await createSupabaseServerClient();
  const { data: claims } = await supabase.auth.getClaims();
  const userId = claims?.claims?.sub;
  if (!userId) redirect("/login");
  const { data: admin } = await supabase.from("admin_users").select("display_name").eq("user_id", userId).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");

  const entityNames = Object.keys(adminEntities) as AdminEntity[];
  const [eventResult, ...rowResults] = await Promise.all([
    supabase.from("event_settings").select("*").eq("singleton_key", "main").single(),
    ...entityNames.map((entity) => supabase.from(entity).select("*").order("archived_at", { ascending: true, nullsFirst: true }).limit(100)),
  ]);
  const event = eventResult.data as Row;
  const rows = Object.fromEntries(entityNames.map((entity, index) => [entity, (rowResults[index].data ?? []) as Row[]])) as Record<AdminEntity, Row[]>;

  return <main className="admin-page"><header className="admin-header"><div><Trophy/><span><b>Petrovietnam 2026</b><small>Admin / Quản trị</small></span></div><form action={logout}><button><LogOut size={16}/>Đăng xuất</button></form></header><div className="admin-layout"><aside><a href="#content">Nội dung / Content</a><a href="#media">Hình ảnh / Media</a><a href="#data">Dữ liệu thi đấu / Competition</a></aside><div className="admin-main">
    <div className="admin-title"><div><h1>Dashboard</h1><p>Xin chào, {admin.display_name}</p></div><a href="/" target="_blank">Xem website ↗</a></div>
    <section id="content" className="admin-card"><h2>Nội dung sự kiện / Event content</h2><form action={saveEvent}><div className="admin-fields"><label><span>Tên sự kiện VI</span><input name="event_name_vi" defaultValue={String(event.event_name_vi ?? "")}/></label><label><span>Event name EN</span><input name="event_name_en" defaultValue={String(event.event_name_en ?? "")}/></label><label><span>Phụ đề VI</span><input name="subtitle_vi" defaultValue={String(event.subtitle_vi ?? "")}/></label><label><span>Subtitle EN</span><input name="subtitle_en" defaultValue={String(event.subtitle_en ?? "")}/></label><label><span>Giới thiệu VI</span><MarkdownInput name="about_vi" defaultValue={String(event.about_vi ?? "")}/></label><label><span>About EN</span><MarkdownInput name="about_en" defaultValue={String(event.about_en ?? "")}/></label><label><span>Địa điểm VI</span><input name="venue_vi" defaultValue={String(event.venue_vi ?? "")}/></label><label><span>Venue EN</span><input name="venue_en" defaultValue={String(event.venue_en ?? "")}/></label><label><span>Hero path</span><input name="hero_path" defaultValue={String(event.hero_path ?? "/kv.png")}/></label><label><span>Bắt đầu</span><input type="datetime-local" name="start_at" defaultValue={event.start_at ? toVietnamLocalInput(String(event.start_at)) : ""}/></label><label><span>Kết thúc</span><input type="datetime-local" name="end_at" defaultValue={event.end_at ? toVietnamLocalInput(String(event.end_at)) : ""}/></label></div><button className="gold-button"><Save size={15}/>Lưu nội dung / Save</button></form></section>
    <section id="media" className="admin-card"><h2><ImagePlus size={18}/> Upload hình ảnh / Media upload</h2><form action={uploadMedia} className="upload-form"><input type="file" name="file" accept="image/png,image/jpeg,image/webp" required/><input name="title_vi" placeholder="Tiêu đề VI"/><input name="title_en" placeholder="Title EN"/><input name="alt_vi" placeholder="Alt VI"/><input name="alt_en" placeholder="Alt EN"/><input name="filter_tag" placeholder="Filter: pickleball, bong-ban…" pattern="[a-z0-9]+(?:-[a-z0-9]+)*" defaultValue="all"/><button className="gold-button">Upload</button></form></section>
    <section id="data"><h2 className="section-label">Dữ liệu website & thi đấu / Website & competition data</h2>{entityNames.map((entity) => <CrudSection key={entity} entity={entity} rows={rows[entity]}/>)}</section>
  </div></div></main>;
}
