"use client";

import Link from "next/link";
import { Pencil, Save, X } from "lucide-react";
import { useActionState, useEffect, useRef, useState } from "react";
import { CARD_WIDTH, COLUMN_GAP, fixtureSides, groupBy, layoutBracket, resolveMatchEntry, slotCandidateLabel, slotGroupCandidates, slotLabel, slotSourceLabel } from "@/lib/brackets";
import { initialAdminActionState, type AdminActionState } from "@/lib/admin-action";
import { formatMatchResult, normalizeLegacyMatchResult, scoresFromMatchResult, standingDifference } from "@/lib/competition-display";
import { buildSearchSuggestions } from "@/lib/search";
import { copy, localized, type Entry, type Fixture, type FixtureEntry, type FixtureSlot, type Group, type GroupEntry, type Locale, type Standing, type Tournament } from "@/lib/site";
import { deriveStandings } from "@/lib/standings";
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
  standingsAction?: PreviewAction;
  sportSlug?: string;
  showTournamentSelector?: boolean;
  participants?: Array<{ id: string; full_name: string }>;
  entryMembers?: Array<{ entry_id: string; participant_id: string; sort_order?: number }>;
};

type BracketLayout = ReturnType<typeof layoutBracket>;
type MatchRow = { row: FixtureEntry | undefined; entry: Entry | undefined; slot: FixtureSlot | undefined; candidates: Entry[]; label: string; candidateLabel: string };

const noopAction: AdminAction = async () => initialAdminActionState;
const scoreValue = (row: FixtureEntry | undefined) => row?.score || (row?.score_numeric == null ? "" : String(row.score_numeric));
const scoreLabel = (row: FixtureEntry | undefined, fallback = "—") => scoreValue(row) || fallback;
function winnerFromScores(homeScore: string, awayScore: string, homeId: string, awayId: string) {
  if (!homeScore || !awayScore) return "";
  const home = Number(homeScore);
  const away = Number(awayScore);
  return Number.isFinite(home) && Number.isFinite(away) && home !== away ? home > away ? homeId : awayId : "";
}
function updateWinnerFromScores(form: HTMLFormElement, homeId: string, awayId: string) {
  const homeInput = form.elements.namedItem("score_1") as HTMLInputElement | null;
  const awayInput = form.elements.namedItem("score_2") as HTMLInputElement | null;
  const winner = form.elements.namedItem("winner_entry_id") as HTMLSelectElement | null;
  if (!homeInput || !awayInput || !winner) return;
  winner.value = winnerFromScores(homeInput.value, awayInput.value, homeId, awayId);
}

function ZoomableBracket({ layout, children, locale }: { layout: BracketLayout; children: React.ReactNode; locale: Locale }) {
  const viewportRef = useRef<HTMLDivElement>(null);
  const [zoom, setZoom] = useState(1);
  const fit = () => setZoom(Math.min(1, Math.max(0.25, ((viewportRef.current?.clientWidth ?? window.innerWidth) - 40) / layout.width)));
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

function InlineBracketResult({ fixture, rows, action, manualWinner }: { fixture: Fixture; rows: MatchRow[]; action: AdminAction; manualWinner: boolean }) {
  const [state, formAction, pending] = useActionState(action, initialAdminActionState);
  const ready = Boolean(rows[0]?.entry && rows[1]?.entry && rows[0].entry.id !== rows[1].entry.id);
  return <form className="bracket-inline-result" action={formAction}>
    <input type="hidden" name="fixture_id" value={fixture.id}/>
    <input type="hidden" name="status" value="completed"/>
    {rows.map((item, index) => <div className="bracket-inline-score" key={item.row?.id ?? item.slot?.id ?? index}>
      <span title={item.label}>{item.label}</span>
      {item.entry ? <input name={`score_${index + 1}`} type="number" min="0" step="any" defaultValue={item.row?.score || (item.row?.score_numeric == null ? "" : String(item.row.score_numeric))} onChange={(event) => updateWinnerFromScores(event.currentTarget.form!, rows[0]?.entry?.id ?? "", rows[1]?.entry?.id ?? "")} aria-label={`Tỷ số ${item.label}`}/> : <small title={item.candidateLabel}>{item.candidateLabel ? `Có thể: ${item.candidateLabel}` : "Chưa xác định"}</small>}
    </div>)}
    {manualWinner && <label className="bracket-inline-winner"><span>Thắng</span><select name="winner_entry_id" aria-label="Đội thắng" required={ready} disabled={!ready} defaultValue={fixture.winner_entry_id ?? winnerFromScores(scoreValue(rows[0]?.row), scoreValue(rows[1]?.row), rows[0]?.entry?.id ?? "", rows[1]?.entry?.id ?? "")}><option value="">Chọn đội</option>{rows.filter((item) => item.entry).map((item) => <option key={item.entry!.id} value={item.entry!.id}>{item.label}</option>)}</select></label>}
    {!ready && <small className="bracket-inline-state">Chưa đủ 2 đội để nhập điểm</small>}
    {manualWinner && ready && <small className="bracket-inline-state">Kéo co: chọn đội thắng</small>}
    {!state.ok && state.message && <small className="form-error bracket-inline-error" title={state.message} role="alert">{state.message}</small>}
    <button className="gold-button bracket-inline-save" aria-label={pending ? "Đang lưu điểm" : "Lưu điểm"} title={pending ? "Đang lưu điểm" : "Lưu điểm"} disabled={pending || !ready}><Save size={13} aria-hidden="true"/><span>{pending ? "Đang lưu" : "Lưu điểm"}</span></button>
  </form>;
}

export function CompetitionBoard({ locale, tournaments, entries, groups, groupEntries, fixtures, fixtureEntries, fixtureSlots, standings, adminHref, resultAction, slotAction, previewAction, standingsAction, sportSlug, showTournamentSelector = true, participants = [], entryMembers = [] }: Props) {
  const t = copy[locale];
  const entriesById = new Map(entries.map((entry) => [entry.id, entry]));
  const fixturesById = new Map(fixtures.map((fixture) => [fixture.id, fixture]));
  const fixturesByTournament = groupBy(fixtures, (fixture) => fixture.tournament_id);
  const entriesByTournament = groupBy(entries, (entry) => entry.tournament_id);
  const participantsById = new Map(participants.map((participant) => [participant.id, participant.full_name]));
  const membersByEntryId = new Map<string, string[]>();
  for (const member of entryMembers) membersByEntryId.set(member.entry_id, [...(membersByEntryId.get(member.entry_id) ?? []), member.participant_id]);
  const groupsByTournament = groupBy(groups, (group) => group.tournament_id);
  const groupEntriesByGroup = groupBy(groupEntries, (item) => item.group_id);
  const standingsByGroup = groupBy(standings, (row) => row.group_id ?? `tournament:${row.tournament_id}`);
  const fixtureRows = groupBy(fixtureEntries, (row) => row.fixture_id);
  const fixtureSlotsById = groupBy(fixtureSlots, (slot) => slot.fixture_id);
  const [editingFixture, setEditingFixture] = useState<Fixture | null>(null);
  const [submittedFixtureId, setSubmittedFixtureId] = useState<string | null>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [resultState, resultFormAction, resultPending] = useActionState(resultAction ?? noopAction, initialAdminActionState);
  useEffect(() => {
    if (editingFixture && !dialogRef.current?.open) dialogRef.current?.showModal();
    if (!editingFixture && dialogRef.current?.open) dialogRef.current.close();
    if (editingFixture && submittedFixtureId === editingFixture.id && resultState.ok && resultState.message) dialogRef.current?.close();
  }, [editingFixture, resultState, submittedFixtureId]);
  const sourceCodes = groupBy(fixtures.filter((fixture) => fixture.source_code), (fixture) => `${fixture.tournament_id}:${fixture.source_code}`);
  const available = tournaments.filter((tournament) => (fixturesByTournament.get(tournament.id)?.length ?? 0) > 0 || (groupsByTournament.get(tournament.id)?.length ?? 0) > 0 || (entriesByTournament.get(tournament.id)?.length ?? 0) > 0);
  const [selectedTournamentId, setSelectedTournamentId] = useState(available[0]?.id ?? "");
  useEffect(() => {
    if (!available.some((tournament) => tournament.id === selectedTournamentId)) setSelectedTournamentId(available[0]?.id ?? "");
  }, [available, selectedTournamentId]);

  const matchLabel = (fixture: Fixture) => {
    if (!fixture.source_code) return localized(fixture, "round", locale) || t.updating;
    const sameCode = sourceCodes.get(`${fixture.tournament_id}:${fixture.source_code}`) ?? [];
    const occurrence = sameCode.findIndex((item) => item.id === fixture.id) + 1;
    return `${locale === "vi" ? "Trận" : "Match"} ${fixture.source_code}${sameCode.length > 1 ? ` (${occurrence})` : ""}`;
  };
  const entryName = (id: string | null | undefined) => id ? localized(entriesById.get(id) ?? {}, "name", locale) : "";
  const entryCell = (id: string) => {
    const entry = entriesById.get(id);
    const members = (membersByEntryId.get(id) ?? []).map((memberId) => participantsById.get(memberId)).filter(Boolean);
    return <div className="entry-cell"><span className="entry-name">{entryName(id)}</span>{entry?.kind === "team" && members.length > 0 && <span className="entry-member-list">{members.join(" · ")}</span>}</div>;
  };
  const slotDisplayLabel = (slot: FixtureSlot) => {
    const group = slot.source_group_id ? groups.find((item) => item.id === slot.source_group_id) : undefined;
    return slotSourceLabel(slot, group ? localized(group, "name", locale) : "", locale) || slotLabel(slot, undefined, locale);
  };
  const matchRows = (fixture: Fixture): MatchRow[] => {
    const rows = fixtureRows.get(fixture.id) ?? [];
    const sides = fixtureSides(rows);
    const slots = fixtureSlotsById.get(fixture.id) ?? [];
    return (["home", "away"] as const).map((side, index) => {
      const sideRow = sides[index];
      const slot = slots.find((item) => item.side === side);
      const entry = resolveMatchEntry(slot, sideRow, { entries, standings, fixtures, fixtureEntries }, slots.length > 0);
      const row = slots.length > 0 ? (entry ? rows.find((item) => item.entry_id === entry.id) : undefined) : sideRow;
      const candidates = slot && !entry ? slotGroupCandidates(slot, groupEntries, entries) : [];
      return { row, entry, slot, candidates, label: entry ? localized(entry, "name", locale) : slot ? slotDisplayLabel(slot) : t.teamsNotAssigned, candidateLabel: !entry && candidates.length ? slotCandidateLabel(candidates, locale) : "" };
    });
  };
  const editingRows = editingFixture ? matchRows(editingFixture) : [];
  const editingReady = Boolean(editingRows[0]?.entry && editingRows[1]?.entry && editingRows[0].entry.id !== editingRows[1].entry.id);
  const editingHome = editingRows[0]?.row;
  const editingAway = editingRows[1]?.row;
  const editingSlots = editingFixture ? fixtureSlotsById.get(editingFixture.id) ?? [] : [];
  const closeDialog = () => { setSubmittedFixtureId(null); setEditingFixture(null); };
  const tournamentHasResults = (tournamentId: string) => (fixturesByTournament.get(tournamentId) ?? []).some((fixture) => ["live", "completed"].includes(fixture.status) || fixture.winner_entry_id || (fixtureRows.get(fixture.id) ?? []).some((row) => row.score !== null || row.score_numeric !== null || row.rank !== null || row.result_status !== null));

  const table = (tournament: Tournament, tournamentGroups: Group[]) => {
    const groupTables = tournamentGroups.length ? tournamentGroups : [{ id: "", tournament_id: tournament.id, name_vi: "Bảng xếp hạng", name_en: "Standings", sort_order: 0 }];
    return <div className="group-grid">{groupTables.map((group) => {
      const ruleValues = [tournament.scoring_rule?.win, tournament.scoring_rule?.draw, tournament.scoring_rule?.loss].map(Number);
      const autoRule = tournament.scoring_rule?.type === "head-to-head" && ruleValues.every(Number.isFinite) ? { type: "head-to-head", win: ruleValues[0], draw: ruleValues[1], loss: ruleValues[2] } : {};
      const autoStandings = autoRule.type === "head-to-head";
      const autoRows = autoStandings ? deriveStandings((fixturesByTournament.get(tournament.id) ?? []).filter((fixture) => (fixture.group_id ?? "") === group.id).map((fixture) => ({ status: fixture.status, entries: fixtureSides(fixtureRows.get(fixture.id) ?? []).filter((row): row is FixtureEntry => Boolean(row)).map((row) => ({ entry_id: row.entry_id, score_numeric: row.score_numeric })) })), autoRule) : [];
      const autoByEntry = new Map(autoRows.map((row) => [row.entry_id, row]));
      const seeded = group.id ? (groupEntriesByGroup.get(group.id) ?? []).map((item) => item.entry_id) : (entriesByTournament.get(tournament.id) ?? []).map((item) => item.id);
      const standingRows = [...(standingsByGroup.get(group.id || `tournament:${tournament.id}`) ?? [])].sort((a, b) => (a.rank ?? 999999) - (b.rank ?? 999999));
      const ids = [...new Set([...autoRows.map((row) => row.entry_id), ...standingRows.map((row) => row.entry_id), ...seeded])];
      const rows = ids.map((id) => { const row = standingRows.find((item) => item.entry_id === id); const empty = { played: 0, won: 0, drawn: 0, lost: 0, score_for: 0, score_against: 0, points: 0, rank: null }; const stats = autoStandings ? autoByEntry.get(id) ?? empty : row ?? empty; return { id, row, stats }; });
      const guide = autoStandings ? `${locale === "vi" ? "Tự tính từ bracket" : "Calculated from bracket"}: ${t.played} = ${locale === "vi" ? "trận đã hoàn tất" : "completed matches"}; ${locale === "vi" ? "Ghi/Thua" : "For/Against"} = ${locale === "vi" ? "tổng tỷ số" : "score totals"}; +/- = ${locale === "vi" ? "Ghi - Thua" : "For - Against"}; ${t.points} = ${t.wins}×${ruleValues[0]} + ${t.draws}×${ruleValues[1]} + ${t.losses}×${ruleValues[2]}.` : `${locale === "vi" ? "Manual" : "Manual"}: ${t.played} = ${t.wins} + ${t.draws} + ${t.losses}; +/- = ${locale === "vi" ? "Ghi - Thua" : "For - Against"}.`;
      const readonlyRow = ({ id, row, stats }: { id: string; row?: Standing; stats: { played: number; won: number; drawn: number; lost: number; score_for: number; score_against: number; points: number; rank?: number | null } }) => <tr key={id}><td>{stats.rank ?? row?.rank ?? "—"}</td><td>{entryCell(id)}</td><td>{stats.played}</td><td>{stats.won}</td><td>{stats.drawn}</td><td>{stats.lost}</td><td>{stats.score_for} / {stats.score_against}<output className="standings-difference">+/- {standingDifference(stats)}</output></td><td><b>{stats.points}</b></td></tr>;
      const manualRow = ({ id, row, stats }: { id: string; row?: Standing; stats: Standing | { played: number; won: number; drawn: number; lost: number; score_for: number; score_against: number; points: number; rank: number | null } }) => <tr key={id}><td><output className="auto-rank-cell">{row?.rank ?? "Tự động"}</output></td><td><input type="hidden" name="entry_id" value={id}/>{entryCell(id)}</td><td><input name="played" type="number" min="0" defaultValue={stats.played} aria-label={`Số trận ${entryName(id)}`}/></td><td><input name="won" type="number" min="0" defaultValue={stats.won} aria-label={`Thắng ${entryName(id)}`}/></td><td><input name="drawn" type="number" min="0" defaultValue={stats.drawn} aria-label={`Hòa ${entryName(id)}`}/></td><td><input name="lost" type="number" min="0" defaultValue={stats.lost} aria-label={`Thua ${entryName(id)}`}/></td><td><span className="standings-score-pair"><label>Ghi<input name="score_for" type="number" min="0" step="any" defaultValue={stats.score_for} aria-label={`Điểm ghi ${entryName(id)}`}/></label><label>Thua<input name="score_against" type="number" min="0" step="any" defaultValue={stats.score_against} aria-label={`Điểm thua ${entryName(id)}`}/></label></span><output className="standings-difference">+/- {standingDifference(stats)}</output></td><td><input name="points" type="number" min="0" step="any" defaultValue={stats.points} aria-label={`Điểm ${entryName(id)}`}/></td></tr>;
      const tableContent = <><p className="standings-guide" hidden={!standingsAction}>{standingsAction ? guide : ""}</p><table><thead><tr><th>{t.rank}</th><th>{t.teams}</th><th>{t.played}</th><th>{t.wins}</th><th>{t.draws}</th><th>{t.losses}</th><th>{locale === "vi" ? "Ghi/Thua (+/-)" : "For/Against (+/-)"}</th><th>{t.points}</th></tr></thead><tbody>{rows.map(autoStandings || !standingsAction ? readonlyRow : manualRow)}</tbody></table>{standingsAction && !autoStandings && <button className="gold-button" type="submit">Lưu bảng / Save standings</button>}</>;
      return <div className="panel table-scroll" key={group.id || tournament.id}><h3 className="table-title">{localized(group, "name", locale)}</h3>{standingsAction && !autoStandings ? <form className="standings-inline-form" action={standingsAction}><input type="hidden" name="tournament_id" value={tournament.id}/><input type="hidden" name="group_id" value={group.id}/><input type="hidden" name="manual_mode" value="standings"/>{tableContent}</form> : tableContent}</div>;
    })}</div>;
  };

  const manualTable = (tournament: Tournament) => {
    const tournamentEntries = entriesByTournament.get(tournament.id) ?? [];
    const standingRows = standingsByGroup.get(`tournament:${tournament.id}`) ?? [];
    const standingsByEntry = new Map(standingRows.map((row) => [row.entry_id, row]));
    const raceMode = tournament.competition_mode === "race";
    const fixturesForTournament = fixturesByTournament.get(tournament.id) ?? [];
    const sourceFixtures = fixturesForTournament.filter((fixture) => fixture.source_code?.startsWith(tournament.slug.toUpperCase())).sort((a, b) => (a.source_code ?? "").localeCompare(b.source_code ?? ""));
    const sections = (sourceFixtures.length ? sourceFixtures : fixturesForTournament).map((fixture) => ({
      fixture,
      rows: [...(fixtureRows.get(fixture.id) ?? [])].sort((a, b) => (a.seed_order ?? Number.MAX_SAFE_INTEGER) - (b.seed_order ?? Number.MAX_SAFE_INTEGER)),
    }));
    const tableFor = (fixture: Fixture, raceRows: FixtureEntry[]) => {
      const raceByEntry = new Map(raceRows.map((row) => [row.entry_id, row]));
      const ids = sourceFixtures.length ? [...new Set(raceRows.map((row) => row.entry_id))] : [...new Set([...standingRows.map((row) => row.entry_id), ...tournamentEntries.map((entry) => entry.id)])];
      return <div className="panel table-scroll manual-results" key={fixture.id}>{sourceFixtures.length > 1 && <h3 className="table-title">{localized(fixture, "round", locale)}</h3>}<table><thead><tr><th>{t.rank}</th><th>{t.athlete}</th><th>{t.played}</th><th>{t.wins}</th><th>{t.draws}</th><th>{t.losses}</th><th>+/-</th><th>{t.points}</th>{raceMode && <><th>{t.lane}</th><th>{t.performance}</th><th>{t.status}</th></>}</tr></thead><tbody>{ids.map((id) => { const standing = standingsByEntry.get(id); const race = raceByEntry.get(id); const stats = standing ?? { played: 0, won: 0, drawn: 0, lost: 0, score_for: 0, score_against: 0, points: 0 }; return <tr key={id}><td>{standing?.rank ?? race?.rank ?? "—"}</td><td>{entryCell(id)}</td><td>{stats.played}</td><td>{stats.won}</td><td>{stats.drawn}</td><td>{stats.lost}</td><td>{standingDifference(stats)}</td><td><b>{stats.points}</b></td>{raceMode && <><td>{race?.lane ?? "—"}</td><td>{race?.score ?? "—"}</td><td>{race?.result_status?.toUpperCase() ?? t.updating}</td></>}</tr>; })}</tbody></table></div>;
    };
    return <div className={sourceFixtures.length > 1 ? "manual-results-stack" : ""}>{sections.map(({ fixture, rows }) => tableFor(fixture, rows))}</div>;
  };

  const matchesTable = (items: Fixture[]) => <div className="panel table-scroll board-matches"><table><thead><tr><th>{t.match}</th><th>{t.round}</th><th>{t.teams}</th><th>{t.result}</th></tr></thead><tbody>{items.map((fixture) => { const rows = matchRows(fixture); const summary = localized(fixture, "result_summary", locale); const result = formatMatchResult(rows[0]?.label ?? "", scoreValue(rows[0]?.row), scoreValue(rows[1]?.row), rows[1]?.label ?? "") || normalizeLegacyMatchResult(summary, rows[0]?.label ?? "", rows[1]?.label ?? "") || summary; return <tr key={fixture.id}><td>{matchLabel(fixture)}</td><td>{localized(fixture, "round", locale) || t.updating}</td><td>{rows.map((row) => row.label).join(" — ")}</td><td>{result || rows.map((row) => scoreLabel(row.row)).join(" : ")}</td></tr>; })}</tbody></table></div>;

  if (!available.length) return <section className="panel empty-state"><h2>{t.empty}</h2></section>;
  const selectedTournament = available.find((tournament) => tournament.id === selectedTournamentId) ?? available[0];
  return <div className="competition-board">{showTournamentSelector && available.length > 1 && <div className="board-selector"><label htmlFor="board-tournament">Lọc hạng mục / Category<select id="board-tournament" value={selectedTournament.id} onChange={(event) => setSelectedTournamentId(event.target.value)}>{available.map((tournament) => <option key={tournament.id} value={tournament.id}>{localized(tournament, "name", locale)}</option>)}</select></label></div>}{resultAction && <aside className="bracket-help" aria-label="Hướng dẫn cập nhật kết quả"><b>Cách đọc và cập nhật</b><span>Đọc từ trái sang phải. Đường nối đưa đội thắng sang vòng kế tiếp.</span><span>Chọn trận, nhập kết quả hai đội, rồi bấm <strong>Lưu điểm</strong>.</span></aside>}<div className="tournament-stack">{[selectedTournament].map((tournament) => {
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
        const layout = layoutBracket(knockout, slots, resultAction ? 166 : 84, resultAction ? undefined : 100);
        const roundCount = Math.max(1, ...knockout.map((fixture) => fixture.round_order ?? 1));
        const roundLabels = new Map<number, string>();
        knockout.forEach((fixture) => { if (fixture.round_order !== null && !roundLabels.has(fixture.round_order)) roundLabels.set(fixture.round_order, localized(fixture, "round", locale) || `${locale === "vi" ? "Vòng" : "Round"} ${fixture.round_order}`); });
        return <ZoomableBracket key={`${tournament.id}-${layout.width}`} locale={locale} layout={layout}><div className="bracket-round-headings">{Array.from({ length: roundCount }, (_, index) => <div className="bracket-round-heading" key={index} style={{ left: index * (CARD_WIDTH + COLUMN_GAP), width: CARD_WIDTH }}>{roundLabels.get(index + 1) ?? `${locale === "vi" ? "Vòng" : "Round"} ${index + 1}`}</div>)}</div><svg viewBox={`0 0 ${layout.width} ${layout.height}`} aria-hidden="true">{layout.connectors.map((connector) => <path key={`${connector.sourceId}-${connector.targetId}`} d={connector.path}/>)}</svg>{layout.nodes.map((node) => { const fixture = fixturesById.get(node.id)!; const rows = matchRows(fixture); const card = <article className={`bracket-match source-bracket-match${resultAction ? " admin-bracket-match" : ""}`}>
          {resultAction && <button type="button" className="bracket-edit-button" aria-label={`Mở form sửa kết quả ${matchLabel(fixture)}`} title="Mở form sửa kết quả" onClick={() => { setSubmittedFixtureId(null); setEditingFixture(fixture); }}><Pencil size={13} aria-hidden="true"/><span>Sửa</span></button>}
          <small className="bracket-match-label">{[matchLabel(fixture), localized(fixture, "round", locale)].filter(Boolean).join(" · ") || t.updating}</small>{resultAction ? <InlineBracketResult fixture={fixture} rows={rows} action={resultAction} manualWinner={sportSlug === "keo-co"}/> : <div className="bracket-teams">{(() => { const fallbackScores = scoresFromMatchResult(localized(fixture, "result_summary", locale), rows[0]?.label ?? "", rows[1]?.label ?? ""); return rows.map(({ row, entry, label }, index) => <div className={`bracket-team${entry?.id === fixture.winner_entry_id ? " winner" : ""}`} key={row?.id ?? index}><span>{label}</span><b>{scoreLabel(row, fallbackScores?.[index] ?? "—")}</b></div>); })()}</div>}</article>;
          return <div className="source-bracket-node" style={{ left: node.x, top: node.y }} key={node.id}>{resultAction ? card : adminHref ? <Link href={`${adminHref}&edit=fixture-result:${fixture.id}#fixture-${fixture.id}`}>{card}</Link> : card}</div>;
        })}</ZoomableBracket>;
      })()}
      {tournament.competition_mode === "group_knockout" && table(tournament, tournamentGroups)}
      {tournament.competition_mode === "round_robin" && <>{table(tournament, tournamentGroups)}{matchesTable(tournamentFixtures)}</>}
      {(tournament.competition_mode === "race" || tournament.competition_mode === "swiss") && manualTable(tournament)}
      {!tournamentFixtures.length && !tournamentGroups.length && !entriesByTournament.get(tournament.id)?.length && <div className="panel board-empty">{t.empty}</div>}
    </section>;
  })}</div>{resultAction && <dialog ref={dialogRef} className="result-dialog" onClick={(event) => { if (event.target === event.currentTarget) closeDialog(); }} onClose={closeDialog}>
    <header><div><h2>Sửa kết quả trận đấu</h2><p>{editingFixture ? `${matchLabel(editingFixture)} · ${localized(editingFixture, "round", locale) || t.updating}` : ""}</p></div><button type="button" className="dialog-close" onClick={closeDialog} aria-label="Đóng" title="Đóng"><X size={16} aria-hidden="true"/></button></header>
    {editingFixture && <div className="result-dialog-body">
      <section className="dialog-result-section"><h3>Nhập kết quả</h3><form key={editingFixture.id} action={resultFormAction} onSubmit={() => setSubmittedFixtureId(editingFixture.id)}><input type="hidden" name="fixture_id" value={editingFixture.id}/><div className="result-side-readonly"><div><span>Đội 1 / Team 1</span><output>{editingRows[0]?.label}</output></div><div><span>Đội 2 / Team 2</span><output>{editingRows[1]?.label}</output></div></div><div className="admin-fields"><label><span>Kết quả đội 1 / Score 1</span><input name="score_1" type="number" min="0" step="any" defaultValue={scoreValue(editingHome)} onChange={(event) => updateWinnerFromScores(event.currentTarget.form!, editingRows[0]?.entry?.id ?? "", editingRows[1]?.entry?.id ?? "")}/></label><label><span>Kết quả đội 2 / Score 2</span><input name="score_2" type="number" min="0" step="any" defaultValue={scoreValue(editingAway)} onChange={(event) => updateWinnerFromScores(event.currentTarget.form!, editingRows[0]?.entry?.id ?? "", editingRows[1]?.entry?.id ?? "")}/></label><label><span>Trạng thái / Status</span><select name="status" defaultValue={editingFixture.status}><option value="scheduled">Scheduled</option><option value="live">Live</option><option value="completed">Completed</option><option value="postponed">Postponed</option><option value="cancelled">Cancelled</option></select></label>{sportSlug === "keo-co" ? <><label><span>Đội thắng / Winner</span><select name="winner_entry_id" required={editingReady} defaultValue={editingFixture.winner_entry_id ?? winnerFromScores(scoreValue(editingHome), scoreValue(editingAway), editingRows[0]?.entry?.id ?? "", editingRows[1]?.entry?.id ?? "")}><option value="">Chọn đội thắng</option>{editingRows.filter((item) => item.entry).map((item) => <option key={item.entry!.id} value={item.entry!.id}>{item.label}</option>)}</select></label><p className="auto-winner-note">Nhập tỷ số, đội thắng sẽ tự động chọn.</p></> : <p className="auto-winner-note" title="Nếu hòa ở vòng loại trực tiếp, nhập tỷ số phân định.">Tự chọn đội thắng theo tỷ số.</p>}<label><span>Ghi chú / Note</span><input name="note" defaultValue={editingHome?.result_detail?.note ?? ""}/></label></div>{!editingReady ? <p className="form-error result-form-message" title="Trận chưa đủ hai đội khác nhau. Hoàn tất cấu trúc nguồn nhánh trước khi lưu." role="alert">Trận chưa đủ hai đội khác nhau. Hoàn tất cấu trúc nguồn nhánh trước khi lưu.</p> : resultState.message && !resultState.ok && submittedFixtureId === editingFixture.id ? <p className="form-error result-form-message" title={resultState.message} role="alert">{resultState.message}</p> : null}<div className="dialog-actions"><button type="button" className="archive-button" onClick={closeDialog}>Huỷ</button><button className="gold-button" title="Lưu kết quả" disabled={resultPending || !editingReady}>{resultPending ? "Đang lưu..." : <><Save size={15} aria-hidden="true"/>Lưu kết quả</>}</button></div></form>{resultState.code === "DEPENDENT_RESULTS" && submittedFixtureId === editingFixture.id && previewAction && sportSlug && <form className="reset-preview" action={previewAction}><input type="hidden" name="fixture_id" value={editingFixture.id}/><input type="hidden" name="sport_slug" value={sportSlug}/><button className="archive-button">Xem ảnh hưởng khi mở lại vòng sau</button></form>}</section>
      {editingSlots.length > 0 && <details className="dialog-source-details" open={!tournamentHasResults(editingFixture.tournament_id)}><summary><b>Ghép đội vào trận này</b><span>Chỉ chỉnh trước khi hạng mục có kết quả</span></summary><div className="dialog-source-section">{editingSlots.map((slot) => slotAction && !tournamentHasResults(editingFixture.tournament_id) ? <SlotEditor key={slot.id} slot={slot} fixture={editingFixture} entries={entries} groups={groups} groupEntries={groupEntries} fixtures={fixtures} action={slotAction}/> : <div className="slot-readonly" key={slot.id}><b>{slot.side === "home" ? "Đội 1" : "Đội 2"}</b><span>{slot.source_entry_id ? entryName(slot.source_entry_id) : slotDisplayLabel(slot)}</span></div>)}</div></details>}
    </div>}
  </dialog>}</div>;
}
