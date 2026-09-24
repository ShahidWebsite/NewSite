"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { calculateShippingFee } from "@/lib/shipping";

export default function AdminShippingSettingsPage() {
  const [baseFee, setBaseFee] = useState("150");
  const [perKgRate, setPerKgRate] = useState("100");
  const [courierName, setCourierName] = useState("Leopard Courier");
  const [loading, setLoading] = useState(true);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    const { data } = await supabase.from("shipping_settings").select("*").single();
    if (data) {
      setBaseFee(String(data.base_fee));
      setPerKgRate(String(data.per_kg_rate));
      setCourierName(data.courier_name);
    }
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function handleSave() {
    setError(null);
    const base = Number(baseFee);
    const perKg = Number(perKgRate);
    if (Number.isNaN(base) || base < 0 || Number.isNaN(perKg) || perKg < 0) {
      setError("Base fee and per-kg rate must be numbers, 0 or more.");
      return;
    }
    const { error } = await supabase
      .from("shipping_settings")
      .update({ base_fee: base, per_kg_rate: perKg, courier_name: courierName.trim() || "Leopard Courier" })
      .eq("id", 1);
    if (error) {
      setError(error.message);
      return;
    }
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  }

  const previewWeights = [500, 1000, 2500, 5000];

  return (
    <div className="max-w-2xl">
      <h1 className="font-display text-3xl text-ink">Shipping (Cash on Delivery)</h1>
      <p className="mt-2 font-body text-sm text-graphite">
        Used to calculate the COD shipping fee charged on top of the product price — collected
        by {courierName || "the courier"} on delivery. Also shown to bank-transfer customers as
        part of their total. Weight comes from each product&rsquo;s &ldquo;Weight&rdquo; field in
        the product form.
      </p>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : (
        <>
          <div className="mt-8 grid gap-4 border border-nickel/25 p-5 sm:grid-cols-2">
            <label className="block">
              <span className="font-body text-xs text-graphite">Courier name</span>
              <input
                value={courierName}
                onChange={(e) => setCourierName(e.target.value)}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
              />
            </label>
            <div />
            <label className="block">
              <span className="font-body text-xs text-graphite">Base / dispatch fee (Rs.)</span>
              <input
                type="number"
                min={0}
                value={baseFee}
                onChange={(e) => setBaseFee(e.target.value)}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
              />
              <span className="mt-1 block font-body text-xs text-graphite/70">Charged once per order</span>
            </label>
            <label className="block">
              <span className="font-body text-xs text-graphite">Rate per kg (Rs.)</span>
              <input
                type="number"
                min={0}
                value={perKgRate}
                onChange={(e) => setPerKgRate(e.target.value)}
                className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
              />
              <span className="mt-1 block font-body text-xs text-graphite/70">
                Rounded up to the next full kg, minimum 1kg per order
              </span>
            </label>
          </div>

          {error && <p className="mt-3 font-body text-sm text-rust">{error}</p>}

          <button
            onClick={handleSave}
            className="mt-4 bg-ink px-4 py-2 font-body text-sm text-stone hover:bg-brass"
          >
            {saved ? "Saved ✓" : "Save"}
          </button>

          <div className="mt-10">
            <p className="font-body text-sm text-ink">Preview</p>
            <div className="mt-3 divide-y divide-nickel/20 border-y border-nickel/20 font-body text-sm">
              {previewWeights.map((g) => (
                <div key={g} className="flex justify-between py-2">
                  <span className="text-graphite">{g >= 1000 ? `${g / 1000}kg` : `${g}g`} order</span>
                  <span className="text-ink">
                    Rs. {calculateShippingFee(g, { base_fee: Number(baseFee) || 0, per_kg_rate: Number(perKgRate) || 0 }).toLocaleString()}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}