"use client";

import { useMemo, useState } from "react";
import { CalendarDays, Printer, Users } from "lucide-react";
import { copy, localized, type Entry, type Fixture, type FixtureEntry, type Locale, type Sport, type Tournament } from "@/lib/site";
import { formatVietnamDateTime } from "@/lib/datetime";

export function ScheduleView({ locale, sports, tournaments, entries, fixtures, fixtureEntries }: { locale: Locale; sports: Sport[]; tournaments: Tournament[]; entries: Entry[]; fixtures: Fixture[]; fixtureEntries: FixtureEntry[] }) {
  const t = copy[locale];
  const [sport, setSport] = useState("all");
  const [status, setStatus] = useState("all");
  const [mode, setMode] = useState<"calendar" | "team">("calendar");
  const tournamentsById = useMemo(() => new Map(tournaments.map((item) => [item.id, item])), [tournaments]);
  const sportsById = useMemo(() => new Map(sports.map((item) => [item.id, item])), [sports]);
  const entriesById = useMemo(() => new Map(entries.map((item) => [item.id, item])), [entries]);
  const fixtureEntriesById = useMemo(() => {
    const rows = new Map<string, FixtureEntry[]>();
    for (const item of fixtureEntries) rows.set(item.fixture_id, [...(rows.get(item.fixture_id) ?? []), item]);
    return rows;
  }, [fixtureEntries]);
  const filtered = useMemo(() => fixtures.filter((fixture) => {
    const tournament = tournamentsById.get(fixture.tournament_id);
    return (sport === "all" || tournament?.sport_id === sport) && (status === "all" || fixture.status === status);
  }), [fixtures, sport, status, tournamentsById]);
  return <>
    <div className="schedule-toolbar no-print">
      <select value={sport} onChange={(event) => setSport(event.target.value)} aria-label={t.filterSport}><option value="all">{t.filterSport}</option>{sports.map((item) => <option key={item.id} value={item.id}>{localized(item,"name",locale)}</option>)}</select>
      <select value={status} onChange={(event) => setStatus(event.target.value)} aria-label={t.filterStatus}><option value="all">{t.filterStatus}</option><option value="scheduled">{t.scheduled}</option><option value="live">{t.live}</option><option value="completed">{t.completed}</option><option value="postponed">{t.postponed}</option><option value="cancelled">{t.cancelled}</option></select>
      <div className="segmented"><button className={mode === "calendar" ? "active" : ""} onClick={() => setMode("calendar")}><CalendarDays size={16}/>{t.calendar}</button><button className={mode === "team" ? "active" : ""} onClick={() => setMode("team")}><Users size={16}/>{t.byTeam}</button></div>
      <button className="gold-button" onClick={() => window.print()}><Printer size={16}/>{t.print}</button>
    </div>
    <section className="panel table-scroll schedule-table"><table><thead><tr><th>{t.competitionDay}</th><th>{t.sports}</th><th>{t.categories}</th><th>{mode === "team" ? t.teams : t.details}</th></tr></thead><tbody>{filtered.length ? filtered.map((fixture) => { const tournament = tournamentsById.get(fixture.tournament_id); const sportItem = tournament ? sportsById.get(tournament.sport_id) : undefined; const teamNames = (fixtureEntriesById.get(fixture.id) ?? []).map((item) => entriesById.get(item.entry_id)).filter(Boolean).map((item) => localized(item!, "name", locale)).join(" — "); return <tr key={fixture.id}><td>{fixture.starts_at ? formatVietnamDateTime(fixture.starts_at, locale) : t.updating}</td><td>{sportItem ? localized(sportItem,"name",locale) : ""}</td><td>{tournament ? localized(tournament,"name",locale) : ""}</td><td>{mode === "team" ? teamNames || t.updating : <span className={`status ${fixture.status}`}>{t[fixture.status as "scheduled" | "live" | "completed" | "postponed" | "cancelled"] ?? fixture.status}</span>}</td></tr>; }) : <tr><td colSpan={4}>{t.empty}</td></tr>}</tbody></table></section>
  </>;
}
