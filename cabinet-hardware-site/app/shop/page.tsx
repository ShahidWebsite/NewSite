import { supabase } from "@/lib/supabase";
import ProductCard from "@/components/ProductCard";
import { Product } from "@/lib/types";

async function getCategories() {
  const { data } = await supabase.from("categories").select("*").order("sort_order");
  return data ?? [];
}

async function getProducts(categorySlug?: string): Promise<Product[]> {
  let categoryId: string | undefined;
  if (categorySlug) {
    const { data } = await supabase.from("categories").select("id").eq("slug", categorySlug).single();
    categoryId = data?.id;
  }

  let query = supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
    .eq("status", "active")
    .order("created_at", { ascending: false });

  if (categoryId) query = query.eq("category_id", categoryId);

  const { data } = await query;
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

export default async function ShopPage({
  searchParams,
}: {
  searchParams: { category?: string };
}) {
  const [categories, products] = await Promise.all([
    getCategories(),
    getProducts(searchParams.category),
  ]);

  const activeCategory = categories.find((c) => c.slug === searchParams.category);

  return (
    <div className="mx-auto max-w-6xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">
        {activeCategory ? activeCategory.name : "All products"}
      </h1>

      <div className="mt-6 flex flex-wrap gap-3">
        <a
          href="/shop"
          className={`border px-4 py-1.5 font-body text-sm ${
            !activeCategory ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite"
          }`}
        >
          All
        </a>
        {categories.map((cat) => (
          <a
            key={cat.id}
            href={`/shop?category=${cat.slug}`}
            className={`border px-4 py-1.5 font-body text-sm ${
              activeCategory?.id === cat.id
                ? "border-ink bg-ink text-stone"
                : "border-nickel/40 text-graphite"
            }`}
          >
            {cat.name}
          </a>
        ))}
      </div>

      {products.length === 0 ? (
        <p className="mt-16 font-body text-graphite">
          No products here yet — check back soon, or browse all products.
        </p>
      ) : (
        <div className="mt-10 grid gap-x-6 gap-y-12 sm:grid-cols-2 md:grid-cols-3">
          {products.map((p) => (
            <ProductCard key={p.id} product={p} />
          ))}
        </div>
      )}
    </div>
  );
}
