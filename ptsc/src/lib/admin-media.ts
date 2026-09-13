const extensions = { "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp" } as const;
const DEFAULT_MAX_IMAGE_BYTES = 10 * 1024 * 1024;
export const MAX_IMAGE_DIMENSION = 16_000;
export const MAX_IMAGE_PIXELS = 40_000_000;

export function heroStoragePath(variant: string, mimeType: string, id: string) {
  if (variant !== "desktop" && variant !== "mobile" || !(mimeType in extensions)) throw new Error("Hero không hợp lệ");
  return `hero/${variant}/${id}.${extensions[mimeType as keyof typeof extensions]}`;
}

export function sportIconStoragePath(slug: string, mimeType: string, id: string) {
  if (!slug || !(mimeType in extensions)) throw new Error("Logo môn thể thao không hợp lệ");
  return `sports/${slug}/icon/${id}.${extensions[mimeType as keyof typeof extensions]}`;
}

export function assertImageFile(file: File, maxBytes = DEFAULT_MAX_IMAGE_BYTES) {
  if (!file.size || !(file.type in extensions) || file.size > maxBytes) throw new Error(`Chỉ nhận PNG/JPEG/WebP tối đa ${maxBytes / 1024 / 1024}MB`);
  return extensions[file.type as keyof typeof extensions];
}

function u16(bytes: Uint8Array, offset: number) { return (bytes[offset] << 8) | bytes[offset + 1]; }
function u24le(bytes: Uint8Array, offset: number) { return bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16); }
function ascii(bytes: Uint8Array, offset: number, length: number) { return String.fromCharCode(...bytes.slice(offset, offset + length)); }

export function imageDimensions(bytes: Uint8Array, mimeType: string) {
  let width = 0;
  let height = 0;
  if (mimeType === "image/png" && bytes.length >= 24 && ascii(bytes, 0, 8) === "\x89PNG\r\n\x1a\n" && ascii(bytes, 12, 4) === "IHDR") {
    width = (bytes[16] * 0x1000000) + (bytes[17] << 16) + (bytes[18] << 8) + bytes[19];
    height = (bytes[20] * 0x1000000) + (bytes[21] << 16) + (bytes[22] << 8) + bytes[23];
  } else if (mimeType === "image/jpeg" && bytes.length >= 4 && bytes[0] === 0xff && bytes[1] === 0xd8) {
    for (let offset = 2; offset + 8 < bytes.length;) {
      if (bytes[offset] !== 0xff) { offset += 1; continue; }
      while (bytes[offset] === 0xff) offset += 1;
      const marker = bytes[offset++];
      if (marker === 0xd9 || marker === 0xda) break;
      const length = u16(bytes, offset);
      if (length < 2 || offset + length > bytes.length) break;
      if ((marker >= 0xc0 && marker <= 0xc3) || (marker >= 0xc5 && marker <= 0xc7) || (marker >= 0xc9 && marker <= 0xcb) || (marker >= 0xcd && marker <= 0xcf)) {
        height = u16(bytes, offset + 3);
        width = u16(bytes, offset + 5);
        break;
      }
      offset += length;
    }
  } else if (mimeType === "image/webp" && bytes.length >= 30 && ascii(bytes, 0, 4) === "RIFF" && ascii(bytes, 8, 4) === "WEBP") {
    const chunk = ascii(bytes, 12, 4);
    if (chunk === "VP8X") {
      width = 1 + u24le(bytes, 24);
      height = 1 + u24le(bytes, 27);
    } else if (chunk === "VP8 ") {
      for (let offset = 20; offset + 9 < bytes.length; offset += 1) if (bytes[offset] === 0x9d && bytes[offset + 1] === 0x01 && bytes[offset + 2] === 0x2a) {
        width = bytes[offset + 3] | (bytes[offset + 4] << 8);
        height = bytes[offset + 5] | (bytes[offset + 6] << 8);
        break;
      }
    } else if (chunk === "VP8L" && bytes[21] === 0x2f) {
      width = 1 + (bytes[22] | ((bytes[23] & 0x3f) << 8));
      height = 1 + ((bytes[23] >> 6) | (bytes[24] << 2) | ((bytes[25] & 0x0f) << 10));
    }
  }
  if (!width || !height) throw new Error("Không đọc được kích thước ảnh");
  if (width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION || width * height > MAX_IMAGE_PIXELS) throw new Error("Kích thước ảnh vượt giới hạn");
  return { width, height };
}

export async function assertImageContent(file: File, maxBytes = DEFAULT_MAX_IMAGE_BYTES) {
  const extension = assertImageFile(file, maxBytes);
  const bytes = new Uint8Array(await file.arrayBuffer());
  const validMagic = file.type === "image/png"
    ? ascii(bytes, 0, 8) === "\x89PNG\r\n\x1a\n"
    : file.type === "image/jpeg"
      ? bytes[0] === 0xff && bytes[1] === 0xd8
      : ascii(bytes, 0, 4) === "RIFF" && ascii(bytes, 8, 4) === "WEBP";
  if (!validMagic) throw new Error("Ảnh không khớp chữ ký magic bytes");
  imageDimensions(bytes, file.type);
  return extension;
}

export function mediaDeletionIds(formData: FormData) {
  const singleId = String(formData.get("single_id") ?? "").trim();
  const ids = singleId ? [singleId] : formData.getAll("id").map((value) => String(value).trim()).filter(Boolean);
  return [...new Set(ids)];
}

export function setMediaSelection(inputs: Iterable<{ checked: boolean }>, checked: boolean) {
  for (const input of inputs) input.checked = checked;
}
