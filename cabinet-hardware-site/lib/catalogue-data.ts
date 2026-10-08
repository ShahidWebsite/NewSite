// lib/catalogue-data.ts
//
// Fetches the CURRENT active product catalogue straight from Supabase,
// grouped by category (in the order your categories.sort_order defines).
// Called fresh on every catalogue download — no caching here, and the
// API route also disables HTTP caching, so it always reflects whatever
// is live at the moment someone clicks "Download Catalogue".
//
// Built directly against your real schema (products, product_variants,
// product_images, categories, attributes, attribute_values,
// variant_attribute_values) — confirmed via information_schema.
//
// ⚠️ One remaining unknown: `products.specs` is jsonb with no fixed
// columns in information_schema, so I can't know your exact key names
// for things like "material" from the schema alone. Check the
// `specs.material` line below against a real row and adjust if needed.
//
// ⚠️ Also confirm RLS: the anon key needs SELECT access on categories,
// product_images, product_variants, attribute_values, attributes, and
// variant_attribute_values (not just products) for this to return
// anything — the onboarding doc only explicitly confirms this for
// "active catalog data" on products itself.

import { createClient } from '@supabase/supabase-js';

// Next.js 14 caches every fetch() by default, which includes the ones
// supabase-js makes internally. That is what can leave a newly added
// category (e.g. Brass Knob) missing from the catalogue. no-store makes
// each catalogue build read live data; the route still caches the PDF itself.
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  {
    global: {
      fetch: (input: RequestInfo | URL, init?: RequestInit) =>
        fetch(input, { ...init, cache: 'no-store' }),
    },
  }
);

export type CatalogueVariant = {
  sku: string | null;
  price: number;
  stock_qty: number;
  // e.g. { Finish: 'Matte Black', Size: '128mm' } — built from
  // variant_attribute_values -> attribute_values -> attributes
  attributes: Record<string, string>;
};

export type CatalogueProduct = {
  id: string;
  name: string;
  slug: string;
  model_code: string | null;
  material: string | null;
  image_url: string | null;
  variants: CatalogueVariant[];
};

export type CatalogueCategory = {
  category: string;
  products: CatalogueProduct[];
};

export async function getCatalogueData(): Promise<CatalogueCategory[]> {
  const { data: categories, error: catError } = await supabase
    .from('categories')
    .select('id, name, sort_order')
    .order('sort_order', { ascending: true });

  if (catError) {
    throw new Error(`Failed to load categories: ${catError.message}`);
  }

  // Page through products: Supabase returns at most 1000 rows per request,
  // and nested images/variants make large catalogues hit limits sooner.
  const PAGE = 200;
  const products: any[] = [];
  for (let from = 0; ; from += PAGE) {
    const { data, error: prodError } = await supabase
      .from('products')
      .select(
        `
      id,
      name,
      slug,
      model_code,
      specs,
      category_id,
      status,
      product_images ( url, sort_order ),
      product_variants (
        id,
        sku,
        price,
        stock_qty,
        variant_attribute_values (
          attribute_value:attribute_values (
            value,
            attribute:attributes ( name )
          )
        )
      )
    `
      )
      .eq('status', 'active')
      .order('name', { ascending: true })
      .order('id', { ascending: true })
      .range(from, from + PAGE - 1);

    if (prodError) {
      throw new Error(`Failed to load products: ${prodError.message}`);
    }
    products.push(...(data ?? []));
    if (!data || data.length < PAGE) break;
  }

  const byCategoryId: Record<string, CatalogueProduct[]> = {};

  for (const p of products) {
    const images = (p.product_images ?? []).slice().sort(
      (a: any, b: any) => (a.sort_order ?? 0) - (b.sort_order ?? 0)
    );
    const image_url = images[0]?.url ?? null;

    const specs = p.specs ?? {};
    // ADJUST if your specs JSON uses a different key for material
    const material = specs.material ?? specs.Material ?? null;

    const variants: CatalogueVariant[] = (p.product_variants ?? []).map((v: any) => {
      const attrs: Record<string, string> = {};
      for (const vav of v.variant_attribute_values ?? []) {
        const attrName = vav.attribute_value?.attribute?.name;
        const attrValue = vav.attribute_value?.value;
        if (attrName && attrValue) attrs[attrName] = attrValue;
      }
      return {
        sku: v.sku ?? null,
        price: v.price,
        stock_qty: v.stock_qty,
        attributes: attrs,
      };
    });

    const catId = p.category_id ?? 'uncategorised';
    if (!byCategoryId[catId]) byCategoryId[catId] = [];
    byCategoryId[catId].push({
      id: p.id,
      name: p.name,
      slug: p.slug,
      model_code: p.model_code ?? null,
      material,
      image_url,
      variants,
    });
  }

  const result: CatalogueCategory[] = [];

  for (const cat of (categories ?? []) as any[]) {
    const prods = byCategoryId[cat.id];
    if (prods && prods.length) {
      result.push({ category: cat.name, products: prods });
    }
  }

  // Products whose category_id matches no known category (or has none)
  // must not vanish from the catalogue silently.
  const known = new Set((categories ?? []).map((c: any) => c.id));
  const orphans: CatalogueProduct[] = [];
  for (const [id, prods] of Object.entries(byCategoryId)) {
    if (id === 'uncategorised' || !known.has(id)) orphans.push(...prods);
  }
  if (orphans.length) {
    result.push({ category: 'Other', products: orphans });
  }

  return result;
}
