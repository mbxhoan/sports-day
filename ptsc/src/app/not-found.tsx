import Link from "next/link";

export default function NotFound() {
  return <main className="container page-container"><section className="panel empty-state"><h1>Không tìm thấy trang</h1><p>Dữ liệu hoặc đường dẫn này không tồn tại.</p><Link className="gold-button" href="/">Về trang chủ</Link></section></main>;
}
