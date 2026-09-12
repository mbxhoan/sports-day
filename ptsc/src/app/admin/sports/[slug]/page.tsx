import Link from "next/link";
import { Archive, ArrowLeft, RotateCcw, Save, Trash2 } from "lucide-react";
import Image from "next/image";
import { notFound, redirect } from "next/navigation";
import { ConfirmedMediaDeleteForm } from "@/components/confirmed-media-delete-form";
import { CompetitionBoard } from "@/components/competition-board";
import { AdminSearch } from "@/components/admin-search";
import { AdminRosterWorkspace } from "@/components/admin-roster-workspace";
import { MarkdownInput } from "@/components/markdown-input";
import { AdminRecordForm } from "@/components/admin-record-form";
import { standingDifference } from "@/lib/competition-display";
import { adminEntities, type AdminEntity, type AdminField } from "@/lib/admin-config";
import { isManualSport } from "@/lib/manual-competition";
import { relationEntity } from "@/lib/admin-relations";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getTenantId } from "@/lib/tenant";
import { withTimeout } from "@/lib/auth-timeout";
import { buildSearchSuggestions } from "@/lib/search";
import { formatVietnamDateTime } from "@/lib/datetime";
import type { Entry, Fixture, FixtureEntry, FixtureSlot, Group, GroupEntry, Standing, Tournament } from "@/lib/site";
import { applySportExcelImport, confirmFixtureReset, confirmGroupStandings, deleteMedia, prepareSportExcelImport, previewFixtureReset, rollbackSportExcelImport, saveFixtureResult, saveFixtureSlot, saveManualStandings, saveRaceResult, saveRecordAction, saveRosterRecord, saveScoringRule, setArchived, uploadSportIcon } from "../../actions";

export const dynamic = "force-dynamic";

type Row = Record<string, unknown> & { id: string; archived_at: string | null };
type ExcelImport = { id: string; status: string; mode: string; file_sha256: string; created_at: string; applied_at: string | null; rolled_back_at: string | null; preview: { blockers?: unknown[]; warnings?: unknown[]; diff?: unknown[]; operation_count?: number } | null };

function readable(value: unknown) {
  const text = String(value ?? "").trim();
  return text && !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(text) ? text : "";
}
function summary(row: Row, entity?: AdminEntity, rows?: Record<AdminEntity, Row[]>): string {
  const related = (field: string, relation: AdminEntity): string => {
    const id = String(row[field] ?? "");
    const item = rows?.[relation].find((candidate) => candidate.id === id);
    return item ? summary(item, relation, rows) : "";
  };
  if (entity === "fixtures") {
    const label: string = [readable(row.source_code), readable(row.round_vi), related("group_id", "groups"), related("tournament_id", "tournaments")].filter(Boolean).join(" · ");
    return label || "Trận đấu chưa đặt tên";
  }
  if (entity === "group_entries") {
    const label: string = [related("group_id", "groups"), related("entry_id", "entries")].filter(Boolean).join(" · ");
    return label || "Đội chưa xếp vào bảng";
  }
  if (entity === "fixture_entries") {
    const side = row.side === "home" ? "Bên 1" : row.side === "away" ? "Bên 2" : readable(row.side);
    const label: string = [related("fixture_id", "fixtures"), related("entry_id", "entries"), side].filter(Boolean).join(" · ");
    return label || "Đối thủ chưa gán trận";
  }
  const label = [row.name_vi, row.title_vi, row.full_name, row.code, row.value, row.source_code, row.round_vi].map(readable).find(Boolean) ?? "";
  return label || `${entity === "entries" ? "Đội / VĐV" : entity === "groups" ? "Bảng đấu" : entity === "tournaments" ? "Hạng mục" : "Bản ghi"} chưa đặt tên`;
}
function rule(row: Row) { const value = row.scoring_rule; return value && typeof value === "object" ? value as { type?: string; win?: number; draw?: number; loss?: number } : {}; }
function selectColumns(entity: AdminEntity) { const extra: Partial<Record<AdminEntity, string[]>> = { tournaments: ["competition_mode", "source_metadata", "scoring_rule"], groups: ["standings_confirmed_at"], fixtures: ["source_code"], fixture_entries: ["result_status"] }; return [...new Set(["id", "archived_at", ...adminEntities[entity].fields.map((field) => field.name), ...(extra[entity] ?? [])])].join(","); }
function asRows(data: unknown) { return (data ?? []) as Row[]; }

function previewItems(value: unknown) { return Array.isArray(value) ? value.map(String) : []; }
function ExcelAdmin({ slug, imports, selected, error }: { slug: string; imports: ExcelImport[]; selected?: ExcelImport; error?: string }) {
  const resultSheet = ["co-vua", "co-tuong"].includes(slug) ? "BXH" : "KẾT_QUẢ";
  const blockers = previewItems(selected?.preview?.blockers);
  const warnings = previewItems(selected?.preview?.warnings);
  const diff = Array.isArray(selected?.preview?.diff) ? selected.preview.diff as Array<{ table?: string; ref?: string; action?: string }> : [];
  return <section id="excel" className="admin-group"><div className="admin-card"><h2>Cập nhật kết quả bằng Excel</h2><p className="upload-help">Mỗi môn có một file riêng. Tải file, sửa điểm trong sheet {resultSheet} bằng tên người/đội có sẵn, đổi trạng thái trận nếu cần, rồi nạp lại.</p><p className="results-help">Không cần sửa ID hoặc cột ẩn. File có xem trước; chỉ khi không có lỗi thì dữ liệu mới được ghi.</p><div className="admin-actions"><a className="gold-button" href={`/admin/sports/${encodeURIComponent(slug)}/excel?mode=current&view=results`}>Tải file cập nhật kết quả</a></div><details className="record-form"><summary>Excel nâng cao: sửa toàn bộ dữ liệu</summary><div className="admin-actions"><a className="gold-button" href={`/admin/sports/${encodeURIComponent(slug)}/excel?mode=current`}>Xuất dữ liệu hiện tại</a><a className="gold-button" href={`/admin/sports/${encodeURIComponent(slug)}/excel?mode=blank`}>Xuất template trống</a></div></details><form action={prepareSportExcelImport} className="record-form"><input type="hidden" name="sport_slug" value={slug}/><label><span>Nạp workbook .xlsx</span><input name="file" type="file" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" required/></label><button className="gold-button"><Save size={15}/>Xem trước import</button></form>{error && <p className="results-error" role="alert">{error}</p>}</div>
    {selected && <div className="admin-card"><h3>Preview import · {selected.id}</h3><p className="results-help">Trạng thái: {selected.status} · {selected.preview?.operation_count ?? 0} thay đổi · SHA-256: {selected.file_sha256}</p>{diff.length > 0 && <details className="record-form"><summary>Chi tiết thay đổi ({diff.length})</summary><ul>{diff.slice(0, 200).map((item, index) => <li key={`${item.ref ?? "row"}-${index}`}>{item.action} · {item.table} · {item.ref}</li>)}</ul>{diff.length > 200 && <p className="results-help">Chỉ hiển thị 200 dòng đầu.</p>}</details>}{blockers.length > 0 && <div className="reset-warning" role="alert"><b>Lỗi chặn</b><ul>{blockers.map((item, index) => <li key={`${item}-${index}`}>{item}</li>)}</ul></div>}{warnings.length > 0 && <div className="reset-warning"><b>Cảnh báo cần xác nhận</b><ul>{warnings.map((item, index) => <li key={`${item}-${index}`}>{item}</li>)}</ul></div>}{selected.status === "prepared" && blockers.length === 0 && <form action={applySportExcelImport}><input type="hidden" name="sport_slug" value={slug}/><input type="hidden" name="import_id" value={selected.id}/>{warnings.length > 0 && <label><input type="checkbox" name="confirm" value="yes" required/> Tôi đã kiểm tra và xác nhận cảnh báo.</label>}<button className="gold-button"><Save size={15}/>Áp dụng toàn bộ import</button></form>}{selected.status === "applied" && <form action={rollbackSportExcelImport}><input type="hidden" name="sport_slug" value={slug}/><input type="hidden" name="import_id" value={selected.id}/><button className="archive-button"><RotateCcw size={15}/>Rollback import này</button><p className="results-help">Rollback chỉ chạy nếu dữ liệu chưa bị thay đổi sau import.</p></form>}</div>}
    <div className="admin-card"><h3>Lịch sử import</h3><div className="record-list">{imports.length ? imports.map((item) => <div className="record" key={item.id}><a href={`?section=excel&import=${encodeURIComponent(item.id)}#excel`}><b>{item.mode}</b> · {item.status} · {formatVietnamDateTime(item.created_at, "vi")}</a></div>) : <p className="results-help">Chưa có workbook import.</p>}</div></div>
  </section>;
}

function Fields({ fields, row = {}, rows }: { fields: readonly AdminField[]; row?: Partial<Row>; rows: Record<AdminEntity, Row[]> }) {
  return <div className="admin-fields">{fields.map((field) => {
    const relation = relationEntity(field.name);
    const options = relation ? rows[relation].filter((item) => !item.archived_at) : [];
    return <label key={field.name}><span>{field.label}</span>{field.type === "textarea" ? <MarkdownInput name={field.name} defaultValue={String(row[field.name] ?? "")}/> : relation || field.options ? <select name={field.name} defaultValue={String(row[field.name] ?? "")} required={field.required}><option value="">Chọn / Select</option>{relation ? options.map((item) => <option value={item.id} key={item.id}>{summary(item, relation, rows)}</option>) : field.options?.map((option) => <option value={option.value} key={option.value}>{option.label}</option>)}</select> : <input name={field.name} type={field.type ?? "text"} defaultValue={String(row[field.name] ?? "")} required={field.required}/>}</label>;
  })}</div>;
}

function CrudSection({ entity, rows, allRows, section, editTarget, sportSlug }: { entity: AdminEntity; rows: Row[]; allRows: Record<AdminEntity, Row[]>; section: string; editTarget?: string; sportSlug: string }) {
  const config = adminEntities[entity];
  const removable = entity === "entries" || entity === "participants";
  const defaultRow = entity === "tournaments" ? { sport_id: allRows.sports[0]?.id ?? "", gender: "mixed", sort_order: 0 } : {};
  return <details className="admin-section" open={Boolean(editTarget)}><summary><span>{config.title}</span><small>{rows.length}</small></summary><div className="admin-section-body">
    <details className="record-form"><summary>＋ Thêm / Add</summary><AdminRecordForm action={saveRecordAction}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="sport_slug" value={sportSlug}/><Fields fields={config.fields} row={defaultRow} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></AdminRecordForm></details>
    <div className="record-list">{rows.map((row) => { const target = `${entity}:${row.id}`; const actionLabel = row.archived_at ? "Khôi phục / Restore" : removable ? "Xoá khỏi giải" : "Lưu trữ / Archive"; return <details className={`record ${row.archived_at ? "archived" : ""}`} key={row.id} open={editTarget === target}><summary><a href={`?section=${section}&edit=${encodeURIComponent(target)}#${section}`}>{summary(row, entity, allRows)}</a>{row.archived_at && <em>Archived</em>}</summary>{editTarget === target && <><AdminRecordForm action={saveRecordAction}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="sport_slug" value={sportSlug}/><Fields fields={config.fields} row={row} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></AdminRecordForm><form action={setArchived}><input type="hidden" name="entity" value={entity}/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="archived" value={row.archived_at ? "false" : "true"}/><button className="archive-button">{row.archived_at ? <RotateCcw size={15}/> : removable ? <Trash2 size={15}/> : <Archive size={15}/>} {actionLabel}</button>{removable && !row.archived_at && <small className="results-help">Ẩn khỏi website, có thể khôi phục.</small>}</form></>}</details>; })}</div>
  </div></details>;
}

function MediaGrid({ rows, allRows, editTarget, publicUrl }: { rows: Row[]; allRows: Record<AdminEntity, Row[]>; editTarget?: string; publicUrl: (path: string) => string }) {
  const config = adminEntities.media;
  return <><ConfirmedMediaDeleteForm action={deleteMedia}/><div className="admin-media-grid">{rows.map((row) => {
    const target = `media:${row.id}`;
    const path = String(row.storage_path ?? "");
    return <article className={`admin-media-card ${row.archived_at ? "archived" : ""}`} key={row.id}><div className="admin-media-thumb">{!row.archived_at && <><input className="media-select" type="checkbox" form="media-delete" name="id" value={row.id} aria-label={`Chọn ${summary(row)} để xoá`}/><button className="media-trash-button" type="submit" form="media-delete" name="single_id" value={row.id} aria-label={`Xoá ${summary(row)}`} title="Xoá vĩnh viễn"><Trash2 size={15}/></button></>}{path && <Image src={publicUrl(path)} alt={String(row.alt_vi ?? row.title_vi ?? "Gallery image")} fill sizes="(max-width: 820px) 50vw, 220px"/>}</div><div className="admin-media-meta"><b>{summary(row)}</b><small>{String(row.album_vi ?? "") || "Legacy media"}</small></div><details className="admin-media-edit" open={editTarget === target}><summary>Chỉnh / Edit</summary><AdminRecordForm action={saveRecordAction}><input type="hidden" name="entity" value="media"/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="sport_slug" value={String(allRows.sports[0]?.slug ?? "")}/><Fields fields={config.fields} row={row} rows={allRows}/><button className="gold-button"><Save size={15}/>Lưu / Save</button></AdminRecordForm><form action={setArchived}><input type="hidden" name="entity" value="media"/><input type="hidden" name="id" value={row.id}/><input type="hidden" name="archived" value={row.archived_at ? "false" : "true"}/><button className="archive-button">{row.archived_at ? <RotateCcw size={15}/> : <Archive size={15}/>} {row.archived_at ? "Khôi phục / Restore" : "Lưu trữ / Archive"}</button></form></details></article>;
  })}</div></>;
}

function ManualStandingsEditor({ tournament, entries, standings, groupId }: { tournament: Row; entries: Row[]; standings: Row[]; groupId?: string }) {
  const key = groupId ?? "";
  const race = tournament.competition_mode === "race";
  const byEntry = new Map(standings.filter((row) => String(row.group_id ?? "") === key).map((row) => [String(row.entry_id), row]));
  return <section className="admin-card manual-standings-editor"><h3>{summary(tournament)}</h3><p className="results-help">{race ? "Nhập Trận, Thắng, Hòa, Thua, Ghi/Thua và Thành tích; Trận phải bằng Thắng + Hòa + Thua." : "Nhập các chỉ số khi không có bracket; Điểm tự tính theo rule nếu hạng mục có rule."}</p><form action={saveManualStandings}><input type="hidden" name="tournament_id" value={String(tournament.id)}/>{groupId && <input type="hidden" name="group_id" value={groupId}/>}<input type="hidden" name="manual_mode" value={race ? "race" : "standings"}/><div className="manual-standings-list">{entries.filter((entry) => !entry.archived_at).map((entry) => { const row = byEntry.get(String(entry.id)); const difference = standingDifference({ score_for: Number(row?.score_for ?? 0), score_against: Number(row?.score_against ?? 0) }); return <div className="manual-standings-row" key={entry.id}><input type="hidden" name="entry_id" value={String(entry.id)}/><b>{summary(entry)}</b>{race ? <label>Hạng<input name="rank" type="number" min="1" defaultValue={String(row?.rank ?? "")}/></label> : <label>Hạng<output className="auto-rank-cell">{String(row?.rank ?? "Tự động")}</output></label>}<label>Trận<input name="played" type="number" min="0" defaultValue={String(row?.played ?? 0)}/></label><label>Thắng<input name="won" type="number" min="0" defaultValue={String(row?.won ?? 0)}/></label><label>Hòa<input name="drawn" type="number" min="0" defaultValue={String(row?.drawn ?? 0)}/></label><label>Thua<input name="lost" type="number" min="0" defaultValue={String(row?.lost ?? 0)}/></label><label>Điểm ghi<input name="score_for" type="number" min="0" step="any" defaultValue={String(row?.score_for ?? 0)}/></label><label>Điểm thua<input name="score_against" type="number" min="0" step="any" defaultValue={String(row?.score_against ?? 0)}/></label><label>Điểm<input name="points" type="number" min="0" step="any" defaultValue={String(row?.points ?? 0)}/></label><output>+/- {difference}</output>{race ? <><label>Làn<input name="lane" type="number" min="1" defaultValue={String(row?.lane ?? "")}/></label><label>Thành tích<input name="score" defaultValue={String(row?.score ?? "")}/></label><label>Trạng thái<input name="result_status" defaultValue={String(row?.result_status ?? "")}/></label></> : null}</div>; })}</div><button className="gold-button"><Save size={15}/>{race ? "Lưu kết quả / Save results" : "Lưu bảng / Save standings"}</button></form>{groupId && <form action={confirmGroupStandings} className="confirm-standings"><input type="hidden" name="group_id" value={groupId}/><button className="gold-button">Xác nhận bảng / Confirm group</button></form>}</section>;
}

function RaceResultsEditor({ tournament, fixture, entries, fixtureEntries }: { tournament: Row; fixture: Row; entries: Row[]; fixtureEntries: Row[] }) {
  const entriesById = new Map(entries.map((entry) => [String(entry.id), entry]));
  const round = readable(fixture.round_vi) || readable(fixture.round_en) || "Lượt thi";
  return <section className="admin-card manual-standings-editor"><h3>{summary(tournament)} · {round}</h3><p className="results-help">Nhập hạng, làn, thành tích và trạng thái cho lượt này.</p><form action={saveRaceResult}><input type="hidden" name="fixture_id" value={String(fixture.id)}/><div className="race-result-list">{fixtureEntries.map((row) => { const entry = entriesById.get(String(row.entry_id)); if (!entry) return null; return <div key={row.id}><input type="hidden" name="entry_id" value={String(row.entry_id)}/><b>{summary(entry)}</b><label>Hạng<input name="rank" type="number" min="1" defaultValue={String(row.rank ?? "")}/></label><label>Làn<input name="lane" type="number" min="1" defaultValue={String(row.lane ?? "")}/></label><label>Thành tích<input name="score" defaultValue={String(row.score ?? row.score_numeric ?? "")}/></label><label>Trạng thái<select name="result_status" defaultValue={String(row.result_status ?? "")}><option value="">Đang cập nhật</option><option value="finished">Hoàn thành</option><option value="dns">DNS</option><option value="dnf">DNF</option><option value="dsq">DSQ</option></select></label></div>; })}</div><button className="gold-button"><Save size={15}/>Lưu kết quả / Save results</button></form></section>;
}

function SportNavLink({ current, section, href, children }: { current: string; section: string; href: string; children: React.ReactNode }) { const active = current === section; return <a href={href} className={active ? "active" : undefined} aria-current={active ? "page" : undefined}>{children}</a>; }

export default async function SportAdminPage({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<{ edit?: string; section?: string; tournament?: string; reset?: string; affected?: string; import?: string; error?: string }> }) {
  const { slug } = await params;
  const requested = await searchParams;
  const editTarget = requested.edit;
  const resetTarget = requested.reset;
  const resetAffected = Number(requested.affected ?? 0);
  const section = ["overview", "categories", "teams", "schedule", "results", "gallery", "excel"].includes(requested.section ?? "") ? requested.section! : "overview";
  const supabase = await createSupabaseServerClient();
  const tenantId = await getTenantId(supabase);
  let claims;
  try { ({ data: claims } = await withTimeout(() => supabase.auth.getClaims())); } catch { redirect("/login?error=session"); }
  if (!claims?.claims?.sub) redirect("/login");
  const { data: admin } = await supabase.from("admin_users").select("user_id").eq("tenant_id", tenantId).eq("user_id", claims.claims.sub).maybeSingle();
  if (!admin) redirect("/login?error=forbidden");

  const sportResult = await supabase.from("sports").select(selectColumns("sports")).eq("tenant_id", tenantId).eq("slug", slug).maybeSingle();
  const sport = sportResult.data as unknown as Row | null;
  if (sportResult.error || !sport) notFound();
  const manual = isManualSport(String(sport.slug));
  const tournamentsResult = await supabase.from("tournaments").select(selectColumns("tournaments")).eq("tenant_id", tenantId).eq("sport_id", sport.id).order("archived_at", { ascending: true, nullsFirst: true }).order("sort_order").limit(2000);
  const tournamentRows = asRows(tournamentsResult.data);
  const selectedTournamentId = tournamentRows.some((item) => item.id === requested.tournament) ? requested.tournament : "";
  const tournamentIds = tournamentRows.filter((item) => !selectedTournamentId || item.id === selectedTournamentId).map((item) => item.id);
  const tournamentIdSet = new Set(tournamentIds);
  const all = (entity: AdminEntity) => supabase.from(entity).select(selectColumns(entity)).eq("tenant_id", tenantId).order("archived_at", { ascending: true, nullsFirst: true }).limit(2000);
  const scoped = (entity: AdminEntity, column: string, ids: string[]) => { const query = all(entity); return ids.length ? query.in(column, ids) : query.limit(0); };
  const entityNames = Object.keys(adminEntities) as AdminEntity[];
  const rows = Object.fromEntries(entityNames.map((entity) => [entity, [] as Row[]])) as Record<AdminEntity, Row[]>;
  let resultsLoadError = false;
  let fixtureSlots: Row[] = [];
  let excelImports: ExcelImport[] = [];
  let selectedExcelImport: ExcelImport | undefined;
  rows.sports = [sport];
  rows.tournaments = tournamentRows.filter((item) => tournamentIds.includes(item.id));
  if (section === "teams") {
    const [entriesResult, organizationsResult, entryMembersResult, participantsResult] = await Promise.all([all("entries"), all("organizations"), all("entry_members"), all("participants")]);
    rows.entries = asRows(entriesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.organizations = asRows(organizationsResult.data);
    const entryIds = new Set(rows.entries.map((item) => item.id));
    rows.entry_members = asRows(entryMembersResult.data).filter((item) => entryIds.has(String(item.entry_id)));
    rows.participants = asRows(participantsResult.data);
  } else if (section === "schedule") {
    const [groupsResult, fixturesResult, groupEntriesResult, fixtureEntriesResult, venuesResult, courtsResult, entriesResult] = await Promise.all([all("groups"), all("fixtures"), all("group_entries"), all("fixture_entries"), all("venues"), all("courts"), all("entries")]);
    rows.groups = asRows(groupsResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.fixtures = asRows(fixturesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.entries = asRows(entriesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)));
    rows.venues = asRows(venuesResult.data);
    rows.courts = asRows(courtsResult.data);
    const groupIds = new Set(rows.groups.map((item) => item.id));
    const fixtureIds = new Set(rows.fixtures.map((item) => item.id));
    rows.group_entries = asRows(groupEntriesResult.data).filter((item) => groupIds.has(String(item.group_id)));
    rows.fixture_entries = asRows(fixtureEntriesResult.data).filter((item) => fixtureIds.has(String(item.fixture_id)));
  } else if (section === "results") {
    try {
      const [entriesResult, fixturesResult, standingsResult, awardsResult, groupsResult, entryMembersResult, participantsResult] = await withTimeout(() => Promise.all([scoped("entries", "tournament_id", tournamentIds), scoped("fixtures", "tournament_id", tournamentIds), scoped("standings", "tournament_id", tournamentIds), scoped("awards", "tournament_id", tournamentIds), scoped("groups", "tournament_id", tournamentIds), all("entry_members"), all("participants")]), 10_000);
      if ([entriesResult, fixturesResult, standingsResult, awardsResult, groupsResult, entryMembersResult, participantsResult].some((result) => result.error)) throw new Error("Results query failed");
      rows.entries = asRows(entriesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)) && !item.archived_at);
      rows.fixtures = asRows(fixturesResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)) && !item.archived_at);
      rows.standings = asRows(standingsResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)) && !item.archived_at);
      rows.awards = asRows(awardsResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)) && !item.archived_at);
      rows.groups = asRows(groupsResult.data).filter((item) => tournamentIdSet.has(String(item.tournament_id)) && !item.archived_at);
      const resultEntryIds = new Set(rows.entries.map((item) => item.id));
      rows.entry_members = asRows(entryMembersResult.data).filter((item) => resultEntryIds.has(String(item.entry_id)));
      const resultParticipantIds = new Set(rows.entry_members.map((item) => String(item.participant_id)));
      rows.participants = asRows(participantsResult.data).filter((item) => resultParticipantIds.has(item.id));
      const fixtureIds = rows.fixtures.map((item) => item.id);
      const fixtureIdSet = new Set(fixtureIds);
      const groupIds = rows.groups.map((item) => item.id);
      const groupIdSet = new Set(groupIds);
      const fixtureSlotsQuery = supabase.from("fixture_slots").select("id,fixture_id,side,source_kind,source_entry_id,source_group_id,source_fixture_id,source_rank,label_vi,label_en,archived_at").eq("tenant_id", tenantId).is("archived_at", null);
      const activeFixtureEntriesQuery = supabase.from("fixture_entries").select("id,fixture_id,entry_id,side,lane,seed_order,score,score_numeric,rank,result_status,result_detail,archived_at").eq("tenant_id", tenantId).is("archived_at", null).order("seed_order");
      if (fixtureIds.length) activeFixtureEntriesQuery.in("fixture_id", fixtureIds);
      else activeFixtureEntriesQuery.limit(0);
      const [fixtureEntriesResult, groupEntriesResult, fixtureSlotsResult] = await withTimeout(() => Promise.all([activeFixtureEntriesQuery, all("group_entries"), fixtureSlotsQuery]), 10_000);
      if ([fixtureEntriesResult, groupEntriesResult, fixtureSlotsResult].some((result) => result.error)) throw new Error("Results query failed");
      rows.fixture_entries = asRows(fixtureEntriesResult.data).filter((item) => fixtureIdSet.has(String(item.fixture_id)));
      const tournamentByFixture = new Map(rows.fixtures.map((fixture) => [fixture.id, fixture.tournament_id]));
      rows.standings = [...rows.standings, ...rows.fixture_entries.map((row) => ({ ...row, tournament_id: tournamentByFixture.get(String(row.fixture_id)), group_id: null, points: 0 }))];
      rows.group_entries = asRows(groupEntriesResult.data).filter((item) => !item.archived_at && resultEntryIds.has(String(item.entry_id)) && groupIdSet.has(String(item.group_id)));
      fixtureSlots = asRows(fixtureSlotsResult.data).filter((item) => fixtureIdSet.has(String(item.fixture_id)));
    } catch { resultsLoadError = true; }
  } else if (section === "gallery") {
    rows.media = asRows((await supabase.from("media").select(selectColumns("media")).eq("tenant_id", tenantId).eq("sport_id", sport.id).eq("kind", "gallery").is("archived_at", null).order("sort_order").limit(2000)).data);
  } else if (section === "excel") {
    const { data: importRows } = await supabase.from("sport_excel_imports").select("id,status,mode,file_sha256,created_at,applied_at,rolled_back_at,preview").eq("tenant_id", tenantId).eq("sport_id", sport.id).order("created_at", { ascending: false }).limit(30);
    excelImports = (importRows ?? []) as ExcelImport[];
    selectedExcelImport = excelImports.find((item) => item.id === requested.import);
  }
  const entries = rows.entries.filter((item) => tournamentIdSet.has(String(item.tournament_id)));
  const entryIds = new Set(entries.map((item) => item.id));
  const entryMembers = rows.entry_members.filter((item) => entryIds.has(String(item.entry_id)));
  const participantIds = new Set(entryMembers.map((item) => String(item.participant_id)));
  const groups = rows.groups.filter((item) => tournamentIdSet.has(String(item.tournament_id)));
  const groupIds = new Set(groups.map((item) => item.id));
  const fixtures = rows.fixtures.filter((item) => tournamentIdSet.has(String(item.tournament_id)));
  const fixtureIds = new Set(fixtures.map((item) => item.id));
  const scopedRows: Record<AdminEntity, Row[]> = { ...rows, sports: [sport], tournaments: rows.tournaments.filter((item) => tournamentIdSet.has(item.id)), entries, entry_members: entryMembers, participants: section === "teams" ? rows.participants : rows.participants.filter((item) => participantIds.has(item.id)), groups, group_entries: rows.group_entries.filter((item) => groupIds.has(String(item.group_id))), fixtures, fixture_entries: rows.fixture_entries.filter((item) => fixtureIds.has(String(item.fixture_id))), standings: rows.standings.filter((item) => tournamentIdSet.has(String(item.tournament_id))), awards: rows.awards.filter((item) => tournamentIdSet.has(String(item.tournament_id))), media: rows.media.filter((item) => item.sport_id === sport.id) };
  fixtureSlots = fixtureSlots.filter((item) => fixtureIds.has(String(item.fixture_id)));
  const fixtureEntriesByFixture = new Map<string, Row[]>();
  for (const row of scopedRows.fixture_entries) fixtureEntriesByFixture.set(String(row.fixture_id), [...(fixtureEntriesByFixture.get(String(row.fixture_id)) ?? []), row]);
  const boardProps = { locale: "vi" as const, tournaments: scopedRows.tournaments as unknown as Tournament[], entries: scopedRows.entries as unknown as Entry[], groups: scopedRows.groups as unknown as Group[], groupEntries: scopedRows.group_entries as unknown as GroupEntry[], fixtures: scopedRows.fixtures as unknown as Fixture[], fixtureEntries: scopedRows.fixture_entries as unknown as FixtureEntry[], fixtureSlots: fixtureSlots as unknown as FixtureSlot[], standings: scopedRows.standings as unknown as Standing[], standingsAction: saveManualStandings };
  const entriesById = new Map(scopedRows.entries.map((entry) => [entry.id, entry]));
  const searchSuggestions = buildSearchSuggestions({
    tournaments: scopedRows.tournaments.map((tournament) => ({ id: tournament.id, name: summary(tournament, "tournaments", scopedRows), detail: "Hạng mục" })),
    participants: scopedRows.participants.map((participant) => ({ id: participant.id, full_name: String(participant.full_name ?? "") })),
    entries: scopedRows.entries.map((entry) => ({ id: entry.id, name: summary(entry, "entries", scopedRows), tournament: summary(scopedRows.tournaments.find((tournament) => tournament.id === entry.tournament_id) ?? { id: String(entry.tournament_id), archived_at: null }, "tournaments", scopedRows) })),
    fixtures: scopedRows.fixtures.map((fixture) => ({ id: fixture.id, label: summary(fixture, "fixtures", scopedRows), detail: `${summary(scopedRows.tournaments.find((tournament) => tournament.id === fixture.tournament_id) ?? { id: String(fixture.tournament_id), archived_at: null }, "tournaments", scopedRows)} · ${scopedRows.fixture_entries.filter((item) => item.fixture_id === fixture.id).map((item) => summary(entriesById.get(String(item.entry_id)) ?? { id: String(item.entry_id), archived_at: null }, "entries", scopedRows)).join(" vs ")}` })),
  });
  return <main className="admin-page"><header className="admin-header"><div><b>{summary(sport)}</b><small>Quản lý môn / Sport operations</small></div><Link href="/admin"><ArrowLeft size={16}/> Dashboard</Link></header><div className="admin-main admin-sport-main"><div className="admin-sport-workspace">
    <nav className="admin-sport-nav" aria-label="Sport sections"><b>{summary(sport)}</b><small>Danh mục dữ liệu</small><SportNavLink current={section} section="overview" href="?section=overview#overview">Thông tin môn</SportNavLink><SportNavLink current={section} section="categories" href="?section=categories#categories">Hạng mục <small>{scopedRows.tournaments.length}</small></SportNavLink><SportNavLink current={section} section="teams" href="?section=teams#teams">Đội & VĐV {section === "teams" && <small>{scopedRows.entries.length + scopedRows.participants.length}</small>}</SportNavLink><SportNavLink current={section} section="schedule" href="?section=schedule#schedule">Bảng & trận {section === "schedule" && <small>{scopedRows.fixtures.length}</small>}</SportNavLink><SportNavLink current={section} section="results" href="?section=results#results">Kết quả</SportNavLink><SportNavLink current={section} section="gallery" href="?section=gallery#gallery">Thư viện {section === "gallery" && <small>{scopedRows.media.length}</small>}</SportNavLink><SportNavLink current={section} section="excel" href="?section=excel#excel">Excel admin {section === "excel" && <small>{excelImports.length}</small>}</SportNavLink></nav>
    <div className="admin-sport-panels"><section id="overview" className="admin-card"><div className="sport-admin-hero"><div><span className="admin-kicker">THÔNG TIN MÔN</span><h1>{summary(sport)}</h1><p>Cập nhật tên, mô tả, thể lệ và hình ảnh đại diện. Các thay đổi này chỉ áp dụng cho môn đang chọn.</p></div><div className="sport-logo-editor"><div className="sport-logo-preview">{String(sport.emoji ?? "").startsWith("http") || String(sport.emoji ?? "").startsWith("/") ? <Image src={String(sport.emoji)} alt={`Logo ${summary(sport)}`} fill sizes="72px"/> : <span>{String(sport.emoji ?? "") || "—"}</span>}</div><form action={uploadSportIcon}><input type="hidden" name="sport_id" value={sport.id}/><label><span>Logo môn thể thao</span><input name="file" type="file" accept="image/png,image/jpeg,image/webp" required/></label><button className="gold-button"><Save size={15}/>Đổi logo</button></form></div></div><AdminRecordForm action={saveRecordAction}><input type="hidden" name="entity" value="sports"/><input type="hidden" name="id" value={sport.id}/><input type="hidden" name="sport_slug" value={slug}/><Fields fields={adminEntities.sports.fields} row={sport} rows={scopedRows}/><button className="gold-button"><Save size={15}/>Lưu thông tin môn</button></AdminRecordForm></section>
      {searchSuggestions.length > 0 && <div className="admin-card admin-search-card"><AdminSearch slug={slug} suggestions={searchSuggestions}/><p className="results-help">Chọn gợi ý để mở nhanh hạng mục, đội, VĐV hoặc trận đấu cần cập nhật.</p></div>}
      <section id="categories"><CrudSection entity="tournaments" rows={scopedRows.tournaments} allRows={scopedRows} section="categories" editTarget={editTarget} sportSlug={slug}/><div className="admin-card"><h2>Quy tắc tính BXH / Standings rules</h2><p className="results-help">Môn đối kháng dùng bracket: nhập tỷ số trên bracket, BXH tự tính Trận/Thắng/Hòa/Thua/Ghi/Thua/+/-/Điểm theo rule. Chỉ để Manual khi điều lệ không tính được từ từng trận.</p><div className="record-list">{scopedRows.tournaments.map((tournament) => { const item = rule(tournament); return <details className="record" key={tournament.id}><summary>{summary(tournament)}</summary><form action={saveScoringRule}><input type="hidden" name="tournament_id" value={tournament.id}/><div className="admin-fields"><label><span>Loại / Type</span><select name="scoring_type" defaultValue={item.type ?? "manual"}><option value="manual">Manual / Other PDF rule</option><option value="head-to-head">Head-to-head points</option></select></label><label><span>Thắng / Win</span><input name="win_points" type="number" step="any" defaultValue={item.win ?? ""}/></label><label><span>Hòa / Draw</span><input name="draw_points" type="number" step="any" defaultValue={item.draw ?? ""}/></label><label><span>Thua / Loss</span><input name="loss_points" type="number" step="any" defaultValue={item.loss ?? ""}/></label></div><button className="gold-button"><Save size={15}/>Lưu quy tắc / Save rule</button></form></details>; })}</div></div></section>
      <section id="teams" className="admin-group"><AdminRosterWorkspace entries={scopedRows.entries} participants={scopedRows.participants} organizations={scopedRows.organizations} tournaments={scopedRows.tournaments} members={scopedRows.entry_members} sportSlug={slug} saveRosterRecord={saveRosterRecord} setArchived={setArchived}/></section>
      <section id="schedule" className="admin-group"><CrudSection entity="venues" rows={rows.venues} allRows={scopedRows} section="schedule" editTarget={editTarget} sportSlug={slug}/><CrudSection entity="courts" rows={rows.courts} allRows={scopedRows} section="schedule" editTarget={editTarget} sportSlug={slug}/><CrudSection entity="groups" rows={scopedRows.groups} allRows={scopedRows} section="schedule" editTarget={editTarget} sportSlug={slug}/><CrudSection entity="group_entries" rows={scopedRows.group_entries} allRows={scopedRows} section="schedule" editTarget={editTarget} sportSlug={slug}/><CrudSection entity="fixtures" rows={scopedRows.fixtures} allRows={scopedRows} section="schedule" editTarget={editTarget} sportSlug={slug}/><CrudSection entity="fixture_entries" rows={scopedRows.fixture_entries} allRows={scopedRows} section="schedule" editTarget={editTarget} sportSlug={slug}/></section>
      <section id="results" className="admin-group">{resetTarget && <div className="admin-card reset-warning"><h2>⚠ Mở lại vòng sau</h2><p>Thao tác sẽ xoá tỷ số, thứ hạng và người thắng của {resetAffected} trận phụ thuộc. Không thể hoàn tác tự động.</p><form action={confirmFixtureReset}><input type="hidden" name="fixture_id" value={resetTarget}/><label><input type="checkbox" name="confirm" value="yes" required/> Tôi xác nhận đặt lại dữ liệu vòng sau.</label><button className="archive-button">Xác nhận reset</button></form></div>}
        {resultsLoadError ? <p className="results-error" role="alert">Không tải được dữ liệu kết quả. Vui lòng tải lại trang.</p> : !manual && <div className="admin-card admin-board-card"><h2>Bảng đấu theo nguồn</h2><p className="results-help">Chọn trực tiếp một trận trên nhánh để nhập kết quả.</p><CompetitionBoard {...boardProps} resultAction={saveFixtureResult} slotAction={saveFixtureSlot} previewAction={previewFixtureReset} sportSlug={slug}/></div>}
        {manual && <div className="manual-standings-stack">{scopedRows.tournaments.map((tournament) => { const tournamentEntries = scopedRows.entries.filter((entry) => entry.tournament_id === tournament.id); if (tournament.competition_mode !== "race") return <ManualStandingsEditor key={tournament.id} tournament={tournament} entries={tournamentEntries} standings={scopedRows.standings.filter((row) => row.tournament_id === tournament.id)}/>; const fixturesForTournament = scopedRows.fixtures.filter((fixture) => fixture.tournament_id === tournament.id && !fixture.archived_at); const sourceFixtures = fixturesForTournament.filter((fixture) => String(fixture.source_code ?? "").startsWith(String(tournament.slug ?? "").toUpperCase())).sort((a, b) => String(a.source_code ?? "").localeCompare(String(b.source_code ?? ""))); const resultFixtures = sourceFixtures.length ? sourceFixtures : fixturesForTournament; const sections = resultFixtures.map((fixture) => ({ fixture, fixtureEntries: fixtureEntriesByFixture.get(String(fixture.id)) ?? [] })).filter((section) => section.fixtureEntries.length); return sections.length ? sections.map(({ fixture, fixtureEntries }) => { const entryIds = new Set(fixtureEntries.map((row) => String(row.entry_id))); return <RaceResultsEditor key={fixture.id} tournament={tournament} fixture={fixture} entries={tournamentEntries.filter((entry) => entryIds.has(String(entry.id)))} fixtureEntries={fixtureEntries}/>; }) : <ManualStandingsEditor key={tournament.id} tournament={tournament} entries={tournamentEntries} standings={scopedRows.standings.filter((row) => row.tournament_id === tournament.id)}/>; })}</div>}
      {!manual && <CrudSection entity="awards" rows={scopedRows.awards} allRows={scopedRows} section="results" editTarget={editTarget} sportSlug={slug}/>}</section>
      <section id="gallery" className="admin-card"><h2>Media cũ / Legacy media</h2><p className="upload-help">Gallery public dùng Google Drive. Media/storage cũ giữ nguyên, không upload mới.</p><MediaGrid rows={scopedRows.media} allRows={scopedRows} editTarget={editTarget} publicUrl={(path) => supabase.storage.from("event-media").getPublicUrl(path).data.publicUrl}/></section>
      <ExcelAdmin slug={slug} imports={excelImports} selected={selectedExcelImport} error={requested.error}/>
    </div></div></div></main>;
}
