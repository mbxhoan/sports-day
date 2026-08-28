"use client";

import { useState } from "react";
import { CalendarDays, Clock3, GitBranch, Info, Users } from "lucide-react";
import {
  copy, localized, type Entry, type EntryMember, type Fixture, type FixtureEntry,
  type Group, type GroupEntry, type Locale, type Organization, type Participant,
  type Sport, type Standing, type Tournament,
} from "@/lib/site";
import { formatVietnamDateTime } from "@/lib/datetime";

type Props = {
  locale: Locale;
  sport: Sport;
  tournaments: Tournament[];
  organizations: Organization[];
  participants: Participant[];
  entries: Entry[];
  entryMembers: EntryMember[];
  groups: Group[];
  groupEntries: GroupEntry[];
  fixtures: Fixture[];
  fixtureEntries: FixtureEntry[];
  standings: Standing[];
};

export function SportTabs({ locale, sport, tournaments, organizations, participants, entries, entryMembers, groups, groupEntries, fixtures, fixtureEntries, standings }: Props) {
  const t = copy[locale];
  const tabs = [["info",t.info,Info],["teams",t.teams,Users],["times",t.times,CalendarDays],["fixtures",t.fixtures,Clock3],["brackets",t.brackets,GitBranch]] as const;
  const [active, setActive] = useState<(typeof tabs)[number][0]>("info");
  const tournamentIds = new Set(tournaments.map((item) => item.id));
  const sportFixtures = fixtures.filter((fixture) => tournamentIds.has(fixture.tournament_id));
  const sportEntries = entries.filter((entry) => tournamentIds.has(entry.tournament_id));
  const sportGroups = groups.filter((group) => tournamentIds.has(group.tournament_id));
  const organizationsById = new Map(organizations.map((item) => [item.id, item]));
  const participantsById = new Map(participants.map((item) => [item.id, item]));
  const entriesById = new Map(entries.map((item) => [item.id, item]));
  const tournamentsById = new Map(tournaments.map((item) => [item.id, item]));
  const date = (value: string | null) => value ? formatVietnamDateTime(value, locale) : t.updating;
  const entryNames = (fixtureId: string) => fixtureEntries.filter((item) => item.fixture_id === fixtureId).map((item) => entriesById.get(item.entry_id)).filter(Boolean).map((item) => localized(item!, "name", locale)).join(" — ");
  const sportRules = localized(sport, "rules", locale);
  const tournamentRules = tournaments.find((item) => localized(item, "rules", locale))?.[locale === "en" ? "rules_en" : "rules_vi"] ?? "";

  return <>
    <div className="tabs" role="tablist" aria-label={localized(sport, "name", locale)}>
      {tabs.map(([key,label,Icon]) => <button key={key} className={active === key ? "active" : ""} onClick={() => setActive(key)} role="tab" aria-selected={active === key}><Icon size={16}/>{label}</button>)}
    </div>
    {active === "info" && <div className="sport-info-layout">
      <div className="stack">
        <section className="panel"><h2>{t.description}</h2><p>{localized(sport, "description", locale)}</p></section>
        <section className="panel prose"><h2>{t.rules}</h2><p>{sportRules || tournamentRules || t.updating}</p></section>
      </div>
      <aside className="stack"><section className="panel"><h2>{t.details}</h2><dl><div><dt>{t.format}</dt><dd>{tournaments[0] ? localized(tournaments[0], "format", locale) : t.updating}</dd></div><div><dt>{t.categories}</dt><dd>{tournaments.length}</dd></div></dl><div className="detail-categories">{tournaments.map((tournament) => <span key={tournament.id}>{localized(tournament, "name", locale)}</span>)}</div></section></aside>
    </div>}
    {active === "teams" && (sportEntries.length ? <section className="panel table-scroll"><table><thead><tr><th>{t.teams}</th><th>{t.categories}</th><th>{t.organization}</th><th>{t.members}</th></tr></thead><tbody>{sportEntries.map((entry) => {
      const members = entryMembers.filter((item) => item.entry_id === entry.id).map((item) => participantsById.get(item.participant_id)?.full_name).filter(Boolean).join(", ");
      return <tr key={entry.id}><td>{localized(entry,"name",locale)}</td><td>{localized(tournamentsById.get(entry.tournament_id) ?? {},"name",locale)}</td><td>{entry.organization_id ? localized(organizationsById.get(entry.organization_id) ?? {},"name",locale) : ""}</td><td>{members || t.updating}</td></tr>;
    })}</tbody></table></section> : <section className="panel empty-state"><Users/><h2>{t.empty}</h2></section>)}
    {active === "times" && <section className="panel table-scroll"><table><thead><tr><th>{t.categories}</th><th>{t.competitionDay}</th></tr></thead><tbody>{tournaments.map((item) => { const fixture = sportFixtures.find((candidate) => candidate.tournament_id === item.id); return <tr key={item.id}><td>{localized(item,"name",locale)}</td><td>{date(fixture?.starts_at ?? null)}</td></tr>; })}</tbody></table></section>}
    {active === "fixtures" && <section className="panel table-scroll"><table><thead><tr><th>{t.competitionDay}</th><th>{t.categories}</th><th>{t.details}</th></tr></thead><tbody>{sportFixtures.length ? sportFixtures.map((fixture) => <tr key={fixture.id}><td>{date(fixture.starts_at)}</td><td>{localized(tournamentsById.get(fixture.tournament_id) ?? {},"name",locale)}</td><td>{entryNames(fixture.id) || localized(fixture,"round",locale)}</td></tr>) : <tr><td colSpan={3}>{t.empty}</td></tr>}</tbody></table></section>}
    {active === "brackets" && (sportGroups.length || sportFixtures.some((item) => item.bracket_position !== null) ? <div className="stack">
      {sportGroups.map((group) => {
        const rows = groupEntries.filter((item) => item.group_id === group.id).map((item) => ({ item, entry: entriesById.get(item.entry_id), standing: standings.find((standing) => standing.group_id === group.id && standing.entry_id === item.entry_id) })).sort((a,b) => (a.standing?.rank ?? a.item.seed_order ?? 999) - (b.standing?.rank ?? b.item.seed_order ?? 999));
        return <section className="panel table-scroll" key={group.id}><h2 className="table-title">{localized(group,"name",locale)}</h2><table><thead><tr><th>{t.rank}</th><th>{t.teams}</th><th>P</th><th>W</th><th>D</th><th>L</th><th>{t.points}</th></tr></thead><tbody>{rows.map(({ item, entry, standing }, index) => <tr key={item.id}><td>{standing?.rank ?? index + 1}</td><td>{entry ? localized(entry,"name",locale) : ""}</td><td>{standing?.played ?? 0}</td><td>{standing?.won ?? 0}</td><td>{standing?.drawn ?? 0}</td><td>{standing?.lost ?? 0}</td><td>{standing?.points ?? 0}</td></tr>)}</tbody></table></section>;
      })}
      {sportFixtures.some((item) => item.bracket_position !== null) && <section className="panel bracket-scroll"><div className="bracket-grid">{sportFixtures.filter((item) => item.bracket_position !== null).map((fixture) => <article key={fixture.id}><small>{localized(fixture,"round",locale)}</small><b>{entryNames(fixture.id) || t.updating}</b><span>{localized(fixture,"result_summary",locale)}</span></article>)}</div></section>}
    </div> : <section className="panel empty-state bracket-placeholder"><GitBranch/><h2>{t.empty}</h2></section>)}
  </>;
}
