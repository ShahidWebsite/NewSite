import Link from "next/link";
import { supabase } from "@/lib/supabase";
import ProductCard from "@/components/ProductCard";
import { Product } from "@/lib/types";

// Without this, Next.js bakes the homepage into a static snapshot at build
// time — so new products/photos added later through /admin would never show
// up here until the next deploy. This makes it fetch fresh data every visit.
export const dynamic = "force-dynamic";

async function getFeaturedProducts(): Promise<Product[]> {
  const { data } = await supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
    .eq("status", "active")
    .limit(4);

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

async function getCategories() {
  const { data } = await supabase.from("categories").select("*").order("sort_order");
  return data ?? [];
}

export default async function HomePage() {
  const [products, categories] = await Promise.all([getFeaturedProducts(), getCategories()]);

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
              { name: "Brushed Brass", hex: "#A9832E" },
              { name: "Brushed Nickel", hex: "#9B9992" },
            ].map((finish) => (
              <div key={finish.name} className="space-y-3">
                <div
                  className="aspect-square rounded-full border-2 border-stone/40 ring-1 ring-black/20"
                  style={{ backgroundColor: finish.hex }}
                />
                <p className="text-center font-body text-xs text-stone/60">{finish.name}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Category tiles */}
      {categories.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <h2 className="font-display text-3xl text-ink">Shop by category</h2>
          <div className="mt-8 grid gap-6 sm:grid-cols-2 md:grid-cols-3">
            {categories.map((cat) => (
              <Link
                key={cat.id}
                href={`/shop?category=${cat.slug}`}
                className="group flex items-center justify-between border border-nickel/30 px-6 py-8 transition-colors hover:border-ink"
              >
                <span className="font-display text-xl text-ink">{cat.name}</span>
                <span className="font-body text-graphite transition-transform group-hover:translate-x-1">
                  →
                </span>
              </Link>
            ))}
          </div>
        </section>
      )}

      {/* Featured products */}
      {products.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <div className="flex items-baseline justify-between">
            <h2 className="font-display text-3xl text-ink">Recently added</h2>
            <Link href="/shop" className="font-body text-sm text-graphite hover:text-ink">
              View all
            </Link>
          </div>
          <div className="mt-8 grid gap-x-6 gap-y-10 sm:grid-cols-2 md:grid-cols-4">
            {products.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </section>
      )}

      {/* Trust / specs section */}
      <section className="bg-ink/[0.03] py-20">
        <div className="mx-auto grid max-w-6xl gap-10 px-6 md:grid-cols-3">
          <div>
            <p className="font-display text-xl text-ink">Exact specs, every listing</p>
            <p className="mt-3 font-body text-sm text-graphite">
              Hole spacing, material, and weight are listed on every product
              — no guessing before your cabinets arrive.
            </p>
          </div>
          <div>
            <p className="font-display text-xl text-ink">Bank transfer accepted</p>
            <p className="mt-3 font-body text-sm text-graphite">
              Pay by direct bank transfer with your order number as
              reference — details are shown at checkout.
            </p>
          </div>
          <div>
            <p className="font-display text-xl text-ink">Track your order</p>
            <p className="mt-3 font-body text-sm text-graphite">
              Look up your order anytime with your order number and email
              to see its current status.
            </p>
          </div>
        </div>
      </section>
    </>
  );
}
