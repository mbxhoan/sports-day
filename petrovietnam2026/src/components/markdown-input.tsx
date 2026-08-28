"use client";

import { useState } from "react";

export function MarkdownInput({ name, defaultValue = "" }: { name: string; defaultValue?: string }) {
  const [value, setValue] = useState(defaultValue);
  return <div className="markdown-field"><textarea name={name} value={value} onChange={(event) => setValue(event.target.value)} rows={7}/><details><summary>Preview / Xem trước</summary><div className="markdown-preview">{value || "—"}</div></details></div>;
}
