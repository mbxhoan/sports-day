"use client";

import { useState } from "react";
import type { SearchSuggestion } from "@/lib/search";
import { SearchCombobox } from "./search-combobox";

export function AdminSearch({ slug, suggestions }: { slug: string; suggestions: SearchSuggestion[] }) {
  const [value, setValue] = useState("");
  return <SearchCombobox label="Tìm nhanh trong môn" placeholder="Tên VĐV, đội hoặc trận đấu..." suggestions={suggestions} value={value} onChange={setValue} onSelect={(suggestion) => {
    const section = suggestion.kind === "fixture" ? "results" : "teams";
    const target = `${suggestion.kind === "fixture" ? "fixture-result" : suggestion.kind === "participant" ? "participants" : "entries"}:${suggestion.id}`;
    window.location.assign(`/admin/sports/${encodeURIComponent(slug)}?section=${section}&edit=${encodeURIComponent(target)}#${suggestion.kind === "fixture" ? `fixture-${suggestion.id}` : section}`);
  }}/>;
}
