import Link from "next/link";
import { CalendarDays, Clock3, GitBranch, Info, MapPin, Trophy, Users } from "lucide-react";
import type { ComponentType } from "react";
import {
  copy, localized, type Entry, type EntryMember, type Fixture, type FixtureEntry, type FixtureSlot,
  type Group, type GroupEntry, type Locale, type Organization, type Participant,
  type Sport, type Standing, type Tournament, type Venue, type Court,
} from "@/lib/site";
import { formatVietnamDateTime } from "@/lib/datetime";
import { groupBy } from "@/lib/brackets";
import { ScheduleView } from "./schedule-view";
import { CompetitionBoard } from "./competition-board";

type Props = {
  locale: Locale;
  sport: Sport;
  venue: string;
  active: TabKey;
  hrefBase: string;
  tournaments: Tournament[];
  organizations: Organization[];
  participants: Participant[];
  entries: Entry[];
  entryMembers: EntryMember[];
  groups: Group[];
  groupEntries: GroupEntry[];
  fixtures: Fixture[];
  fixtureEntries: FixtureEntry[];
  fixtureSlots: FixtureSlot[];
  standings: Standing[];
  venues: Venue[];
  courts: Court[];
};

export type TabKey = "info" | "teams" | "times" | "fixtures" | "brackets";
type SportTab = [TabKey, string, ComponentType<{ size?: number }>];

export function SportTabs({ locale, sport, venue, active, hrefBase, tournaments, organizations, participants, entries, entryMembers, groups, groupEntries, fixtures, fixtureEntries, fixtureSlots, standings, venues, courts }: Props) {
  const t = copy[locale];
  const tournamentIds = new Set(tournaments.map((item) => item.id));
  const sportFixtures = fixtures.filter((fixture) => tournamentIds.has(fixture.tournament_id));
  const sportEntries = entries.filter((entry) => tournamentIds.has(entry.tournament_id));
  const sportGroups = groups.filter((group) => tournamentIds.has(group.tournament_id));
  const organizationsById = new Map(organizations.map((item) => [item.id, item]));
  const participantsById = new Map(participants.map((item) => [item.id, item]));
  const tournamentsById = new Map(tournaments.map((item) => [item.id, item]));
  const membersByEntryId = new Map<string, EntryMember[]>();
  for (const item of entryMembers) membersByEntryId.set(item.entry_id, [...(membersByEntryId.get(item.entry_id) ?? []), item]);

  const date = (value: string | null) => value ? formatVietnamDateTime(value, locale) : t.updating;
  const dateParts = (value: string | null) => {
    if (!value) return { day: t.updating, time: "—" };
    const formatted = date(value);
    const split = formatted.lastIndexOf(" ");
    return split < 0 ? { day: formatted, time: "" } : { day: formatted.slice(0, split), time: formatted.slice(split + 1) };
  };
  const formats = [...new Set(tournaments.map((item) => localized(item, "format", locale)).filter(Boolean))];
  const datedFixtures = sportFixtures.filter((item) => item.starts_at).sort((a, b) => Date.parse(a.starts_at!) - Date.parse(b.starts_at!));
  const competitionDays = [...new Set(datedFixtures.map((item) => dateParts(item.starts_at).day))];
  const summaryDates = competitionDays.length > 2 ? `${competitionDays[0]} – ${competitionDays.at(-1)}` : competitionDays.join(" & ");
  const sportRules = localized(sport, "rules", locale);
  const tournamentRules = tournaments.find((item) => localized(item, "rules", locale))?.[locale === "en" ? "rules_en" : "rules_vi"] ?? "";
  const tabs: SportTab[] = [
    ["info", t.info, Info],
    ["teams", `${t.teams} (${sportEntries.length})`, Users],
    ["times", t.times, CalendarDays], ["fixtures", `${t.fixtures} (${sportFixtures.length})`, Clock3],
    ["brackets", t.brackets, GitBranch],
  ];
  const timeSlots = [...new Map(datedFixtures.map((fixture) => [`${fixture.tournament_id}|${fixture.starts_at}|${localized(fixture, "round", locale)}`, fixture])).values()];
  const slotsByDay = groupBy(timeSlots, (fixture) => dateParts(fixture.starts_at).day);

  return <>
    <div className="sport-summary" aria-label={t.details}>
      <span><Trophy size={15}/>{formats.join(" · ") || t.updating}</span>
      <span><Users size={15}/>{sportEntries.length} {t.teams.toLocaleLowerCase()}</span>
      <span><CalendarDays size={15}/>{summaryDates || t.updating}</span>
    </div>
    {active === "brackets" && <div className="bracket-overview" aria-label={`${t.fixtures} / ${t.categories}`}>
      <Link className="bracket-schedule-link" href={`${hrefBase}?tab=fixtures`}><CalendarDays size={15}/>{t.fixtures}</Link>
      <span className="bracket-overview-label">{t.categories} · {locale === "vi" ? "Chọn một hạng mục trong bảng" : "Choose one category in the board"}</span>
    </div>}
    <div className="tabs sport-tabs" role="tablist" aria-label={localized(sport, "name", locale)}>
      {tabs.map(([key,label,Icon]) => <Link key={key} href={key === "info" ? hrefBase : `${hrefBase}?tab=${key}`} className={active === key ? "active" : ""} role="tab" aria-selected={active === key} scroll={false}><Icon size={16}/>{label}</Link>)}
    </div>

    {active === "info" && <div className="sport-info-layout">
      <div className="stack">
        <section className="panel sport-description"><h2>{t.description}</h2><p>{localized(sport, "description", locale) || t.updating}</p></section>
        <section className="panel prose sport-rules"><h2>{t.rules}</h2><p>{sportRules || tournamentRules || t.updating}</p></section>
      </div>
      <aside className="stack">
        <section className="panel sport-detail-panel"><h2>{t.details}</h2><dl>
          <div><dt>{t.format}</dt><dd>{formats.join("; ") || t.updating}</dd></div>
          <div><dt>{t.categories}</dt><dd>{tournaments.length}</dd></div>
          <div><dt>{t.teams}</dt><dd>{sportEntries.length}</dd></div>
          <div><dt>{t.competitionDay}</dt><dd>{competitionDays.length || t.updating}</dd></div>
        </dl></section>
        <section className="panel venue-panel"><h2><MapPin size={17}/>{t.venue}</h2><p>{venue || t.updating}</p></section>
        <section className="panel category-panel"><h2>{t.categories}</h2><div className="category-list">{tournaments.map((tournament) => <div key={tournament.id}><b>{localized(tournament, "name", locale)}</b><span>{localized(tournament, "format", locale) || t.updating}</span></div>)}</div></section>
      </aside>
    </div>}

    {active === "teams" && (sportEntries.length ? <section className="entry-grid">{sportEntries.map((entry, index) => {
      const memberNames = (membersByEntryId.get(entry.id) ?? []).map((item) => participantsById.get(item.participant_id)?.full_name).filter(Boolean);
      const organization = entry.organization_id ? organizationsById.get(entry.organization_id) : undefined;
      return <article className="entry-card" key={entry.id}>
        <div><span className="entry-number">{index + 1}</span><b>{localized(entry,"name",locale)}</b><small><Users size={14}/>{memberNames.length}</small></div>
        <p>{localized(tournamentsById.get(entry.tournament_id) ?? {},"name",locale)}</p>
        {memberNames.length > 0 && <span>{memberNames.join(" · ")}</span>}
        <small>{organization ? localized(organization,"name",locale) : `${t.organization}: ${t.updating}`}</small>
      </article>;
    })}</section> : <section className="panel empty-state"><Users/><h2>{t.empty}</h2></section>)}

    {active === "times" && (slotsByDay.size ? <div className="stack">{[...slotsByDay].map(([day, dayFixtures]) => <section className="panel time-panel" key={day}>
      <h2><CalendarDays size={16}/>{day}</h2>
      <div className="time-slot-list">{dayFixtures.map((fixture) => <article key={`${fixture.id}-${fixture.starts_at}`}>
        <time>{dateParts(fixture.starts_at).time}</time>
        <div><b>{localized(tournamentsById.get(fixture.tournament_id) ?? {},"name",locale)}</b><span>{localized(fixture,"round",locale) || t.updating}</span></div>
      </article>)}</div>
    </section>)}</div> : <section className="panel empty-state"><CalendarDays/><h2>{t.empty}</h2></section>)}

    {active === "fixtures" && <ScheduleView locale={locale} sports={[sport]} sportId={sport.id} tournaments={tournaments} entries={entries} groups={groups} groupEntries={groupEntries} fixtures={fixtures} fixtureEntries={fixtureEntries} fixtureSlots={fixtureSlots} standings={standings} venues={venues} courts={courts} participants={participants} entryMembers={entryMembers} defaultVenue={venue}/>}

    {active === "brackets" && <CompetitionBoard locale={locale} tournaments={tournaments} entries={entries} groups={sportGroups} groupEntries={groupEntries} fixtures={sportFixtures} fixtureEntries={fixtureEntries} fixtureSlots={fixtureSlots} standings={standings}/>}
  </>;
}
