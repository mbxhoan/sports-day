import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { tenantHeaders } from "@/lib/tenant";
import { withTimeout } from "@/lib/auth-timeout";

export async function proxy(request: NextRequest) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) return NextResponse.next({ request });

  let response = NextResponse.next({ request });
  const supabase = createServerClient(url, key, {
    global: { headers: tenantHeaders(), fetch: (input, init) => fetch(input, { ...init, signal: AbortSignal.timeout(10_000) }) },
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: (items) => {
        items.forEach(({ name, value }) => request.cookies.set(name, value));
        response = NextResponse.next({ request });
        items.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
      },
    },
  });
  try { await withTimeout(() => supabase.auth.getClaims(), 3_000); } catch { /* page guard handles failed auth */ }
  return response;
}

export const config = { matcher: ["/admin/:path*", "/login", "/en/login"] };
