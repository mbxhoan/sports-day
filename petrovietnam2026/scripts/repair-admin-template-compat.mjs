import path from "node:path";
import { createRequire } from "node:module";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const ExcelJS = createRequire("/Users/leviackerman/Codes/sports-day/petrovietnam2026/package.json")("exceljs");

const root = "/Users/leviackerman/Codes/sports-day";
const sourceDir = path.join(root, "outputs/petrovietnam2026-assets-20260831");
const outputDir = path.join(root, "outputs/petrovietnam2026-admin-templates-20260901");
const files = process.argv[2] ? [process.argv[2]] : ["pickleball", "bong-ban", "cau-long", "boi-loi", "keo-co", "dien-kinh", "co-vua", "co-tuong"];
const technicalHeaders = new Set(["Mã / Ref", "Thao tác / Action", "Nguồn / Source", "Quy tắc điểm / Scoring", "Chi tiết JSON", "Mã nguồn / Source code"]);
const dateHeaders = new Set(["Ngày sinh / Date of birth", "Bắt đầu / Starts", "Kết thúc / Ends"]);

function text(value) { return value === null || value === undefined ? "" : String(value).trim(); }
function excelDate(value) { return typeof value === "number" ? new Date(Date.UTC(1899, 11, 30) + value * 86400000) : value; }

async function repair(slug) {
  const draft = await SpreadsheetFile.importXlsx(await FileBlob.load(path.join(outputDir, `${slug}.xlsx`)));
  const source = new ExcelJS.Workbook();
  await source.xlsx.readFile(path.join(sourceDir, `${slug}.xlsx`));
  for (const draftSheet of draft.worksheets.items) {
    const target = source.getWorksheet(draftSheet.name);
    if (!target) throw new Error(`${slug}: thiếu sheet ${draftSheet.name}`);
    const values = draftSheet.getUsedRange()?.values ?? [];
    for (let row = 0; row < values.length; row += 1) {
      for (let col = 0; col < values[row].length; col += 1) {
        const isDate = dateHeaders.has(text(values[0][col]));
        const cell = target.getCell(row + 1, col + 1);
        cell.value = row === 0 ? values[row][col] ?? null : isDate ? excelDate(values[row][col]) ?? null : values[row][col] ?? null;
        cell.numFmt = isDate ? "yyyy-mm-dd hh:mm" : "General";
      }
    }
    target.showGridLines = false;
    if (draftSheet.name === "HƯỚNG_DẪN") continue;
    const headers = values[0]?.map(text) ?? [];
    for (let col = 0; col < headers.length; col += 1) {
      const column = target.getColumn(col + 1);
      column.width = technicalHeaders.has(headers[col]) ? 2 : Math.min(42, Math.max(15, headers[col].length + 5));
      column.hidden = technicalHeaders.has(headers[col]);
      column.numFmt = "General";
    }
    for (let row = 1; row < values.length; row += 1) {
      for (let col = 0; col < headers.length; col += 1) {
        const cell = target.getCell(row + 1, col + 1);
        cell.style = { ...cell.style, numFmt: dateHeaders.has(headers[col]) ? "yyyy-mm-dd hh:mm" : "General" };
      }
    }
    target.views = [{ state: "frozen", ySplit: 1 }];
  }
  const guide = source.getWorksheet("HƯỚNG_DẪN");
  guide.mergeCells("A1:D1");
  guide.mergeCells("A2:D2");
  guide.getColumn(1).width = 24;
  guide.getColumn(2).width = 30;
  guide.getColumn(3).width = 72;
  guide.getColumn(4).width = 24;
  guide.getRow(1).height = 30;
  guide.getRow(2).height = 22;
  guide.getRow(1).font = { name: "Arial", size: 16, bold: true, color: { argb: "FFFFFFFF" } };
  guide.getRow(1).fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF07527F" } };
  guide.getRow(3).font = { name: "Arial", size: 10, bold: true, color: { argb: "FF07527F" } };
  guide.getRow(3).fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFD8EEF5" } };
  guide.eachRow((row, rowNumber) => { row.eachCell((cell) => { cell.font = { ...cell.font, name: "Arial", size: cell.font?.size ?? 10 }; cell.alignment = { ...cell.alignment, vertical: "top", wrapText: true }; }); if (rowNumber >= 4 && rowNumber <= 10) row.height = 30; });
  await source.xlsx.writeFile(path.join(outputDir, `${slug}.xlsx`));
}

await Promise.all(files.map(repair));
console.log(`Repaired ${files.length} workbooks for app ExcelJS import`);
