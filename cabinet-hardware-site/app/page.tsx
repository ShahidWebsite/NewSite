import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
import { supabase } from "@/lib/supabase";
import { pageMetadata } from "@/lib/seo";
import { LAHORE_GUIDE_SLUG, NOINDEX_REGION_SLUGS, WHOLESALE_HUB_SLUG } from "@/lib/regions";
import ProductCard from "@/components/ProductCard";
import Testimonials from "@/components/Testimonials";
import Reveal from "@/components/Reveal";
import BlogCard from "@/components/BlogCard";
import { BlogPost, Product } from "@/lib/types";

export const metadata: Metadata = pageMetadata({
  title: "Cabinet Handles & Knobs in Lahore & All Pakistan | Shahid Iqbal & Co",
  description:
    "Brass door handles, cabinet handles, knobs and furniture pulls. Shop in Lahore or order online with delivery all over Pakistan. Exact specs on every listing, bank transfer or COD. Wholesale rates for shops.",
  path: "/",
});

// Cached and served instantly, then re-checked in the background at most
// once a minute — new products/photos added through /admin still appear
// quickly, but visitors aren't stuck waiting on a database round-trip
// (previously this was "force-dynamic", which hit the database on every
// single homepage visit).
export const revalidate = 60;

async function getFeaturedProducts(): Promise<Product[]> {
  const { data } = await supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
    .eq("status", "active")
    .order("created_at", { ascending: false })
    .limit(30);

  if (!data) return [];

  // Show products that can actually be bought first; sold-out items go last.
  const stockOf = (p: any) => (p.product_variants ?? []).reduce((n: number, v: any) => n + (v.stock_qty ?? 0), 0);
  const ordered = [...data].sort((a: any, b: any) => Number(stockOf(b) > 0) - Number(stockOf(a) > 0)).slice(0, 8);

  return ordered.map((p: any) => ({
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
    .limit(12);
  return (data ?? []).filter((b) => !NOINDEX_REGION_SLUGS.includes(b.slug)).slice(0, 3);
}

async function getCategories() {
  const { data } = await supabase.from("categories").select("*").order("sort_order");
  return data ?? [];
}

const HERO_FINISHES = [
  { name: "Antique Brass", gradient: "radial-gradient(circle at 30% 28%, #E3C98F 0%, #B08A45 45%, #6E5320 100%)" },
  { name: "Golden", gradient: "radial-gradient(circle at 30% 28%, #F3DC98 0%, #D4A83C 45%, #8F6B14 100%)" },
  { name: "Matte Black", gradient: "radial-gradient(circle at 30% 28%, #55504A 0%, #24211D 55%, #0E0D0B 100%)" },
  { name: "Chrome", gradient: "radial-gradient(circle at 30% 28%, #FFFFFF 0%, #BDBDBD 45%, #7C7C7C 100%)" },
];
const HERO_SIZES = ["64mm", "96mm", "128mm", "160mm", "192mm"];

const TRUST_ITEMS = [
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
        <path d="M5 9v9m4-9v9m4-9v9m4-9v9M3 20h18" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" />
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
];

export default async function HomePage() {
  const [products, categories, posts] = await Promise.all([getFeaturedProducts(), getCategories(), getLatestPosts()]);

  return (
    <>
      {/* Hero */}
      <section className="bg-stone-50">
        <div className="mx-auto max-w-[1500px] px-3 pt-6">
        <div className="grid gap-10 rounded-2xl bg-blacknickel px-8 py-12 text-stone shadow-lg md:grid-cols-[1.45fr_1fr] md:items-center md:px-12 md:py-14">
          <div>
            <p className="rise font-body text-sm text-brass">Dream Hardware at your Door Step</p>
            <h1 className="rise-lcp mt-4 font-display text-5xl leading-[1.05] md:text-6xl">
              Cabinet handles &amp; knobs in Lahore, delivered all over Pakistan.
            </h1>
            <p className="rise mt-6 max-w-prose font-body text-stone/70" style={{ "--d": "140ms" } as React.CSSProperties}>
              Visit our shop on Ferozepur Road, Lahore, or order online from anywhere
              in Pakistan with bank transfer or Cash on Delivery. Cabinet handles,
              knobs, door handles and furniture pulls, specialized in brass. Every
              listing shows the exact hole spacing before you order. Hardware shops
              and carpenters can ask for wholesale rates.
            </p>
            <div className="rise mt-8 flex gap-4" style={{ "--d": "260ms" } as React.CSSProperties}>
              <Link
                href="/shop"
                className="press bg-brass px-6 py-3 font-body text-sm text-blacknickel transition-colors hover:bg-stone"
              >
                Shop all products
              </Link>
              <Link
                href="/contact"
                className="press border border-stone/30 px-6 py-3 font-body text-sm text-stone transition-colors hover:border-stone"
              >
                Wholesale enquiry
              </Link>
            </div>
          </div>

          {/* Finish + size quick-picks: fills the right side of the hero and
              sends buyers straight into the filtered shop. */}
          <div
            className="rise rounded-2xl border border-stone/10 bg-white/[0.04] p-6 md:p-8"
            style={{ "--d": "360ms" } as React.CSSProperties}
          >
            <p className="font-body text-xs uppercase tracking-[0.14em] text-brass">Shop by finish</p>
            <div className="mt-4 grid grid-cols-2 gap-3">
              {HERO_FINISHES.map((finish) => (
                <Link
                  key={finish.name}
                  href={`/shop?color=${encodeURIComponent(finish.name)}`}
                  className="group flex items-center gap-3 rounded-xl border border-stone/15 p-2.5 transition-colors hover:border-brass"
                >
                  <span
                    className="h-11 w-11 flex-none rounded-full ring-1 ring-black/30 transition-transform group-hover:scale-105"
                    style={{ background: finish.gradient }}
                  />
                  <span className="font-body text-sm text-stone/90">{finish.name}</span>
                </Link>
              ))}
            </div>

            <p className="mt-7 font-body text-xs uppercase tracking-[0.14em] text-brass">Find by size</p>
            <div className="mt-4 flex flex-wrap gap-2">
              {HERO_SIZES.map((size) => (
                <Link
                  key={size}
                  href={`/shop?size=${encodeURIComponent(size)}`}
                  className="press rounded border border-stone/25 px-3.5 py-2.5 font-body text-sm text-stone transition-colors hover:border-brass hover:text-brass"
                >
                  {size.replace("mm", " mm")}
                </Link>
              ))}
            </div>
          </div>
        </div>
        </div>
      </section>

      {/* Trust strip: same three messages as before, now right under the hero */}
      <section className="mx-auto max-w-[1500px] px-3">
        <div className="grid border-b border-nickel/25 md:grid-cols-3 md:divide-x md:divide-nickel/25">
          {TRUST_ITEMS.map((item, i) => (
            <Reveal key={item.title} delay={i * 80}>
              <div className="flex h-full gap-4 px-2 py-7 md:px-8 md:first:pl-2">
                <span className="flex h-11 w-11 flex-none items-center justify-center rounded-full bg-brass text-stone shadow-sm">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    {item.icon}
                  </svg>
                </span>
                <div>
                  <p className="font-display text-xl text-ink">{item.title}</p>
                  <p className="mt-1 font-body text-sm text-graphite">{item.body}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* Category tiles */}
      {categories.length > 0 && (
        <section className="mx-auto max-w-[1500px] px-3 py-10">
          <Reveal>
            <h2 className="font-display text-3xl text-ink">Shop by category</h2>
          </Reveal>
          <div
            className={
              categories.length === 5
                ? "mt-5 grid gap-4 sm:grid-cols-2 md:grid-cols-4 md:grid-rows-2"
                : "mt-5 grid gap-4 sm:grid-cols-2 md:grid-cols-4"
            }
          >
            {categories.map((cat, i) => {
              const featured = categories.length === 5 && i === 0;
              return (
                <Reveal key={cat.id} delay={i * 60} className={featured ? "md:col-span-2 md:row-span-2" : ""}>
                  <Link
                    href={`/${cat.slug}`}
                    className={`group relative block overflow-hidden rounded-2xl bg-gradient-to-br from-[#F4EEE0] to-[#E6DAC0] ${
                      featured ? "aspect-[4/3] md:aspect-auto md:h-full md:min-h-[26rem]" : "aspect-[4/3]"
                    }`}
                  >
                    {cat.image_url ? (
                      <Image
                        src={cat.image_url}
                        alt={cat.name}
                        fill
                        sizes={featured ? "(min-width: 768px) 50vw, 100vw" : "(min-width: 768px) 25vw, 50vw"}
                        className="object-cover transition-transform duration-500 group-hover:scale-[1.04]"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center">
                        <svg width="44" height="44" viewBox="0 0 24 24" fill="none" className="text-brass/50">
                          <circle cx="12" cy="8.5" r="3.2" stroke="currentColor" strokeWidth="1.3" />
                          <line x1="12" y1="11.7" x2="12" y2="18" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
                          <line x1="8.5" y1="18" x2="15.5" y2="18" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
                        </svg>
                      </div>
                    )}
                    <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-blacknickel/80 via-blacknickel/10 to-transparent" />
                    <div className="absolute inset-x-0 bottom-0 flex items-center justify-between px-5 py-4 text-stone">
                      <span className={`font-display ${featured ? "text-3xl" : "text-xl"}`}>{cat.name}</span>
                      <span className="font-body transition-transform duration-300 group-hover:translate-x-1">→</span>
                    </div>
                  </Link>
                </Reveal>
              );
            })}
          </div>
        </section>
      )}

      {/* Featured products */}
      {products.length > 0 && (
        <section className="mx-auto max-w-[1500px] px-3 py-10">
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

      {/* Lahore first, Pakistan-wide: short natural text, no keyword-stuffed region grid */}
      <section className="mx-auto max-w-[1500px] px-3 py-10">
        <Reveal>
          <h2 className="font-display text-3xl text-ink">Based in Lahore, delivering all over Pakistan</h2>
          <p className="mt-3 max-w-3xl font-body text-graphite">
            In Lahore? Visit Shahid Iqbal &amp; Co at 218/18 Ferozepur Road, near WAPDA Hospital, or order
            online.{" "}
            <Link href={`/blog/${LAHORE_GUIDE_SLUG}`} className="text-ink underline hover:text-brass">
              Where to buy in Lahore
            </Link>
            . Outside Lahore? We send orders to Islamabad, Karachi, Faisalabad, Multan, Peshawar and every other
            city in Pakistan, by bank transfer or Cash on Delivery. Hardware shop or trade buyer?{" "}
            <Link href={`/blog/${WHOLESALE_HUB_SLUG}`} className="text-ink underline hover:text-brass">
              See how wholesale works
            </Link>
            .
          </p>
        </Reveal>
      </section>

      <Testimonials />

      {/* Latest guides — fresh content + internal links help Google understand the site */}
      {posts.length > 0 && (
        <section className="mx-auto max-w-[1500px] px-3 py-10">
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
