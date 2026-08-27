"use client";

import Image from "next/image";
import { Camera, Download, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { copy, localized, type Locale, type Media, type Sport } from "@/lib/site";

export function GalleryGrid({ locale, media, sports }: { locale: Locale; media: Media[]; sports: Sport[] }) {
  const [sportId, setSportId] = useState("all");
  const [album, setAlbum] = useState("all");
  const [selected, setSelected] = useState<Media | null>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);
  const t = copy[locale];
  const sportVisible = sportId === "all" ? media : media.filter((item) => item.sport_id === sportId || item.filter_tag === sports.find((sport) => sport.id === sportId)?.slug);
  const albums = [...new Set(sportVisible.map((item) => localized(item, "album", locale)).filter(Boolean))];
  const visible = album === "all" ? sportVisible : sportVisible.filter((item) => localized(item, "album", locale) === album);
  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (selected && !dialog.open) dialog.showModal();
    if (!selected && dialog.open) dialog.close();
  }, [selected]);
  const label = (item: Media) => localized(item, "alt", locale) || localized(item, "title", locale) || (locale === "vi" ? "Ảnh hội thao" : "Sports photo");
  return <>
    <div className="filter-pills" aria-label={locale === "vi" ? "Lọc ảnh" : "Filter photos"}>
      <button className={sportId === "all" ? "active" : ""} onClick={() => { setSportId("all"); setAlbum("all"); }}>{locale === "vi" ? "Tất cả" : "All"}</button>
      {sports.map((sport) => <button key={sport.id} className={sportId === sport.id ? "active" : ""} onClick={() => { setSportId(sport.id); setAlbum("all"); }}>{localized(sport, "name", locale)}</button>)}
    </div>
    {albums.length > 1 && <div className="filter-pills gallery-albums" aria-label={locale === "vi" ? "Lọc nhóm ảnh" : "Filter albums"}><button className={album === "all" ? "active" : ""} onClick={() => setAlbum("all")}>{locale === "vi" ? "Tất cả nhóm" : "All albums"}</button>{albums.map((item) => <button key={item} className={album === item ? "active" : ""} onClick={() => setAlbum(item)}>{item}</button>)}</div>}
    {visible.length ? <section className="gallery-grid">{visible.map((item) => <button className="gallery-card" key={item.id} onClick={() => setSelected(item)} aria-label={label(item)}>
      <div><Image src={item.public_url} alt={label(item)} fill sizes="(max-width: 600px) 100vw, (max-width: 1024px) 50vw, 33vw"/></div>
      {localized(item, "title", locale) && <h2>{localized(item, "title", locale)}</h2>}
    </button>)}</section> : <section className="panel empty-state gallery-empty"><Camera/><h2>{t.galleryEmpty}</h2></section>}
    <dialog ref={dialogRef} className="gallery-dialog" onClose={() => setSelected(null)}>{selected && <><button className="gallery-close" onClick={() => setSelected(null)} aria-label={locale === "vi" ? "Đóng" : "Close"}><X/></button><div className="gallery-dialog-image"><Image src={selected.public_url} alt={label(selected)} fill sizes="90vw"/></div><div className="gallery-dialog-actions"><b>{localized(selected, "title", locale)}</b><a href={`${selected.public_url}?download`} download><Download size={16}/>{locale === "vi" ? "Tải xuống" : "Download"}</a></div></>}</dialog>
  </>;
}
