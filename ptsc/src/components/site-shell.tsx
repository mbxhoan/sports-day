import Link from "next/link";
import Image from "next/image";
import { CalendarDays, ImageIcon, ListOrdered, LogIn, Menu, Trophy, X } from "lucide-react";
import { copy, localized, type Locale } from "@/lib/site";
import type { ShellData } from "@/lib/public-data";
import { LanguageSwitch } from "./language-switch";
import { RefreshDataButton } from "./refresh-data-button";
import { isSafeHref } from "@/lib/safe-url";

const nav = [
  ["home", "", Trophy],
  ["leaderboard", "/leaderboard", ListOrdered],
  ["gallery", "/gallery", ImageIcon],
  ["sports", "/sports", Trophy],
  ["schedule", "/schedule", CalendarDays],
] as const;

export function Header({ locale, autoRefreshUntil }: { locale: Locale; autoRefreshUntil?: string | null }) {
  const t = copy[locale];
  const prefix = locale === "en" ? "/en" : "";
  return <header className="site-header">
    <div className="header-inner">
      <Link href={prefix || "/"} className="brand" aria-label={t.home}>
        <Image src="/logo-ptsc.jpg" alt="PTSC Sports Festival 2026" width={124} height={59} priority />
      </Link>
      <nav className="desktop-nav" aria-label="Main navigation">
        {nav.map(([key, href]) => <Link key={key} href={`${prefix}${href}` || "/"}>{t[key]}</Link>)}
      </nav>
      <div className="header-actions">
        <RefreshDataButton label={t.refreshData} autoRefreshUntil={autoRefreshUntil} />
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

export function Footer({ locale, shell }: { locale: Locale; shell: ShellData }) {
  return <footer className="site-footer">
    <div className="footer-mark"><Trophy size={19}/><b>{localized(shell.event, "event_name", locale) || copy[locale].footer}</b></div>
    <p>{locale === "vi" ? "Tập đoàn Công nghiệp - Năng lượng Quốc gia Việt Nam" : "Vietnam National Industry - Energy Group"}</p>
    <p>{localized(shell.event, "subtitle", locale)}</p>
    {shell.contacts.map((item) => <p key={item.id}><a href={isSafeHref(item.href) ? item.href : "#"}>{localized(item, "label", locale)}: {item.value}</a></p>)}
    {shell.footerLinks.length > 0 && <nav className="footer-links" aria-label="Footer">{shell.footerLinks.map((item) => <a href={isSafeHref(item.href) ? item.href : "#"} key={item.id}>{localized(item, "label", locale)}</a>)}</nav>}
  </footer>;
}

export function SiteShell({ locale, shell, children }: { locale: Locale; shell: ShellData; children: React.ReactNode }) {
  return <><Header locale={locale} autoRefreshUntil={shell.event.end_at}/><main>{children}</main><Footer locale={locale} shell={shell}/></>;
}
