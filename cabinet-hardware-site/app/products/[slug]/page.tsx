import { notFound } from "next/navigation";
import { Metadata } from "next";
import { supabase } from "@/lib/supabase";
import VariantSelector from "@/components/VariantSelector";
import { Attribute, Product } from "@/lib/types";

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || "https://www.siqbalhwc.com";

async function getProduct(slug: string): Promise<{ product: Product; attributes: Attribute[] } | null> {
  const { data: product } = await supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
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
  };
}

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const { data: product } = await supabase
    .from("products")
    .select("name, description, seo_title, seo_description, product_images(url)")
    .eq("slug", params.slug)
    .single();

  if (!product) return {};

  const title = product.seo_title || `${product.name} — Shahid Iqbal & Co`;
  const description = product.seo_description || product.description || undefined;
  const image = (product as any).product_images?.[0]?.url;

  return {
    title,
    description,
    openGraph: { title, description, images: image ? [image] : undefined },
  };
}

export default async function ProductPage({ params }: { params: { slug: string } }) {
  const result = await getProduct(params.slug);
  if (!result) notFound();
  const { product, attributes } = result;

  const totalStock = product.variants.reduce((sum, v) => sum + v.stock_qty, 0);
  const priceRange = product.variants.length
    ? [Math.min(...product.variants.map((v) => v.price)), Math.max(...product.variants.map((v) => v.price))]
    : [product.base_price, product.base_price];

  const productJsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: product.name,
    description: product.description || product.name,
    image: product.images.map((img) => img.url),
    brand: { "@type": "Brand", name: "Shahid Iqbal & Co" },
    offers: {
      "@type": "AggregateOffer",
      priceCurrency: "PKR",
      lowPrice: priceRange[0],
      highPrice: priceRange[1],
      availability: totalStock > 0 ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
      url: `${SITE_URL}/products/${product.slug}`,
    },
  };

  return (
    <div className="mx-auto max-w-6xl px-6 py-16">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productJsonLd) }}
      />
      <div className="grid gap-12 md:grid-cols-2">
        <div className="aspect-square bg-nickel/10">
          {product.images[0] ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={product.images[0].url}
              alt={product.name}
              className="h-full w-full object-cover"
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center font-display text-2xl italic text-nickel">
              {product.name}
            </div>
          )}
        </div>

        <div>
          <h1 className="font-display text-4xl text-ink">{product.name}</h1>
          {product.description && (
            <p className="mt-4 max-w-prose font-body text-graphite">{product.description}</p>
          )}

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
        </div>
      </div>
    </div>
  );
}
