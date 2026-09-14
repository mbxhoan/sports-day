export type PreviewRow = {
  sheet?: string;
  row_number?: number;
  category_code?: string;
  natural_key?: string;
  status?: string;
  action?: string;
};

export type PreviewFilter = "needs_review" | "created" | "updated" | "unchanged" | "draft" | "pending_confirmation" | "all";

export const previewFilters: Array<[PreviewFilter, string]> = [
  ["needs_review", "Dòng cần xem"],
  ["created", "Tạo mới"],
  ["updated", "Cập nhật"],
  ["unchanged", "Không đổi"],
  ["draft", "Chờ nhập"],
  ["pending_confirmation", "Chờ xác nhận"],
  ["all", "Tất cả"],
];

function matchesFilter(row: PreviewRow, filter: PreviewFilter) {
  if (filter === "all") return true;
  if (filter === "needs_review") return row.action !== "unchanged" || ["draft", "pending_confirmation"].includes(row.status ?? "");
  return row.action === filter || row.status === filter;
}

export function filterPtscImportRows(rows: PreviewRow[], query: string, filter: PreviewFilter) {
  const needle = query.trim().toLocaleLowerCase();
  return rows.filter((row) => {
    const text = `${row.sheet ?? ""} ${row.category_code ?? ""} ${row.natural_key ?? ""}`.toLocaleLowerCase();
    return (!needle || text.includes(needle)) && matchesFilter(row, filter);
  });
}

export function countPtscImportRows(rows: PreviewRow[], filter: PreviewFilter) {
  return rows.filter((row) => matchesFilter(row, filter)).length;
}
