"use client";

import { useState } from "react";

export default function ContactForm() {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    const form = new FormData(e.currentTarget);
    const payload = {
      name: form.get("name"),
      phone: form.get("phone"),
      email: form.get("email"),
      message: form.get("message"),
      enquiryType: form.get("enquiryType"),
    };

    try {
      const res = await fetch("/api/enquiries/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || "Something went wrong sending your message.");
        return;
      }
      setSent(true);
    } catch {
      setError("Could not reach the server. Please try WhatsApp instead.");
    } finally {
      setSubmitting(false);
    }
  }

  if (sent) {
    return (
      <div className="border border-nickel/30 p-6">
        <p className="font-display text-xl text-ink">Message sent</p>
        <p className="mt-2 font-body text-sm text-graphite">
          Thanks — we&rsquo;ve got your message and will get back to you on WhatsApp or phone
          shortly.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <label className="block">
        <span className="font-body text-sm text-graphite">I&rsquo;m enquiring about</span>
        <select
          name="enquiryType"
          defaultValue="general"
          className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink outline-none focus:border-ink"
        >
          <option value="general">A general question</option>
          <option value="bulk_wholesale">Bulk / wholesale pricing</option>
        </select>
      </label>

      <Field name="name" label="Full name" required />
      <Field name="phone" label="Phone / WhatsApp number" required />
      <Field name="email" label="Email (optional)" type="email" />

      <label className="block">
        <span className="font-body text-sm text-graphite">Message</span>
        <textarea
          name="message"
          required
          rows={5}
          placeholder="Products, finishes, quantities, or your question…"
          className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink outline-none placeholder:text-graphite/50 focus:border-ink"
        />
      </label>

      {error && <p className="font-body text-sm text-rust">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="w-full bg-ink py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
      >
        {submitting ? "Sending…" : "Send message"}
      </button>
    </form>
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
        className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink outline-none focus:border-ink"
      />
    </label>
  );
}