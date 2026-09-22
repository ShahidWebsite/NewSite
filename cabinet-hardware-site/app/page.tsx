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

  // Prefer the newest active product that actually has a photo, so the hero
  // always shows something real from the catalog rather than going stale.
  const heroProduct = products.find((p) => p.images[0]?.url);
  const heroImage = heroProduct?.images[0]?.url;

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

          <div>
            {/* Product photo, when the catalog has one — this is the "hint" of
                real hardware that makes the hero feel less flat. Falls back
                to a soft brass-toned panel so the layout still looks
                intentional before photography is uploaded. */}
            <div className="relative aspect-[4/3] overflow-hidden rounded-sm bg-gradient-to-br from-brass/25 via-blacknickel to-blacknickel">
              {heroImage ? (
                <Image
                  src={heroImage}
                  alt={heroProduct?.name ?? "Featured hardware"}
                  fill
                  priority
                  sizes="(min-width: 768px) 45vw, 90vw"
                  className="object-cover"
                />
              ) : (
                <div className="flex h-full w-full items-center justify-center">
                  <svg width="72" height="72" viewBox="0 0 24 24" fill="none" className="text-brass/60">
                    <rect x="4" y="10" width="16" height="3" rx="1.5" stroke="currentColor" strokeWidth="1.3" />
                    <circle cx="6.5" cy="11.5" r="0.6" fill="currentColor" />
                    <circle cx="17.5" cy="11.5" r="0.6" fill="currentColor" />
                  </svg>
                </div>
              )}
            </div>

            {/* Finish swatches — a literal, materials-first hero element */}
            <div className="mt-6 grid grid-cols-3 gap-4">
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
        <section className="mx-auto max-w-6xl px-6 py-20">
          <Reveal>
            <h2 className="font-display text-3xl text-ink">Shop by category</h2>
          </Reveal>
          <div className="mt-8 grid gap-6 sm:grid-cols-2 md:grid-cols-4">
            {categories.map((cat, i) => (
              <Reveal key={cat.id} delay={i * 60}>
                <Link
                  href={`/shop?category=${cat.slug}`}
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
