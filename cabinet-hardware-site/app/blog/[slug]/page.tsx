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
    <article className="mx-auto max-w-[1400px] px-6 py-16">
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
