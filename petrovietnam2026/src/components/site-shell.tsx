import Link from "next/link";
import { CalendarDays, ImageIcon, ListOrdered, LogIn, Menu, Trophy, X } from "lucide-react";
import { copy, getSiteData, localized, type Locale, type SiteData } from "@/lib/site";
import { LanguageSwitch } from "./language-switch";
import { RefreshDataButton } from "./refresh-data-button";

const nav = [
  ["home", "", Trophy],
  ["leaderboard", "/leaderboard", ListOrdered],
  ["gallery", "/gallery", ImageIcon],
  ["sports", "/sports", Trophy],
  ["schedule", "/schedule", CalendarDays],
] as const;

export function Header({ locale }: { locale: Locale }) {
  const t = copy[locale];
  const prefix = locale === "en" ? "/en" : "";
  return <header className="site-header">
    <div className="header-inner">
      <Link href={prefix || "/"} className="brand" aria-label={t.home}>
        <Trophy size={23} aria-hidden="true" />
        <span><b>PETROVIETNAM</b><small>SPORTS DAY 2026</small></span>
      </Link>
      <nav className="desktop-nav" aria-label="Main navigation">
        {nav.map(([key, href]) => <Link key={key} href={`${prefix}${href}` || "/"}>{t[key]}</Link>)}
      </nav>
      <div className="header-actions">
        <RefreshDataButton label={t.refreshData} />
        <LanguageSwitch locale={locale} />
        <Link className="login-link" href={`${prefix}/login`}><LogIn size={16} />{t.login}</Link>
        <details className="mobile-menu">
          <summary aria-label="Menu"><Menu className="menu-open" /><X className="menu-close" /></summary>
          <nav aria-label="Mobile navigation">
            {nav.map(([key, href, Icon]) => <Link key={key} href={`${prefix}${href}` || "/"}><Icon size={18}/>{t[key]}</Link>)}
            <Link href={`${prefix}/login`}><LogIn size={18}/>{t.login}</Link>
          </nav>
        </details>
      </div>
    </div>
  </header>;
}

export function Footer({ locale, data }: { locale: Locale; data: SiteData }) {
  return <footer className="site-footer">
    <div className="footer-mark"><Trophy size={19}/><b>{localized(data.event, "event_name", locale) || copy[locale].footer}</b></div>
    <p>{locale === "vi" ? "Tập đoàn Công nghiệp - Năng lượng Quốc gia Việt Nam" : "Vietnam National Industry - Energy Group"}</p>
    <p>{localized(data.event, "subtitle", locale)}</p>
    {data.contacts.map((item) => <p key={item.id}><a href={item.href}>{localized(item, "label", locale)}: {item.value}</a></p>)}
    {data.footerLinks.length > 0 && <nav className="footer-links" aria-label="Footer">{data.footerLinks.map((item) => <a href={item.href} key={item.id}>{localized(item, "label", locale)}</a>)}</nav>}
  </footer>;
}

export async function SiteShell({ locale, children }: { locale: Locale; children: React.ReactNode }) {
  const data = await getSiteData();
  return <><Header locale={locale}/><main>{children}</main><Footer locale={locale} data={data}/></>;
}
