import { SportPage } from "@/components/public-pages";
export default async function Page({ params }: { params: Promise<{ slug: string }> }) { const { slug } = await params; return <SportPage locale="en" slug={slug}/>; }
