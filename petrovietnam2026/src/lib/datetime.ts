const vietnamInput = new Intl.DateTimeFormat("sv-SE", {
  timeZone: "Asia/Ho_Chi_Minh",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  hourCycle: "h23",
});

export function toVietnamLocalInput(value: string) {
  return vietnamInput.format(new Date(value)).replace(" ", "T");
}

export function fromVietnamLocalInput(value: string) {
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(value)) throw new Error("Ngày giờ không hợp lệ");
  const iso = new Date(`${value}:00+07:00`).toISOString();
  if (toVietnamLocalInput(iso) !== value) throw new Error("Ngày giờ không hợp lệ");
  return iso;
}

export function formatVietnamDateTime(value: string, locale: "vi" | "en") {
  const date = new Date(new Date(value).getTime() + 7 * 60 * 60 * 1000);
  if (!Number.isFinite(date.getTime())) return "";
  const pad = (part: number) => String(part).padStart(2, "0");
  const weekdays = locale === "vi" ? ["CN","T2","T3","T4","T5","T6","T7"] : ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
  return `${weekdays[date.getUTCDay()]}, ${pad(date.getUTCDate())}/${pad(date.getUTCMonth() + 1)}/${date.getUTCFullYear()} ${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())}`;
}
