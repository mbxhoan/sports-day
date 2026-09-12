"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export function LanguageSwitch({ locale }: { locale: "vi" | "en" }) {
  const pathname = usePathname();
  const href = locale === "vi" ? `/en${pathname === "/" ? "" : pathname}` : pathname.replace(/^\/en(?=\/|$)/, "") || "/";
  return <Link className="language" href={href} aria-label={locale === "vi" ? "English" : "Tiếng Việt"}>{locale === "vi" ? "EN" : "VI"}</Link>;
}
