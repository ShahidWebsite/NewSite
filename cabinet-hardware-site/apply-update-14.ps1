# ============================================================================
# Website update script — run this from PowerShell on your computer.
# What it does, in order:
#   1. Gets a clean, up-to-date copy of the code from GitHub
#   2. Fixes the duplicate "Cabinet Handles" menu item and duplicate
#      "128mm" / "128MM" size (this part is code-safety-net; the main fix
#      for those two is the SQL script — see apply-update-14.sql)
#   3. Lets you add a photo to each category (Cabinet Knobs, Cabinet
#      Handles, etc.) from the Categories admin page, and shows it on the
#      homepage "Shop by category" section
#   4. Adds a real product photo to the homepage hero banner automatically
#      (uses your newest product photo — no extra step needed)
#   5. Adds an "+ Insert photo" button inside the blog editor's article
#      text, so a picture (like a sizing diagram) can be dropped in right
#      where it's needed, not just as the cover photo
#   6. Commits and pushes the change — Vercel then deploys it automatically
#
# IMPORTANT: run apply-update-14.sql in Supabase's SQL Editor FIRST (before
# or after this script, order doesn't matter, but do both). The SQL script
# is what actually removes the duplicate category and duplicate size rows
# from the database, and adds the new "photo" column categories need.
# ============================================================================

# 1. Always work from a clean, up-to-date copy
cd "$HOME\Desktop\NewSite"        # adjust to wherever your local clone lives
git pull origin main

@'
export type Category = {
  id: string;
  name: string;
  slug: string;
  image_url?: string | null;
};

export type ProductImage = {
  id: string;
  url: string;
  sort_order: number;
};

export type AttributeValue = {
  id: string;
  value: string;
  swatch_hex: string | null;
  attribute_id: string;
};

export type Attribute = {
  id: string;
  name: string;
  values: AttributeValue[];
};

export type Variant = {
  id: string;
  sku: string | null;
  price: number;
  stock_qty: number;
  attribute_value_ids: string[];
};

export type Product = {
  id: string;
  name: string;
  slug: string;
  model_code?: string | null;
  seo_title?: string | null;
  seo_description?: string | null;
  description: string | null;
  specs: Record<string, string>;
  base_price: number;
  status: "active" | "out_of_stock" | "discontinued";
  category_id: string | null;
  images: ProductImage[];
  variants: Variant[];
};

export type CartLine = {
  productId: string;
  productName: string;
  productSlug: string;
  variantId: string;
  variantLabel: string;
  unitPrice: number;
  quantity: number;
  imageUrl: string | null;
};

export type Review = {
  id: string;
  product_id: string | null;
  customer_name: string;
  rating: number;
  body: string;
  approved: boolean;
  created_at: string;
};

export type BankSettings = {
  account_title: string;
  bank_name: string;
  account_number: string;
  ifsc_or_routing: string;
  instructions: string;
};

export type BankAccount = {
  id: string;
  bank_name: string;
  account_title: string;
  account_number: string;
  ifsc_or_routing: string;
  sort_order: number;
  active: boolean;
};

export type BlogPost = {
  id: string;
  slug: string;
  title: string;
  tag: string | null;
  excerpt: string | null;
  content: string;
  cover_image_url: string | null;
  seo_title: string | null;
  seo_description: string | null;
  published: boolean;
  published_at: string | null;
  created_at: string;
  updated_at: string;
};
'@ | Set-Content "cabinet-hardware-site\lib\types.ts"

@'
import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";
import { supabase } from "@/lib/supabase";
import { pageMetadata } from "@/lib/seo";
import ProductCard from "@/components/ProductCard";
import Testimonials from "@/components/Testimonials";
import Reveal from "@/components/Reveal";
import BlogCard from "@/components/BlogCard";
import { BlogPost, Product } from "@/lib/types";

export const metadata: Metadata = pageMetadata({
  title: "Door & Cabinet Handles in Lahore | Shahid Iqbal & Co",
  description:
    "Brass door handles, cabinet handles, knobs and furniture pulls in Lahore. Exact specs on every listing, bank-transfer checkout and delivery across Pakistan.",
  path: "/",
});

// Without this, Next.js bakes the homepage into a static snapshot at build
// time — so new products/photos added later through /admin would never show
// up here until the next deploy. This makes it fetch fresh data every visit.
export const dynamic = "force-dynamic";

async function getFeaturedProducts(): Promise<Product[]> {
  const { data } = await supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
    .eq("status", "active")
    .order("created_at", { ascending: false })
    .limit(8);

  if (!data) return [];

  return data.map((p: any) => ({
    ...p,
    images: (p.product_images ?? []).sort((a: any, b: any) => a.sort_order - b.sort_order),
    variants: (p.product_variants ?? []).map((v: any) => ({
      ...v,
      attribute_value_ids: (v.variant_attribute_values ?? []).map((j: any) => j.attribute_value_id),
    })),
  }));
}

async function getLatestPosts(): Promise<Pick<BlogPost, "slug" | "title" | "tag" | "excerpt" | "cover_image_url" | "content">[]> {
  const { data } = await supabase
    .from("blog_posts")
    .select("slug, title, tag, excerpt, cover_image_url, content")
    .eq("published", true)
    .order("published_at", { ascending: false })
    .limit(3);
  return data ?? [];
}

async function getCategories() {
  const { data } = await supabase.from("categories").select("*").order("sort_order");
  return data ?? [];
}

export default async function HomePage() {
  const [products, categories, posts] = await Promise.all([getFeaturedProducts(), getCategories(), getLatestPosts()]);

  // Prefer the newest active product that actually has a photo, so the hero
  // always shows something real from the catalog rather than going stale.
  const heroProduct = products.find((p) => p.images[0]?.url);
  const heroImage = heroProduct?.images[0]?.url;

  return (
    <>
      {/* Hero */}
      <section className="bg-blacknickel text-stone">
        <div className="mx-auto grid max-w-6xl gap-10 px-6 py-24 md:grid-cols-2 md:items-center md:py-32">
          <div>
            <p className="font-body text-sm text-brass">Dream Hardware at your Door Step</p>
            <h1 className="mt-4 font-display text-5xl leading-[1.05] md:text-6xl">
              Handles and knobs that hold up to daily use.
            </h1>
            <p className="mt-6 max-w-prose font-body text-stone/70">
              Door handles, cabinet handles, knobs, and furniture pulls —
              specialized in brass, in the sizes your cabinets already take.
              Every listing shows the exact hole spacing before you order.
            </p>
            <div className="mt-8 flex gap-4">
              <Link
                href="/shop"
                className="bg-brass px-6 py-3 font-body text-sm text-blacknickel transition-colors hover:bg-stone"
              >
                Shop all products
              </Link>
              <Link
                href="/track-order"
                className="border border-stone/30 px-6 py-3 font-body text-sm text-stone transition-colors hover:border-stone"
              >
                Track an order
              </Link>
            </div>
          </div>

          <div>
            {/* Product photo, when the catalog has one — this is the "hint" of
                real hardware that makes the hero feel less flat. Falls back
                to a soft brass-toned panel so the layout still looks
                intentional before photography is uploaded. */}
            <div className="relative aspect-[4/3] overflow-hidden rounded-sm bg-gradient-to-br from-brass/25 via-blacknickel to-blacknickel">
              {heroImage ? (
                <Image
                  src={heroImage}
                  alt={heroProduct?.name ?? "Featured hardware"}
                  fill
                  priority
                  sizes="(min-width: 768px) 45vw, 90vw"
                  className="object-cover"
                />
              ) : (
                <div className="flex h-full w-full items-center justify-center">
                  <svg width="72" height="72" viewBox="0 0 24 24" fill="none" className="text-brass/60">
                    <rect x="4" y="10" width="16" height="3" rx="1.5" stroke="currentColor" strokeWidth="1.3" />
                    <circle cx="6.5" cy="11.5" r="0.6" fill="currentColor" />
                    <circle cx="17.5" cy="11.5" r="0.6" fill="currentColor" />
                  </svg>
                </div>
              )}
            </div>

            {/* Finish swatches — a literal, materials-first hero element */}
            <div className="mt-6 grid grid-cols-3 gap-4">
              {[
                { name: "Matte Black", hex: "#1C1B19" },
                { name: "Golden", hex: "#A9832E" },
                { name: "Chrome", hex: "#9B9992" },
              ].map((finish) => (
                <Link key={finish.name} href={`/shop?color=${encodeURIComponent(finish.name)}`} className="group space-y-3">
                  <div
                    className="aspect-square rounded-full border-2 border-stone/40 ring-1 ring-black/20 transition-transform group-hover:scale-105"
                    style={{ backgroundColor: finish.hex }}
                  />
                  <p className="text-center font-body text-xs text-stone/60 group-hover:text-stone">{finish.name}</p>
                </Link>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Category tiles */}
      {categories.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <Reveal>
            <h2 className="font-display text-3xl text-ink">Shop by category</h2>
          </Reveal>
          <div className="mt-8 grid gap-6 sm:grid-cols-2 md:grid-cols-4">
            {categories.map((cat, i) => (
              <Reveal key={cat.id} delay={i * 60}>
                <Link
                  href={`/shop?category=${cat.slug}`}
                  className="group block border border-nickel/30 transition-all duration-300 hover:-translate-y-0.5 hover:border-brass hover:shadow-[0_10px_25px_-15px_rgba(42,40,37,0.3)]"
                >
                  <div className="relative aspect-square overflow-hidden bg-gradient-to-br from-ink/[0.06] to-brass/10">
                    {cat.image_url ? (
                      <Image
                        src={cat.image_url}
                        alt={cat.name}
                        fill
                        sizes="(min-width: 768px) 25vw, 50vw"
                        className="object-cover transition-transform duration-300 group-hover:scale-[1.04]"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center">
                        <svg width="44" height="44" viewBox="0 0 24 24" fill="none" className="text-brass/50">
                          <circle cx="12" cy="8.5" r="3.2" stroke="currentColor" strokeWidth="1.3" />
                          <line x1="12" y1="11.7" x2="12" y2="18" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
                          <line x1="8.5" y1="18" x2="15.5" y2="18" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
                        </svg>
                      </div>
                    )}
                  </div>
                  <div className="flex items-center justify-between px-5 py-4">
                    <span className="font-display text-lg text-ink">{cat.name}</span>
                    <span className="font-body text-graphite transition-transform duration-300 group-hover:translate-x-1 group-hover:text-brass">
                      →
                    </span>
                  </div>
                </Link>
              </Reveal>
            ))}
          </div>
        </section>
      )}

      {/* Featured products */}
      {products.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <Reveal>
            <div className="flex items-baseline justify-between">
              <h2 className="font-display text-3xl text-ink">Recently added</h2>
              <Link href="/shop" className="font-body text-sm text-graphite hover:text-brass">
                View all
              </Link>
            </div>
          </Reveal>
          <div className="mt-8 grid gap-x-6 gap-y-10 sm:grid-cols-2 md:grid-cols-4">
            {products.map((p, i) => (
              <Reveal key={p.id} delay={i * 60}>
                <ProductCard product={p} />
              </Reveal>
            ))}
          </div>
        </section>
      )}

      {/* Trust / specs section */}
      <section className="border-y border-nickel/20 bg-ink/[0.03] py-20">
        <div className="mx-auto max-w-6xl px-6">
          <div className="grid gap-6 md:grid-cols-3">
            {[
              {
                icon: (
                  <path
                    d="M4 15L15 4M8 16l-4-4M9 20l3-3M4 11l4 4m5-11l4 4m-8 4l4 4"
                    stroke="currentColor"
                    strokeWidth="1.4"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                ),
                title: "Exact specs, every listing",
                body: "Hole spacing, material, and weight are listed on every product — no guessing before your cabinets arrive.",
              },
              {
                icon: (
                  <>
                    <path d="M3 9l9-5 9 5" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
                    <path
                      d="M5 9v9m4-9v9m4-9v9m4-9v9M3 20h18"
                      stroke="currentColor"
                      strokeWidth="1.4"
                      strokeLinecap="round"
                    />
                  </>
                ),
                title: "Bank transfer accepted",
                body: "Pay by direct bank transfer with your order number as reference — details are shown at checkout.",
              },
              {
                icon: (
                  <>
                    <path
                      d="M12 21s7-6.1 7-11.5A7 7 0 105 9.5C5 14.9 12 21 12 21z"
                      stroke="currentColor"
                      strokeWidth="1.4"
                      strokeLinejoin="round"
                    />
                    <circle cx="12" cy="9.5" r="2.3" stroke="currentColor" strokeWidth="1.4" />
                  </>
                ),
                title: "Track your order",
                body: "Look up your order anytime with your order number and email to see its current status.",
              },
            ].map((item, i) => (
              <Reveal key={item.title} delay={i * 100}>
                <div className="group h-full border border-transparent px-2 py-2 transition-colors duration-300 hover:border-nickel/20">
                  <span className="flex h-11 w-11 items-center justify-center border border-brass/40 text-brass transition-colors duration-300 group-hover:bg-brass group-hover:text-stone">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                      {item.icon}
                    </svg>
                  </span>
                  <p className="mt-4 font-display text-xl text-ink">{item.title}</p>
                  <p className="mt-3 font-body text-sm text-graphite">{item.body}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <Testimonials />

      {/* Latest guides — fresh content + internal links help Google understand the site */}
      {posts.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <Reveal>
            <div className="flex items-baseline justify-between">
              <h2 className="font-display text-3xl text-ink">Buying guides</h2>
              <Link href="/blog" className="font-body text-sm text-graphite hover:text-brass">
                All guides
              </Link>
            </div>
          </Reveal>
          <div className="mt-8 grid gap-8 md:grid-cols-3">
            {posts.map((post, i) => (
              <Reveal key={post.slug} delay={i * 60}>
                <BlogCard post={post} />
              </Reveal>
            ))}
          </div>
        </section>
      )}
    </>
  );
}
'@ | Set-Content "cabinet-hardware-site\app\page.tsx"

@'
"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import { supabase } from "@/lib/supabase";

const STORAGE_BUCKET = "product-images"; // same bucket as product photos, in a "categories/" folder

function slugify(text: string) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
}

export default function AdminCategoriesPage() {
  const [categories, setCategories] = useState<any[]>([]);
  const [newName, setNewName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [uploadingId, setUploadingId] = useState<string | null>(null);
  const fileInputs = useRef<Record<string, HTMLInputElement | null>>({});

  async function load() {
    setLoading(true);
    const { data } = await supabase.from("categories").select("*, products(count)").order("sort_order");
    setCategories(data ?? []);
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function handleAdd() {
    const trimmed = newName.trim();
    if (!trimmed) return;
    setError(null);

    // Guard against the same category being added twice (e.g. different
    // capitalization or spacing) — this is what caused duplicate entries in
    // the site menu before.
    const alreadyExists = categories.some((c) => c.name.trim().toLowerCase() === trimmed.toLowerCase());
    if (alreadyExists) {
      setError(`"${trimmed}" already exists as a category — no need to add it again.`);
      return;
    }

    const { error } = await supabase
      .from("categories")
      .insert({ name: trimmed, slug: slugify(trimmed), sort_order: categories.length });
    if (error) {
      setError(
        error.message.includes("duplicate")
          ? `"${trimmed}" already exists as a category — no need to add it again.`
          : error.message
      );
      return;
    }
    setNewName("");
    load();
  }

  async function handleDelete(id: string, productCount: number) {
    if (productCount > 0) {
      alert(`This category has ${productCount} product(s) in it. Move or delete those first.`);
      return;
    }
    if (!confirm("Delete this category?")) return;
    await supabase.from("categories").delete().eq("id", id);
    load();
  }

  async function handlePhotoChange(id: string, file: File | null) {
    if (!file) return;
    setError(null);
    setUploadingId(id);
    try {
      const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-");
      const path = `categories/${id}-${Date.now()}-${cleanName}`;
      const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, file);
      if (uploadError) throw new Error(`Photo upload failed: ${uploadError.message}`);
      const url = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path).data.publicUrl;
      const { error: updateError } = await supabase.from("categories").update({ image_url: url }).eq("id", id);
      if (updateError) throw new Error(updateError.message);
      await load();
    } catch (err: any) {
      setError(err.message || "Something went wrong uploading this photo.");
    } finally {
      setUploadingId(null);
    }
  }

  async function handleRemovePhoto(id: string) {
    await supabase.from("categories").update({ image_url: null }).eq("id", id);
    load();
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Categories</h1>
      <p className="mt-2 max-w-xl font-body text-sm text-graphite">
        Each category can have a photo — it's what shows on the homepage under
        &quot;Shop by category&quot;. Categories without a photo show a plain
        placeholder icon instead.
      </p>

      <div className="mt-8 flex max-w-md gap-2">
        <input
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleAdd()}
          placeholder="New category name (e.g. Drawer Pulls)"
          className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink"
        />
        <button onClick={handleAdd} className="bg-ink px-4 py-2 font-body text-sm text-stone hover:bg-brass">
          Add
        </button>
      </div>
      {error && <p className="mt-2 font-body text-sm text-rust">{error}</p>}

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : (
        <div className="mt-8 max-w-2xl divide-y divide-nickel/20 border-y border-nickel/20">
          {categories.map((cat) => (
            <div key={cat.id} className="flex items-center justify-between gap-4 py-4 font-body text-sm">
              <div className="flex items-center gap-4">
                <div className="relative h-16 w-16 flex-shrink-0 overflow-hidden border border-nickel/30 bg-nickel/10">
                  {cat.image_url ? (
                    <Image src={cat.image_url} alt={cat.name} fill sizes="64px" className="object-cover" />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center text-xs text-graphite">No photo</div>
                  )}
                </div>
                <div>
                  <span className="block text-ink">{cat.name}</span>
                  <span className="text-graphite">{cat.products?.[0]?.count ?? 0} products</span>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <input
                  ref={(el) => {
                    fileInputs.current[cat.id] = el;
                  }}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => handlePhotoChange(cat.id, e.target.files?.[0] ?? null)}
                />
                <button
                  type="button"
                  disabled={uploadingId === cat.id}
                  onClick={() => fileInputs.current[cat.id]?.click()}
                  className="border border-nickel/50 px-3 py-1.5 text-graphite hover:border-ink hover:text-ink disabled:opacity-60"
                >
                  {uploadingId === cat.id ? "Uploading…" : cat.image_url ? "Change photo" : "+ Add photo"}
                </button>
                {cat.image_url && (
                  <button type="button" onClick={() => handleRemovePhoto(cat.id)} className="text-graphite hover:text-rust">
                    Remove photo
                  </button>
                )}
                <button
                  onClick={() => handleDelete(cat.id, cat.products?.[0]?.count ?? 0)}
                  className="text-graphite hover:text-rust"
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
          {categories.length === 0 && <p className="py-3 font-body text-sm text-graphite">No categories yet.</p>}
        </div>
      )}
    </div>
  );
}
'@ | Set-Content "cabinet-hardware-site\app\admin\categories\page.tsx"

@'
"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import SeoFields from "@/components/admin/SeoFields";
import { firstParagraph } from "@/lib/markdown";
import { generateBlogSeoDescription, generateBlogSeoTitle, slugify, truncateAtWord } from "@/lib/seo";
import { BlogPost } from "@/lib/types";

const STORAGE_BUCKET = "product-images"; // same bucket as product photos, in a "blog/" folder

export default function BlogPostForm({ existing }: { existing?: BlogPost }) {
  const router = useRouter();
  const isEdit = !!existing;

  const [title, setTitle] = useState(existing?.title ?? "");
  const [tag, setTag] = useState(existing?.tag ?? "");
  const [content, setContent] = useState(existing?.content ?? "");
  const [slugOverride, setSlugOverride] = useState<string | null>(existing ? existing.slug : null);
  const [excerptOverride, setExcerptOverride] = useState<string | null>(existing?.excerpt ? existing.excerpt : null);
  const [seoTitleOverride, setSeoTitleOverride] = useState<string | null>(existing?.seo_title || null);
  const [seoDescOverride, setSeoDescOverride] = useState<string | null>(existing?.seo_description || null);
  const [published, setPublished] = useState(existing?.published ?? false);
  const [coverUrl, setCoverUrl] = useState<string | null>(existing?.cover_image_url ?? null);
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showHelp, setShowHelp] = useState(false);
  const [insertingImage, setInsertingImage] = useState(false);
  const contentRef = useRef<HTMLTextAreaElement | null>(null);

  // ---- Automatic values, built from what's been written ----
  const slug = slugOverride ?? slugify(title);
  const autoExcerpt = truncateAtWord(firstParagraph(content), 160);
  const excerpt = excerptOverride ?? autoExcerpt;
  const autoSeoTitle = title ? generateBlogSeoTitle(title) : "";
  const autoSeoDescription = excerpt ? generateBlogSeoDescription(excerpt) : "";
  const seoTitle = seoTitleOverride ?? autoSeoTitle;
  const seoDescription = seoDescOverride ?? autoSeoDescription;

  // Uploads a photo the same way the cover photo does, then drops it into
  // the article text as a markdown image — right where the cursor is, so a
  // photo can sit next to whichever paragraph it explains (e.g. a sizing
  // diagram inside a "How to measure" guide).
  async function handleInsertImage(file: File | null) {
    if (!file) return;
    setInsertingImage(true);
    setError(null);
    try {
      const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-");
      const path = `blog/${Date.now()}-${cleanName}`;
      const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, file);
      if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);
      const url = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path).data.publicUrl;

      const textarea = contentRef.current;
      const markdown = `![](${url})`;
      if (textarea) {
        const start = textarea.selectionStart ?? content.length;
        const end = textarea.selectionEnd ?? content.length;
        const before = content.slice(0, start);
        const after = content.slice(end);
        // Keep the image on its own line, with a blank line on each side.
        const prefix = before && !before.endsWith("\n\n") ? (before.endsWith("\n") ? "\n" : "\n\n") : "";
        const suffix = after && !after.startsWith("\n\n") ? (after.startsWith("\n") ? "\n" : "\n\n") : "";
        const next = `${before}${prefix}${markdown}${suffix}${after}`;
        setContent(next);
        // Put the cursor right after the inserted image next render.
        requestAnimationFrame(() => {
          const pos = (before + prefix + markdown).length;
          textarea.focus();
          textarea.setSelectionRange(pos, pos);
        });
      } else {
        setContent((c) => `${c}${c ? "\n\n" : ""}${markdown}\n\n`);
      }
    } catch (err: any) {
      setError(err.message || "Something went wrong uploading this photo.");
    } finally {
      setInsertingImage(false);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);

    try {
      if (!slug) throw new Error("Please add a title.");

      let cover = coverUrl;
      if (coverFile) {
        const cleanName = coverFile.name.replace(/[^a-zA-Z0-9._-]/g, "-");
        const path = `blog/${Date.now()}-${cleanName}`;
        const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, coverFile);
        if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);
        cover = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path).data.publicUrl;
      }

      const now = new Date().toISOString();
      const payload = {
        slug,
        title: title.trim(),
        tag: tag.trim() || null,
        excerpt: excerpt.trim() || null,
        content,
        cover_image_url: cover,
        seo_title: seoTitleOverride?.trim() || null, // null = generated automatically
        seo_description: seoDescOverride?.trim() || null,
        published,
        // First time it goes live, stamp the date; keep the original date afterwards.
        published_at: published ? existing?.published_at ?? now : existing?.published_at ?? null,
        updated_at: now,
      };

      const result = isEdit
        ? await supabase.from("blog_posts").update(payload).eq("id", existing!.id)
        : await supabase.from("blog_posts").insert(payload);
      if (result.error) {
        throw new Error(
          result.error.message.includes("duplicate")
            ? "Another post already uses this web address — change the title or the web address."
            : result.error.message
        );
      }

      router.push("/admin/blog");
    } catch (err: any) {
      setError(err.message || "Something went wrong saving this post.");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mt-8 max-w-3xl space-y-8">
      {error && (
        <div className="border-2 border-rust bg-rust/10 p-4">
          <p className="font-body text-sm font-medium text-rust">Could not save this post:</p>
          <p className="mt-1 font-body text-sm text-rust">{error}</p>
        </div>
      )}

      <div className="space-y-4">
        <label className="block">
          <span className="font-body text-sm text-graphite">Title</span>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            placeholder="e.g. How to measure cabinet handle hole spacing"
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
          />
        </label>

        <label className="block">
          <span className="font-body text-sm text-graphite">Topic (one or two words, e.g. Sizing, Materials, Care)</span>
          <input
            value={tag}
            onChange={(e) => setTag(e.target.value)}
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
          />
        </label>

        <div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Web address</span>
            <div className="mt-1 flex items-center border border-nickel/50">
              <span className="px-3 font-body text-sm text-graphite">/blog/</span>
              <input
                value={slug}
                onChange={(e) => setSlugOverride(slugify(e.target.value) || null)}
                disabled={isEdit}
                className="w-full bg-transparent py-2 pr-3 font-body text-ink disabled:text-graphite"
              />
            </div>
          </label>
          <p className="mt-1 font-body text-xs text-graphite">
            {isEdit
              ? "The web address can't be changed after publishing, so existing links keep working."
              : "Made from the title automatically. Keep it short and descriptive."}
          </p>
        </div>

        <div>
          <div className="flex items-center justify-between">
            <span className="font-body text-sm text-graphite">Article text</span>
            <div className="flex items-center gap-4">
              <label className="cursor-pointer font-body text-xs text-graphite underline hover:text-ink">
                {insertingImage ? "Uploading…" : "+ Insert photo"}
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  disabled={insertingImage}
                  onChange={(e) => {
                    handleInsertImage(e.target.files?.[0] ?? null);
                    e.target.value = "";
                  }}
                />
              </label>
              <button
                type="button"
                onClick={() => setShowHelp((v) => !v)}
                className="font-body text-xs text-graphite underline hover:text-ink"
              >
                {showHelp ? "Hide formatting help" : "Formatting help"}
              </button>
            </div>
          </div>
          <p className="mt-1 font-body text-xs text-graphite">
            Click into the article text where you want a photo to appear (e.g. right after the
            paragraph it explains), then use &quot;+ Insert photo&quot; — it drops the picture in
            at that spot.
          </p>
          {showHelp && (
            <pre className="mt-2 overflow-x-auto border border-nickel/30 bg-white/50 p-3 font-body text-xs leading-relaxed text-graphite">
{`## A big heading
### A smaller heading
Normal paragraph text. **Bold**, *italic*, [a link](/shop?category=cabinet-handles)

- A bullet point
- Another bullet point

1. First step
2. Second step

| Size | Best for |
|---|---|
| 96mm | Drawers |
| 128mm | Wardrobe doors |

![](a photo — use the "+ Insert photo" button above instead of typing this by hand)

## Frequently asked questions
### A question a customer might ask?
The answer, in a normal paragraph.`}
            </pre>
          )}
          <textarea
            ref={contentRef}
            value={content}
            onChange={(e) => setContent(e.target.value)}
            required
            rows={24}
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm leading-relaxed text-ink"
          />
          <p className="mt-1 font-body text-xs text-graphite">
            Tip: aim for 600+ words that genuinely answer a customer question. A section titled
            &quot;Frequently asked questions&quot; with a smaller heading for each question automatically
            becomes Google FAQ results.
          </p>
        </div>

        <div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Short summary (shown on the Guides page)</span>
            <textarea
              value={excerpt}
              onChange={(e) => setExcerptOverride(e.target.value === "" ? null : e.target.value)}
              rows={2}
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            />
          </label>
          <p className="mt-1 font-body text-xs text-graphite">
            {excerptOverride === null ? "Taken from the first paragraph automatically." : "Using your own wording."}
            {excerptOverride !== null && (
              <button type="button" onClick={() => setExcerptOverride(null)} className="ml-2 underline hover:text-ink">
                Reset to auto
              </button>
            )}
          </p>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">Cover photo (optional)</p>
          <p className="font-body text-xs text-graphite">
            If you skip this, a branded picture with the title is used automatically — including when the
            post is shared on WhatsApp or Facebook.
          </p>
          <div className="mt-2 flex items-center gap-4">
            {(coverFile || coverUrl) && (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={coverFile ? URL.createObjectURL(coverFile) : coverUrl!}
                alt=""
                className="h-20 w-32 border border-nickel/30 object-cover"
              />
            )}
            <label className="cursor-pointer border border-dashed border-nickel/50 px-4 py-2 font-body text-sm text-graphite hover:border-ink hover:text-ink">
              {coverFile || coverUrl ? "Change photo" : "+ Add photo"}
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => setCoverFile(e.target.files?.[0] ?? null)}
              />
            </label>
            {(coverFile || coverUrl) && (
              <button
                type="button"
                onClick={() => {
                  setCoverFile(null);
                  setCoverUrl(null);
                }}
                className="font-body text-sm text-graphite hover:text-rust"
              >
                Remove
              </button>
            )}
          </div>
        </div>
      </div>

      <SeoFields
        urlPreview={`www.siqbalhwc.com › blog › ${slug || "your-post"}`}
        title={seoTitle}
        description={seoDescription}
        titleIsAuto={seoTitleOverride === null}
        descriptionIsAuto={seoDescOverride === null}
        onTitleChange={(v) => setSeoTitleOverride(v === "" ? null : v)}
        onDescriptionChange={(v) => setSeoDescOverride(v === "" ? null : v)}
        onResetTitle={() => setSeoTitleOverride(null)}
        onResetDescription={() => setSeoDescOverride(null)}
      />

      <label className="flex items-center gap-3">
        <input type="checkbox" checked={published} onChange={(e) => setPublished(e.target.checked)} className="h-4 w-4" />
        <span className="font-body text-sm text-ink">
          Published — visible on the website {published ? "" : "(untick to keep it as a private draft)"}
        </span>
      </label>

      <button
        type="submit"
        disabled={saving}
        className="bg-ink px-6 py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
      >
        {saving ? "Saving…" : isEdit ? "Save changes" : "Save post"}
      </button>
    </form>
  );
}
'@ | Set-Content "cabinet-hardware-site\components\admin\BlogPostForm.tsx"

# 2. Commit and push — Vercel picks this up automatically, no further action needed
git add .
git commit -m "Fix duplicate menu/size entries, add category + blog photos, hero photo"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host "Don't forget: also run apply-update-14.sql in Supabase's SQL Editor if you haven't yet."
