import { SportPage } from "@/components/public-pages";
export default async function Page({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<{ tab?: string; tournament?: string }> }) { const [{ slug }, { tab, tournament }] = await Promise.all([params, searchParams]); return <SportPage locale="vi" slug={slug} tab={tab} tournamentSlug={tournament}/>; }
