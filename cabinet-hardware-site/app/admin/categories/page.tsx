"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

function slugify(text: string) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
}

export default function AdminCategoriesPage() {
  const [categories, setCategories] = useState<any[]>([]);
  const [newName, setNewName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

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
    if (!newName.trim()) return;
    setError(null);
    const { error } = await supabase
      .from("categories")
      .insert({ name: newName.trim(), slug: slugify(newName), sort_order: categories.length });
    if (error) {
      setError(error.message);
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

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Categories</h1>

      <div className="mt-8 flex max-w-md gap-2">
        <input
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
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
        <div className="mt-8 max-w-md divide-y divide-nickel/20 border-y border-nickel/20">
          {categories.map((cat) => (
            <div key={cat.id} className="flex items-center justify-between py-3 font-body text-sm">
              <span className="text-ink">{cat.name}</span>
              <div className="flex items-center gap-4">
                <span className="text-graphite">{cat.products?.[0]?.count ?? 0} products</span>
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
