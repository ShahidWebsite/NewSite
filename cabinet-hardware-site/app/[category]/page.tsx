import { Metadata } from "next";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";
import ShopBrowser from "@/components/ShopBrowser";
import { getCategories, getFilterOptions, getProducts, PAGE_SIZE } from "@/lib/shop-data";
import { BRAND, pageMetadata } from "@/lib/seo";

// Clean, SEO-friendly category URLs: /cabinet-handles, /cabinet-knobs, etc.
// Next.js always matches a static route (like /about or /shop) before
// falling through to this dynamic segment, so this only ever handles a
// genuine category slug or a true 404 — it can't shadow any other page.

async function getCategoryBySlug(slug: string) {
  const { data } = await supabase.from("categories").select("id, name, slug").eq("slug", slug).maybeSingle();
  return data;
}

export async function generateMetadata({
  params,
  searchParams,
}: {
  params: { category: string };
  searchParams: { color?: string; size?: string; q?: string };
}): Promise<Metadata> {
  const category = await getCategoryBySlug(params.category);
  if (!category) {
    return pageMetadata({ title: `Not found — ${BRAND}`, path: `/${params.category}`, noindex: true });
  }

  const basePath = `/${category.slug}`;

  if (searchParams.q) {
    return pageMetadata({ title: `Search: "${searchParams.q}" — ${BRAND}`, path: basePath, noindex: true });
  }
  if (searchParams.color || searchParams.size) {
    return pageMetadata({ title: `${category.name} — ${BRAND}`, path: basePath, noindex: true });
  }

  return pageMetadata({
    title: `${category.name} in Lahore — Buy Online | ${BRAND}`,
    description: `Shop ${category.name.toLowerCase()} — brass, chrome, and matte black finishes in every standard size. Exact specs on every listing, bank transfer or Cash on Delivery, delivery across Pakistan.`,
    path: basePath,
  });
}

export default async function CategoryPage({
  params,
  searchParams,
}: {
  params: { category: string };
  searchParams: { color?: string; size?: string; q?: string; sort?: string; limit?: string };
}) {
  const category = await getCategoryBySlug(params.category);
  if (!category) notFound();

  const limit = Math.max(PAGE_SIZE, Number(searchParams.limit) || PAGE_SIZE);

  const [categories, filterOptions, { products, hasMore }] = await Promise.all([
    getCategories(),
    getFilterOptions(),
    getProducts(category.slug, searchParams.color, searchParams.size, searchParams.q, searchParams.sort, limit),
  ]);

  return (
    <ShopBrowser
      basePath={`/${category.slug}`}
      heading={searchParams.q ? `Results for "${searchParams.q}"` : category.name}
      activeCategorySlug={category.slug}
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