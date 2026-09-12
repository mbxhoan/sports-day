"use client";

import { useEffect, useState } from "react";
import { copy, type Locale } from "@/lib/site";

function remaining(target: string, now: number) {
  const seconds = Math.max(0, Math.floor((new Date(target).getTime() - now) / 1000));
  return [Math.floor(seconds / 86400), Math.floor(seconds % 86400 / 3600), Math.floor(seconds % 3600 / 60), seconds % 60];
}

export function Countdown({ target, locale }: { target: string; locale: Locale }) {
  const [time, setTime] = useState<number[] | null>(null);
  useEffect(() => {
    const tick = () => setTime(remaining(target, Date.now()));
    tick();
    const timer = window.setInterval(tick, 1000);
    return () => window.clearInterval(timer);
  }, [target]);
  const labels = [copy[locale].days, copy[locale].hours, copy[locale].minutes, copy[locale].seconds];
  return <section className="countdown" aria-label={copy[locale].countdown}>
    <p>{copy[locale].countdown}</p>
    <div className="countdown-grid">
      {labels.map((label, index) => <div className="count-unit" key={label}>
        <b>{time ? String(time[index]).padStart(2, "0") : "--"}</b><span>{label}</span>
      </div>)}
    </div>
  </section>;
}
