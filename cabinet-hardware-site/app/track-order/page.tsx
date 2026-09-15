"use client";

import { Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";

const STATUS_STEPS = ["processing", "packed", "shipped", "delivered"];

export default function TrackOrderPage() {
  return (
    <Suspense fallback={<div className="mx-auto max-w-2xl px-6 py-16 font-body text-graphite">Loading…</div>}>
      <TrackOrderForm />
    </Suspense>
  );
}

function TrackOrderForm() {
  const searchParams = useSearchParams();
  const [orderNumber, setOrderNumber] = useState(searchParams.get("orderNumber") ?? "");
  const [email, setEmail] = useState("");
  const [order, setOrder] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setOrder(null);

    try {
      const res = await fetch(
        `/api/orders/track?orderNumber=${encodeURIComponent(orderNumber)}&email=${encodeURIComponent(email)}`
      );
      const data = await res.json();
      if (!res.ok) {
        setError(data.error);
        return;
      }
      setOrder(data.order);
    } catch {
      setError("Could not reach the server. Try again in a moment.");
    } finally {
      setLoading(false);
    }
  }

  const currentStepIndex = order ? STATUS_STEPS.indexOf(order.fulfillment_status) : -1;

  return (
    <div className="mx-auto max-w-2xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Track your order</h1>
      <p className="mt-3 font-body text-graphite">
        Enter your order number and the email you checked out with.
      </p>

      <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-4 sm:flex-row">
        <input
          value={orderNumber}
          onChange={(e) => setOrderNumber(e.target.value)}
          placeholder="Order number (e.g. ORD-1001)"
          required
          className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink focus:border-ink"
        />
        <input
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          type="email"
          placeholder="Email used at checkout"
          required
          className="flex-1 border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink focus:border-ink"
        />
        <button
          type="submit"
          disabled={loading}
          className="bg-ink px-6 py-2 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
        >
          {loading ? "Looking up…" : "Track"}
        </button>
      </form>

      {error && <p className="mt-6 font-body text-sm text-rust">{error}</p>}

      {order && (
        <div className="mt-10 border border-nickel/30 p-6">
          <div className="flex items-baseline justify-between">
            <p className="font-display text-2xl text-ink">{order.order_number}</p>
            <p className="font-body text-sm text-graphite">
              Payment: <span className="text-ink">{order.payment_status}</span>
            </p>
          </div>

          <div className="mt-6 flex justify-between">
            {STATUS_STEPS.map((step, i) => (
              <div key={step} className="flex-1 text-center">
                <div
                  className={`mx-auto h-2 w-2 rounded-full ${
                    i <= currentStepIndex ? "bg-brass" : "bg-nickel/30"
                  }`}
                />
                <p
                  className={`mt-2 font-body text-xs capitalize ${
                    i <= currentStepIndex ? "text-ink" : "text-graphite"
                  }`}
                >
                  {step}
                </p>
              </div>
            ))}
          </div>

          <div className="mt-8 divide-y divide-nickel/20 border-t border-nickel/20">
            {order.order_items.map((item: any) => (
              <div key={item.id} className="flex justify-between py-3 font-body text-sm">
                <span className="text-ink">
                  {item.product_name} — {item.variant_label}{" "}
                  <span className="text-graphite">× {item.quantity}</span>
                </span>
                <span className="text-ink">Rs. {(item.unit_price * item.quantity).toLocaleString()}</span>
              </div>
            ))}
          </div>

          <div className="mt-4 flex justify-between font-body">
            <span className="text-graphite">Total</span>
            <span className="text-ink">Rs. {order.total.toLocaleString()}</span>
          </div>
        </div>
      )}
    </div>
  );
}
