"use client";

import Image from "next/image";
import { Camera } from "lucide-react";
import { useState } from "react";
import { copy, localized, type Locale, type Media, type Sport } from "@/lib/site";

export function GalleryGrid({ locale, media, sports }: { locale: Locale; media: Media[]; sports: Sport[] }) {
  const [active, setActive] = useState("all");
  const visible = active === "all" ? media : media.filter((item) => item.filter_tag === active);
  const t = copy[locale];
  return <>
    <div className="filter-pills" aria-label={locale === "vi" ? "Lọc ảnh" : "Filter photos"}>
      <button className={active === "all" ? "active" : ""} onClick={() => setActive("all")}>{locale === "vi" ? "Tất cả" : "All"}</button>
      {sports.map((sport) => <button key={sport.id} className={active === sport.slug ? "active" : ""} onClick={() => setActive(sport.slug)}>{localized(sport, "name", locale)}</button>)}
    </div>
    {visible.length ? <section className="gallery-grid">{visible.map((item) => <article className="gallery-card" key={item.id}>
      <div><Image src={item.public_url} alt={localized(item, "alt", locale) || localized(item, "title", locale)} fill sizes="(max-width: 600px) 100vw, (max-width: 1024px) 50vw, 33vw"/></div>
      {localized(item, "title", locale) && <h2>{localized(item, "title", locale)}</h2>}
    </article>)}</section> : <section className="panel empty-state gallery-empty"><Camera/><h2>{t.galleryEmpty}</h2></section>}
  </>;
}
