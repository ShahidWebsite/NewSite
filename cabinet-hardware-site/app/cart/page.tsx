"use client";

import Link from "next/link";
import Image from "next/image";
import { useCart } from "@/lib/cart-context";

export default function CartPage() {
  const { lines, updateQuantity, removeLine, subtotal } = useCart();

  if (lines.length === 0) {
    return (
      <div className="mx-auto max-w-2xl px-6 py-24 text-center">
        <h1 className="font-display text-3xl text-ink">Your cart is empty</h1>
        <p className="mt-3 font-body text-graphite">Nothing added yet — browse the catalog to get started.</p>
        <Link
          href="/shop"
          className="mt-8 inline-block bg-ink px-6 py-3 font-body text-sm text-stone hover:bg-brass"
        >
          Shop all products
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Your cart</h1>

      <div className="mt-8 divide-y divide-nickel/20">
        {lines.map((line) => (
          <div key={line.variantId} className="flex flex-wrap items-center gap-4 py-5">
            <div className="relative h-20 w-20 flex-shrink-0 bg-nickel/10">
              {line.imageUrl && (
                <Image src={line.imageUrl} alt={line.productName} fill sizes="80px" className="object-cover" />
              )}
            </div>
            <div className="flex-1">
              <Link href={`/products/${line.productSlug}`} className="font-body text-ink hover:underline">
                {line.productName}
              </Link>
              <p className="font-body text-sm text-graphite">{line.variantLabel}</p>
              <p className="mt-1 font-body text-sm text-ink">Rs. {line.unitPrice.toLocaleString()}</p>
            </div>
            <div className="flex items-center border border-nickel/50">
              <button
                onClick={() => updateQuantity(line.variantId, line.quantity - 1)}
                className="px-2 py-1 text-ink hover:bg-nickel/10"
                aria-label="Decrease quantity"
              >
                −
              </button>
              <span className="w-8 text-center font-body text-sm">{line.quantity}</span>
              <button
                onClick={() => updateQuantity(line.variantId, line.quantity + 1)}
                className="px-2 py-1 text-ink hover:bg-nickel/10"
                aria-label="Increase quantity"
              >
                +
              </button>
            </div>
            <button
              onClick={() => removeLine(line.variantId)}
              className="font-body text-sm text-graphite hover:text-rust"
            >
              Remove
            </button>
          </div>
        ))}
      </div>

      <div className="mt-8 flex items-center justify-between border-t border-nickel/30 pt-6">
        <p className="font-body text-graphite">Subtotal</p>
        <p className="font-display text-2xl text-ink">Rs. {subtotal.toLocaleString()}</p>
      </div>

      <Link
        href="/checkout"
        className="mt-6 block bg-ink py-3 text-center font-body text-sm text-stone hover:bg-brass"
      >
        Proceed to checkout
      </Link>
    </div>
  );
}
