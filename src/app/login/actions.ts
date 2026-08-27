"use server";

import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function login(formData: FormData) {
  const locale = formData.get("locale") === "en" ? "en" : "vi";
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  if (!email || !password) redirect(`/${locale === "en" ? "en/" : ""}login?error=required`);
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) redirect(`/${locale === "en" ? "en/" : ""}login?error=invalid`);
  redirect("/admin");
}
