import { Metadata } from "next";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import BlogCard from "@/components/BlogCard";
import { BlogPost } from "@/lib/types";
import { BRAND, SITE_URL, pageMetadata } from "@/lib/seo";

// Re-check for new posts every minute (no redeploy needed after publishing).
export const revalidate = 60;

export const metadata: Metadata = pageMetadata({
  title: `Handle & Knob Buying Guides | ${BRAND}`,
  description:
    "Plain-language guides on measuring hole spacing, choosing materials and finishes, and fitting cabinet handles, knobs and main door handles — from our Lahore hardware shop.",
  path: "/blog",
});

export default async function BlogIndexPage() {
  const { data } = await supabase
    .from("blog_posts")
    .select("slug, title, tag, excerpt, cover_image_url, content, published_at")
    .eq("published", true)
    .order("published_at", { ascending: false });

  const posts = (data ?? []) as Pick<
    BlogPost,
    "slug" | "title" | "tag" | "excerpt" | "cover_image_url" | "content" | "published_at"
  >[];

  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "CollectionPage",
        name: "Handle & Knob Buying Guides",
        url: `${SITE_URL}/blog`,
        isPartOf: { "@type": "WebSite", name: BRAND, url: SITE_URL },
        hasPart: posts.map((p) => ({
          "@type": "BlogPosting",
          headline: p.title,
          url: `${SITE_URL}/blog/${p.slug}`,
        })),
      },
      {
        "@type": "BreadcrumbList",
        itemListElement: [
          { "@type": "ListItem", position: 1, name: "Home", item: SITE_URL },
          { "@type": "ListItem", position: 2, name: "Guides", item: `${SITE_URL}/blog` },
        ],
      },
    ],
  };

  const [featured, ...rest] = posts;

  return (
    <div className="mx-auto max-w-[1400px] px-6 py-16">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      <nav aria-label="Breadcrumb" className="mb-6 font-body text-xs text-graphite">
        <ol className="flex flex-wrap items-center gap-1">
          <li><Link href="/" className="hover:text-ink">Home</Link></li>
          <li aria-hidden="true">/</li>
          <li className="text-ink" aria-current="page">Guides</li>
        </ol>
      </nav>

      <h1 className="max-w-3xl font-display text-5xl leading-[1.05] text-ink">
        Handle, knob and door hardware guides
      </h1>
      <p className="mt-5 max-w-prose font-body text-lg text-graphite">
        How to measure before you order, which material suits which room, and how to keep hardware
        looking new — practical advice from the team at Shahid Iqbal &amp; Co in Lahore.
      </p>

      {posts.length === 0 ? (
        <p className="mt-16 font-body text-graphite">New guides are on the way — check back soon.</p>
      ) : (
        <>
          <div className="mt-14 grid gap-10 md:grid-cols-2 md:items-center">
            <div className="relative aspect-[16/10] overflow-hidden bg-blacknickel">
              <Link href={`/blog/${featured.slug}`} aria-label={featured.title} className="block h-full w-full">
                {featured.cover_image_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={featured.cover_image_url} alt={featured.title} className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full w-full items-end border-b-4 border-brass p-8">
                    <span className="font-display text-6xl italic leading-none text-stone">{featured.tag || "Guide"}</span>
                  </div>
                )}
              </Link>
            </div>
            <div>
              <h2 className="font-display text-4xl leading-tight text-ink">
                <Link href={`/blog/${featured.slug}`} className="hover:text-brass">{featured.title}</Link>
              </h2>
              {featured.excerpt && <p className="mt-4 max-w-prose font-body text-graphite">{featured.excerpt}</p>}
              <Link
                href={`/blog/${featured.slug}`}
                className="mt-6 inline-block border-b-2 border-brass pb-1 font-body text-sm text-ink hover:text-brass"
              >
                Read the guide
              </Link>
            </div>
          </div>

          {rest.length > 0 && (
            <div className="mt-16 grid gap-x-8 gap-y-14 border-t border-nickel/30 pt-14 sm:grid-cols-2 lg:grid-cols-3">
              {rest.map((post) => (
                <BlogCard key={post.slug} post={post} />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
