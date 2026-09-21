import { cache } from "react";
import { notFound } from "next/navigation";
import { Metadata } from "next";
import { supabase } from "@/lib/supabase";
import VariantSelector from "@/components/VariantSelector";
import ProductGallery from "@/components/ProductGallery";
import ProductReviews from "@/components/ProductReviews";
import ShareButtons from "@/components/ShareButtons";
import { Attribute, Product } from "@/lib/types";
import {
  BRAND,
  SITE_URL,
  expandDescription,
  generateSeoTitle,
  pageMetadata,
  pickMetaDescription,
  ProductSeoInput,
  looksLikeCode,
  suggestProductName,
} from "@/lib/seo";

type ProductBundle = {
  product: Product;
  attributes: Attribute[];
  category: { name: string; slug: string } | null;
};

// `cache` lets generateMetadata and the page share ONE database read per request.
const getProduct = cache(async (slug: string): Promise<ProductBundle | null> => {
  const { data: product } = await supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id)), categories(name, slug)")
    .eq("slug", slug)
    .eq("status", "active")
    .single();

  if (!product) return null;

  const variants = (product.product_variants ?? []).map((v: any) => ({
    ...v,
    attribute_value_ids: (v.variant_attribute_values ?? []).map((j: any) => j.attribute_value_id),
  }));

  // Collect every attribute_value_id used across this product's variants,
  // then fetch the attributes + values so the selector knows what to render.
  const usedValueIds: string[] = variants.flatMap((v: any) => v.attribute_value_ids);

  const { data: attributeValues } = await supabase
    .from("attribute_values")
    .select("*, attributes(id, name)")
    .in("id", usedValueIds.length > 0 ? usedValueIds : ["00000000-0000-0000-0000-000000000000"]);

  const attributeMap = new Map<string, Attribute>();
  for (const av of attributeValues ?? []) {
    const attrId = av.attributes.id;
    if (!attributeMap.has(attrId)) {
      attributeMap.set(attrId, { id: attrId, name: av.attributes.name, values: [] });
    }
    attributeMap.get(attrId)!.values.push({
      id: av.id,
      value: av.value,
      swatch_hex: av.swatch_hex,
      attribute_id: attrId,
    });
  }

  return {
    product: {
      ...product,
      images: (product.product_images ?? []).sort((a: any, b: any) => a.sort_order - b.sort_order),
      variants,
    },
    attributes: Array.from(attributeMap.values()),
    category: (product as any).categories
      ? { name: (product as any).categories.name, slug: (product as any).categories.slug }
      : null,
  };
});

// Everything the SEO text generators need, pulled from the product's real data.
function seoInputFor({ product, attributes, category }: ProductBundle): ProductSeoInput {
  const valuesOf = (attrName: string) =>
    attributes.find((a) => a.name.toLowerCase() === attrName)?.values.map((v) => v.value) ?? [];
  const specEntry = (re: RegExp) => Object.entries(product.specs ?? {}).find(([k]) => re.test(k))?.[1] ?? null;
  const prices = product.variants.map((v) => v.price).filter((p) => p > 0);

  const base = {
    modelCode: product.model_code ?? (looksLikeCode(product.name) ? product.name : null),
    categoryName: category?.name ?? null,
    material: specEntry(/^material$/i),
    weight: specEntry(/^weight$/i),
    holeSpacing: specEntry(/hole/i),
    finishes: valuesOf("finish"),
    sizes: valuesOf("size"),
    minPrice: prices.length ? Math.min(...prices) : product.base_price,
    description: product.description,
  };
  // If the product is still named only by its code (e.g. "DHB001"), the generated
  // SEO text uses a descriptive name instead ("Brass Main Door Handle DHB001").
  const name = looksLikeCode(product.name) ? suggestProductName(base) || product.name : product.name;
  return { name, ...base };
}

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const result = await getProduct(params.slug);
  if (!result) return {};

  const input = seoInputFor(result);
  // The admin's own SEO title/description win; otherwise they're generated
  // fresh from the product's name, material, finishes, sizes and price.
  const title = result.product.seo_title?.trim() || generateSeoTitle(input);
  const description = pickMetaDescription(result.product.seo_description, input);
  const image = result.product.images[0]?.url;

  return pageMetadata({
    title,
    description,
    path: `/products/${result.product.slug}`,
    image,
    imageAlt: result.product.name,
  });
}

export default async function ProductPage({ params }: { params: { slug: string } }) {
  const result = await getProduct(params.slug);
  if (!result) notFound();
  const { product, attributes, category } = result;

  const { data: reviewRows } = await supabase
    .from("reviews")
    .select("customer_name, rating, body, created_at")
    .eq("product_id", product.id)
    .eq("approved", true)
    .order("created_at", { ascending: false })
    .limit(20);
  const reviews = reviewRows ?? [];

  const seoInput = seoInputFor(result);
  const description = expandDescription(seoInput);
  const descriptionParagraphs = description.split(/\n{2,}/).filter(Boolean);

  const totalStock = product.variants.reduce((sum, v) => sum + v.stock_qty, 0);
  const priceRange = product.variants.length
    ? [Math.min(...product.variants.map((v) => v.price)), Math.max(...product.variants.map((v) => v.price))]
    : [product.base_price, product.base_price];
  const sku = product.model_code || product.variants.find((v) => v.sku)?.sku || undefined;

  const productJsonLd: Record<string, unknown> = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: product.name,
    description: descriptionParagraphs.join(" "),
    image: product.images.map((img) => img.url),
    sku,
    mpn: product.model_code || undefined,
    category: category?.name,
    material: seoInput.material || undefined,
    brand: { "@type": "Brand", name: BRAND },
    offers: {
      "@type": "AggregateOffer",
      priceCurrency: "PKR",
      lowPrice: priceRange[0],
      highPrice: priceRange[1],
      offerCount: Math.max(1, product.variants.length),
      availability: totalStock > 0 ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
      url: `${SITE_URL}/products/${product.slug}`,
      seller: { "@type": "Organization", name: BRAND },
    },
  };

  if (reviews.length > 0) {
    const average = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;
    productJsonLd.aggregateRating = {
      "@type": "AggregateRating",
      ratingValue: Number(average.toFixed(1)),
      reviewCount: reviews.length,
      bestRating: 5,
      worstRating: 1,
    };
    productJsonLd.review = reviews.slice(0, 5).map((r) => ({
      "@type": "Review",
      author: { "@type": "Person", name: r.customer_name },
      datePublished: r.created_at?.slice(0, 10),
      reviewBody: r.body,
      reviewRating: { "@type": "Rating", ratingValue: r.rating, bestRating: 5, worstRating: 1 },
    }));
  }

  const breadcrumbItems = [
    { name: "Home", url: SITE_URL },
    ...(category ? [{ name: category.name, url: `${SITE_URL}/shop?category=${category.slug}` }] : []),
    { name: product.name, url: `${SITE_URL}/products/${product.slug}` },
  ];

  const breadcrumbJsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: breadcrumbItems.map((item, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: item.name,
      item: item.url,
    })),
  };

  return (
    <div className="mx-auto max-w-6xl px-6 py-16">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(productJsonLd) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }} />

      <nav aria-label="Breadcrumb" className="mb-6 font-body text-xs text-graphite">
        <ol className="flex flex-wrap items-center gap-1">
          <li>
            <a href="/" className="hover:text-ink">Home</a>
          </li>
          {category && (
            <>
              <li aria-hidden="true">/</li>
              <li>
                <a href={`/shop?category=${category.slug}`} className="hover:text-ink">
                  {category.name}
                </a>
              </li>
            </>
          )}
          <li aria-hidden="true">/</li>
          <li className="text-ink" aria-current="page">{product.name}</li>
        </ol>
      </nav>

      <div className="grid gap-12 md:grid-cols-2">
        <ProductGallery images={product.images} productName={product.name} />

        <div>
          <h1 className="font-display text-4xl text-ink">{product.name}</h1>
          {product.model_code && (
            <p className="mt-2 font-body text-sm text-graphite">Model code: {product.model_code}</p>
          )}
          <div className="mt-4 max-w-prose space-y-3 font-body text-graphite">
            {descriptionParagraphs.map((para, i) => (
              <p key={i}>{para}</p>
            ))}
          </div>

          <div className="mt-8">
            <VariantSelector
              productId={product.id}
              productName={product.name}
              productSlug={product.slug}
              imageUrl={product.images[0]?.url ?? null}
              attributes={attributes}
              variants={product.variants}
            />
          </div>

          {Object.keys(product.specs).length > 0 && (
            <div className="mt-10 border-t border-nickel/30 pt-6">
              <p className="mb-3 font-body text-sm text-graphite">Specifications</p>
              <dl className="grid grid-cols-2 gap-y-2 font-body text-sm">
                {Object.entries(product.specs).map(([key, value]) => (
                  <div key={key} className="contents">
                    <dt className="capitalize text-graphite">{key.replace(/_/g, " ")}</dt>
                    <dd className="text-ink">{value}</dd>
                  </div>
                ))}
              </dl>
            </div>
          )}

          <div className="mt-8 border-t border-nickel/30 pt-6">
            <ShareButtons path={`/products/${product.slug}`} text={`${product.name} — ${BRAND}`} />
          </div>
        </div>
      </div>

      <ProductReviews productId={product.id} />
    </div>
  );
}
