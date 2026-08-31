"use client";

import Link from "next/link";
import { useActionState, useEffect, useRef, useState } from "react";
import { layoutBracket, slotLabel } from "@/lib/brackets";
import { initialAdminActionState, type AdminActionState } from "@/lib/admin-action";
import { standingDifference } from "@/lib/competition-display";
import { buildSearchSuggestions } from "@/lib/search";
import { copy, localized, type Entry, type Fixture, type FixtureEntry, type FixtureSlot, type Group, type GroupEntry, type Locale, type Standing, type Tournament } from "@/lib/site";
import { SearchCombobox } from "./search-combobox";

type AdminAction = (previousState: AdminActionState, formData: FormData) => Promise<AdminActionState>;
type PreviewAction = (formData: FormData) => void | Promise<void>;

type Props = {
  locale: Locale;
  tournaments: Tournament[];
  entries: Entry[];
  groups: Group[];
  groupEntries: GroupEntry[];
  fixtures: Fixture[];
  fixtureEntries: FixtureEntry[];
  fixtureSlots: FixtureSlot[];
  standings: Standing[];
  adminHref?: string;
  resultAction?: AdminAction;
  slotAction?: AdminAction;
  previewAction?: PreviewAction;
  sportSlug?: string;
};

type BracketLayout = ReturnType<typeof layoutBracket>;

const noopAction: AdminAction = async () => initialAdminActionState;

function ZoomableBracket({ layout, children, locale }: { layout: BracketLayout; children: React.ReactNode; locale: Locale }) {
  const viewportRef = useRef<HTMLDivElement>(null);
  const [zoom, setZoom] = useState(1);
  const fit = () => setZoom(Math.min(1, Math.max(0.25, ((viewportRef.current?.clientWidth ?? window.innerWidth) - 16) / layout.width)));
  useEffect(() => {
    const update = () => setZoom(Math.min(1, Math.max(0.25, ((viewportRef.current?.clientWidth ?? window.innerWidth) - 16) / layout.width)));
    const frame = window.requestAnimationFrame(update);
    window.addEventListener("resize", update);
    return () => { window.cancelAnimationFrame(frame); window.removeEventListener("resize", update); };
  }, [layout.width]);
  return <section className="bracket-canvas" aria-label={locale === "vi" ? "Nhánh đấu có thể phóng to" : "Zoomable bracket canvas"}>
    <div className="bracket-canvas-toolbar"><span>{locale === "vi" ? "Nhánh đấu" : "Bracket"}</span><div><button type="button" onClick={() => setZoom((value) => Math.max(0.25, Number((value - 0.1).toFixed(2))))} aria-label={locale === "vi" ? "Thu nhỏ" : "Zoom out"}>−</button><button type="button" onClick={fit} aria-label={locale === "vi" ? "Vừa khung" : "Fit to view"}>{Math.round(zoom * 100)}%</button><button type="button" onClick={() => setZoom((value) => Math.min(1.5, Number((value + 0.1).toFixed(2))))} aria-label={locale === "vi" ? "Phóng to" : "Zoom in"}>＋</button></div></div>
    <div className="bracket-canvas-viewport" ref={viewportRef}><div className="bracket-canvas-stage" style={{ width: layout.width * zoom, height: layout.height * zoom }}><div className="source-bracket" style={{ width: layout.width, height: layout.height, transform: `scale(${zoom})` }}>{children}</div></div></div>
  </section>;
}

function sourceNote(tournament: Tournament, locale: Locale) {
  const source = tournament.source_metadata ?? {};
  if (!source.file) return null;
  const page = source.page_or_sheet ? ` · ${locale === "vi" ? "trang" : "page"} ${source.page_or_sheet}` : "";
  return <small className="board-source">{source.file.split("/").at(-1)}{page}</small>;
}

function SlotEditor({ slot, fixture, entries, groups, groupEntries, fixtures, action }: { slot: FixtureSlot; fixture: Fixture; entries: Entry[]; groups: Group[]; groupEntries: GroupEntry[]; fixtures: Fixture[]; action: AdminAction }) {
  const [state, formAction, pending] = useActionState(action, initialAdminActionState);
  const [sourceKind, setSourceKind] = useState(slot.source_kind);
  const [entryId, setEntryId] = useState(slot.source_entry_id ?? "");
  const [groupId, setGroupId] = useState(slot.source_group_id ?? "");
  const [query, setQuery] = useState(entries.find((entry) => entry.id === slot.source_entry_id)?.name_vi ?? "");
  const tournamentEntries = entries.filter((entry) => entry.tournament_id === fixture.tournament_id);
  const groupEntryIds = new Set(groupEntries.filter((item) => item.group_id === fixture.group_id).map((item) => item.entry_id));
  const entryCandidates = fixture.group_id ? tournamentEntries.filter((entry) => groupEntryIds.has(entry.id)) : tournamentEntries;
  const suggestions = buildSearchSuggestions({ participants: [], entries: entryCandidates.map((entry) => ({ id: entry.id, name: entry.name_vi })), fixtures: [] });
  const sourceFixtures = fixtures.filter((item) => item.tournament_id === fixture.tournament_id && item.id !== fixture.id);
  const sourceGroups = groups.filter((group) => group.tournament_id === fixture.tournament_id);
  const selectedGroup = sourceGroups.find((group) => group.id === groupId);
  const selectedMembers = selectedGroup ? groupEntries.filter((item) => item.group_id === selectedGroup.id).map((item) => tournamentEntries.find((entry) => entry.id === item.entry_id)?.name_vi).filter(Boolean) : [];
  return <form className="slot-source-form" action={formAction}>
    <input type="hidden" name="slot_id" value={slot.id}/>
    <b>{slot.side === "home" ? "Ô trên" : "Ô dưới"}</b>
    <label><span>Nguồn</span><select name="source_kind" value={sourceKind} onChange={(event) => setSourceKind(event.target.value as FixtureSlot["source_kind"])}><option value="entry">Đội/cặp/cá nhân</option><option value="group_rank">Thứ hạng bảng</option><option value="fixture_winner">Thắng trận</option><option value="fixture_loser">Thua trận</option><option value="bye">Bye</option></select></label>
    {sourceKind === "entry" && <><SearchCombobox label="Tìm đội/cặp" placeholder="Nhập tên đội hoặc cặp..." suggestions={suggestions} value={query} onChange={(value) => { setQuery(value); setEntryId(""); }} onSelect={(suggestion) => { setQuery(suggestion.label); setEntryId(suggestion.id); }}/><input type="hidden" name="source_entry_id" value={entryId}/></>}
    {sourceKind === "group_rank" && <><label><span>Bảng nguồn</span><select name="source_group_id" value={groupId} onChange={(event) => setGroupId(event.target.value)}><option value="">Chọn bảng</option>{sourceGroups.map((group) => <option key={group.id} value={group.id}>{group.name_vi}</option>)}</select></label><label><span>Hạng</span><input name="source_rank" type="number" min="1" defaultValue={slot.source_rank ?? ""}/></label>{selectedMembers.length > 0 && <small className="slot-candidates">Thành viên: {selectedMembers.join(" · ")}</small>}</>}
    {(["fixture_winner", "fixture_loser"] as const).includes(sourceKind as "fixture_winner" | "fixture_loser") && <label><span>Trận nguồn</span><select name="source_fixture_id" defaultValue={slot.source_fixture_id ?? ""}><option value="">Chọn trận</option>{sourceFixtures.map((item) => <option key={item.id} value={item.id}>{(item.source_code ?? item.round_vi) || item.id}</option>)}</select></label>}
    {sourceKind === "bye" && <p className="slot-candidates">Ô trống, tự resolve theo cấu trúc nhánh.</p>}
    <label><span>Nhãn VI</span><input name="label_vi" defaultValue={slot.label_vi}/></label><label><span>Label EN</span><input name="label_en" defaultValue={slot.label_en}/></label>
    {!state.ok && <p className="form-error" role="alert">{state.message}</p>}
    <button className="gold-button" disabled={pending}>{pending ? "Đang lưu..." : "Lưu cấu trúc"}</button>
  </form>;
}

export function CompetitionBoard({ locale, tournaments, entries, groups, groupEntries, fixtures, fixtureEntries, fixtureSlots, standings, adminHref, resultAction, slotAction, previewAction, sportSlug }: Props) {
  const t = copy[locale];
  const entriesById = new Map(entries.map((entry) => [entry.id, entry]));
  const fixturesById = new Map(fixtures.map((fixture) => [fixture.id, fixture]));
  const fixturesByTournament = Map.groupBy(fixtures, (fixture) => fixture.tournament_id);
  const entriesByTournament = Map.groupBy(entries, (entry) => entry.tournament_id);
  const groupsByTournament = Map.groupBy(groups, (group) => group.tournament_id);
  const groupEntriesByGroup = Map.groupBy(groupEntries, (item) => item.group_id);
  const standingsByGroup = Map.groupBy(standings, (row) => row.group_id ?? `tournament:${row.tournament_id}`);
  const fixtureRows = Map.groupBy(fixtureEntries, (row) => row.fixture_id);
  const fixtureSlotsById = Map.groupBy(fixtureSlots, (slot) => slot.fixture_id);
  const [editingFixture, setEditingFixture] = useState<Fixture | null>(null);
  const [submittedFixtureId, setSubmittedFixtureId] = useState<string | null>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [resultState, resultFormAction, resultPending] = useActionState(resultAction ?? noopAction, initialAdminActionState);
  useEffect(() => {
    if (editingFixture && !dialogRef.current?.open) dialogRef.current?.showModal();
    if (!editingFixture && dialogRef.current?.open) dialogRef.current.close();
    if (editingFixture && submittedFixtureId === editingFixture.id && resultState.ok && resultState.message) dialogRef.current?.close();
  }, [editingFixture, resultState, submittedFixtureId]);
  const sourceCodes = Map.groupBy(fixtures.filter((fixture) => fixture.source_code), (fixture) => `${fixture.tournament_id}:${fixture.source_code}`);
  const available = tournaments.filter((tournament) => (fixturesByTournament.get(tournament.id)?.length ?? 0) > 0 || (groupsByTournament.get(tournament.id)?.length ?? 0) > 0 || (entriesByTournament.get(tournament.id)?.length ?? 0) > 0);

  const matchLabel = (fixture: Fixture) => {
    if (!fixture.source_code) return localized(fixture, "round", locale) || t.updating;
    const sameCode = sourceCodes.get(`${fixture.tournament_id}:${fixture.source_code}`) ?? [];
    const occurrence = sameCode.findIndex((item) => item.id === fixture.id) + 1;
    return `${locale === "vi" ? "Trận" : "Match"} ${fixture.source_code}${sameCode.length > 1 ? ` (${occurrence})` : ""}`;
  };
  const entryName = (id: string | null | undefined) => id ? localized(entriesById.get(id) ?? {}, "name", locale) : "";
  const matchRows = (fixture: Fixture) => {
    const rows = fixtureRows.get(fixture.id) ?? [];
    const slots = fixtureSlotsById.get(fixture.id) ?? [];
    return (["home", "away"] as const).map((side, index) => {
      const row = rows.find((item) => item.side === side) ?? rows[index];
      const slot = slots.find((item) => item.side === side);
      const entry = row ? entriesById.get(row.entry_id) : slot?.source_entry_id ? entriesById.get(slot.source_entry_id) : undefined;
      return { row, entry, label: slot ? slotLabel(slot, entry, locale) : entry ? localized(entry, "name", locale) : t.teamsNotAssigned };
    });
  };
  const editingRows = editingFixture ? matchRows(editingFixture) : [];
  const editingHome = editingRows[0]?.row;
  const editingAway = editingRows[1]?.row;
  const editingSlots = editingFixture ? fixtureSlotsById.get(editingFixture.id) ?? [] : [];
  const closeDialog = () => { setSubmittedFixtureId(null); setEditingFixture(null); };
  const tournamentHasResults = (tournamentId: string) => (fixturesByTournament.get(tournamentId) ?? []).some((fixture) => ["live", "completed"].includes(fixture.status) || fixture.winner_entry_id || (fixtureRows.get(fixture.id) ?? []).some((row) => row.score !== null || row.score_numeric !== null || row.rank !== null || row.result_status !== null));

  const table = (tournament: Tournament, tournamentGroups: Group[]) => {
    const groupTables = tournamentGroups.length ? tournamentGroups : [{ id: "", tournament_id: tournament.id, name_vi: "Bảng xếp hạng", name_en: "Standings", sort_order: 0 }];
    return <div className="group-grid">{groupTables.map((group) => {
      const seeded = group.id ? (groupEntriesByGroup.get(group.id) ?? []).map((item) => item.entry_id) : (entriesByTournament.get(tournament.id) ?? []).map((item) => item.id);
      const standingRows = [...(standingsByGroup.get(group.id || `tournament:${tournament.id}`) ?? [])].sort((a, b) => (a.rank ?? 999999) - (b.rank ?? 999999));
      const ids = [...new Set([...standingRows.map((row) => row.entry_id), ...seeded])];
      return <div className="panel table-scroll" key={group.id || tournament.id}><h3 className="table-title">{localized(group, "name", locale)}</h3><table><thead><tr><th>{t.rank}</th><th>{t.teams}</th><th>{t.played}</th><th>{t.wins}</th><th>{t.draws}</th><th>{t.losses}</th><th>+/-</th><th>{t.points}</th></tr></thead><tbody>{ids.map((id) => { const row = standingRows.find((item) => item.entry_id === id); const stats = row ?? { played: 0, won: 0, drawn: 0, lost: 0, score_for: 0, score_against: 0, points: 0 }; return <tr key={id}><td>{row?.rank ?? "—"}</td><td>{entryName(id)}</td><td>{stats.played}</td><td>{stats.won}</td><td>{stats.drawn}</td><td>{stats.lost}</td><td>{standingDifference(stats)}</td><td><b>{stats.points}</b></td></tr>; })}</tbody></table></div>;
    })}</div>;
  };

  const manualTable = (tournament: Tournament) => {
    const tournamentEntries = entriesByTournament.get(tournament.id) ?? [];
    const standingRows = standingsByGroup.get(`tournament:${tournament.id}`) ?? [];
    const standingsByEntry = new Map(standingRows.map((row) => [row.entry_id, row]));
    const raceRows = (fixturesByTournament.get(tournament.id) ?? []).flatMap((fixture) => fixtureRows.get(fixture.id) ?? []);
    const raceByEntry = new Map(raceRows.map((row) => [row.entry_id, row]));
    const ids = [...new Set([...standingRows.map((row) => row.entry_id), ...tournamentEntries.map((entry) => entry.id)])];
    const raceMode = tournament.competition_mode === "race";
    return <div className="panel table-scroll manual-results"><table><thead><tr><th>{t.rank}</th><th>{t.athlete}</th><th>{t.played}</th><th>{t.wins}</th><th>{t.draws}</th><th>{t.losses}</th><th>+/-</th><th>{t.points}</th>{raceMode && <><th>{t.lane}</th><th>{t.performance}</th><th>{t.status}</th></>}</tr></thead><tbody>{ids.map((id) => { const standing = standingsByEntry.get(id); const race = raceByEntry.get(id); const stats = standing ?? { played: 0, won: 0, drawn: 0, lost: 0, score_for: 0, score_against: 0, points: 0 }; return <tr key={id}><td>{standing?.rank ?? race?.rank ?? "—"}</td><td>{entryName(id)}</td><td>{stats.played}</td><td>{stats.won}</td><td>{stats.drawn}</td><td>{stats.lost}</td><td>{standingDifference(stats)}</td><td><b>{stats.points}</b></td>{raceMode && <><td>{race?.lane ?? "—"}</td><td>{race?.score ?? "—"}</td><td>{race?.result_status?.toUpperCase() ?? t.updating}</td></>}</tr>; })}</tbody></table></div>;
  };

  const matchesTable = (items: Fixture[]) => <div className="panel table-scroll board-matches"><table><thead><tr><th>{t.match}</th><th>{t.round}</th><th>{t.teams}</th><th>{t.result}</th></tr></thead><tbody>{items.map((fixture) => { const rows = matchRows(fixture); return <tr key={fixture.id}><td>{matchLabel(fixture)}</td><td>{localized(fixture, "round", locale) || t.updating}</td><td>{rows.map((row) => row.label).join(" — ")}</td><td>{rows.map((row) => row.row?.score ?? "—").join(" : ")}</td></tr>; })}</tbody></table></div>;

  if (!available.length) return <section className="panel empty-state"><h2>{t.empty}</h2></section>;
  return <div className="competition-board"><div className="tournament-stack">{available.map((tournament) => {
    const tournamentFixtures = fixturesByTournament.get(tournament.id) ?? [];
    const tournamentGroups = groupsByTournament.get(tournament.id) ?? [];
    const knockout = tournamentFixtures.filter((fixture) => fixture.round_order !== null && fixture.bracket_position !== null);
    const warnings = tournament.source_metadata?.warnings ?? [];
    const isBracket = tournament.competition_mode === "knockout" || tournament.competition_mode === "group_knockout";
    return <section className="tournament-block" id={`tournament-${tournament.id}`} key={tournament.id} style={{ contentVisibility: "auto", containIntrinsicSize: "0 560px" }}>
      <header className="board-heading"><div><h2>{localized(tournament, "name", locale)}</h2>{sourceNote(tournament, locale)}</div><span>{localized(tournament, "format", locale)}</span></header>
      {warnings.map((warning) => <p className="board-warning" key={warning}>⚠ {warning}</p>)}
      {isBracket && knockout.length > 0 && (() => {
        const slots = fixtureSlots.filter((slot) => fixturesById.get(slot.fixture_id)?.tournament_id === tournament.id);
        const layout = layoutBracket(knockout, slots);
        return <ZoomableBracket key={`${tournament.id}-${layout.width}`} locale={locale} layout={layout}><svg viewBox={`0 0 ${layout.width} ${layout.height}`} aria-hidden="true">{layout.connectors.map((connector) => <path key={`${connector.sourceId}-${connector.targetId}`} d={connector.path}/>)}</svg>{layout.nodes.map((node) => { const fixture = fixturesById.get(node.id)!; const rows = matchRows(fixture); const card = <article className="bracket-match source-bracket-match"><small>{[matchLabel(fixture), localized(fixture, "round", locale)].filter(Boolean).join(" · ") || t.updating}</small><div className="bracket-teams">{rows.map(({ row, entry, label }, index) => <div className={`bracket-team${entry?.id === fixture.winner_entry_id ? " winner" : ""}`} key={row?.id ?? index}><span>{label}</span><b>{row?.score ?? "—"}</b></div>)}</div></article>;
          const editButton = resultAction ? <button type="button" className="bracket-edit-button" onClick={() => { setSubmittedFixtureId(null); setEditingFixture(fixture); }}>Sửa kết quả</button> : null;
          return <div className="source-bracket-node" style={{ left: node.x, top: node.y }} key={node.id}>{resultAction ? <>{card}{editButton}</> : adminHref ? <Link href={`${adminHref}&edit=fixture-result:${fixture.id}#fixture-${fixture.id}`}>{card}</Link> : card}</div>;
        })}</ZoomableBracket>;
      })()}
      {tournament.competition_mode === "group_knockout" && table(tournament, tournamentGroups)}
      {tournament.competition_mode === "round_robin" && <>{table(tournament, tournamentGroups)}{matchesTable(tournamentFixtures)}</>}
      {(tournament.competition_mode === "race" || tournament.competition_mode === "swiss") && manualTable(tournament)}
      {!tournamentFixtures.length && !tournamentGroups.length && !entriesByTournament.get(tournament.id)?.length && <div className="panel board-empty">{t.empty}</div>}
    </section>;
  })}</div>{resultAction && <dialog ref={dialogRef} className="result-dialog" onClick={(event) => { if (event.target === event.currentTarget) closeDialog(); }} onClose={closeDialog}>
    <header><div><h2>Sửa kết quả trận đấu</h2><p>{editingFixture ? `${matchLabel(editingFixture)} · ${localized(editingFixture, "round", locale) || t.updating}` : ""}</p></div><button type="button" className="dialog-close" onClick={closeDialog} aria-label="Đóng">×</button></header>
    {editingFixture && <div className="result-dialog-body">
      <section className="dialog-source-section"><h3>Cấu trúc nguồn nhánh</h3>{editingSlots.length ? editingSlots.map((slot) => slotAction && !tournamentHasResults(editingFixture.tournament_id) ? <SlotEditor key={slot.id} slot={slot} fixture={editingFixture} entries={entries} groups={groups} groupEntries={groupEntries} fixtures={fixtures} action={slotAction}/> : <div className="slot-readonly" key={slot.id}><b>{slot.side === "home" ? "Ô trên" : "Ô dưới"}</b><span>{slotLabel(slot, slot.source_entry_id ? entriesById.get(slot.source_entry_id) : undefined, locale)}</span></div>) : <p className="slot-candidates">Chưa cấu hình nguồn nhánh.</p>}</section>
      <section className="dialog-result-section"><h3>Nhập kết quả</h3><form key={editingFixture.id} action={resultFormAction} onSubmit={() => setSubmittedFixtureId(editingFixture.id)}><input type="hidden" name="fixture_id" value={editingFixture.id}/><div className="result-side-readonly"><div><span>Đội 1 / Team 1</span><output>{editingRows[0]?.label}</output></div><div><span>Đội 2 / Team 2</span><output>{editingRows[1]?.label}</output></div></div><div className="admin-fields"><label><span>Tỷ số 1 / Score 1</span><input name="score_1" type="number" min="0" step="any" defaultValue={editingHome?.score ?? ""}/></label><label><span>Tỷ số 2 / Score 2</span><input name="score_2" type="number" min="0" step="any" defaultValue={editingAway?.score ?? ""}/></label><label><span>Trạng thái / Status</span><select name="status" defaultValue={editingFixture.status}><option value="scheduled">Scheduled</option><option value="live">Live</option><option value="completed">Completed</option><option value="postponed">Postponed</option><option value="cancelled">Cancelled</option></select></label><fieldset className="winner-options"><legend>Đội thắng / Winner</legend>{[editingHome, editingAway].filter((entry): entry is FixtureEntry => Boolean(entry?.entry_id)).map((entry) => <label key={entry.entry_id}><input type="radio" name="winner_entry_id" value={entry.entry_id} defaultChecked={entry.entry_id === editingFixture.winner_entry_id}/>{entryName(entry.entry_id)}</label>)}</fieldset><label><span>Ghi chú / Note</span><input name="note" defaultValue={editingHome?.result_detail?.note ?? ""}/></label></div>{!editingHome || !editingAway || editingHome.entry_id === editingAway.entry_id ? <p className="form-error" role="alert">Trận chưa đủ hai đội khác nhau. Hoàn tất cấu trúc nguồn nhánh trước khi lưu.</p> : resultState.message && !resultState.ok && submittedFixtureId === editingFixture.id ? <p className="form-error" role="alert">{resultState.message}</p> : null}<div className="dialog-actions"><button type="button" className="archive-button" onClick={closeDialog}>Huỷ</button><button className="gold-button" disabled={resultPending || !editingHome || !editingAway || editingHome.entry_id === editingAway.entry_id}>{resultPending ? "Đang lưu..." : "Lưu kết quả / Save result"}</button></div></form>{resultState.code === "DEPENDENT_RESULTS" && submittedFixtureId === editingFixture.id && previewAction && sportSlug && <form className="reset-preview" action={previewAction}><input type="hidden" name="fixture_id" value={editingFixture.id}/><input type="hidden" name="sport_slug" value={sportSlug}/><button className="archive-button">Xem ảnh hưởng khi mở lại vòng sau</button></form>}</section>
    </div>}
  </dialog>}</div>;
}
