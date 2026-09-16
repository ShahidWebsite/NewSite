"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

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
  const [name, setName] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [description, setDescription] = useState("");
  const [basePrice, setBasePrice] = useState("");
  const [imageFiles, setImageFiles] = useState<ImageFile[]>([]);
  const [specs, setSpecs] = useState<SpecRow[]>([{ key: "Material", value: "" }]);
  const [variants, setVariants] = useState<VariantRow[]>([
    { finish: "", size: "", price: "", stock: "", sku: "" },
  ]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    supabase.from("categories").select("*").order("sort_order").then(({ data }) => setCategories(data ?? []));
  }, []);

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
      const specsObject = Object.fromEntries(
        specs.filter((s) => s.key.trim() && s.value.trim()).map((s) => [s.key.trim(), s.value.trim()])
      );

      const { data: product, error: productError } = await supabase
        .from("products")
        .insert({
          name,
          slug: slugify(name),
          description,
          category_id: categoryId || null,
          base_price: Number(basePrice) || 0,
          specs: specsObject,
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
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Add product</h1>

      <form onSubmit={handleSubmit} className="mt-8 max-w-2xl space-y-8">
        <div className="space-y-4">
          <LabeledInput label="Product name" value={name} onChange={setName} required />
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
          <label className="block">
            <span className="font-body text-sm text-graphite">Description</span>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            />
          </label>
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

        <div>
          <p className="font-body text-sm text-graphite">Specifications</p>
          {specs.map((spec, i) => (
            <div key={i} className="mt-2 flex gap-2">
              <input
                value={spec.key}
                onChange={(e) =>
                  setSpecs((prev) => prev.map((s, idx) => (idx === i ? { ...s, key: e.target.value } : s)))
                }
                placeholder="Spec name (e.g. Material)"
                className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
              />
              <input
                value={spec.value}
                onChange={(e) =>
                  setSpecs((prev) => prev.map((s, idx) => (idx === i ? { ...s, value: e.target.value } : s)))
                }
                placeholder="Value (e.g. Zinc alloy)"
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

        <div>
          <p className="font-body text-sm text-graphite">
            Variants — each row is one buyable combination. Leave Size blank if this product doesn't vary by size.
          </p>
          <div className="mt-3 space-y-3">
            {variants.map((v, i) => (
              <div key={i} className="grid grid-cols-5 gap-2 border border-nickel/20 p-3">
                <input
                  value={v.finish}
                  onChange={(e) => updateVariant(i, "finish", e.target.value)}
                  placeholder="Finish (e.g. Matte Black)"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
                />
                <input
                  value={v.size}
                  onChange={(e) => updateVariant(i, "size", e.target.value)}
                  placeholder="Size (e.g. 128mm)"
                  className="border border-nickel/50 bg-transparent px-2 py-1.5 font-body text-sm text-ink"
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

        {error && <p className="font-body text-sm text-rust">{error}</p>}

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
