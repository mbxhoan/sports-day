import type { Metadata } from "next";
import { Suspense } from "react";
import { Analytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";
import { LoadingFeedback } from "@/components/loading-feedback";
import "@fontsource-variable/lexend";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Hội thao PTSC 2026", template: "%s | PTSC 2026" },
  description: "Hội thao PTSC lần thứ 15",
};

export const dynamic = "force-dynamic";

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="vi"><body><Suspense fallback={null}><LoadingFeedback /></Suspense>{children}<Analytics /><SpeedInsights /></body></html>;
}
