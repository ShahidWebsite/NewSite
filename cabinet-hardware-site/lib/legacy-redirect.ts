import { supabase } from "@/lib/supabase";

// Old WordPress/WooCommerce URLs that Google still remembers. Instead of sending
// everything to /shop (which Google treats as a "soft 404"), send each old URL to
// the closest matching page on the new site.

export async function categoryPathFor(text: string): Promise<string> {
  const t = text.toLowerCase().replace(/[-_/]+/g, " ");
  const { data } = await supabase.from("categories").select("slug");
  const slugs = new Set((data ?? []).map((c: any) => c.slug as string));
  const pick = (s: string) => (slugs.has(s) ? `/${s}` : null);

  if (/hinge/.test(t)) return pick("hinges") ?? "/shop";
  if (/antique|brass knob/.test(t)) return pick("brass-knob-antique-knob") ?? pick("cabinet-knob") ?? "/shop";
  if (/knob/.test(t)) return pick("cabinet-knob") ?? "/shop";
  if (/door|main/.test(t)) return pick("main-door-handle") ?? "/shop";
  if (/handle|pull|wardrobe|drawer|cabinet/.test(t)) return pick("cabinet-handles") ?? "/shop";
  return "/shop";
}

export async function productPathFor(oldSlug: string): Promise<string> {
  const slug = decodeURIComponent(oldSlug).toLowerCase();

  const { data: exact } = await supabase.from("products").select("slug").eq("slug", slug).eq("status", "active").maybeSingle();
  if (exact) return `/products/${exact.slug}`;

  const tokens = slug.split(/[^a-z0-9]+/).filter((w) => w.length >= 3);
  if (tokens.length) {
    const { data: all } = await supabase.from("products").select("slug, name").eq("status", "active");
    let best: { slug: string; score: number } | null = null;
    for (const p of all ?? []) {
      const hay = `${p.slug} ${p.name}`.toLowerCase();
      const hits = tokens.filter((t) => hay.includes(t)).length;
      const score = hits / tokens.length;
      if (!best || score > best.score) best = { slug: p.slug, score };
    }
    if (best && best.score >= 0.7) return `/products/${best.slug}`;
  }
  return categoryPathFor(slug);
}
