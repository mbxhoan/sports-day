import { SportPage } from "@/components/public-pages";
export default async function Page({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<{ tab?: string }> }) { const [{ slug }, { tab }] = await Promise.all([params, searchParams]); return <SportPage locale="vi" slug={slug} tab={tab}/>; }
