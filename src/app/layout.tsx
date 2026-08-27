import type { Metadata } from "next";
import "@fontsource-variable/lexend";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Hội thao Petrovietnam 2026", template: "%s | Petrovietnam 2026" },
  description: "Hội thao Petrovietnam 2026 khu vực phía Nam",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="vi"><body>{children}</body></html>;
}
