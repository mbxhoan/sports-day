import fs from "node:fs/promises";
import path from "node:path";
import ExcelJS from "exceljs";

const root = "/Users/leviackerman/Codes/sports-day";
const sourceDir = path.join(root, "outputs/petrovietnam2026-admin-templates-20260901");
const outputDir = path.join(root, "outputs/petrovietnam2026-result-templates-20260904");
const sports = ["pickleball", "bong-ban", "cau-long", "boi-loi", "keo-co", "dien-kinh", "co-vua", "co-tuong"];

function resultSheets(slug) {
  if (["co-vua", "co-tuong"].includes(slug)) return ["HƯỚNG_DẪN", "BXH", "_META"];
  if (["boi-loi", "dien-kinh"].includes(slug)) return ["HƯỚNG_DẪN", "TRẬN_ĐẤU", "KẾT_QUẢ", "BXH", "_META"];
  return ["HƯỚNG_DẪN", "TRẬN_ĐẤU", "KẾT_QUẢ", "_META"];
}

function headers(sheet) {
  return sheet.getRow(1).values.slice(1).map((value) => String(value ?? ""));
}

function hideExcept(sheet, visible) {
  for (const [index, header] of headers(sheet).entries()) sheet.getColumn(index + 1).hidden = !visible.has(header);
  sheet.views = [{ state: "frozen", ySplit: 1 }];
  sheet.autoFilter = { from: "A1", to: `${String.fromCharCode(64 + headers(sheet).length)}1` };
  sheet.getRow(1).font = { bold: true, color: { argb: "FFFFFFFF" } };
  sheet.getRow(1).fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF07527F" } };
}

await fs.mkdir(outputDir, { recursive: true });
for (const slug of sports) {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(path.join(sourceDir, `${slug}.xlsx`));
  for (const sheet of [...workbook.worksheets]) if (!resultSheets(slug).includes(sheet.name)) workbook.removeWorksheet(sheet.id);

  const guide = workbook.getWorksheet("HƯỚNG_DẪN");
  for (const merge of [...guide.model.merges]) guide.unMergeCells(merge);
  guide.spliceRows(1, guide.rowCount);
  guide.columns = [{ header: "HƯỚNG DẪN CẬP NHẬT KẾT QUẢ", key: "content", width: 110 }];
  guide.addRows([
    [`Môn: ${slug}`],
    [slug === "co-vua" || slug === "co-tuong" ? "1. Sheet BXH: nhập Điểm và Hạng theo biên bản tổng hợp." : "1. Sheet TRẬN_ĐẤU: đổi Trạng thái thành completed khi trận đã có kết quả."],
    [slug === "co-vua" || slug === "co-tuong" ? "2. Chỉ sửa ô Điểm và Hạng ở đúng dòng tên VĐV." : "2. Sheet KẾT_QUẢ: nhập tỷ số/thành tích vào đúng dòng tên người hoặc đội."],
    [slug === "co-vua" || slug === "co-tuong" ? "3. Không tự ghép cặp hoặc tự tính hạng; nhập đúng biên bản." : "3. Với bơi lội/điền kinh: nhập Làn, Tỷ số / Score, Hạng và Trạng thái KQ."],
    ["4. Chỉ sửa ô đang hiển thị. Không sửa tên người/đội, ID hoặc cột ẩn."],
    ["5. Lưu file rồi tải lên mục Excel admin để xem trước và áp dụng."],
  ]);
  guide.getRow(1).font = { bold: true, size: 16, color: { argb: "FFFFFFFF" } };
  guide.getRow(1).fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF07527F" } };
  guide.getColumn(1).alignment = { wrapText: true, vertical: "top" };
  guide.eachRow((row) => { row.height = 28; });

  const race = ["boi-loi", "dien-kinh"].includes(slug);
  if (workbook.getWorksheet("TRẬN_ĐẤU")) hideExcept(workbook.getWorksheet("TRẬN_ĐẤU"), new Set(["Hạng mục / Tournament", "Vòng VI", "Trạng thái / Status"]));
  if (workbook.getWorksheet("KẾT_QUẢ")) hideExcept(workbook.getWorksheet("KẾT_QUẢ"), new Set(["Trận / Fixture", "Đội / Entry", "Tỷ số / Score", ...(race ? ["Làn / Lane", "Hạng / Rank", "Trạng thái KQ / Result status"] : [])]));
  if (workbook.getWorksheet("BXH")) hideExcept(workbook.getWorksheet("BXH"), new Set(["Hạng mục / Tournament", "Đội / Entry", "Điểm", "Hạng"]));
  const meta = workbook.getWorksheet("_META");
  for (let row = meta.rowCount; row > 1; row--) if (["export_id", "sport_id"].includes(String(meta.getCell(row, 1).value ?? ""))) meta.spliceRows(row, 1);
  meta.addRow(["view", "results"]);
  await workbook.xlsx.writeFile(path.join(outputDir, `${slug}.xlsx`));
}

console.log(`Created ${sports.length} result workbooks in ${outputDir}`);
