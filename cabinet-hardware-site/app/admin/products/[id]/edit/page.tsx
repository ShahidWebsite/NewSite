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
