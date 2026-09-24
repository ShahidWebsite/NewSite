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