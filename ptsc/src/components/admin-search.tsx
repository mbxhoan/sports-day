"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { SearchSuggestion } from "@/lib/search";
import { SearchCombobox } from "./search-combobox";

export function AdminSearch({ slug, suggestions }: { slug: string; suggestions: SearchSuggestion[] }) {
  const router = useRouter();
  const [value, setValue] = useState("");
  return <SearchCombobox label="Tìm nhanh trong môn" placeholder="Tên VĐV, đội hoặc trận đấu..." suggestions={suggestions} value={value} onChange={setValue} onSelect={(suggestion) => {
    const isTournament = suggestion.kind === "tournament";
    const section = isTournament ? "results" : suggestion.kind === "fixture" ? "results" : "teams";
    const params = new URLSearchParams({ section });
    if (isTournament) params.set("tournament", suggestion.id);
    else {
      const target = `${suggestion.kind === "fixture" ? "fixture-result" : suggestion.kind === "participant" ? "participants" : "entries"}:${suggestion.id}`;
      params.set("edit", target);
    }
    router.push(`/admin/sports/${encodeURIComponent(slug)}?${params}#${section === "results" && !isTournament ? `fixture-${suggestion.id}` : section}`);
  }}/>;
}
