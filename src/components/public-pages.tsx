import Image from "next/image";
import Link from "next/link";
import { CalendarDays, CircleDot, Medal, Trophy, Users } from "lucide-react";
import { Countdown } from "./countdown";
import { GalleryGrid } from "./gallery-grid";
import { ScheduleView } from "./schedule-view";
import { SiteShell } from "./site-shell";
import { SportTabs } from "./sport-tabs";
import { copy, getSiteData, localized, rankOrganizations, type Locale, type SiteData, type Sport } from "@/lib/site";

function PageTitle({ emoji, title, subtitle }: { emoji?: string; title: string; subtitle?: string }) {
  return <div className="page-heading"><span>{emoji}</span><div><h1>{title}</h1>{subtitle && <p>{subtitle}</p>}</div></div>;
}

function SportCard({ locale, sport, data }: { locale: Locale; sport: Sport; data: SiteData }) {
  const prefix = locale === "en" ? "/en" : "";
  const tournamentCount = data.tournaments.filter((item) => item.sport_id === sport.id).length;
  const fixtureCount = data.fixtures.filter((fixture) => data.tournaments.some((item) => item.id === fixture.tournament_id && item.sport_id === sport.id)).length;
  return <Link className="sport-card" href={`${prefix}/sports/${sport.slug}`}>
    <span className="sport-emoji">{sport.emoji}</span>
    <h3>{localized(sport,"name",locale)}</h3>
    <p>{localized(sport,"description",locale)}</p>
    <div className="sport-meta"><span><Users size={14}/>{tournamentCount}</span><span><CircleDot size={14}/>{fixtureCount}</span></div>
    <span className="card-cta">{copy[locale].viewDetail}</span>
  </Link>;
}

export async function HomePage({ locale }: { locale: Locale }) {
  const data = await getSiteData();
  const t = copy[locale];
  const dayCount = Math.max(1, Math.ceil((Date.parse(data.event.end_at) - Date.parse(data.event.start_at)) / 86_400_000));
  const stats = [
    [Trophy, data.counts.sports, t.sportCount],
    [CalendarDays, dayCount, t.dayCount],
    [Medal, data.counts.organizations, t.unitCount],
    [Users, data.counts.participants, t.athleteCount],
  ] as const;
  return <SiteShell locale={locale}>
    <section className="hero"><Image className="hero-desktop" src={data.event.hero_path} alt={localized(data.event,"event_name",locale)} fill priority sizes="100vw" /><Image className="hero-mobile" src={data.event.hero_mobile_path} alt={localized(data.event,"event_name",locale)} fill priority sizes="100vw" /></section>
    <Countdown target={data.event.start_at} locale={locale}/>
    <div className="container home-content">
      <section className="stats-grid">
        {stats.map(([Icon,value,label]) => <article className="stat-card" key={label}><Icon/><b>{value}</b><span>{label}</span></article>)}
        <article className="stat-card matches"><Trophy/><b>{data.counts.fixtures}</b><span>{t.matchCount}</span></article>
      </section>
      <section className="sports-section"><h2>{t.allSports}</h2><div className="sports-grid">{data.sports.map((sport) => <SportCard key={sport.id} locale={locale} sport={sport} data={data}/>)}</div></section>
    </div>
  </SiteShell>;
}

export async function SportsPage({ locale }: { locale: Locale }) {
  const data = await getSiteData();
  const t = copy[locale];
  return <SiteShell locale={locale}><div className="container page-container"><PageTitle emoji="🏆" title={t.sports} subtitle={localized(data.event,"subtitle",locale)}/><div className="sports-grid">{data.sports.map((sport) => <SportCard key={sport.id} locale={locale} sport={sport} data={data}/>)}</div></div></SiteShell>;
}

export async function SportPage({ locale, slug }: { locale: Locale; slug: string }) {
  const data = await getSiteData();
  const sport = data.sports.find((item) => item.slug === slug);
  if (!sport) return <SiteShell locale={locale}><div className="container page-container"><PageTitle title="404" subtitle={copy[locale].empty}/></div></SiteShell>;
  const tournaments = data.tournaments.filter((item) => item.sport_id === sport.id);
  return <SiteShell locale={locale}><div className="container page-container"><PageTitle emoji={sport.emoji} title={localized(sport,"name",locale)} subtitle={localized(sport,"description",locale)}/><SportTabs locale={locale} sport={sport} tournaments={tournaments} organizations={data.organizations} participants={data.participants} entries={data.entries} entryMembers={data.entryMembers} groups={data.groups} groupEntries={data.groupEntries} fixtures={data.fixtures} fixtureEntries={data.fixtureEntries} standings={data.standings}/></div></SiteShell>;
}

export async function SchedulePage({ locale }: { locale: Locale }) {
  const data = await getSiteData();
  return <SiteShell locale={locale}><div className="container page-container"><PageTitle emoji="📅" title={copy[locale].schedule}/><ScheduleView locale={locale} sports={data.sports} tournaments={data.tournaments} entries={data.entries} fixtures={data.fixtures} fixtureEntries={data.fixtureEntries}/></div></SiteShell>;
}

export async function LeaderboardPage({ locale }: { locale: Locale }) {
  const t = copy[locale];
  const data = await getSiteData();
  const rows = rankOrganizations(data.awards, data.organizations, data.entries, data.participants);
  const podium = [rows[1], rows[0], rows[2]];
  return <SiteShell locale={locale}><div className="container page-container"><PageTitle emoji="🏆" title={t.leaderboard}/>{rows.length ? <>
    <section className="leaderboard podium panel">{podium.map((row, index) => row ? <div className={index === 1 ? "first" : ""} key={row.organization.id}><span>{index === 0 ? "🥈" : index === 1 ? "🥇" : "🥉"}</span><b>{localized(row.organization, "name", locale)}</b><small>{row.total} {t.medals}</small></div> : <div className={index === 1 ? "first" : ""} key={index}/>)}</section>
    <section className="panel table-scroll"><table><thead><tr><th>#</th><th>{t.organization}</th><th>🥇</th><th>🥈</th><th>🥉</th><th>{t.total}</th></tr></thead><tbody>{rows.map((row, index) => <tr key={row.organization.id}><td>{index + 1}</td><td>{localized(row.organization, "name", locale)}</td><td>{row.gold}</td><td>{row.silver}</td><td>{row.bronze}</td><td><b>{row.total}</b></td></tr>)}</tbody></table></section>
  </> : <section className="panel empty-state"><Medal/><h2>{t.leaderboardEmpty}</h2></section>}</div></SiteShell>;
}

export async function GalleryPage({ locale }: { locale: Locale }) {
  const t = copy[locale];
  const data = await getSiteData();
  return <SiteShell locale={locale}><div className="container page-container"><PageTitle emoji="📷" title={t.gallery}/><GalleryGrid locale={locale} media={data.media} sports={data.sports}/></div></SiteShell>;
}
