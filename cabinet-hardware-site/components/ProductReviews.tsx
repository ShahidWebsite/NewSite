import { supabase } from "@/lib/supabase";
import { Review } from "@/lib/types";
import ReviewForm from "@/components/ReviewForm";

function Stars({ rating }: { rating: number }) {
  return (
    <span className="text-rust" aria-label={`${rating} out of 5 stars`}>
      {"★".repeat(rating)}
      <span className="text-nickel/50">{"★".repeat(5 - rating)}</span>
    </span>
  );
}

export default async function ProductReviews({ productId }: { productId: string }) {
  const { data } = await supabase
    .from("reviews")
    .select("*")
    .eq("product_id", productId)
    .eq("approved", true)
    .order("created_at", { ascending: false });

  const reviews = (data ?? []) as Review[];
  const average =
    reviews.length > 0 ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length : null;

  return (
    <div className="mt-16 border-t border-nickel/30 pt-10">
      <div className="flex items-center justify-between gap-4">
        <h2 className="font-display text-2xl text-ink">Customer reviews</h2>
        {average !== null && (
          <p className="font-body text-sm text-graphite">
            <Stars rating={Math.round(average)} /> {average.toFixed(1)} ({reviews.length} review
            {reviews.length === 1 ? "" : "s"})
          </p>
        )}
      </div>

      {reviews.length === 0 ? (
        <p className="mt-4 font-body text-sm text-graphite">
          No reviews yet — be the first to share what you think.
        </p>
      ) : (
        <ul className="mt-6 space-y-6">
          {reviews.map((r) => (
            <li key={r.id} className="border-b border-nickel/20 pb-6 last:border-none">
              <div className="flex items-center justify-between gap-4">
                <p className="font-body text-sm text-ink">{r.customer_name}</p>
                <Stars rating={r.rating} />
              </div>
              <p className="mt-1 font-body text-sm text-graphite">{r.body}</p>
            </li>
          ))}
        </ul>
      )}

      <div className="mt-8">
        <ReviewForm productId={productId} />
      </div>
    </div>
  );
}
