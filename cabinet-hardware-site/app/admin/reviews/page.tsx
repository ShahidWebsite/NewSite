"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type ReviewRow = {
  id: string;
  product_id: string | null;
  customer_name: string;
  rating: number;
  body: string;
  approved: boolean;
  created_at: string;
  products: { name: string; slug: string } | null;
};

export default function AdminReviewsPage() {
  const [reviews, setReviews] = useState<ReviewRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<"pending" | "approved" | "all">("pending");

  async function load() {
    setLoading(true);
    const { data } = await supabase
      .from("reviews")
      .select("*, products(name, slug)")
      .order("created_at", { ascending: false });
    setReviews((data as any) ?? []);
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function approve(id: string) {
    await supabase.from("reviews").update({ approved: true }).eq("id", id);
    load();
  }

  async function unapprove(id: string) {
    await supabase.from("reviews").update({ approved: false }).eq("id", id);
    load();
  }

  async function remove(id: string) {
    if (!confirm("Delete this review permanently?")) return;
    await supabase.from("reviews").delete().eq("id", id);
    load();
  }

  const visible = reviews.filter((r) =>
    filter === "all" ? true : filter === "pending" ? !r.approved : r.approved
  );

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Reviews</h1>
      <p className="mt-2 font-body text-sm text-graphite">
        New reviews start hidden. Approve the ones you want visible on the product page.
      </p>

      <div className="mt-6 flex gap-4 font-body text-sm">
        {(["pending", "approved", "all"] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={filter === f ? "text-ink underline" : "text-graphite hover:text-ink"}
          >
            {f === "pending" ? "Pending" : f === "approved" ? "Approved" : "All"} (
            {f === "all" ? reviews.length : reviews.filter((r) => (f === "pending" ? !r.approved : r.approved)).length}
            )
          </button>
        ))}
      </div>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : visible.length === 0 ? (
        <p className="mt-8 font-body text-graphite">Nothing here.</p>
      ) : (
        <div className="mt-6 max-w-2xl divide-y divide-nickel/20 border-y border-nickel/20">
          {visible.map((r) => (
            <div key={r.id} className="py-4 font-body text-sm">
              <div className="flex items-center justify-between gap-4">
                <p className="text-ink">
                  {r.customer_name} — {"★".repeat(r.rating)}
                  {"★".repeat(5 - r.rating).split("").map((_, i) => (
                    <span key={i} className="text-nickel/40">★</span>
                  ))}
                </p>
                <span className="text-xs text-graphite">
                  {r.products ? r.products.name : r.product_id ? "(deleted product)" : "General testimonial"}
                </span>
              </div>
              <p className="mt-1 text-graphite">{r.body}</p>
              <div className="mt-2 flex gap-4 text-xs">
                {r.approved ? (
                  <button onClick={() => unapprove(r.id)} className="text-graphite hover:text-ink">
                    Unapprove
                  </button>
                ) : (
                  <button onClick={() => approve(r.id)} className="text-olive hover:underline">
                    Approve
                  </button>
                )}
                <button onClick={() => remove(r.id)} className="text-graphite hover:text-rust">
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
