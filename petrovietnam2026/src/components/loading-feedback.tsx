"use client";

import { usePathname } from "next/navigation";
import { useEffect } from "react";

export function LoadingFeedback() {
  const pathname = usePathname();

  useEffect(() => {
    delete document.documentElement.dataset.routeLoading;
  }, [pathname]);

  useEffect(() => {
    const handleLinkClick = (event: MouseEvent) => {
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      const target = event.target instanceof Element ? event.target.closest("a") : null;
      if (!target || target.target === "_blank" || target.hasAttribute("download")) return;
      const url = new URL(target.href, window.location.href);
      if (url.origin !== window.location.origin || (url.pathname === window.location.pathname && url.search === window.location.search)) return;
      document.documentElement.dataset.routeLoading = "true";
    };
    const handleSubmit = (event: SubmitEvent) => {
      if (event.defaultPrevented) return;
      const form = event.target instanceof HTMLFormElement ? event.target : null;
      const button = event.submitter instanceof HTMLButtonElement ? event.submitter : form?.querySelector<HTMLButtonElement>("button[type=submit], button:not([type])");
      if (!form || !button) return;
      form.dataset.pending = "true";
      button.dataset.pending = "true";
      button.disabled = true;
      button.setAttribute("aria-busy", "true");
    };
    document.addEventListener("click", handleLinkClick);
    document.addEventListener("submit", handleSubmit);
    return () => {
      document.removeEventListener("click", handleLinkClick);
      document.removeEventListener("submit", handleSubmit);
    };
  }, []);

  return null;
}
