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
