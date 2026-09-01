"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { SearchSuggestion } from "@/lib/search";
import { SearchCombobox } from "./search-combobox";

export function AdminSearch({ slug, suggestions }: { slug: string; suggestions: SearchSuggestion[] }) {
  const router = useRouter();
  const [value, setValue] = useState("");
  return <SearchCombobox label="Tìm nhanh trong môn" placeholder="Tên VĐV, đội hoặc trận đấu..." suggestions={suggestions} value={value} onChange={setValue} onSelect={(suggestion) => {
    const section = suggestion.kind === "tournament" ? "categories" : suggestion.kind === "fixture" ? "results" : "teams";
    const target = `${suggestion.kind === "tournament" ? "tournaments" : suggestion.kind === "fixture" ? "fixture-result" : suggestion.kind === "participant" ? "participants" : "entries"}:${suggestion.id}`;
    router.push(`/admin/sports/${encodeURIComponent(slug)}?section=${section}&edit=${encodeURIComponent(target)}#${section === "results" ? `fixture-${suggestion.id}` : section}`);
  }}/>;
}
