"use client";

import { useState } from "react";
import Link from "next/link";
import { useCart } from "@/lib/cart-context";
import { BankSettings } from "@/lib/types";

export default function CheckoutPage() {
  const { lines, subtotal, clear } = useCart();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmation, setConfirmation] = useState<{
    orderNumber: string;
    total: number;
    bankSettings: BankSettings;
  } | null>(null);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    const form = new FormData(e.currentTarget);
    const payload = {
      customerName: form.get("customerName"),
      email: form.get("email"),
      phone: form.get("phone"),
      shippingAddress: {
        line1: form.get("line1"),
        line2: form.get("line2"),
        city: form.get("city"),
        region: form.get("region"),
        postal_code: form.get("postal_code"),
        country: form.get("country"),
      },
      lines: lines.map((l) => ({ variantId: l.variantId, quantity: l.quantity })),
    };

    try {
      const res = await fetch("/api/orders/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Something went wrong placing your order.");
        return;
      }

      setConfirmation(data);
      clear();
    } catch {
      setError("Could not reach the server. Check your connection and try again.");
    } finally {
      setSubmitting(false);
    }
  }

  if (confirmation) {
    return (
      <div className="mx-auto max-w-xl px-6 py-20">
        <p className="font-body text-sm text-olive">Order placed</p>
        <h1 className="mt-2 font-display text-4xl text-ink">Thank you</h1>
        <p className="mt-3 font-body text-graphite">
          Your order number is <span className="text-ink">{confirmation.orderNumber}</span>. Save
          this to track your order later.
        </p>

        <div className="mt-8 border border-nickel/30 p-6">
          <p className="font-body text-sm text-graphite">Complete your payment by bank transfer</p>
          <dl className="mt-4 space-y-2 font-body text-sm">
            <Row label="Account title" value={confirmation.bankSettings.account_title} />
            <Row label="Bank" value={confirmation.bankSettings.bank_name} />
            <Row label="Account number" value={confirmation.bankSettings.account_number} />
            <Row label="IFSC / Routing" value={confirmation.bankSettings.ifsc_or_routing} />
            <Row label="Amount" value={`Rs. ${confirmation.total.toLocaleString()}`} />
          </dl>
          <p className="mt-4 font-body text-sm text-graphite">{confirmation.bankSettings.instructions}</p>
        </div>

        <Link
          href={`/track-order?orderNumber=${confirmation.orderNumber}`}
          className="mt-8 block bg-ink py-3 text-center font-body text-sm text-stone hover:bg-brass"
        >
          Track this order
        </Link>
      </div>
    );
  }

  if (lines.length === 0) {
    return (
      <div className="mx-auto max-w-xl px-6 py-24 text-center">
        <p className="font-body text-graphite">Your cart is empty.</p>
        <Link href="/shop" className="mt-4 inline-block font-body text-sm text-ink underline">
          Continue shopping
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Checkout</h1>

      <form onSubmit={handleSubmit} className="mt-8 grid gap-8 md:grid-cols-2">
        <div className="space-y-4">
          <h2 className="font-body text-sm text-graphite">Contact & shipping</h2>
          <Field name="customerName" label="Full name" required />
          <Field name="email" label="Email" type="email" required />
          <Field name="phone" label="Phone" required />
          <Field name="line1" label="Address line 1" required />
          <Field name="line2" label="Address line 2" />
          <div className="grid grid-cols-2 gap-4">
            <Field name="city" label="City" required />
            <Field name="region" label="Province/State" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Field name="postal_code" label="Postal code" />
            <Field name="country" label="Country" required />
          </div>
        </div>

        <div>
          <h2 className="font-body text-sm text-graphite">Order summary</h2>
          <div className="mt-4 divide-y divide-nickel/20 border-y border-nickel/20">
            {lines.map((line) => (
              <div key={line.variantId} className="flex justify-between py-3 font-body text-sm">
                <span className="text-ink">
                  {line.productName} <span className="text-graphite">× {line.quantity}</span>
                </span>
                <span className="text-ink">Rs. {(line.unitPrice * line.quantity).toLocaleString()}</span>
              </div>
            ))}
          </div>
          <div className="mt-4 flex justify-between font-body">
            <span className="text-graphite">Total</span>
            <span className="text-ink">Rs. {subtotal.toLocaleString()}</span>
          </div>

          <p className="mt-6 font-body text-sm text-graphite">
            Payment is by bank transfer. Account details will be shown once
            your order is placed.
          </p>

          {error && <p className="mt-4 font-body text-sm text-rust">{error}</p>}

          <button
            type="submit"
            disabled={submitting}
            className="mt-6 w-full bg-ink py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
          >
            {submitting ? "Placing order…" : "Place order"}
          </button>
        </div>
      </form>
    </div>
  );
}

function Field({
  name,
  label,
  type = "text",
  required = false,
}: {
  name: string;
  label: string;
  type?: string;
  required?: boolean;
}) {
  return (
    <label className="block">
      <span className="font-body text-sm text-graphite">{label}</span>
      <input
        name={name}
        type={type}
        required={required}
        className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink focus:border-ink"
      />
    </label>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <dt className="text-graphite">{label}</dt>
      <dd className="text-ink">{value}</dd>
    </div>
  );
}
