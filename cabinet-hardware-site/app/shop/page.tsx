import { Metadata } from "next";
import { permanentRedirect } from "next/navigation";
import { supabase } from "@/lib/supabase";
import ShopBrowser from "@/components/ShopBrowser";
import { getCategories, getFilterOptions, getProducts, PAGE_SIZE } from "@/lib/shop-data";
import { BRAND, pageMetadata } from "@/lib/seo";

export async function generateMetadata({
  searchParams,
}: {
  searchParams: { category?: string; color?: string; size?: string; q?: string };
}): Promise<Metadata> {
  // A category is now a clean path (e.g. /cabinet-handles), not a query
  // param — /shop?category=x always redirects there (see below), so this
  // page's own metadata never needs a category branch.
  if (searchParams.q) {
    return pageMetadata({ title: `Search: "${searchParams.q}" — ${BRAND}`, path: "/shop", noindex: true });
  }
  if (searchParams.color || searchParams.size) {
    return pageMetadata({ title: `Shop — ${BRAND}`, path: "/shop", noindex: true });
  }

  return pageMetadata({
    title: `Shop All Cabinet Handles & Knobs — ${BRAND}`,
    description:
      "Browse our full range of cabinet handles, cabinet knobs, and drawer pulls — brass, chrome, and matte black finishes, every size specified. Based in Lahore, delivered across Pakistan.",
    path: "/shop",
  });
}

export default async function ShopPage({
  searchParams,
}: {
  searchParams: { category?: string; color?: string; size?: string; q?: string; sort?: string; limit?: string };
}) {
  // Legacy / bookmarked /shop?category=x links: send them to the clean
  // /{category-slug} URL, carrying over any other active filters.
  if (searchParams.category) {
    const { data: category } = await supabase
      .from("categories")
      .select("slug")
      .eq("slug", searchParams.category)
      .maybeSingle();

    if (category) {
      const params = new URLSearchParams();
      if (searchParams.color) params.set("color", searchParams.color);
      if (searchParams.size) params.set("size", searchParams.size);
      if (searchParams.sort) params.set("sort", searchParams.sort);
      if (searchParams.q) params.set("q", searchParams.q);
      const qs = params.toString();
      permanentRedirect(qs ? `/${category.slug}?${qs}` : `/${category.slug}`);
    }
    // Unknown category slug — fall through and just show "All products".
  }

  const limit = Math.max(PAGE_SIZE, Number(searchParams.limit) || PAGE_SIZE);

  const [categories, filterOptions, { products, hasMore }] = await Promise.all([
    getCategories(),
    getFilterOptions(),
    getProducts(undefined, searchParams.color, searchParams.size, searchParams.q, searchParams.sort, limit),
  ]);

  return (
    <ShopBrowser
      basePath="/shop"
      heading={searchParams.q ? `Results for "${searchParams.q}"` : "All products"}
      categories={categories}
      filterOptions={filterOptions}
      products={products}
      hasMore={hasMore}
      color={searchParams.color}
      size={searchParams.size}
      q={searchParams.q}
      sort={searchParams.sort}
      limit={limit}
    />
  );
}