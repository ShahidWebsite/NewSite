import { MetadataRoute } from "next";
import { supabase } from "@/lib/supabase";

// Update this once your real domain (www.siqbalhwc.com) is connected in Vercel.
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || "https://www.siqbalhwc.com";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [{ data: products }, { data: categories }] = await Promise.all([
    supabase.from("products").select("slug, updated_at").eq("status", "active"),
    supabase.from("categories").select("slug"),
  ]);

  const staticPages: MetadataRoute.Sitemap = [
    { url: SITE_URL, changeFrequency: "daily", priority: 1 },
    { url: `${SITE_URL}/shop`, changeFrequency: "daily", priority: 0.9 },
    { url: `${SITE_URL}/track-order`, changeFrequency: "monthly", priority: 0.3 },
  ];

  const categoryPages: MetadataRoute.Sitemap = (categories ?? []).map((c) => ({
    url: `${SITE_URL}/shop?category=${c.slug}`,
    changeFrequency: "weekly",
    priority: 0.7,
  }));

  const productPages: MetadataRoute.Sitemap = (products ?? []).map((p) => ({
    url: `${SITE_URL}/products/${p.slug}`,
    lastModified: p.updated_at ? new Date(p.updated_at) : undefined,
    changeFrequency: "weekly",
    priority: 0.8,
  }));

  return [...staticPages, ...categoryPages, ...productPages];
}
