import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
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
      <section className="bg-stone-50">
        <div className="mx-auto max-w-[1500px] px-3 pt-6">
        <div className="grid gap-10 rounded-2xl bg-blacknickel px-8 py-12 text-stone shadow-lg md:grid-cols-2 md:items-center md:px-12 md:py-16">
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
        </div>
      </section>

      {/* Category tiles */}
      {categories.length > 0 && (
        <section className="mx-auto max-w-[1500px] px-3 py-10">
          <Reveal>
            <h2 className="font-display text-3xl text-ink">Shop by category</h2>
          </Reveal>
          <div className="mt-5 grid gap-6 sm:grid-cols-2 md:grid-cols-4">
            {categories.map((cat, i) => (
              <Reveal key={cat.id} delay={i * 60}>
                <Link
                  href={`/${cat.slug}`}
                  className="group block border border-nickel/30 transition-all duration-300 hover:-translate-y-0.5 hover:border-brass hover:shadow-[0_10px_25px_-15px_rgba(42,40,37,0.3)]"
                >
                  <div className="relative aspect-square overflow-hidden bg-gradient-to-br from-ink/[0.06] to-brass/10">
                    {cat.image_url ? (
                      <Image
                        src={cat.image_url}
                        alt={cat.name}
                        fill
                        sizes="(min-width: 768px) 25vw, 50vw"
                        className="object-cover transition-transform duration-300 group-hover:scale-[1.04]"
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
                  </div>
                  <div className="flex items-center justify-between px-5 py-4">
                    <span className="font-display text-lg text-ink">{cat.name}</span>
                    <span className="font-body text-graphite transition-transform duration-300 group-hover:translate-x-1 group-hover:text-brass">
                      →
                    </span>
                  </div>
                </Link>
              </Reveal>
            ))}
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

      {/* Trust / specs section */}
      <section className="border-y border-nickel/20 bg-[#F5F1EA] py-16">
        <div className="mx-auto max-w-[1500px] px-3">
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
                <div className="group h-full rounded-lg border border-nickel/30 bg-white px-6 py-6 shadow-sm transition-all duration-300 hover:-translate-y-0.5 hover:border-brass hover:shadow-md">
                  <span className="flex h-12 w-12 items-center justify-center rounded-full bg-brass text-stone shadow-sm">
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