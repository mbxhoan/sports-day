const allowedProtocols = new Set(["https:", "mailto:", "tel:"]);

export function isSafeHref(value: string) {
  const href = value.trim();
  if (!href || /^[\u0000-\u001f\u007f]|javascript\s*:/i.test(href) || href.startsWith("//")) return !href;
  try {
    const parsed = new URL(href, "https://ptsc.invalid");
    if (parsed.origin === "https://ptsc.invalid") return true;
    return allowedProtocols.has(parsed.protocol);
  } catch {
    return false;
  }
}
