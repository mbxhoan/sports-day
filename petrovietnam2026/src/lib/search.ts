export type SearchSuggestion = {
  id: string;
  kind: "participant" | "entry" | "fixture" | "tournament";
  label: string;
  detail: string;
  searchText: string;
};

export function normalizeSearch(value: string) {
  return value.toLocaleLowerCase("vi-VN").replace(/đ/g, "d").normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z0-9]+/g, " ").trim();
}

export function matchesSearch(value: string, query: string) {
  const normalizedQuery = normalizeSearch(query);
  return !normalizedQuery || normalizeSearch(value).includes(normalizedQuery);
}

export function buildSearchSuggestions(input: {
  participants: Array<{ id: string; full_name: string; organization?: string }>;
  entries: Array<{ id: string; name: string; tournament?: string }>;
  fixtures: Array<{ id: string; label: string; detail: string }>;
  tournaments?: Array<{ id: string; name: string; detail?: string }>;
}): SearchSuggestion[] {
  return [
    ...(input.tournaments ?? []).map((item) => ({ id: item.id, kind: "tournament" as const, label: item.name, detail: item.detail ?? "Hạng mục", searchText: `${item.name} ${item.detail ?? ""}` })),
    ...input.participants.map((item) => ({ id: item.id, kind: "participant" as const, label: item.full_name, detail: item.organization ?? "", searchText: `${item.full_name} ${item.organization ?? ""}` })),
    ...input.entries.map((item) => ({ id: item.id, kind: "entry" as const, label: item.name, detail: item.tournament ?? "", searchText: `${item.name} ${item.tournament ?? ""}` })),
    ...input.fixtures.map((item) => ({ id: item.id, kind: "fixture" as const, label: item.label, detail: item.detail, searchText: `${item.label} ${item.detail}` })),
  ];
}
