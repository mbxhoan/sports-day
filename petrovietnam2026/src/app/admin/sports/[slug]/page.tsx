import Link from "next/link";
import { Archive, ArrowLeft, RotateCcw, Save } from "lucide-react";
import { notFound, redirect } from "next/navigation";
import { MarkdownInput } from "@/components/markdown-input";
import { adminEntities, type AdminEntity, type AdminField } from "@/lib/admin-config";
import { relationEntity } from "@/lib/admin-relations";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getTenantId } from "@/lib/tenant";
import { saveFixtureResult, saveRecord, saveScoringRule, setArchived, uploadMedia } from "../../actions";

type Row = Record<string, unknown> & { id: string; archived_at: string | null };

function summary(row: Row) { return String(row.name_vi ?? row.title_vi ?? row.full_name ?? row.code ?? row.value ?? row.id); }
function rule(row: Row) { const value = row.scoring_rule; return value && typeof value === "object" ? value as { type?: string; win?: number; draw?: number; loss?: number } : {}; }

function Fields({ fields, row = {}, rows }: { fields: readonly AdminField[]; row?: Partial<Row>; rows: Record<AdminEntity, Row[]> }) {
  return <div className="admin-fields">{fields.map((field) => {
    const relation = relationEntity(field.name);
    const options = relation ? rows[relation].filter((item) => !item.archived_at) : [];
    return <label key={field.name}><span>{field.label}</span>{field.type === "textarea" ? <MarkdownInput name={field.name} defaultValue={String(row[field.name] ?? "")}/> : relation ? <select name={field.name} defaultValue={String(row[field.name] ?? "")}><option value="">Chọn / Select</option>{options.map((item) => <option value={item.id} key={item.id}>{summary(item)}</option>)}</select> : <input name={field.name} type={field.type ?? "text"} defaultValue={String(row[field.name] ?? "")}/>}</label>;
  })}</div>;
}

function CrudSection({ entity, rows, allRows }: { entity: AdminEntity; rows: Row[]; allRows: Record<AdminEntity, Row[]> }) {
  const config = adminEntities[entity];
  return <details className="admin-section" open><summary><span>{config.title}</span><small>{rows.length}</small></summary><div className="admin-section-body">
    <details className="record-form"><summary>＋ Thêm / Add</summary><form action={saveRecord}><input type="hidden" name="entity" value={entity}/><Fields fields={config.fields} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></form></details>
    <div className="record-list">{rows.map((row) => <details className={`record ${row.archived_at ? "archived" : ""}`} key={row.id}><summary><span>{summary(row)}</span>{row.archived_at && <em>Archived</em>}</summary><form action={saveRecord}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><Fields fields={config.fields} row={row} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></form><form action={setArchived}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="archived" value={row.archived_at ? "false" : "true"}/><button className="archive-button">{row.archived_at ? <RotateCcw size={15}/> : <Archive size={15}/>} {row.archived_at ? "Khôi phục / Restore" : "Lưu trữ / Archive"}</button></form></details>)}</div>
  </div></details>;
}

export default async function SportAdminPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();
  const tenantId = await getTenantId(supabase);
  const { data: claims } = await supabase.auth.getClaims();
  if (!claims?.claims?.sub) redirect("/login");
  const { data: admin } = await supabase.from("admin_users").select("user_id").eq("tenant_id", tenantId).eq("user_id", claims.claims.sub).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");

  const entityNames = Object.keys(adminEntities) as AdminEntity[];
  const results = await Promise.all(entityNames.map((entity) => supabase.from(entity).select("*").eq("tenant_id", tenantId).order("archived_at", { ascending: true, nullsFirst: true }).limit(2000)));
  const rows = Object.fromEntries(entityNames.map((entity, index) => [entity, (results[index].data ?? []) as Row[]])) as Record<AdminEntity, Row[]>;
  const sport = rows.sports.find((item) => item.slug === slug);
  if (!sport) notFound();
  const tournamentIds = new Set(rows.tournaments.filter((item) => item.sport_id === sport.id).map((item) => item.id));
  const entries = rows.entries.filter((item) => tournamentIds.has(String(item.tournament_id)));
  const entryIds = new Set(entries.map((item) => item.id));
  const groups = rows.groups.filter((item) => tournamentIds.has(String(item.tournament_id)));
  const groupIds = new Set(groups.map((item) => item.id));
  const fixtures = rows.fixtures.filter((item) => tournamentIds.has(String(item.tournament_id)));
  const fixtureIds = new Set(fixtures.map((item) => item.id));
  const scopedRows: Record<AdminEntity, Row[]> = {
    ...rows,
    sports: [sport],
    tournaments: rows.tournaments.filter((item) => tournamentIds.has(item.id)),
    entries,
    entry_members: rows.entry_members.filter((item) => entryIds.has(String(item.entry_id))),
    groups,
    group_entries: rows.group_entries.filter((item) => groupIds.has(String(item.group_id))),
    fixtures,
    fixture_entries: rows.fixture_entries.filter((item) => fixtureIds.has(String(item.fixture_id))),
    standings: rows.standings.filter((item) => tournamentIds.has(String(item.tournament_id))),
    awards: rows.awards.filter((item) => tournamentIds.has(String(item.tournament_id))),
    media: rows.media.filter((item) => item.sport_id === sport.id),
  };

  return <main className="admin-page"><header className="admin-header"><div><b>{summary(sport)}</b><small>Quản lý môn / Sport operations</small></div><Link href="/admin"><ArrowLeft size={16}/> Dashboard</Link></header><div className="admin-main admin-sport-main">
    <nav className="admin-sport-nav"><a href="#categories">Hạng mục</a><a href="#teams">Đội & VĐV</a><a href="#schedule">Lịch & trận</a><a href="#results">Kết quả</a><a href="#gallery">Thư viện</a></nav>
    <section className="admin-card"><h1>{summary(sport)}</h1><form action={saveRecord}><input type="hidden" name="entity" value="sports"/><input type="hidden" name="id" value={sport.id}/><Fields fields={adminEntities.sports.fields} row={sport} rows={scopedRows}/><button className="gold-button"><Save size={15}/>Lưu môn / Save sport</button></form></section>
    <section id="categories"><CrudSection entity="tournaments" rows={scopedRows.tournaments} allRows={scopedRows}/><div className="admin-card"><h2>Quy tắc tính BXH / Standings rules</h2><div className="record-list">{scopedRows.tournaments.map((tournament) => { const item = rule(tournament); return <details className="record" key={tournament.id}><summary>{summary(tournament)}</summary><form action={saveScoringRule}><input type="hidden" name="tournament_id" value={tournament.id}/><div className="admin-fields"><label><span>Loại / Type</span><select name="scoring_type" defaultValue={item.type ?? "manual"}><option value="manual">Manual / Other PDF rule</option><option value="head-to-head">Head-to-head points</option></select></label><label><span>Thắng / Win</span><input name="win_points" type="number" step="any" defaultValue={item.win ?? ""}/></label><label><span>Hòa / Draw</span><input name="draw_points" type="number" step="any" defaultValue={item.draw ?? ""}/></label><label><span>Thua / Loss</span><input name="loss_points" type="number" step="any" defaultValue={item.loss ?? ""}/></label></div><button className="gold-button"><Save size={15}/>Lưu quy tắc / Save rule</button></form></details>; })}</div></div></section>
    <section id="teams" className="admin-group"><CrudSection entity="entries" rows={scopedRows.entries} allRows={scopedRows}/><CrudSection entity="participants" rows={rows.participants} allRows={scopedRows}/><CrudSection entity="entry_members" rows={scopedRows.entry_members} allRows={scopedRows}/></section>
    <section id="schedule" className="admin-group"><CrudSection entity="venues" rows={rows.venues} allRows={scopedRows}/><CrudSection entity="courts" rows={rows.courts} allRows={scopedRows}/><CrudSection entity="groups" rows={scopedRows.groups} allRows={scopedRows}/><CrudSection entity="group_entries" rows={scopedRows.group_entries} allRows={scopedRows}/><CrudSection entity="fixtures" rows={scopedRows.fixtures} allRows={scopedRows}/><CrudSection entity="fixture_entries" rows={scopedRows.fixture_entries} allRows={scopedRows}/></section>
    <section id="results" className="admin-group"><div className="admin-card"><h2>Cập nhật kết quả / Update results</h2><div className="record-list">{scopedRows.fixtures.map((fixture) => { const current = scopedRows.fixture_entries.filter((item) => item.fixture_id === fixture.id); const home = current.find((item) => item.side === "home") ?? current[0]; const away = current.find((item) => item.side === "away") ?? current[1]; return <details className="record" key={fixture.id}><summary>{summary(fixture)}</summary><form action={saveFixtureResult}><input type="hidden" name="fixture_id" value={fixture.id}/><div className="admin-fields"><label><span>Đội 1 / Team 1</span><select name="entry_1" defaultValue={String(home?.entry_id ?? "")} required><option value="">Chọn / Select</option>{scopedRows.entries.filter((entry) => !entry.archived_at).map((entry) => <option key={entry.id} value={entry.id}>{summary(entry)}</option>)}</select></label><label><span>Tỷ số 1 / Score 1</span><input name="score_1" type="number" min="0" step="any" defaultValue={String(home?.score ?? "")}/></label><label><span>Đội 2 / Team 2</span><select name="entry_2" defaultValue={String(away?.entry_id ?? "")} required><option value="">Chọn / Select</option>{scopedRows.entries.filter((entry) => !entry.archived_at).map((entry) => <option key={entry.id} value={entry.id}>{summary(entry)}</option>)}</select></label><label><span>Tỷ số 2 / Score 2</span><input name="score_2" type="number" min="0" step="any" defaultValue={String(away?.score ?? "")}/></label><label><span>Trạng thái / Status</span><select name="status" defaultValue={String(fixture.status ?? "scheduled")}><option value="scheduled">Scheduled</option><option value="live">Live</option><option value="completed">Completed</option><option value="postponed">Postponed</option><option value="cancelled">Cancelled</option></select></label><label><span>Đội thắng (nếu khác auto) / Winner</span><select name="winner_entry_id" defaultValue={String(fixture.winner_entry_id ?? "")}><option value="">Tự tính / Auto</option>{scopedRows.entries.filter((entry) => !entry.archived_at).map((entry) => <option key={entry.id} value={entry.id}>{summary(entry)}</option>)}</select></label></div><button className="gold-button"><Save size={15}/>Lưu kết quả / Save result</button></form></details>; })}</div></div><CrudSection entity="standings" rows={scopedRows.standings} allRows={scopedRows}/><CrudSection entity="awards" rows={scopedRows.awards} allRows={scopedRows}/></section>
    <section id="gallery" className="admin-card"><h2>Thư viện ảnh / Gallery</h2><form action={uploadMedia} className="upload-form"><input type="hidden" name="sport_id" value={sport.id}/><input type="file" name="file" accept="image/png,image/jpeg,image/webp" required/><input name="title_vi" placeholder="Tiêu đề VI"/><input name="title_en" placeholder="Title EN"/><input name="alt_vi" placeholder="Alt VI"/><input name="alt_en" placeholder="Alt EN"/><input name="album_vi" placeholder="Nhóm ảnh VI"/><input name="album_en" placeholder="Album EN"/><button className="gold-button">Upload</button></form><CrudSection entity="media" rows={scopedRows.media} allRows={scopedRows}/></section>
  </div></main>;
}
