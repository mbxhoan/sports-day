"use client";

import { RefreshCw } from "lucide-react";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export function RefreshDataButton({ label }: { label: string }) {
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    const interval = window.setInterval(() => router.refresh(), 30000);
    return () => window.clearInterval(interval);
  }, [router]);

  const refresh = async () => {
    setRefreshing(true);
    try {
      if ("caches" in window) {
        await Promise.all((await window.caches.keys()).map((key) => window.caches.delete(key)));
      }
    } catch {
      // A full reload below is still useful when Cache Storage is unavailable.
    }
    const url = new URL(window.location.href);
    url.searchParams.set("_refresh", String(Date.now()));
    window.location.replace(url);
  };

  return <button className="refresh-data-button" type="button" onClick={refresh} disabled={refreshing} aria-label={label} title={label} data-refreshing={refreshing || undefined}>
    <RefreshCw size={16} aria-hidden="true"/>
  </button>;
}
