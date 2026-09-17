import { supabase } from "@/lib/supabase";
import { Review } from "@/lib/types";

export default async function Testimonials() {
  const { data } = await supabase
    .from("reviews")
    .select("*")
    .is("product_id", null)
    .eq("approved", true)
    .order("created_at", { ascending: false })
    .limit(6);

  const reviews = (data ?? []) as Review[];
  if (reviews.length === 0) return null;

  return (
    <section className="mx-auto max-w-6xl px-6 py-20">
      <h2 className="font-display text-3xl text-ink">What customers say</h2>
      <div className="mt-8 grid gap-x-6 gap-y-10 sm:grid-cols-2 md:grid-cols-3">
        {reviews.map((r) => (
          <div key={r.id}>
            <p className="text-rust" aria-hidden="true">
              {"★".repeat(r.rating)}
              <span className="text-nickel/40">{"★".repeat(5 - r.rating)}</span>
            </p>
            <p className="mt-2 font-body text-sm text-graphite">&ldquo;{r.body}&rdquo;</p>
            <p className="mt-3 font-body text-xs text-ink">{r.customer_name}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
