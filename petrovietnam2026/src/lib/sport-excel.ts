import ExcelJS from "exceljs";

export const SPORT_EXCEL_VERSION = 1;
export const SPORT_EXCEL_MAX_BYTES = 10 * 1024 * 1024;
export const SPORT_EXCEL_MAX_ROWS = 20_000;
export const SPORT_EXCEL_MAX_CELLS = 250_000;

export const SPORT_EXCEL_SPORTS = [
  "pickleball", "bong-ban", "cau-long", "boi-loi", "keo-co", "dien-kinh", "co-vua", "co-tuong",
] as const;

export type SportExcelMode = "current" | "blank";
export type SportExcelTable =
  | "sports" | "tournaments" | "organizations" | "participants" | "entries" | "entry_members"
  | "venues" | "courts" | "groups" | "group_entries" | "fixtures" | "fixture_entries"
  | "fixture_slots" | "standings" | "awards";
export type SportExcelAction = "KEEP" | "UPDATE" | "UPSERT" | "ARCHIVE";

type ColumnType = "text" | "number" | "date" | "json";
type Column = { key: string; header: string; type?: ColumnType; required?: boolean };
type RawRow = Record<string, unknown> & { id: string; tenant_id?: string; archived_at?: string | null };
export type SportExcelSnapshot = { sport_id: string; sport_slug: string; tables: Partial<Record<SportExcelTable, RawRow[]>> };
export type ParsedExcelRow = { ref: string; action: SportExcelAction; values: Record<string, unknown>; sheet: string; rowNumber: number };
export type ParsedSportWorkbook = { meta: Record<string, string>; tables: Partial<Record<SportExcelTable, ParsedExcelRow[]>> };
export type SportExcelOperation = { table: SportExcelTable; ref: string; action: SportExcelAction; id: string | null; base: RawRow | null; data: Record<string, unknown>; sheet: string; rowNumber: number };

const commonSheets = ["tournaments", "organizations", "participants", "entries", "entry_members", "venues", "courts", "standings", "awards"] as const;
const bracketSheets = ["groups", "group_entries", "fixtures", "fixture_entries", "fixture_slots"] as const;
const raceSheets = ["fixtures", "fixture_entries"] as const;

export const sportExcelConfig = {
  pickleball: { sheets: [...commonSheets, ...bracketSheets] },
  "bong-ban": { sheets: [...commonSheets, ...bracketSheets] },
  "cau-long": { sheets: [...commonSheets, ...bracketSheets] },
  "keo-co": { sheets: [...commonSheets, ...bracketSheets] },
  "boi-loi": { sheets: [...commonSheets, ...raceSheets] },
  "dien-kinh": { sheets: [...commonSheets, ...raceSheets] },
  "co-vua": { sheets: [...commonSheets, "fixtures", "fixture_entries"] },
  "co-tuong": { sheets: [...commonSheets, "fixtures", "fixture_entries"] },
} as const satisfies Record<(typeof SPORT_EXCEL_SPORTS)[number], { sheets: readonly SportExcelTable[] }>;

const sheetNames: Record<SportExcelTable, string> = {
  sports: "MÔN",
  tournaments: "HẠNG_MỤC",
  organizations: "ĐƠN_VỊ",
  participants: "VĐV",
  entries: "ĐỘI",
  entry_members: "THÀNH_VIÊN",
  venues: "ĐỊA_ĐIỂM",
  courts: "SÂN_LÀN",
  groups: "BẢNG_ĐẤU",
  group_entries: "ĐỘI_TRONG_BẢNG",
  fixtures: "TRẬN_ĐẤU",
  fixture_entries: "KẾT_QUẢ",
  fixture_slots: "NGUỒN_NHÁNH",
  standings: "BXH",
  awards: "HUY_CHƯƠNG",
};

const tableDefinitions: Record<SportExcelTable, readonly Column[]> = {
  sports: [
    { key: "slug", header: "Slug", required: true }, { key: "name_vi", header: "Tên VI", required: true }, { key: "name_en", header: "Name EN" }, { key: "emoji", header: "Icon", required: true },
    { key: "description_vi", header: "Mô tả VI" }, { key: "description_en", header: "Description EN" }, { key: "rules_vi", header: "Thể lệ VI" }, { key: "rules_en", header: "Rules EN" }, { key: "sort_order", header: "Thứ tự", type: "number" },
  ],
  tournaments: [
    { key: "sport_ref", header: "Môn / Sport", required: true }, { key: "slug", header: "Slug", required: true }, { key: "name_vi", header: "Tên VI", required: true }, { key: "name_en", header: "Name EN" },
    { key: "category_vi", header: "Hạng mục VI" }, { key: "category_en", header: "Category EN" }, { key: "gender", header: "Giới tính / Gender", required: true }, { key: "format_vi", header: "Thể thức VI" }, { key: "format_en", header: "Format EN" },
    { key: "rules_vi", header: "Thể lệ VI" }, { key: "rules_en", header: "Rules EN" }, { key: "competition_mode", header: "Kiểu thi / Mode", required: true }, { key: "source_metadata", header: "Nguồn / Source", type: "json" }, { key: "scoring_rule", header: "Quy tắc điểm / Scoring", type: "json" }, { key: "sort_order", header: "Thứ tự", type: "number" },
  ],
  organizations: [
    { key: "code", header: "Mã đơn vị / Code", required: true }, { key: "name_vi", header: "Tên VI", required: true }, { key: "name_en", header: "Name EN" }, { key: "logo_path", header: "Logo path" }, { key: "leaderboard_rank", header: "Hạng BXH", type: "number" },
    { key: "gold_medals", header: "Vàng", type: "number" }, { key: "silver_medals", header: "Bạc", type: "number" }, { key: "bronze_medals", header: "Đồng", type: "number" }, { key: "sort_order", header: "Thứ tự", type: "number" },
  ],
  participants: [
    { key: "organization_ref", header: "Đơn vị / Organization" }, { key: "full_name", header: "Họ tên", required: true }, { key: "full_name_en", header: "English name" }, { key: "gender", header: "Giới tính / Gender" }, { key: "birth_date", header: "Ngày sinh / Date of birth", type: "date" },
  ],
  entries: [
    { key: "tournament_ref", header: "Hạng mục / Tournament", required: true }, { key: "organization_ref", header: "Đơn vị / Organization" }, { key: "kind", header: "Loại / Kind", required: true }, { key: "name_vi", header: "Tên VI", required: true }, { key: "name_en", header: "Name EN" }, { key: "seed_number", header: "Seed", type: "number" }, { key: "bib_number", header: "Số áo / Bib" },
  ],
  entry_members: [
    { key: "entry_ref", header: "Đội / Entry", required: true }, { key: "participant_ref", header: "VĐV / Athlete", required: true }, { key: "role_vi", header: "Vai trò VI" }, { key: "role_en", header: "Role EN" }, { key: "sort_order", header: "Thứ tự", type: "number" },
  ],
  venues: [
    { key: "name_vi", header: "Tên VI", required: true }, { key: "name_en", header: "Name EN" }, { key: "address_vi", header: "Địa chỉ VI" }, { key: "address_en", header: "Address EN" }, { key: "sort_order", header: "Thứ tự", type: "number" },
  ],
  courts: [
    { key: "venue_ref", header: "Địa điểm / Venue", required: true }, { key: "name_vi", header: "Tên VI", required: true }, { key: "name_en", header: "Name EN" }, { key: "sort_order", header: "Thứ tự", type: "number" },
  ],
  groups: [
    { key: "tournament_ref", header: "Hạng mục / Tournament", required: true }, { key: "name_vi", header: "Tên VI", required: true }, { key: "name_en", header: "Name EN" }, { key: "sort_order", header: "Thứ tự", type: "number" },
  ],
  group_entries: [
    { key: "group_ref", header: "Bảng / Group", required: true }, { key: "entry_ref", header: "Đội / Entry", required: true }, { key: "seed_order", header: "Seed", type: "number" },
  ],
  fixtures: [
    { key: "tournament_ref", header: "Hạng mục / Tournament", required: true }, { key: "group_ref", header: "Bảng / Group" }, { key: "venue_ref", header: "Địa điểm / Venue" }, { key: "court_ref", header: "Sân / Court" }, { key: "starts_at", header: "Bắt đầu / Starts", type: "date" }, { key: "ends_at", header: "Kết thúc / Ends", type: "date" },
    { key: "status", header: "Trạng thái / Status", required: true }, { key: "round_vi", header: "Vòng VI" }, { key: "round_en", header: "Round EN" }, { key: "round_order", header: "Round order", type: "number" }, { key: "bracket_position", header: "Bracket position", type: "number" }, { key: "next_fixture_ref", header: "Trận kế / Next fixture" }, { key: "result_summary_vi", header: "Kết quả VI" }, { key: "result_summary_en", header: "Result EN" }, { key: "winner_entry_ref", header: "Đội thắng / Winner" }, { key: "source_code", header: "Mã nguồn / Source code" },
  ],
  fixture_entries: [
    { key: "fixture_ref", header: "Trận / Fixture", required: true }, { key: "entry_ref", header: "Đội / Entry", required: true }, { key: "side", header: "Bên / Side" }, { key: "lane", header: "Làn / Lane", type: "number" }, { key: "seed_order", header: "Seed", type: "number" }, { key: "score", header: "Tỷ số / Score" }, { key: "score_numeric", header: "Điểm số / Numeric score", type: "number" }, { key: "rank", header: "Hạng / Rank", type: "number" }, { key: "result_status", header: "Trạng thái KQ / Result status" }, { key: "result_detail", header: "Chi tiết JSON", type: "json" },
  ],
  fixture_slots: [
    { key: "fixture_ref", header: "Trận / Fixture", required: true }, { key: "side", header: "Bên / Side", required: true }, { key: "source_kind", header: "Nguồn / Source kind", required: true }, { key: "source_entry_ref", header: "Đội nguồn / Entry" }, { key: "source_group_ref", header: "Bảng nguồn / Group" }, { key: "source_fixture_ref", header: "Trận nguồn / Fixture" }, { key: "source_rank", header: "Hạng nguồn / Rank", type: "number" }, { key: "label_vi", header: "Nhãn VI" }, { key: "label_en", header: "Label EN" },
  ],
  standings: [
    { key: "tournament_ref", header: "Hạng mục / Tournament", required: true }, { key: "group_ref", header: "Bảng / Group" }, { key: "entry_ref", header: "Đội / Entry", required: true }, { key: "played", header: "P", type: "number" }, { key: "won", header: "W", type: "number" }, { key: "drawn", header: "D", type: "number" }, { key: "lost", header: "L", type: "number" }, { key: "score_for", header: "Điểm ghi", type: "number" }, { key: "score_against", header: "Điểm thua", type: "number" }, { key: "points", header: "Điểm", type: "number" }, { key: "rank", header: "Hạng", type: "number" }, { key: "note_vi", header: "Ghi chú VI" }, { key: "note_en", header: "Note EN" },
  ],
  awards: [
    { key: "sport_ref", header: "Môn / Sport" }, { key: "tournament_ref", header: "Hạng mục / Tournament" }, { key: "entry_ref", header: "Đội / Entry" }, { key: "participant_ref", header: "VĐV / Athlete" }, { key: "organization_ref", header: "Đơn vị / Organization" }, { key: "title_vi", header: "Tên giải VI", required: true }, { key: "title_en", header: "Award EN" }, { key: "medal", header: "Huy chương / Medal", required: true }, { key: "sort_order", header: "Thứ tự", type: "number" },
  ],
};

const relations: Partial<Record<string, SportExcelTable>> = {
  sport_id: "sports", tournament_id: "tournaments", organization_id: "organizations", participant_id: "participants", entry_id: "entries", venue_id: "venues", court_id: "courts", group_id: "groups", fixture_id: "fixtures", next_fixture_id: "fixtures", winner_entry_id: "entries", source_entry_id: "entries", source_group_id: "groups", source_fixture_id: "fixtures",
};

const tablePrefix: Record<SportExcelTable, string> = {
  sports: "MON", tournaments: "HM", organizations: "DV", participants: "VDV", entries: "DOI", entry_members: "TV", venues: "DD", courts: "SAN", groups: "BANG", group_entries: "BANGDOI", fixtures: "TRAN", fixture_entries: "KQ", fixture_slots: "NGUON", standings: "BXH", awards: "HC",
};

function slugPart(value: unknown) {
  return String(value ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 28) || "row";
}

export function rowRef(table: SportExcelTable, row: RawRow) {
  const base = row.code ?? row.slug ?? row.source_code ?? row.name_vi ?? row.full_name ?? row.title_vi ?? row.round_vi ?? row.id;
  return `${tablePrefix[table]}-${slugPart(base)}-${String(row.id).slice(0, 8)}`;
}

function relationKey(key: string) {
  return key.endsWith("_ref") ? key.slice(0, -4) + "_id" : null;
}

function refsForSnapshot(snapshot: SportExcelSnapshot) {
  const byTable = new Map<SportExcelTable, Map<string, string>>();
  const byRef = new Map<string, { table: SportExcelTable; id: string }>();
  for (const table of Object.keys(tableDefinitions) as SportExcelTable[]) {
    const map = new Map<string, string>();
    for (const row of snapshot.tables[table] ?? []) {
      const ref = rowRef(table, row);
      map.set(row.id, ref);
      byRef.set(`${table}:${ref}`, { table, id: row.id });
    }
    byTable.set(table, map);
  }
  return { byTable, byRef };
}

function exportValue(table: SportExcelTable, key: string, row: RawRow, refs: ReturnType<typeof refsForSnapshot>) {
  const actualKey = relationKey(key);
  if (actualKey) {
    const relatedId = row[actualKey];
    const relatedTable = relations[actualKey];
    return relatedId && relatedTable ? refs.byTable.get(relatedTable)?.get(String(relatedId)) ?? "" : "";
  }
  const value = row[key];
  if (value === null || value === undefined) return "";
  if (tableDefinitions[table].find((column) => column.key === key)?.type === "json") return JSON.stringify(value);
  return value;
}

function displayLabel(row: RawRow) {
  return String(row.name_vi ?? row.full_name ?? row.code ?? row.slug ?? row.title_vi ?? row.source_code ?? row.id);
}

function configureDataSheet(sheet: ExcelJS.Worksheet, table: SportExcelTable, rows: RawRow[], refs: ReturnType<typeof refsForSnapshot>, editable: boolean) {
  const columns = tableDefinitions[table];
  sheet.columns = [{ header: "Mã / Ref", key: "ref", width: 34 }, { header: "Thao tác / Action", key: "action", width: 14 }, ...columns.map((column) => ({ header: column.header, key: column.key, width: Math.min(32, Math.max(13, column.header.length + 3)) }))];
  for (const row of rows) {
    const values: Record<string, unknown> = { ref: rowRef(table, row), action: editable ? "UPDATE" : "KEEP" };
    for (const column of columns) values[column.key] = exportValue(table, column.key, row, refs);
    const excelRow = sheet.addRow(values);
    for (const column of columns) {
      if (column.type === "date" && excelRow.getCell(column.key).value) excelRow.getCell(column.key).value = new Date(String(row[column.key]));
      if (column.type === "json") excelRow.getCell(column.key).alignment = { vertical: "top", wrapText: true };
    }
  }
  const header = sheet.getRow(1);
  header.font = { bold: true, color: { argb: "FFFFFFFF" } };
  header.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF07527F" } };
  header.alignment = { vertical: "middle", wrapText: true };
  header.height = 30;
  sheet.views = [{ state: "frozen", ySplit: 1 }];
  sheet.autoFilter = { from: "A1", to: `${String.fromCharCode(65 + Math.min(25, columns.length + 1))}1` };
  sheet.getColumn("ref").font = { color: { argb: "FF9FDDEA" } };
  if (editable) sheet.getColumn("action").eachCell((cell, rowNumber) => { if (rowNumber > 1) cell.dataValidation = { type: "list", allowBlank: false, formulae: ["\"KEEP,UPDATE,UPSERT,ARCHIVE\""] }; });
  sheet.eachRow((row, rowNumber) => { if (rowNumber > 1 && rowNumber % 2 === 0) row.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFF2F8FA" } }; });
}

export async function buildSportWorkbook(snapshot: SportExcelSnapshot, mode: SportExcelMode, exportId: string) {
  if (!SPORT_EXCEL_SPORTS.includes(snapshot.sport_slug as (typeof SPORT_EXCEL_SPORTS)[number])) throw new Error("Môn thể thao không được hỗ trợ");
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "Petrovietnam Sports Day";
  workbook.created = new Date();
  workbook.modified = new Date();
  const refs = refsForSnapshot(snapshot);
  const allowed = sportExcelConfig[snapshot.sport_slug as keyof typeof sportExcelConfig].sheets;
  const guide = workbook.addWorksheet("HƯỚNG_DẪN");
  guide.columns = [{ header: "Nội dung", key: "content", width: 110 }];
  guide.addRows([
    ["Workbook quản trị Excel · Petrovietnam 2026"],
    [`Môn: ${snapshot.sport_slug} · Chế độ: ${mode === "current" ? "Dữ liệu hiện tại" : "Mẫu trống"}`],
    ["Chỉ sửa các sheet dữ liệu. Cột Mã / Ref dùng để nối dữ liệu; không đổi mã của dòng đã xuất."],
    ["Dòng đã xuất: giữ UPDATE để cập nhật, KEEP để bỏ qua, ARCHIVE để lưu trữ. Dòng mới dùng mã NEW-* và UPSERT."],
    ["Xóa dòng khỏi file không xóa dữ liệu. Không nhập công thức, macro, file .xls/.xlsm hoặc file có mật khẩu."],
    ["Import luôn có bước xem trước. Một lỗi chặn sẽ làm toàn workbook không ghi gì; cảnh báo cần được xác nhận."],
    ["NGUỒN_NHÁNH chỉ để xem. Muốn thay đổi đường đi/nhánh, dùng màn hình reset cấu trúc hiện có."],
    ["Ngày giờ là ô ngày giờ Excel và được hiểu theo múi giờ Asia/Ho_Chi_Minh."],
  ]);
  guide.getRow(1).font = { bold: true, size: 16, color: { argb: "FFFFFFFF" } };
  guide.getRow(1).fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF07527F" } };
  guide.getColumn(1).alignment = { wrapText: true, vertical: "top" };
  guide.eachRow((row) => { row.height = 28; });
  for (const table of allowed) {
    const sheet = workbook.addWorksheet(sheetNames[table]);
    const rows = mode === "current" ? snapshot.tables[table] ?? [] : [];
    configureDataSheet(sheet, table, rows, refs, table !== "fixture_slots");
    if (table === "fixture_slots") sheet.getRow(1).fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF6B7280" } };
  }
  const lookup = workbook.addWorksheet("_LOOKUP");
  lookup.columns = [{ header: "Loại / Type", key: "type", width: 24 }, { header: "Mã / Ref", key: "ref", width: 38 }, { header: "Tên / Label", key: "label", width: 70 }];
  for (const table of allowed) for (const row of snapshot.tables[table] ?? []) lookup.addRow({ type: table, ref: rowRef(table, row), label: displayLabel(row) });
  lookup.views = [{ state: "frozen", ySplit: 1 }];
  lookup.protect("sports-day-template", { selectLockedCells: true, selectUnlockedCells: true });
  const meta = workbook.addWorksheet("_META");
  meta.columns = [{ header: "Khóa / Key", key: "key", width: 28 }, { header: "Giá trị / Value", key: "value", width: 80 }];
  meta.addRows([
    { key: "template_version", value: String(SPORT_EXCEL_VERSION) }, { key: "export_id", value: exportId }, { key: "tenant_slug", value: "petrovietnam2026" }, { key: "sport_slug", value: snapshot.sport_slug }, { key: "sport_id", value: snapshot.sport_id }, { key: "mode", value: mode },
  ]);
  meta.views = [{ state: "frozen", ySplit: 1 }];
  meta.protect("sports-day-template", { selectLockedCells: true, selectUnlockedCells: true });
  for (const sheet of workbook.worksheets) {
    sheet.eachRow((row) => row.eachCell((cell) => { cell.font = { ...cell.font, name: "Arial", size: 10 }; }));
  }
  return Buffer.from(await workbook.xlsx.writeBuffer());
}

function cellValue(cell: ExcelJS.Cell, column: Column) {
  const value = cell.value;
  if (value && typeof value === "object" && ("formula" in value || "sharedFormula" in value)) throw new Error(`Không nhận công thức tại ô ${cell.address}`);
  if (value && typeof value === "object" && !(value instanceof Date)) throw new Error(`Kiểu dữ liệu tại ô ${cell.address} không được hỗ trợ`);
  if (column.type === "date") {
    if (value === null || value === undefined || value === "") return null;
    if (!(value instanceof Date) || !Number.isFinite(value.getTime())) throw new Error(`Ngày giờ tại ô ${cell.address} không hợp lệ`);
    return value.toISOString();
  }
  if (value === null || value === undefined) return null;
  if (column.type === "json") {
    const text = typeof value === "string" ? value.trim() : JSON.stringify(value);
    if (!text) return null;
    const parsed = JSON.parse(text);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error(`JSON tại ô ${cell.address} phải là object`);
    return parsed;
  }
  if (column.type === "number") {
    if (value === "") return null;
    const number = typeof value === "number" ? value : Number(String(value).trim());
    if (!Number.isFinite(number)) throw new Error(`Số tại ô ${cell.address} không hợp lệ`);
    return number;
  }
  const text = String(value).trim();
  return text || null;
}

function allowedSheetMap(slug: string) {
  if (!(slug in sportExcelConfig)) throw new Error("Môn thể thao không được hỗ trợ");
  return new Map(sportExcelConfig[slug as keyof typeof sportExcelConfig].sheets.map((table) => [sheetNames[table], table]));
}

export async function parseSportWorkbook(buffer: Buffer | ArrayBuffer): Promise<ParsedSportWorkbook> {
  const bytes = Buffer.isBuffer(buffer) ? buffer : Buffer.from(buffer);
  if (!bytes.length || bytes.length > SPORT_EXCEL_MAX_BYTES) throw new Error("File Excel phải từ 1 byte đến 10 MB");
  const workbook = new ExcelJS.Workbook();
  const xlsxBuffer = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
  try { await workbook.xlsx.load(xlsxBuffer as Parameters<typeof workbook.xlsx.load>[0]); } catch { throw new Error("File Excel không đọc được hoặc bị hỏng"); }
  const metaSheet = workbook.getWorksheet("_META");
  if (!metaSheet) throw new Error("Thiếu sheet _META");
  const meta: Record<string, string> = {};
  metaSheet.eachRow((row, rowNumber) => { if (rowNumber > 1) { const key = String(row.getCell(1).value ?? "").trim(); if (key) meta[key] = String(row.getCell(2).value ?? "").trim(); } });
  if (meta.template_version !== String(SPORT_EXCEL_VERSION)) throw new Error("Phiên bản template không được hỗ trợ");
  if (!meta.tenant_slug || !meta.sport_slug || !meta.export_id) throw new Error("_META thiếu tenant, môn hoặc export_id");
  const sheets = allowedSheetMap(meta.sport_slug);
  const allowedNames = new Set(["HƯỚNG_DẪN", "_META", "_LOOKUP", ...sheets.keys()]);
  for (const sheet of workbook.worksheets) if (!allowedNames.has(sheet.name)) throw new Error(`Sheet không được phép: ${sheet.name}`);
  const tables: Partial<Record<SportExcelTable, ParsedExcelRow[]>> = {};
  let cellCount = 0;
  for (const [sheetName, table] of sheets) {
    const sheet = workbook.getWorksheet(sheetName);
    if (!sheet) continue;
    const expected = ["Mã / Ref", "Thao tác / Action", ...tableDefinitions[table].map((column) => column.header)];
    const headers = (sheet.getRow(1).values as unknown[]).slice(1).map((value) => String(value ?? "").trim());
    if (headers.join("\u0000") !== expected.join("\u0000")) throw new Error(`Header sheet ${sheetName} không đúng template`);
    const indexes = new Map(headers.map((header, index) => [header, index + 1]));
    const rows: ParsedExcelRow[] = [];
    sheet.eachRow((row, rowNumber) => {
      if (rowNumber === 1) return;
      cellCount += headers.length;
      if (cellCount > SPORT_EXCEL_MAX_CELLS || rowNumber > SPORT_EXCEL_MAX_ROWS) throw new Error("Workbook vượt giới hạn dòng hoặc ô");
      const values = headers.map((header) => row.getCell(indexes.get(header)!).value);
      if (values.every((value) => value === null || value === undefined || value === "")) return;
      const ref = String(row.getCell(1).value ?? "").trim();
      const actionText = String(row.getCell(2).value ?? "").trim().toUpperCase();
      if (!ref) throw new Error(`Thiếu Mã / Ref tại ${sheetName}!A${rowNumber}`);
      if (!/^(NEW-[A-Z0-9][A-Z0-9_-]{0,60}|[A-Z0-9][A-Z0-9_-]{1,100})$/i.test(ref)) throw new Error(`Mã / Ref không hợp lệ tại ${sheetName}!A${rowNumber}`);
      const action = (actionText || (ref.startsWith("NEW-") ? "UPSERT" : "UPDATE")) as SportExcelAction;
      if (!( ["KEEP", "UPDATE", "UPSERT", "ARCHIVE"] as SportExcelAction[]).includes(action)) throw new Error(`Thao tác không hợp lệ tại ${sheetName}!B${rowNumber}`);
      const parsed: Record<string, unknown> = {};
      for (const column of tableDefinitions[table]) {
        parsed[column.key] = cellValue(row.getCell(indexes.get(column.header)!), column);
        if (column.required && (parsed[column.key] === null || parsed[column.key] === "")) throw new Error(`Thiếu ${column.header} tại ${sheetName}!${row.getCell(indexes.get(column.header)!).address}`);
      }
      rows.push({ ref, action, values: parsed, sheet: sheetName, rowNumber });
    });
    tables[table] = rows;
  }
  return { meta, tables };
}

function fallbackEnglish(values: Record<string, unknown>) {
  for (const [vi, en] of [["name_vi", "name_en"], ["description_vi", "description_en"], ["rules_vi", "rules_en"], ["category_vi", "category_en"], ["format_vi", "format_en"], ["full_name", "full_name_en"], ["role_vi", "role_en"], ["address_vi", "address_en"], ["title_vi", "title_en"], ["note_vi", "note_en"]]) if (!values[en] && values[vi]) values[en] = values[vi];
}

const insertDefaults: Partial<Record<SportExcelTable, Record<string, unknown>>> = {
  tournaments: { category_vi: "", category_en: "", format_vi: "", format_en: "", rules_vi: "", rules_en: "", source_metadata: {}, scoring_rule: {}, sort_order: 0 },
  organizations: { gold_medals: 0, silver_medals: 0, bronze_medals: 0, sort_order: 0 },
  entry_members: { role_vi: "Vận động viên", role_en: "Athlete", sort_order: 0 },
  venues: { address_vi: "", address_en: "", sort_order: 0 },
  courts: { sort_order: 0 },
  groups: { sort_order: 0 },
  fixtures: { round_vi: "", round_en: "", result_summary_vi: "", result_summary_en: "" },
  fixture_entries: { result_detail: {} },
  fixture_slots: { label_vi: "", label_en: "" },
  standings: { played: 0, won: 0, drawn: 0, lost: 0, score_for: 0, score_against: 0, points: 0, note_vi: "", note_en: "" },
  awards: { sort_order: 0 },
};

function applyInsertDefaults(table: SportExcelTable, data: Record<string, unknown>) {
  for (const [key, value] of Object.entries(insertDefaults[table] ?? {})) if (data[key] === null || data[key] === undefined) data[key] = value;
}

function sameValue(left: unknown, right: unknown, type?: ColumnType) {
  if (type === "date") return left == null && right == null || (left != null && right != null && new Date(String(left)).getTime() === new Date(String(right)).getTime());
  return JSON.stringify(left ?? null) === JSON.stringify(right ?? null);
}

export function buildOperations(parsed: ParsedSportWorkbook, snapshot: SportExcelSnapshot, sportId: string) {
  if (parsed.meta.sport_id && parsed.meta.sport_id !== sportId) throw new Error("Workbook không thuộc môn đang mở");
  if (parsed.meta.sport_slug !== snapshot.sport_slug) throw new Error("Workbook không thuộc môn đang mở");
  const refs = refsForSnapshot(snapshot);
  const operations: SportExcelOperation[] = [];
  const seen = new Set<string>();
  for (const table of Object.keys(tableDefinitions) as SportExcelTable[]) {
    for (const row of parsed.tables[table] ?? []) {
      const key = `${table}:${row.ref}`;
      if (seen.has(key)) throw new Error(`Mã bị trùng: ${row.ref}`);
      seen.add(key);
      const current = (snapshot.tables[table] ?? []).find((candidate) => rowRef(table, candidate) === row.ref) ?? null;
      if (!current && !row.ref.startsWith("NEW-")) throw new Error(`Không tìm thấy dòng export cho ${table}:${row.ref}`);
      if (row.action === "ARCHIVE" && !current) throw new Error(`Chỉ dòng đã xuất mới được ARCHIVE: ${row.ref}`);
      if (row.action === "KEEP") continue;
      const data = { ...row.values };
      if (!current) fallbackEnglish(data);
      applyInsertDefaults(table, data);
      for (const column of tableDefinitions[table]) {
        const actual = relationKey(column.key);
        if (!actual) continue;
        const relatedTable = relations[actual];
        const ref = String(data[column.key] ?? "").trim();
        data[actual] = !ref ? null : ref.startsWith("NEW-") ? `@ref:${ref}` : refs.byRef.get(`${relatedTable}:${ref}`)?.id ?? (() => { throw new Error(`Không tìm thấy liên kết ${column.header}: ${ref}`); })();
        delete data[column.key];
      }
      if (current && row.action !== "ARCHIVE" && tableDefinitions[table].every((column) => {
        const actual = relationKey(column.key) ?? column.key;
        return sameValue(data[actual], current[actual], column.type);
      })) continue;
      operations.push({ table, ref: row.ref, action: row.action, id: current?.id ?? null, base: current, data: data as Record<string, unknown>, sheet: row.sheet, rowNumber: row.rowNumber });
    }
  }
  return { sport_id: sportId, sport_slug: snapshot.sport_slug, export_id: parsed.meta.export_id, operations };
}

export function previewOperations(operations: SportExcelOperation[]) {
  const blockers: string[] = [];
  const warnings: string[] = [];
  const diff: Array<{ table: string; ref: string; action: string }> = [];
  for (const operation of operations) {
    if (operation.table === "fixture_slots") blockers.push(`${operation.sheet}!${operation.rowNumber}: NGUỒN_NHÁNH chỉ đọc; không sửa đường đi của nhánh bằng Excel.`);
    if (!operation.id && operation.action === "UPDATE") blockers.push(`${operation.sheet}!${operation.rowNumber}: dòng mới phải dùng UPSERT.`);
    if (operation.table === "standings" && operation.data.rank !== null && operation.data.rank !== undefined && Number(operation.data.rank) < 1) blockers.push(`${operation.sheet}!${operation.rowNumber}: hạng phải lớn hơn 0.`);
    if (operation.table === "organizations" && ["leaderboard_rank", "gold_medals", "silver_medals", "bronze_medals"].some((key) => operation.data[key] !== null && operation.data[key] !== undefined && (!Number.isInteger(Number(operation.data[key])) || Number(operation.data[key]) < (key === "leaderboard_rank" ? 1 : 0)))) blockers.push(`${operation.sheet}!${operation.rowNumber}: hạng hoặc huy chương không hợp lệ.`);
    if (operation.table === "entries" && operation.data.seed_number !== null && operation.data.seed_number !== undefined && (!Number.isInteger(Number(operation.data.seed_number)) || Number(operation.data.seed_number) < 1)) blockers.push(`${operation.sheet}!${operation.rowNumber}: seed phải là số nguyên lớn hơn 0.`);
    if (operation.table === "fixture_entries" && ["lane", "rank", "seed_order"].some((key) => operation.data[key] !== null && operation.data[key] !== undefined && (!Number.isInteger(Number(operation.data[key])) || Number(operation.data[key]) < 1))) blockers.push(`${operation.sheet}!${operation.rowNumber}: làn, hạng và seed phải là số nguyên lớn hơn 0.`);
    if (operation.table === "fixture_entries" && operation.data.score_numeric !== null && operation.data.score_numeric !== undefined && (!Number.isFinite(Number(operation.data.score_numeric)) || Number(operation.data.score_numeric) < 0)) blockers.push(`${operation.sheet}!${operation.rowNumber}: điểm số không hợp lệ.`);
    if (operation.table === "fixtures" && operation.base && operation.data.source_code !== operation.base.source_code) blockers.push(`${operation.sheet}!${operation.rowNumber}: không được đổi mã nguồn trận.`);
    if (operation.table === "fixture_entries" && operation.base && operation.data.entry_id !== operation.base.entry_id) warnings.push(`${operation.sheet}!${operation.rowNumber}: đổi đội trong trận sẽ bị DB kiểm tra lại theo nguồn nhánh.`);
    if (operation.action === "ARCHIVE") warnings.push(`${operation.sheet}!${operation.rowNumber}: lưu trữ là thao tác không xóa và sẽ bị chặn nếu còn dữ liệu phụ thuộc.`);
    diff.push({ table: operation.table, ref: operation.ref, action: operation.action });
  }
  return { blockers, warnings, diff, operation_count: operations.length };
}

export function sheetName(table: SportExcelTable) { return sheetNames[table]; }
