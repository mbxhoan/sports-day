const extensions = { "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp" } as const;
const DEFAULT_MAX_IMAGE_BYTES = 10 * 1024 * 1024;

export function heroStoragePath(variant: string, mimeType: string, id: string) {
  if (variant !== "desktop" && variant !== "mobile" || !(mimeType in extensions)) throw new Error("Hero không hợp lệ");
  return `hero/${variant}/${id}.${extensions[mimeType as keyof typeof extensions]}`;
}

export function assertImageFile(file: File, maxBytes = DEFAULT_MAX_IMAGE_BYTES) {
  if (!file.size || !(file.type in extensions) || file.size > maxBytes) throw new Error(`Chỉ nhận PNG/JPEG/WebP tối đa ${maxBytes / 1024 / 1024}MB`);
  return extensions[file.type as keyof typeof extensions];
}

export function mediaDeletionIds(formData: FormData) {
  const singleId = String(formData.get("single_id") ?? "").trim();
  const ids = singleId ? [singleId] : formData.getAll("id").map((value) => String(value).trim()).filter(Boolean);
  return [...new Set(ids)];
}
