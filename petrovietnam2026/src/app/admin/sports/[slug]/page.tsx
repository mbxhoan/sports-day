import Link from "next/link";
import { Archive, ArrowLeft, RotateCcw, Save } from "lucide-react";
import Image from "next/image";
import { notFound, redirect } from "next/navigation";
import { MarkdownInput } from "@/components/markdown-input";
import { MediaUploadForm } from "@/components/media-upload-form";
import { adminEntities, type AdminEntity, type AdminField } from "@/lib/admin-config";
import { relationEntity } from "@/lib/admin-relations";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getTenantId } from "@/lib/tenant";
import { deleteMedia, saveFixtureResult, saveRecord, saveScoringRule, setArchived, uploadMedia } from "../../actions";

type Row = Record<string, unknown> & { id: string; archived_at: string | null };

function summary(row: Row) { return String(row.name_vi ?? row.title_vi ?? row.full_name ?? row.code ?? row.value ?? row.id); }
function resultDate(value: unknown) { return typeof value === "string" && value ? new Intl.DateTimeFormat("vi-VN", { timeZone: "Asia/Ho_Chi_Minh", dateStyle: "short", timeStyle: "short" }).format(new Date(value)) : "Chưa xếp lịch"; }
function resultTeam(row?: Row) { return row ? summary(row) : "Chưa xếp đội"; }
function rule(row: Row) { const value = row.scoring_rule; return value && typeof value === "object" ? value as { type?: string; win?: number; draw?: number; loss?: number } : {}; }
function selectColumns(entity: AdminEntity) { return [...new Set(["id", "archived_at", ...adminEntities[entity].fields.map((field) => field.name)])].join(","); }
function asRows(data: unknown) { return (data ?? []) as Row[]; }

function Fields({ fields, row = {}, rows }: { fields: readonly AdminField[]; row?: Partial<Row>; rows: Record<AdminEntity, Row[]> }) {
  return <div className="admin-fields">{fields.map((field) => {
    const relation = relationEntity(field.name);
    const options = relation ? rows[relation].filter((item) => !item.archived_at) : [];
    return <label key={field.name}><span>{field.label}</span>{field.type === "textarea" ? <MarkdownInput name={field.name} defaultValue={String(row[field.name] ?? "")}/> : relation ? <select name={field.name} defaultValue={String(row[field.name] ?? "")}><option value="">Chọn / Select</option>{options.map((item) => <option value={item.id} key={item.id}>{summary(item)}</option>)}</select> : <input name={field.name} type={field.type ?? "text"} defaultValue={String(row[field.name] ?? "")}/>}</label>;
  })}</div>;
}

function CrudSection({ entity, rows, allRows, section, editTarget }: { entity: AdminEntity; rows: Row[]; allRows: Record<AdminEntity, Row[]>; section: string; editTarget?: string }) {
  const config = adminEntities[entity];
  return <details className="admin-section" open><summary><span>{config.title}</span><small>{rows.length}</small></summary><div className="admin-section-body">
    <details className="record-form"><summary>＋ Thêm / Add</summary><form action={saveRecord}><input type="hidden" name="entity" value={entity}/><Fields fields={config.fields} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></form></details>
    <div className="record-list">{rows.map((row) => { const target = `${entity}:${row.id}`; return <details className={`record ${row.archived_at ? "archived" : ""}`} key={row.id} open={editTarget === target}><summary><a href={`?section=${section}&edit=${encodeURIComponent(target)}#${section}`}>{summary(row)}</a>{row.archived_at && <em>Archived</em>}</summary>{editTarget === target && <><form action={saveRecord}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><Fields fields={config.fields} row={row} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></form><form action={setArchived}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="archived" value={row.archived_at ? "false" : "true"}/><button className="archive-button">{row.archived_at ? <RotateCcw size={15}/> : <Archive size={15}/>} {row.archived_at ? "Khôi phục / Restore" : "Lưu trữ / Archive"}</button></form></>}</details>; })}</div>
  </div></details>;
}

function MediaGrid({ rows, allRows, editTarget, publicUrl }: { rows: Row[]; allRows: Record<AdminEntity, Row[]>; editTarget?: string; publicUrl: (path: string) => string }) {
  const config = adminEntities.media;
  return <>
    <details className="record-form"><summary>＋ Thêm / Add</summary><form action={saveRecord}><input type="hidden" name="entity" value="media"/><Fields fields={config.fields} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></form></details>
    <div className="admin-media-grid">{rows.map((row) => {
      const target = `media:${row.id}`;
      const path = String(row.storage_path ?? "");
      return <article className={`admin-media-card ${row.archived_at ? "archived" : ""}`} key={row.id}>
        <div className="admin-media-thumb">{path && <Image src={publicUrl(path)} alt={String(row.alt_vi ?? row.title_vi ?? "Gallery image")} fill sizes="(max-width: 820px) 50vw, 220px"/>}</div>
        <div className="admin-media-meta"><b>{summary(row)}</b><small>{String(row.album_vi ?? "") || "Gallery"}</small></div>
        <details className="admin-media-edit" open={editTarget === target}><summary>Chỉnh / Edit</summary><form action={saveRecord}><input type="hidden" name="entity" value="media"/><input type="hidden" name="id" value={row.id}/><Fields fields={config.fields} row={row} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></form>{!row.archived_at && <form action={deleteMedia}><input type="hidden" name="id" value={row.id}/><button className="delete-button" type="submit">Xoá ảnh / Delete image</button></form>}<form action={setArchived}><input type="hidden" name="entity" value="media"/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="archived" value={row.archived_at ? "false" : "true"}/><button className="archive-button">{row.archived_at ? <RotateCcw size={15}/> : <Archive size={15}/>} {row.archived_at ? "Khôi phục / Restore" : "Lưu trữ / Archive"}</button></form></details>
      </article>;
    })}</div>
  </>;
}

function SportNavLink({ current, section, href, children }: { current: string; section: string; href: string; children: React.ReactNode }) {
  const active = current === section;
  return <a href={href} className={active ? "active" : undefined} aria-current={active ? "page" : undefined}>{children}</a>;
}

export default async function SportAdminPage({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<{ edit?: string; section?: string }> }) {
  const { slug } = await params;
  const requested = await searchParams;
  const editTarget = requested.edit;
  const section = ["overview", "categories", "teams", "schedule", "results", "gallery"].includes(requested.section ?? "") ? requested.section! : "overview";
  const supabase = await createSupabaseServerClient();
  const tenantId = await getTenantId(supabase);
  const { data: claims } = await supabase.auth.getClaims();
  if (!claims?.claims?.sub) redirect("/login");
  const { data: admin } = await supabase.from("admin_users").select("user_id").eq("tenant_id", tenantId).eq("user_id", claims.claims.sub).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");

  const sportResult = await supabase.from("sports").select(selectColumns("sports")).eq("tenant_id", tenantId).eq("slug", slug).maybeSingle();
  const sport = sportResult.data as unknown as Row | null;
  if (sportResult.error || !sport) notFound();
  const tournamentsResult = await supabase.from("tournaments").select(selectColumns("tournaments")).eq("tenant_id", tenantId).eq("sport_id", sport.id).order("archived_at", { ascending: true, nullsFirst: true }).order("sort_order").limit(2000);
  const tournamentRows = asRows(tournamentsResult.data);
  const tournamentIds = tournamentRows.map((item) => item.id);
  const tournamentIdSet = new Set(tournamentIds);
  const all = (entity: AdminEntity) => supabase.from(entity).select(selectColumns(entity)).eq("tenant_id", tenantId).order("archived_at", { ascending: true, nullsFirst: true }).limit(2000);
  const entityNames = Object.keys(adminEntities) as AdminEntity[];
  const rows = Object.fromEntries(entityNames.map((entity) => [entity, [] as Row[]])) as Record<AdminEntity, Row[]>;
  rows.sports = [sport];
  rows.tournaments = tournamentRows;
  if (section === "teams") {
    const [entriesResult, organizationsResult, entryMembersResult, participantsResult] = await Promise.all([
      all("entries"),
      all("organizations"),
      all("entry_members"),
      all("participants"),
    ]);
    rows.entries = asRows(entriesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.organizations = asRows(organizationsResult.data);
    const entryIds = new Set(rows.entries.map((item) => item.id));
    rows.entry_members = asRows(entryMembersResult.data).filter((item) => entryIds.has(String(item.entry_id)));
    const participantIds = new Set(rows.entry_members.map((item) => String(item.participant_id)));
    rows.participants = asRows(participantsResult.data).filter((item) => participantIds.has(item.id));
  } else if (section === "schedule") {
    const [groupsResult, fixturesResult, groupEntriesResult, fixtureEntriesResult, venuesResult, courtsResult] = await Promise.all([
      all("groups"),
      all("fixtures"),
      all("group_entries"),
      all("fixture_entries"),
      all("venues"),
      all("courts"),
    ]);
    rows.groups = asRows(groupsResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.fixtures = asRows(fixturesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.venues = asRows(venuesResult.data);
    rows.courts = asRows(courtsResult.data);
    const groupIds = new Set(rows.groups.map((item) => item.id));
    const fixtureIds = new Set(rows.fixtures.map((item) => item.id));
    rows.group_entries = asRows(groupEntriesResult.data).filter((item) => groupIds.has(String(item.group_id)));
    rows.fixture_entries = asRows(fixtureEntriesResult.data).filter((item) => fixtureIds.has(String(item.fixture_id)));
  } else if (section === "results") {
    const [entriesResult, fixturesResult, fixtureEntriesResult, standingsResult, awardsResult] = await Promise.all([
      all("entries"),
      all("fixtures"),
      all("fixture_entries"),
      all("standings"),
      all("awards"),
    ]);
    rows.entries = asRows(entriesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.fixtures = asRows(fixturesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    const fixtureIds = new Set(rows.fixtures.map((item) => item.id));
    rows.fixture_entries = asRows(fixtureEntriesResult.data).filter((item) => fixtureIds.has(String(item.fixture_id)));
    rows.standings = asRows(standingsResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.awards = asRows(awardsResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
  } else if (section === "gallery") {
    rows.media = asRows((await supabase.from("media").select(selectColumns("media")).eq("tenant_id", tenantId).eq("sport_id", sport.id).eq("kind", "gallery").is("archived_at", null).order("sort_order").limit(2000)).data);
  }
  const entries = rows.entries.filter((item) => tournamentIdSet.has(String(item.tournament_id)));
  const entryIds = new Set(entries.map((item) => item.id));
  const entryMembers = rows.entry_members.filter((item) => entryIds.has(String(item.entry_id)));
  const participantIds = new Set(entryMembers.map((item) => String(item.participant_id)));
  const groups = rows.groups.filter((item) => tournamentIdSet.has(String(item.tournament_id)));
  const groupIds = new Set(groups.map((item) => item.id));
  const fixtures = rows.fixtures.filter((item) => tournamentIdSet.has(String(item.tournament_id)));
  const fixtureIds = new Set(fixtures.map((item) => item.id));
  const scopedRows: Record<AdminEntity, Row[]> = {
    ...rows,
    sports: [sport],
    tournaments: rows.tournaments.filter((item) => tournamentIdSet.has(item.id)),
    entries,
    entry_members: entryMembers,
    participants: rows.participants.filter((item) => participantIds.has(item.id)),
    groups,
    group_entries: rows.group_entries.filter((item) => groupIds.has(String(item.group_id))),
    fixtures,
    fixture_entries: rows.fixture_entries.filter((item) => fixtureIds.has(String(item.fixture_id))),
    standings: rows.standings.filter((item) => tournamentIdSet.has(String(item.tournament_id))),
    awards: rows.awards.filter((item) => tournamentIdSet.has(String(item.tournament_id))),
    media: rows.media.filter((item) => item.sport_id === sport.id),
  };

  return <main className="admin-page"><header className="admin-header"><div><b>{summary(sport)}</b><small>Quản lý môn / Sport operations</small></div><Link href="/admin"><ArrowLeft size={16}/> Dashboard</Link></header><div className="admin-main admin-sport-main">
    <div className="admin-sport-workspace">
      <nav className="admin-sport-nav" aria-label="Sport sections"><b>{summary(sport)}</b><small>Danh mục dữ liệu</small><SportNavLink current={section} section="overview" href="?section=overview#overview">Thông tin môn</SportNavLink><SportNavLink current={section} section="categories" href="?section=categories#categories">Hạng mục <small>{scopedRows.tournaments.length}</small></SportNavLink><SportNavLink current={section} section="teams" href="?section=teams#teams">Đội & VĐV {section === "teams" && <small>{scopedRows.entries.length + scopedRows.participants.length}</small>}</SportNavLink><SportNavLink current={section} section="schedule" href="?section=schedule#schedule">Lịch & trận {section === "schedule" && <small>{scopedRows.fixtures.length}</small>}</SportNavLink><SportNavLink current={section} section="results" href="?section=results#results">Kết quả</SportNavLink><SportNavLink current={section} section="gallery" href="?section=gallery#gallery">Thư viện {section === "gallery" && <small>{scopedRows.media.length}</small>}</SportNavLink></nav>
      <div className="admin-sport-panels">
        <section id="overview" className="admin-card"><h1>{summary(sport)}</h1><form action={saveRecord}><input type="hidden" name="entity" value="sports"/><input type="hidden" name="id" value={sport.id}/><Fields fields={adminEntities.sports.fields} row={sport} rows={scopedRows}/><button className="gold-button"><Save size={15}/>Lưu môn / Save sport</button></form></section>
        <section id="categories"><CrudSection entity="tournaments" rows={scopedRows.tournaments} allRows={scopedRows} section="categories" editTarget={editTarget}/><div className="admin-card"><h2>Quy tắc tính BXH / Standings rules</h2><div className="record-list">{scopedRows.tournaments.map((tournament) => { const item = rule(tournament); return <details className="record" key={tournament.id}><summary>{summary(tournament)}</summary><form action={saveScoringRule}><input type="hidden" name="tournament_id" value={tournament.id}/><div className="admin-fields"><label><span>Loại / Type</span><select name="scoring_type" defaultValue={item.type ?? "manual"}><option value="manual">Manual / Other PDF rule</option><option value="head-to-head">Head-to-head points</option></select></label><label><span>Thắng / Win</span><input name="win_points" type="number" step="any" defaultValue={item.win ?? ""}/></label><label><span>Hòa / Draw</span><input name="draw_points" type="number" step="any" defaultValue={item.draw ?? ""}/></label><label><span>Thua / Loss</span><input name="loss_points" type="number" step="any" defaultValue={item.loss ?? ""}/></label></div><button className="gold-button"><Save size={15}/>Lưu quy tắc / Save rule</button></form></details>; })}</div></div></section>
        <section id="teams" className="admin-group"><CrudSection entity="entries" rows={scopedRows.entries} allRows={scopedRows} section="teams" editTarget={editTarget}/><CrudSection entity="participants" rows={scopedRows.participants} allRows={scopedRows} section="teams" editTarget={editTarget}/><CrudSection entity="entry_members" rows={scopedRows.entry_members} allRows={scopedRows} section="teams" editTarget={editTarget}/></section>
        <section id="schedule" className="admin-group"><CrudSection entity="venues" rows={rows.venues} allRows={scopedRows} section="schedule" editTarget={editTarget}/><CrudSection entity="courts" rows={rows.courts} allRows={scopedRows} section="schedule" editTarget={editTarget}/><CrudSection entity="groups" rows={scopedRows.groups} allRows={scopedRows} section="schedule" editTarget={editTarget}/><CrudSection entity="group_entries" rows={scopedRows.group_entries} allRows={scopedRows} section="schedule" editTarget={editTarget}/><CrudSection entity="fixtures" rows={scopedRows.fixtures} allRows={scopedRows} section="schedule" editTarget={editTarget}/><CrudSection entity="fixture_entries" rows={scopedRows.fixture_entries} allRows={scopedRows} section="schedule" editTarget={editTarget}/></section>
        <section id="results" className="admin-group"><div className="admin-card"><h2>Cập nhật kết quả / Update results</h2><p className="results-help">Bấm vào từng trận để nhập đội, tỷ số và trạng thái. / Click a match to enter teams, score and status.</p><div className="record-list">{scopedRows.fixtures.map((fixture) => { const current = scopedRows.fixture_entries.filter((item) => item.fixture_id === fixture.id); const home = current.find((item) => item.side === "home") ?? current[0]; const away = current.find((item) => item.side === "away") ?? current[1]; const tournament = scopedRows.tournaments.find((item) => item.id === fixture.tournament_id); const target = `fixture-result:${fixture.id}`; return <details className="record result-match" key={fixture.id} open={editTarget === target}><summary className="result-match-summary"><div><b>{resultTeam(scopedRows.entries.find((entry) => entry.id === home?.entry_id))} <span>vs</span> {resultTeam(scopedRows.entries.find((entry) => entry.id === away?.entry_id))}</b><small>{tournament ? summary(tournament) : "Chưa có hạng mục"} · {String(fixture.round_vi ?? "Chưa có vòng")}</small></div><div><time>{resultDate(fixture.starts_at)}</time><strong>{String(home?.score ?? "—")} : {String(away?.score ?? "—")}</strong></div></summary><form action={saveFixtureResult}><input type="hidden" name="fixture_id" value={fixture.id}/><div className="admin-fields"><label><span>Đội 1 / Team 1</span><select name="entry_1" defaultValue={String(home?.entry_id ?? "")} required><option value="">Chọn / Select</option>{scopedRows.entries.filter((entry) => !entry.archived_at).map((entry) => <option key={entry.id} value={entry.id}>{summary(entry)}</option>)}</select></label><label><span>Tỷ số 1 / Score 1</span><input name="score_1" type="number" min="0" step="any" defaultValue={String(home?.score ?? "")}/></label><label><span>Đội 2 / Team 2</span><select name="entry_2" defaultValue={String(away?.entry_id ?? "")} required><option value="">Chọn / Select</option>{scopedRows.entries.filter((entry) => !entry.archived_at).map((entry) => <option key={entry.id} value={entry.id}>{summary(entry)}</option>)}</select></label><label><span>Tỷ số 2 / Score 2</span><input name="score_2" type="number" min="0" step="any" defaultValue={String(away?.score ?? "")}/></label><label><span>Trạng thái / Status</span><select name="status" defaultValue={String(fixture.status ?? "scheduled")}><option value="scheduled">Scheduled</option><option value="live">Live</option><option value="completed">Completed</option><option value="postponed">Postponed</option><option value="cancelled">Cancelled</option></select></label><label><span>Đội thắng (nếu khác auto) / Winner</span><select name="winner_entry_id" defaultValue={String(fixture.winner_entry_id ?? "")}><option value="">Tự tính / Auto</option>{scopedRows.entries.filter((entry) => !entry.archived_at).map((entry) => <option key={entry.id} value={entry.id}>{summary(entry)}</option>)}</select></label></div><button className="gold-button"><Save size={15}/>Lưu kết quả / Save result</button></form></details>; })}</div></div><CrudSection entity="standings" rows={scopedRows.standings} allRows={scopedRows} section="results" editTarget={editTarget}/><CrudSection entity="awards" rows={scopedRows.awards} allRows={scopedRows} section="results" editTarget={editTarget}/></section>
        <section id="gallery" className="admin-card"><h2>Thư viện ảnh / Gallery</h2><p className="upload-help">Chọn nhiều ảnh cùng lúc. PNG, JPEG, WebP; tối đa 10MB mỗi ảnh.</p><MediaUploadForm action={uploadMedia} sportId={sport.id} multiple albumFields/><MediaGrid rows={scopedRows.media} allRows={scopedRows} editTarget={editTarget} publicUrl={(path) => supabase.storage.from("event-media").getPublicUrl(path).data.publicUrl}/></section>
      </div>
    </div>
  </div></main>;
}
