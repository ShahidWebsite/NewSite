"use client";

import { useMemo, useState } from "react";
import { Attribute, Variant } from "@/lib/types";
import StockBadge from "./StockBadge";
import { useCart } from "@/lib/cart-context";

export default function VariantSelector({
  productId,
  productName,
  productSlug,
  imageUrl,
  attributes,
  variants,
}: {
  productId: string;
  productName: string;
  productSlug: string;
  imageUrl: string | null;
  attributes: Attribute[];
  variants: Variant[];
}) {
  const { addLine } = useCart();

  // Track which value is picked for each attribute, e.g. { "Finish": "<id>", "Size": "<id>" }
  const [selected, setSelected] = useState<Record<string, string>>(() => {
    const initial: Record<string, string> = {};
    for (const attr of attributes) {
      if (attr.values.length > 0) initial[attr.id] = attr.values[0].id;
    }
    return initial;
  });
  const [quantity, setQuantity] = useState(1);
  const [justAdded, setJustAdded] = useState(false);

  const matchedVariant = useMemo(() => {
    const selectedIds = Object.values(selected);
    return variants.find(
      (v) =>
        v.attribute_value_ids.length === selectedIds.length &&
        selectedIds.every((id) => v.attribute_value_ids.includes(id))
    );
  }, [selected, variants]);

  function pickValue(attributeId: string, valueId: string) {
    setSelected((prev) => ({ ...prev, [attributeId]: valueId }));
    setJustAdded(false);
  }

  function handleAddToCart() {
    if (!matchedVariant) return;
    const label = attributes
      .map((attr) => attr.values.find((v) => v.id === selected[attr.id])?.value)
      .filter(Boolean)
      .join(" / ");

    addLine({
      productId,
      productName,
      productSlug,
      variantId: matchedVariant.id,
      variantLabel: label,
      unitPrice: matchedVariant.price,
      quantity,
      imageUrl,
    });
    setJustAdded(true);
  }

  return (
    <div className="space-y-6">
      {attributes.map((attr) => (
        <div key={attr.id}>
          <p className="mb-2 font-body text-sm text-graphite">{attr.name}</p>
          <div className="flex flex-wrap gap-2">
            {attr.values.map((val) => {
              const isSelected = selected[attr.id] === val.id;
              return (
                <button
                  key={val.id}
                  type="button"
                  onClick={() => pickValue(attr.id, val.id)}
                  className={`flex items-center gap-2 border px-3 py-2 font-body text-sm transition-colors ${
                    isSelected
                      ? "border-ink bg-ink text-stone"
                      : "border-nickel/50 text-ink hover:border-ink"
                  }`}
                >
                  {val.swatch_hex && (
                    <span
                      className="h-3 w-3 rounded-full border border-black/10"
                      style={{ backgroundColor: val.swatch_hex }}
                    />
                  )}
                  {val.value}
                </button>
              );
            })}
          </div>
        </div>
      ))}

      <div className="flex items-center justify-between border-t border-nickel/30 pt-5">
        <div>
          <p className="font-display text-2xl text-ink">
            {matchedVariant ? `Rs. ${matchedVariant.price.toLocaleString()}` : "Select options"}
          </p>
          {matchedVariant && <StockBadge stockQty={matchedVariant.stock_qty} />}
        </div>

        <div className="flex items-center border border-nickel/50">
          <button
            type="button"
            onClick={() => setQuantity((q) => Math.max(1, q - 1))}
            className="px-3 py-2 font-body text-ink hover:bg-nickel/10"
            aria-label="Decrease quantity"
          >
            −
          </button>
          <span className="w-8 text-center font-body text-ink">{quantity}</span>
          <button
            type="button"
            onClick={() => setQuantity((q) => q + 1)}
            className="px-3 py-2 font-body text-ink hover:bg-nickel/10"
            aria-label="Increase quantity"
          >
            +
          </button>
        </div>
      </div>

      <button
        type="button"
        onClick={handleAddToCart}
        disabled={!matchedVariant || matchedVariant.stock_qty <= 0}
        className="w-full bg-ink py-3 font-body text-sm text-stone transition-colors hover:bg-brass disabled:cursor-not-allowed disabled:bg-nickel/50"
      >
        {!matchedVariant
          ? "Select options to continue"
          : matchedVariant.stock_qty <= 0
          ? "Out of stock"
          : justAdded
          ? "Added to cart ✓"
          : "Add to cart"}
      </button>
    </div>
  );
}
