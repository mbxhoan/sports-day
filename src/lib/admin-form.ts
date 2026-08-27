import { fromVietnamLocalInput } from "./datetime.ts";

export function formValue(formData: FormData, name: string, type?: string) {
  const raw = String(formData.get(name) ?? "").trim();
  if (!raw) {
    if (name === "result_detail") return {};
    return name.endsWith("_id") || type === "number" || type === "date" || type === "datetime-local" ? null : "";
  }
  if (type === "number") {
    const number = Number(raw);
    if (!Number.isFinite(number)) throw new Error(`${name} không hợp lệ`);
    return number;
  }
  if (name === "result_detail") return JSON.parse(raw);
  if (type === "datetime-local") return fromVietnamLocalInput(raw);
  return raw;
}
