import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const root = "/Users/leviackerman/Codes/sports-day";
const sourceDir = path.join(root, "outputs/petrovietnam2026-assets-20260831");
const outputDir = path.join(root, "outputs/petrovietnam2026-admin-templates-20260901");
const files = ["pickleball", "bong-ban", "cau-long", "boi-loi", "keo-co", "dien-kinh", "co-vua", "co-tuong"];
const relationTables = {
  "Môn / Sport": "sports",
  "Hạng mục / Tournament": "tournaments",
  "Đơn vị / Organization": "organizations",
  "VĐV / Athlete": "participants",
  "Đội / Entry": "entries",
  "Địa điểm / Venue": "venues",
  "Sân / Court": "courts",
  "Bảng / Group": "groups",
  "Trận / Fixture": "fixtures",
  "Trận kế / Next fixture": "fixtures",
  "Đội thắng / Winner": "entries",
  "Đội nguồn / Entry": "entries",
  "Bảng nguồn / Group": "groups",
  "Trận nguồn / Fixture": "fixtures",
};
const technicalHeaders = new Set(["Mã / Ref", "Thao tác / Action", "Nguồn / Source", "Quy tắc điểm / Scoring", "Chi tiết JSON", "Mã nguồn / Source code"]);
const tableBySheet = {
  "MÔN": "sports",
  "HẠNG_MỤC": "tournaments",
  "ĐƠN_VỊ": "organizations",
  "VĐV": "participants",
  "ĐỘI": "entries",
  "THÀNH_VIÊN": "entry_members",
  "ĐỊA_ĐIỂM": "venues",
  "SÂN_LÀN": "courts",
  "BẢNG_ĐẤU": "groups",
  "ĐỘI_TRONG_BẢNG": "group_entries",
  "TRẬN_ĐẤU": "fixtures",
  "KẾT_QUẢ": "fixture_entries",
  "NGUỒN_NHÁNH": "fixture_slots",
  "BXH": "standings",
  "HUY_CHƯƠNG": "awards",
};
const labelHeaders = {
  sports: "Tên VI",
  tournaments: "Tên VI",
  organizations: "Tên VI",
  participants: "Họ tên",
  entries: "Tên VI",
  venues: "Tên VI",
  courts: "Tên VI",
  groups: "Tên VI",
};

function text(value) {
  return value === null || value === undefined ? "" : String(value).trim();
}

function columnLetter(index) {
  let result = "";
  for (let n = index; n > 0; n = Math.floor((n - 1) / 26)) result = String.fromCharCode(65 + ((n - 1) % 26)) + result;
  return result;
}

function styleGuide(sheet, lastRow) {
  sheet.showGridLines = false;
  sheet.getRange(`A1:D${lastRow}`).format.font = { name: "Arial", size: 10, color: "#123047" };
  sheet.getRange("A1:D1").format = { fill: "#07527F", font: { name: "Arial", size: 16, bold: true, color: "#FFFFFF" }, rowHeight: 30 };
  sheet.getRange("A3:D3").format = { fill: "#D8EEF5", font: { name: "Arial", size: 10, bold: true, color: "#07527F" } };
  sheet.getRange(`A4:D${lastRow}`).format.borders = { preset: "inside", style: "thin", color: "#D8E5EA" };
  sheet.getRange(`A1:D${lastRow}`).format.wrapText = true;
  sheet.mergeCells("A1:D1");
  sheet.mergeCells("A2:D2");
  sheet.getRange(`A4:D${Math.min(lastRow, 10)}`).format.rowHeight = 30;
  sheet.getRange("A:A").format.columnWidth = 24;
  sheet.getRange("B:B").format.columnWidth = 30;
  sheet.getRange("C:C").format.columnWidth = 72;
  sheet.getRange("D:D").format.columnWidth = 24;
}

async function cleanWorkbook(slug) {
  const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(path.join(sourceDir, `${slug}.xlsx`)));
  const lookupSheet = workbook.worksheets.getItem("_LOOKUP");
  const lookupValues = lookupSheet.getUsedRange().values;
  const labels = new Map();
  const records = [];
  for (const sheet of workbook.worksheets.items) {
    if (["HƯỚNG_DẪN", "_LOOKUP", "_META"].includes(sheet.name)) continue;
    const used = sheet.getUsedRange();
    if (!used) continue;
    const values = used.values;
    const headers = values[0].map(text);
    const table = tableBySheet[sheet.name];
    const refIndex = headers.indexOf("Mã / Ref");
    const labelIndex = table ? headers.indexOf(labelHeaders[table]) : -1;
    if (table && refIndex >= 0) for (let row = 1; row < values.length; row += 1) {
      const ref = text(values[row][refIndex]);
      if (!ref) continue;
      const label = labelIndex >= 0 ? text(values[row][labelIndex]) : "";
      if (label) labels.set(`${table}:${ref}`, label);
    }
    records.push({ sheet, used, values, headers, table });
  }
  for (const record of records.filter((item) => item.table === "fixtures")) {
    const refIndex = record.headers.indexOf("Mã / Ref");
    const roundIndex = record.headers.indexOf("Vòng VI");
    const tournamentIndex = record.headers.indexOf("Hạng mục / Tournament");
    const groupIndex = record.headers.indexOf("Bảng / Group");
    const sourceIndex = record.headers.indexOf("Mã nguồn / Source code");
    for (let row = 1; row < record.values.length; row += 1) {
      const ref = text(record.values[row][refIndex]);
      if (!ref) continue;
      const tournament = labels.get(`tournaments:${text(record.values[row][tournamentIndex])}`);
      const group = labels.get(`groups:${text(record.values[row][groupIndex])}`);
      const label = [text(record.values[row][roundIndex]), tournament, group].filter(Boolean).join(" · ") || text(record.values[row][sourceIndex]) || ref;
      labels.set(`fixtures:${ref}`, label);
    }
  }
  const labelCounts = new Map();
  const labelOccurrences = new Map();
  const friendlyLabels = new Map();
  for (const [key, label] of labels) {
    const table = key.split(":")[0];
    const countKey = table + ":" + label;
    labelCounts.set(countKey, (labelCounts.get(countKey) ?? 0) + 1);
  }
  for (const [key, label] of labels) {
    const table = key.split(":")[0];
    const countKey = table + ":" + label;
    const occurrence = (labelOccurrences.get(countKey) ?? 0) + 1;
    labelOccurrences.set(countKey, occurrence);
    friendlyLabels.set(key, (labelCounts.get(countKey) ?? 0) > 1 ? `${label} (${occurrence})` : label);
  }
  const guide = workbook.worksheets.getItem("HƯỚNG_DẪN");
  const counts = [];

  for (const record of records) {
    const { sheet, used, values, headers } = record;
    sheet.showGridLines = false;
    counts.push([sheet.name, Math.max(0, values.length - 1)]);
    for (let col = 0; col < headers.length; col += 1) {
      const header = headers[col];
      const relationTable = relationTables[header];
      if (!relationTable) continue;
      for (let row = 1; row < values.length; row += 1) {
        const value = text(values[row][col]);
        const label = friendlyLabels.get(`${relationTable}:${value}`);
        if (label) values[row][col] = label;
      }
    }
    const order = headers.map((header, index) => ({ header, index })).sort((left, right) => Number(technicalHeaders.has(left.header)) - Number(technicalHeaders.has(right.header)) || left.index - right.index);
    used.values = values.map((row) => order.map(({ index }) => row[index] ?? null));
    const orderedHeaders = order.map(({ header }) => header);
    for (let col = 0; col < orderedHeaders.length; col += 1) {
      const header = orderedHeaders[col];
      const width = technicalHeaders.has(header) ? 2 : Math.min(42, Math.max(15, header.length + 5));
      const letter = columnLetter(col + 1);
      const columnRange = sheet.getRange(`${letter}1:${letter}${values.length}`);
      columnRange.format.columnWidth = width;
      if (technicalHeaders.has(header)) {
        columnRange.format.fill = "#FFFFFF";
        sheet.getRange(`${letter}1`).format = { fill: "#07527F", font: { color: "#07527F" } };
        sheet.getRange(`${letter}2:${letter}${values.length}`).format.font = { color: "#FFFFFF" };
      }
    }
    used.format.wrapText = false;
    sheet.freezePanes.freezeRows(1);
  }

  const guideRows = [
    ["HƯỚNG DẪN NHẬP DỮ LIỆU", "", "", ""],
    [`Môn: ${slug}`, "", "", ""],
    ["Việc cần làm", "Sheet", "Cách làm", "Ghi chú"],
    ["Sửa hạng mục / đội / VĐV", "HẠNG_MỤC, ĐỘI, VĐV", "Sửa trực tiếp tên, đơn vị, seed hoặc thành viên.", "Không cần nhớ mã."],
    ["Sửa lịch / kết quả", "TRẬN_ĐẤU, KẾT_QUẢ", "Sửa thời gian, trạng thái, tỷ số hoặc điểm số.", "Kết quả được hệ thống kiểm tra lại."],
    ["Thêm dữ liệu", "Sheet tương ứng", "Thêm dòng cuối bảng, điền từ cột C trở đi.", "Mã và thao tác tự tạo khi nạp."],
    ["Cột kỹ thuật cuối sheet", "Mã / Ref, Action, JSON", "Để nguyên, hệ thống dùng nhận diện dòng.", "Không cần mở hoặc điền."],
    ["Tên liên kết", "Các cột tên", "Dùng tên dễ đọc đang hiển thị.", "Tên trùng thì lấy mã trong _LOOKUP."],
    ["Không dùng", "NGUỒN_NHÁNH", "Không sửa đường đi của nhánh.", "Sheet chỉ đọc."],
    ["An toàn", "Toàn workbook", "Nạp file sẽ có bước xem trước.", "Có lỗi chặn thì không ghi một phần."],
    ["Dữ liệu hiện có", "", "", ""],
    ...counts.map(([sheet, count]) => [sheet, count, "dòng", ""]),
  ];
  guide.getRange("A1:D40").clear({ applyTo: "all" });
  guide.getRange(`A1:D${guideRows.length}`).values = guideRows;
  styleGuide(guide, guideRows.length);

  for (let row = 1; row < lookupValues.length; row += 1) {
    const key = `${text(lookupValues[row][0])}:${text(lookupValues[row][1])}`;
    if (friendlyLabels.has(key)) lookupValues[row][2] = friendlyLabels.get(key);
  }
  lookupSheet.getUsedRange().values = lookupValues;
  lookupSheet.showGridLines = false;
  lookupSheet.getRange("A:A").format.columnWidth = 18;
  lookupSheet.getRange("B:B").format.columnWidth = 34;
  lookupSheet.getRange("C:C").format.columnWidth = 58;
  const meta = workbook.worksheets.getItem("_META");
  meta.showGridLines = false;
  await fs.mkdir(outputDir, { recursive: true });
  const output = await SpreadsheetFile.exportXlsx(workbook);
  await output.save(path.join(outputDir, `${slug}.xlsx`));
}

await Promise.all(files.map(cleanWorkbook));
console.log(`Created ${files.length} admin workbooks in ${outputDir}`);
