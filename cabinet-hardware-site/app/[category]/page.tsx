import { Metadata } from "next";
import { notFound } from "next/navigation";
import { supabase } from "@/lib/supabase";
import ShopBrowser from "@/components/ShopBrowser";
import { getCategories, getFilterOptions, getProducts, PAGE_SIZE } from "@/lib/shop-data";
import { BRAND, pageMetadata } from "@/lib/seo";
import { categoryCopy } from "@/lib/category-copy";

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
    title: `${category.name} in Lahore & Pakistan — Buy Online | ${BRAND}`,
    description: `Buy ${category.name.toLowerCase()} in Lahore or anywhere in Pakistan — brass, chrome and matte black in every standard size. Exact specs on every listing. Bank transfer or COD, delivered nationwide.`,
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

  const copy = categoryCopy(category.slug, category.name);
  const showCopy = !searchParams.q && !searchParams.color && !searchParams.size;

  return (
    <>
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
    {showCopy && (
      <section className="mx-auto max-w-[1500px] px-3 pb-12">
        <div className="max-w-3xl border-t border-nickel/30 pt-8">
          <h2 className="font-display text-2xl text-ink">{copy.heading}</h2>
          {copy.paragraphs.map((t, i) => (
            <p key={i} className="mt-3 font-body text-graphite">{t}</p>
          ))}
        </div>
      </section>
    )}
    </>
  );
}
