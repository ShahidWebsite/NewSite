import { supabase } from "@/lib/supabase";
import ProductCard from "@/components/ProductCard";
import { Product } from "@/lib/types";

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

async function getProducts(categorySlug?: string, colorValue?: string, sizeValue?: string): Promise<Product[]> {
  let categoryId: string | undefined;
  if (categorySlug) {
    const { data } = await supabase.from("categories").select("id").eq("slug", categorySlug).single();
    categoryId = data?.id;
  }

  const matchingProductIds = await getProductIdsMatchingVariantFilters(colorValue, sizeValue);
  if (matchingProductIds !== null && matchingProductIds.length === 0) return []; // filters applied, nothing matched

  let query = supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
    .eq("status", "active")
    .order("created_at", { ascending: false });

  if (categoryId) query = query.eq("category_id", categoryId);
  if (matchingProductIds !== null) query = query.in("id", matchingProductIds);

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
  searchParams: { category?: string; color?: string; size?: string };
}) {
  const [categories, filterOptions, products] = await Promise.all([
    getCategories(),
    getFilterOptions(),
    getProducts(searchParams.category, searchParams.color, searchParams.size),
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
    const qs = params.toString();
    return qs ? `/shop?${qs}` : "/shop";
  }

  return (
    <div className="mx-auto max-w-6xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">
        {activeCategory ? activeCategory.name : "All products"}
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
          {products.length === 0 ? (
            <p className="font-body text-graphite">
              No products match these filters — try clearing one, or browse all products.
            </p>
          ) : (
            <div className="grid gap-x-6 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
              {products.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
