import { createHash } from "node:crypto";
import JSZip from "jszip";
import { preflightZip, SPORT_EXCEL_MAX_BYTES } from "./sport-excel.ts";

export const PTSC_TEMPLATE_VERSION = 1;
export const PTSC_CATEGORY_COUNT = 45;
export const PTSC_POSITION_COUNT = 490;

export const PTSC_SHEET_NAMES = [
  "TONG_QUAN",
  "HANG_MUC",
  "01_Boi",
  "02_BongBan",
  "03_BD_Nam_A",
  "04_BD_Nam_B",
  "05_BD_Nu",
  "06_CauLong",
  "07_DienKinh",
  "08_KeoCo",
  "09_PB_LanhDao",
  "10_Pickleball",
  "11_Tennis",
] as const;

export type PtscStatus = "draft" | "active" | "pending_confirmation" | "archived";
export type PtscKind = "individual" | "pair" | "team";

export type PtscSport = {
  code: string;
  slug: string;
  name_vi: string;
  name_en: string;
  emoji: string;
  sort_order: number;
};

export const PTSC_SPORTS: readonly PtscSport[] = [
  { code: "BB", slug: "bong-ban", name_vi: "Bóng bàn", name_en: "Table tennis", emoji: "🏓", sort_order: 1 },
  { code: "CL", slug: "cau-long", name_vi: "Cầu lông", name_en: "Badminton", emoji: "🏸", sort_order: 2 },
  { code: "TEN", slug: "tennis", name_vi: "Tennis", name_en: "Tennis", emoji: "🎾", sort_order: 3 },
  { code: "DK", slug: "dien-kinh", name_vi: "Điền kinh", name_en: "Athletics", emoji: "🏃", sort_order: 4 },
  { code: "PB", slug: "pickleball", name_vi: "Pickleball", name_en: "Pickleball", emoji: "🏓", sort_order: 5 },
  { code: "PBLD", slug: "pickleball-lanh-dao", name_vi: "Pickleball lãnh đạo PTSC", name_en: "PTSC leadership pickleball", emoji: "🏓", sort_order: 6 },
  { code: "BOI", slug: "boi-loi", name_vi: "Bơi lội", name_en: "Swimming", emoji: "🏊", sort_order: 7 },
  { code: "KC", slug: "keo-co", name_vi: "Kéo co", name_en: "Tug of war", emoji: "🤼", sort_order: 8 },
  { code: "BDNU", slug: "bong-da-nu", name_vi: "Bóng đá nữ", name_en: "Women's football", emoji: "⚽", sort_order: 9 },
  { code: "BDNA", slug: "bong-da-nam-a", name_vi: "Bóng đá nam A", name_en: "Men's football A", emoji: "⚽", sort_order: 10 },
  { code: "BDNB", slug: "bong-da-nam-b", name_vi: "Bóng đá nam B", name_en: "Men's football B", emoji: "⚽", sort_order: 11 },
];

const sportByCode = new Map(PTSC_SPORTS.map((sport) => [sport.code, sport]));
const sportBySheet = new Map([
  ["01_Boi", "BOI"], ["02_BongBan", "BB"], ["03_BD_Nam_A", "BDNA"], ["04_BD_Nam_B", "BDNB"],
  ["05_BD_Nu", "BDNU"], ["06_CauLong", "CL"], ["07_DienKinh", "DK"], ["08_KeoCo", "KC"],
  ["09_PB_LanhDao", "PBLD"], ["10_Pickleball", "PB"], ["11_Tennis", "TEN"],
]);

const categoryCodes = [
  "BOI-NAM45-100", "BOI-NAM46-100", "BOI-NU45-50", "BOI-DONGDOI-NAM-200",
  "BB-DON-NAM45", "BB-DON-NAM46", "BB-DON-NU45", "BB-DOI-NAM45", "BB-DOI-NAMNU45",
  "BDNA-DONGDOI", "BDNB-DONGDOI", "BDNU-DONGDOI",
  "CL-DON-NAM45", "CL-DON-NAM46", "CL-DON-NU45", "CL-DOI-NAM45", "CL-DOI-NAM46", "CL-DOI-NU45", "CL-DOI-NAMNU45",
  "DK-NAM45-5K", "DK-NAM45-10K", "DK-NAM45-21K", "DK-NAM46-5K", "DK-NAM46-10K", "DK-NAM46-21K", "DK-NU45-5K", "DK-NU45-10K", "DK-NU46-10K",
  "KC-DONGDOI",
  "PBLD-DOI-NAM", "PBLD-DOI-NAMNU",
  "PB-DON-NAM45", "PB-DON-NAM46", "PB-DON-NU45", "PB-DON-NU46", "PB-DOI-NAM45", "PB-DOI-NAM46", "PB-DOI-NU45", "PB-DOI-NU46", "PB-DOI-NAMNU45", "PB-DOI-NAMNU46",
  "TEN-DON-NAM45", "TEN-DON-NAM46", "TEN-DOI-NAM45", "TEN-DOI-NAM46",
] as const;

const aliases = new Map([["TEN-DOI-NAM46-CHECK", "TEN-DOI-NAM46"]]);

export type PtscCategory = {
  code: string;
  sport_code: string;
  sport_slug: string;
  sport_name_vi: string;
  name_vi: string;
  kind: PtscKind;
  distance: string;
  group_count: number;
  capacity: string;
  format_branch: string;
  status: PtscStatus;
  source_note: string;
  source_row: number;
};

export type PtscPosition = {
  sheet: string;
  row_number: number;
  source_id: string;
  category_code: string;
  sport_code: string;
  sport_slug: string;
  group: string;
  normalized_group: string;
  slot_no: number;
  members: string[];
  reserves: string[];
  unit: string;
  note: string;
  pdf_page: number | null;
  kind: PtscKind;
  status: PtscStatus;
  natural_key: string;
  fingerprint: string;
  id_matches: boolean;
};

export type PtscValidationReport = { blockers: string[]; warnings: string[] };

export type ParsedPtscWorkbook = {
  template_version: number;
  sheets: readonly string[];
  sports: readonly PtscSport[];
  categories: PtscCategory[];
  positions: PtscPosition[];
  validation: PtscValidationReport;
};

export type PtscImportPayload = {
  parser_version: string;
  template_version: number;
  sports: readonly PtscSport[];
  categories: PtscCategory[];
  positions: PtscPosition[];
  stats: { sports: number; categories: number; positions: number; draft: number; pending_confirmation: number; active: number };
};

export function normalizePtscText(value: unknown) {
  return String(value ?? "").normalize("NFC").trim().replace(/\s+/gu, " ");
}

export function canonicalCategoryCode(value: unknown) {
  const code = normalizePtscText(value).toUpperCase();
  return aliases.get(code) ?? code;
}

export function normalizePtscGroup(value: unknown) {
  const group = normalizePtscText(value);
  return !group || group === "-" ? "X" : group.toUpperCase();
}

export function buildNaturalKey(categoryCode: unknown, group: unknown, slotNo: unknown) {
  const slot = Number(slotNo);
  return `${canonicalCategoryCode(categoryCode)}|${normalizePtscGroup(group)}|${Number.isInteger(slot) ? slot : normalizePtscText(slotNo)}`;
}

function statusFromText(value: unknown): PtscStatus {
  const text = normalizePtscText(value).toLowerCase();
  if (text.includes("chờ xác") || text.includes("pending") || text.includes("confirm")) return "pending_confirmation";
  if (text.includes("chờ nhập") || text.includes("draft") || text.includes("thiếu")) return "draft";
  if (text.includes("lưu trữ") || text.includes("archive")) return "archived";
  return "active";
}

function kindFromText(value: unknown, code = "") {
  const text = normalizePtscText(value).toLowerCase();
  if (text.includes("đội") || text.includes("team") || code.startsWith("BD") || code.startsWith("KC")) return "team" as const;
  if (text.includes("đôi") || text.includes("pair") || code.includes("-DOI-")) return "pair" as const;
  return "individual" as const;
}

const fallbackCategories: PtscCategory[] = categoryCodes.map((code, index) => {
  const sportCode = code.split("-")[0] === "PBLD" ? "PBLD" : code.split("-")[0];
  const sport = sportByCode.get(sportCode)!;
  return {
    code,
    sport_code: sport.code,
    sport_slug: sport.slug,
    sport_name_vi: sport.name_vi,
    name_vi: code,
    kind: kindFromText(code, code),
    distance: "",
    group_count: 0,
    capacity: "",
    format_branch: "",
    status: "active",
    source_note: "",
    source_row: index + 6,
  };
});

function categoryMap(categories: readonly PtscCategory[]) {
  return new Map(categories.map((category) => [canonicalCategoryCode(category.code), category]));
}

function stableJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(",")}]`;
  if (value && typeof value === "object") return `{${Object.entries(value as Record<string, unknown>).sort(([left], [right]) => left.localeCompare(right)).map(([key, item]) => `${JSON.stringify(key)}:${stableJson(item)}`).join(",")}}`;
  return JSON.stringify(value ?? null);
}

function positionFingerprint(position: Omit<PtscPosition, "fingerprint">) {
  return createHash("sha256").update(stableJson(position)).digest("hex");
}

export function validatePtscRows(rows: Array<Partial<PtscPosition> & { category_code?: string; group?: string; slot_no?: number; kind?: PtscKind; id_matches?: boolean }>, categories: readonly PtscCategory[] = fallbackCategories): PtscValidationReport {
  const blockers: string[] = [];
  const warnings: string[] = [];
  const byCode = categoryMap(categories);
  const seen = new Set<string>();
  for (const row of rows) {
    const location = `${row.sheet ?? "Workbook"}!${row.row_number ?? "?"}`;
    const code = canonicalCategoryCode(row.category_code);
    const category = byCode.get(code);
    if (!category) blockers.push(`${location}: sai mã hạng mục ${code || "(trống)"}`);
    const slot = Number(row.slot_no);
    if (!Number.isInteger(slot) || slot < 1) blockers.push(`${location}: slot phải là số nguyên lớn hơn 0`);
    const naturalKey = buildNaturalKey(code, row.group, row.slot_no);
    if (seen.has(naturalKey)) blockers.push(`${location}: khóa tự nhiên bị trùng ${naturalKey}`);
    seen.add(naturalKey);
    if (category && row.kind && category.kind !== row.kind) blockers.push(`${location}: loại entry ${row.kind} không khớp hạng mục ${category.kind}`);
    if (row.id_matches === false) blockers.push(`${location}: ID tự động không khớp mã hạng mục, bảng và STT`);
    if (category?.status === "pending_confirmation") warnings.push(`${location}: hạng mục đang chờ xác nhận BTC`);
  }
  return { blockers, warnings };
}

export function buildPtscImportPayload(parsed: ParsedPtscWorkbook): PtscImportPayload {
  const stats = {
    sports: parsed.sports.length,
    categories: parsed.categories.length,
    positions: parsed.positions.length,
    draft: parsed.positions.filter((row) => row.status === "draft").length,
    pending_confirmation: parsed.positions.filter((row) => row.status === "pending_confirmation").length,
    active: parsed.positions.filter((row) => row.status === "active").length,
  };
  return {
    parser_version: "ptsc-template-excel-v1",
    template_version: parsed.template_version,
    sports: parsed.sports,
    categories: parsed.categories,
    positions: parsed.positions,
    stats,
  };
}

function decodeXml(value: string) {
  return value.replace(/&#x([0-9a-f]+);/giu, (_, code) => String.fromCodePoint(Number.parseInt(code, 16)))
    .replace(/&#(\d+);/gu, (_, code) => String.fromCodePoint(Number(code)))
    .replace(/&amp;/gu, "&").replace(/&lt;/gu, "<").replace(/&gt;/gu, ">").replace(/&quot;/gu, '"').replace(/&apos;/gu, "'");
}

function attributes(tag: string) {
  const output = new Map<string, string>();
  for (const match of tag.matchAll(/([A-Za-z_][\w:.-]*)\s*=\s*"([^"]*)"/gu)) output.set(match[1], decodeXml(match[2]));
  return output;
}

function textTag(body: string, name: string) {
  const match = body.match(new RegExp(`<([A-Za-z_][\\w.-]*:)?${name}\\b[^>]*>([\\s\\S]*?)</(?:[A-Za-z_][\\w.-]*:)?${name}>`, "u"));
  return match ? decodeXml(match[2].replace(/<[^>]+>/gu, "")) : "";
}

type XmlCell = { value: string | number | boolean | null; formula: boolean };
type XmlSheet = Map<number, Map<number, XmlCell>>;

function columnNumber(ref: string) {
  const letters = ref.match(/[A-Z]+/iu)?.[0]?.toUpperCase() ?? "";
  let value = 0;
  for (const letter of letters) value = value * 26 + letter.charCodeAt(0) - 64;
  return value;
}

function parseSharedStrings(xml: string) {
  const values: string[] = [];
  for (const item of xml.matchAll(/<[^>]*\bsi\b[^>]*>([\s\S]*?)<\/[^>]*\bsi\s*>/gu)) {
    values.push(decodeXml([...item[1].matchAll(/<[^>]*\bt\b[^>]*>([\s\S]*?)<\/[^>]*\bt\s*>/gu)].map((match) => match[1]).join("")));
  }
  return values;
}

function parseWorksheet(xml: string, sharedStrings: string[]): XmlSheet {
  const rows: XmlSheet = new Map();
  for (const rowMatch of xml.matchAll(/<[^>]*\brow\b[^>]*>([\s\S]*?)<\/[^>]*\brow\s*>/gu)) {
    const rowTag = rowMatch[0].slice(0, rowMatch[0].indexOf(">") + 1);
    const rowNo = Number(attributes(rowTag).get("r"));
    if (!Number.isInteger(rowNo)) continue;
    const cells = new Map<number, XmlCell>();
    for (const cellMatch of rowMatch[1].matchAll(/<[^>]*\bc\b([^>]*?)(?:\/>|>([\s\S]*?)<\/[^>]*\bc\s*>)/gu)) {
      const cellAttrs = attributes(cellMatch[0]);
      const column = columnNumber(cellAttrs.get("r") ?? "");
      if (!column) continue;
      const body = cellMatch[2] ?? "";
      const formula = /<([A-Za-z_][\w.-]*:)?f\b/iu.test(body);
      const raw = textTag(body, "v") || textTag(body, "t") || textTag(body, "is");
      const type = cellAttrs.get("t");
      let value: string | number | boolean | null = raw || null;
      if (type === "s" && raw) value = sharedStrings[Number(raw)] ?? raw;
      else if (type === "b") value = raw === "1";
      else if (type === "n" && raw) value = Number(raw);
      cells.set(column, { value, formula });
    }
    rows.set(rowNo, cells);
  }
  return rows;
}

function rowValue(rows: XmlSheet, rowNo: number, column: number) {
  return rows.get(rowNo)?.get(column)?.value ?? null;
}

function rowHasData(rows: XmlSheet, rowNo: number, start: number, end: number) {
  for (let column = start; column <= end; column += 1) {
    const cell = rows.get(rowNo)?.get(column);
    if (cell && !cell.formula && normalizePtscText(cell.value)) return true;
  }
  return false;
}

function numeric(value: unknown) {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function sheetRows(workbookXml: string, relationshipsXml: string) {
  const relationships = new Map<string, string>();
  for (const match of relationshipsXml.matchAll(/<([A-Za-z_][\w.-]*:)?Relationship\b([^>]*)\/?>(?:<\/[^>]+>)?/gu)) {
    const attrs = attributes(match[0]);
    const id = attrs.get("Id");
    const target = attrs.get("Target");
    if (id && target) relationships.set(id, target);
  }
  const sheets: Array<{ name: string; path: string }> = [];
  for (const match of workbookXml.matchAll(/<([A-Za-z_][\w.-]*:)?sheet\b([^>]*)\/?>(?:<\/[^>]+>)?/gu)) {
    const attrs = attributes(match[0]);
    const name = attrs.get("name");
    const relation = attrs.get("r:id") ?? attrs.get("id");
    const target = relation ? relationships.get(relation) : null;
    if (!name || !target) continue;
    const path = target.startsWith("/") ? target.slice(1) : `xl/${target.replace(/^\.\//u, "")}`;
    if (!path.startsWith("xl/") || path.includes("..")) throw new Error("Workbook chứa relationship không an toàn");
    sheets.push({ name, path });
  }
  return sheets;
}

function expectedId(code: string, group: string, slot: number) {
  return `${code}-${normalizePtscGroup(group)}-${String(slot).padStart(2, "0")}`;
}

export async function parsePtscWorkbook(input: Buffer | ArrayBuffer): Promise<ParsedPtscWorkbook> {
  const bytes = Buffer.isBuffer(input) ? input : Buffer.from(input);
  if (!bytes.length || bytes.length > SPORT_EXCEL_MAX_BYTES) throw new Error("File Excel phải từ 1 byte đến 10 MB");
  await preflightZip(bytes);
  const zip = await JSZip.loadAsync(bytes);
  const paths = Object.keys(zip.files);
  if (paths.some((path) => /vbaProject\.bin|externalLinks?\//iu.test(path))) throw new Error("Không nhận macro hoặc external link trong workbook");
  const fileText = async (path: string) => {
    const file = zip.file(path);
    if (!file) throw new Error(`Thiếu thành phần workbook: ${path}`);
    return file.async("string");
  };
  const workbookXml = await fileText("xl/workbook.xml");
  const relationshipsXml = await fileText("xl/_rels/workbook.xml.rels");
  if (/externalLink|TargetMode\s*=\s*"External"/iu.test(relationshipsXml)) throw new Error("Không nhận external link trong workbook");
  const sharedStrings = paths.includes("xl/sharedStrings.xml") ? parseSharedStrings(await fileText("xl/sharedStrings.xml")) : [];
  const sheets = sheetRows(workbookXml, relationshipsXml);
  const names = sheets.map((sheet) => sheet.name);
  if (names.length !== PTSC_SHEET_NAMES.length || PTSC_SHEET_NAMES.some((name, index) => names[index] !== name)) throw new Error("Workbook phải có đúng 13 sheet PTSC theo đúng thứ tự");
  const parsedSheets = new Map<string, XmlSheet>();
  for (const sheet of sheets) parsedSheets.set(sheet.name, parseWorksheet(await fileText(sheet.path), sharedStrings));

  const categoryHeaders = ["MÃ HẠNG MỤC", "MÃ MÔN", "MÔN", "TÊN HẠNG MỤC", "LOẠI", "CỰ LY", "SỐ BẢNG", "QUY MÔ", "THỂ THỨC / NHÁNH", "TRẠNG THÁI", "GHI CHÚ NGUỒN", "KIỂM TRA"];
  const categorySheet = parsedSheets.get("HANG_MUC")!;
  const actualCategoryHeaders = Array.from({ length: categoryHeaders.length }, (_, index) => normalizePtscText(rowValue(categorySheet, 5, index + 1)).toUpperCase());
  if (categoryHeaders.some((header, index) => actualCategoryHeaders[index] !== header)) throw new Error(`Header HANG_MUC không đúng template PTSC: ${actualCategoryHeaders.join("|")} (rows=${categorySheet.size}, keys=${Array.from(categorySheet.keys()).slice(0, 8).join(",")})`);
  const categories: PtscCategory[] = [];
  for (let rowNo = 6; rowNo <= 50; rowNo += 1) {
    const code = canonicalCategoryCode(rowValue(categorySheet, rowNo, 1));
    if (!code) continue;
    const sportCode = normalizePtscText(rowValue(categorySheet, rowNo, 2)).toUpperCase();
    const sport = sportByCode.get(sportCode);
    if (!sport) continue;
    categories.push({
      code,
      sport_code: sportCode,
      sport_slug: sport.slug,
      sport_name_vi: normalizePtscText(rowValue(categorySheet, rowNo, 3)),
      name_vi: normalizePtscText(rowValue(categorySheet, rowNo, 4)),
      kind: kindFromText(rowValue(categorySheet, rowNo, 5), code),
      distance: normalizePtscText(rowValue(categorySheet, rowNo, 6)),
      group_count: numeric(rowValue(categorySheet, rowNo, 7)) ?? 0,
      capacity: normalizePtscText(rowValue(categorySheet, rowNo, 8)),
      format_branch: normalizePtscText(rowValue(categorySheet, rowNo, 9)),
      status: statusFromText(rowValue(categorySheet, rowNo, 10)),
      source_note: normalizePtscText(rowValue(categorySheet, rowNo, 11)),
      source_row: rowNo,
    });
  }
  if (categories.length !== PTSC_CATEGORY_COUNT) throw new Error(`HANG_MUC phải có đúng ${PTSC_CATEGORY_COUNT} hạng mục`);
  const byCode = categoryMap(categories);
  const positions: PtscPosition[] = [];
  for (const sheetName of PTSC_SHEET_NAMES.slice(2)) {
    const sheet = parsedSheets.get(sheetName)!;
    const sportCode = sportBySheet.get(sheetName)!;
    const headers = Array.from({ length: 14 }, (_, index) => normalizePtscText(rowValue(sheet, 7, index + 1)).toUpperCase());
    if (headers[1] !== "MÃ HẠNG MỤC" || headers[2] !== "BẢNG" || headers[3] !== "STT") throw new Error(`Header ${sheetName} không đúng template PTSC`);
    for (let rowNo = 8; rowNo <= 500; rowNo += 1) {
      if (!rowHasData(sheet, rowNo, 2, 14)) continue;
      const categoryCode = canonicalCategoryCode(rowValue(sheet, rowNo, 2));
      const category = byCode.get(categoryCode);
      const group = normalizePtscText(rowValue(sheet, rowNo, 3));
      const slotNo = numeric(rowValue(sheet, rowNo, 4));
      const memberCells = [5, 6, 7, 8].map((column) => normalizePtscText(rowValue(sheet, rowNo, column))).filter(Boolean);
      const reserves = normalizePtscText(rowValue(sheet, rowNo, 9)).split(";").map((value) => normalizePtscText(value)).filter(Boolean);
      const id = normalizePtscText(rowValue(sheet, rowNo, 1));
      const effectiveStatus = category?.status === "pending_confirmation" ? "pending_confirmation" : memberCells.length ? statusFromText(rowValue(sheet, rowNo, 13)) : "draft";
      const base: Omit<PtscPosition, "fingerprint"> = {
        sheet: sheetName,
        row_number: rowNo,
        source_id: id,
        category_code: categoryCode,
        sport_code: category?.sport_code ?? sportCode,
        sport_slug: category?.sport_slug ?? sportByCode.get(sportCode)?.slug ?? "",
        group,
        normalized_group: normalizePtscGroup(group),
        slot_no: slotNo ?? 0,
        members: memberCells,
        reserves,
        unit: normalizePtscText(rowValue(sheet, rowNo, 10)),
        note: normalizePtscText(rowValue(sheet, rowNo, 11)),
        pdf_page: numeric(rowValue(sheet, rowNo, 12)),
        kind: category?.kind ?? "individual",
        status: effectiveStatus,
        natural_key: buildNaturalKey(categoryCode, group, slotNo),
        id_matches: !id || !slotNo || id === expectedId(categoryCode, group, slotNo),
      };
      positions.push({ ...base, fingerprint: positionFingerprint(base) });
    }
  }
  const validation = validatePtscRows(positions, categories);
  if (positions.length !== PTSC_POSITION_COUNT) validation.warnings.push(`Workbook có ${positions.length} vị trí, baseline PTSC là ${PTSC_POSITION_COUNT}`);
  return { template_version: PTSC_TEMPLATE_VERSION, sheets: names, sports: PTSC_SPORTS, categories, positions, validation };
}
