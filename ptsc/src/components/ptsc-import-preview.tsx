"use client";

import { useMemo, useState } from "react";
import { countPtscImportRows, filterPtscImportRows, previewFilters, type PreviewFilter, type PreviewRow } from "@/lib/ptsc-import-preview";

const labels: Record<string, string> = { created: "Tạo mới", updated: "Cập nhật", unchanged: "Không đổi", draft: "Chờ nhập", pending_confirmation: "Chờ xác nhận" };

export function PtscImportPreview({ rows }: { rows: PreviewRow[] }) {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<PreviewFilter>("needs_review");
  const filtered = useMemo(() => filterPtscImportRows(rows, query, status), [query, rows, status]);
  return <div className="ptsc-import-rows"><div className="ptsc-import-filters"><label><span>Tìm trong preview</span><input aria-label="Tìm dòng import" placeholder="Tìm môn, mã hạng mục, khóa..." value={query} onChange={(event) => setQuery(event.target.value)}/></label><label><span>Lọc trạng thái</span><select aria-label="Lọc trạng thái" value={status} onChange={(event) => setStatus(event.target.value as PreviewFilter)}>{previewFilters.map(([value, label]) => <option value={value} key={value}>{label} ({countPtscImportRows(rows, value)})</option>)}</select></label></div><p className="upload-help">Hiển thị {filtered.length}/{rows.length} dòng · mặc định ẩn dòng không đổi</p><div className="table-scroll ptsc-import-table-scroll"><table className="ptsc-import-table"><thead><tr><th>Sheet</th><th>Dòng</th><th>Hạng mục</th><th>Khóa tự nhiên</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{filtered.slice(0, 500).map((row) => <tr key={`${row.sheet}-${row.row_number}-${row.natural_key}`}><td data-label="Sheet">{row.sheet}</td><td data-label="Dòng">{row.row_number}</td><td data-label="Hạng mục">{row.category_code}</td><td data-label="Khóa tự nhiên">{row.natural_key}</td><td data-label="Trạng thái"><span className="status-pill">{labels[row.status ?? ""] ?? row.status ?? "—"}</span></td><td data-label="Thao tác"><span className="status-pill">{labels[row.action ?? ""] ?? row.action ?? "—"}</span></td></tr>)}</tbody></table></div>{filtered.length > 500 && <p className="upload-help">Chỉ hiển thị 500 dòng đầu trong vùng xem trước.</p>}</div>;
}
