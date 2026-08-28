import type { Metadata } from "next";
import { LoadingFeedback } from "@/components/loading-feedback";
import "@fontsource-variable/lexend";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Hội Thao Tổng Công Ty Cổ Phần Dịch Vụ Kỹ Thuật Dầu Khí Việt Nam Lần Thứ 15", template: "%s | PTSC" },
  description: "Hội thao PTSC lần thứ 15",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="vi"><body><LoadingFeedback />{children}</body></html>;
}
