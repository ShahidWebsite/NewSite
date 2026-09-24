import { supabase } from "@/lib/supabase";
import { Product } from "@/lib/types";

export const PAGE_SIZE = 12;

export async function getCategories() {
  const { data } = await supabase.from("categories").select("*").order("sort_order");
  return data ?? [];
}

// Every Finish/Size value currently in use, for the filter buttons
export async function getFilterOptions() {
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

export async function getProducts(
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