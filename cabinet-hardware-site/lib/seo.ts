import type { Metadata } from "next";

// ---------------------------------------------------------------------------
// Site-wide constants. Everything that talks to Google or social networks
// reads the business name / phone / domain from here, so they stay identical
// everywhere (Google compares them across the web — consistency matters).
// ---------------------------------------------------------------------------

export const SITE_URL = (process.env.NEXT_PUBLIC_SITE_URL || "https://www.siqbalhwc.com").replace(/\/$/, "");
export const BRAND = "Shahid Iqbal & Co";
export const PHONE = "+92 311 7798157";

export function absoluteUrl(path: string) {
  if (/^https?:\/\//i.test(path)) return path;
  return `${SITE_URL}${path.startsWith("/") ? path : `/${path}`}`;
}

// The branded 1200x630 card used when a page has no photo of its own.
// Served by app/og/route.tsx. WhatsApp, Facebook, Instagram DMs, LinkedIn and
// X all read this when someone shares a link.
export function ogImageUrl(opts?: { title?: string; tag?: string }) {
  const params = new URLSearchParams();
  if (opts?.title) params.set("title", opts.title);
  if (opts?.tag) params.set("tag", opts.tag);
  const qs = params.toString();
  return `${SITE_URL}/og${qs ? `?${qs}` : ""}`;
}

type PageMeta = {
  title: string;
  description?: string;
  path: string; // e.g. "/about" — becomes the canonical URL
  image?: string; // absolute URL of a photo; defaults to the branded card
  imageAlt?: string;
  noindex?: boolean;
  type?: "website" | "article";
  publishedTime?: string;
  modifiedTime?: string;
};

// One function that builds the complete <head> metadata for a page, including
// its OWN canonical URL. Next.js merges metadata shallowly, so every page must
// state its own canonical + social tags — otherwise it silently inherits the
// homepage's (that was the canonical bug).
export function pageMetadata(o: PageMeta): Metadata {
  const url = absoluteUrl(o.path);
  const image = o.image || ogImageUrl();
  const isCard = !o.image || image.startsWith(`${SITE_URL}/og`);

  const openGraph: Record<string, unknown> = {
    type: o.type || "website",
    url,
    siteName: BRAND,
    locale: "en_PK",
    title: o.title,
    description: o.description,
    images: [
      {
        url: image,
        alt: o.imageAlt || o.title,
        ...(isCard ? { width: 1200, height: 630 } : {}),
      },
    ],
  };
  if (o.type === "article") {
    if (o.publishedTime) openGraph.publishedTime = o.publishedTime;
    if (o.modifiedTime) openGraph.modifiedTime = o.modifiedTime;
  }

  return {
    title: o.title,
    description: o.description,
    alternates: { canonical: url },
    robots: o.noindex ? { index: false, follow: true } : undefined,
    openGraph: openGraph as Metadata["openGraph"],
    twitter: {
      card: "summary_large_image",
      title: o.title,
      description: o.description,
      images: [image],
    },
  };
}

// ---------------------------------------------------------------------------
// Small text helpers
// ---------------------------------------------------------------------------

export function slugify(text: string) {
  return text
    .toLowerCase()
    .trim()
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

const clean = (s?: string | null) => (s ?? "").replace(/\s+/g, " ").trim();
const lc = (s?: string | null) => clean(s).toLowerCase();

// Cuts at a word boundary so search results never end mid-word.
export function truncateAtWord(text: string, max: number) {
  const t = clean(text);
  if (t.length <= max) return t;
  const cut = t.slice(0, max - 1);
  const lastSpace = cut.lastIndexOf(" ");
  return `${(lastSpace > max * 0.6 ? cut.slice(0, lastSpace) : cut).replace(/[.,;:\s-]+$/, "")}…`;
}

// "Cabinet Handles" -> "Cabinet Handle"; "Cabinet Knob" stays as is.
export function singularize(phrase: string) {
  const p = clean(phrase);
  return /[^s]s$/i.test(p) ? p.slice(0, -1) : p;
}

export function joinList(items: string[]) {
  const a = items.map(clean).filter(Boolean);
  if (a.length <= 1) return a[0] ?? "";
  return `${a.slice(0, -1).join(", ")} and ${a[a.length - 1]}`;
}

// ---------------------------------------------------------------------------
// Product SEO — everything is generated from what the admin already typed
// (model code, category, material, finishes, sizes, weight, price). The admin
// can overwrite any generated field; these only fill in what was left blank.
// ---------------------------------------------------------------------------

export type ProductSeoInput = {
  name: string;
  modelCode?: string | null;
  categoryName?: string | null;
  material?: string | null;
  finishes?: string[];
  sizes?: string[];
  weight?: string | null;
  holeSpacing?: string | null;
  minPrice?: number | null;
  description?: string | null;
};

export type ProductKind = "door" | "knob" | "handle" | "other";

export function productKind(categoryName?: string | null, name?: string | null): ProductKind {
  const fromText = (t: string): ProductKind | null => {
    if (/\bdoor\b/.test(t)) return "door";
    if (/\bknobs?\b/.test(t)) return "knob";
    if (/\b(handles?|pulls?)\b/.test(t)) return "handle";
    return null;
  };
  return fromText(lc(categoryName)) ?? fromText(lc(name)) ?? "other";
}

export function fitTip(kind: ProductKind) {
  switch (kind) {
    case "door":
      return "Before ordering, check your door thickness and the position of the existing fixing holes so the handle fits without any extra drilling.";
    case "knob":
      return "Knobs mount with a single screw, so there is no hole spacing to match. Just make sure the screw length suits the thickness of your door or drawer.";
    case "handle":
      return "To get the right fit, measure the centre-to-centre distance between the two screw holes on your cabinet and choose a handle with the same hole spacing.";
    default:
      return "Please check the size and fit against your own measurements before ordering.";
  }
}

// A readable, keyword-rich product name from the admin's own inputs, e.g.
// "Golden Brass Cabinet Handle WH205 GP".
export function suggestProductName(i: Omit<ProductSeoInput, "name"> & { name?: string }) {
  const model = clean(i.modelCode);
  const category = i.categoryName ? singularize(i.categoryName) : "";
  if (!model && !category) return "";

  const finishes = (i.finishes ?? []).map(clean).filter(Boolean);
  const finish = finishes.length === 1 ? finishes[0] : "";
  let material = clean(i.material);
  if (finish && material && finish.toLowerCase().includes(material.toLowerCase())) material = "";

  const words = [finish, material, category, model].filter(Boolean);
  // Drop a word if the same phrase is already in the name (e.g. category already says "Brass").
  const out: string[] = [];
  for (const w of words) {
    if (!out.join(" ").toLowerCase().includes(w.toLowerCase())) out.push(w);
  }
  return out.join(" ");
}

// True for names that are just an internal code ("DHB001", "WH205 GR", "3885").
export function looksLikeCode(name?: string | null) {
  const n = clean(name);
  return n.length > 0 && n.length <= 16 && /\d/.test(n) && !/[A-Za-z]{4,}/.test(n) && /^[A-Za-z0-9 \-\/]+$/.test(n);
}

export function generateSeoTitle(i: ProductSeoInput) {
  const name = clean(i.name);
  const candidates = [
    `${name} — Buy in Lahore, Pakistan | ${BRAND}`,
    `${name} — Buy Online | ${BRAND}`,
    `${name} | ${BRAND}`,
  ];
  return candidates.find((c) => c.length <= 60) ?? truncateAtWord(candidates[2], 60);
}

export function generateSeoDescription(i: ProductSeoInput) {
  const name = clean(i.name);
  const finishes = (i.finishes ?? []).map(clean).filter(Boolean);
  const sizes = (i.sizes ?? []).map(clean).filter(Boolean);

  let out = `Buy ${name} online from ${BRAND}, Lahore.`;
  const extras: string[] = [];
  if (i.material) extras.push(`${clean(i.material)} construction.`);
  if (finishes.length) extras.push(`${finishes.length > 1 ? "Finishes" : "Finish"}: ${joinList(finishes)}.`);
  if (i.minPrice && i.minPrice > 0) extras.push(`From Rs. ${Math.round(i.minPrice).toLocaleString("en-US")}.`);
  extras.push("Delivery across Pakistan.");
  if (sizes.length) extras.push(`Sizes: ${joinList(sizes)}.`);

  for (const e of extras) {
    if ((out + " " + e).length <= 155) out += ` ${e}`;
  }
  return out;
}

export function generateProductDescription(i: ProductSeoInput) {
  const name = clean(i.name) || "This product";
  const finishes = (i.finishes ?? []).map(clean).filter(Boolean);
  const sizes = (i.sizes ?? []).map(clean).filter(Boolean);
  const kind = productKind(i.categoryName, i.name);

  let p1 = `${name} is available from ${BRAND} in Lahore`;
  if (finishes.length) p1 += `, in ${joinList(finishes)} ${finishes.length > 1 ? "finishes" : "finish"}`;
  if (sizes.length) p1 += `${finishes.length ? " and" : ","} in ${sizes.length > 1 ? "sizes" : "size"} ${joinList(sizes)}`;
  p1 += ".";

  const specBits: string[] = [];
  if (clean(i.material)) specBits.push(`made from ${lc(i.material)}`);
  if (clean(i.weight)) specBits.push(`weighs ${clean(i.weight)}`);
  if (clean(i.holeSpacing)) specBits.push(`${clean(i.holeSpacing)} hole spacing`);
  const p2 = specBits.length ? `${specBits.join(", ").replace(/^./, (c) => c.toUpperCase())}.` : "";

  const p3 = fitTip(kind);
  const p4 = `Order online with bank transfer and delivery across Pakistan, or WhatsApp us on ${PHONE} for bulk and wholesale prices.`;

  return [[p1, p2].filter(Boolean).join(" "), p3, p4].join("\n\n");
}

// If the admin's description is short (or missing) the product page shows it
// followed by the generated text, so every listing has real, useful copy.
export function expandDescription(i: ProductSeoInput) {
  const own = clean(i.description);
  if (own.length >= 160) return i.description as string;
  const generated = generateProductDescription(i);
  if (!own) return generated;
  const ownWithStop = /[.!?]$/.test(own) ? own : `${own}.`;
  return `${ownWithStop}\n\n${generated}`;
}

// Meta description: the admin's own SEO text if they wrote one, otherwise a
// fresh one generated from the product's details.
export function pickMetaDescription(seoDescription: string | null | undefined, i: ProductSeoInput) {
  return clean(seoDescription) || generateSeoDescription(i);
}

export function productImageAlt(name: string, index: number) {
  return index === 0 ? name : `${name} — photo ${index + 1}`;
}

// ---------------------------------------------------------------------------
// Blog SEO
// ---------------------------------------------------------------------------

export function generateBlogSeoTitle(title: string) {
  const t = clean(title);
  const withBrand = `${t} | ${BRAND}`;
  return withBrand.length <= 62 ? withBrand : truncateAtWord(t, 60);
}

export function generateBlogSeoDescription(excerpt: string) {
  return truncateAtWord(excerpt, 155);
}
