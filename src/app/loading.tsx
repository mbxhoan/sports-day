import { LoaderCircle } from "lucide-react";

export default function Loading() {
  return <div className="route-loading" role="status" aria-live="polite">
    <LoaderCircle className="loading-spinner" size={28} aria-hidden="true" />
    <span>Đang tải / Loading…</span>
  </div>;
}
