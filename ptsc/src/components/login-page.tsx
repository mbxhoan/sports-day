import { LockKeyhole, Mail, Trophy } from "lucide-react";
import Link from "next/link";
import { login } from "@/app/login/actions";
import { SiteShell } from "./site-shell";
import { SubmitButton } from "./submit-button";
import type { Locale } from "@/lib/site";

export async function LoginPage({ locale, searchParams }: { locale: Locale; searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;
  const en = locale === "en";
  return <SiteShell locale={locale}><div className="login-wrap"><section className="login-card">
    <div className="login-icon"><Trophy/></div>
    <h1>{en ? "Administrator sign in" : "Đăng nhập quản trị"}</h1>
    <p>{en ? "Manage Petrovietnam Sports Day 2026" : "Quản lý Hội thao Petrovietnam 2026"}</p>
    {error && <div className="form-error">{error === "required" ? (en ? "Enter email and password." : "Vui lòng nhập email và mật khẩu.") : error === "forbidden" ? (en ? "This account is not allowed to access the administrator area." : "Tài khoản chưa được cấp quyền quản trị.") : error === "session" ? (en ? "Your session expired. Please sign in again." : "Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.") : (en ? "Incorrect email or password." : "Email hoặc mật khẩu không đúng.")}</div>}
    <form action={login} className="login-form">
      <input type="hidden" name="locale" value={locale}/>
      <label><span><Mail size={15}/>{en ? "Email" : "Email"}</span><input name="email" type="email" autoComplete="email" required/></label>
      <label><span><LockKeyhole size={15}/>{en ? "Password" : "Mật khẩu"}</span><input name="password" type="password" autoComplete="current-password" required/></label>
      <label className="remember-login"><input name="remember" type="checkbox" defaultChecked/><span>{en ? "Remember me on this device" : "Ghi nhớ đăng nhập trên thiết bị này"}</span></label>
      <SubmitButton className="gold-button">{en ? "Sign in" : "Đăng nhập"}</SubmitButton>
    </form>
    <Link className="back-link" href={en ? "/en" : "/"}>← {en ? "Back to website" : "Về trang chủ"}</Link>
  </section></div></SiteShell>;
}
