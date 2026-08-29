"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { layoutBracket, slotLabel } from "@/lib/brackets";
import { copy, localized, type Entry, type Fixture, type FixtureEntry, type FixtureSlot, type Group, type GroupEntry, type Locale, type Standing, type Tournament } from "@/lib/site";

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
};

type BracketLayout = ReturnType<typeof layoutBracket>;

function ZoomableBracket({ layout, children, locale }: { layout: BracketLayout; children: React.ReactNode; locale: Locale }) {
  const viewportRef = useRef<HTMLDivElement>(null);
  const [zoom, setZoom] = useState(1);
  const fit = () => setZoom(Math.min(1, Math.max(0.25, ((viewportRef.current?.clientWidth ?? window.innerWidth) - 16) / layout.width)));
  useEffect(() => {
    const update = () => {
      const width = viewportRef.current?.clientWidth ?? window.innerWidth;
      setZoom(Math.min(1, Math.max(0.25, (width - 16) / layout.width)));
    };
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

export function CompetitionBoard({ locale, tournaments, entries, groups, groupEntries, fixtures, fixtureEntries, fixtureSlots, standings, adminHref }: Props) {
  const t = copy[locale];
  const available = tournaments.filter((tournament) => fixtures.some((fixture) => fixture.tournament_id === tournament.id) || groups.some((group) => group.tournament_id === tournament.id) || entries.some((entry) => entry.tournament_id === tournament.id));
  const [selectedId, setSelectedId] = useState(available[0]?.id ?? "");
  useEffect(() => { if (!available.some((item) => item.id === selectedId)) setSelectedId(available[0]?.id ?? ""); }, [available, selectedId]);
  const entriesById = new Map(entries.map((entry) => [entry.id, entry]));
  const fixturesById = new Map(fixtures.map((fixture) => [fixture.id, fixture]));
  const fixtureRows = Map.groupBy(fixtureEntries, (row) => row.fixture_id);
  const fixtureSlotsById = Map.groupBy(fixtureSlots, (slot) => slot.fixture_id);
  const groupsByTournament = Map.groupBy(groups, (group) => group.tournament_id);

  const matchLabel = (fixture: Fixture) => {
    if (!fixture.source_code) return localized(fixture, "round", locale) || t.updating;
    const sameCode = fixtures.filter((item) => item.tournament_id === fixture.tournament_id && item.source_code === fixture.source_code);
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

  const table = (tournament: Tournament, tournamentGroups: Group[]) => {
    const standingsFor = (groupId: string | null) => standings.filter((row) => row.tournament_id === tournament.id && row.group_id === groupId).sort((a, b) => (a.rank ?? 999) - (b.rank ?? 999));
    const groupTables = tournamentGroups.length ? tournamentGroups : [{ id: "", tournament_id: tournament.id, name_vi: "Bảng xếp hạng", name_en: "Standings", sort_order: 0 }];
    return <div className="group-grid">{groupTables.map((group) => {
      const seeded = group.id ? groupEntries.filter((item) => item.group_id === group.id).map((item) => item.entry_id) : entries.filter((item) => item.tournament_id === tournament.id).map((item) => item.id);
      const standingRows = standingsFor(group.id || null);
      const ids = [...new Set([...standingRows.map((row) => row.entry_id), ...seeded])];
      return <div className="panel table-scroll" key={group.id || tournament.id}><h3 className="table-title">{localized(group, "name", locale)}</h3><table><thead><tr><th>#</th><th>{t.teams}</th><th>P</th><th>W</th><th>D</th><th>L</th><th>{t.points}</th></tr></thead><tbody>{ids.map((id, index) => { const row = standingRows.find((item) => item.entry_id === id); return <tr key={id}><td>{row?.rank ?? index + 1}</td><td>{entryName(id)}</td><td>{row?.played ?? 0}</td><td>{row?.won ?? 0}</td><td>{row?.drawn ?? 0}</td><td>{row?.lost ?? 0}</td><td><b>{row?.points ?? 0}</b></td></tr>; })}</tbody></table></div>;
    })}</div>;
  };

  const matchesTable = (items: Fixture[]) => <div className="panel table-scroll board-matches"><table><thead><tr><th>{t.match}</th><th>{t.round}</th><th>{t.teams}</th><th>{t.result}</th></tr></thead><tbody>{items.map((fixture) => { const rows = matchRows(fixture); return <tr key={fixture.id}><td>{matchLabel(fixture)}</td><td>{localized(fixture, "round", locale) || t.updating}</td><td>{rows.map((row) => row.label).join(" — ")}</td><td>{rows.map((row) => row.row?.score ?? "—").join(" : ")}</td></tr>; })}</tbody></table></div>;

  if (!available.length) return <section className="panel empty-state"><h2>{t.empty}</h2></section>;
  const selectedTournament = available.find((tournament) => tournament.id === selectedId) ?? available[0];
  return <div className="competition-board"><div className="board-selector"><label htmlFor="board-tournament">{locale === "vi" ? "Hạng mục" : "Category"}<select id="board-tournament" value={selectedTournament.id} onChange={(event) => setSelectedId(event.target.value)}>{available.map((tournament) => <option key={tournament.id} value={tournament.id}>{localized(tournament, "name", locale)}</option>)}</select></label></div><div className="tournament-stack">{[selectedTournament].map((tournament) => {
    const tournamentFixtures = fixtures.filter((fixture) => fixture.tournament_id === tournament.id);
    const tournamentGroups = groupsByTournament.get(tournament.id) ?? [];
    const knockout = tournamentFixtures.filter((fixture) => fixture.round_order !== null && fixture.bracket_position !== null);
    const warnings = tournament.source_metadata?.warnings ?? [];
    const isBracket = tournament.competition_mode === "knockout" || tournament.competition_mode === "group_knockout";
    return <section className="tournament-block" id={`tournament-${tournament.id}`} key={tournament.id}>
      <header className="board-heading"><div><h2>{localized(tournament, "name", locale)}</h2>{sourceNote(tournament, locale)}</div><span>{localized(tournament, "format", locale)}</span></header>
      {warnings.map((warning) => <p className="board-warning" key={warning}>⚠ {warning}</p>)}
      {isBracket && knockout.length > 0 && (() => {
        const slots = fixtureSlots.filter((slot) => fixturesById.get(slot.fixture_id)?.tournament_id === tournament.id);
        const layout = layoutBracket(knockout, slots);
        return <ZoomableBracket key={`${tournament.id}-${layout.width}`} locale={locale} layout={layout}><svg viewBox={`0 0 ${layout.width} ${layout.height}`} aria-hidden="true">{layout.connectors.map((connector) => <path key={`${connector.sourceId}-${connector.targetId}`} d={connector.path}/>)}</svg>{layout.nodes.map((node) => { const fixture = fixturesById.get(node.id)!; const rows = matchRows(fixture); const card = <article className="bracket-match source-bracket-match"><small>{[matchLabel(fixture), localized(fixture, "round", locale)].filter(Boolean).join(" · ") || t.updating}</small><div className="bracket-teams">{rows.map(({ row, entry, label }, index) => <div className={`bracket-team${entry?.id === fixture.winner_entry_id ? " winner" : ""}`} key={row?.id ?? index}><span>{label}</span><b>{row?.score ?? "—"}</b></div>)}</div></article>;
          return <div className="source-bracket-node" style={{ left: node.x, top: node.y }} key={node.id}>{adminHref ? <Link href={`${adminHref}&edit=fixture-result:${fixture.id}#fixture-${fixture.id}`}>{card}</Link> : card}</div>;
        })}</ZoomableBracket>;
      })()}
      {tournament.competition_mode === "group_knockout" && table(tournament, tournamentGroups)}
      {(tournament.competition_mode === "round_robin" || tournament.competition_mode === "swiss") && <>{table(tournament, tournamentGroups)}{matchesTable(tournamentFixtures)}</>}
      {tournament.competition_mode === "race" && <div className="panel table-scroll board-race"><table><thead><tr><th>{t.rank}</th><th>{t.court}</th><th>{t.teams}</th><th>{locale === "vi" ? "Thành tích" : "Performance"}</th><th>{locale === "vi" ? "Trạng thái" : "Status"}</th></tr></thead><tbody>{tournamentFixtures.flatMap((fixture) => (fixtureRows.get(fixture.id) ?? []).sort((a, b) => (a.lane ?? a.seed_order ?? 999) - (b.lane ?? b.seed_order ?? 999))).map((row) => <tr key={row.id}><td>{row.rank ?? "—"}</td><td>{row.lane ?? "—"}</td><td>{entryName(row.entry_id)}</td><td>{row.score ?? row.score_numeric ?? "—"}</td><td>{row.result_status?.toUpperCase() ?? t.updating}</td></tr>)}</tbody></table></div>}
      {!tournamentFixtures.length && !tournamentGroups.length && <div className="panel board-empty">{t.empty}</div>}
    </section>;
  })}</div></div>;
}
