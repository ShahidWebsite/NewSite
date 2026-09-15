"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default function AdminProductsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const { data } = await supabase
      .from("products")
      .select("*, product_variants(stock_qty)")
      .order("created_at", { ascending: false });
    setProducts(data ?? []);
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function handleDelete(id: string) {
    if (!confirm("Delete this product and all its variants? This cannot be undone.")) return;
    await supabase.from("products").delete().eq("id", id);
    load();
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="font-display text-3xl text-ink">Products</h1>
        <Link href="/admin/products/new" className="bg-ink px-4 py-2 font-body text-sm text-stone hover:bg-brass">
          Add product
        </Link>
      </div>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : (
        <table className="mt-8 w-full font-body text-sm">
          <thead>
            <tr className="border-b border-nickel/30 text-left text-graphite">
              <th className="py-2">Name</th>
              <th className="py-2">Base price</th>
              <th className="py-2">Total stock</th>
              <th className="py-2">Status</th>
              <th className="py-2"></th>
            </tr>
          </thead>
          <tbody>
            {products.map((p) => {
              const totalStock = (p.product_variants ?? []).reduce(
                (sum: number, v: any) => sum + v.stock_qty,
                0
              );
              return (
                <tr key={p.id} className="border-b border-nickel/10">
                  <td className="py-3 text-ink">{p.name}</td>
                  <td className="py-3 text-ink">Rs. {p.base_price.toLocaleString()}</td>
                  <td className="py-3 text-ink">{totalStock}</td>
                  <td className="py-3 capitalize text-graphite">{p.status.replace("_", " ")}</td>
                  <td className="py-3 text-right">
                    <button onClick={() => handleDelete(p.id)} className="text-graphite hover:text-rust">
                      Delete
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );
}
