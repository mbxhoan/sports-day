"use client";

import { useCallback, useMemo, useState } from "react";
import { CalendarDays, Clock3, GitBranch, MapPin, Printer } from "lucide-react";
import { fixtureSides, groupBy } from "@/lib/brackets";
import { formatMatchResult, normalizeLegacyMatchResult } from "@/lib/competition-display";
import { copy, localized, type Court, type Entry, type Fixture, type FixtureEntry, type FixtureSlot, type Group, type GroupEntry, type Locale, type Sport, type Standing, type Tournament, type Venue } from "@/lib/site";
import { formatVietnamDateTime } from "@/lib/datetime";
import { buildSearchSuggestions, matchesSearch } from "@/lib/search";
import { CompetitionBoard } from "./competition-board";
import { SearchCombobox } from "./search-combobox";

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
  participants?: Array<{ id: string; full_name: string }>;
  entryMembers?: Array<{ entry_id: string; participant_id: string }>;
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

export function ScheduleView({ locale, sports, tournaments, entries, groups = [], groupEntries = [], fixtures, fixtureEntries, fixtureSlots = [], standings = [], venues = [], courts = [], participants = [], entryMembers = [], sportId, defaultVenue }: Props) {
  const t = copy[locale];
  const [selectedSport, setSelectedSport] = useState(sportId ?? "all");
  const [selectedTournament, setSelectedTournament] = useState("all");
  const [status, setStatus] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");
  const [mode, setMode] = useState<"calendar" | "board">("calendar");
  const tournamentsById = useMemo(() => new Map(tournaments.map((item) => [item.id, item])), [tournaments]);
  const sportsById = useMemo(() => new Map(sports.map((item) => [item.id, item])), [sports]);
  const entriesById = useMemo(() => new Map(entries.map((item) => [item.id, item])), [entries]);
  const entriesByTournament = useMemo(() => groupBy(entries, (item) => item.tournament_id), [entries]);
  const groupsById = useMemo(() => new Map(groups.map((item) => [item.id, item])), [groups]);
  const venuesById = useMemo(() => new Map(venues.map((item) => [item.id, item])), [venues]);
  const courtsById = useMemo(() => new Map(courts.map((item) => [item.id, item])), [courts]);
  const participantsById = useMemo(() => new Map(participants.map((item) => [item.id, item])), [participants]);
  const membersByEntryId = useMemo(() => {
    const rows = new Map<string, string[]>();
    for (const item of entryMembers) rows.set(item.entry_id, [...(rows.get(item.entry_id) ?? []), item.participant_id]);
    return rows;
  }, [entryMembers]);
  const fixtureEntriesById = useMemo(() => {
    const rows = new Map<string, FixtureEntry[]>();
    for (const item of fixtureEntries) rows.set(item.fixture_id, [...(rows.get(item.fixture_id) ?? []), item]);
    return rows;
  }, [fixtureEntries]);
  const fixtureSearchText = useCallback((fixture: Fixture) => {
    const teamNames = (fixtureEntriesById.get(fixture.id) ?? []).flatMap((item) => {
      const entry = entriesById.get(item.entry_id);
      const members = (membersByEntryId.get(item.entry_id) ?? []).map((id) => participantsById.get(id)?.full_name ?? "");
      return [entry ? localized(entry, "name", locale) : "", ...members];
    });
    const tournament = tournamentsById.get(fixture.tournament_id);
    const sport = tournament ? sportsById.get(tournament.sport_id) : undefined;
    return [localized(sport ?? {}, "name", locale), localized(tournament ?? {}, "name", locale), ...teamNames, localized(fixture, "round", locale), localized(fixture, "result_summary", locale)].filter(Boolean).join(" ");
  }, [entriesById, fixtureEntriesById, membersByEntryId, participantsById, sportsById, tournamentsById, locale]);
  const searchSuggestions = useMemo(() => buildSearchSuggestions({
    tournaments: tournaments.map((item) => ({ id: item.id, name: localized(item, "name", locale), detail: t.categories })),
    participants: participants.map((item) => ({ id: item.id, full_name: item.full_name })),
    entries: entries.map((item) => ({ id: item.id, name: localized(item, "name", locale), tournament: localized(tournamentsById.get(item.tournament_id) ?? {}, "name", locale) })),
    fixtures: fixtures.map((item) => ({ id: item.id, label: localized(item, "round", locale) || t.match, detail: fixtureSearchText(item) })),
  }), [entries, fixtures, locale, participants, t.categories, t.match, tournaments, tournamentsById, fixtureSearchText]);
  const visibleFixtures = useMemo(() => fixtures, [fixtures]);
  const availableSports = useMemo(() => sports, [sports]);
  const availableTournaments = useMemo(() => tournaments.filter((item) => (!sportId || item.sport_id === sportId) && (selectedSport === "all" || item.sport_id === selectedSport)), [tournaments, sportId, selectedSport]);
  const filtered = useMemo(() => visibleFixtures.filter((fixture) => {
    const tournament = tournamentsById.get(fixture.tournament_id);
    return (!sportId || tournament?.sport_id === sportId) && (selectedSport === "all" || tournament?.sport_id === selectedSport) && (selectedTournament === "all" || fixture.tournament_id === selectedTournament) && (status === "all" || fixture.status === status) && matchesSearch(fixtureSearchText(fixture), searchTerm);
  }).sort((a, b) => a.starts_at && b.starts_at ? Date.parse(a.starts_at) - Date.parse(b.starts_at) : a.starts_at ? -1 : b.starts_at ? 1 : 0), [visibleFixtures, sportId, selectedSport, selectedTournament, status, searchTerm, tournamentsById, fixtureSearchText]);
  const byDay = useMemo(() => groupBy(filtered, (fixture) => dayLabel(fixture.starts_at, locale, t.updating)), [filtered, locale, t.updating]);
  const statusText = (value: string) => statusKeys.includes(value as typeof statusKeys[number]) ? t[value as typeof statusKeys[number]] : value;
  const matchScores = (fixture: Fixture) => {
    const scores = fixtureSides(fixtureEntriesById.get(fixture.id) ?? []).map((item) => item?.score || (item?.score_numeric == null ? "" : String(item.score_numeric)));
    return scores.some(Boolean) ? scores.join(" : ") : "";
  };
  const matchResult = (fixture: Fixture, summary: string) => {
    const sides = fixtureSides(fixtureEntriesById.get(fixture.id) ?? []);
    const names = sides.map((item) => item ? localized(entriesById.get(item.entry_id) ?? {}, "name", locale) : "");
    const scores = sides.map((item) => item?.score || (item?.score_numeric == null ? "" : String(item.score_numeric)));
    return formatMatchResult(names[0], scores[0], scores[1], names[1]) || normalizeLegacyMatchResult(summary, names[0], names[1]);
  };
  const matchNames = (fixture: Fixture) => fixtureSides(fixtureEntriesById.get(fixture.id) ?? []).map((item) => {
    if (!item) return "";
    const entry = entriesById.get(item.entry_id);
    const score = item.score || (item.score_numeric == null ? "" : String(item.score_numeric));
    return entry ? `${localized(entry, "name", locale)}${score ? ` (${score})` : ""}` : "";
  }).filter(Boolean).join(" — ");

  return <>
    <div className="schedule-toolbar no-print">
      <SearchCombobox label={t.searchLabel} hideLabel placeholder={t.searchPlaceholder} suggestions={searchSuggestions} value={searchTerm} onChange={setSearchTerm} onSelect={(suggestion) => { setSearchTerm(suggestion.label); if (suggestion.kind === "tournament") setSelectedTournament(suggestion.id); }}/>
      {!sportId && <select value={selectedSport} onChange={(event) => { setSelectedSport(event.target.value); setSelectedTournament("all"); }} aria-label={t.filterSport}><option value="all">{t.filterSport}</option>{availableSports.map((item) => <option key={item.id} value={item.id}>{localized(item, "name", locale)}</option>)}</select>}
      <select value={selectedTournament} onChange={(event) => setSelectedTournament(event.target.value)} aria-label={t.filterCategory}><option value="all">{t.filterCategory}</option>{availableTournaments.map((item) => <option key={item.id} value={item.id}>{localized(item, "name", locale)} ({entriesByTournament.get(item.id)?.length ?? 0} {locale === "vi" ? "đội/VĐV" : "teams/athletes"})</option>)}</select>
      <select value={status} onChange={(event) => setStatus(event.target.value)} aria-label={t.filterStatus}><option value="all">{t.filterStatus}</option>{statusKeys.map((key) => <option key={key} value={key}>{t[key]}</option>)}</select>
      <div className="segmented"><button className={mode === "calendar" ? "active" : ""} onClick={() => setMode("calendar")}><CalendarDays size={16}/>{t.calendar}</button><button className={mode === "board" ? "active" : ""} onClick={() => setMode("board")}><GitBranch size={16}/>{t.board}</button></div>
      <button className="gold-button" onClick={() => window.print()}><Printer size={16}/>{t.print}</button>
    </div>
    {!sportId && <div className="schedule-sport-pills no-print"><button className={selectedSport === "all" ? "active" : ""} onClick={() => { setSelectedSport("all"); setSelectedTournament("all"); }}>{t.allSports}</button>{availableSports.map((item) => <button key={item.id} className={selectedSport === item.id ? "active" : ""} onClick={() => { setSelectedSport(item.id); setSelectedTournament("all"); }}>{localized(item, "name", locale)}</button>)}</div>}
    {mode === "board" ? <CompetitionBoard locale={locale} tournaments={availableTournaments.filter((item) => selectedTournament === "all" || item.id === selectedTournament)} entries={entries} groups={groups} groupEntries={groupEntries} fixtures={filtered} fixtureEntries={fixtureEntries} fixtureSlots={fixtureSlots} standings={standings}/> : byDay.size ? <div className="schedule-days">{[...byDay].map(([day, dayFixtures]) => <section className="panel schedule-day" key={day}>
      <h2 className="schedule-day-title"><CalendarDays size={17}/>{day}<small>{dayFixtures.length} {t.fixtureUnit}</small></h2>
      <div className="table-scroll"><table><thead><tr><th>{t.time}</th><th>{t.sports}</th><th>{t.categories}</th><th>{t.match}</th><th>{t.round}</th><th>{t.venue}</th><th>{t.court}</th><th>{t.result}</th></tr></thead><tbody>{dayFixtures.map((fixture) => {
        const tournament = tournamentsById.get(fixture.tournament_id);
        const sport = tournament ? sportsById.get(tournament.sport_id) : undefined;
        const venue = fixture.venue_id ? venuesById.get(fixture.venue_id) : undefined;
        const court = fixture.court_id ? courtsById.get(fixture.court_id) : undefined;
        const group = fixture.group_id ? groupsById.get(fixture.group_id) : undefined;
        const result = localized(fixture, "result_summary", locale);
        const score = matchScores(fixture);
        const resultLabel = matchResult(fixture, result);
        const teams = matchNames(fixture);
        return <tr key={fixture.id}><td><time className="schedule-time"><Clock3 size={14}/>{timeLabel(fixture.starts_at, locale)}</time></td><td>{sport ? localized(sport, "name", locale) : "—"}</td><td>{tournament ? localized(tournament, "name", locale) : "—"}</td><td className="schedule-match"><b>{teams || t.teamsNotAssigned}</b>{group ? <small>{localized(group, "name", locale)}</small> : !teams && <small>{t.teamsNotAssigned}</small>}</td><td>{localized(fixture, "round", locale) || t.updating}</td><td className="schedule-venue">{venue ? <><b><MapPin size={13}/>{localized(venue, "name", locale)}</b><small>{localized(venue, "address", locale)}</small></> : defaultVenue || "—"}</td><td>{court ? localized(court, "name", locale) : "—"}</td><td><span className={`status ${fixture.status}`}>{resultLabel || result || score || statusText(fixture.status)}</span></td></tr>;
      })}</tbody></table></div>
    </section>)}</div> : <section className="panel empty-state"><CalendarDays/><h2>{t.empty}</h2></section>}
  </>;
}
