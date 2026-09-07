"use client";

import { RefreshCw } from "lucide-react";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export function RefreshDataButton({ label, autoRefreshUntil }: { label: string; autoRefreshUntil?: string | null }) {
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    if (autoRefreshUntil && Date.parse(autoRefreshUntil) <= Date.now()) return;
    const interval = window.setInterval(() => {
      if (document.visibilityState === "visible") router.refresh();
    }, 300000);
    return () => window.clearInterval(interval);
  }, [autoRefreshUntil, router]);

  const refresh = () => {
    setRefreshing(true);
    router.refresh();
    window.setTimeout(() => setRefreshing(false), 500);
  };

  return <button className="refresh-data-button" type="button" onClick={refresh} disabled={refreshing} aria-label={label} title={label} data-refreshing={refreshing || undefined}>
    <RefreshCw size={16} aria-hidden="true"/>
  </button>;
}
