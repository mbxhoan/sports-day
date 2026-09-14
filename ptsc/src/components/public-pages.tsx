import Image from "next/image";
import Link from "next/link";
import { CalendarDays, CircleDot, Medal, Trophy, Users } from "lucide-react";
import { Countdown } from "./countdown";
import { ScheduleView } from "./schedule-view";
import { SiteShell } from "./site-shell";
import { SportTabs, type TabKey } from "./sport-tabs";
import { copy, localized, rankOrganizations, type Locale, type Sport, type Tournament } from "@/lib/site";
import { getGalleryData, getHomeData, getLeaderboardData, getScheduleData, getSportData, getSportsIndexData } from "@/lib/public-data";
import { validateGalleryDriveUrl } from "@/lib/manual-competition";
import { notFound } from "next/navigation";

function PageTitle({ emoji, title, subtitle }: { emoji?: string; title: string; subtitle?: string }) {
  const mark = emoji?.startsWith("/") || emoji?.startsWith("http") ? <Image className="page-heading-icon" src={emoji} alt="" width={42} height={42} /> : emoji ? <span>{emoji}</span> : null;
  return <div className="page-heading">{mark}<div><h1>{title}</h1>{subtitle && <p>{subtitle}</p>}</div></div>;
}

function SportIcon({ value }: { value: string }) {
  return value.startsWith("/") || value.startsWith("http") ? <Image className="sport-icon" src={value} alt="" width={48} height={48} /> : <span className="sport-emoji">{value}</span>;
}

function SportCard({ locale, sport, tournaments, fixtureCount }: { locale: Locale; sport: Sport; tournaments: Tournament[]; fixtureCount: number }) {
  const prefix = locale === "en" ? "/en" : "";
  return <Link className="sport-card" href={`${prefix}/sports/${sport.slug}`}>
    <SportIcon value={sport.emoji} />
    <h3>{localized(sport,"name",locale)}</h3>
    <p>{localized(sport,"description",locale)}</p>
    <div className="sport-meta"><span><Users size={14}/>{tournaments.length} {copy[locale].categoryUnit}</span><span><CircleDot size={14}/>{fixtureCount} {copy[locale].fixtureUnit}</span></div>
    <div className="sport-categories" aria-label={copy[locale].categories}>{tournaments.map((tournament) => <span key={tournament.id}>{localized(tournament, "name", locale)}</span>)}</div>
    <span className="card-cta">{copy[locale].viewDetail}</span>
  </Link>;
}

export async function HomePage({ locale }: { locale: Locale }) {
  const { shell, data } = await getHomeData();
  const t = copy[locale];
  const desktopHero = shell.event.hero_path === "/kv.png" ? "/kv.webp" : shell.event.hero_path;
  const mobileHero = shell.event.hero_mobile_path === "/kv-mobile.png" ? "/kv-mobile.webp" : shell.event.hero_mobile_path;
  const dayCount = shell.event.start_at && shell.event.end_at ? Math.max(1, Math.ceil((Date.parse(shell.event.end_at) - Date.parse(shell.event.start_at)) / 86_400_000)) : 0;
  const stats = [
    [Trophy, data.counts.sports, t.sportCount],
    [CalendarDays, dayCount, t.dayCount],
    [Medal, data.counts.organizations, t.unitCount],
    [Users, data.counts.participants, t.athleteCount],
  ] as const;
  return <SiteShell locale={locale} shell={shell}>
    {(desktopHero || mobileHero) && <section className="hero"><picture>{mobileHero && <source media="(max-width: 767px)" srcSet={mobileHero}/>}<Image src={desktopHero || mobileHero} alt={localized(shell.event,"event_name",locale)} fill sizes="100vw" priority /></picture></section>}
    {shell.event.start_at && <Countdown target={shell.event.start_at} locale={locale}/>}
    <div className="container home-content">
      <section className="stats-grid">
        {stats.map(([Icon,value,label]) => <article className="stat-card" key={label}><Icon/><b>{value}</b><span>{label}</span></article>)}
        <article className="stat-card matches"><Trophy/><b>{data.counts.fixtures}</b><span>{t.matchCount}</span></article>
      </section>
      <section className="sports-section"><h2>{t.allSports}</h2><div className="sports-grid">{data.sports.map((sport) => <SportCard key={sport.id} locale={locale} sport={sport} tournaments={data.tournaments.filter((item) => item.sport_id === sport.id)} fixtureCount={data.fixtureCounts[sport.id] ?? 0}/>)}</div></section>
    </div>
  </SiteShell>;
}

export async function SportsPage({ locale }: { locale: Locale }) {
  const { shell, data } = await getSportsIndexData();
  const t = copy[locale];
  return <SiteShell locale={locale} shell={shell}><div className="container page-container"><PageTitle emoji="🏆" title={t.sports} subtitle={localized(shell.event,"subtitle",locale)}/><div className="sports-grid">{data.sports.map((sport) => <SportCard key={sport.id} locale={locale} sport={sport} tournaments={data.tournaments.filter((item) => item.sport_id === sport.id)} fixtureCount={data.fixtureCounts[sport.id] ?? 0}/>)}</div></div></SiteShell>;
}

export async function SportPage({ locale, slug, tab = "info", tournamentSlug }: { locale: Locale; slug: string; tab?: string; tournamentSlug?: string }) {
  const { shell, data } = await getSportData(slug);
  const sport = data.sport;
  if (!sport) notFound();
  const allowedTabs = ["info", "teams", "times", "fixtures", "brackets", "gallery"] as TabKey[];
  const active = allowedTabs.includes(tab as TabKey) ? tab as TabKey : "info";
  const hrefBase = `${locale === "en" ? "/en" : ""}/sports/${sport.slug}`;
  return <SiteShell locale={locale} shell={shell}><div className="container page-container sport-page"><PageTitle emoji={sport.emoji} title={localized(sport,"name",locale)} subtitle={localized(sport,"description",locale)}/><SportTabs locale={locale} sport={sport} venue={localized(shell.event,"venue",locale)} active={active} hrefBase={hrefBase} tournaments={data.tournaments} initialTournamentSlug={tournamentSlug} organizations={data.organizations} participants={data.participants} entries={data.entries} entryMembers={data.entryMembers} groups={data.groups} groupEntries={data.groupEntries} fixtures={data.fixtures} fixtureEntries={data.fixtureEntries} fixtureSlots={data.fixtureSlots} standings={data.standings} venues={data.venues} courts={data.courts}/></div></SiteShell>;
}

export async function SchedulePage({ locale }: { locale: Locale }) {
  const { shell, data } = await getScheduleData();
  return <SiteShell locale={locale} shell={shell}><div className="container page-container schedule-page"><PageTitle emoji="📅" title={copy[locale].schedule}/><ScheduleView locale={locale} sports={data.sports} tournaments={data.tournaments} entries={data.entries} groups={data.groups} groupEntries={data.groupEntries} fixtures={data.fixtures} fixtureEntries={data.fixtureEntries} fixtureSlots={data.fixtureSlots} standings={data.standings} venues={data.venues} courts={data.courts} participants={data.participants} entryMembers={data.entryMembers} defaultVenue={localized(shell.event,"venue",locale)}/></div></SiteShell>;
}

export async function LeaderboardPage({ locale }: { locale: Locale }) {
  const t = copy[locale];
  const { shell, data } = await getLeaderboardData();
  const rows = rankOrganizations(data.awards, data.organizations, data.entries, data.participants);
  const podium = [rows[1], rows[0], rows[2]];
  return <SiteShell locale={locale} shell={shell}><div className="container page-container"><PageTitle emoji="🏆" title={t.leaderboard}/>{rows.length ? <>
    <section className="leaderboard podium panel">{podium.map((row, index) => row ? <div className={index === 1 ? "first" : ""} key={row.organization.id}><span>{index === 0 ? "🥈" : index === 1 ? "🥇" : "🥉"}</span><b>{row.organization.code}</b><small>{row.total} {t.medals}</small></div> : <div className={index === 1 ? "first" : ""} key={index}/>)}</section>
    <section className="panel table-scroll"><table className="leaderboard-table"><thead><tr><th>#</th><th>{t.organization}</th><th>{t.abbreviation}</th><th>🥇</th><th>🥈</th><th>🥉</th><th>{t.total}</th></tr></thead><tbody>{rows.map((row, index) => <tr key={row.organization.id}><td>{index + 1}</td><td>{localized(row.organization, "name", locale)}</td><td><b>{row.organization.code}</b></td><td>{row.gold}</td><td>{row.silver}</td><td>{row.bronze}</td><td><b>{row.total}</b></td></tr>)}</tbody></table></section>
  </> : <section className="panel empty-state"><Medal/><h2>{t.leaderboardEmpty}</h2></section>}</div></SiteShell>;
}

export async function GalleryPage({ locale }: { locale: Locale }) {
  const t = copy[locale];
  const { shell, data } = await getGalleryData();
  const driveUrl = validateGalleryDriveUrl(data.gallery_drive_url) ? data.gallery_drive_url : "";
  return <SiteShell locale={locale} shell={shell}><div className="container page-container"><PageTitle emoji="📷" title={t.gallery}/>{driveUrl ? <section className="panel drive-gallery"><p>{t.galleryEmpty}</p><a className="gold-button" href={driveUrl} target="_blank" rel="noreferrer">{t.openDrive} ↗</a></section> : <section className="panel empty-state gallery-empty"><p>{t.updating}</p></section>}</div></SiteShell>;
}
