# ============================================================================
# Update script: Contact/Bulk Enquiry page, clean category URLs, and
# Cash on Delivery (Leopard Courier, weight-based shipping).
#
# Run this from PowerShell. It pulls the latest code, writes every changed
# file, commits, and pushes. Vercel deploys automatically after the push.
# ============================================================================

cd "$HOME\Desktop\NewSite"        # adjust if your local clone lives elsewhere
git pull origin main

Set-Location "cabinet-hardware-site"

# ---- app/admin/layout.tsx ----
$path = "app/admin/layout.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    if (pathname === "/admin/login") {
      setChecked(true);
      return;
    }
    supabase.auth.getSession().then(({ data }) => {
      if (!data.session) {
        router.replace("/admin/login");
      } else {
        setChecked(true);
      }
    });
  }, [pathname, router]);

  if (pathname === "/admin/login") return <>{children}</>;
  if (!checked) return <div className="p-10 font-body text-graphite">Checking session…</div>;

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6 px-6 py-10 sm:flex-row sm:gap-10">
      <aside className="w-full flex-shrink-0 sm:w-48">
        <p className="font-display text-xl text-ink">Admin</p>
        <nav className="mt-4 flex gap-4 font-body text-sm sm:mt-6 sm:flex-col sm:gap-2">
          <AdminLink href="/admin" label="Dashboard" />
          <AdminLink href="/admin/products" label="Products" />
          <AdminLink href="/admin/categories" label="Categories" />
          <AdminLink href="/admin/blog" label="Guides (blog)" />
          <AdminLink href="/admin/orders" label="Orders" />
          <AdminLink href="/admin/enquiries" label="Enquiries" />
          <AdminLink href="/admin/reviews" label="Reviews" />
          <AdminLink href="/admin/bank-accounts" label="Bank Accounts" />
          <AdminLink href="/admin/shipping-settings" label="Shipping (COD)" />
        </nav>
        <button
          onClick={async () => {
            await supabase.auth.signOut();
            router.push("/admin/login");
          }}
          className="mt-8 font-body text-sm text-graphite hover:text-rust"
        >
          Sign out
        </button>
      </aside>
      <div className="flex-1">{children}</div>
    </div>
  );
}

function AdminLink({ href, label }: { href: string; label: string }) {
  return (
    <Link href={href} className="block text-graphite hover:text-ink">
      {label}
    </Link>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/admin/orders/page.tsx ----
$path = "app/admin/orders/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

const FULFILLMENT_STEPS = ["processing", "packed", "shipped", "delivered", "cancelled"];

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const { data } = await supabase.from("orders").select("*").order("created_at", { ascending: false });
    setOrders(data ?? []);
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function markPaid(id: string) {
    await supabase.from("orders").update({ payment_status: "paid" }).eq("id", id);
    load();
  }

  async function updateFulfillment(id: string, status: string) {
    await supabase.from("orders").update({ fulfillment_status: status }).eq("id", id);
    load();
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Orders</h1>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : orders.length === 0 ? (
        <p className="mt-8 font-body text-graphite">No orders yet.</p>
      ) : (
        <div className="mt-8 space-y-4">
          {orders.map((order) => (
            <div key={order.id} className="border border-nickel/30 p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="font-body text-ink">
                    {order.order_number}
                    <span className="ml-2 border border-nickel/40 px-1.5 py-0.5 font-body text-xs uppercase text-graphite">
                      {order.payment_method === "cod" ? "COD" : "Bank transfer"}
                    </span>
                  </p>
                  <p className="font-body text-sm text-graphite">
                    {order.customer_name} · {order.email}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-display text-lg text-ink">Rs. {order.total.toLocaleString()}</p>
                  {order.shipping_fee > 0 && (
                    <p className="font-body text-xs text-graphite">incl. Rs. {order.shipping_fee.toLocaleString()} shipping</p>
                  )}
                </div>
              </div>

              <div className="mt-3 flex flex-wrap items-center gap-4">
                <div className="flex items-center gap-2">
                  <span className="font-body text-sm text-graphite">Payment:</span>
                  <span
                    className={`font-body text-sm ${
                      order.payment_status === "paid" ? "text-olive" : "text-rust"
                    }`}
                  >
                    {order.payment_status}
                  </span>
                  {order.payment_status !== "paid" && (
                    <button
                      onClick={() => markPaid(order.id)}
                      className="font-body text-sm text-ink underline hover:text-brass"
                    >
                      Mark as paid
                    </button>
                  )}
                </div>

                <div className="flex items-center gap-2">
                  <span className="font-body text-sm text-graphite">Fulfillment:</span>
                  <select
                    value={order.fulfillment_status}
                    onChange={(e) => updateFulfillment(order.id, e.target.value)}
                    className="border border-nickel/50 bg-transparent px-2 py-1 font-body text-sm text-ink"
                  >
                    {FULFILLMENT_STEPS.map((s) => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/admin/products/[id]/edit/page.tsx ----
$path = "app/admin/products/[id]/edit/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { supabase } from "@/lib/supabase";
import PresetSelect from "@/components/admin/PresetSelect";
import SeoFields from "@/components/admin/SeoFields";
import {
  ProductSeoInput,
  generateProductDescription,
  generateSeoDescription,
  generateSeoTitle,
  slugify,
  suggestProductName,
} from "@/lib/seo";
import { FINISH_OPTIONS, SIZE_OPTIONS, MATERIAL_OPTIONS, WEIGHT_UNIT_OPTIONS } from "@/lib/constants";
import { weightToGrams } from "@/lib/shipping";

type ExistingImage = { id: string; url: string; sort_order: number; markedForDelete: boolean };
type NewImageFile = { file: File; previewUrl: string };
type VariantRow = {
  id: string | null; // null = new, not yet saved
  finish: string;
  size: string;
  price: string;
  stock: string;
  sku: string;
  markedForDelete: boolean;
};
type SpecRow = { key: string; value: string };

const STORAGE_BUCKET = "product-images";

export default function EditProductPage() {
  const router = useRouter();
  const params = useParams();
  const productId = params.id as string;

  const [loading, setLoading] = useState(true);
  const [categories, setCategories] = useState<any[]>([]);
  const [modelCode, setModelCode] = useState("");
  const [slug, setSlug] = useState("");
  // null = "use the automatic suggestion"; a string = the admin's own wording.
  const [nameOverride, setNameOverride] = useState<string | null>(null);
  const [descOverride, setDescOverride] = useState<string | null>(null);
  const [seoTitleOverride, setSeoTitleOverride] = useState<string | null>(null);
  const [seoDescOverride, setSeoDescOverride] = useState<string | null>(null);
  const [categoryId, setCategoryId] = useState("");
  const [basePrice, setBasePrice] = useState("");
  const [material, setMaterial] = useState("");
  const [weight, setWeight] = useState("");
  const [weightUnit, setWeightUnit] = useState("g");
  const [specs, setSpecs] = useState<SpecRow[]>([]);
  const [existingImages, setExistingImages] = useState<ExistingImage[]>([]);
  const [newImageFiles, setNewImageFiles] = useState<NewImageFile[]>([]);
  const [variants, setVariants] = useState<VariantRow[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [addingCategory, setAddingCategory] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState("");

  // ---- Automatic SEO content, built from whatever is entered above ----
  const categoryName = categories.find((c) => c.id === categoryId)?.name ?? "";
  const liveVariants = variants.filter((v) => !v.markedForDelete);
  const finishes = Array.from(new Set(liveVariants.map((v) => v.finish.trim()).filter(Boolean)));
  const sizes = Array.from(new Set(liveVariants.map((v) => v.size.trim()).filter(Boolean)));
  const prices = liveVariants.map((v) => Number(v.price)).filter((n) => n > 0);
  const holeSpacing = specs.find((s) => /hole/i.test(s.key) && s.value.trim())?.value.trim() ?? "";
  const suggestedName = suggestProductName({ modelCode, categoryName, material, finishes });
  const name = nameOverride ?? suggestedName;
  const seoBase: ProductSeoInput = {
    name,
    modelCode,
    categoryName,
    material,
    weight: weight.trim() ? `${weight.trim()}${weightUnit}` : "",
    holeSpacing,
    finishes,
    sizes,
    minPrice: prices.length ? Math.min(...prices) : Number(basePrice) || null,
  };
  const autoDescription = name ? generateProductDescription(seoBase) : "";
  const description = descOverride ?? autoDescription;
  const autoSeoTitle = name ? generateSeoTitle(seoBase) : "";
  const autoSeoDescription = name ? generateSeoDescription(seoBase) : "";
  const seoTitle = seoTitleOverride ?? autoSeoTitle;
  const seoDescription = seoDescOverride ?? autoSeoDescription;

  useEffect(() => {
    async function load() {
      const [{ data: cats }, { data: product }] = await Promise.all([
        supabase.from("categories").select("*").order("sort_order"),
        supabase
          .from("products")
          .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id, attribute_values(value, attribute_id, attributes(name))))")
          .eq("id", productId)
          .single(),
      ]);

      setCategories(cats ?? []);
      if (!product) {
        setError("Product not found.");
        setLoading(false);
        return;
      }

      setNameOverride(product.name); // keep the existing name until the admin chooses otherwise
      setModelCode(product.model_code ?? "");
      setSlug(product.slug ?? "");
      setCategoryId(product.category_id ?? "");
      setDescOverride(product.description ? product.description : null);
      setSeoTitleOverride(product.seo_title ? product.seo_title : null);
      setSeoDescOverride(product.seo_description ? product.seo_description : null);
      setBasePrice(String(product.base_price ?? ""));

      const specsEntries = Object.entries(product.specs ?? {});
      const materialEntry = specsEntries.find(([k]) => k === "Material");
      const weightEntry = specsEntries.find(([k]) => k === "Weight");
      setMaterial(materialEntry ? String(materialEntry[1]) : "");
      if (weightEntry) {
        const match = String(weightEntry[1]).match(/^([\d.]+)(g|kg)?$/);
        setWeight(match ? match[1] : String(weightEntry[1]));
        setWeightUnit(match?.[2] ?? "g");
      }
      setSpecs(specsEntries.filter(([k]) => k !== "Material" && k !== "Weight").map(([key, value]) => ({ key, value: String(value) })));

      setExistingImages(
        (product.product_images ?? [])
          .sort((a: any, b: any) => a.sort_order - b.sort_order)
          .map((img: any) => ({ id: img.id, url: img.url, sort_order: img.sort_order, markedForDelete: false }))
      );

      setVariants(
        (product.product_variants ?? []).map((v: any) => {
          const finish = v.variant_attribute_values.find((j: any) => j.attribute_values?.attributes?.name === "Finish")?.attribute_values?.value ?? "";
          const size = v.variant_attribute_values.find((j: any) => j.attribute_values?.attributes?.name === "Size")?.attribute_values?.value ?? "";
          return {
            id: v.id,
            finish,
            size,
            price: String(v.price),
            stock: String(v.stock_qty),
            sku: v.sku ?? "",
            markedForDelete: false,
          };
        })
      );

      setLoading(false);
    }
    load();
  }, [productId]);

  function updateVariant(i: number, field: keyof VariantRow, value: string | boolean) {
    setVariants((prev) => prev.map((v, idx) => (idx === i ? { ...v, [field]: value } : v)));
  }

  async function handleAddCategory() {
    if (!newCategoryName.trim()) return;
    const { data, error } = await supabase
      .from("categories")
      .insert({ name: newCategoryName.trim(), slug: slugify(newCategoryName) })
      .select()
      .single();
    if (error) {
      setError(`Could not add category: ${error.message}`);
      return;
    }
    setCategories((prev) => [...prev, data]);
    setCategoryId(data.id);
    setNewCategoryName("");
    setAddingCategory(false);
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    setNewImageFiles((prev) => [...prev, ...files.map((file) => ({ file, previewUrl: URL.createObjectURL(file) }))]);
    e.target.value = "";
  }

  async function findOrCreateAttribute(attrName: string) {
    const { data: existing } = await supabase.from("attributes").select("id").eq("name", attrName).maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase.from("attributes").insert({ name: attrName }).select().single();
    if (error) throw error;
    return created.id;
  }

  async function findOrCreateAttributeValue(attributeId: string, value: string) {
    const { data: existing } = await supabase
      .from("attribute_values")
      .select("id")
      .eq("attribute_id", attributeId)
      .eq("value", value)
      .maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase
      .from("attribute_values")
      .insert({ attribute_id: attributeId, value })
      .select()
      .single();
    if (error) throw error;
    return created.id;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);

    try {
      const specsObject: Record<string, string> = {};
      if (material.trim()) specsObject["Material"] = material.trim();
      if (weight.trim()) specsObject["Weight"] = `${weight.trim()}${weightUnit}`;
      for (const s of specs) {
        if (s.key.trim() && s.value.trim()) specsObject[s.key.trim()] = s.value.trim();
      }

      const { error: updateError } = await supabase
        .from("products")
        .update({
          name: name.trim(),
          // slug is deliberately NOT changed: renaming a product must not break
          // its web address (links, Google rankings, WhatsApp shares).
          model_code: modelCode.trim() || null,
          description,
          seo_title: seoTitleOverride?.trim() || null, // null = keep generating automatically
          seo_description: seoDescOverride?.trim() || null,
          updated_at: new Date().toISOString(),
          category_id: categoryId || null,
          base_price: Number(basePrice) || 0,
          specs: specsObject,
          weight_grams: weightToGrams(weight, weightUnit),
        })
        .eq("id", productId);
      if (updateError) throw updateError;

      // Delete images marked for removal
      const toDelete = existingImages.filter((img) => img.markedForDelete);
      if (toDelete.length > 0) {
        const { error: delError } = await supabase.from("product_images").delete().in("id", toDelete.map((i) => i.id));
        if (delError) throw delError;
      }

      // Upload and insert any newly added photos
      if (newImageFiles.length > 0) {
        const keepCount = existingImages.filter((i) => !i.markedForDelete).length;
        const rows = [];
        for (let i = 0; i < newImageFiles.length; i++) {
          const { file } = newImageFiles[i];
          const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-");
          const path = `${productId}/${Date.now()}-${cleanName}`;
          const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, file);
          if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);
          const { data } = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path);
          rows.push({ product_id: productId, url: data.publicUrl, sort_order: keepCount + i });
        }
        const { error: imgError } = await supabase.from("product_images").insert(rows);
        if (imgError) throw imgError;
      }

      // Delete variants marked for removal
      const variantsToDelete = variants.filter((v) => v.markedForDelete && v.id);
      if (variantsToDelete.length > 0) {
        const { error: delVarError } = await supabase
          .from("product_variants")
          .delete()
          .in("id", variantsToDelete.map((v) => v.id!));
        if (delVarError) throw delVarError;
      }

      const activeVariants = variants.filter((v) => !v.markedForDelete && v.price);
      const usesFinish = activeVariants.some((v) => v.finish.trim());
      const usesSize = activeVariants.some((v) => v.size.trim());
      const finishAttrId = usesFinish ? await findOrCreateAttribute("Finish") : null;
      const sizeAttrId = usesSize ? await findOrCreateAttribute("Size") : null;

      for (const v of activeVariants) {
        let variantId = v.id;

        if (variantId) {
          const { error: updVarError } = await supabase
            .from("product_variants")
            .update({ sku: v.sku || null, price: Number(v.price), stock_qty: Number(v.stock) || 0 })
            .eq("id", variantId);
          if (updVarError) throw updVarError;
          // Clear old attribute links, then re-add — simplest way to keep this in sync
          await supabase.from("variant_attribute_values").delete().eq("variant_id", variantId);
        } else {
          const { data: created, error: createVarError } = await supabase
            .from("product_variants")
            .insert({ product_id: productId, sku: v.sku || null, price: Number(v.price), stock_qty: Number(v.stock) || 0 })
            .select()
            .single();
          if (createVarError) throw createVarError;
          variantId = created.id;
        }

        const links: { variant_id: string; attribute_value_id: string }[] = [];
        if (finishAttrId && v.finish.trim()) {
          const valueId = await findOrCreateAttributeValue(finishAttrId, v.finish.trim());
          links.push({ variant_id: variantId!, attribute_value_id: valueId });
        }
        if (sizeAttrId && v.size.trim()) {
          const valueId = await findOrCreateAttributeValue(sizeAttrId, v.size.trim());
          links.push({ variant_id: variantId!, attribute_value_id: valueId });
        }
        if (links.length > 0) {
          const { error: linkError } = await supabase.from("variant_attribute_values").insert(links);
          if (linkError) throw linkError;
        }
      }

      router.push("/admin/products");
    } catch (err: any) {
      setError(err.message || "Something went wrong saving this product.");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <p className="font-body text-graphite">Loading…</p>;

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Edit product</h1>

      <form onSubmit={handleSubmit} className="mt-8 max-w-2xl space-y-8">
        {error && (
          <div className="border-2 border-rust bg-rust/10 p-4">
            <p className="font-body text-sm font-medium text-rust">Could not save:</p>
            <p className="mt-1 font-body text-sm text-rust">{error}</p>
          </div>
        )}

        <div className="space-y-4">
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Model / product code (e.g. DHB001) — optional</span>
              <input
                value={modelCode}
                onChange={(e) => setModelCode(e.target.value)}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              Your internal code. It is shown on the product page and used in the automatic name below.
            </p>
          </div>
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Product name — what customers and Google see</span>
              <input
                value={name}
                onChange={(e) => setNameOverride(e.target.value === "" ? null : e.target.value)}
                required
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              {suggestedName && suggestedName !== name ? (
                <button type="button" onClick={() => setNameOverride(null)} className="underline hover:text-ink">
                  Use suggested name: {suggestedName}
                </button>
              ) : (
                "Renaming is safe — the product's web address stays the same."
              )}
            </p>
            {slug && (
              <p className="mt-1 font-body text-xs text-graphite">Web address: /products/{slug}</p>
            )}
          </div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Category</span>
            <select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            >
              <option value="">— None —</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
          </label>
          {addingCategory ? (
            <div className="flex gap-2">
              <input
                value={newCategoryName}
                onChange={(e) => setNewCategoryName(e.target.value)}
                placeholder="New category name"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink"
              />
              <button type="button" onClick={handleAddCategory} className="bg-ink px-3 py-2 font-body text-sm text-stone">
                Add
              </button>
              <button type="button" onClick={() => setAddingCategory(false)} className="font-body text-sm text-graphite">
                Cancel
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setAddingCategory(true)}
              className="font-body text-sm text-graphite hover:text-ink"
            >
              + Add a new category
            </button>
          )}
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Description</span>
              <textarea
                value={description}
                onChange={(e) => setDescOverride(e.target.value === "" ? null : e.target.value)}
                rows={8}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              {descOverride === null
                ? "Written automatically from the details you enter (name, material, finishes, sizes, weight). Edit it freely."
                : "Using your own wording."}
              {descOverride !== null && (
                <button type="button" onClick={() => setDescOverride(null)} className="ml-2 underline hover:text-ink">
                  Regenerate from details
                </button>
              )}
            </p>
          </div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Base price (shown on catalog cards)</span>
            <input
              value={basePrice}
              onChange={(e) => setBasePrice(e.target.value)}
              type="number"
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            />
          </label>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">Product photos</p>
          <div className="mt-2 flex flex-wrap gap-3">
            {existingImages.filter((img) => !img.markedForDelete).map((img) => (
              <div key={img.id} className="relative h-24 w-24 border border-nickel/30">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img.url} alt="" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={() =>
                    setExistingImages((prev) => prev.map((i) => (i.id === img.id ? { ...i, markedForDelete: true } : i)))
                  }
                  className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-ink text-xs text-stone"
                  aria-label="Remove image"
                >
                  ×
                </button>
              </div>
            ))}
            {newImageFiles.map((img, i) => (
              <div key={i} className="relative h-24 w-24 border border-nickel/30">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img.previewUrl} alt="" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={() => setNewImageFiles((prev) => prev.filter((_, idx) => idx !== i))}
                  className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-ink text-xs text-stone"
                  aria-label="Remove image"
                >
                  ×
                </button>
              </div>
            ))}
            <label className="flex h-24 w-24 cursor-pointer items-center justify-center border border-dashed border-nickel/50 font-body text-xs text-graphite hover:border-ink hover:text-ink">
              + Add photo
              <input type="file" accept="image/*" multiple onChange={handleFileSelect} className="hidden" />
            </label>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <p className="font-body text-sm text-graphite">Material</p>
            <PresetSelect options={MATERIAL_OPTIONS} value={material} onChange={setMaterial} placeholder="Select material…" />
          </div>
          <div>
            <p className="font-body text-sm text-graphite">Weight</p>
            <div className="flex gap-2">
              <input
                value={weight}
                onChange={(e) => setWeight(e.target.value)}
                type="number"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
              <select
                value={weightUnit}
                onChange={(e) => setWeightUnit(e.target.value)}
                className="border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              >
                {WEIGHT_UNIT_OPTIONS.map((u) => (
                  <option key={u} value={u}>{u}</option>
                ))}
              </select>
            </div>
            <p className="mt-1 font-body text-xs text-graphite/70">
              Also used to calculate the Cash on Delivery shipping fee — see Shipping (COD) in the admin menu.
            </p>
          </div>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">
            Variants — check "Remove" to delete one, or add a new row for a new combination.
          </p>
          <div className="mt-3 space-y-3">
            {variants.map((v, i) => (
              <div key={i} className={`grid grid-cols-2 gap-2 border p-3 sm:grid-cols-6 ${v.markedForDelete ? "border-rust/40 opacity-50" : "border-nickel/20"}`}>
                <PresetSelect options={FINISH_OPTIONS} value={v.finish} onChange={(val) => updateVariant(i, "finish", val)} placeholder="Finish" />
                <PresetSelect options={SIZE_OPTIONS} value={v.size} onChange={(val) => updateVariant(i, "size", val)} placeholder="Size" />
                <input
                  value={v.price}
                  onChange={(e) => updateVariant(i, "price", e.target.value)}
                  placeholder="Price"
                  type="number"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.stock}
                  onChange={(e) => updateVariant(i, "stock", e.target.value)}
                  placeholder="Stock"
                  type="number"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.sku}
                  onChange={(e) => updateVariant(i, "sku", e.target.value)}
                  placeholder="SKU"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <button
                  type="button"
                  onClick={() => updateVariant(i, "markedForDelete", !v.markedForDelete)}
                  className="font-body text-xs text-graphite hover:text-rust"
                >
                  {v.markedForDelete ? "Undo" : "Remove"}
                </button>
              </div>
            ))}
          </div>
          <button
            type="button"
            onClick={() =>
              setVariants((prev) => [...prev, { id: null, finish: "", size: "", price: "", stock: "", sku: "", markedForDelete: false }])
            }
            className="mt-2 font-body text-sm text-graphite hover:text-ink"
          >
            + Add another variant
          </button>
        </div>

        <SeoFields
          urlPreview={`www.siqbalhwc.com › products › ${slug || slugify(name) || "your-product"}`}
          title={seoTitle}
          description={seoDescription}
          titleIsAuto={seoTitleOverride === null}
          descriptionIsAuto={seoDescOverride === null}
          onTitleChange={(v) => setSeoTitleOverride(v === "" ? null : v)}
          onDescriptionChange={(v) => setSeoDescOverride(v === "" ? null : v)}
          onResetTitle={() => setSeoTitleOverride(null)}
          onResetDescription={() => setSeoDescOverride(null)}
        />

        <button
          type="submit"
          disabled={saving}
          className="bg-ink px-6 py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
        >
          {saving ? "Saving…" : "Save changes"}
        </button>
      </form>
    </div>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/admin/products/new/page.tsx ----
$path = "app/admin/products/new/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import PresetSelect from "@/components/admin/PresetSelect";
import SeoFields from "@/components/admin/SeoFields";
import {
  ProductSeoInput,
  generateProductDescription,
  generateSeoDescription,
  generateSeoTitle,
  suggestProductName,
} from "@/lib/seo";
import { FINISH_OPTIONS, SIZE_OPTIONS, MATERIAL_OPTIONS, WEIGHT_UNIT_OPTIONS } from "@/lib/constants";
import { weightToGrams } from "@/lib/shipping";

type VariantRow = { finish: string; size: string; price: string; stock: string; sku: string };
type SpecRow = { key: string; value: string };
type ImageFile = { file: File; previewUrl: string };

const STORAGE_BUCKET = "product-images";

function slugify(text: string) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
}

export default function NewProductPage() {
  const router = useRouter();
  const [categories, setCategories] = useState<any[]>([]);
  const [modelCode, setModelCode] = useState("");
  // null = "use the automatic suggestion"; a string = the admin typed their own.
  const [nameOverride, setNameOverride] = useState<string | null>(null);
  const [descOverride, setDescOverride] = useState<string | null>(null);
  const [seoTitleOverride, setSeoTitleOverride] = useState<string | null>(null);
  const [seoDescOverride, setSeoDescOverride] = useState<string | null>(null);
  const [categoryId, setCategoryId] = useState("");
  const [basePrice, setBasePrice] = useState("");
  const [imageFiles, setImageFiles] = useState<ImageFile[]>([]);
  const [material, setMaterial] = useState("");
  const [weight, setWeight] = useState("");
  const [weightUnit, setWeightUnit] = useState("g");
  const [specs, setSpecs] = useState<SpecRow[]>([]);
  const [addingCategory, setAddingCategory] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState("");
  const [variants, setVariants] = useState<VariantRow[]>([
    { finish: "", size: "", price: "", stock: "", sku: "" },
  ]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ---- Automatic SEO content, built from whatever the admin has entered ----
  const categoryName = categories.find((c) => c.id === categoryId)?.name ?? "";
  const finishes = Array.from(new Set(variants.map((v) => v.finish.trim()).filter(Boolean)));
  const sizes = Array.from(new Set(variants.map((v) => v.size.trim()).filter(Boolean)));
  const prices = variants.map((v) => Number(v.price)).filter((n) => n > 0);
  const holeSpacing = specs.find((s) => /hole/i.test(s.key) && s.value.trim())?.value.trim() ?? "";
  const suggestedName = suggestProductName({ modelCode, categoryName, material, finishes });
  const name = nameOverride ?? suggestedName;
  const seoBase: ProductSeoInput = {
    name,
    modelCode,
    categoryName,
    material,
    weight: weight.trim() ? `${weight.trim()}${weightUnit}` : "",
    holeSpacing,
    finishes,
    sizes,
    minPrice: prices.length ? Math.min(...prices) : Number(basePrice) || null,
  };
  const autoDescription = name ? generateProductDescription(seoBase) : "";
  const description = descOverride ?? autoDescription;
  const autoSeoTitle = name ? generateSeoTitle(seoBase) : "";
  const autoSeoDescription = name ? generateSeoDescription(seoBase) : "";
  const seoTitle = seoTitleOverride ?? autoSeoTitle;
  const seoDescription = seoDescOverride ?? autoSeoDescription;

  useEffect(() => {
    supabase.from("categories").select("*").order("sort_order").then(({ data }) => setCategories(data ?? []));
  }, []);

  async function handleAddCategory() {
    if (!newCategoryName.trim()) return;
    const { data, error } = await supabase
      .from("categories")
      .insert({ name: newCategoryName.trim(), slug: slugify(newCategoryName) })
      .select()
      .single();
    if (error) {
      setError(`Could not add category: ${error.message}`);
      return;
    }
    setCategories((prev) => [...prev, data]);
    setCategoryId(data.id);
    setNewCategoryName("");
    setAddingCategory(false);
  }

  function updateVariant(i: number, field: keyof VariantRow, value: string) {
    setVariants((prev) => prev.map((v, idx) => (idx === i ? { ...v, [field]: value } : v)));
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    const newImages = files.map((file) => ({ file, previewUrl: URL.createObjectURL(file) }));
    setImageFiles((prev) => [...prev, ...newImages]);
    e.target.value = ""; // allow selecting the same file again if removed and re-added
  }

  function removeImage(index: number) {
    setImageFiles((prev) => {
      URL.revokeObjectURL(prev[index].previewUrl);
      return prev.filter((_, i) => i !== index);
    });
  }

  async function uploadImages(productId: string) {
    const uploaded: { url: string; sort_order: number }[] = [];
    for (let i = 0; i < imageFiles.length; i++) {
      const { file } = imageFiles[i];
      const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-");
      const path = `${productId}/${Date.now()}-${cleanName}`;

      const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, file);
      if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);

      const { data } = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path);
      uploaded.push({ url: data.publicUrl, sort_order: i });
    }
    return uploaded;
  }

  async function findOrCreateAttribute(attrName: string) {
    const { data: existing } = await supabase.from("attributes").select("id").eq("name", attrName).maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase.from("attributes").insert({ name: attrName }).select().single();
    if (error) throw error;
    return created.id;
  }

  async function findOrCreateAttributeValue(attributeId: string, value: string) {
    const { data: existing } = await supabase
      .from("attribute_values")
      .select("id")
      .eq("attribute_id", attributeId)
      .eq("value", value)
      .maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase
      .from("attribute_values")
      .insert({ attribute_id: attributeId, value })
      .select()
      .single();
    if (error) throw error;
    return created.id;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);

    try {
      const specsObject: Record<string, string> = {};
      if (material.trim()) specsObject["Material"] = material.trim();
      if (weight.trim()) specsObject["Weight"] = `${weight.trim()}${weightUnit}`;
      for (const s of specs) {
        if (s.key.trim() && s.value.trim()) specsObject[s.key.trim()] = s.value.trim();
      }

      const { data: product, error: productError } = await supabase
        .from("products")
        .insert({
          name: name.trim(),
          slug: slugify(name),
          model_code: modelCode.trim() || null,
          description,
          seo_title: seoTitleOverride?.trim() || null, // null = keep generating automatically
          seo_description: seoDescOverride?.trim() || null,
          category_id: categoryId || null,
          base_price: Number(basePrice) || 0,
          specs: specsObject,
          weight_grams: weightToGrams(weight, weightUnit),
        })
        .select()
        .single();

      if (productError) throw productError;

      if (imageFiles.length > 0) {
        const uploaded = await uploadImages(product.id);
        const imageRows = uploaded.map((img) => ({
          product_id: product.id,
          url: img.url,
          sort_order: img.sort_order,
        }));
        const { error: imgError } = await supabase.from("product_images").insert(imageRows);
        if (imgError) throw imgError;
      }

      // Only create attributes for the ones actually used, so a product
      // with just one finish and no sizing doesn't get an empty "Size" attribute.
      const usesFinish = variants.some((v) => v.finish.trim());
      const usesSize = variants.some((v) => v.size.trim());
      const finishAttrId = usesFinish ? await findOrCreateAttribute("Finish") : null;
      const sizeAttrId = usesSize ? await findOrCreateAttribute("Size") : null;

      for (const v of variants) {
        if (!v.price) continue;
        const { data: variant, error: variantError } = await supabase
          .from("product_variants")
          .insert({
            product_id: product.id,
            sku: v.sku || null,
            price: Number(v.price),
            stock_qty: Number(v.stock) || 0,
          })
          .select()
          .single();
        if (variantError) throw variantError;

        const links: { variant_id: string; attribute_value_id: string }[] = [];
        if (finishAttrId && v.finish.trim()) {
          const valueId = await findOrCreateAttributeValue(finishAttrId, v.finish.trim());
          links.push({ variant_id: variant.id, attribute_value_id: valueId });
        }
        if (sizeAttrId && v.size.trim()) {
          const valueId = await findOrCreateAttributeValue(sizeAttrId, v.size.trim());
          links.push({ variant_id: variant.id, attribute_value_id: valueId });
        }
        if (links.length > 0) {
          const { error: linkError } = await supabase.from("variant_attribute_values").insert(links);
          if (linkError) throw linkError;
        }
      }

      router.push("/admin/products");
    } catch (err: any) {
      setError(err.message || "Something went wrong saving this product.");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Add product</h1>

      <form onSubmit={handleSubmit} className="mt-8 max-w-2xl space-y-8">
        <div className="space-y-4">
          <div>
            <LabeledInput
              label="Model / product code (e.g. DHB001) — optional"
              value={modelCode}
              onChange={setModelCode}
            />
            <p className="mt-1 font-body text-xs text-graphite">
              Your internal code. It is shown on the product page and used in the automatic name below.
            </p>
          </div>
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Product name — what customers and Google see</span>
              <input
                value={name}
                onChange={(e) => setNameOverride(e.target.value === "" ? null : e.target.value)}
                required
                placeholder="Pick a category and add a model code — the name is suggested for you"
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              {nameOverride === null
                ? "Suggested automatically from category, material and model code. Type to use your own wording."
                : "Using your own wording."}
              {nameOverride !== null && suggestedName && (
                <button type="button" onClick={() => setNameOverride(null)} className="ml-2 underline hover:text-ink">
                  Use suggested name: {suggestedName}
                </button>
              )}
            </p>
          </div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Category</span>
            <select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            >
              <option value="">— None —</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
            {categories.length === 0 && (
              <p className="mt-1 font-body text-xs text-graphite">
                No categories yet — add your first one below.
              </p>
            )}
          </label>
          {addingCategory ? (
            <div className="flex gap-2">
              <input
                value={newCategoryName}
                onChange={(e) => setNewCategoryName(e.target.value)}
                placeholder="New category name"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink"
              />
              <button type="button" onClick={handleAddCategory} className="bg-ink px-3 py-2 font-body text-sm text-stone">
                Add
              </button>
              <button type="button" onClick={() => setAddingCategory(false)} className="font-body text-sm text-graphite">
                Cancel
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setAddingCategory(true)}
              className="font-body text-sm text-graphite hover:text-ink"
            >
              + Add a new category
            </button>
          )}
          <div>
            <label className="block">
              <span className="font-body text-sm text-graphite">Description</span>
              <textarea
                value={description}
                onChange={(e) => setDescOverride(e.target.value === "" ? null : e.target.value)}
                rows={8}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
            </label>
            <p className="mt-1 font-body text-xs text-graphite">
              {descOverride === null
                ? "Written automatically from the details you enter (name, material, finishes, sizes, weight). Edit it freely."
                : "Using your own wording."}
              {descOverride !== null && (
                <button type="button" onClick={() => setDescOverride(null)} className="ml-2 underline hover:text-ink">
                  Regenerate from details
                </button>
              )}
            </p>
          </div>
          <LabeledInput
            label="Base price (shown on catalog cards)"
            value={basePrice}
            onChange={setBasePrice}
            type="number"
          />
        </div>

        <div>
          <p className="font-body text-sm text-graphite">Product photos</p>
          <div className="mt-2 flex flex-wrap gap-3">
            {imageFiles.map((img, i) => (
              <div key={i} className="relative h-24 w-24 border border-nickel/30">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img.previewUrl} alt="" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={() => removeImage(i)}
                  className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-ink text-xs text-stone"
                  aria-label="Remove image"
                >
                  ×
                </button>
              </div>
            ))}
            <label className="flex h-24 w-24 cursor-pointer items-center justify-center border border-dashed border-nickel/50 font-body text-xs text-graphite hover:border-ink hover:text-ink">
              + Add photo
              <input type="file" accept="image/*" multiple onChange={handleFileSelect} className="hidden" />
            </label>
          </div>
          <p className="mt-2 font-body text-xs text-graphite">
            Upload from your computer — the first photo becomes the main image shown on the catalog.
          </p>
        </div>

        <div className="space-y-4">
          <div>
            <p className="font-body text-sm text-graphite">Material</p>
            <PresetSelect options={MATERIAL_OPTIONS} value={material} onChange={setMaterial} placeholder="Select material…" />
          </div>
          <div>
            <p className="font-body text-sm text-graphite">Weight</p>
            <div className="flex gap-2">
              <input
                value={weight}
                onChange={(e) => setWeight(e.target.value)}
                type="number"
                placeholder="e.g. 85"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
              <select
                value={weightUnit}
                onChange={(e) => setWeightUnit(e.target.value)}
                className="border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              >
                {WEIGHT_UNIT_OPTIONS.map((u) => (
                  <option key={u} value={u}>{u}</option>
                ))}
              </select>
            </div>
            <p className="mt-1 font-body text-xs text-graphite/70">
              Also used to calculate the Cash on Delivery shipping fee — see Shipping (COD) in the admin menu.
            </p>
          </div>

          <div>
            <p className="font-body text-sm text-graphite">Other specs (optional)</p>
            {specs.map((spec, i) => (
              <div key={i} className="mt-2 flex gap-2">
                <input
                  value={spec.key}
                  onChange={(e) =>
                    setSpecs((prev) => prev.map((s, idx) => (idx === i ? { ...s, key: e.target.value } : s)))
                  }
                  placeholder="Spec name (e.g. Hole spacing)"
                  className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
                />
                <input
                  value={spec.value}
                  onChange={(e) =>
                    setSpecs((prev) => prev.map((s, idx) => (idx === i ? { ...s, value: e.target.value } : s)))
                  }
                  placeholder="Value"
                  className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
                />
              </div>
            ))}
            <button
              type="button"
              onClick={() => setSpecs((prev) => [...prev, { key: "", value: "" }])}
              className="mt-2 font-body text-sm text-graphite hover:text-ink"
            >
              + Add another spec
            </button>
          </div>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">
            Variants — each row is one buyable combination. Leave Size blank if this product doesn't vary by size.
          </p>
          <div className="mt-3 space-y-3">
            {variants.map((v, i) => (
              <div key={i} className="grid grid-cols-2 gap-2 border border-nickel/20 p-3 sm:grid-cols-5">
                <PresetSelect
                  options={FINISH_OPTIONS}
                  value={v.finish}
                  onChange={(val) => updateVariant(i, "finish", val)}
                  placeholder="Finish"
                />
                <PresetSelect
                  options={SIZE_OPTIONS}
                  value={v.size}
                  onChange={(val) => updateVariant(i, "size", val)}
                  placeholder="Size"
                />
                <input
                  value={v.price}
                  onChange={(e) => updateVariant(i, "price", e.target.value)}
                  placeholder="Price"
                  type="number"
                  required
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.stock}
                  onChange={(e) => updateVariant(i, "stock", e.target.value)}
                  placeholder="Stock qty"
                  type="number"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.sku}
                  onChange={(e) => updateVariant(i, "sku", e.target.value)}
                  placeholder="SKU (optional)"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
              </div>
            ))}
          </div>
          <button
            type="button"
            onClick={() =>
              setVariants((prev) => [...prev, { finish: "", size: "", price: "", stock: "", sku: "" }])
            }
            className="mt-2 font-body text-sm text-graphite hover:text-ink"
          >
            + Add another variant
          </button>
        </div>

        <SeoFields
          urlPreview={`www.siqbalhwc.com › products › ${slugify(name) || "your-product"}`}
          title={seoTitle}
          description={seoDescription}
          titleIsAuto={seoTitleOverride === null}
          descriptionIsAuto={seoDescOverride === null}
          onTitleChange={(v) => setSeoTitleOverride(v === "" ? null : v)}
          onDescriptionChange={(v) => setSeoDescOverride(v === "" ? null : v)}
          onResetTitle={() => setSeoTitleOverride(null)}
          onResetDescription={() => setSeoDescOverride(null)}
        />

        {error && (
          <div className="border-2 border-rust bg-rust/10 p-4">
            <p className="font-body text-sm font-medium text-rust">Could not save this product:</p>
            <p className="mt-1 font-body text-sm text-rust">{error}</p>
          </div>
        )}

        <button
          type="submit"
          disabled={saving}
          className="bg-ink px-6 py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
        >
          {saving ? "Saving…" : "Save product"}
        </button>
      </form>
    </div>
  );
}

function LabeledInput({
  label,
  value,
  onChange,
  type = "text",
  required = false,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
  required?: boolean;
}) {
  return (
    <label className="block">
      <span className="font-body text-sm text-graphite">{label}</span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        type={type}
        required={required}
        className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
      />
    </label>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/api/orders/create/route.ts ----
$path = "app/api/orders/create/route.ts"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
import { NextResponse } from "next/server";
import { getServiceClient } from "@/lib/supabase";
import { calculateShippingFee, DEFAULT_SHIPPING_SETTINGS, FALLBACK_ITEM_WEIGHT_GRAMS } from "@/lib/shipping";

type IncomingLine = {
  variantId: string;
  quantity: number;
};

export async function POST(request: Request) {
  const body = await request.json();
  const { customerName, email, phone, shippingAddress, lines, paymentMethod } = body as {
    customerName: string;
    email: string;
    phone: string;
    shippingAddress: Record<string, string>;
    lines: IncomingLine[];
    paymentMethod?: "bank_transfer" | "cod";
  };

  if (!customerName || !email || !lines?.length) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  // Only two payment methods are wired up on the storefront today — never
  // trust a value the browser sends beyond that.
  const safePaymentMethod = paymentMethod === "cod" ? "cod" : "bank_transfer";

  const supabase = getServiceClient();

  // Re-fetch each variant server-side — never trust the price/stock the
  // browser sends, since that's easy to tamper with in devtools. Also pulls
  // the product's shipping weight, needed for the COD/shipping fee below.
  const variantIds = lines.map((l) => l.variantId);
  const { data: variants, error: variantError } = await supabase
    .from("product_variants")
    .select(
      "id, price, stock_qty, product_id, products(name, weight_grams), variant_attribute_values(attribute_value_id, attribute_values(value))"
    )
    .in("id", variantIds);

  if (variantError || !variants) {
    return NextResponse.json({ error: "Could not verify products" }, { status: 500 });
  }

  const orderItems = [];
  let subtotal = 0;
  let totalWeightGrams = 0;

  for (const line of lines) {
    const variant = variants.find((v: any) => v.id === line.variantId);
    if (!variant) {
      return NextResponse.json({ error: "One of the items is no longer available" }, { status: 400 });
    }
    if (variant.stock_qty < line.quantity) {
      return NextResponse.json(
        { error: `Not enough stock for one of the items. Only ${variant.stock_qty} left.` },
        { status: 400 }
      );
    }

    const variantLabel = (variant as any).variant_attribute_values
      .map((j: any) => j.attribute_values?.value)
      .filter(Boolean)
      .join(" / ");

    const lineTotal = variant.price * line.quantity;
    subtotal += lineTotal;

    const itemWeight = (variant as any).products?.weight_grams || FALLBACK_ITEM_WEIGHT_GRAMS;
    totalWeightGrams += itemWeight * line.quantity;

    orderItems.push({
      product_id: variant.product_id,
      variant_id: variant.id,
      product_name: (variant as any).products?.name ?? "Product",
      variant_label: variantLabel,
      quantity: line.quantity,
      unit_price: variant.price,
    });
  }

  // Weight-based shipping fee, charged either way: collected by the courier
  // on delivery for COD, or added to the bank-transfer total.
  const { data: shippingSettingsRow } = await supabase.from("shipping_settings").select("*").single();
  const shippingSettings = shippingSettingsRow ?? DEFAULT_SHIPPING_SETTINGS;
  const shippingFee = calculateShippingFee(totalWeightGrams, shippingSettings);
  const total = subtotal + shippingFee;

  // Create the order
  const { data: order, error: orderError } = await supabase
    .from("orders")
    .insert({
      customer_name: customerName,
      email,
      phone,
      shipping_address: shippingAddress,
      subtotal,
      shipping_fee: shippingFee,
      total,
      payment_method: safePaymentMethod,
    })
    .select()
    .single();

  if (orderError || !order) {
    return NextResponse.json({ error: "Could not create the order" }, { status: 500 });
  }

  // Attach order_id now that we have it, then insert items
  const { error: itemsError } = await supabase
    .from("order_items")
    .insert(orderItems.map((item) => ({ ...item, order_id: order.id })));

  if (itemsError) {
    return NextResponse.json({ error: "Could not save order items" }, { status: 500 });
  }

  // Decrement stock for each variant
  for (const line of lines) {
    const variant = variants.find((v: any) => v.id === line.variantId)!;
    await supabase
      .from("product_variants")
      .update({ stock_qty: variant.stock_qty - line.quantity })
      .eq("id", line.variantId);
  }

  const base = {
    orderNumber: order.order_number,
    subtotal: order.subtotal,
    shippingFee: order.shipping_fee,
    total: order.total,
    paymentMethod: safePaymentMethod,
  };

  if (safePaymentMethod === "cod") {
    return NextResponse.json({
      ...base,
      courierName: shippingSettings.courier_name ?? "the courier",
    });
  }

  const { data: bankAccounts } = await supabase
    .from("bank_accounts")
    .select("id, bank_name, account_title, account_number, ifsc_or_routing, sort_order, active")
    .eq("active", true)
    .order("sort_order");

  const { data: bankSettings } = await supabase.from("bank_settings").select("instructions").single();

  return NextResponse.json({
    ...base,
    bankAccounts: bankAccounts ?? [],
    instructions: bankSettings?.instructions ?? "Please use your Order Number as the payment reference.",
  });
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/checkout/page.tsx ----
$path = "app/checkout/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useState } from "react";
import Link from "next/link";
import { useCart } from "@/lib/cart-context";
import { BankAccount } from "@/lib/types";

export default function CheckoutPage() {
  const { lines, subtotal, clear } = useCart();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<"bank_transfer" | "cod">("bank_transfer");
  const [confirmation, setConfirmation] = useState<{
    orderNumber: string;
    subtotal: number;
    shippingFee: number;
    total: number;
    paymentMethod: "bank_transfer" | "cod";
    bankAccounts?: BankAccount[];
    instructions?: string;
    courierName?: string;
  } | null>(null);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    const form = new FormData(e.currentTarget);
    const payload = {
      customerName: form.get("customerName"),
      email: form.get("email"),
      phone: form.get("phone"),
      shippingAddress: {
        line1: form.get("line1"),
        line2: form.get("line2"),
        city: form.get("city"),
        region: form.get("region"),
        postal_code: form.get("postal_code"),
        country: form.get("country"),
      },
      lines: lines.map((l) => ({ variantId: l.variantId, quantity: l.quantity })),
      paymentMethod,
    };

    try {
      const res = await fetch("/api/orders/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Something went wrong placing your order.");
        return;
      }

      setConfirmation(data);
      clear();
    } catch {
      setError("Could not reach the server. Check your connection and try again.");
    } finally {
      setSubmitting(false);
    }
  }

  if (confirmation) {
    return (
      <div className="mx-auto max-w-xl px-6 py-20">
        <p className="font-body text-sm text-olive">Order placed</p>
        <h1 className="mt-2 font-display text-4xl text-ink">Thank you</h1>
        <p className="mt-3 font-body text-graphite">
          Your order number is <span className="text-ink">{confirmation.orderNumber}</span>. Save
          this to track your order later.
        </p>

        <div className="mt-8 space-y-4">
          <div className="border-t border-nickel/20 pt-4">
            <Row label="Products" value={`Rs. ${confirmation.subtotal.toLocaleString()}`} />
            <Row label="Shipping" value={`Rs. ${confirmation.shippingFee.toLocaleString()}`} />
            <div className="mt-2 border-t border-nickel/20 pt-2">
              <Row label="Total" value={`Rs. ${confirmation.total.toLocaleString()}`} />
            </div>
          </div>

          {confirmation.paymentMethod === "cod" ? (
            <div className="border border-nickel/30 p-6">
              <p className="font-display text-lg text-ink">Cash on Delivery</p>
              <p className="mt-2 font-body text-sm text-graphite">
                Your order will be dispatched via {confirmation.courierName}. Have{" "}
                <span className="text-ink">Rs. {confirmation.total.toLocaleString()}</span> ready
                to pay the rider in cash on delivery — this already includes the weight-based
                shipping charge, so there&rsquo;s nothing extra to pay.
              </p>
            </div>
          ) : (
            <>
              <p className="font-body text-sm text-graphite">
                Complete your payment by bank transfer to any one of the accounts below
              </p>
              {(confirmation.bankAccounts?.length ?? 0) === 0 ? (
                <p className="border border-nickel/30 p-6 font-body text-sm text-rust">
                  No bank account is set up yet — contact us on WhatsApp to arrange payment for
                  this order.
                </p>
              ) : (
                confirmation.bankAccounts!.map((acc) => (
                  <div key={acc.id} className="border border-nickel/30 p-6">
                    <p className="font-display text-lg text-ink">{acc.bank_name}</p>
                    <dl className="mt-3 space-y-2 font-body text-sm">
                      <Row label="Account title" value={acc.account_title} />
                      <Row label="Account number" value={acc.account_number} />
                      {acc.ifsc_or_routing && <Row label="IBAN / Routing" value={acc.ifsc_or_routing} />}
                    </dl>
                  </div>
                ))
              )}
              <p className="font-body text-sm text-graphite">{confirmation.instructions}</p>
            </>
          )}
        </div>

        <Link
          href={`/track-order?orderNumber=${confirmation.orderNumber}`}
          className="mt-8 block bg-ink py-3 text-center font-body text-sm text-stone hover:bg-brass"
        >
          Track this order
        </Link>
      </div>
    );
  }

  if (lines.length === 0) {
    return (
      <div className="mx-auto max-w-xl px-6 py-24 text-center">
        <p className="font-body text-graphite">Your cart is empty.</p>
        <Link href="/shop" className="mt-4 inline-block font-body text-sm text-ink underline">
          Continue shopping
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Checkout</h1>

      <form onSubmit={handleSubmit} className="mt-8 grid gap-8 md:grid-cols-2">
        <div className="space-y-4">
          <h2 className="font-body text-sm text-graphite">Contact & shipping</h2>
          <Field name="customerName" label="Full name" required />
          <Field name="email" label="Email" type="email" required />
          <Field name="phone" label="Phone" required />
          <Field name="line1" label="Address line 1" required />
          <Field name="line2" label="Address line 2" />
          <div className="grid grid-cols-2 gap-4">
            <Field name="city" label="City" required />
            <Field name="region" label="Province/State" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Field name="postal_code" label="Postal code" />
            <Field name="country" label="Country" required />
          </div>
        </div>

        <div>
          <h2 className="font-body text-sm text-graphite">Order summary</h2>
          <div className="mt-4 divide-y divide-nickel/20 border-y border-nickel/20">
            {lines.map((line) => (
              <div key={line.variantId} className="flex justify-between py-3 font-body text-sm">
                <span className="text-ink">
                  {line.productName} <span className="text-graphite">× {line.quantity}</span>
                </span>
                <span className="text-ink">Rs. {(line.unitPrice * line.quantity).toLocaleString()}</span>
              </div>
            ))}
          </div>
          <div className="mt-4 flex justify-between font-body">
            <span className="text-graphite">Products</span>
            <span className="text-ink">Rs. {subtotal.toLocaleString()}</span>
          </div>
          <p className="mt-1 font-body text-xs text-graphite">
            Shipping is calculated by weight and shown on the next screen once your order is
            placed.
          </p>

          <div className="mt-6">
            <p className="font-body text-sm text-graphite">Payment method</p>
            <div className="mt-2 space-y-2">
              <PaymentOption
                value="bank_transfer"
                selected={paymentMethod === "bank_transfer"}
                onSelect={() => setPaymentMethod("bank_transfer")}
                title="Bank transfer"
                description="Pay the full amount (products + shipping) by bank transfer. Account details shown after you place the order."
              />
              <PaymentOption
                value="cod"
                selected={paymentMethod === "cod"}
                onSelect={() => setPaymentMethod("cod")}
                title="Cash on Delivery — Leopard Courier"
                description="Pay the rider in cash when your order arrives. Includes the weight-based shipping charge."
              />
            </div>
          </div>

          {error && <p className="mt-4 font-body text-sm text-rust">{error}</p>}

          <button
            type="submit"
            disabled={submitting}
            className="mt-6 w-full bg-ink py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
          >
            {submitting ? "Placing order…" : "Place order"}
          </button>
        </div>
      </form>
    </div>
  );
}

function Field({
  name,
  label,
  type = "text",
  required = false,
}: {
  name: string;
  label: string;
  type?: string;
  required?: boolean;
}) {
  return (
    <label className="block">
      <span className="font-body text-sm text-graphite">{label}</span>
      <input
        name={name}
        type={type}
        required={required}
        className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink focus:border-ink"
      />
    </label>
  );
}

function PaymentOption({
  value,
  selected,
  onSelect,
  title,
  description,
}: {
  value: string;
  selected: boolean;
  onSelect: () => void;
  title: string;
  description: string;
}) {
  return (
    <label
      className={`flex cursor-pointer items-start gap-3 border p-3 font-body text-sm ${
        selected ? "border-ink" : "border-nickel/40"
      }`}
    >
      <input
        type="radio"
        name="paymentMethodChoice"
        value={value}
        checked={selected}
        onChange={onSelect}
        className="mt-1"
      />
      <span>
        <span className="block text-ink">{title}</span>
        <span className="block text-xs text-graphite">{description}</span>
      </span>
    </label>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <dt className="text-graphite">{label}</dt>
      <dd className="text-ink">{value}</dd>
    </div>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/page.tsx ----
$path = "app/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
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

  return (
    <>
      {/* Hero */}
      <section className="bg-stone-50">
        <div className="mx-auto max-w-[1500px] px-3 pt-6">
        <div className="grid gap-10 rounded-2xl bg-blacknickel px-8 py-12 text-stone shadow-lg md:grid-cols-2 md:items-center md:px-12 md:py-16">
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

          {/* Finish swatches — a literal, materials-first hero element */}
          <div className="grid grid-cols-3 gap-4">
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
        <section className="mx-auto max-w-[1500px] px-3 py-10">
          <Reveal>
            <h2 className="font-display text-3xl text-ink">Shop by category</h2>
          </Reveal>
          <div className="mt-5 grid gap-6 sm:grid-cols-2 md:grid-cols-4">
            {categories.map((cat, i) => (
              <Reveal key={cat.id} delay={i * 60}>
                <Link
                  href={`/${cat.slug}`}
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
        <section className="mx-auto max-w-[1500px] px-3 py-10">
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
      <section className="border-y border-nickel/20 bg-[#F5F1EA] py-16">
        <div className="mx-auto max-w-[1500px] px-3">
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
                <div className="group h-full rounded-lg border border-nickel/30 bg-white px-6 py-6 shadow-sm transition-all duration-300 hover:-translate-y-0.5 hover:border-brass hover:shadow-md">
                  <span className="flex h-12 w-12 items-center justify-center rounded-full bg-brass text-stone shadow-sm">
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
        <section className="mx-auto max-w-[1500px] px-3 py-10">
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
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/shop/page.tsx ----
$path = "app/shop/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
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
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/sitemap.ts ----
$path = "app/sitemap.ts"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
import { MetadataRoute } from "next";
import { supabase } from "@/lib/supabase";
import { SITE_URL } from "@/lib/seo";

// Rebuilt at most once an hour, so new products and guides reach Google without a redeploy.
export const revalidate = 3600;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [{ data: products }, { data: categories }, { data: posts }] = await Promise.all([
    supabase.from("products").select("slug, updated_at").eq("status", "active"),
    supabase.from("categories").select("slug"),
    supabase.from("blog_posts").select("slug, updated_at, published_at").eq("published", true),
  ]);

  // Only pages that should appear in Google. Utility pages (track-order, cart,
  // checkout) are marked noindex, so they are deliberately left out.
  const staticPages: MetadataRoute.Sitemap = [
    { url: SITE_URL, changeFrequency: "daily", priority: 1 },
    { url: `${SITE_URL}/shop`, changeFrequency: "daily", priority: 0.9 },
    { url: `${SITE_URL}/blog`, changeFrequency: "weekly", priority: 0.8 },
    { url: `${SITE_URL}/about`, changeFrequency: "monthly", priority: 0.5 },
    { url: `${SITE_URL}/contact`, changeFrequency: "monthly", priority: 0.5 },
    { url: `${SITE_URL}/shipping`, changeFrequency: "monthly", priority: 0.3 },
    { url: `${SITE_URL}/returns`, changeFrequency: "monthly", priority: 0.3 },
    { url: `${SITE_URL}/privacy`, changeFrequency: "yearly", priority: 0.2 },
    { url: `${SITE_URL}/terms`, changeFrequency: "yearly", priority: 0.2 },
  ];

  const categoryPages: MetadataRoute.Sitemap = (categories ?? []).map((c) => ({
    url: `${SITE_URL}/${c.slug}`,
    changeFrequency: "weekly",
    priority: 0.7,
  }));

  const productPages: MetadataRoute.Sitemap = (products ?? []).map((p) => ({
    url: `${SITE_URL}/products/${p.slug}`,
    lastModified: p.updated_at ? new Date(p.updated_at) : undefined,
    changeFrequency: "weekly",
    priority: 0.8,
  }));

  const blogPages: MetadataRoute.Sitemap = (posts ?? []).map((p) => ({
    url: `${SITE_URL}/blog/${p.slug}`,
    lastModified: new Date(p.updated_at || p.published_at || Date.now()),
    changeFrequency: "monthly",
    priority: 0.7,
  }));

  return [...staticPages, ...categoryPages, ...blogPages, ...productPages];
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- components/Footer.tsx ----
$path = "components/Footer.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
import Link from "next/link";

export default function Footer({ categories = [] }: { categories?: { name: string; slug: string }[] }) {
  return (
    <footer className="px-3 pb-6 pt-16">
      <div className="mx-auto max-w-[1500px] rounded-2xl bg-blacknickel px-8 py-14 text-stone shadow-lg md:px-12">
        <div className="grid gap-10 sm:grid-cols-2 md:grid-cols-4">
          <div>
            <div className="flex items-center gap-3">
              <img src="/logo.png?v=3" alt="Shahid Iqbal & Co logo" className="h-10 w-10" />
              <p className="font-display text-xl">Shahid Iqbal &amp; Co</p>
            </div>
            <p className="mt-3 max-w-prose font-body text-sm text-stone/70">
              Dream Hardware at your Door Step — door handles, cabinet
              handles, knobs, and furniture pulls, specialized in brass.
            </p>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Shop</p>
            <ul className="space-y-2">
              <li><Link href="/shop" className="hover:text-brass">All products</Link></li>
              {categories.map((c) => (
                <li key={c.slug}>
                  <Link href={`/${c.slug}`} className="hover:text-brass">{c.name}</Link>
                </li>
              ))}
              <li><Link href="/blog" className="hover:text-brass">Guides &amp; tips</Link></li>
              <li><Link href="/track-order" className="hover:text-brass">Track an order</Link></li>
              <li><Link href="/about" className="hover:text-brass">About us</Link></li>
              <li><Link href="/contact" className="hover:text-brass">Contact &amp; bulk enquiries</Link></li>
            </ul>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Policies</p>
            <ul className="space-y-2">
              <li><Link href="/shipping" className="hover:text-brass">Shipping</Link></li>
              <li><Link href="/returns" className="hover:text-brass">Returns &amp; Exchanges</Link></li>
              <li><Link href="/privacy" className="hover:text-brass">Privacy Policy</Link></li>
              <li><Link href="/terms" className="hover:text-brass">Terms of Service</Link></li>
            </ul>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Get in touch</p>
            <ul className="space-y-2 text-stone/80">
              <li>WhatsApp / Call: +92 311 7798157</li>
              <li>218/18 Ferozepur Road, near WAPDA Hospital, Lahore</li>
              <li>
                <a href="https://www.facebook.com/siqbalhwc" className="hover:text-brass" target="_blank" rel="noopener noreferrer">
                  facebook.com/siqbalhwc
                </a>
              </li>
              <li>
                <a href="https://www.instagram.com/siqbalco" className="hover:text-brass" target="_blank" rel="noopener noreferrer">
                  Instagram: @siqbalco
                </a>
              </li>
            </ul>
          </div>
        </div>

        <p className="mt-12 border-t border-stone/10 pt-6 font-body text-xs text-stone/40">
          © {new Date().getFullYear()} Shahid Iqbal &amp; Co. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- components/Header.tsx ----
$path = "components/Header.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCart } from "@/lib/cart-context";
import { CatalogueDownloadButton } from "@/components/CatalogueDownloadButton";

export default function Header({ categories = [] }: { categories?: { name: string; slug: string }[] }) {
  const { lines } = useCart();
  const router = useRouter();
  const itemCount = lines.reduce((sum, l) => sum + l.quantity, 0);
  const [menuOpen, setMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [query, setQuery] = useState("");

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    const q = query.trim();
    setSearchOpen(false);
    setMenuOpen(false);
    router.push(q ? `/shop?q=${encodeURIComponent(q)}` : "/shop");
  }

  return (
    <header className="border-b border-nickel/30">
      <div className="mx-auto flex max-w-[1400px] items-center justify-between px-6 py-5">
        <Link href="/" className="flex items-center gap-3">
          <img src="/logo.png?v=3" alt="Shahid Iqbal & Co logo" className="h-11 w-11" />
          <span className="font-display text-2xl tracking-tight text-ink">
            Shahid Iqbal &amp; Co
          </span>
        </Link>

        <nav className="hidden items-center gap-8 font-body text-sm text-graphite md:flex">
          <Link href="/shop" className="hover:text-ink">Shop</Link>
          {categories.slice(0, 4).map((c) => (
            <Link key={c.slug} href={`/${c.slug}`} className="hover:text-ink">{c.name}</Link>
          ))}
          <Link href="/blog" className="hover:text-ink">Guides</Link>
          <Link href="/track-order" className="hover:text-ink">Track order</Link>
          <CatalogueDownloadButton />
        </nav>

        <div className="flex items-center gap-4">
          {searchOpen ? (
            <form onSubmit={handleSearch} className="flex items-center gap-2">
              <input
                type="text"
                autoFocus
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Escape") {
                    setSearchOpen(false);
                    setQuery("");
                  }
                }}
                onBlur={() => {
                  if (!query.trim()) setSearchOpen(false);
                }}
                placeholder="Search…"
                className="w-32 border-b border-nickel/50 bg-transparent px-0.5 py-1 font-body text-sm text-ink outline-none placeholder:text-graphite/60 focus:border-ink sm:w-48"
              />
              <button
                type="button"
                onClick={() => {
                  setSearchOpen(false);
                  setQuery("");
                }}
                aria-label="Close search"
                className="text-graphite hover:text-ink"
              >
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                  <path d="M1 1L13 13M13 1L1 13" stroke="currentColor" strokeWidth="1.3" />
                </svg>
              </button>
            </form>
          ) : (
            <button
              type="button"
              onClick={() => setSearchOpen(true)}
              className="text-graphite hover:text-ink"
              aria-label="Open search"
            >
              <svg width="17" height="17" viewBox="0 0 17 17" fill="none">
                <circle cx="7" cy="7" r="5.5" stroke="currentColor" strokeWidth="1.3" />
                <path d="M11.5 11.5L15.5 15.5" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
              </svg>
            </button>
          )}
          <Link
            href="/cart"
            className="font-body text-sm text-ink underline decoration-nickel decoration-1 underline-offset-4 hover:decoration-brass"
          >
            Cart{itemCount > 0 ? ` (${itemCount})` : ""}
          </Link>
          <button
            type="button"
            onClick={() => setMenuOpen((v) => !v)}
            className="flex h-9 w-9 flex-col items-center justify-center gap-1.5 md:hidden"
            aria-label="Toggle menu"
            aria-expanded={menuOpen}
          >
            <span className="block h-px w-5 bg-ink" />
            <span className="block h-px w-5 bg-ink" />
            <span className="block h-px w-5 bg-ink" />
          </button>
        </div>
      </div>

      {menuOpen && (
        <nav className="flex flex-col gap-1 border-t border-nickel/20 px-6 py-4 font-body text-sm text-graphite md:hidden">
          <Link href="/shop" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Shop</Link>
          {categories.map((c) => (
            <Link key={c.slug} href={`/${c.slug}`} onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">{c.name}</Link>
          ))}
          <Link href="/blog" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Guides</Link>
          <Link href="/track-order" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Track order</Link>
          <Link href="/contact" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Contact</Link>
        </nav>
      )}
    </header>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- components/SortSelect.tsx ----
$path = "components/SortSelect.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useRouter, useSearchParams, usePathname } from "next/navigation";

const OPTIONS = [
  { value: "newest", label: "Newest" },
  { value: "price_asc", label: "Price: Low to High" },
  { value: "price_desc", label: "Price: High to Low" },
];

export default function SortSelect() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const pathname = usePathname(); // "/shop" or the current clean category path, e.g. "/cabinet-handles"

  function handleChange(value: string) {
    const params = new URLSearchParams(searchParams.toString());
    params.delete("limit"); // reset pagination when sort order changes
    if (value === "newest") {
      params.delete("sort");
    } else {
      params.set("sort", value);
    }
    const qs = params.toString();
    router.push(qs ? `${pathname}?${qs}` : pathname);
  }

  return (
    <select
      defaultValue={searchParams.get("sort") ?? "newest"}
      onChange={(e) => handleChange(e.target.value)}
      className="border border-nickel/40 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
      aria-label="Sort products"
    >
      {OPTIONS.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- lib/types.ts ----
$path = "lib/types.ts"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
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

export type ShippingSettings = {
  base_fee: number;
  per_kg_rate: number;
  courier_name: string;
};

export type Enquiry = {
  id: string;
  name: string;
  phone: string;
  email: string | null;
  message: string;
  enquiry_type: "general" | "bulk_wholesale";
  status: "new" | "contacted" | "closed";
  created_at: string;
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
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/[category]/page.tsx ----
$path = "app/[category]/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
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
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/admin/enquiries/page.tsx ----
$path = "app/admin/enquiries/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Enquiry } from "@/lib/types";

const STATUS_STEPS: Enquiry["status"][] = ["new", "contacted", "closed"];

export default function AdminEnquiriesPage() {
  const [enquiries, setEnquiries] = useState<Enquiry[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const { data } = await supabase.from("enquiries").select("*").order("created_at", { ascending: false });
    setEnquiries(data ?? []);
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function updateStatus(id: string, status: string) {
    await supabase.from("enquiries").update({ status }).eq("id", id);
    load();
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Enquiries</h1>
      <p className="mt-2 font-body text-sm text-graphite">
        Messages from the Contact &amp; Bulk Enquiry page.
      </p>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : enquiries.length === 0 ? (
        <p className="mt-8 font-body text-graphite">No enquiries yet.</p>
      ) : (
        <div className="mt-8 space-y-4">
          {enquiries.map((enq) => (
            <div key={enq.id} className="border border-nickel/30 p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="font-body text-ink">
                    {enq.name}
                    {enq.enquiry_type === "bulk_wholesale" && (
                      <span className="ml-2 border border-brass px-1.5 py-0.5 font-body text-xs text-brass">
                        Bulk / wholesale
                      </span>
                    )}
                  </p>
                  <p className="font-body text-sm text-graphite">
                    {enq.phone}
                    {enq.email ? ` · ${enq.email}` : ""}
                  </p>
                </div>
                <p className="font-body text-xs text-graphite">
                  {new Date(enq.created_at).toLocaleString()}
                </p>
              </div>

              <p className="mt-3 whitespace-pre-wrap font-body text-sm text-ink">{enq.message}</p>

              <div className="mt-4 flex items-center gap-2">
                <span className="font-body text-sm text-graphite">Status:</span>
                {STATUS_STEPS.map((s) => (
                  <button
                    key={s}
                    onClick={() => updateStatus(enq.id, s)}
                    className={`border px-2 py-1 font-body text-xs capitalize ${
                      enq.status === s ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite hover:text-ink"
                    }`}
                  >
                    {s}
                  </button>
                ))}
                <a
                  href={`https://wa.me/${enq.phone.replace(/[^\d]/g, "")}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="ml-auto font-body text-xs text-graphite underline hover:text-ink"
                >
                  Reply on WhatsApp
                </a>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/admin/shipping-settings/page.tsx ----
$path = "app/admin/shipping-settings/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { calculateShippingFee } from "@/lib/shipping";

export default function AdminShippingSettingsPage() {
  const [baseFee, setBaseFee] = useState("150");
  const [perKgRate, setPerKgRate] = useState("100");
  const [courierName, setCourierName] = useState("Leopard Courier");
  const [loading, setLoading] = useState(true);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    const { data } = await supabase.from("shipping_settings").select("*").single();
    if (data) {
      setBaseFee(String(data.base_fee));
      setPerKgRate(String(data.per_kg_rate));
      setCourierName(data.courier_name);
    }
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function handleSave() {
    setError(null);
    const base = Number(baseFee);
    const perKg = Number(perKgRate);
    if (Number.isNaN(base) || base < 0 || Number.isNaN(perKg) || perKg < 0) {
      setError("Base fee and per-kg rate must be numbers, 0 or more.");
      return;
    }
    const { error } = await supabase
      .from("shipping_settings")
      .update({ base_fee: base, per_kg_rate: perKg, courier_name: courierName.trim() || "Leopard Courier" })
      .eq("id", 1);
    if (error) {
      setError(error.message);
      return;
    }
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  }

  const previewWeights = [500, 1000, 2500, 5000];

  return (
    <div className="max-w-2xl">
      <h1 className="font-display text-3xl text-ink">Shipping (Cash on Delivery)</h1>
      <p className="mt-2 font-body text-sm text-graphite">
        Used to calculate the COD shipping fee charged on top of the product price — collected
        by {courierName || "the courier"} on delivery. Also shown to bank-transfer customers as
        part of their total. Weight comes from each product&rsquo;s &ldquo;Weight&rdquo; field in
        the product form.
      </p>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : (
        <>
          <div className="mt-8 grid gap-4 border border-nickel/25 p-5 sm:grid-cols-2">
            <label className="block">
              <span className="font-body text-xs text-graphite">Courier name</span>
              <input
                value={courierName}
                onChange={(e) => setCourierName(e.target.value)}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
              />
            </label>
            <div />
            <label className="block">
              <span className="font-body text-xs text-graphite">Base / dispatch fee (Rs.)</span>
              <input
                type="number"
                min={0}
                value={baseFee}
                onChange={(e) => setBaseFee(e.target.value)}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
              />
              <span className="mt-1 block font-body text-xs text-graphite/70">Charged once per order</span>
            </label>
            <label className="block">
              <span className="font-body text-xs text-graphite">Rate per kg (Rs.)</span>
              <input
                type="number"
                min={0}
                value={perKgRate}
                onChange={(e) => setPerKgRate(e.target.value)}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
              />
              <span className="mt-1 block font-body text-xs text-graphite/70">
                Rounded up to the next full kg, minimum 1kg per order
              </span>
            </label>
          </div>

          {error && <p className="mt-3 font-body text-sm text-rust">{error}</p>}

          <button
            onClick={handleSave}
            className="mt-4 bg-ink px-4 py-2 font-body text-sm text-stone hover:bg-brass"
          >
            {saved ? "Saved ✓" : "Save"}
          </button>

          <div className="mt-10">
            <p className="font-body text-sm text-ink">Preview</p>
            <div className="mt-3 divide-y divide-nickel/20 border-y border-nickel/20 font-body text-sm">
              {previewWeights.map((g) => (
                <div key={g} className="flex justify-between py-2">
                  <span className="text-graphite">{g >= 1000 ? `${g / 1000}kg` : `${g}g`} order</span>
                  <span className="text-ink">
                    Rs. {calculateShippingFee(g, { base_fee: Number(baseFee) || 0, per_kg_rate: Number(perKgRate) || 0 }).toLocaleString()}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/api/enquiries/create/route.ts ----
$path = "app/api/enquiries/create/route.ts"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
import { NextResponse } from "next/server";
import { getServiceClient } from "@/lib/supabase";

export async function POST(request: Request) {
  const body = await request.json();
  const { name, phone, email, message, enquiryType } = body as {
    name: string;
    phone: string;
    email?: string;
    message: string;
    enquiryType: "general" | "bulk_wholesale";
  };

  if (!name?.trim() || !phone?.trim() || !message?.trim()) {
    return NextResponse.json({ error: "Name, phone, and a message are required." }, { status: 400 });
  }

  const supabase = getServiceClient();

  const { error } = await supabase.from("enquiries").insert({
    name: name.trim(),
    phone: phone.trim(),
    email: email?.trim() || null,
    message: message.trim(),
    enquiry_type: enquiryType === "bulk_wholesale" ? "bulk_wholesale" : "general",
  });

  if (error) {
    return NextResponse.json({ error: "Could not save your message. Please try WhatsApp instead." }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- app/contact/page.tsx ----
$path = "app/contact/page.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";
import ContactForm from "@/components/ContactForm";

export const metadata: Metadata = pageMetadata({
  title: "Contact Us & Bulk / Wholesale Enquiries — Shahid Iqbal & Co",
  description:
    "Get in touch with Shahid Iqbal & Co for questions, custom orders, or bulk/wholesale pricing on cabinet handles, knobs, and door hardware. WhatsApp, call, or send a message — Lahore, Pakistan.",
  path: "/contact",
});

export default function ContactPage() {
  return (
    <div className="mx-auto max-w-4xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Contact &amp; Bulk Enquiries</h1>
      <p className="mt-3 max-w-prose font-body text-graphite">
        Questions about a product, a custom order, or pricing for a contractor / wholesale
        quantity? Send us a message below, on WhatsApp, or by phone — we usually reply the same
        day.
      </p>

      <div className="mt-10 grid gap-10 md:grid-cols-[1fr_1.2fr]">
        <div className="space-y-6 font-body text-sm">
          <div>
            <p className="text-graphite">WhatsApp / Call</p>
            <a href="tel:+923117798157" className="text-lg text-ink underline hover:text-brass">
              +92 311 7798157
            </a>
          </div>
          <div>
            <p className="text-graphite">Visit us</p>
            <p className="text-ink">218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan</p>
          </div>
          <div>
            <p className="text-graphite">Bulk / wholesale orders</p>
            <p className="text-ink">
              Contractors and carpenters — tell us the products, finishes, and quantities you
              need in the form and we&rsquo;ll come back with a quote.
            </p>
          </div>
          <div className="flex gap-4 pt-2">
            <a
              href="https://www.facebook.com/siqbalhwc"
              target="_blank"
              rel="noopener noreferrer"
              className="text-ink underline hover:text-brass"
            >
              Facebook
            </a>
            <a
              href="https://www.instagram.com/siqbalco"
              target="_blank"
              rel="noopener noreferrer"
              className="text-ink underline hover:text-brass"
            >
              Instagram
            </a>
          </div>
        </div>

        <ContactForm />
      </div>
    </div>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- components/ContactForm.tsx ----
$path = "components/ContactForm.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
"use client";

import { useState } from "react";

export default function ContactForm() {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    const form = new FormData(e.currentTarget);
    const payload = {
      name: form.get("name"),
      phone: form.get("phone"),
      email: form.get("email"),
      message: form.get("message"),
      enquiryType: form.get("enquiryType"),
    };

    try {
      const res = await fetch("/api/enquiries/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || "Something went wrong sending your message.");
        return;
      }
      setSent(true);
    } catch {
      setError("Could not reach the server. Please try WhatsApp instead.");
    } finally {
      setSubmitting(false);
    }
  }

  if (sent) {
    return (
      <div className="border border-nickel/30 p-6">
        <p className="font-display text-xl text-ink">Message sent</p>
        <p className="mt-2 font-body text-sm text-graphite">
          Thanks — we&rsquo;ve got your message and will get back to you on WhatsApp or phone
          shortly.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <label className="block">
        <span className="font-body text-sm text-graphite">I&rsquo;m enquiring about</span>
        <select
          name="enquiryType"
          defaultValue="general"
          className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink outline-none focus:border-ink"
        >
          <option value="general">A general question</option>
          <option value="bulk_wholesale">Bulk / wholesale pricing</option>
        </select>
      </label>

      <Field name="name" label="Full name" required />
      <Field name="phone" label="Phone / WhatsApp number" required />
      <Field name="email" label="Email (optional)" type="email" />

      <label className="block">
        <span className="font-body text-sm text-graphite">Message</span>
        <textarea
          name="message"
          required
          rows={5}
          placeholder="Products, finishes, quantities, or your question…"
          className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink outline-none placeholder:text-graphite/50 focus:border-ink"
        />
      </label>

      {error && <p className="font-body text-sm text-rust">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="w-full bg-ink py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
      >
        {submitting ? "Sending…" : "Send message"}
      </button>
    </form>
  );
}

function Field({
  name,
  label,
  type = "text",
  required = false,
}: {
  name: string;
  label: string;
  type?: string;
  required?: boolean;
}) {
  return (
    <label className="block">
      <span className="font-body text-sm text-graphite">{label}</span>
      <input
        name={name}
        type={type}
        required={required}
        className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink outline-none focus:border-ink"
      />
    </label>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- components/ShopBrowser.tsx ----
$path = "components/ShopBrowser.tsx"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
import ProductCard from "@/components/ProductCard";
import SortSelect from "@/components/SortSelect";
import { Product } from "@/lib/types";
import { PAGE_SIZE } from "@/lib/shop-data";

type Category = { id: string; name: string; slug: string };

export default function ShopBrowser({
  basePath,
  heading,
  activeCategorySlug,
  categories,
  filterOptions,
  products,
  hasMore,
  color,
  size,
  q,
  sort,
  limit,
}: {
  basePath: string; // "/shop" or "/{category-slug}" — where filter/sort links point
  heading: string;
  activeCategorySlug?: string; // set only on a /{category-slug} route
  categories: Category[];
  filterOptions: { colors: any[]; sizes: any[] };
  products: Product[];
  hasMore: boolean;
  color?: string;
  size?: string;
  q?: string;
  sort?: string;
  limit: number;
}) {
  // Category switch: goes to the other category's own clean path, carrying
  // color/size/sort/q along (never carries a "category" query param — the
  // path itself is the category now).
  function categoryHref(slug?: string) {
    const params = new URLSearchParams();
    if (color) params.set("color", color);
    if (size) params.set("size", size);
    if (sort) params.set("sort", sort);
    if (q) params.set("q", q);
    const qs = params.toString();
    const path = slug ? `/${slug}` : "/shop";
    return qs ? `${path}?${qs}` : path;
  }

  // Color/size/sort toggle: stays on the current basePath (whether that's
  // /shop or a category page), just changes the query string.
  function filterHref(next: { color?: string; size?: string }) {
    const params = new URLSearchParams();
    const nextColor = next.color !== undefined ? next.color : color;
    const nextSize = next.size !== undefined ? next.size : size;
    if (nextColor) params.set("color", nextColor);
    if (nextSize) params.set("size", nextSize);
    if (q) params.set("q", q);
    if (sort) params.set("sort", sort);
    const qs = params.toString();
    return qs ? `${basePath}?${qs}` : basePath;
  }

  function loadMoreHref() {
    const params = new URLSearchParams();
    if (color) params.set("color", color);
    if (size) params.set("size", size);
    if (q) params.set("q", q);
    if (sort) params.set("sort", sort);
    params.set("limit", String(limit + PAGE_SIZE));
    return `${basePath}?${params.toString()}`;
  }

  function clearFiltersHref() {
    const params = new URLSearchParams();
    if (sort) params.set("sort", sort);
    const qs = params.toString();
    return qs ? `${basePath}?${qs}` : basePath;
  }

  return (
    <div className="mx-auto max-w-[1400px] px-6 py-16">
      <h1 className="font-display text-4xl text-ink">{heading}</h1>

      <div className="mt-8 grid gap-8 md:grid-cols-[200px_1fr]">
        {/* Filters sidebar — stacks above the grid on mobile */}
        <aside className="space-y-6">
          <div>
            <p className="mb-2 font-body text-sm text-graphite">Category</p>
            <div className="flex flex-wrap gap-2 md:flex-col md:items-start md:gap-1">
              <a
                href={categoryHref(undefined)}
                className={`font-body text-sm ${!activeCategorySlug ? "text-ink underline" : "text-graphite hover:text-ink"}`}
              >
                All
              </a>
              {categories.map((cat) => (
                <a
                  key={cat.id}
                  href={categoryHref(cat.slug)}
                  className={`font-body text-sm ${activeCategorySlug === cat.slug ? "text-ink underline" : "text-graphite hover:text-ink"}`}
                >
                  {cat.name}
                </a>
              ))}
            </div>
          </div>

          {filterOptions.colors.length > 0 && (
            <div>
              <p className="mb-2 font-body text-sm text-graphite">Color</p>
              <div className="flex flex-wrap gap-2">
                {filterOptions.colors.map((c: any) => (
                  <a
                    key={c.id}
                    href={color === c.value ? filterHref({ color: undefined }) : filterHref({ color: c.value })}
                    className={`flex items-center gap-1.5 border px-2 py-1 font-body text-xs ${
                      color === c.value ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite"
                    }`}
                  >
                    {c.swatch_hex && (
                      <span className="h-2.5 w-2.5 rounded-full border border-black/10" style={{ backgroundColor: c.swatch_hex }} />
                    )}
                    {c.value}
                  </a>
                ))}
              </div>
            </div>
          )}

          {filterOptions.sizes.length > 0 && (
            <div>
              <p className="mb-2 font-body text-sm text-graphite">Size</p>
              <div className="flex flex-wrap gap-2">
                {filterOptions.sizes.map((s: any) => (
                  <a
                    key={s.id}
                    href={size === s.value ? filterHref({ size: undefined }) : filterHref({ size: s.value })}
                    className={`border px-2 py-1 font-body text-xs ${
                      size === s.value ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite"
                    }`}
                  >
                    {s.value}
                  </a>
                ))}
              </div>
            </div>
          )}

          {(color || size) && (
            <a href={clearFiltersHref()} className="inline-block font-body text-xs text-graphite underline hover:text-ink">
              Clear all filters
            </a>
          )}
        </aside>

        {/* Results */}
        <div>
          <div className="mb-6 flex items-center justify-between gap-4">
            <p className="font-body text-sm text-graphite">
              {q && (
                <>
                  {products.length === 0 ? "No matches" : `Showing results`} for &ldquo;{q}&rdquo;
                  {" · "}
                  <a href={basePath} className="underline hover:text-ink">
                    Clear search
                  </a>
                </>
              )}
            </p>
            <SortSelect />
          </div>

          {products.length === 0 ? (
            <p className="font-body text-graphite">
              No products match these filters — try clearing one, or browse all products.
            </p>
          ) : (
            <>
              <div className="grid gap-x-6 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
                {products.map((p) => (
                  <ProductCard key={p.id} product={p} />
                ))}
              </div>
              {hasMore && (
                <div className="mt-10 text-center">
                  <a
                    href={loadMoreHref()}
                    className="inline-block border border-ink px-6 py-2 font-body text-sm text-ink hover:bg-ink hover:text-stone"
                  >
                    Load more
                  </a>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- lib/shipping.ts ----
$path = "lib/shipping.ts"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
// Weight-based COD shipping via Leopard Courier.
//
// How it works: every product stores its shipping weight in grams
// (`weight_grams`). At checkout, we sum weight × quantity across the cart,
// then apply the store's rate card (editable in /admin/shipping-settings)
// to work out the courier fee. The same number is charged whether the
// customer pays by bank transfer (added to the bank total) or COD (collected
// by the Leopard rider along with the product price).
//
// This is only ever computed SERVER-SIDE at order time (see
// app/api/orders/create/route.ts) — the client-side estimate shown at
// checkout is for the customer's information only and is never trusted.

export type ShippingSettings = {
  base_fee: number; // flat dispatch/handling fee, charged once per order
  per_kg_rate: number; // charged per billable kg on top of the base fee
  courier_name?: string;
};

export const DEFAULT_SHIPPING_SETTINGS: ShippingSettings = {
  base_fee: 150,
  per_kg_rate: 100,
  courier_name: "the courier",
};

// Products created before a weight was recorded fall back to this so
// shipping still calculates something reasonable instead of zero.
export const FALLBACK_ITEM_WEIGHT_GRAMS = 300;

// Couriers bill by rounded-up kg, not the exact gram weight — this mirrors
// that so the estimate shown to the customer matches what Leopard actually
// charges.
export function calculateShippingFee(totalWeightGrams: number, settings: ShippingSettings): number {
  const billableKg = Math.max(1, Math.ceil(totalWeightGrams / 1000));
  return Math.round(settings.base_fee + billableKg * settings.per_kg_rate);
}

// Converts the admin's free-text "Weight" spec (e.g. "500", unit "g"/"kg")
// into a plain integer grams value for the dedicated weight_grams column.
export function weightToGrams(weight: string, unit: string): number | null {
  const n = Number(weight.trim());
  if (!weight.trim() || Number.isNaN(n) || n <= 0) return null;
  return Math.round(unit === "kg" ? n * 1000 : n);
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- lib/shop-data.ts ----
$path = "lib/shop-data.ts"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
import { supabase } from "@/lib/supabase";
import { Product } from "@/lib/types";

export const PAGE_SIZE = 12;

export async function getCategories() {
  const { data } = await supabase.from("categories").select("*").order("sort_order");
  return data ?? [];
}

// Every Finish/Size value currently in use, for the filter buttons
export async function getFilterOptions() {
  const { data } = await supabase
    .from("attribute_values")
    .select("id, value, swatch_hex, attributes(name)")
    .order("value");

  const colors = (data ?? []).filter((v: any) => v.attributes?.name === "Finish");
  const sizes = (data ?? []).filter((v: any) => v.attributes?.name === "Size");
  return { colors, sizes };
}

// Resolves the color/size query params down to a set of product ids that
// have a variant matching BOTH selected filters together (not just either).
async function getProductIdsMatchingVariantFilters(colorValue?: string, sizeValue?: string) {
  if (!colorValue && !sizeValue) return null; // null = no filtering needed

  const wantedValueIds: string[] = [];
  if (colorValue) {
    const { data } = await supabase.from("attribute_values").select("id").eq("value", colorValue).maybeSingle();
    if (data) wantedValueIds.push(data.id);
  }
  if (sizeValue) {
    const { data } = await supabase.from("attribute_values").select("id").eq("value", sizeValue).maybeSingle();
    if (data) wantedValueIds.push(data.id);
  }
  if (wantedValueIds.length === 0) return [];

  const { data: links } = await supabase
    .from("variant_attribute_values")
    .select("variant_id, attribute_value_id")
    .in("attribute_value_id", wantedValueIds);

  // Keep only variants that matched EVERY requested filter, not just one
  const matchCounts = new Map<string, number>();
  for (const link of links ?? []) {
    matchCounts.set(link.variant_id, (matchCounts.get(link.variant_id) ?? 0) + 1);
  }
  const matchingVariantIds = Array.from(matchCounts.entries())
    .filter(([, count]) => count === wantedValueIds.length)
    .map(([variantId]) => variantId);

  if (matchingVariantIds.length === 0) return [];

  const { data: variants } = await supabase
    .from("product_variants")
    .select("product_id")
    .in("id", matchingVariantIds);

  return Array.from(new Set((variants ?? []).map((v) => v.product_id)));
}

export async function getProducts(
  categorySlug?: string,
  colorValue?: string,
  sizeValue?: string,
  searchTerm?: string,
  sort?: string,
  limit?: number
): Promise<{ products: Product[]; hasMore: boolean }> {
  let categoryId: string | undefined;
  if (categorySlug) {
    const { data } = await supabase.from("categories").select("id").eq("slug", categorySlug).single();
    categoryId = data?.id;
  }

  const matchingProductIds = await getProductIdsMatchingVariantFilters(colorValue, sizeValue);
  if (matchingProductIds !== null && matchingProductIds.length === 0) return { products: [], hasMore: false };

  const effectiveLimit = limit ?? PAGE_SIZE;

  let query = supabase
    .from("products")
    .select("*, product_images(*), product_variants(*, variant_attribute_values(attribute_value_id))")
    .eq("status", "active");

  if (categoryId) query = query.eq("category_id", categoryId);
  if (matchingProductIds !== null) query = query.in("id", matchingProductIds);
  if (searchTerm) query = query.or(`name.ilike.%${searchTerm}%,description.ilike.%${searchTerm}%`);

  if (sort === "price_asc") query = query.order("base_price", { ascending: true });
  else if (sort === "price_desc") query = query.order("base_price", { ascending: false });
  else query = query.order("created_at", { ascending: false });

  // Fetch one extra row so we know whether a "Load more" link is needed,
  // without a separate count() query.
  query = query.range(0, effectiveLimit);

  const { data } = await query;
  if (!data) return { products: [], hasMore: false };

  const hasMore = data.length > effectiveLimit;
  const page = data.slice(0, effectiveLimit);

  const products = page.map((p: any) => ({
    ...p,
    images: (p.product_images ?? []).sort((a: any, b: any) => a.sort_order - b.sort_order),
    variants: (p.product_variants ?? []).map((v: any) => ({
      ...v,
      attribute_value_ids: (v.variant_attribute_values ?? []).map((j: any) => j.attribute_value_id),
    })),
  }));

  return { products, hasMore };
}
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- migration-contact-and-shipping.sql ----
$path = "migration-contact-and-shipping.sql"
New-Item -ItemType Directory -Force -Path (Split-Path -LiteralPath $path) | Out-Null
@'
-- ============================================================================
-- Adds: 1) Contact / Bulk Enquiry form storage, 2) weight-based shipping
-- settings for the new Cash on Delivery (Leopard Courier) option, and
-- 3) the columns needed to record that shipping fee on each order.
-- Safe to re-run — every statement below is idempotent.
-- Paste this whole file into Supabase → SQL Editor → Run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONTACT / BULK ENQUIRY FORM
-- Every submission from /contact lands here. Public (anon key) can insert
-- but never read back — same pattern as orders. You review these in
-- /admin/enquiries.
-- ----------------------------------------------------------------------------
create table if not exists enquiries (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  phone        text not null,
  email        text,
  message      text not null,
  enquiry_type text not null default 'general' check (enquiry_type in ('general', 'bulk_wholesale')),
  status       text not null default 'new' check (status in ('new', 'contacted', 'closed')),
  created_at   timestamptz not null default now()
);

alter table enquiries enable row level security;

drop policy if exists public_insert_enquiries on enquiries;
drop policy if exists admin_all_enquiries on enquiries;

create policy public_insert_enquiries on enquiries for insert with check (true);
create policy admin_all_enquiries on enquiries for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create index if not exists idx_enquiries_created on enquiries(created_at desc);

-- ----------------------------------------------------------------------------
-- SHIPPING (weight-based COD rate card)
-- Single row, editable in /admin/shipping-settings. total_shipping_fee =
-- base_fee + per_kg_rate × ceil(order_weight_kg). Shown to customers at
-- checkout and recomputed server-side (never trusted from the browser) when
-- the order is actually created.
-- ----------------------------------------------------------------------------
create table if not exists shipping_settings (
  id           integer primary key default 1 check (id = 1), -- enforces a single row
  base_fee     numeric(12,2) not null default 150,
  per_kg_rate  numeric(12,2) not null default 100,
  courier_name text not null default 'Leopard Courier',
  updated_at   timestamptz not null default now()
);

insert into shipping_settings (id) values (1) on conflict (id) do nothing;

alter table shipping_settings enable row level security;

drop policy if exists public_read_shipping_settings on shipping_settings;
drop policy if exists admin_all_shipping_settings on shipping_settings;

-- Public can read it (needed to show a live shipping estimate at checkout)
-- but never write it.
create policy public_read_shipping_settings on shipping_settings for select using (true);
create policy admin_all_shipping_settings on shipping_settings for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ----------------------------------------------------------------------------
-- PRODUCT SHIPPING WEIGHT
-- Numeric grams, used only for the shipping calculation (separate from the
-- free-text "Weight" spec shown on the product page). Falls back to a
-- reasonable default in code if a product was created before this existed.
-- ----------------------------------------------------------------------------
alter table products add column if not exists weight_grams integer;

-- ----------------------------------------------------------------------------
-- ORDERS: record the shipping fee actually charged, and allow COD
-- ----------------------------------------------------------------------------
alter table orders add column if not exists shipping_fee numeric(12,2) not null default 0;

alter table orders drop constraint if exists orders_payment_method_check;
alter table orders add constraint orders_payment_method_check
  check (payment_method in ('bank_transfer', 'cod', 'razorpay', 'stripe'));
'@ | Set-Content -LiteralPath $path -NoNewline -Encoding UTF8

# ---- housekeeping ----
Add-Content -LiteralPath ".gitignore" -Value "*.tsbuildinfo"

Set-Location ".."

git add .
git commit -m "Add contact/bulk enquiry page, clean category URLs, and COD shipping via Leopard Courier"
git push origin main

Write-Host ""
Write-Host "Done - check https://vercel.com for the new deployment in a minute or two." -ForegroundColor Green
Write-Host ""
Write-Host "ONE MORE STEP (do this once): open Supabase -> SQL Editor, paste the" -ForegroundColor Yellow
Write-Host "contents of cabinet-hardware-site/migration-contact-and-shipping.sql, and Run it." -ForegroundColor Yellow
Write-Host "Then set your COD rates in /admin/shipping-settings." -ForegroundColor Yellow