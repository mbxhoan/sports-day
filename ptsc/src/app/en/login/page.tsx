import { LoginPage } from "@/components/login-page";
export default function Page({ searchParams }: { searchParams: Promise<{ error?: string }> }) { return <LoginPage locale="en" searchParams={searchParams}/>; }
