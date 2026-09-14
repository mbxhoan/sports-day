"use client";

import { useMemo, useState } from "react";

type PreviewRow = { sheet?: string; row_number?: number; category_code?: string; natural_key?: string; status?: string; action?: string };

export function PtscImportPreview({ rows }: { rows: PreviewRow[] }) {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("all");
  const filtered = useMemo(() => rows.filter((row) => {
    const text = `${row.sheet ?? ""} ${row.category_code ?? ""} ${row.natural_key ?? ""}`.toLowerCase();
    return (!query || text.includes(query.toLowerCase())) && (status === "all" || row.action === status || row.status === status);
  }), [query, rows, status]);
  return <div className="ptsc-import-rows"><div className="ptsc-import-filters"><input aria-label="Tìm dòng import" placeholder="Tìm môn, mã hạng mục, khóa..." value={query} onChange={(event) => setQuery(event.target.value)}/><select aria-label="Lọc trạng thái" value={status} onChange={(event) => setStatus(event.target.value)}><option value="all">Tất cả trạng thái</option><option value="created">Tạo mới</option><option value="updated">Cập nhật</option><option value="unchanged">Không đổi</option><option value="draft">Chờ nhập</option><option value="pending_confirmation">Chờ xác nhận</option></select></div><p className="upload-help">Hiển thị {filtered.length}/{rows.length} dòng</p><div className="table-scroll"><table><thead><tr><th>Sheet</th><th>Dòng</th><th>Hạng mục</th><th>Khóa tự nhiên</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{filtered.slice(0, 500).map((row) => <tr key={`${row.sheet}-${row.row_number}-${row.natural_key}`}><td>{row.sheet}</td><td>{row.row_number}</td><td>{row.category_code}</td><td>{row.natural_key}</td><td>{row.status}</td><td>{row.action}</td></tr>)}</tbody></table></div></div>;
}
