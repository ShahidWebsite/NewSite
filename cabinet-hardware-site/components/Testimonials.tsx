import { supabase } from "@/lib/supabase";
import { Review } from "@/lib/types";
import Reveal from "@/components/Reveal";

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
    <section className="mx-auto max-w-[1500px] px-3 py-20">
      <Reveal>
        <p className="font-body text-sm text-brass">Customer stories</p>
        <h2 className="mt-2 font-display text-3xl text-ink">What customers say</h2>
      </Reveal>

      <div className="mt-10 grid gap-6 sm:grid-cols-2 md:grid-cols-3">
        {reviews.map((r, i) => (
          <Reveal key={r.id} delay={i * 80}>
            <div className="group relative flex h-full flex-col border border-nickel/25 bg-white/60 p-6 transition-all duration-300 hover:-translate-y-1 hover:border-brass/60 hover:shadow-[0_12px_30px_-15px_rgba(42,40,37,0.25)]">
              <span
                aria-hidden="true"
                className="font-display text-5xl leading-none text-brass/25 transition-colors duration-300 group-hover:text-brass/40"
              >
                &ldquo;
              </span>
              <p className="text-rust" aria-label={`${r.rating} out of 5 stars`}>
                {"★".repeat(r.rating)}
                <span className="text-nickel/40">{"★".repeat(5 - r.rating)}</span>
              </p>
              <p className="mt-3 flex-1 font-body text-sm leading-relaxed text-graphite">{r.body}</p>
              <div className="mt-5 flex items-center gap-3 border-t border-nickel/15 pt-4">
                <span className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-blacknickel font-display text-sm text-brass">
                  {r.customer_name.charAt(0)}
                </span>
                <p className="font-body text-xs text-ink">{r.customer_name}</p>
              </div>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
