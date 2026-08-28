import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { tenantHeaders, tenantSlug } from "@/lib/tenant";

export function hasSupabaseConfig() {
  return Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY && tenantSlug);
}

export async function createSupabaseServerClient() {
  const cookieStore = await cookies();
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) throw new Error("Supabase chưa được cấu hình");
  return createServerClient(url, key, {
    // Bound cold/failed Supabase requests so App Router never stays on loading.tsx forever.
    global: { headers: tenantHeaders(), fetch: (input, init) => fetch(input, { ...init, signal: AbortSignal.timeout(10_000) }) },
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll: (items) => {
        try { items.forEach(({ name, value, options }) => cookieStore.set(name, value, options)); }
        catch { /* Server Components cannot write cookies; proxy refreshes them. */ }
      },
    },
  });
}
