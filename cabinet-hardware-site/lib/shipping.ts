// Weight-based COD shipping via Leopard Courier.
//
// How it works: every product stores its shipping weight in grams
// (`weight_grams`). At checkout, we sum weight × quantity across the cart,
// then apply the store's rate card (editable in /admin/shipping-settings)
// to work out the courier fee. The same number is charged whether the
// customer pays by bank transfer (added to the bank total) or COD (collected
// by the Leopard rider along with the product price).
//
// This is only ever computed SERVER-SIDE at order time (see
// app/api/orders/create/route.ts) — the client-side estimate shown at
// checkout is for the customer's information only and is never trusted.

export type ShippingSettings = {
  base_fee: number; // flat dispatch/handling fee, charged once per order
  per_kg_rate: number; // charged per billable kg on top of the base fee
  courier_name?: string;
};

export const DEFAULT_SHIPPING_SETTINGS: ShippingSettings = {
  base_fee: 150,
  per_kg_rate: 100,
  courier_name: "the courier",
};

// Products created before a weight was recorded fall back to this so
// shipping still calculates something reasonable instead of zero.
export const FALLBACK_ITEM_WEIGHT_GRAMS = 300;

// Couriers bill by rounded-up kg, not the exact gram weight — this mirrors
// that so the estimate shown to the customer matches what Leopard actually
// charges.
export function calculateShippingFee(totalWeightGrams: number, settings: ShippingSettings): number {
  const billableKg = Math.max(1, Math.ceil(totalWeightGrams / 1000));
  return Math.round(settings.base_fee + billableKg * settings.per_kg_rate);
}

// Converts the admin's free-text "Weight" spec (e.g. "500", unit "g"/"kg")
// into a plain integer grams value for the dedicated weight_grams column.
export function weightToGrams(weight: string, unit: string): number | null {
  const n = Number(weight.trim());
  if (!weight.trim() || Number.isNaN(n) || n <= 0) return null;
  return Math.round(unit === "kg" ? n * 1000 : n);
}