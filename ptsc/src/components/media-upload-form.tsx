"use client";

import { useState, type FormEvent } from "react";
import { SubmitButton } from "./submit-button";

type UploadAction = (formData: FormData) => void | Promise<void>;

type Props = {
  action: UploadAction;
  sportId?: string;
  multiple?: boolean;
  filterTag?: string;
  albumFields?: boolean;
};

const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

type QueueItem = { file: File; progress: number; status: "queued" | "uploading" | "done" | "error" };

export function MediaUploadForm({ action, sportId, multiple = false, filterTag, albumFields = false }: Props) {
  const [error, setError] = useState("");
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [uploading, setUploading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (uploading) return;
    const form = event.currentTarget;
    const source = new FormData(form);
    const input = form.elements.namedItem("file");
    const files = input instanceof HTMLInputElement ? Array.from(input.files ?? []) : [];
    const oversized = files.find((file) => file.size > MAX_IMAGE_BYTES);
    if (!files.length) return setError("Chưa chọn ảnh / Choose at least one image.");
    if (oversized) return setError(`Ảnh “${oversized.name}” vượt quá 10MB / Image exceeds 10MB.`);
    setError("");
    setQueue(files.map((file) => ({ file, progress: 0, status: "queued" })));
    setUploading(true);
    let failed = false;
    for (let index = 0; index < files.length; index += 1) {
      const file = files[index];
      setQueue((items) => items.map((item, itemIndex) => itemIndex === index ? { ...item, status: "uploading" } : item));
      const payload = new FormData();
      payload.append("file", file);
      for (const [name, value] of source.entries()) if (name !== "file") payload.append(name, typeof value === "string" ? value : String(value));
      const timer = window.setInterval(() => setQueue((items) => items.map((item, itemIndex) => itemIndex === index && item.progress < 90 ? { ...item, progress: Math.min(90, item.progress + 5) } : item)), 450);
      try {
        await action(payload);
        window.clearInterval(timer);
        setQueue((items) => items.map((item, itemIndex) => itemIndex === index ? { ...item, progress: 100, status: "done" } : item));
      } catch (cause) {
        window.clearInterval(timer);
        setQueue((items) => items.map((item, itemIndex) => itemIndex === index ? { ...item, status: "error" } : item));
        setError(cause instanceof Error ? cause.message : "Upload thất bại / Upload failed.");
        failed = true;
        break;
      }
    }
    setUploading(false);
    if (!failed) form.reset();
  }

  const completed = queue.filter((item) => item.status === "done").length;
  const progress = queue.length ? Math.round((queue.reduce((sum, item) => sum + item.progress, 0)) / queue.length) : 0;

  return <form action={action} className="upload-form" onSubmit={handleSubmit}>
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
    {queue.length > 0 && <div className="upload-queue" aria-live="polite"><div className="upload-progress-head"><b>{uploading ? "Đang tải lần lượt / Uploading queue" : "Hoàn tất / Complete"}</b><span>{progress}% · {completed}/{queue.length}</span></div><progress max="100" value={progress}/>{queue.map((item) => <div className="upload-queue-item" key={`${item.file.name}-${item.file.lastModified}`}><span>{item.file.name}</span><small>{item.status === "queued" ? "Đang chờ / Queued" : item.status === "uploading" ? `${item.progress}%` : item.status === "done" ? "Đã tải / Done" : "Lỗi / Error"}</small></div>)}</div>}
    {error && <p className="upload-error" role="alert">{error}</p>}
    <SubmitButton className="gold-button" disabled={uploading}>{uploading ? "Đang tải… / Uploading…" : "Upload"}</SubmitButton>
  </form>;
}
