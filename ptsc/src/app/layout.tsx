import type { Metadata } from "next";
import { Suspense } from "react";
import { Analytics } from "@vercel/analytics/next";
import { LoadingFeedback } from "@/components/loading-feedback";
import "@fontsource-variable/lexend";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Hội thao Petrovietnam 2026", template: "%s | Petrovietnam 2026" },
  description: "Hội thao Petrovietnam 2026 khu vực phía Nam",
};

export const dynamic = "force-dynamic";

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="vi"><body><Suspense fallback={null}><LoadingFeedback /></Suspense>{children}<Analytics /></body></html>;
}
