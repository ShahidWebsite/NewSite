# ============================================================================
# Update 13 - SEO fixes + automatic SEO content + Guides (blog) + social share images
#
# BEFORE running this: paste migration-13-seo-and-blog.sql into Supabase SQL Editor and click Run.
#
# What this script does (you don't need to touch any code):
#   1. Pulls the latest code from GitHub
#   2. Writes 33 updated/new files
#   3. Commits and pushes - Vercel then deploys automatically
# ============================================================================
$repo = "$HOME\Desktop\NewSite"
$site = "$repo\cabinet-hardware-site"
$expectedBase = "5e843ed"

cd $repo
git pull origin main

# Safety check: this update was prepared against one specific version of the code.
$head = (git rev-parse HEAD).Trim()
if (-not $head.StartsWith($expectedBase)) {
    Write-Host ""
    Write-Host "STOP: the website code on GitHub has changed since this update was prepared." -ForegroundColor Red
    Write-Host "Nothing was changed. Please send Claude a message saying: repo changed ($head)" -ForegroundColor Red
    exit 1
}

function Write-SiteFile([string]$relativePath, [string]$content) {
    $full = [System.IO.Path]::Combine($site, $relativePath.Replace("/", "\"))
    $dir = [System.IO.Path]::GetDirectoryName($full)
    [System.IO.Directory]::CreateDirectory($dir) | Out-Null
    [System.IO.File]::WriteAllText($full, $content + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  wrote $relativePath"
}

Write-Host ""
Write-Host "Writing files..."

Write-SiteFile 'app/admin/blog/[id]/edit/page.tsx' @'
"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { supabase } from "@/lib/supabase";
import BlogPostForm from "@/components/admin/BlogPostForm";
import { BlogPost } from "@/lib/types";

export default function EditBlogPostPage() {
  const params = useParams();
  const [post, setPost] = useState<BlogPost | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase
      .from("blog_posts")
      .select("*")
      .eq("id", params.id as string)
      .single()
      .then(({ data }) => {
        setPost(data as BlogPost | null);
        setLoading(false);
      });
  }, [params.id]);

  if (loading) return <p className="font-body text-graphite">Loading…</p>;
  if (!post) return <p className="font-body text-rust">Post not found.</p>;

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Edit guide</h1>
      <BlogPostForm existing={post} />
    </div>
  );
}
'@

Write-SiteFile 'app/admin/blog/new/page.tsx' @'
import BlogPostForm from "@/components/admin/BlogPostForm";

export default function NewBlogPostPage() {
  return (
    <div>
      <h1 className="font-display text-3xl text-ink">New guide</h1>
      <BlogPostForm />
    </div>
  );
}
'@

Write-SiteFile 'app/admin/blog/page.tsx' @'
"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { BlogPost } from "@/lib/types";

type Row = Pick<BlogPost, "id" | "slug" | "title" | "tag" | "published" | "published_at" | "updated_at">;

export default function AdminBlogPage() {
  const [posts, setPosts] = useState<Row[] | null>(null);

  async function load() {
    const { data } = await supabase
      .from("blog_posts")
      .select("id, slug, title, tag, published, published_at, updated_at")
      .order("created_at", { ascending: false });
    setPosts((data ?? []) as Row[]);
  }

  useEffect(() => {
    load();
  }, []);

  async function handleDelete(post: Row) {
    if (!window.confirm(`Delete "${post.title}"? This cannot be undone.`)) return;
    await supabase.from("blog_posts").delete().eq("id", post.id);
    load();
  }

  async function togglePublished(post: Row) {
    const now = new Date().toISOString();
    await supabase
      .from("blog_posts")
      .update({
        published: !post.published,
        published_at: post.published_at ?? (!post.published ? now : null),
        updated_at: now,
      })
      .eq("id", post.id);
    load();
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="font-display text-3xl text-ink">Guides (blog)</h1>
        <Link href="/admin/blog/new" className="bg-ink px-4 py-2 font-body text-sm text-stone hover:bg-brass">
          + New guide
        </Link>
      </div>

      {posts === null ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : posts.length === 0 ? (
        <p className="mt-8 font-body text-graphite">
          No guides yet. If you just set up the blog, make sure the database update (SQL) has been run.
        </p>
      ) : (
        <table className="mt-8 w-full text-left font-body text-sm">
          <thead>
            <tr className="border-b border-nickel/40 text-graphite">
              <th className="py-2 font-normal">Title</th>
              <th className="py-2 font-normal">Status</th>
              <th className="py-2 font-normal" />
            </tr>
          </thead>
          <tbody>
            {posts.map((p) => (
              <tr key={p.id} className="border-b border-nickel/20">
                <td className="py-3 pr-4 text-ink">
                  {p.title}
                  {p.tag && <span className="ml-2 text-xs text-graphite">{p.tag}</span>}
                </td>
                <td className="py-3 pr-4">
                  <span className={p.published ? "text-olive" : "text-graphite"}>
                    {p.published ? "Published" : "Draft"}
                  </span>
                </td>
                <td className="space-x-4 py-3 text-right">
                  {p.published && (
                    <a href={`/blog/${p.slug}`} target="_blank" rel="noopener noreferrer" className="text-graphite hover:text-ink">
                      View
                    </a>
                  )}
                  <Link href={`/admin/blog/${p.id}/edit`} className="text-graphite hover:text-ink">Edit</Link>
                  <button onClick={() => togglePublished(p)} className="text-graphite hover:text-ink">
                    {p.published ? "Unpublish" : "Publish"}
                  </button>
                  <button onClick={() => handleDelete(p)} className="text-graphite hover:text-rust">Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
'@

Write-SiteFile 'app/blog/[slug]/page.tsx' @'
import { cache } from "react";
import { notFound } from "next/navigation";
import { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
import { supabase } from "@/lib/supabase";
import { Markdown, extractFaqs, extractHeadings, firstParagraph, readingMinutes } from "@/lib/markdown";
import ShareButtons from "@/components/ShareButtons";
import BlogCard from "@/components/BlogCard";
import { BlogPost } from "@/lib/types";
import {
  BRAND,
  PHONE,
  SITE_URL,
  generateBlogSeoTitle,
  ogImageUrl,
  pageMetadata,
  truncateAtWord,
} from "@/lib/seo";

// New or edited posts appear within a minute — no redeploy needed.
export const revalidate = 60;

const getPost = cache(async (slug: string): Promise<BlogPost | null> => {
  const { data } = await supabase
    .from("blog_posts")
    .select("*")
    .eq("slug", slug)
    .eq("published", true)
    .maybeSingle();
  return (data as BlogPost) ?? null;
});

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const post = await getPost(params.slug);
  if (!post) return {};

  const description =
    post.seo_description?.trim() ||
    post.excerpt?.trim() ||
    truncateAtWord(firstParagraph(post.content), 155);

  return pageMetadata({
    title: post.seo_title?.trim() || generateBlogSeoTitle(post.title),
    description,
    path: `/blog/${post.slug}`,
    // Own cover photo if one was uploaded, otherwise a branded card carrying the post title.
    image: post.cover_image_url || ogImageUrl({ title: post.title, tag: post.tag || undefined }),
    imageAlt: post.title,
    type: "article",
    publishedTime: post.published_at || post.created_at,
    modifiedTime: post.updated_at,
  });
}

export default async function BlogPostPage({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug);
  if (!post) notFound();

  const [{ data: moreRows }, { data: categoryRows }] = await Promise.all([
    supabase
      .from("blog_posts")
      .select("slug, title, tag, excerpt, cover_image_url, content, published_at")
      .eq("published", true)
      .neq("slug", post.slug)
      .order("published_at", { ascending: false })
      .limit(3),
    supabase.from("categories").select("name, slug").order("sort_order"),
  ]);
  const more = moreRows ?? [];
  const categories = categoryRows ?? [];

  const headings = extractHeadings(post.content).filter((h) => !/faq|frequently asked/i.test(h.text));
  const faqs = extractFaqs(post.content);
  const minutes = readingMinutes(post.content);
  const url = `${SITE_URL}/blog/${post.slug}`;
  const published = post.published_at || post.created_at;
  const description =
    post.seo_description?.trim() || post.excerpt?.trim() || truncateAtWord(firstParagraph(post.content), 155);

  const graph: Record<string, unknown>[] = [
    {
      "@type": "BlogPosting",
      headline: post.title,
      description,
      image: [post.cover_image_url || ogImageUrl({ title: post.title, tag: post.tag || undefined })],
      datePublished: published,
      dateModified: post.updated_at,
      articleSection: post.tag || undefined,
      inLanguage: "en",
      mainEntityOfPage: { "@type": "WebPage", "@id": url },
      author: { "@type": "Organization", name: BRAND, url: SITE_URL },
      publisher: {
        "@type": "Organization",
        name: BRAND,
        url: SITE_URL,
        logo: { "@type": "ImageObject", url: `${SITE_URL}/logo.png` },
      },
    },
    {
      "@type": "BreadcrumbList",
      itemListElement: [
        { "@type": "ListItem", position: 1, name: "Home", item: SITE_URL },
        { "@type": "ListItem", position: 2, name: "Guides", item: `${SITE_URL}/blog` },
        { "@type": "ListItem", position: 3, name: post.title, item: url },
      ],
    },
  ];
  if (faqs.length > 0) {
    graph.push({
      "@type": "FAQPage",
      mainEntity: faqs.map((f) => ({
        "@type": "Question",
        name: f.q,
        acceptedAnswer: { "@type": "Answer", text: f.a },
      })),
    });
  }
  const jsonLd = { "@context": "https://schema.org", "@graph": graph };

  return (
    <article className="mx-auto max-w-6xl px-6 py-16">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      <div className="mx-auto max-w-3xl">
        <nav aria-label="Breadcrumb" className="mb-8 font-body text-xs text-graphite">
          <ol className="flex flex-wrap items-center gap-1">
            <li><Link href="/" className="hover:text-ink">Home</Link></li>
            <li aria-hidden="true">/</li>
            <li><Link href="/blog" className="hover:text-ink">Guides</Link></li>
            <li aria-hidden="true">/</li>
            <li className="text-ink" aria-current="page">{post.title}</li>
          </ol>
        </nav>

        <h1 className="font-display text-4xl leading-[1.08] text-ink md:text-5xl">{post.title}</h1>
        {post.excerpt && <p className="mt-5 font-display text-xl italic leading-snug text-graphite">{post.excerpt}</p>}
        <p className="mt-5 font-body text-sm text-graphite">
          By {BRAND}
          {" — "}
          <time dateTime={published}>
            {new Date(published).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}
          </time>
          {" — "}
          {minutes} min read
        </p>

        {post.cover_image_url && (
          <div className="relative mt-8 aspect-[16/9] overflow-hidden bg-nickel/10">
            <Image
              src={post.cover_image_url}
              alt={post.title}
              fill
              priority
              sizes="(min-width: 768px) 768px, 100vw"
              className="object-cover"
            />
          </div>
        )}

        {headings.length >= 3 && (
          <nav aria-label="In this guide" className="mt-10 border-l-2 border-brass pl-5">
            <p className="font-body text-sm text-ink">In this guide</p>
            <ol className="mt-2 space-y-1 font-body text-sm text-graphite">
              {headings.map((h) => (
                <li key={h.id}>
                  <a href={`#${h.id}`} className="hover:text-ink hover:underline">{h.text}</a>
                </li>
              ))}
            </ol>
          </nav>
        )}

        <div className="mt-6">
          <Markdown source={post.content} />
        </div>

        <div className="mt-14 border border-nickel/40 bg-white/50 p-6">
          <p className="font-display text-2xl text-ink">Ready to choose?</p>
          <p className="mt-2 font-body text-sm text-graphite">
            Every product page lists the exact size, finish and hole spacing. Not sure what fits? Send us
            your measurements on WhatsApp at {PHONE} and we will help you pick.
          </p>
          <div className="mt-4 flex flex-wrap gap-3">
            {categories.map((c) => (
              <Link
                key={c.slug}
                href={`/shop?category=${c.slug}`}
                className="border border-ink px-4 py-2 font-body text-sm text-ink hover:bg-ink hover:text-stone"
              >
                {c.name}
              </Link>
            ))}
            <a
              href="https://wa.me/923117798157"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-ink px-4 py-2 font-body text-sm text-stone hover:bg-brass"
            >
              Message us on WhatsApp
            </a>
          </div>
        </div>

        <div className="mt-8">
          <ShareButtons path={`/blog/${post.slug}`} text={post.title} />
        </div>
      </div>

      {more.length > 0 && (
        <section className="mt-20 border-t border-nickel/30 pt-14">
          <h2 className="font-display text-3xl text-ink">More guides</h2>
          <div className="mt-8 grid gap-8 md:grid-cols-3">
            {more.map((p) => (
              <BlogCard key={p.slug} post={p} />
            ))}
          </div>
        </section>
      )}
    </article>
  );
}
'@

Write-SiteFile 'app/blog/page.tsx' @'
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
    <div className="mx-auto max-w-6xl px-6 py-16">
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
'@

Write-SiteFile 'app/cart/layout.tsx' @'
import type { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

// Utility page — useful to customers, useless in Google search results.
export const metadata: Metadata = pageMetadata({
  title: "Your Cart | Shahid Iqbal & Co",
  path: "/cart",
  noindex: true,
});

export default function Layout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
'@

Write-SiteFile 'app/checkout/layout.tsx' @'
import type { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

// Utility page — useful to customers, useless in Google search results.
export const metadata: Metadata = pageMetadata({
  title: "Checkout | Shahid Iqbal & Co",
  path: "/checkout",
  noindex: true,
});

export default function Layout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
'@

Write-SiteFile 'app/og/route.tsx' @'
import { ImageResponse } from "next/og";

// Branded 1200x630 share card. This is the picture that appears when someone
// pastes a link to the site into WhatsApp, Facebook, Instagram DMs, LinkedIn
// or X. Blog posts pass ?title= so each one gets its own card.
export const runtime = "edge";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const title = (searchParams.get("title") || "").slice(0, 110);
  const tag = (searchParams.get("tag") || "").slice(0, 30);

  const headline = title || "Door handles, cabinet handles & knobs";
  const sub = title
    ? tag
      ? `${tag} guide from our Lahore shop`
      : "Hardware guides from our Lahore shop"
    : "Brass hardware from Lahore, delivered across Pakistan";

  const headlineSize = headline.length > 70 ? 54 : headline.length > 40 ? 64 : 76;

  return new ImageResponse(
    (
      <div
        style={{
          display: "flex",
          width: "100%",
          height: "100%",
          background: "#F7F7F7",
          position: "relative",
        }}
      >
        <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 16, background: "#A9832E", display: "flex" }} />
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
            width: "100%",
            padding: "56px 72px 56px 88px",
          }}
        >
          <div style={{ display: "flex", alignItems: "center" }}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={`${origin}/logo.png`} width={92} height={92} alt="" style={{ marginRight: 24 }} />
            <div style={{ display: "flex", fontSize: 38, color: "#2A2825", fontWeight: 700 }}>Shahid Iqbal &amp; Co</div>
          </div>

          <div style={{ display: "flex", flexDirection: "column" }}>
            <div style={{ display: "flex", fontSize: headlineSize, lineHeight: 1.1, color: "#1C1B19", fontWeight: 700, maxWidth: 1000 }}>
              {headline}
            </div>
            <div style={{ display: "flex", fontSize: 32, color: "#A9832E", marginTop: 26, fontWeight: 700 }}>{sub}</div>
          </div>

          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 26, color: "#57534C" }}>
            <div style={{ display: "flex" }}>www.siqbalhwc.com</div>
            <div style={{ display: "flex" }}>WhatsApp +92 311 7798157</div>
          </div>
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
      headers: {
        "Cache-Control": "public, max-age=86400, s-maxage=604800, stale-while-revalidate=86400",
      },
    }
  );
}
'@

Write-SiteFile 'app/track-order/layout.tsx' @'
import type { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

// Utility page — useful to customers, useless in Google search results.
export const metadata: Metadata = pageMetadata({
  title: "Track Your Order | Shahid Iqbal & Co",
  path: "/track-order",
  noindex: true,
});

export default function Layout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
'@

Write-SiteFile 'components/BlogCard.tsx' @'
import Link from "next/link";
import Image from "next/image";
import { readingMinutes } from "@/lib/markdown";
import { BlogPost } from "@/lib/types";

type CardPost = Pick<BlogPost, "slug" | "title" | "tag" | "excerpt" | "cover_image_url" | "content"> & {
  published_at?: string | null;
};

export default function BlogCard({ post }: { post: CardPost }) {
  return (
    <Link href={`/blog/${post.slug}`} className="group flex h-full flex-col">
      <div className="relative aspect-[16/10] overflow-hidden bg-blacknickel">
        {post.cover_image_url ? (
          <Image
            src={post.cover_image_url}
            alt={post.title}
            fill
            sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
            className="object-cover transition-transform duration-300 group-hover:scale-[1.03]"
          />
        ) : (
          <div className="flex h-full w-full items-end border-b-4 border-brass p-6">
            <span className="font-display text-4xl italic leading-none text-stone">{post.tag || "Guide"}</span>
          </div>
        )}
      </div>
      <h3 className="mt-4 font-display text-2xl leading-snug text-ink group-hover:text-brass">{post.title}</h3>
      {post.excerpt && <p className="mt-2 font-body text-sm text-graphite">{post.excerpt}</p>}
      <p className="mt-3 font-body text-xs text-graphite">
        {post.published_at
          ? `${new Date(post.published_at).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })} — `
          : ""}
        {readingMinutes(post.content)} min read
      </p>
    </Link>
  );
}
'@

Write-SiteFile 'components/ShareButtons.tsx' @'
import { absoluteUrl } from "@/lib/seo";

// Plain links (no JavaScript needed) that open WhatsApp / Facebook with the
// page already filled in. The preview card people see comes from the page's
// Open Graph image (lib/seo.ts).
export default function ShareButtons({ path, text }: { path: string; text: string }) {
  const url = absoluteUrl(path);
  const whatsapp = `https://wa.me/?text=${encodeURIComponent(`${text} ${url}`)}`;
  const facebook = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`;
  const cls =
    "border border-nickel/50 px-3 py-1.5 font-body text-xs text-graphite transition-colors hover:border-ink hover:text-ink";

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="font-body text-xs text-graphite">Share on</span>
      <a href={whatsapp} target="_blank" rel="noopener noreferrer" className={cls}>
        WhatsApp
      </a>
      <a href={facebook} target="_blank" rel="noopener noreferrer" className={cls}>
        Facebook
      </a>
    </div>
  );
}
'@

Write-SiteFile 'components/admin/BlogPostForm.tsx' @'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import SeoFields from "@/components/admin/SeoFields";
import { firstParagraph } from "@/lib/markdown";
import { generateBlogSeoDescription, generateBlogSeoTitle, slugify, truncateAtWord } from "@/lib/seo";
import { BlogPost } from "@/lib/types";

const STORAGE_BUCKET = "product-images"; // same bucket as product photos, in a "blog/" folder

export default function BlogPostForm({ existing }: { existing?: BlogPost }) {
  const router = useRouter();
  const isEdit = !!existing;

  const [title, setTitle] = useState(existing?.title ?? "");
  const [tag, setTag] = useState(existing?.tag ?? "");
  const [content, setContent] = useState(existing?.content ?? "");
  const [slugOverride, setSlugOverride] = useState<string | null>(existing ? existing.slug : null);
  const [excerptOverride, setExcerptOverride] = useState<string | null>(existing?.excerpt ? existing.excerpt : null);
  const [seoTitleOverride, setSeoTitleOverride] = useState<string | null>(existing?.seo_title || null);
  const [seoDescOverride, setSeoDescOverride] = useState<string | null>(existing?.seo_description || null);
  const [published, setPublished] = useState(existing?.published ?? false);
  const [coverUrl, setCoverUrl] = useState<string | null>(existing?.cover_image_url ?? null);
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showHelp, setShowHelp] = useState(false);

  // ---- Automatic values, built from what's been written ----
  const slug = slugOverride ?? slugify(title);
  const autoExcerpt = truncateAtWord(firstParagraph(content), 160);
  const excerpt = excerptOverride ?? autoExcerpt;
  const autoSeoTitle = title ? generateBlogSeoTitle(title) : "";
  const autoSeoDescription = excerpt ? generateBlogSeoDescription(excerpt) : "";
  const seoTitle = seoTitleOverride ?? autoSeoTitle;
  const seoDescription = seoDescOverride ?? autoSeoDescription;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);

    try {
      if (!slug) throw new Error("Please add a title.");

      let cover = coverUrl;
      if (coverFile) {
        const cleanName = coverFile.name.replace(/[^a-zA-Z0-9._-]/g, "-");
        const path = `blog/${Date.now()}-${cleanName}`;
        const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, coverFile);
        if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);
        cover = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path).data.publicUrl;
      }

      const now = new Date().toISOString();
      const payload = {
        slug,
        title: title.trim(),
        tag: tag.trim() || null,
        excerpt: excerpt.trim() || null,
        content,
        cover_image_url: cover,
        seo_title: seoTitleOverride?.trim() || null, // null = generated automatically
        seo_description: seoDescOverride?.trim() || null,
        published,
        // First time it goes live, stamp the date; keep the original date afterwards.
        published_at: published ? existing?.published_at ?? now : existing?.published_at ?? null,
        updated_at: now,
      };

      const result = isEdit
        ? await supabase.from("blog_posts").update(payload).eq("id", existing!.id)
        : await supabase.from("blog_posts").insert(payload);
      if (result.error) {
        throw new Error(
          result.error.message.includes("duplicate")
            ? "Another post already uses this web address — change the title or the web address."
            : result.error.message
        );
      }

      router.push("/admin/blog");
    } catch (err: any) {
      setError(err.message || "Something went wrong saving this post.");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mt-8 max-w-3xl space-y-8">
      {error && (
        <div className="border-2 border-rust bg-rust/10 p-4">
          <p className="font-body text-sm font-medium text-rust">Could not save this post:</p>
          <p className="mt-1 font-body text-sm text-rust">{error}</p>
        </div>
      )}

      <div className="space-y-4">
        <label className="block">
          <span className="font-body text-sm text-graphite">Title</span>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            placeholder="e.g. How to measure cabinet handle hole spacing"
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
          />
        </label>

        <label className="block">
          <span className="font-body text-sm text-graphite">Topic (one or two words, e.g. Sizing, Materials, Care)</span>
          <input
            value={tag}
            onChange={(e) => setTag(e.target.value)}
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
          />
        </label>

        <div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Web address</span>
            <div className="mt-1 flex items-center border border-nickel/50">
              <span className="px-3 font-body text-sm text-graphite">/blog/</span>
              <input
                value={slug}
                onChange={(e) => setSlugOverride(slugify(e.target.value) || null)}
                disabled={isEdit}
                className="w-full bg-transparent py-2 pr-3 font-body text-ink disabled:text-graphite"
              />
            </div>
          </label>
          <p className="mt-1 font-body text-xs text-graphite">
            {isEdit
              ? "The web address can't be changed after publishing, so existing links keep working."
              : "Made from the title automatically. Keep it short and descriptive."}
          </p>
        </div>

        <div>
          <div className="flex items-center justify-between">
            <span className="font-body text-sm text-graphite">Article text</span>
            <button
              type="button"
              onClick={() => setShowHelp((v) => !v)}
              className="font-body text-xs text-graphite underline hover:text-ink"
            >
              {showHelp ? "Hide formatting help" : "Formatting help"}
            </button>
          </div>
          {showHelp && (
            <pre className="mt-2 overflow-x-auto border border-nickel/30 bg-white/50 p-3 font-body text-xs leading-relaxed text-graphite">
{`## A big heading
### A smaller heading
Normal paragraph text. **Bold**, *italic*, [a link](/shop?category=cabinet-handles)

- A bullet point
- Another bullet point

1. First step
2. Second step

| Size | Best for |
|---|---|
| 96mm | Drawers |
| 128mm | Wardrobe doors |

## Frequently asked questions
### A question a customer might ask?
The answer, in a normal paragraph.`}
            </pre>
          )}
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            required
            rows={24}
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm leading-relaxed text-ink"
          />
          <p className="mt-1 font-body text-xs text-graphite">
            Tip: aim for 600+ words that genuinely answer a customer question. A section titled
            &quot;Frequently asked questions&quot; with a smaller heading for each question automatically
            becomes Google FAQ results.
          </p>
        </div>

        <div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Short summary (shown on the Guides page)</span>
            <textarea
              value={excerpt}
              onChange={(e) => setExcerptOverride(e.target.value === "" ? null : e.target.value)}
              rows={2}
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            />
          </label>
          <p className="mt-1 font-body text-xs text-graphite">
            {excerptOverride === null ? "Taken from the first paragraph automatically." : "Using your own wording."}
            {excerptOverride !== null && (
              <button type="button" onClick={() => setExcerptOverride(null)} className="ml-2 underline hover:text-ink">
                Reset to auto
              </button>
            )}
          </p>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">Cover photo (optional)</p>
          <p className="font-body text-xs text-graphite">
            If you skip this, a branded picture with the title is used automatically — including when the
            post is shared on WhatsApp or Facebook.
          </p>
          <div className="mt-2 flex items-center gap-4">
            {(coverFile || coverUrl) && (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={coverFile ? URL.createObjectURL(coverFile) : coverUrl!}
                alt=""
                className="h-20 w-32 border border-nickel/30 object-cover"
              />
            )}
            <label className="cursor-pointer border border-dashed border-nickel/50 px-4 py-2 font-body text-sm text-graphite hover:border-ink hover:text-ink">
              {coverFile || coverUrl ? "Change photo" : "+ Add photo"}
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => setCoverFile(e.target.files?.[0] ?? null)}
              />
            </label>
            {(coverFile || coverUrl) && (
              <button
                type="button"
                onClick={() => {
                  setCoverFile(null);
                  setCoverUrl(null);
                }}
                className="font-body text-sm text-graphite hover:text-rust"
              >
                Remove
              </button>
            )}
          </div>
        </div>
      </div>

      <SeoFields
        urlPreview={`www.siqbalhwc.com › blog › ${slug || "your-post"}`}
        title={seoTitle}
        description={seoDescription}
        titleIsAuto={seoTitleOverride === null}
        descriptionIsAuto={seoDescOverride === null}
        onTitleChange={(v) => setSeoTitleOverride(v === "" ? null : v)}
        onDescriptionChange={(v) => setSeoDescOverride(v === "" ? null : v)}
        onResetTitle={() => setSeoTitleOverride(null)}
        onResetDescription={() => setSeoDescOverride(null)}
      />

      <label className="flex items-center gap-3">
        <input type="checkbox" checked={published} onChange={(e) => setPublished(e.target.checked)} className="h-4 w-4" />
        <span className="font-body text-sm text-ink">
          Published — visible on the website {published ? "" : "(untick to keep it as a private draft)"}
        </span>
      </label>

      <button
        type="submit"
        disabled={saving}
        className="bg-ink px-6 py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
      >
        {saving ? "Saving…" : isEdit ? "Save changes" : "Save post"}
      </button>
    </form>
  );
}
'@

Write-SiteFile 'components/admin/SeoFields.tsx' @'
"use client";

// "How this appears on Google" editor, shared by the product and blog forms.
// The fields are filled in automatically from what the admin has typed. If the
// admin edits one, it is locked to their wording until they press "Reset to auto".

type Props = {
  urlPreview: string;
  title: string;
  description: string;
  titleIsAuto: boolean;
  descriptionIsAuto: boolean;
  onTitleChange: (v: string) => void;
  onDescriptionChange: (v: string) => void;
  onResetTitle: () => void;
  onResetDescription: () => void;
};

export default function SeoFields({
  urlPreview,
  title,
  description,
  titleIsAuto,
  descriptionIsAuto,
  onTitleChange,
  onDescriptionChange,
  onResetTitle,
  onResetDescription,
}: Props) {
  const titleLen = title.length;
  const descLen = description.length;

  return (
    <div className="space-y-4 border border-nickel/30 p-4">
      <div>
        <p className="font-body text-sm font-medium text-ink">Google search listing (SEO)</p>
        <p className="mt-1 font-body text-xs text-graphite">
          Filled in automatically from your details above. You can change either line — your wording is
          then kept until you press &quot;Reset to auto&quot;.
        </p>
      </div>

      {/* Live preview of the Google result */}
      <div className="border border-nickel/20 bg-white/60 p-4">
        <p className="truncate font-body text-xs text-olive">{urlPreview}</p>
        <p className="mt-1 font-body text-lg leading-snug text-[#1a0dab]">{title || "Page title appears here"}</p>
        <p className="mt-1 font-body text-sm text-graphite">{description || "Page description appears here."}</p>
      </div>

      <label className="block">
        <span className="flex items-center justify-between font-body text-sm text-graphite">
          <span>
            SEO title{" "}
            <span className={`text-xs ${titleIsAuto ? "text-olive" : "text-brass"}`}>
              {titleIsAuto ? "(auto)" : "(edited by you)"}
            </span>
          </span>
          <span className={`text-xs ${titleLen > 60 ? "text-rust" : "text-graphite"}`}>{titleLen}/60</span>
        </span>
        <input
          value={title}
          onChange={(e) => onTitleChange(e.target.value)}
          className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
        />
        {!titleIsAuto && (
          <button type="button" onClick={onResetTitle} className="mt-1 font-body text-xs text-graphite underline hover:text-ink">
            Reset to auto
          </button>
        )}
      </label>

      <label className="block">
        <span className="flex items-center justify-between font-body text-sm text-graphite">
          <span>
            SEO description{" "}
            <span className={`text-xs ${descriptionIsAuto ? "text-olive" : "text-brass"}`}>
              {descriptionIsAuto ? "(auto)" : "(edited by you)"}
            </span>
          </span>
          <span className={`text-xs ${descLen > 160 ? "text-rust" : "text-graphite"}`}>{descLen}/155</span>
        </span>
        <textarea
          value={description}
          onChange={(e) => onDescriptionChange(e.target.value)}
          rows={3}
          className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
        />
        {!descriptionIsAuto && (
          <button
            type="button"
            onClick={onResetDescription}
            className="mt-1 font-body text-xs text-graphite underline hover:text-ink"
          >
            Reset to auto
          </button>
        )}
      </label>
    </div>
  );
}
'@

Write-SiteFile 'lib/markdown.tsx' @'
import React from "react";
import Link from "next/link";

// A deliberately small markdown renderer for blog posts. It builds React
// elements directly (never raw HTML), so post content can't inject scripts.
//
// Supported: ## / ### headings, paragraphs, - bullet lists, 1. numbered lists,
// > quotes, --- dividers, | tables |, ![images](url), **bold**, *italic*,
// `code` and [links](url).

export type Block =
  | { type: "h2" | "h3"; text: string; id: string }
  | { type: "p"; text: string }
  | { type: "ul" | "ol"; items: string[] }
  | { type: "quote"; text: string }
  | { type: "hr" }
  | { type: "table"; head: string[]; rows: string[][] }
  | { type: "img"; alt: string; src: string };

export function headingId(text: string) {
  return stripInline(text)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

export function stripInline(text: string) {
  return text
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/\*([^*]+)\*/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\s+/g, " ")
    .trim();
}

function splitRow(line: string) {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split("|")
    .map((c) => c.trim());
}

const TABLE_SEPARATOR = /^\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?$/;

export function parseMarkdown(source: string): Block[] {
  const lines = source.replace(/\r\n?/g, "\n").split("\n");
  const blocks: Block[] = [];
  let para: string[] = [];

  const flushPara = () => {
    if (para.length) {
      blocks.push({ type: "p", text: para.join(" ").trim() });
      para = [];
    }
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trimEnd();
    const trimmed = line.trim();

    if (!trimmed) {
      flushPara();
      continue;
    }

    const heading = trimmed.match(/^(#{1,4})\s+(.+)$/);
    if (heading) {
      flushPara();
      const text = heading[2].trim();
      blocks.push({ type: heading[1].length <= 2 ? "h2" : "h3", text, id: headingId(text) });
      continue;
    }

    if (/^-{3,}$/.test(trimmed)) {
      flushPara();
      blocks.push({ type: "hr" });
      continue;
    }

    const image = trimmed.match(/^!\[([^\]]*)\]\(([^)\s]+)\)$/);
    if (image) {
      flushPara();
      blocks.push({ type: "img", alt: image[1], src: image[2] });
      continue;
    }

    if (trimmed.startsWith("|") && i + 1 < lines.length && TABLE_SEPARATOR.test(lines[i + 1].trim())) {
      flushPara();
      const head = splitRow(trimmed);
      const rows: string[][] = [];
      i += 2;
      while (i < lines.length && lines[i].trim().startsWith("|")) {
        rows.push(splitRow(lines[i]));
        i++;
      }
      i--; // the for-loop will advance again
      blocks.push({ type: "table", head, rows });
      continue;
    }

    if (/^>\s?/.test(trimmed)) {
      flushPara();
      const quote: string[] = [];
      while (i < lines.length && /^>\s?/.test(lines[i].trim())) {
        quote.push(lines[i].trim().replace(/^>\s?/, ""));
        i++;
      }
      i--;
      blocks.push({ type: "quote", text: quote.join(" ") });
      continue;
    }

    if (/^[-*]\s+/.test(trimmed)) {
      flushPara();
      const items: string[] = [];
      while (i < lines.length && /^[-*]\s+/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^[-*]\s+/, ""));
        i++;
      }
      i--;
      blocks.push({ type: "ul", items });
      continue;
    }

    if (/^\d+[.)]\s+/.test(trimmed)) {
      flushPara();
      const items: string[] = [];
      while (i < lines.length && /^\d+[.)]\s+/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^\d+[.)]\s+/, ""));
        i++;
      }
      i--;
      blocks.push({ type: "ol", items });
      continue;
    }

    para.push(trimmed);
  }
  flushPara();
  return blocks;
}

// ---------------------------------------------------------------------------
// Helpers used by the blog pages and the admin form
// ---------------------------------------------------------------------------

export function extractHeadings(source: string) {
  return parseMarkdown(source)
    .filter((b): b is Extract<Block, { type: "h2" | "h3" }> => b.type === "h2")
    .map((b) => ({ id: b.id, text: stripInline(b.text) }));
}

// Any "## Frequently asked questions" section followed by "### Question?"
// headings becomes FAQ structured data automatically — no extra admin work.
export function extractFaqs(source: string): { q: string; a: string }[] {
  const blocks = parseMarkdown(source);
  const faqs: { q: string; a: string }[] = [];
  let inFaq = false;
  let current: { q: string; a: string[] } | null = null;

  const push = () => {
    if (current && current.a.length) faqs.push({ q: current.q, a: current.a.join(" ") });
    current = null;
  };

  for (const b of blocks) {
    if (b.type === "h2") {
      push();
      inFaq = /faq|frequently asked/i.test(b.text);
      continue;
    }
    if (!inFaq) continue;
    if (b.type === "h3") {
      push();
      current = { q: stripInline(b.text), a: [] };
    } else if (current) {
      if (b.type === "p") current.a.push(stripInline(b.text));
      else if (b.type === "ul" || b.type === "ol") current.a.push(b.items.map(stripInline).join("; "));
    }
  }
  push();
  return faqs;
}

export function firstParagraph(source: string) {
  const p = parseMarkdown(source).find((b) => b.type === "p");
  return p && p.type === "p" ? stripInline(p.text) : "";
}

export function readingMinutes(source: string) {
  const words = stripInline(source).split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.round(words / 200));
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

function safeHref(href: string) {
  return /^(https?:\/\/|mailto:|tel:|\/|#)/i.test(href) ? href : "#";
}

const INLINE = /(\*\*[^*]+\*\*|\*[^*\s][^*]*\*|`[^`]+`|\[[^\]]+\]\([^)\s]+\))/g;

function renderInline(text: string, keyPrefix: string): React.ReactNode[] {
  return text.split(INLINE).map((part, i) => {
    const key = `${keyPrefix}-${i}`;
    if (!part) return null;
    if (part.startsWith("**") && part.endsWith("**")) return <strong key={key} className="font-medium text-ink">{part.slice(2, -2)}</strong>;
    if (part.startsWith("`") && part.endsWith("`")) return <code key={key} className="bg-nickel/15 px-1 text-[0.9em]">{part.slice(1, -1)}</code>;
    if (part.startsWith("*") && part.endsWith("*") && part.length > 2) return <em key={key}>{part.slice(1, -1)}</em>;
    const link = part.match(/^\[([^\]]+)\]\(([^)\s]+)\)$/);
    if (link) {
      const href = safeHref(link[2]);
      const cls = "text-ink underline decoration-brass decoration-2 underline-offset-4 hover:text-brass";
      if (href.startsWith("/")) return <Link key={key} href={href} className={cls}>{link[1]}</Link>;
      return (
        <a key={key} href={href} className={cls} rel="noopener noreferrer" target={href.startsWith("http") ? "_blank" : undefined}>
          {link[1]}
        </a>
      );
    }
    return <React.Fragment key={key}>{part}</React.Fragment>;
  });
}

export function Markdown({ source }: { source: string }) {
  const blocks = parseMarkdown(source);

  return (
    <div className="font-body text-[17px] leading-relaxed text-graphite">
      {blocks.map((b, i) => {
        const key = `b${i}`;
        switch (b.type) {
          case "h2":
            return (
              <h2 key={key} id={b.id} className="mt-14 scroll-mt-24 font-display text-3xl leading-tight text-ink">
                {renderInline(b.text, key)}
              </h2>
            );
          case "h3":
            return (
              <h3 key={key} id={b.id} className="mt-9 scroll-mt-24 font-display text-2xl leading-snug text-ink">
                {renderInline(b.text, key)}
              </h3>
            );
          case "p":
            return <p key={key} className="mt-4">{renderInline(b.text, key)}</p>;
          case "ul":
            return (
              <ul key={key} className="mt-4 list-disc space-y-2 pl-6 marker:text-brass">
                {b.items.map((it, j) => <li key={j}>{renderInline(it, `${key}-${j}`)}</li>)}
              </ul>
            );
          case "ol":
            return (
              <ol key={key} className="mt-4 list-decimal space-y-2 pl-6 marker:text-brass">
                {b.items.map((it, j) => <li key={j}>{renderInline(it, `${key}-${j}`)}</li>)}
              </ol>
            );
          case "quote":
            return (
              <blockquote key={key} className="mt-6 border-l-2 border-brass pl-5 font-display text-xl italic text-ink">
                {renderInline(b.text, key)}
              </blockquote>
            );
          case "hr":
            return <hr key={key} className="my-10 border-nickel/30" />;
          case "img":
            return (
              // eslint-disable-next-line @next/next/no-img-element
              <img key={key} src={b.src} alt={b.alt} loading="lazy" className="mt-6 w-full border border-nickel/20" />
            );
          case "table":
            return (
              <div key={key} className="mt-6 overflow-x-auto">
                <table className="w-full border-collapse text-left text-[15px]">
                  <thead>
                    <tr className="border-b border-ink/40">
                      {b.head.map((h, j) => (
                        <th key={j} className="py-2 pr-4 font-medium text-ink">{renderInline(h, `${key}-h${j}`)}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {b.rows.map((row, r) => (
                      <tr key={r} className="border-b border-nickel/25 align-top">
                        {row.map((cell, c) => (
                          <td key={c} className="py-2 pr-4">{renderInline(cell, `${key}-${r}-${c}`)}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            );
        }
      })}
    </div>
  );
}
'@

Write-SiteFile 'lib/seo.ts' @'
import type { Metadata } from "next";

// ---------------------------------------------------------------------------
// Site-wide constants. Everything that talks to Google or social networks
// reads the business name / phone / domain from here, so they stay identical
// everywhere (Google compares them across the web — consistency matters).
// ---------------------------------------------------------------------------

export const SITE_URL = (process.env.NEXT_PUBLIC_SITE_URL || "https://www.siqbalhwc.com").replace(/\/$/, "");
export const BRAND = "Shahid Iqbal & Co";
export const PHONE = "+92 311 7798157";

export function absoluteUrl(path: string) {
  if (/^https?:\/\//i.test(path)) return path;
  return `${SITE_URL}${path.startsWith("/") ? path : `/${path}`}`;
}

// The branded 1200x630 card used when a page has no photo of its own.
// Served by app/og/route.tsx. WhatsApp, Facebook, Instagram DMs, LinkedIn and
// X all read this when someone shares a link.
export function ogImageUrl(opts?: { title?: string; tag?: string }) {
  const params = new URLSearchParams();
  if (opts?.title) params.set("title", opts.title);
  if (opts?.tag) params.set("tag", opts.tag);
  const qs = params.toString();
  return `${SITE_URL}/og${qs ? `?${qs}` : ""}`;
}

type PageMeta = {
  title: string;
  description?: string;
  path: string; // e.g. "/about" — becomes the canonical URL
  image?: string; // absolute URL of a photo; defaults to the branded card
  imageAlt?: string;
  noindex?: boolean;
  type?: "website" | "article";
  publishedTime?: string;
  modifiedTime?: string;
};

// One function that builds the complete <head> metadata for a page, including
// its OWN canonical URL. Next.js merges metadata shallowly, so every page must
// state its own canonical + social tags — otherwise it silently inherits the
// homepage's (that was the canonical bug).
export function pageMetadata(o: PageMeta): Metadata {
  const url = absoluteUrl(o.path);
  const image = o.image || ogImageUrl();
  const isCard = !o.image || image.startsWith(`${SITE_URL}/og`);

  const openGraph: Record<string, unknown> = {
    type: o.type || "website",
    url,
    siteName: BRAND,
    locale: "en_PK",
    title: o.title,
    description: o.description,
    images: [
      {
        url: image,
        alt: o.imageAlt || o.title,
        ...(isCard ? { width: 1200, height: 630 } : {}),
      },
    ],
  };
  if (o.type === "article") {
    if (o.publishedTime) openGraph.publishedTime = o.publishedTime;
    if (o.modifiedTime) openGraph.modifiedTime = o.modifiedTime;
  }

  return {
    title: o.title,
    description: o.description,
    alternates: { canonical: url },
    robots: o.noindex ? { index: false, follow: true } : undefined,
    openGraph: openGraph as Metadata["openGraph"],
    twitter: {
      card: "summary_large_image",
      title: o.title,
      description: o.description,
      images: [image],
    },
  };
}

// ---------------------------------------------------------------------------
// Small text helpers
// ---------------------------------------------------------------------------

export function slugify(text: string) {
  return text
    .toLowerCase()
    .trim()
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

const clean = (s?: string | null) => (s ?? "").replace(/\s+/g, " ").trim();
const lc = (s?: string | null) => clean(s).toLowerCase();

// Cuts at a word boundary so search results never end mid-word.
export function truncateAtWord(text: string, max: number) {
  const t = clean(text);
  if (t.length <= max) return t;
  const cut = t.slice(0, max - 1);
  const lastSpace = cut.lastIndexOf(" ");
  return `${(lastSpace > max * 0.6 ? cut.slice(0, lastSpace) : cut).replace(/[.,;:\s-]+$/, "")}…`;
}

// "Cabinet Handles" -> "Cabinet Handle"; "Cabinet Knob" stays as is.
export function singularize(phrase: string) {
  const p = clean(phrase);
  return /[^s]s$/i.test(p) ? p.slice(0, -1) : p;
}

export function joinList(items: string[]) {
  const a = items.map(clean).filter(Boolean);
  if (a.length <= 1) return a[0] ?? "";
  return `${a.slice(0, -1).join(", ")} and ${a[a.length - 1]}`;
}

// ---------------------------------------------------------------------------
// Product SEO — everything is generated from what the admin already typed
// (model code, category, material, finishes, sizes, weight, price). The admin
// can overwrite any generated field; these only fill in what was left blank.
// ---------------------------------------------------------------------------

export type ProductSeoInput = {
  name: string;
  modelCode?: string | null;
  categoryName?: string | null;
  material?: string | null;
  finishes?: string[];
  sizes?: string[];
  weight?: string | null;
  holeSpacing?: string | null;
  minPrice?: number | null;
  description?: string | null;
};

export type ProductKind = "door" | "knob" | "handle" | "other";

export function productKind(categoryName?: string | null, name?: string | null): ProductKind {
  const fromText = (t: string): ProductKind | null => {
    if (/\bdoor\b/.test(t)) return "door";
    if (/\bknobs?\b/.test(t)) return "knob";
    if (/\b(handles?|pulls?)\b/.test(t)) return "handle";
    return null;
  };
  return fromText(lc(categoryName)) ?? fromText(lc(name)) ?? "other";
}

export function fitTip(kind: ProductKind) {
  switch (kind) {
    case "door":
      return "Before ordering, check your door thickness and the position of the existing fixing holes so the handle fits without any extra drilling.";
    case "knob":
      return "Knobs mount with a single screw, so there is no hole spacing to match. Just make sure the screw length suits the thickness of your door or drawer.";
    case "handle":
      return "To get the right fit, measure the centre-to-centre distance between the two screw holes on your cabinet and choose a handle with the same hole spacing.";
    default:
      return "Please check the size and fit against your own measurements before ordering.";
  }
}

// A readable, keyword-rich product name from the admin's own inputs, e.g.
// "Golden Brass Cabinet Handle WH205 GP".
export function suggestProductName(i: Omit<ProductSeoInput, "name"> & { name?: string }) {
  const model = clean(i.modelCode);
  const category = i.categoryName ? singularize(i.categoryName) : "";
  if (!model && !category) return "";

  const finishes = (i.finishes ?? []).map(clean).filter(Boolean);
  const finish = finishes.length === 1 ? finishes[0] : "";
  let material = clean(i.material);
  if (finish && material && finish.toLowerCase().includes(material.toLowerCase())) material = "";

  const words = [finish, material, category, model].filter(Boolean);
  // Drop a word if the same phrase is already in the name (e.g. category already says "Brass").
  const out: string[] = [];
  for (const w of words) {
    if (!out.join(" ").toLowerCase().includes(w.toLowerCase())) out.push(w);
  }
  return out.join(" ");
}

// True for names that are just an internal code ("DHB001", "WH205 GR", "3885").
export function looksLikeCode(name?: string | null) {
  const n = clean(name);
  return n.length > 0 && n.length <= 16 && /\d/.test(n) && !/[A-Za-z]{4,}/.test(n) && /^[A-Za-z0-9 \-\/]+$/.test(n);
}

export function generateSeoTitle(i: ProductSeoInput) {
  const name = clean(i.name);
  const candidates = [
    `${name} — Buy in Lahore, Pakistan | ${BRAND}`,
    `${name} — Buy Online | ${BRAND}`,
    `${name} | ${BRAND}`,
  ];
  return candidates.find((c) => c.length <= 60) ?? truncateAtWord(candidates[2], 60);
}

export function generateSeoDescription(i: ProductSeoInput) {
  const name = clean(i.name);
  const finishes = (i.finishes ?? []).map(clean).filter(Boolean);
  const sizes = (i.sizes ?? []).map(clean).filter(Boolean);

  let out = `Buy ${name} online from ${BRAND}, Lahore.`;
  const extras: string[] = [];
  if (i.material) extras.push(`${clean(i.material)} construction.`);
  if (finishes.length) extras.push(`${finishes.length > 1 ? "Finishes" : "Finish"}: ${joinList(finishes)}.`);
  if (i.minPrice && i.minPrice > 0) extras.push(`From Rs. ${Math.round(i.minPrice).toLocaleString("en-US")}.`);
  extras.push("Delivery across Pakistan.");
  if (sizes.length) extras.push(`Sizes: ${joinList(sizes)}.`);

  for (const e of extras) {
    if ((out + " " + e).length <= 155) out += ` ${e}`;
  }
  return out;
}

export function generateProductDescription(i: ProductSeoInput) {
  const name = clean(i.name) || "This product";
  const finishes = (i.finishes ?? []).map(clean).filter(Boolean);
  const sizes = (i.sizes ?? []).map(clean).filter(Boolean);
  const kind = productKind(i.categoryName, i.name);

  let p1 = `${name} is available from ${BRAND} in Lahore`;
  if (finishes.length) p1 += `, in ${joinList(finishes)} ${finishes.length > 1 ? "finishes" : "finish"}`;
  if (sizes.length) p1 += `${finishes.length ? " and" : ","} in ${sizes.length > 1 ? "sizes" : "size"} ${joinList(sizes)}`;
  p1 += ".";

  const specBits: string[] = [];
  if (clean(i.material)) specBits.push(`made from ${lc(i.material)}`);
  if (clean(i.weight)) specBits.push(`weighs ${clean(i.weight)}`);
  if (clean(i.holeSpacing)) specBits.push(`${clean(i.holeSpacing)} hole spacing`);
  const p2 = specBits.length ? `${specBits.join(", ").replace(/^./, (c) => c.toUpperCase())}.` : "";

  const p3 = fitTip(kind);
  const p4 = `Order online with bank transfer and delivery across Pakistan, or WhatsApp us on ${PHONE} for bulk and wholesale prices.`;

  return [[p1, p2].filter(Boolean).join(" "), p3, p4].join("\n\n");
}

// If the admin's description is short (or missing) the product page shows it
// followed by the generated text, so every listing has real, useful copy.
export function expandDescription(i: ProductSeoInput) {
  const own = clean(i.description);
  if (own.length >= 160) return i.description as string;
  const generated = generateProductDescription(i);
  if (!own) return generated;
  const ownWithStop = /[.!?]$/.test(own) ? own : `${own}.`;
  return `${ownWithStop}\n\n${generated}`;
}

// Meta description: the admin's own SEO text if they wrote one, otherwise a
// fresh one generated from the product's details.
export function pickMetaDescription(seoDescription: string | null | undefined, i: ProductSeoInput) {
  return clean(seoDescription) || generateSeoDescription(i);
}

export function productImageAlt(name: string, index: number) {
  return index === 0 ? name : `${name} — photo ${index + 1}`;
}

// ---------------------------------------------------------------------------
// Blog SEO
// ---------------------------------------------------------------------------

export function generateBlogSeoTitle(title: string) {
  const t = clean(title);
  const withBrand = `${t} | ${BRAND}`;
  return withBrand.length <= 62 ? withBrand : truncateAtWord(t, 60);
}

export function generateBlogSeoDescription(excerpt: string) {
  return truncateAtWord(excerpt, 155);
}
'@

Write-SiteFile 'migration-13-seo-and-blog.sql' @'
-- ============================================================================
-- Update 13: product model codes + automatic SEO, and the Guides (blog).
-- Paste this WHOLE block into Supabase -> SQL Editor -> Run.
-- Safe to run more than once. Run it BEFORE running the PowerShell update.
-- ============================================================================

-- 1) Products: a separate model code (e.g. DHB001) so the product NAME can be
--    a proper descriptive name, plus SEO fields the site fills in automatically.
alter table products add column if not exists model_code text;
alter table products add column if not exists seo_title text;
alter table products add column if not exists seo_description text;
alter table products add column if not exists updated_at timestamptz default now();

-- Keep today's names as model codes (only for products that don't have one yet).
update products set model_code = name where model_code is null;

-- Give products that are currently named ONLY by their code a descriptive name,
-- e.g. "DHB001" becomes "Brass Main Door Handle DHB001". Web addresses (slugs)
-- are NOT changed, so existing links keep working. Any name can be edited later
-- in Admin -> Products.
update products p
set name = trim(concat_ws(' ',
      nullif(p.specs->>'Material', ''),
      case when c.name ~* 's$' and c.name !~* 'ss$' then left(c.name, length(c.name) - 1) else c.name end,
      p.model_code))
from categories c
where p.category_id = c.id
  and p.name = p.model_code
  and p.model_code is not null;

-- 2) Guides (blog)
create table if not exists blog_posts (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  tag text,
  excerpt text,
  content text not null default '',
  cover_image_url text,
  seo_title text,
  seo_description text,
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists blog_posts_published_idx on blog_posts (published, published_at desc);

alter table blog_posts enable row level security;

drop policy if exists public_read_blog_posts on blog_posts;
drop policy if exists admin_all_blog_posts on blog_posts;

create policy public_read_blog_posts on blog_posts
  for select using (published = true);

create policy admin_all_blog_posts on blog_posts
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- 3) Six starter guides (published). Edit or delete them any time in Admin -> Guides.
insert into blog_posts (slug, title, tag, excerpt, content, published, published_at) values

('how-to-measure-cabinet-handle-hole-spacing',
 'How to Measure Cabinet Handle Hole Spacing',
 'Sizing',
 'The one measurement that decides whether a two-hole handle fits your cabinet — and how to take it in two minutes with just a ruler.',
 $md$
Buying a handle that doesn't fit is the most common — and most avoidable — hardware mistake. The measurement that decides whether a two-hole handle fits is **hole spacing**, also called centre-to-centre distance. This guide shows you how to measure it in two minutes.

## What hole spacing means

Hole spacing is the distance from the **centre of one screw hole to the centre of the other**. It is not the same as the handle's overall length. A handle with 128mm hole spacing is usually longer than 128mm in total, because the handle extends past the screws at each end.

## How to measure it, step by step

1. If there is an old handle, unscrew it so you can see the two holes in the door or drawer.
2. Lay a ruler or tape across both holes. Line up the zero mark with the **centre** of the first hole.
3. Read the number at the centre of the second hole. That is your hole spacing.
4. Note it in millimetres — handles are usually specified in millimetres, so this saves converting later.
5. Measure the thickness of the door or drawer front as well. It tells you how long the screws need to be.

If your cabinets are new and have no holes yet, choose the handle first and then drill to match its hole spacing. A paper strip marked with the two hole centres makes it easy to drill every handle in exactly the same position.

## Common hole spacings

| Hole spacing | Approx. inches | Typical use |
|---|---|---|
| 64mm | 2.5 in | Small drawers, cupboard doors |
| 96mm | 3.8 in | Kitchen drawers and doors |
| 128mm | 5 in | Standard drawers, larger doors |
| 160mm | 6.3 in | Wide drawers, wardrobe doors |
| 192mm | 7.6 in | Large drawers, tall doors |
| 224mm and 256mm | 8.8 and 10 in | Very wide drawers, wardrobes |

These are standard sizes, so matching handles exist for almost any existing cabinet. The "typical use" column is a guide, not a rule — see our [cabinet handle size guide](/blog/cabinet-handle-size-guide-drawers-doors-wardrobes) for choosing the right length for your drawers and doors.

## What if my holes don't match a standard size?

Some older or custom cabinets have non-standard spacing. You have two easy options: use a single-hole knob and fill the spare hole with wood filler, or send us your measurement on WhatsApp and we will suggest the closest match. Browse our [cabinet handles](/shop?category=cabinet-handles) and [cabinet knobs](/shop?category=cabinet-knob) — every listing shows the exact size.

## Frequently asked questions

### Is hole spacing the same as handle length?

No. Hole spacing is the distance between the two screw holes. The overall length of the handle is longer, because the ends extend beyond the screws. Always match hole spacing when you are replacing an existing handle.

### Do knobs need hole spacing?

No. A knob is fixed with a single screw, so there is only one hole and nothing to match. You only need to check that the screw is long enough for the thickness of your door or drawer.

### Can I fit a handle with a different hole spacing?

Only if you are willing to drill new holes and fill the old ones. A 128mm handle will not fit holes that are 160mm apart, so measure before you order.
$md$,
 true, now() - interval '6 days'),

('brass-vs-stainless-steel-vs-zinc-alloy-handles',
 'Brass vs Stainless Steel vs Zinc Alloy Handles',
 'Materials',
 'How the most common handle materials compare for feel, durability and upkeep, and which one suits your kitchen, wardrobe or main door.',
 $md$
The material decides how a handle feels in your hand, how it ages and how long it lasts. Here is how the most common materials compare, so you can choose for the room — not just the look.

## Brass

Brass is a dense copper-and-zinc alloy. It is heavy, solid and does not rust, because it contains no iron. Over time brass can darken and develop a warm patina, unless it has been lacquered to keep it bright. It usually costs more than other materials, but it is the traditional choice for pieces meant to last, especially main door handles.

## Stainless steel

Stainless steel resists rust and stains and is very strong, which makes it a sensible choice for kitchens and bathrooms. It has a cool, modern look, and brushed finishes hide fingerprints well. It is harder to form into ornate shapes, so designs tend to be simpler.

## Zinc alloy

Zinc alloy is cast in a mould, which allows detailed shapes at a lower price. The colour you see is a plated or coated finish over the base metal, so the quality of that finish matters most. It works well for wardrobes and bedrooms where handles are touched less often, but heavy daily use can wear a thin coating.

## Aluminium

Aluminium is light and does not rust. It is softer than the other metals and can dent or scratch, so it suits light-use cupboards better than busy kitchen drawers.

## Quick comparison

| Material | Feel | How it ages | Best for |
|---|---|---|---|
| Brass | Heavy, solid | Warm patina, or stays bright if lacquered | Main doors, kitchens, long-term use |
| Stainless steel | Solid, cool | Very little change | Kitchens, bathrooms |
| Zinc alloy | Medium weight | Depends on the finish quality | Wardrobes, bedrooms, low-traffic doors |
| Aluminium | Light | Can scratch or dent | Light-use cupboards |

## Which should you choose?

- **Kitchen:** brass or stainless steel. Steam, grease and frequent cleaning are hard on thin finishes.
- **Bedroom and wardrobe:** zinc alloy or brass, depending on budget.
- **Bathroom:** stainless steel or brass, because of moisture.
- **Main door:** brass. It is exposed to sun, dust and rain and is handled every day.

Lahore's hot summers and monsoon humidity are tough on thin plated finishes, so a solid metal such as brass or stainless steel is the safer long-term choice for hardware you touch every day.

## How to judge quality when you shop

- **Weight:** solid pieces feel noticeably heavier than hollow or thin ones.
- **Finish:** it should look even, with no rough patches or bubbles.
- **Edges and threads:** casting edges should be smooth and screw threads clean.
- **Honest listings:** the material should be stated clearly in the product specifications. Browse [door handles](/shop?category=main-door-handle) or [cabinet handles](/shop?category=cabinet-handles) to compare.

## Frequently asked questions

### Is brass better than zinc alloy?

Generally brass is more durable and feels more substantial, while zinc alloy offers detailed designs at a lower price. For rarely used doors, a well-finished zinc alloy handle can be good value.

### Will brass rust?

No. Rust needs iron, and brass contains none. Brass can tarnish or darken over time, which is normal. Our [care guide](/blog/how-to-clean-and-care-for-brass-matte-black-chrome-handles) explains how to keep it looking good.

### Which material is best for humid areas?

Stainless steel and brass both cope well with moisture. Avoid thin-plated handles in bathrooms and kitchens if you want them to last.
$md$,
 true, now() - interval '5 days'),

('matte-black-golden-chrome-choosing-a-handle-finish',
 'Matte Black, Golden or Chrome? Choosing a Handle Finish',
 'Finishes',
 'A practical guide to picking a handle finish that suits your cabinet colour, your taps and lights, and how much cleaning you want to do.',
 $md$
Finish is the first thing people notice about a handle, and it is the hardest to change later. Here is how to choose one that suits your cabinets and room, and how each finish behaves in daily use.

## The main finishes

**Golden (brass tone)** is warm and classic. It stands out beautifully against white, navy and forest green, and looks rich on dark wood. Polished gold shows fingerprints more than satin or brushed versions.

**Matte black** is modern and high-contrast. It looks sharp on white, grey and light wood cabinets and hides fingerprints better than polished finishes. In kitchens, grease marks can show, so a quick regular wipe keeps it looking crisp.

**Chrome** is bright, cool and neutral. It matches taps and appliances easily. It shows fingerprints and water spots, but wipes clean in seconds.

**Antique brass** is a darker, aged tone that suits traditional and vintage interiors and hides everyday wear.

**Silver** is a soft, neutral metal tone that sits quietly in the background of almost any room.

## Which finish goes with which cabinet colour?

| Cabinet colour | Finishes that work well |
|---|---|
| White | Matte black, golden or chrome |
| Natural or light wood | Matte black or antique brass |
| Dark wood | Golden or antique brass |
| Navy or green | Golden |
| Grey | Matte black or chrome |

## Match the rest of the room

Look at the taps, light fittings and door hardware around your handles. A simple rule that works: choose one **dominant metal** and at most one **accent**. Mixing finishes is fine when it looks deliberate — for example, matte black handles with a golden light fitting — but three or four different metals in one room looks accidental.

## Practical tips before you order

- **Order everything for a room at the same time.** The exact shade of a finish can vary slightly between batches, so handles bought months apart may not match perfectly.
- **Think about the light.** Warm lighting makes golden finishes glow and can soften chrome; cool white light does the opposite.
- **Consider how often you will clean.** Brushed and satin finishes forgive fingerprints. Polished chrome needs wiping more often.
- **Ask for help.** Send us a photo of your cabinets on WhatsApp and we will suggest a finish. You can browse [cabinet handles](/shop?category=cabinet-handles) and [knobs](/shop?category=cabinet-knob) in each finish.

## Frequently asked questions

### Can I mix different finishes in one room?

Yes, if it is deliberate. Keep one dominant metal for most of the hardware and repeat any accent finish at least twice so it looks planned.

### Which finish is easiest to keep clean?

Brushed and satin finishes hide fingerprints best. Chrome shows marks but wipes clean very easily. Read our [care guide](/blog/how-to-clean-and-care-for-brass-matte-black-chrome-handles) for the right cleaning method for each finish.

### Does matte black wear off?

A matte black coating can wear at the edges with heavy use, especially if it is scrubbed with abrasive cleaners. Clean it with a soft damp cloth and mild soap and it will last much longer.
$md$,
 true, now() - interval '4 days'),

('cabinet-handle-size-guide-drawers-doors-wardrobes',
 'Cabinet Handle Size Guide for Drawers, Doors and Wardrobes',
 'Sizing',
 'How long should a handle be for a drawer, a kitchen door or a wardrobe? Simple proportion rules, a quick-reference table and where to position handles.',
 $md$
Once you know your hole spacing (see our guide on [how to measure hole spacing](/blog/how-to-measure-cabinet-handle-hole-spacing)), the next question is size: how long should the handle be? The answer depends on what it is fitted to. A handle that is too small looks lost on a wide drawer, and one that is too big overwhelms a small cupboard.

## Simple proportion rules

- **Drawers:** a handle about one third of the drawer front's width usually looks balanced. On narrow drawers it can be up to about half the width.
- **Wide drawers:** on drawers wider than about 75 cm, consider two handles placed roughly a quarter and three quarters of the way across, or one long handle.
- **Doors:** a handle or knob sits near the edge opposite the hinges. Tall doors suit a vertical handle.
- **Small cupboards:** knobs or short handles look best and are easier to place neatly.

## Quick reference

| Fitted to | Suggested hole spacing | Notes |
|---|---|---|
| Small cupboard door (up to about 40 cm wide) | Knob, or 64–96mm | Knobs keep small doors uncluttered |
| Kitchen drawer (40–60 cm wide) | 96–128mm | Centre it on the drawer front |
| Wide drawer (60–90 cm wide) | 128–192mm | Or two handles on very wide drawers |
| Tall wardrobe door | 160–256mm, fitted vertically | Easier to grip at a comfortable height |

These are starting points. Your own cabinets and taste matter more than any table.

## Where to position handles

- **Drawers:** centred left to right, and centred or slightly above the middle vertically.
- **Base cabinet doors:** near the top corner, opposite the hinge side.
- **Wall cabinet doors:** near the bottom corner, opposite the hinge side.
- **Distance from the edge:** about 5 cm from the corner is a comfortable, common position.
- **Use a template:** cut a small piece of card with the hole positions marked, so every handle lands in exactly the same place.

## Knob or handle?

Knobs are neat on small doors and drawers, but they offer less grip. Handles are easier to pull with wet or full hands and suit larger and heavier fronts. Many kitchens use knobs on doors and handles on drawers for a consistent, practical look. Browse our [cabinet knobs](/shop?category=cabinet-knob) and [cabinet handles](/shop?category=cabinet-handles).

## Check the clearance

Before you commit, hold the handle against the door and check that it will not knock against a neighbouring door, an appliance or a corner cabinet when it opens.

## Frequently asked questions

### Can I use a longer handle than the one I have now?

Only if the hole spacing matches, or you are prepared to drill new holes and fill the old ones. A longer handle with the same hole spacing will fit the existing holes.

### How many handles does a wide drawer need?

For very wide drawers, two handles spread evenly are easier to use and keep the drawer from twisting as it opens. One long handle can also work if it is centred.

### What size handle is best for a wardrobe door?

Longer handles of around 160mm to 256mm hole spacing, fitted vertically, are a popular choice because they are easy to grip and look proportionate on tall doors.
$md$,
 true, now() - interval '3 days'),

('how-to-choose-a-main-door-handle',
 'How to Choose a Main Door Handle for Your Home',
 'Door hardware',
 'Door thickness, lock type, handle size, material and fitting: a practical checklist for choosing a main door handle that fits and lasts.',
 $md$
The main door handle is the first thing visitors touch and the piece of hardware used most every day. Choosing well means checking a few measurements first. This checklist covers what to look at before you order.

## Start with the door

- **Door thickness.** Most doors fall somewhere between 35 mm and 50 mm thick, but measure yours. It affects the bolt and screw length you need.
- **The lock.** Does your door have a mortise lock (fitted inside the door), a rim lock (fitted on the surface) or a separate latch? The handle must work with it.
- **Existing fixing holes.** If you are replacing a handle, measure the distance between the fixing holes, centre to centre, and check whether the handle is fixed from one side or through the door.

## Pull handle or lever handle?

**Pull handles** are fixed bars you grip and pull. They suit main entrance doors that have their own lock. **Lever handles** turn to operate a latch and are common on interior doors. Knowing which your door uses saves an expensive mistake.

## Choosing the size

Long pull handles from around 400 mm up to well over a metre are common on tall or wide entrance doors. A good rule is to pick a length that looks proportionate to the door and is easy to grip with your whole hand. Door handles are usually fitted at around 100 cm from the floor, which is comfortable for most people.

## Material and finish

An outside door is exposed to sun, dust and rain, so material matters more than on an indoor cabinet. Solid brass is a long-lasting choice for main doors, and it ages gracefully. Read our comparison of [handle materials](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles) for more, or see the [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) to match your door and gate.

## A handle is not a lock

A handle makes the door easy to use, but security comes from the lock, hinges and door frame. Choose your lock separately and make sure the handle and lock work together.

## Fitting checklist

1. Measure door thickness and hole spacing before ordering.
2. Check the handle's projection so it clears the door frame and wall.
3. Use the fixings supplied, and confirm the screws or bolts are long enough for your door.
4. Drilling into solid wood or metal doors needs the right tools — consider a carpenter.
5. Tighten fixings firmly but not over-tight, and re-check them after a few weeks.

Browse our [main door handles](/shop?category=main-door-handle), and message us on WhatsApp with your measurements if you would like a second opinion.

## Frequently asked questions

### Can I change the handle without changing the lock?

Often yes, if the new handle's fixing holes line up with the existing ones or the handle is a simple pull fitted on the surface. Send us your measurements to check.

### What height should a main door handle be?

Around 100 cm from the floor is common, but follow the position of your existing handle or lock, and consider the people who use the door every day.

### How do I know if I need a pull handle or a lever handle?

If the door opens by pulling a fixed bar and locks with a separate lock, you need a pull handle. If the handle turns to release a latch, you need a lever handle.
$md$,
 true, now() - interval '2 days'),

('how-to-clean-and-care-for-brass-matte-black-chrome-handles',
 'How to Clean and Care for Brass, Matte Black and Chrome Handles',
 'Care',
 'Most hardware damage comes from the wrong cleaner. Here is what is safe for brass, matte black and chrome — and what to avoid.',
 $md$
Most damage to handles and knobs comes from the wrong cleaner, not from everyday use. The good news is that the safest method is also the simplest, and it works on nearly every finish.

## The basic routine

1. Mix a little mild dish soap into warm water.
2. Wipe the handle with a soft cloth or microfibre cloth wrung out well.
3. Wipe again with a cloth dampened with clean water.
4. **Dry immediately** with a soft dry cloth to prevent water spots.

In kitchens, do this every week or two, because grease builds up quietly and dulls the finish. Elsewhere, once a month is plenty.

## Brass

Most decorative brass hardware is lacquered to keep it bright. Treat lacquered brass like any coated finish: soap and water only. **Do not use metal polish on it**, because polish strips the lacquer and leaves patchy, tarnished spots. If a piece is unlacquered and has dulled, a brass polish used exactly as its label says will bring the shine back — or you can leave it to develop its natural patina, which many people prefer.

## Matte black

Matte black finishes are easily damaged by scrubbing. Use a damp microfibre cloth and mild soap. Avoid scouring powders, abrasive pads and polishes — they can burnish the coating into shiny patches or wear it away, especially at the edges.

## Chrome

Chrome cleans easily with soap and water. Dry it afterwards to avoid water spots. Avoid bleach and strong acid or chlorine-based cleaners, which can pit or dull the surface.

## Golden and other plated finishes

Treat these gently, like lacquered brass: mild soap, soft cloth, no abrasives, and no harsh chemicals. A thin plated layer can wear through if it is scrubbed.

## What to avoid on every finish

- Bleach and strong household cleaners
- Steel wool, scouring pads and gritty powders
- Spraying cleaner directly onto the handle — spray onto the cloth instead so liquid does not seep into the screw fittings
- Leaving wet cloths or soapy water sitting on the surface

## Keep handles firm

Every few months, check that handles are tight. A wobbling handle loosens further with use. Tighten gently by hand, because over-tightening can strip the thread or crack the fixing.

## Choosing hardware that is easy to keep clean

Brushed and satin finishes hide fingerprints, while polished chrome and gold show them more but wipe clean easily. Our [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) explains the differences, and you can compare [cabinet handles](/shop?category=cabinet-handles) in each finish.

## Frequently asked questions

### How often should I clean my handles?

Every week or two in kitchens, and about once a month elsewhere. Wipe up splashes and grease as soon as you notice them.

### Can I use vinegar or lemon to clean handles?

Acidic cleaners can damage some coatings and finishes, so mild soap and water is the safer choice. If you want to try something else, test it on a hidden spot first.

### Why has my handle gone dull?

Usually it is built-up grease, dust or hand oils, which soap and water will lift. If the finish itself has worn through, cleaning will not restore it, and replacing the handle is the practical fix.
$md$,
 true, now() - interval '1 day')

on conflict (slug) do nothing;
'@

Write-SiteFile 'app/about/page.tsx' @'
import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata({
  title: 'About Shahid Iqbal & Co — Hardware Retailer in Lahore',
  description:
    'Shahid Iqbal & Co is a Lahore-based hardware retailer specializing in brass door handles, cabinet handles, knobs and furniture pulls. Visit us on Ferozepur Road or order online.',
  path: '/about',
});

export default function AboutPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">About Shahid Iqbal &amp; Co</h1>
      <p className="mt-2 font-body text-brass">Dream Hardware at your Door Step</p>

      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>
          Shahid Iqbal &amp; Co is a Lahore-based hardware retailer specializing in door
          handles, cabinet handles, knobs, and furniture pulls — with a particular focus on
          brass hardware.
        </p>
        <p>
          Every listing on this site shows exact specs — size, finish, material, and hole
          spacing — before you order, so what arrives is what you measured for. No guessing,
          no surprises when your cabinets or doors are ready to be fitted.
        </p>
        <p>
          We work with both individual homeowners fitting out a new kitchen or bedroom, and
          contractors and carpenters sourcing hardware in bulk for a project.
        </p>
        <p>
          Have a question before you order, or need a bulk/wholesale quote? Reach out on
          WhatsApp or call us directly — details below.
        </p>
      </div>

      <div className="mt-10 border-t border-nickel/30 pt-6 font-body text-sm text-graphite">
        <p className="text-ink">Shahid Iqbal &amp; Co</p>
        <p className="mt-2">WhatsApp / Call: +92 311 7798157</p>
        <p>218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan</p>
        <p className="mt-2">
          <a
            href="https://www.facebook.com/siqbalhwc"
            className="text-ink underline hover:text-brass"
            target="_blank"
            rel="noopener noreferrer"
          >
            facebook.com/siqbalhwc
          </a>
          {" · "}
          <a
            href="https://www.instagram.com/siqbalco"
            className="text-ink underline hover:text-brass"
            target="_blank"
            rel="noopener noreferrer"
          >
            @siqbalco
          </a>
        </p>
      </div>
    </div>
  );
}
'@

Write-SiteFile 'app/admin/layout.tsx' @'
"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    if (pathname === "/admin/login") {
      setChecked(true);
      return;
    }
    supabase.auth.getSession().then(({ data }) => {
      if (!data.session) {
        router.replace("/admin/login");
      } else {
        setChecked(true);
      }
    });
  }, [pathname, router]);

  if (pathname === "/admin/login") return <>{children}</>;
  if (!checked) return <div className="p-10 font-body text-graphite">Checking session…</div>;

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6 px-6 py-10 sm:flex-row sm:gap-10">
      <aside className="w-full flex-shrink-0 sm:w-48">
        <p className="font-display text-xl text-ink">Admin</p>
        <nav className="mt-4 flex gap-4 font-body text-sm sm:mt-6 sm:flex-col sm:gap-2">
          <AdminLink href="/admin" label="Dashboard" />
          <AdminLink href="/admin/products" label="Products" />
          <AdminLink href="/admin/categories" label="Categories" />
          <AdminLink href="/admin/blog" label="Guides (blog)" />
          <AdminLink href="/admin/orders" label="Orders" />
          <AdminLink href="/admin/reviews" label="Reviews" />
          <AdminLink href="/admin/bank-accounts" label="Bank Accounts" />
        </nav>
        <button
          onClick={async () => {
            await supabase.auth.signOut();
            router.push("/admin/login");
          }}
          className="mt-8 font-body text-sm text-graphite hover:text-rust"
        >
          Sign out
        </button>
      </aside>
      <div className="flex-1">{children}</div>
    </div>
  );
}

function AdminLink({ href, label }: { href: string; label: string }) {
  return (
    <Link href={href} className="block text-graphite hover:text-ink">
      {label}
    </Link>
  );
}
'@

Write-SiteFile 'app/admin/products/[id]/edit/page.tsx' @'
"use client";

import { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { supabase } from "@/lib/supabase";
import PresetSelect from "@/components/admin/PresetSelect";
import SeoFields from "@/components/admin/SeoFields";
import {
  ProductSeoInput,
  generateProductDescription,
  generateSeoDescription,
  generateSeoTitle,
  slugify,
  suggestProductName,
} from "@/lib/seo";
import { FINISH_OPTIONS, SIZE_OPTIONS, MATERIAL_OPTIONS, WEIGHT_UNIT_OPTIONS } from "@/lib/constants";

type ExistingImage = { id: string; url: string; sort_order: number; markedForDelete: boolean };
type NewImageFile = { file: File; previewUrl: string };
type VariantRow = {
  id: string | null; // null = new, not yet saved
  finish: string;
  size: string;
  price: string;
  stock: string;
  sku: string;
  markedForDelete: boolean;
};
type SpecRow = { key: string; value: string };

const STORAGE_BUCKET = "product-images";

export default function EditProductPage() {
  const router = useRouter();
  const params = useParams();
  const productId = params.id as string;

  const [loading, setLoading] = useState(true);
  const [categories, setCategories] = useState<any[]>([]);
  const [modelCode, setModelCode] = useState("");
  const [slug, setSlug] = useState("");
  // null = "use the automatic suggestion"; a string = the admin's own wording.
  const [nameOverride, setNameOverride] = useState<string | null>(null);
  const [descOverride, setDescOverride] = useState<string | null>(null);
  const [seoTitleOverride, setSeoTitleOverride] = useState<string | null>(null);
  const [seoDescOverride, setSeoDescOverride] = useState<string | null>(null);
  const [categoryId, setCategoryId] = useState("");
  const [basePrice, setBasePrice] = useState("");
  const [material, setMaterial] = useState("");
  const [weight, setWeight] = useState("");
  const [weightUnit, setWeightUnit] = useState("g");
  const [specs, setSpecs] = useState<SpecRow[]>([]);
  const [existingImages, setExistingImages] = useState<ExistingImage[]>([]);
  const [newImageFiles, setNewImageFiles] = useState<NewImageFile[]>([]);
  const [variants, setVariants] = useState<VariantRow[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [addingCategory, setAddingCategory] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState("");

  // ---- Automatic SEO content, built from whatever is entered above ----
  const categoryName = categories.find((c) => c.id === categoryId)?.name ?? "";
  const liveVariants = variants.filter((v) => !v.markedForDelete);
  const finishes = Array.from(new Set(liveVariants.map((v) => v.finish.trim()).filter(Boolean)));
  const sizes = Array.from(new Set(liveVariants.map((v) => v.size.trim()).filter(Boolean)));
  const prices = liveVariants.map((v) => Number(v.price)).filter((n) => n > 0);
  const holeSpacing = specs.find((s) => /hole/i.test(s.key) && s.value.trim())?.value.trim() ?? "";
  const suggestedName = suggestProductName({ modelCode, categoryName, material, finishes });
  const name = nameOverride ?? suggestedName;
  const seoBase: ProductSeoInput = {
    name,
    modelCode,
    categoryName,
    material,
    weight: weight.trim() ? `${weight.trim()}${weightUnit}` : "",
    holeSpacing,
    finishes,
    sizes,
    minPrice: prices.length ? Math.min(...prices) : Number(basePrice) || null,
  };
  const autoDescription = name ? generateProductDescription(seoBase) : "";
  const description = descOverride ?? autoDescription;
  const autoSeoTitle = name ? generateSeoTitle(seoBase) : "";
  const autoSeoDescription = name ? generateSeoDescription(seoBase) : "";
  const seoTitle = seoTitleOverride ?? autoSeoTitle;
  const seoDescription = seoDescOverride ?? autoSeoDescription;

  useEffect(() => {
    async function load() {
      const [{ data: cats }, { data: product }] = await Promise.all([
        supabase.from("categories").select("*").order("sort_order"),
        supabase
          .from("products")
          .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id, attribute_values(value, attribute_id, attributes(name))))")
          .eq("id", productId)
          .single(),
      ]);

      setCategories(cats ?? []);
      if (!product) {
        setError("Product not found.");
        setLoading(false);
        return;
      }

      setNameOverride(product.name); // keep the existing name until the admin chooses otherwise
      setModelCode(product.model_code ?? "");
      setSlug(product.slug ?? "");
      setCategoryId(product.category_id ?? "");
      setDescOverride(product.description ? product.description : null);
      setSeoTitleOverride(product.seo_title ? product.seo_title : null);
      setSeoDescOverride(product.seo_description ? product.seo_description : null);
      setBasePrice(String(product.base_price ?? ""));

      const specsEntries = Object.entries(product.specs ?? {});
      const materialEntry = specsEntries.find(([k]) => k === "Material");
      const weightEntry = specsEntries.find(([k]) => k === "Weight");
      setMaterial(materialEntry ? String(materialEntry[1]) : "");
      if (weightEntry) {
        const match = String(weightEntry[1]).match(/^([\d.]+)(g|kg)?$/);
        setWeight(match ? match[1] : String(weightEntry[1]));
        setWeightUnit(match?.[2] ?? "g");
      }
      setSpecs(specsEntries.filter(([k]) => k !== "Material" && k !== "Weight").map(([key, value]) => ({ key, value: String(value) })));

      setExistingImages(
        (product.product_images ?? [])
          .sort((a: any, b: any) => a.sort_order - b.sort_order)
          .map((img: any) => ({ id: img.id, url: img.url, sort_order: img.sort_order, markedForDelete: false }))
      );

      setVariants(
        (product.product_variants ?? []).map((v: any) => {
          const finish = v.variant_attribute_values.find((j: any) => j.attribute_values?.attributes?.name === "Finish")?.attribute_values?.value ?? "";
          const size = v.variant_attribute_values.find((j: any) => j.attribute_values?.attributes?.name === "Size")?.attribute_values?.value ?? "";
          return {
            id: v.id,
            finish,
            size,
            price: String(v.price),
            stock: String(v.stock_qty),
            sku: v.sku ?? "",
            markedForDelete: false,
          };
        })
      );

      setLoading(false);
    }
    load();
  }, [productId]);

  function updateVariant(i: number, field: keyof VariantRow, value: string | boolean) {
    setVariants((prev) => prev.map((v, idx) => (idx === i ? { ...v, [field]: value } : v)));
  }

  async function handleAddCategory() {
    if (!newCategoryName.trim()) return;
    const { data, error } = await supabase
      .from("categories")
      .insert({ name: newCategoryName.trim(), slug: slugify(newCategoryName) })
      .select()
      .single();
    if (error) {
      setError(`Could not add category: ${error.message}`);
      return;
    }
    setCategories((prev) => [...prev, data]);
    setCategoryId(data.id);
    setNewCategoryName("");
    setAddingCategory(false);
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    setNewImageFiles((prev) => [...prev, ...files.map((file) => ({ file, previewUrl: URL.createObjectURL(file) }))]);
    e.target.value = "";
  }

  async function findOrCreateAttribute(attrName: string) {
    const { data: existing } = await supabase.from("attributes").select("id").eq("name", attrName).maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase.from("attributes").insert({ name: attrName }).select().single();
    if (error) throw error;
    return created.id;
  }

  async function findOrCreateAttributeValue(attributeId: string, value: string) {
    const { data: existing } = await supabase
      .from("attribute_values")
      .select("id")
      .eq("attribute_id", attributeId)
      .eq("value", value)
      .maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase
      .from("attribute_values")
      .insert({ attribute_id: attributeId, value })
      .select()
      .single();
    if (error) throw error;
    return created.id;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);

    try {
      const specsObject: Record<string, string> = {};
      if (material.trim()) specsObject["Material"] = material.trim();
      if (weight.trim()) specsObject["Weight"] = `${weight.trim()}${weightUnit}`;
      for (const s of specs) {
        if (s.key.trim() && s.value.trim()) specsObject[s.key.trim()] = s.value.trim();
      }

      const { error: updateError } = await supabase
        .from("products")
        .update({
          name: name.trim(),
          // slug is deliberately NOT changed: renaming a product must not break
          // its web address (links, Google rankings, WhatsApp shares).
          model_code: modelCode.trim() || null,
          description,
          seo_title: seoTitleOverride?.trim() || null, // null = keep generating automatically
          seo_description: seoDescOverride?.trim() || null,
          updated_at: new Date().toISOString(),
          category_id: categoryId || null,
          base_price: Number(basePrice) || 0,
          specs: specsObject,
        })
        .eq("id", productId);
      if (updateError) throw updateError;

      // Delete images marked for removal
      const toDelete = existingImages.filter((img) => img.markedForDelete);
      if (toDelete.length > 0) {
        const { error: delError } = await supabase.from("product_images").delete().in("id", toDelete.map((i) => i.id));
        if (delError) throw delError;
      }

      // Upload and insert any newly added photos
      if (newImageFiles.length > 0) {
        const keepCount = existingImages.filter((i) => !i.markedForDelete).length;
        const rows = [];
        for (let i = 0; i < newImageFiles.length; i++) {
          const { file } = newImageFiles[i];
          const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-");
          const path = `${productId}/${Date.now()}-${cleanName}`;
          const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, file);
          if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);
          const { data } = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path);
          rows.push({ product_id: productId, url: data.publicUrl, sort_order: keepCount + i });
        }
        const { error: imgError } = await supabase.from("product_images").insert(rows);
        if (imgError) throw imgError;
      }

      // Delete variants marked for removal
      const variantsToDelete = variants.filter((v) => v.markedForDelete && v.id);
      if (variantsToDelete.length > 0) {
        const { error: delVarError } = await supabase
          .from("product_variants")
          .delete()
          .in("id", variantsToDelete.map((v) => v.id!));
        if (delVarError) throw delVarError;
      }

      const activeVariants = variants.filter((v) => !v.markedForDelete && v.price);
      const usesFinish = activeVariants.some((v) => v.finish.trim());
      const usesSize = activeVariants.some((v) => v.size.trim());
      const finishAttrId = usesFinish ? await findOrCreateAttribute("Finish") : null;
      const sizeAttrId = usesSize ? await findOrCreateAttribute("Size") : null;

      for (const v of activeVariants) {
        let variantId = v.id;

        if (variantId) {
          const { error: updVarError } = await supabase
            .from("product_variants")
            .update({ sku: v.sku || null, price: Number(v.price), stock_qty: Number(v.stock) || 0 })
            .eq("id", variantId);
          if (updVarError) throw updVarError;
          // Clear old attribute links, then re-add — simplest way to keep this in sync
          await supabase.from("variant_attribute_values").delete().eq("variant_id", variantId);
        } else {
          const { data: created, error: createVarError } = await supabase
            .from("product_variants")
            .insert({ product_id: productId, sku: v.sku || null, price: Number(v.price), stock_qty: Number(v.stock) || 0 })
            .select()
            .single();
          if (createVarError) throw createVarError;
          variantId = created.id;
        }

        const links: { variant_id: string; attribute_value_id: string }[] = [];
        if (finishAttrId && v.finish.trim()) {
          const valueId = await findOrCreateAttributeValue(finishAttrId, v.finish.trim());
          links.push({ variant_id: variantId!, attribute_value_id: valueId });
        }
        if (sizeAttrId && v.size.trim()) {
          const valueId = await findOrCreateAttributeValue(sizeAttrId, v.size.trim());
          links.push({ variant_id: variantId!, attribute_value_id: valueId });
        }
        if (links.length > 0) {
          const { error: linkError } = await supabase.from("variant_attribute_values").insert(links);
          if (linkError) throw linkError;
        }
      }

      router.push("/admin/products");
    } catch (err: any) {
      setError(err.message || "Something went wrong saving this product.");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <p className="font-body text-graphite">Loading…</p>;

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Edit product</h1>

      <form onSubmit={handleSubmit} className="mt-8 max-w-2xl space-y-8">
        {error && (
          <div className="border-2 border-rust bg-rust/10 p-4">
            <p className="font-body text-sm font-medium text-rust">Could not save:</p>
            <p className="mt-1 font-body text-sm text-rust">{error}</p>
          </div>
        )}

        <div className="space-y-4">
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Model / product code (e.g. DHB001) — optional</span>
              <input
                value={modelCode}
                onChange={(e) => setModelCode(e.target.value)}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              Your internal code. It is shown on the product page and used in the automatic name below.
            </p>
          </div>
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Product name — what customers and Google see</span>
              <input
                value={name}
                onChange={(e) => setNameOverride(e.target.value === "" ? null : e.target.value)}
                required
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              {suggestedName && suggestedName !== name ? (
                <button type="button" onClick={() => setNameOverride(null)} className="underline hover:text-ink">
                  Use suggested name: {suggestedName}
                </button>
              ) : (
                "Renaming is safe — the product's web address stays the same."
              )}
            </p>
            {slug && (
              <p className="mt-1 font-body text-xs text-graphite">Web address: /products/{slug}</p>
            )}
          </div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Category</span>
            <select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            >
              <option value="">— None —</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
          </label>
          {addingCategory ? (
            <div className="flex gap-2">
              <input
                value={newCategoryName}
                onChange={(e) => setNewCategoryName(e.target.value)}
                placeholder="New category name"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink"
              />
              <button type="button" onClick={handleAddCategory} className="bg-ink px-3 py-2 font-body text-sm text-stone">
                Add
              </button>
              <button type="button" onClick={() => setAddingCategory(false)} className="font-body text-sm text-graphite">
                Cancel
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setAddingCategory(true)}
              className="font-body text-sm text-graphite hover:text-ink"
            >
              + Add a new category
            </button>
          )}
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Description</span>
              <textarea
                value={description}
                onChange={(e) => setDescOverride(e.target.value === "" ? null : e.target.value)}
                rows={8}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              {descOverride === null
                ? "Written automatically from the details you enter (name, material, finishes, sizes, weight). Edit it freely."
                : "Using your own wording."}
              {descOverride !== null && (
                <button type="button" onClick={() => setDescOverride(null)} className="ml-2 underline hover:text-ink">
                  Regenerate from details
                </button>
              )}
            </p>
          </div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Base price (shown on catalog cards)</span>
            <input
              value={basePrice}
              onChange={(e) => setBasePrice(e.target.value)}
              type="number"
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            />
          </label>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">Product photos</p>
          <div className="mt-2 flex flex-wrap gap-3">
            {existingImages.filter((img) => !img.markedForDelete).map((img) => (
              <div key={img.id} className="relative h-24 w-24 border border-nickel/30">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img.url} alt="" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={() =>
                    setExistingImages((prev) => prev.map((i) => (i.id === img.id ? { ...i, markedForDelete: true } : i)))
                  }
                  className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-ink text-xs text-stone"
                  aria-label="Remove image"
                >
                  ×
                </button>
              </div>
            ))}
            {newImageFiles.map((img, i) => (
              <div key={i} className="relative h-24 w-24 border border-nickel/30">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img.previewUrl} alt="" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={() => setNewImageFiles((prev) => prev.filter((_, idx) => idx !== i))}
                  className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-ink text-xs text-stone"
                  aria-label="Remove image"
                >
                  ×
                </button>
              </div>
            ))}
            <label className="flex h-24 w-24 cursor-pointer items-center justify-center border border-dashed border-nickel/50 font-body text-xs text-graphite hover:border-ink hover:text-ink">
              + Add photo
              <input type="file" accept="image/*" multiple onChange={handleFileSelect} className="hidden" />
            </label>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <p className="font-body text-sm text-graphite">Material</p>
            <PresetSelect options={MATERIAL_OPTIONS} value={material} onChange={setMaterial} placeholder="Select material…" />
          </div>
          <div>
            <p className="font-body text-sm text-graphite">Weight</p>
            <div className="flex gap-2">
              <input
                value={weight}
                onChange={(e) => setWeight(e.target.value)}
                type="number"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
              <select
                value={weightUnit}
                onChange={(e) => setWeightUnit(e.target.value)}
                className="border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              >
                {WEIGHT_UNIT_OPTIONS.map((u) => (
                  <option key={u} value={u}>{u}</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">
            Variants — check "Remove" to delete one, or add a new row for a new combination.
          </p>
          <div className="mt-3 space-y-3">
            {variants.map((v, i) => (
              <div key={i} className={`grid grid-cols-2 gap-2 border p-3 sm:grid-cols-6 ${v.markedForDelete ? "border-rust/40 opacity-50" : "border-nickel/20"}`}>
                <PresetSelect options={FINISH_OPTIONS} value={v.finish} onChange={(val) => updateVariant(i, "finish", val)} placeholder="Finish" />
                <PresetSelect options={SIZE_OPTIONS} value={v.size} onChange={(val) => updateVariant(i, "size", val)} placeholder="Size" />
                <input
                  value={v.price}
                  onChange={(e) => updateVariant(i, "price", e.target.value)}
                  placeholder="Price"
                  type="number"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.stock}
                  onChange={(e) => updateVariant(i, "stock", e.target.value)}
                  placeholder="Stock"
                  type="number"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.sku}
                  onChange={(e) => updateVariant(i, "sku", e.target.value)}
                  placeholder="SKU"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <button
                  type="button"
                  onClick={() => updateVariant(i, "markedForDelete", !v.markedForDelete)}
                  className="font-body text-xs text-graphite hover:text-rust"
                >
                  {v.markedForDelete ? "Undo" : "Remove"}
                </button>
              </div>
            ))}
          </div>
          <button
            type="button"
            onClick={() =>
              setVariants((prev) => [...prev, { id: null, finish: "", size: "", price: "", stock: "", sku: "", markedForDelete: false }])
            }
            className="mt-2 font-body text-sm text-graphite hover:text-ink"
          >
            + Add another variant
          </button>
        </div>

        <SeoFields
          urlPreview={`www.siqbalhwc.com › products › ${slug || slugify(name) || "your-product"}`}
          title={seoTitle}
          description={seoDescription}
          titleIsAuto={seoTitleOverride === null}
          descriptionIsAuto={seoDescOverride === null}
          onTitleChange={(v) => setSeoTitleOverride(v === "" ? null : v)}
          onDescriptionChange={(v) => setSeoDescOverride(v === "" ? null : v)}
          onResetTitle={() => setSeoTitleOverride(null)}
          onResetDescription={() => setSeoDescOverride(null)}
        />

        <button
          type="submit"
          disabled={saving}
          className="bg-ink px-6 py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
        >
          {saving ? "Saving…" : "Save changes"}
        </button>
      </form>
    </div>
  );
}
'@

Write-SiteFile 'app/admin/products/new/page.tsx' @'
"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import PresetSelect from "@/components/admin/PresetSelect";
import SeoFields from "@/components/admin/SeoFields";
import {
  ProductSeoInput,
  generateProductDescription,
  generateSeoDescription,
  generateSeoTitle,
  suggestProductName,
} from "@/lib/seo";
import { FINISH_OPTIONS, SIZE_OPTIONS, MATERIAL_OPTIONS, WEIGHT_UNIT_OPTIONS } from "@/lib/constants";

type VariantRow = { finish: string; size: string; price: string; stock: string; sku: string };
type SpecRow = { key: string; value: string };
type ImageFile = { file: File; previewUrl: string };

const STORAGE_BUCKET = "product-images";

function slugify(text: string) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
}

export default function NewProductPage() {
  const router = useRouter();
  const [categories, setCategories] = useState<any[]>([]);
  const [modelCode, setModelCode] = useState("");
  // null = "use the automatic suggestion"; a string = the admin typed their own.
  const [nameOverride, setNameOverride] = useState<string | null>(null);
  const [descOverride, setDescOverride] = useState<string | null>(null);
  const [seoTitleOverride, setSeoTitleOverride] = useState<string | null>(null);
  const [seoDescOverride, setSeoDescOverride] = useState<string | null>(null);
  const [categoryId, setCategoryId] = useState("");
  const [basePrice, setBasePrice] = useState("");
  const [imageFiles, setImageFiles] = useState<ImageFile[]>([]);
  const [material, setMaterial] = useState("");
  const [weight, setWeight] = useState("");
  const [weightUnit, setWeightUnit] = useState("g");
  const [specs, setSpecs] = useState<SpecRow[]>([]);
  const [addingCategory, setAddingCategory] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState("");
  const [variants, setVariants] = useState<VariantRow[]>([
    { finish: "", size: "", price: "", stock: "", sku: "" },
  ]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ---- Automatic SEO content, built from whatever the admin has entered ----
  const categoryName = categories.find((c) => c.id === categoryId)?.name ?? "";
  const finishes = Array.from(new Set(variants.map((v) => v.finish.trim()).filter(Boolean)));
  const sizes = Array.from(new Set(variants.map((v) => v.size.trim()).filter(Boolean)));
  const prices = variants.map((v) => Number(v.price)).filter((n) => n > 0);
  const holeSpacing = specs.find((s) => /hole/i.test(s.key) && s.value.trim())?.value.trim() ?? "";
  const suggestedName = suggestProductName({ modelCode, categoryName, material, finishes });
  const name = nameOverride ?? suggestedName;
  const seoBase: ProductSeoInput = {
    name,
    modelCode,
    categoryName,
    material,
    weight: weight.trim() ? `${weight.trim()}${weightUnit}` : "",
    holeSpacing,
    finishes,
    sizes,
    minPrice: prices.length ? Math.min(...prices) : Number(basePrice) || null,
  };
  const autoDescription = name ? generateProductDescription(seoBase) : "";
  const description = descOverride ?? autoDescription;
  const autoSeoTitle = name ? generateSeoTitle(seoBase) : "";
  const autoSeoDescription = name ? generateSeoDescription(seoBase) : "";
  const seoTitle = seoTitleOverride ?? autoSeoTitle;
  const seoDescription = seoDescOverride ?? autoSeoDescription;

  useEffect(() => {
    supabase.from("categories").select("*").order("sort_order").then(({ data }) => setCategories(data ?? []));
  }, []);

  async function handleAddCategory() {
    if (!newCategoryName.trim()) return;
    const { data, error } = await supabase
      .from("categories")
      .insert({ name: newCategoryName.trim(), slug: slugify(newCategoryName) })
      .select()
      .single();
    if (error) {
      setError(`Could not add category: ${error.message}`);
      return;
    }
    setCategories((prev) => [...prev, data]);
    setCategoryId(data.id);
    setNewCategoryName("");
    setAddingCategory(false);
  }

  function updateVariant(i: number, field: keyof VariantRow, value: string) {
    setVariants((prev) => prev.map((v, idx) => (idx === i ? { ...v, [field]: value } : v)));
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    const newImages = files.map((file) => ({ file, previewUrl: URL.createObjectURL(file) }));
    setImageFiles((prev) => [...prev, ...newImages]);
    e.target.value = ""; // allow selecting the same file again if removed and re-added
  }

  function removeImage(index: number) {
    setImageFiles((prev) => {
      URL.revokeObjectURL(prev[index].previewUrl);
      return prev.filter((_, i) => i !== index);
    });
  }

  async function uploadImages(productId: string) {
    const uploaded: { url: string; sort_order: number }[] = [];
    for (let i = 0; i < imageFiles.length; i++) {
      const { file } = imageFiles[i];
      const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-");
      const path = `${productId}/${Date.now()}-${cleanName}`;

      const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, file);
      if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);

      const { data } = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path);
      uploaded.push({ url: data.publicUrl, sort_order: i });
    }
    return uploaded;
  }

  async function findOrCreateAttribute(attrName: string) {
    const { data: existing } = await supabase.from("attributes").select("id").eq("name", attrName).maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase.from("attributes").insert({ name: attrName }).select().single();
    if (error) throw error;
    return created.id;
  }

  async function findOrCreateAttributeValue(attributeId: string, value: string) {
    const { data: existing } = await supabase
      .from("attribute_values")
      .select("id")
      .eq("attribute_id", attributeId)
      .eq("value", value)
      .maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase
      .from("attribute_values")
      .insert({ attribute_id: attributeId, value })
      .select()
      .single();
    if (error) throw error;
    return created.id;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);

    try {
      const specsObject: Record<string, string> = {};
      if (material.trim()) specsObject["Material"] = material.trim();
      if (weight.trim()) specsObject["Weight"] = `${weight.trim()}${weightUnit}`;
      for (const s of specs) {
        if (s.key.trim() && s.value.trim()) specsObject[s.key.trim()] = s.value.trim();
      }

      const { data: product, error: productError } = await supabase
        .from("products")
        .insert({
          name: name.trim(),
          slug: slugify(name),
          model_code: modelCode.trim() || null,
          description,
          seo_title: seoTitleOverride?.trim() || null, // null = keep generating automatically
          seo_description: seoDescOverride?.trim() || null,
          category_id: categoryId || null,
          base_price: Number(basePrice) || 0,
          specs: specsObject,
        })
        .select()
        .single();

      if (productError) throw productError;

      if (imageFiles.length > 0) {
        const uploaded = await uploadImages(product.id);
        const imageRows = uploaded.map((img) => ({
          product_id: product.id,
          url: img.url,
          sort_order: img.sort_order,
        }));
        const { error: imgError } = await supabase.from("product_images").insert(imageRows);
        if (imgError) throw imgError;
      }

      // Only create attributes for the ones actually used, so a product
      // with just one finish and no sizing doesn't get an empty "Size" attribute.
      const usesFinish = variants.some((v) => v.finish.trim());
      const usesSize = variants.some((v) => v.size.trim());
      const finishAttrId = usesFinish ? await findOrCreateAttribute("Finish") : null;
      const sizeAttrId = usesSize ? await findOrCreateAttribute("Size") : null;

      for (const v of variants) {
        if (!v.price) continue;
        const { data: variant, error: variantError } = await supabase
          .from("product_variants")
          .insert({
            product_id: product.id,
            sku: v.sku || null,
            price: Number(v.price),
            stock_qty: Number(v.stock) || 0,
          })
          .select()
          .single();
        if (variantError) throw variantError;

        const links: { variant_id: string; attribute_value_id: string }[] = [];
        if (finishAttrId && v.finish.trim()) {
          const valueId = await findOrCreateAttributeValue(finishAttrId, v.finish.trim());
          links.push({ variant_id: variant.id, attribute_value_id: valueId });
        }
        if (sizeAttrId && v.size.trim()) {
          const valueId = await findOrCreateAttributeValue(sizeAttrId, v.size.trim());
          links.push({ variant_id: variant.id, attribute_value_id: valueId });
        }
        if (links.length > 0) {
          const { error: linkError } = await supabase.from("variant_attribute_values").insert(links);
          if (linkError) throw linkError;
        }
      }

      router.push("/admin/products");
    } catch (err: any) {
      setError(err.message || "Something went wrong saving this product.");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Add product</h1>

      <form onSubmit={handleSubmit} className="mt-8 max-w-2xl space-y-8">
        <div className="space-y-4">
          <div>
            <LabeledInput
              label="Model / product code (e.g. DHB001) — optional"
              value={modelCode}
              onChange={setModelCode}
            />
            <p className="mt-1 font-body text-xs text-graphite">
              Your internal code. It is shown on the product page and used in the automatic name below.
            </p>
          </div>
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Product name — what customers and Google see</span>
              <input
                value={name}
                onChange={(e) => setNameOverride(e.target.value === "" ? null : e.target.value)}
                required
                placeholder="Pick a category and add a model code — the name is suggested for you"
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              {nameOverride === null
                ? "Suggested automatically from category, material and model code. Type to use your own wording."
                : "Using your own wording."}
              {nameOverride !== null && suggestedName && (
                <button type="button" onClick={() => setNameOverride(null)} className="ml-2 underline hover:text-ink">
                  Use suggested name: {suggestedName}
                </button>
              )}
            </p>
          </div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Category</span>
            <select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            >
              <option value="">— None —</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
            {categories.length === 0 && (
              <p className="mt-1 font-body text-xs text-graphite">
                No categories yet — add your first one below.
              </p>
            )}
          </label>
          {addingCategory ? (
            <div className="flex gap-2">
              <input
                value={newCategoryName}
                onChange={(e) => setNewCategoryName(e.target.value)}
                placeholder="New category name"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink"
              />
              <button type="button" onClick={handleAddCategory} className="bg-ink px-3 py-2 font-body text-sm text-stone">
                Add
              </button>
              <button type="button" onClick={() => setAddingCategory(false)} className="font-body text-sm text-graphite">
                Cancel
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setAddingCategory(true)}
              className="font-body text-sm text-graphite hover:text-ink"
            >
              + Add a new category
            </button>
          )}
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Description</span>
              <textarea
                value={description}
                onChange={(e) => setDescOverride(e.target.value === "" ? null : e.target.value)}
                rows={8}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              {descOverride === null
                ? "Written automatically from the details you enter (name, material, finishes, sizes, weight). Edit it freely."
                : "Using your own wording."}
              {descOverride !== null && (
                <button type="button" onClick={() => setDescOverride(null)} className="ml-2 underline hover:text-ink">
                  Regenerate from details
                </button>
              )}
            </p>
          </div>
          <LabeledInput
            label="Base price (shown on catalog cards)"
            value={basePrice}
            onChange={setBasePrice}
            type="number"
          />
        </div>

        <div>
          <p className="font-body text-sm text-graphite">Product photos</p>
          <div className="mt-2 flex flex-wrap gap-3">
            {imageFiles.map((img, i) => (
              <div key={i} className="relative h-24 w-24 border border-nickel/30">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img.previewUrl} alt="" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={() => removeImage(i)}
                  className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-ink text-xs text-stone"
                  aria-label="Remove image"
                >
                  ×
                </button>
              </div>
            ))}
            <label className="flex h-24 w-24 cursor-pointer items-center justify-center border border-dashed border-nickel/50 font-body text-xs text-graphite hover:border-ink hover:text-ink">
              + Add photo
              <input type="file" accept="image/*" multiple onChange={handleFileSelect} className="hidden" />
            </label>
          </div>
          <p className="mt-2 font-body text-xs text-graphite">
            Upload from your computer — the first photo becomes the main image shown on the catalog.
          </p>
        </div>

        <div className="space-y-4">
          <div>
            <p className="font-body text-sm text-graphite">Material</p>
            <PresetSelect options={MATERIAL_OPTIONS} value={material} onChange={setMaterial} placeholder="Select material…" />
          </div>
          <div>
            <p className="font-body text-sm text-graphite">Weight</p>
            <div className="flex gap-2">
              <input
                value={weight}
                onChange={(e) => setWeight(e.target.value)}
                type="number"
                placeholder="e.g. 85"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
              <select
                value={weightUnit}
                onChange={(e) => setWeightUnit(e.target.value)}
                className="border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              >
                {WEIGHT_UNIT_OPTIONS.map((u) => (
                  <option key={u} value={u}>{u}</option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <p className="font-body text-sm text-graphite">Other specs (optional)</p>
            {specs.map((spec, i) => (
              <div key={i} className="mt-2 flex gap-2">
                <input
                  value={spec.key}
                  onChange={(e) =>
                    setSpecs((prev) => prev.map((s, idx) => (idx === i ? { ...s, key: e.target.value } : s)))
                  }
                  placeholder="Spec name (e.g. Hole spacing)"
                  className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
                />
                <input
                  value={spec.value}
                  onChange={(e) =>
                    setSpecs((prev) => prev.map((s, idx) => (idx === i ? { ...s, value: e.target.value } : s)))
                  }
                  placeholder="Value"
                  className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
                />
              </div>
            ))}
            <button
              type="button"
              onClick={() => setSpecs((prev) => [...prev, { key: "", value: "" }])}
              className="mt-2 font-body text-sm text-graphite hover:text-ink"
            >
              + Add another spec
            </button>
          </div>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">
            Variants — each row is one buyable combination. Leave Size blank if this product doesn't vary by size.
          </p>
          <div className="mt-3 space-y-3">
            {variants.map((v, i) => (
              <div key={i} className="grid grid-cols-2 gap-2 border border-nickel/20 p-3 sm:grid-cols-5">
                <PresetSelect
                  options={FINISH_OPTIONS}
                  value={v.finish}
                  onChange={(val) => updateVariant(i, "finish", val)}
                  placeholder="Finish"
                />
                <PresetSelect
                  options={SIZE_OPTIONS}
                  value={v.size}
                  onChange={(val) => updateVariant(i, "size", val)}
                  placeholder="Size"
                />
                <input
                  value={v.price}
                  onChange={(e) => updateVariant(i, "price", e.target.value)}
                  placeholder="Price"
                  type="number"
                  required
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.stock}
                  onChange={(e) => updateVariant(i, "stock", e.target.value)}
                  placeholder="Stock qty"
                  type="number"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.sku}
                  onChange={(e) => updateVariant(i, "sku", e.target.value)}
                  placeholder="SKU (optional)"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
              </div>
            ))}
          </div>
          <button
            type="button"
            onClick={() =>
              setVariants((prev) => [...prev, { finish: "", size: "", price: "", stock: "", sku: "" }])
            }
            className="mt-2 font-body text-sm text-graphite hover:text-ink"
          >
            + Add another variant
          </button>
        </div>

        <SeoFields
          urlPreview={`www.siqbalhwc.com › products › ${slugify(name) || "your-product"}`}
          title={seoTitle}
          description={seoDescription}
          titleIsAuto={seoTitleOverride === null}
          descriptionIsAuto={seoDescOverride === null}
          onTitleChange={(v) => setSeoTitleOverride(v === "" ? null : v)}
          onDescriptionChange={(v) => setSeoDescOverride(v === "" ? null : v)}
          onResetTitle={() => setSeoTitleOverride(null)}
          onResetDescription={() => setSeoDescOverride(null)}
        />

        {error && (
          <div className="border-2 border-rust bg-rust/10 p-4">
            <p className="font-body text-sm font-medium text-rust">Could not save this product:</p>
            <p className="mt-1 font-body text-sm text-rust">{error}</p>
          </div>
        )}

        <button
          type="submit"
          disabled={saving}
          className="bg-ink px-6 py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
        >
          {saving ? "Saving…" : "Save product"}
        </button>
      </form>
    </div>
  );
}

function LabeledInput({
  label,
  value,
  onChange,
  type = "text",
  required = false,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
  required?: boolean;
}) {
  return (
    <label className="block">
      <span className="font-body text-sm text-graphite">{label}</span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        type={type}
        required={required}
        className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
      />
    </label>
  );
}
'@

Write-SiteFile 'app/layout.tsx' @'
import type { Metadata } from "next";
import Script from "next/script";
import "./globals.css";
import { CartProvider } from "@/lib/cart-context";
import { supabase } from "@/lib/supabase";
import { BRAND, SITE_URL, ogImageUrl } from "@/lib/seo";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

// Header + footer show your real categories, so new categories appear in the
// menu automatically. Re-checked at most once a minute.
export const revalidate = 60;

// Set NEXT_PUBLIC_GA_ID in Vercel (Project Settings → Environment Variables)
// to turn Google Analytics on. Until then this renders nothing, so it's
// safe to ship even before the owner has a GA4 property set up.
const GA_ID = process.env.NEXT_PUBLIC_GA_ID;
// NOTE: there is intentionally NO canonical here. A canonical set in the root
// layout is inherited by every page that doesn't set its own, which made About,
// Shipping, Privacy etc. all claim "I'm a copy of the homepage". Each page now
// sets its own canonical via pageMetadata() in lib/seo.ts.
export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Shahid Iqbal & Co — Cabinet Handles & Knobs in Lahore",
    template: "%s",
  },
  description:
    "Door handles, cabinet handles, knobs, and furniture pulls, specialized in brass. Based in Lahore — order online with bank transfer and track your delivery.",
  applicationName: BRAND,
  // Fallback social-share card for any page that doesn't set its own.
  openGraph: {
    type: "website",
    siteName: BRAND,
    locale: "en_PK",
    images: [{ url: ogImageUrl(), width: 1200, height: 630, alt: BRAND }],
  },
  twitter: { card: "summary_large_image", images: [ogImageUrl()] },
};

async function getNavCategories() {
  const { data } = await supabase.from("categories").select("name, slug").order("sort_order").limit(8);
  return (data ?? []) as { name: string; slug: string }[];
}

// LocalBusiness structured data — tells Google exactly who you are, where
// you're located, and how to reach you, matching your Facebook Page (NAP
// consistency matters for local search ranking). Update the URL fields once
// the real domain and phone are confirmed live.
const localBusinessJsonLd = {
  "@context": "https://schema.org",
  "@type": "HardwareStore",
  name: "Shahid Iqbal & Co",
  slogan: "Dream Hardware at your Door Step",
  telephone: "+92-311-7798157",
  email: "siqbalhwc@gmail.com",
  url: SITE_URL,
  logo: `${SITE_URL}/logo.png`,
  image: `${SITE_URL}/logo.png`,
  areaServed: { "@type": "Country", name: "Pakistan" },
  address: {
    "@type": "PostalAddress",
    streetAddress: "218/18 Ferozepur Road, near WAPDA Hospital",
    addressLocality: "Lahore",
    addressCountry: "PK",
  },
  sameAs: [
    "https://www.facebook.com/siqbalhwc",
    "https://www.instagram.com/siqbalco",
  ],
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const categories = await getNavCategories();
  return (
    <html lang="en">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(localBusinessJsonLd) }}
        />
        {GA_ID && (
          <>
            <Script src={`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`} strategy="afterInteractive" />
            <Script id="ga4-init" strategy="afterInteractive">
              {`
                window.dataLayer = window.dataLayer || [];
                function gtag(){dataLayer.push(arguments);}
                gtag('js', new Date());
                gtag('config', '${GA_ID}');
              `}
            </Script>
          </>
        )}
      </head>
      <body className="font-body">
        <CartProvider>
          <Header categories={categories} />
          <main>{children}</main>
          <Footer categories={categories} />
        </CartProvider>
      </body>
    </html>
  );
}
'@

Write-SiteFile 'app/page.tsx' @'
import type { Metadata } from "next";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { pageMetadata } from "@/lib/seo";
import ProductCard from "@/components/ProductCard";
import Testimonials from "@/components/Testimonials";
import Reveal from "@/components/Reveal";
import BlogCard from "@/components/BlogCard";
import { BlogPost, Product } from "@/lib/types";

export const metadata: Metadata = pageMetadata({
  title: "Door & Cabinet Handles in Lahore | Shahid Iqbal & Co",
  description:
    "Brass door handles, cabinet handles, knobs and furniture pulls in Lahore. Exact specs on every listing, bank-transfer checkout and delivery across Pakistan.",
  path: "/",
});

// Without this, Next.js bakes the homepage into a static snapshot at build
// time — so new products/photos added later through /admin would never show
// up here until the next deploy. This makes it fetch fresh data every visit.
export const dynamic = "force-dynamic";

async function getFeaturedProducts(): Promise<Product[]> {
  const { data } = await supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
    .eq("status", "active")
    .order("created_at", { ascending: false })
    .limit(8);

  if (!data) return [];

  return data.map((p: any) => ({
    ...p,
    images: (p.product_images ?? []).sort((a: any, b: any) => a.sort_order - b.sort_order),
    variants: (p.product_variants ?? []).map((v: any) => ({
      ...v,
      attribute_value_ids: (v.variant_attribute_values ?? []).map((j: any) => j.attribute_value_id),
    })),
  }));
}

async function getLatestPosts(): Promise<Pick<BlogPost, "slug" | "title" | "tag" | "excerpt" | "cover_image_url" | "content">[]> {
  const { data } = await supabase
    .from("blog_posts")
    .select("slug, title, tag, excerpt, cover_image_url, content")
    .eq("published", true)
    .order("published_at", { ascending: false })
    .limit(3);
  return data ?? [];
}

async function getCategories() {
  const { data } = await supabase.from("categories").select("*").order("sort_order");
  return data ?? [];
}

export default async function HomePage() {
  const [products, categories, posts] = await Promise.all([getFeaturedProducts(), getCategories(), getLatestPosts()]);

  return (
    <>
      {/* Hero */}
      <section className="bg-blacknickel text-stone">
        <div className="mx-auto grid max-w-6xl gap-10 px-6 py-24 md:grid-cols-2 md:items-center md:py-32">
          <div>
            <p className="font-body text-sm text-brass">Dream Hardware at your Door Step</p>
            <h1 className="mt-4 font-display text-5xl leading-[1.05] md:text-6xl">
              Handles and knobs that hold up to daily use.
            </h1>
            <p className="mt-6 max-w-prose font-body text-stone/70">
              Door handles, cabinet handles, knobs, and furniture pulls —
              specialized in brass, in the sizes your cabinets already take.
              Every listing shows the exact hole spacing before you order.
            </p>
            <div className="mt-8 flex gap-4">
              <Link
                href="/shop"
                className="bg-brass px-6 py-3 font-body text-sm text-blacknickel transition-colors hover:bg-stone"
              >
                Shop all products
              </Link>
              <Link
                href="/track-order"
                className="border border-stone/30 px-6 py-3 font-body text-sm text-stone transition-colors hover:border-stone"
              >
                Track an order
              </Link>
            </div>
          </div>

          {/* Finish swatches — a literal, materials-first hero element */}
          <div className="grid grid-cols-3 gap-4">
            {[
              { name: "Matte Black", hex: "#1C1B19" },
              { name: "Golden", hex: "#A9832E" },
              { name: "Chrome", hex: "#9B9992" },
            ].map((finish) => (
              <Link key={finish.name} href={`/shop?color=${encodeURIComponent(finish.name)}`} className="group space-y-3">
                <div
                  className="aspect-square rounded-full border-2 border-stone/40 ring-1 ring-black/20 transition-transform group-hover:scale-105"
                  style={{ backgroundColor: finish.hex }}
                />
                <p className="text-center font-body text-xs text-stone/60 group-hover:text-stone">{finish.name}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Category tiles */}
      {categories.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <Reveal>
            <h2 className="font-display text-3xl text-ink">Shop by category</h2>
          </Reveal>
          <div className="mt-8 grid gap-6 sm:grid-cols-2 md:grid-cols-3">
            {categories.map((cat, i) => (
              <Reveal key={cat.id} delay={i * 60}>
                <Link
                  href={`/shop?category=${cat.slug}`}
                  className="group flex items-center justify-between border border-nickel/30 px-6 py-8 transition-all duration-300 hover:-translate-y-0.5 hover:border-brass hover:shadow-[0_10px_25px_-15px_rgba(42,40,37,0.3)]"
                >
                  <span className="font-display text-xl text-ink">{cat.name}</span>
                  <span className="font-body text-graphite transition-transform duration-300 group-hover:translate-x-1 group-hover:text-brass">
                    →
                  </span>
                </Link>
              </Reveal>
            ))}
          </div>
        </section>
      )}

      {/* Featured products */}
      {products.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <Reveal>
            <div className="flex items-baseline justify-between">
              <h2 className="font-display text-3xl text-ink">Recently added</h2>
              <Link href="/shop" className="font-body text-sm text-graphite hover:text-brass">
                View all
              </Link>
            </div>
          </Reveal>
          <div className="mt-8 grid gap-x-6 gap-y-10 sm:grid-cols-2 md:grid-cols-4">
            {products.map((p, i) => (
              <Reveal key={p.id} delay={i * 60}>
                <ProductCard product={p} />
              </Reveal>
            ))}
          </div>
        </section>
      )}

      {/* Trust / specs section */}
      <section className="border-y border-nickel/20 bg-ink/[0.03] py-20">
        <div className="mx-auto max-w-6xl px-6">
          <div className="grid gap-6 md:grid-cols-3">
            {[
              {
                icon: (
                  <path
                    d="M4 15L15 4M8 16l-4-4M9 20l3-3M4 11l4 4m5-11l4 4m-8 4l4 4"
                    stroke="currentColor"
                    strokeWidth="1.4"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                ),
                title: "Exact specs, every listing",
                body: "Hole spacing, material, and weight are listed on every product — no guessing before your cabinets arrive.",
              },
              {
                icon: (
                  <>
                    <path d="M3 9l9-5 9 5" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
                    <path
                      d="M5 9v9m4-9v9m4-9v9m4-9v9M3 20h18"
                      stroke="currentColor"
                      strokeWidth="1.4"
                      strokeLinecap="round"
                    />
                  </>
                ),
                title: "Bank transfer accepted",
                body: "Pay by direct bank transfer with your order number as reference — details are shown at checkout.",
              },
              {
                icon: (
                  <>
                    <path
                      d="M12 21s7-6.1 7-11.5A7 7 0 105 9.5C5 14.9 12 21 12 21z"
                      stroke="currentColor"
                      strokeWidth="1.4"
                      strokeLinejoin="round"
                    />
                    <circle cx="12" cy="9.5" r="2.3" stroke="currentColor" strokeWidth="1.4" />
                  </>
                ),
                title: "Track your order",
                body: "Look up your order anytime with your order number and email to see its current status.",
              },
            ].map((item, i) => (
              <Reveal key={item.title} delay={i * 100}>
                <div className="group h-full border border-transparent px-2 py-2 transition-colors duration-300 hover:border-nickel/20">
                  <span className="flex h-11 w-11 items-center justify-center border border-brass/40 text-brass transition-colors duration-300 group-hover:bg-brass group-hover:text-stone">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                      {item.icon}
                    </svg>
                  </span>
                  <p className="mt-4 font-display text-xl text-ink">{item.title}</p>
                  <p className="mt-3 font-body text-sm text-graphite">{item.body}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <Testimonials />

      {/* Latest guides — fresh content + internal links help Google understand the site */}
      {posts.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <Reveal>
            <div className="flex items-baseline justify-between">
              <h2 className="font-display text-3xl text-ink">Buying guides</h2>
              <Link href="/blog" className="font-body text-sm text-graphite hover:text-brass">
                All guides
              </Link>
            </div>
          </Reveal>
          <div className="mt-8 grid gap-8 md:grid-cols-3">
            {posts.map((post, i) => (
              <Reveal key={post.slug} delay={i * 60}>
                <BlogCard post={post} />
              </Reveal>
            ))}
          </div>
        </section>
      )}
    </>
  );
}
'@

Write-SiteFile 'app/privacy/page.tsx' @'
import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata({
  title: 'Privacy Policy | Shahid Iqbal & Co',
  description:
    'How Shahid Iqbal & Co collects, uses and protects your personal information when you shop or contact us.',
  path: '/privacy',
});

export default function PrivacyPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Privacy Policy</h1>
      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>Last updated: {new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}</p>
        <div>
          <h2 className="font-display text-xl text-ink">Information we collect</h2>
          <p className="mt-2">
            When you place an order, we collect your name, delivery address, phone number,
            and email address so we can fulfill and let you track your order. We don't
            require an account to shop — no password or profile is created.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">How we use it</h2>
          <p className="mt-2">
            Order details are used only to process, ship, and let you track your purchase,
            and to contact you about that order if needed. We don't sell or share your
            information with third parties for marketing purposes.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Payment information</h2>
          <p className="mt-2">
            We currently accept bank transfer only — we never collect or store card details
            on this site.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Cookies &amp; analytics</h2>
          <p className="mt-2">
            We may use basic, privacy-respecting analytics (such as Google Analytics) to
            understand how visitors use the site, so we can improve it. This data is
            aggregated and not used to personally identify you.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Contact us</h2>
          <p className="mt-2">
            Questions about your data? Message us on WhatsApp at +92 311 7798157 or via our{" "}
            <a href="https://www.facebook.com/siqbalhwc" className="text-ink underline hover:text-brass" target="_blank" rel="noopener noreferrer">
              Facebook page
            </a>
            .
          </p>
        </div>
      </div>
    </div>
  );
}
'@

Write-SiteFile 'app/products/[slug]/page.tsx' @'
import { cache } from "react";
import { notFound } from "next/navigation";
import { Metadata } from "next";
import { supabase } from "@/lib/supabase";
import VariantSelector from "@/components/VariantSelector";
import ProductGallery from "@/components/ProductGallery";
import ProductReviews from "@/components/ProductReviews";
import ShareButtons from "@/components/ShareButtons";
import { Attribute, Product } from "@/lib/types";
import {
  BRAND,
  SITE_URL,
  expandDescription,
  generateSeoTitle,
  pageMetadata,
  pickMetaDescription,
  ProductSeoInput,
  looksLikeCode,
  suggestProductName,
} from "@/lib/seo";

type ProductBundle = {
  product: Product;
  attributes: Attribute[];
  category: { name: string; slug: string } | null;
};

// `cache` lets generateMetadata and the page share ONE database read per request.
const getProduct = cache(async (slug: string): Promise<ProductBundle | null> => {
  const { data: product } = await supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id)), categories(name, slug)")
    .eq("slug", slug)
    .eq("status", "active")
    .single();

  if (!product) return null;

  const variants = (product.product_variants ?? []).map((v: any) => ({
    ...v,
    attribute_value_ids: (v.variant_attribute_values ?? []).map((j: any) => j.attribute_value_id),
  }));

  // Collect every attribute_value_id used across this product's variants,
  // then fetch the attributes + values so the selector knows what to render.
  const usedValueIds: string[] = variants.flatMap((v: any) => v.attribute_value_ids);

  const { data: attributeValues } = await supabase
    .from("attribute_values")
    .select("*, attributes(id, name)")
    .in("id", usedValueIds.length > 0 ? usedValueIds : ["00000000-0000-0000-0000-000000000000"]);

  const attributeMap = new Map<string, Attribute>();
  for (const av of attributeValues ?? []) {
    const attrId = av.attributes.id;
    if (!attributeMap.has(attrId)) {
      attributeMap.set(attrId, { id: attrId, name: av.attributes.name, values: [] });
    }
    attributeMap.get(attrId)!.values.push({
      id: av.id,
      value: av.value,
      swatch_hex: av.swatch_hex,
      attribute_id: attrId,
    });
  }

  return {
    product: {
      ...product,
      images: (product.product_images ?? []).sort((a: any, b: any) => a.sort_order - b.sort_order),
      variants,
    },
    attributes: Array.from(attributeMap.values()),
    category: (product as any).categories
      ? { name: (product as any).categories.name, slug: (product as any).categories.slug }
      : null,
  };
});

// Everything the SEO text generators need, pulled from the product's real data.
function seoInputFor({ product, attributes, category }: ProductBundle): ProductSeoInput {
  const valuesOf = (attrName: string) =>
    attributes.find((a) => a.name.toLowerCase() === attrName)?.values.map((v) => v.value) ?? [];
  const specEntry = (re: RegExp) => Object.entries(product.specs ?? {}).find(([k]) => re.test(k))?.[1] ?? null;
  const prices = product.variants.map((v) => v.price).filter((p) => p > 0);

  const base = {
    modelCode: product.model_code ?? (looksLikeCode(product.name) ? product.name : null),
    categoryName: category?.name ?? null,
    material: specEntry(/^material$/i),
    weight: specEntry(/^weight$/i),
    holeSpacing: specEntry(/hole/i),
    finishes: valuesOf("finish"),
    sizes: valuesOf("size"),
    minPrice: prices.length ? Math.min(...prices) : product.base_price,
    description: product.description,
  };
  // If the product is still named only by its code (e.g. "DHB001"), the generated
  // SEO text uses a descriptive name instead ("Brass Main Door Handle DHB001").
  const name = looksLikeCode(product.name) ? suggestProductName(base) || product.name : product.name;
  return { name, ...base };
}

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const result = await getProduct(params.slug);
  if (!result) return {};

  const input = seoInputFor(result);
  // The admin's own SEO title/description win; otherwise they're generated
  // fresh from the product's name, material, finishes, sizes and price.
  const title = result.product.seo_title?.trim() || generateSeoTitle(input);
  const description = pickMetaDescription(result.product.seo_description, input);
  const image = result.product.images[0]?.url;

  return pageMetadata({
    title,
    description,
    path: `/products/${result.product.slug}`,
    image,
    imageAlt: result.product.name,
  });
}

export default async function ProductPage({ params }: { params: { slug: string } }) {
  const result = await getProduct(params.slug);
  if (!result) notFound();
  const { product, attributes, category } = result;

  const { data: reviewRows } = await supabase
    .from("reviews")
    .select("customer_name, rating, body, created_at")
    .eq("product_id", product.id)
    .eq("approved", true)
    .order("created_at", { ascending: false })
    .limit(20);
  const reviews = reviewRows ?? [];

  const seoInput = seoInputFor(result);
  const description = expandDescription(seoInput);
  const descriptionParagraphs = description.split(/\n{2,}/).filter(Boolean);

  const totalStock = product.variants.reduce((sum, v) => sum + v.stock_qty, 0);
  const priceRange = product.variants.length
    ? [Math.min(...product.variants.map((v) => v.price)), Math.max(...product.variants.map((v) => v.price))]
    : [product.base_price, product.base_price];
  const sku = product.model_code || product.variants.find((v) => v.sku)?.sku || undefined;

  const productJsonLd: Record<string, unknown> = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: product.name,
    description: descriptionParagraphs.join(" "),
    image: product.images.map((img) => img.url),
    sku,
    mpn: product.model_code || undefined,
    category: category?.name,
    material: seoInput.material || undefined,
    brand: { "@type": "Brand", name: BRAND },
    offers: {
      "@type": "AggregateOffer",
      priceCurrency: "PKR",
      lowPrice: priceRange[0],
      highPrice: priceRange[1],
      offerCount: Math.max(1, product.variants.length),
      availability: totalStock > 0 ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
      url: `${SITE_URL}/products/${product.slug}`,
      seller: { "@type": "Organization", name: BRAND },
    },
  };

  if (reviews.length > 0) {
    const average = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;
    productJsonLd.aggregateRating = {
      "@type": "AggregateRating",
      ratingValue: Number(average.toFixed(1)),
      reviewCount: reviews.length,
      bestRating: 5,
      worstRating: 1,
    };
    productJsonLd.review = reviews.slice(0, 5).map((r) => ({
      "@type": "Review",
      author: { "@type": "Person", name: r.customer_name },
      datePublished: r.created_at?.slice(0, 10),
      reviewBody: r.body,
      reviewRating: { "@type": "Rating", ratingValue: r.rating, bestRating: 5, worstRating: 1 },
    }));
  }

  const breadcrumbItems = [
    { name: "Home", url: SITE_URL },
    ...(category ? [{ name: category.name, url: `${SITE_URL}/shop?category=${category.slug}` }] : []),
    { name: product.name, url: `${SITE_URL}/products/${product.slug}` },
  ];

  const breadcrumbJsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: breadcrumbItems.map((item, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: item.name,
      item: item.url,
    })),
  };

  return (
    <div className="mx-auto max-w-6xl px-6 py-16">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(productJsonLd) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }} />

      <nav aria-label="Breadcrumb" className="mb-6 font-body text-xs text-graphite">
        <ol className="flex flex-wrap items-center gap-1">
          <li>
            <a href="/" className="hover:text-ink">Home</a>
          </li>
          {category && (
            <>
              <li aria-hidden="true">/</li>
              <li>
                <a href={`/shop?category=${category.slug}`} className="hover:text-ink">
                  {category.name}
                </a>
              </li>
            </>
          )}
          <li aria-hidden="true">/</li>
          <li className="text-ink" aria-current="page">{product.name}</li>
        </ol>
      </nav>

      <div className="grid gap-12 md:grid-cols-2">
        <ProductGallery images={product.images} productName={product.name} />

        <div>
          <h1 className="font-display text-4xl text-ink">{product.name}</h1>
          {product.model_code && (
            <p className="mt-2 font-body text-sm text-graphite">Model code: {product.model_code}</p>
          )}
          <div className="mt-4 max-w-prose space-y-3 font-body text-graphite">
            {descriptionParagraphs.map((para, i) => (
              <p key={i}>{para}</p>
            ))}
          </div>

          <div className="mt-8">
            <VariantSelector
              productId={product.id}
              productName={product.name}
              productSlug={product.slug}
              imageUrl={product.images[0]?.url ?? null}
              attributes={attributes}
              variants={product.variants}
            />
          </div>

          {Object.keys(product.specs).length > 0 && (
            <div className="mt-10 border-t border-nickel/30 pt-6">
              <p className="mb-3 font-body text-sm text-graphite">Specifications</p>
              <dl className="grid grid-cols-2 gap-y-2 font-body text-sm">
                {Object.entries(product.specs).map(([key, value]) => (
                  <div key={key} className="contents">
                    <dt className="capitalize text-graphite">{key.replace(/_/g, " ")}</dt>
                    <dd className="text-ink">{value}</dd>
                  </div>
                ))}
              </dl>
            </div>
          )}

          <div className="mt-8 border-t border-nickel/30 pt-6">
            <ShareButtons path={`/products/${product.slug}`} text={`${product.name} — ${BRAND}`} />
          </div>
        </div>
      </div>

      <ProductReviews productId={product.id} />
    </div>
  );
}
'@

Write-SiteFile 'app/returns/page.tsx' @'
import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata({
  title: 'Returns & Exchanges | Shahid Iqbal & Co',
  description:
    'Our returns and exchange policy for handles, knobs and door hardware ordered from Shahid Iqbal & Co, Lahore.',
  path: '/returns',
});

export default function ReturnsPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Returns &amp; Exchanges</h1>
      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>
          <strong className="text-ink">Editor's note (remove this box once reviewed):</strong>{" "}
          Please confirm the actual return window and condition requirements with the owner
          and edit the placeholders below before publishing.
        </p>
        <div>
          <h2 className="font-display text-xl text-ink">Return window</h2>
          <p className="mt-2">
            If a product arrives damaged, defective, or different from what you ordered,
            contact us within [7 days] of delivery and we'll arrange a replacement or refund.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Condition for returns</h2>
          <p className="mt-2">
            Items must be unused, in their original packaging, with all parts included.
            Custom or bulk/wholesale orders may not be eligible for return — ask before
            ordering if you're unsure.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">How to start a return</h2>
          <p className="mt-2">
            Message us on WhatsApp at +92 311 7798157 with your order number and photos of
            the issue, and we'll take it from there.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Refunds</h2>
          <p className="mt-2">
            Approved refunds are sent by bank transfer to the account used for the original
            payment, within [X business days] of approval.
          </p>
        </div>
      </div>
    </div>
  );
}
'@

Write-SiteFile 'app/shipping/page.tsx' @'
import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata({
  title: 'Shipping & Delivery Across Pakistan | Shahid Iqbal & Co',
  description:
    'How we pack and deliver door handles, cabinet handles and knobs from Lahore across Pakistan, and how to track your order.',
  path: '/shipping',
});

export default function ShippingPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Shipping Policy</h1>
      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>
          <strong className="text-ink">Editor's note (remove this box once reviewed):</strong>{" "}
          This is a starting draft so the page exists and isn't blank — please confirm actual
          courier, timelines, and charges with the owner and edit the placeholders below
          before publishing.
        </p>
        <div>
          <h2 className="font-display text-xl text-ink">Processing time</h2>
          <p className="mt-2">
            Orders are typically packed and handed to courier within [1–2 business days] of
            payment confirmation.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Delivery time &amp; charges</h2>
          <p className="mt-2">
            Within Lahore: [delivery estimate]. Nationwide (rest of Pakistan): [delivery
            estimate]. Shipping charges, if any, are shown at checkout before you confirm your
            order.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Order tracking</h2>
          <p className="mt-2">
            Once your order ships, you can check its status anytime on the{" "}
            <a href="/track-order" className="text-ink underline hover:text-brass">
              Track an order
            </a>{" "}
            page using your order number and email.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Questions</h2>
          <p className="mt-2">
            For anything shipping-related, message us on WhatsApp at +92 311 7798157.
          </p>
        </div>
      </div>
    </div>
  );
}
'@

Write-SiteFile 'app/shop/page.tsx' @'
import { Metadata } from "next";
import { supabase } from "@/lib/supabase";
import ProductCard from "@/components/ProductCard";
import SortSelect from "@/components/SortSelect";
import { Product } from "@/lib/types";
import { BRAND, pageMetadata } from "@/lib/seo";

const PAGE_SIZE = 12;

export async function generateMetadata({
  searchParams,
}: {
  searchParams: { category?: string; color?: string; size?: string; q?: string };
}): Promise<Metadata> {
  // Look the category up once — used for both the canonical URL and the title.
  let category: { name: string; slug: string } | null = null;
  if (searchParams.category) {
    const { data } = await supabase
      .from("categories")
      .select("name, slug")
      .eq("slug", searchParams.category)
      .maybeSingle();
    category = data;
  }
  const basePath = category ? `/shop?category=${category.slug}` : "/shop";

  // Search results and colour/size filter mixes are thin, ever-changing pages —
  // keep them out of Google, and point their canonical at the real page.
  if (searchParams.q) {
    return pageMetadata({ title: `Search: "${searchParams.q}" — ${BRAND}`, path: basePath, noindex: true });
  }
  if (searchParams.color || searchParams.size) {
    return pageMetadata({
      title: category ? `${category.name} — ${BRAND}` : `Shop — ${BRAND}`,
      path: basePath,
      noindex: true,
    });
  }

  if (category) {
    return pageMetadata({
      title: `${category.name} in Lahore — Buy Online | ${BRAND}`,
      description: `Shop ${category.name.toLowerCase()} — brass, chrome, and matte black finishes in every standard size. Exact specs on every listing, bank transfer, delivery across Pakistan.`,
      path: basePath,
    });
  }

  return pageMetadata({
    title: `Shop All Cabinet Handles & Knobs — ${BRAND}`,
    description:
      "Browse our full range of cabinet handles, cabinet knobs, and drawer pulls — brass, chrome, and matte black finishes, every size specified. Based in Lahore, delivered across Pakistan.",
    path: "/shop",
  });
}

async function getCategories() {
  const { data } = await supabase.from("categories").select("*").order("sort_order");
  return data ?? [];
}

// Every Finish/Size value currently in use, for the filter buttons
async function getFilterOptions() {
  const { data } = await supabase
    .from("attribute_values")
    .select("id, value, swatch_hex, attributes(name)")
    .order("value");

  const colors = (data ?? []).filter((v: any) => v.attributes?.name === "Finish");
  const sizes = (data ?? []).filter((v: any) => v.attributes?.name === "Size");
  return { colors, sizes };
}

// Resolves the color/size query params down to a set of product ids that
// have a variant matching BOTH selected filters together (not just either).
async function getProductIdsMatchingVariantFilters(colorValue?: string, sizeValue?: string) {
  if (!colorValue && !sizeValue) return null; // null = no filtering needed

  const wantedValueIds: string[] = [];
  if (colorValue) {
    const { data } = await supabase.from("attribute_values").select("id").eq("value", colorValue).maybeSingle();
    if (data) wantedValueIds.push(data.id);
  }
  if (sizeValue) {
    const { data } = await supabase.from("attribute_values").select("id").eq("value", sizeValue).maybeSingle();
    if (data) wantedValueIds.push(data.id);
  }
  if (wantedValueIds.length === 0) return [];

  const { data: links } = await supabase
    .from("variant_attribute_values")
    .select("variant_id, attribute_value_id")
    .in("attribute_value_id", wantedValueIds);

  // Keep only variants that matched EVERY requested filter, not just one
  const matchCounts = new Map<string, number>();
  for (const link of links ?? []) {
    matchCounts.set(link.variant_id, (matchCounts.get(link.variant_id) ?? 0) + 1);
  }
  const matchingVariantIds = Array.from(matchCounts.entries())
    .filter(([, count]) => count === wantedValueIds.length)
    .map(([variantId]) => variantId);

  if (matchingVariantIds.length === 0) return [];

  const { data: variants } = await supabase
    .from("product_variants")
    .select("product_id")
    .in("id", matchingVariantIds);

  return Array.from(new Set((variants ?? []).map((v) => v.product_id)));
}

async function getProducts(
  categorySlug?: string,
  colorValue?: string,
  sizeValue?: string,
  searchTerm?: string,
  sort?: string,
  limit?: number
): Promise<{ products: Product[]; hasMore: boolean }> {
  let categoryId: string | undefined;
  if (categorySlug) {
    const { data } = await supabase.from("categories").select("id").eq("slug", categorySlug).single();
    categoryId = data?.id;
  }

  const matchingProductIds = await getProductIdsMatchingVariantFilters(colorValue, sizeValue);
  if (matchingProductIds !== null && matchingProductIds.length === 0) return { products: [], hasMore: false };

  const effectiveLimit = limit ?? PAGE_SIZE;

  let query = supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
    .eq("status", "active");

  if (categoryId) query = query.eq("category_id", categoryId);
  if (matchingProductIds !== null) query = query.in("id", matchingProductIds);
  if (searchTerm) query = query.or(`name.ilike.%${searchTerm}%,description.ilike.%${searchTerm}%`);

  if (sort === "price_asc") query = query.order("base_price", { ascending: true });
  else if (sort === "price_desc") query = query.order("base_price", { ascending: false });
  else query = query.order("created_at", { ascending: false });

  // Fetch one extra row so we know whether a "Load more" link is needed,
  // without a separate count() query.
  query = query.range(0, effectiveLimit);

  const { data } = await query;
  if (!data) return { products: [], hasMore: false };

  const hasMore = data.length > effectiveLimit;
  const page = data.slice(0, effectiveLimit);

  const products = page.map((p: any) => ({
    ...p,
    images: (p.product_images ?? []).sort((a: any, b: any) => a.sort_order - b.sort_order),
    variants: (p.product_variants ?? []).map((v: any) => ({
      ...v,
      attribute_value_ids: (v.variant_attribute_values ?? []).map((j: any) => j.attribute_value_id),
    })),
  }));

  return { products, hasMore };
}

export default async function ShopPage({
  searchParams,
}: {
  searchParams: { category?: string; color?: string; size?: string; q?: string; sort?: string; limit?: string };
}) {
  const limit = Math.max(PAGE_SIZE, Number(searchParams.limit) || PAGE_SIZE);

  const [categories, filterOptions, { products, hasMore }] = await Promise.all([
    getCategories(),
    getFilterOptions(),
    getProducts(searchParams.category, searchParams.color, searchParams.size, searchParams.q, searchParams.sort, limit),
  ]);

  const activeCategory = categories.find((c) => c.slug === searchParams.category);

  // Builds a link that keeps the other active filters when toggling one
  function filterHref(next: { category?: string; color?: string; size?: string }) {
    const params = new URLSearchParams();
    const category = next.category !== undefined ? next.category : searchParams.category;
    const color = next.color !== undefined ? next.color : searchParams.color;
    const size = next.size !== undefined ? next.size : searchParams.size;
    if (category) params.set("category", category);
    if (color) params.set("color", color);
    if (size) params.set("size", size);
    if (searchParams.q) params.set("q", searchParams.q);
    if (searchParams.sort) params.set("sort", searchParams.sort);
    const qs = params.toString();
    return qs ? `/shop?${qs}` : "/shop";
  }

  function loadMoreHref() {
    const params = new URLSearchParams();
    if (searchParams.category) params.set("category", searchParams.category);
    if (searchParams.color) params.set("color", searchParams.color);
    if (searchParams.size) params.set("size", searchParams.size);
    if (searchParams.q) params.set("q", searchParams.q);
    if (searchParams.sort) params.set("sort", searchParams.sort);
    params.set("limit", String(limit + PAGE_SIZE));
    return `/shop?${params.toString()}`;
  }

  function filterHrefWithoutQuery() {
    const params = new URLSearchParams();
    if (searchParams.category) params.set("category", searchParams.category);
    if (searchParams.color) params.set("color", searchParams.color);
    if (searchParams.size) params.set("size", searchParams.size);
    if (searchParams.sort) params.set("sort", searchParams.sort);
    const qs = params.toString();
    return qs ? `/shop?${qs}` : "/shop";
  }

  return (
    <div className="mx-auto max-w-6xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">
        {searchParams.q
          ? `Results for "${searchParams.q}"`
          : activeCategory
          ? activeCategory.name
          : "All products"}
      </h1>

      <div className="mt-8 grid gap-8 md:grid-cols-[200px_1fr]">
        {/* Filters sidebar — stacks above the grid on mobile */}
        <aside className="space-y-6">
          <div>
            <p className="mb-2 font-body text-sm text-graphite">Category</p>
            <div className="flex flex-wrap gap-2 md:flex-col md:items-start md:gap-1">
              <a
                href={filterHref({ category: undefined })}
                className={`font-body text-sm ${!activeCategory ? "text-ink underline" : "text-graphite hover:text-ink"}`}
              >
                All
              </a>
              {categories.map((cat) => (
                <a
                  key={cat.id}
                  href={filterHref({ category: cat.slug })}
                  className={`font-body text-sm ${activeCategory?.id === cat.id ? "text-ink underline" : "text-graphite hover:text-ink"}`}
                >
                  {cat.name}
                </a>
              ))}
            </div>
          </div>

          {filterOptions.colors.length > 0 && (
            <div>
              <p className="mb-2 font-body text-sm text-graphite">Color</p>
              <div className="flex flex-wrap gap-2">
                {filterOptions.colors.map((c: any) => (
                  <a
                    key={c.id}
                    href={searchParams.color === c.value ? filterHref({ color: undefined }) : filterHref({ color: c.value })}
                    className={`flex items-center gap-1.5 border px-2 py-1 font-body text-xs ${
                      searchParams.color === c.value ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite"
                    }`}
                  >
                    {c.swatch_hex && (
                      <span className="h-2.5 w-2.5 rounded-full border border-black/10" style={{ backgroundColor: c.swatch_hex }} />
                    )}
                    {c.value}
                  </a>
                ))}
              </div>
            </div>
          )}

          {filterOptions.sizes.length > 0 && (
            <div>
              <p className="mb-2 font-body text-sm text-graphite">Size</p>
              <div className="flex flex-wrap gap-2">
                {filterOptions.sizes.map((s: any) => (
                  <a
                    key={s.id}
                    href={searchParams.size === s.value ? filterHref({ size: undefined }) : filterHref({ size: s.value })}
                    className={`border px-2 py-1 font-body text-xs ${
                      searchParams.size === s.value ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite"
                    }`}
                  >
                    {s.value}
                  </a>
                ))}
              </div>
            </div>
          )}

          {(searchParams.category || searchParams.color || searchParams.size) && (
            <a href="/shop" className="inline-block font-body text-xs text-graphite underline hover:text-ink">
              Clear all filters
            </a>
          )}
        </aside>

        {/* Results */}
        <div>
          <div className="mb-6 flex items-center justify-between gap-4">
            <p className="font-body text-sm text-graphite">
              {searchParams.q && (
                <>
                  {products.length === 0 ? "No matches" : `Showing results`} for &ldquo;{searchParams.q}&rdquo;
                  {" · "}
                  <a href={filterHrefWithoutQuery()} className="underline hover:text-ink">
                    Clear search
                  </a>
                </>
              )}
            </p>
            <SortSelect />
          </div>

          {products.length === 0 ? (
            <p className="font-body text-graphite">
              No products match these filters — try clearing one, or browse all products.
            </p>
          ) : (
            <>
              <div className="grid gap-x-6 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
                {products.map((p) => (
                  <ProductCard key={p.id} product={p} />
                ))}
              </div>
              {hasMore && (
                <div className="mt-10 text-center">
                  <a
                    href={loadMoreHref()}
                    className="inline-block border border-ink px-6 py-2 font-body text-sm text-ink hover:bg-ink hover:text-stone"
                  >
                    Load more
                  </a>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
'@

Write-SiteFile 'app/sitemap.ts' @'
import { MetadataRoute } from "next";
import { supabase } from "@/lib/supabase";
import { SITE_URL } from "@/lib/seo";

// Rebuilt at most once an hour, so new products and guides reach Google without a redeploy.
export const revalidate = 3600;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [{ data: products }, { data: categories }, { data: posts }] = await Promise.all([
    supabase.from("products").select("slug, updated_at").eq("status", "active"),
    supabase.from("categories").select("slug"),
    supabase.from("blog_posts").select("slug, updated_at, published_at").eq("published", true),
  ]);

  // Only pages that should appear in Google. Utility pages (track-order, cart,
  // checkout) are marked noindex, so they are deliberately left out.
  const staticPages: MetadataRoute.Sitemap = [
    { url: SITE_URL, changeFrequency: "daily", priority: 1 },
    { url: `${SITE_URL}/shop`, changeFrequency: "daily", priority: 0.9 },
    { url: `${SITE_URL}/blog`, changeFrequency: "weekly", priority: 0.8 },
    { url: `${SITE_URL}/about`, changeFrequency: "monthly", priority: 0.5 },
    { url: `${SITE_URL}/shipping`, changeFrequency: "monthly", priority: 0.3 },
    { url: `${SITE_URL}/returns`, changeFrequency: "monthly", priority: 0.3 },
    { url: `${SITE_URL}/privacy`, changeFrequency: "yearly", priority: 0.2 },
    { url: `${SITE_URL}/terms`, changeFrequency: "yearly", priority: 0.2 },
  ];

  const categoryPages: MetadataRoute.Sitemap = (categories ?? []).map((c) => ({
    url: `${SITE_URL}/shop?category=${c.slug}`,
    changeFrequency: "weekly",
    priority: 0.7,
  }));

  const productPages: MetadataRoute.Sitemap = (products ?? []).map((p) => ({
    url: `${SITE_URL}/products/${p.slug}`,
    lastModified: p.updated_at ? new Date(p.updated_at) : undefined,
    changeFrequency: "weekly",
    priority: 0.8,
  }));

  const blogPages: MetadataRoute.Sitemap = (posts ?? []).map((p) => ({
    url: `${SITE_URL}/blog/${p.slug}`,
    lastModified: new Date(p.updated_at || p.published_at || Date.now()),
    changeFrequency: "monthly",
    priority: 0.7,
  }));

  return [...staticPages, ...categoryPages, ...blogPages, ...productPages];
}
'@

Write-SiteFile 'app/terms/page.tsx' @'
import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata({
  title: 'Terms of Service | Shahid Iqbal & Co',
  description:
    'The terms that apply when you order from Shahid Iqbal & Co, including payment by bank transfer, delivery and returns.',
  path: '/terms',
});

export default function TermsPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Terms of Service</h1>
      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>Last updated: {new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}</p>
        <div>
          <h2 className="font-display text-xl text-ink">Orders</h2>
          <p className="mt-2">
            Placing an order on this site is an offer to purchase, which we confirm once
            payment is received. Prices are shown in Pakistani Rupees (PKR) and may change
            without notice, though a price shown at checkout will be honoured for that order.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Payment</h2>
          <p className="mt-2">
            We currently accept bank transfer only. Orders are processed once payment is
            confirmed against the order reference provided at checkout.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Product information</h2>
          <p className="mt-2">
            We aim for every listing's size, finish, material, and hole-spacing specs to be
            accurate. Colors may vary slightly from photos due to screen display differences.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Shipping &amp; returns</h2>
          <p className="mt-2">
            See our{" "}
            <a href="/shipping" className="text-ink underline hover:text-brass">Shipping Policy</a>
            {" "}and{" "}
            <a href="/returns" className="text-ink underline hover:text-brass">Returns &amp; Exchanges</a>
            {" "}pages for details.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Contact</h2>
          <p className="mt-2">
            Shahid Iqbal &amp; Co, 218/18 Ferozepur Road, near WAPDA Hospital, Lahore,
            Pakistan. WhatsApp / Call: +92 311 7798157.
          </p>
        </div>
      </div>
    </div>
  );
}
'@

Write-SiteFile 'components/Footer.tsx' @'
import Link from "next/link";

export default function Footer({ categories = [] }: { categories?: { name: string; slug: string }[] }) {
  return (
    <footer className="mt-24 bg-blacknickel text-stone">
      <div className="mx-auto max-w-6xl px-6 py-14">
        <div className="grid gap-10 sm:grid-cols-2 md:grid-cols-4">
          <div>
            <div className="flex items-center gap-3">
              <img src="/logo.png?v=2" alt="Shahid Iqbal & Co logo" className="h-10 w-10" />
              <p className="font-display text-xl">Shahid Iqbal &amp; Co</p>
            </div>
            <p className="mt-3 max-w-prose font-body text-sm text-stone/70">
              Dream Hardware at your Door Step — door handles, cabinet
              handles, knobs, and furniture pulls, specialized in brass.
            </p>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Shop</p>
            <ul className="space-y-2">
              <li><Link href="/shop" className="hover:text-brass">All products</Link></li>
              {categories.map((c) => (
                <li key={c.slug}>
                  <Link href={`/shop?category=${c.slug}`} className="hover:text-brass">{c.name}</Link>
                </li>
              ))}
              <li><Link href="/blog" className="hover:text-brass">Guides &amp; tips</Link></li>
              <li><Link href="/track-order" className="hover:text-brass">Track an order</Link></li>
              <li><Link href="/about" className="hover:text-brass">About us</Link></li>
            </ul>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Policies</p>
            <ul className="space-y-2">
              <li><Link href="/shipping" className="hover:text-brass">Shipping</Link></li>
              <li><Link href="/returns" className="hover:text-brass">Returns &amp; Exchanges</Link></li>
              <li><Link href="/privacy" className="hover:text-brass">Privacy Policy</Link></li>
              <li><Link href="/terms" className="hover:text-brass">Terms of Service</Link></li>
            </ul>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Get in touch</p>
            <ul className="space-y-2 text-stone/80">
              <li>WhatsApp / Call: +92 311 7798157</li>
              <li>218/18 Ferozepur Road, near WAPDA Hospital, Lahore</li>
              <li>
                <a href="https://www.facebook.com/siqbalhwc" className="hover:text-brass" target="_blank" rel="noopener noreferrer">
                  facebook.com/siqbalhwc
                </a>
              </li>
              <li>
                <a href="https://www.instagram.com/siqbalco" className="hover:text-brass" target="_blank" rel="noopener noreferrer">
                  Instagram: @siqbalco
                </a>
              </li>
            </ul>
          </div>
        </div>

        <p className="mt-12 border-t border-stone/10 pt-6 font-body text-xs text-stone/40">
          © {new Date().getFullYear()} Shahid Iqbal &amp; Co. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
'@

Write-SiteFile 'components/Header.tsx' @'
"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCart } from "@/lib/cart-context";

export default function Header({ categories = [] }: { categories?: { name: string; slug: string }[] }) {
  const { lines } = useCart();
  const router = useRouter();
  const itemCount = lines.reduce((sum, l) => sum + l.quantity, 0);
  const [menuOpen, setMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [query, setQuery] = useState("");

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    const q = query.trim();
    setSearchOpen(false);
    setMenuOpen(false);
    router.push(q ? `/shop?q=${encodeURIComponent(q)}` : "/shop");
  }

  return (
    <header className="border-b border-nickel/30">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Link href="/" className="flex items-center gap-3">
          <img src="/logo.png?v=2" alt="Shahid Iqbal & Co logo" className="h-11 w-11" />
          <span className="font-display text-2xl tracking-tight text-ink">
            Shahid Iqbal &amp; Co
          </span>
        </Link>

        <nav className="hidden items-center gap-8 font-body text-sm text-graphite md:flex">
          <Link href="/shop" className="hover:text-ink">Shop</Link>
          {categories.slice(0, 4).map((c) => (
            <Link key={c.slug} href={`/shop?category=${c.slug}`} className="hover:text-ink">{c.name}</Link>
          ))}
          <Link href="/blog" className="hover:text-ink">Guides</Link>
          <Link href="/track-order" className="hover:text-ink">Track order</Link>
        </nav>

        <div className="flex items-center gap-4">
          {searchOpen ? (
            <form onSubmit={handleSearch} className="flex items-center gap-2">
              <input
                type="text"
                autoFocus
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Escape") {
                    setSearchOpen(false);
                    setQuery("");
                  }
                }}
                onBlur={() => {
                  if (!query.trim()) setSearchOpen(false);
                }}
                placeholder="Search…"
                className="w-32 border-b border-nickel/50 bg-transparent px-0.5 py-1 font-body text-sm text-ink outline-none placeholder:text-graphite/60 focus:border-ink sm:w-48"
              />
              <button
                type="button"
                onClick={() => {
                  setSearchOpen(false);
                  setQuery("");
                }}
                aria-label="Close search"
                className="text-graphite hover:text-ink"
              >
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                  <path d="M1 1L13 13M13 1L1 13" stroke="currentColor" strokeWidth="1.3" />
                </svg>
              </button>
            </form>
          ) : (
            <button
              type="button"
              onClick={() => setSearchOpen(true)}
              className="text-graphite hover:text-ink"
              aria-label="Open search"
            >
              <svg width="17" height="17" viewBox="0 0 17 17" fill="none">
                <circle cx="7" cy="7" r="5.5" stroke="currentColor" strokeWidth="1.3" />
                <path d="M11.5 11.5L15.5 15.5" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
              </svg>
            </button>
          )}
          <Link
            href="/cart"
            className="font-body text-sm text-ink underline decoration-nickel decoration-1 underline-offset-4 hover:decoration-brass"
          >
            Cart{itemCount > 0 ? ` (${itemCount})` : ""}
          </Link>
          <button
            type="button"
            onClick={() => setMenuOpen((v) => !v)}
            className="flex h-9 w-9 flex-col items-center justify-center gap-1.5 md:hidden"
            aria-label="Toggle menu"
            aria-expanded={menuOpen}
          >
            <span className="block h-px w-5 bg-ink" />
            <span className="block h-px w-5 bg-ink" />
            <span className="block h-px w-5 bg-ink" />
          </button>
        </div>
      </div>

      {menuOpen && (
        <nav className="flex flex-col gap-1 border-t border-nickel/20 px-6 py-4 font-body text-sm text-graphite md:hidden">
          <Link href="/shop" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Shop</Link>
          {categories.map((c) => (
            <Link key={c.slug} href={`/shop?category=${c.slug}`} onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">{c.name}</Link>
          ))}
          <Link href="/blog" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Guides</Link>
          <Link href="/track-order" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Track order</Link>
        </nav>
      )}
    </header>
  );
}
'@

Write-SiteFile 'components/ProductGallery.tsx' @'
"use client";

import { useState } from "react";
import Image from "next/image";
import { ProductImage } from "@/lib/types";
import { productImageAlt } from "@/lib/seo";

export default function ProductGallery({
  images,
  productName,
}: {
  images: ProductImage[];
  productName: string;
}) {
  const [activeIndex, setActiveIndex] = useState(0);
  const active = images[activeIndex];

  return (
    <div>
      <div className="relative aspect-square overflow-hidden bg-nickel/10">
        {active ? (
          <Image
            src={active.url}
            alt={productImageAlt(productName, activeIndex)}
            fill
            sizes="(min-width: 768px) 50vw, 100vw"
            className="object-cover"
            priority={activeIndex === 0}
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center font-display text-2xl italic text-nickel">
            {productName}
          </div>
        )}
      </div>

      {images.length > 1 && (
        <div className="mt-3 flex gap-2 overflow-x-auto">
          {images.map((img, i) => (
            <button
              key={img.id}
              type="button"
              onClick={() => setActiveIndex(i)}
              aria-label={`Show image ${i + 1} of ${images.length}`}
              aria-current={i === activeIndex}
              className={`relative h-16 w-16 flex-shrink-0 overflow-hidden border ${
                i === activeIndex ? "border-ink" : "border-nickel/30 hover:border-nickel"
              }`}
            >
              <Image src={img.url} alt={productImageAlt(productName, i)} fill sizes="64px" className="object-cover" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
'@

Write-SiteFile 'lib/types.ts' @'
export type Category = {
  id: string;
  name: string;
  slug: string;
};

export type ProductImage = {
  id: string;
  url: string;
  sort_order: number;
};

export type AttributeValue = {
  id: string;
  value: string;
  swatch_hex: string | null;
  attribute_id: string;
};

export type Attribute = {
  id: string;
  name: string;
  values: AttributeValue[];
};

export type Variant = {
  id: string;
  sku: string | null;
  price: number;
  stock_qty: number;
  attribute_value_ids: string[];
};

export type Product = {
  id: string;
  name: string;
  slug: string;
  model_code?: string | null;
  seo_title?: string | null;
  seo_description?: string | null;
  description: string | null;
  specs: Record<string, string>;
  base_price: number;
  status: "active" | "out_of_stock" | "discontinued";
  category_id: string | null;
  images: ProductImage[];
  variants: Variant[];
};

export type CartLine = {
  productId: string;
  productName: string;
  productSlug: string;
  variantId: string;
  variantLabel: string;
  unitPrice: number;
  quantity: number;
  imageUrl: string | null;
};

export type Review = {
  id: string;
  product_id: string | null;
  customer_name: string;
  rating: number;
  body: string;
  approved: boolean;
  created_at: string;
};

export type BankSettings = {
  account_title: string;
  bank_name: string;
  account_number: string;
  ifsc_or_routing: string;
  instructions: string;
};

export type BankAccount = {
  id: string;
  bank_name: string;
  account_title: string;
  account_number: string;
  ifsc_or_routing: string;
  sort_order: number;
  active: boolean;
};

export type BlogPost = {
  id: string;
  slug: string;
  title: string;
  tag: string | null;
  excerpt: string | null;
  content: string;
  cover_image_url: string | null;
  seo_title: string | null;
  seo_description: string | null;
  published: boolean;
  published_at: string | null;
  created_at: string;
  updated_at: string;
};
'@


cd $site
Write-Host ""
Write-Host "===== Files changed (should NOT be empty): ====="
git status --short
Write-Host "================================================"
Write-Host ""

git add .
git commit -m "SEO: fix canonical inheritance, auto-generated product names/titles/descriptions, editable SEO fields, social share images, fix category nav links, add Guides blog with admin"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two." -ForegroundColor Green
