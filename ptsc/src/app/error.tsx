"use client";

import { useEffect } from "react";

export default function Error({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { if (process.env.NODE_ENV !== "production") console.error(error); }, [error]);
  return <main className="container page-container"><section className="panel empty-state" role="alert"><h1>Không thể tải dữ liệu</h1><p>Vui lòng thử lại sau ít phút.</p><button className="gold-button" onClick={() => reset()}>Thử lại</button></section></main>;
}
