"use client";

import { useState } from "react";
import { supabase } from "@/lib/supabase";

export default function ReviewForm({ productId }: { productId: string }) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [rating, setRating] = useState(5);
  const [body, setBody] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || !body.trim()) return;
    setSubmitting(true);
    setError(null);

    const { error } = await supabase.from("reviews").insert({
      product_id: productId,
      customer_name: name.trim(),
      rating,
      body: body.trim(),
      approved: false,
    });

    setSubmitting(false);
    if (error) {
      setError("Couldn't submit your review — please try again.");
      return;
    }
    setDone(true);
  }

  if (done) {
    return (
      <p className="font-body text-sm text-olive">
        Thanks — your review has been submitted and will appear once it's been checked.
      </p>
    );
  }

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="border border-ink px-4 py-2 font-body text-sm text-ink hover:bg-ink hover:text-stone"
      >
        Write a review
      </button>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-md space-y-3">
      <div>
        <label className="mb-1 block font-body text-xs text-graphite">Your name</label>
        <input
          type="text"
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="w-full border border-nickel/40 px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
        />
      </div>
      <div>
        <label className="mb-1 block font-body text-xs text-graphite">Rating</label>
        <select
          value={rating}
          onChange={(e) => setRating(Number(e.target.value))}
          className="border border-nickel/40 px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
        >
          {[5, 4, 3, 2, 1].map((n) => (
            <option key={n} value={n}>
              {n} star{n === 1 ? "" : "s"}
            </option>
          ))}
        </select>
      </div>
      <div>
        <label className="mb-1 block font-body text-xs text-graphite">Review</label>
        <textarea
          required
          rows={3}
          value={body}
          onChange={(e) => setBody(e.target.value)}
          className="w-full border border-nickel/40 px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
        />
      </div>
      {error && <p className="font-body text-sm text-rust">{error}</p>}
      <button
        type="submit"
        disabled={submitting}
        className="border border-ink px-4 py-2 font-body text-sm text-ink hover:bg-ink hover:text-stone disabled:opacity-50"
      >
        {submitting ? "Submitting…" : "Submit review"}
      </button>
    </form>
  );
}
