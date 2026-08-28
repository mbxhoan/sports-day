"use client";

import { useState } from "react";
import { SubmitButton } from "./submit-button";

type UploadAction = (formData: FormData) => void | Promise<void>;

type Props = {
  action: UploadAction;
  sportId?: string;
  multiple?: boolean;
  filterTag?: string;
  albumFields?: boolean;
};

const MAX_IMAGE_BYTES = 2 * 1024 * 1024;

export function MediaUploadForm({ action, sportId, multiple = false, filterTag, albumFields = false }: Props) {
  const [error, setError] = useState("");

  return <form action={action} className="upload-form" onSubmit={(event) => {
    const input = event.currentTarget.elements.namedItem("file");
    const files = input instanceof HTMLInputElement ? Array.from(input.files ?? []) : [];
    const oversized = files.find((file) => file.size > MAX_IMAGE_BYTES);
    if (oversized) {
      event.preventDefault();
      setError(`Ảnh “${oversized.name}” vượt quá 2MB / Image exceeds 2MB.`);
    } else {
      setError("");
    }
  }}>
    {sportId && <input type="hidden" name="sport_id" value={sportId}/>} 
    <input type="file" name="file" accept="image/png,image/jpeg,image/webp" multiple={multiple} required/>
    <input name="title_vi" placeholder="Tiêu đề VI"/>
    <input name="title_en" placeholder="Title EN"/>
    <input name="alt_vi" placeholder="Alt VI"/>
    <input name="alt_en" placeholder="Alt EN"/>
    {albumFields && <>
      <input name="album_vi" placeholder="Nhóm ảnh VI"/>
      <input name="album_en" placeholder="Album EN"/>
    </>}
    {filterTag !== undefined && <input name="filter_tag" placeholder="Filter: pickleball, bong-ban…" pattern="[a-z0-9]+(?:-[a-z0-9]+)*" defaultValue={filterTag}/>} 
    {error && <p className="upload-error" role="alert">{error}</p>}
    <SubmitButton className="gold-button">Upload</SubmitButton>
  </form>;
}
