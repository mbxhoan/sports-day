"use client";

import { useMemo, useState } from "react";
import { CalendarDays, Clock3, GitBranch, MapPin, Printer } from "lucide-react";
import { copy, localized, type Court, type Entry, type Fixture, type FixtureEntry, type FixtureSlot, type Group, type GroupEntry, type Locale, type Sport, type Standing, type Tournament, type Venue } from "@/lib/site";
import { formatVietnamDateTime } from "@/lib/datetime";
import { CompetitionBoard } from "./competition-board";

type Props = {
  locale: Locale;
  sports: Sport[];
  tournaments: Tournament[];
  entries: Entry[];
  groups?: Group[];
  groupEntries?: GroupEntry[];
  fixtures: Fixture[];
  fixtureEntries: FixtureEntry[];
  fixtureSlots?: FixtureSlot[];
  standings?: Standing[];
  venues?: Venue[];
  courts?: Court[];
  sportId?: string;
  defaultVenue?: string;
};

const statusKeys = ["scheduled", "live", "completed", "postponed", "cancelled"] as const;

function dayLabel(value: string | null, locale: Locale, updating: string) {
  if (!value) return updating;
  const formatted = formatVietnamDateTime(value, locale);
  return formatted.slice(0, formatted.lastIndexOf(" ")) || updating;
}

function timeLabel(value: string | null, locale: Locale) {
  if (!value) return "—";
  const formatted = formatVietnamDateTime(value, locale);
  return formatted.slice(-5) || "—";
}

export function ScheduleView({ locale, sports, tournaments, entries, groups = [], groupEntries = [], fixtures, fixtureEntries, fixtureSlots = [], standings = [], venues = [], courts = [], sportId, defaultVenue }: Props) {
  const t = copy[locale];
  const [selectedSport, setSelectedSport] = useState(sportId ?? "all");
  const [selectedTournament, setSelectedTournament] = useState("all");
  const [status, setStatus] = useState("all");
  const [mode, setMode] = useState<"calendar" | "board">("calendar");
  const tournamentsById = useMemo(() => new Map(tournaments.map((item) => [item.id, item])), [tournaments]);
  const sportsById = useMemo(() => new Map(sports.map((item) => [item.id, item])), [sports]);
  const entriesById = useMemo(() => new Map(entries.map((item) => [item.id, item])), [entries]);
  const groupsById = useMemo(() => new Map(groups.map((item) => [item.id, item])), [groups]);
  const venuesById = useMemo(() => new Map(venues.map((item) => [item.id, item])), [venues]);
  const courtsById = useMemo(() => new Map(courts.map((item) => [item.id, item])), [courts]);
  const fixtureEntriesById = useMemo(() => {
    const rows = new Map<string, FixtureEntry[]>();
    for (const item of fixtureEntries) rows.set(item.fixture_id, [...(rows.get(item.fixture_id) ?? []), item]);
    return rows;
  }, [fixtureEntries]);
  const availableTournaments = useMemo(() => tournaments.filter((item) => (!sportId || item.sport_id === sportId) && (selectedSport === "all" || item.sport_id === selectedSport)), [tournaments, sportId, selectedSport]);
  const filtered = useMemo(() => fixtures.filter((fixture) => {
    const tournament = tournamentsById.get(fixture.tournament_id);
    return (!sportId || tournament?.sport_id === sportId) && (selectedSport === "all" || tournament?.sport_id === selectedSport) && (selectedTournament === "all" || fixture.tournament_id === selectedTournament) && (status === "all" || fixture.status === status);
  }).sort((a, b) => a.starts_at && b.starts_at ? Date.parse(a.starts_at) - Date.parse(b.starts_at) : a.starts_at ? -1 : b.starts_at ? 1 : 0), [fixtures, sportId, selectedSport, selectedTournament, status, tournamentsById]);
  const byDay = useMemo(() => Map.groupBy(filtered, (fixture) => dayLabel(fixture.starts_at, locale, t.updating)), [filtered, locale, t.updating]);
  const statusText = (value: string) => statusKeys.includes(value as typeof statusKeys[number]) ? t[value as typeof statusKeys[number]] : value;
  const matchNames = (fixture: Fixture) => (fixtureEntriesById.get(fixture.id) ?? []).map((item) => {
    const entry = entriesById.get(item.entry_id);
    return entry ? `${localized(entry, "name", locale)}${item.score ? ` (${item.score})` : ""}` : "";
  }).filter(Boolean).join(" — ");

  return <>
    <div className="schedule-toolbar no-print">
      {!sportId && <select value={selectedSport} onChange={(event) => { setSelectedSport(event.target.value); setSelectedTournament("all"); }} aria-label={t.filterSport}><option value="all">{t.filterSport}</option>{sports.map((item) => <option key={item.id} value={item.id}>{localized(item, "name", locale)}</option>)}</select>}
      <select value={selectedTournament} onChange={(event) => setSelectedTournament(event.target.value)} aria-label={t.filterCategory}><option value="all">{t.filterCategory}</option>{availableTournaments.map((item) => <option key={item.id} value={item.id}>{localized(item, "name", locale)}</option>)}</select>
      <select value={status} onChange={(event) => setStatus(event.target.value)} aria-label={t.filterStatus}><option value="all">{t.filterStatus}</option>{statusKeys.map((key) => <option key={key} value={key}>{t[key]}</option>)}</select>
      <div className="segmented"><button className={mode === "calendar" ? "active" : ""} onClick={() => setMode("calendar")}><CalendarDays size={16}/>{t.calendar}</button><button className={mode === "board" ? "active" : ""} onClick={() => setMode("board")}><GitBranch size={16}/>{t.board}</button></div>
      <button className="gold-button" onClick={() => window.print()}><Printer size={16}/>{t.print}</button>
    </div>
    {!sportId && <div className="schedule-sport-pills no-print"><button className={selectedSport === "all" ? "active" : ""} onClick={() => { setSelectedSport("all"); setSelectedTournament("all"); }}>{t.allSports}</button>{sports.map((item) => <button key={item.id} className={selectedSport === item.id ? "active" : ""} onClick={() => { setSelectedSport(item.id); setSelectedTournament("all"); }}>{localized(item, "name", locale)}</button>)}</div>}
    {mode === "board" ? <CompetitionBoard locale={locale} tournaments={availableTournaments.filter((item) => selectedTournament === "all" || item.id === selectedTournament)} entries={entries} groups={groups} groupEntries={groupEntries} fixtures={filtered} fixtureEntries={fixtureEntries} fixtureSlots={fixtureSlots} standings={standings}/> : byDay.size ? <div className="schedule-days">{[...byDay].map(([day, dayFixtures]) => <section className="panel schedule-day" key={day}>
      <h2 className="schedule-day-title"><CalendarDays size={17}/>{day}<small>{dayFixtures.length} {t.fixtureUnit}</small></h2>
      <div className="table-scroll"><table><thead><tr><th>{t.time}</th><th>{t.sports}</th><th>{t.categories}</th><th>{t.match}</th><th>{t.round}</th><th>{t.venue}</th><th>{t.court}</th><th>{t.result}</th></tr></thead><tbody>{dayFixtures.map((fixture) => {
        const tournament = tournamentsById.get(fixture.tournament_id);
        const sport = tournament ? sportsById.get(tournament.sport_id) : undefined;
        const venue = fixture.venue_id ? venuesById.get(fixture.venue_id) : undefined;
        const court = fixture.court_id ? courtsById.get(fixture.court_id) : undefined;
        const group = fixture.group_id ? groupsById.get(fixture.group_id) : undefined;
        const result = localized(fixture, "result_summary", locale);
        const teams = matchNames(fixture);
        return <tr key={fixture.id}><td><time className="schedule-time"><Clock3 size={14}/>{timeLabel(fixture.starts_at, locale)}</time></td><td>{sport ? localized(sport, "name", locale) : "—"}</td><td>{tournament ? localized(tournament, "name", locale) : "—"}</td><td className="schedule-match"><b>{teams || t.teamsNotAssigned}</b>{group ? <small>{localized(group, "name", locale)}</small> : !teams && <small>{t.teamsNotAssigned}</small>}</td><td>{localized(fixture, "round", locale) || t.updating}</td><td className="schedule-venue">{venue ? <><b><MapPin size={13}/>{localized(venue, "name", locale)}</b><small>{localized(venue, "address", locale)}</small></> : defaultVenue || "—"}</td><td>{court ? localized(court, "name", locale) : "—"}</td><td><span className={`status ${fixture.status}`}>{fixture.status === "completed" && result ? result : statusText(fixture.status)}</span></td></tr>;
      })}</tbody></table></div>
    </section>)}</div> : <section className="panel empty-state"><CalendarDays/><h2>{t.empty}</h2></section>}
  </>;
}
