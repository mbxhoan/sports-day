const extensions = { "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp" } as const;

export function heroStoragePath(variant: string, mimeType: string, id: string) {
  if (variant !== "desktop" && variant !== "mobile" || !(mimeType in extensions)) throw new Error("Hero không hợp lệ");
  return `hero/${variant}/${id}.${extensions[mimeType as keyof typeof extensions]}`;
}

export function assertImageFile(file: File) {
  if (!file.size || !(file.type in extensions) || file.size > 10 * 1024 * 1024) throw new Error("Chỉ nhận PNG/JPEG/WebP tối đa 10MB");
  return extensions[file.type as keyof typeof extensions];
}
