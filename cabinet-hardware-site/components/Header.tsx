"use client";

import Link from "next/link";
import { useCart } from "@/lib/cart-context";

export default function Header() {
  const { lines } = useCart();
  const itemCount = lines.reduce((sum, l) => sum + l.quantity, 0);

  return (
    <header className="border-b border-nickel/30">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Link href="/" className="flex items-center gap-3">
          <img src="/logo.png" alt="Shahid Iqbal & Co logo" className="h-11 w-11" />
          <span>
            <span className="block font-display text-2xl leading-tight tracking-tight text-ink">
              Shahid Iqbal &amp; Co
            </span>
            <span className="block font-body text-xs text-graphite">
              Cabinet Handles &amp; Knobs
            </span>
          </span>
        </Link>

        <nav className="hidden items-center gap-8 font-body text-sm text-graphite md:flex">
          <Link href="/shop" className="hover:text-ink">Shop</Link>
          <Link href="/shop?category=cabinet-handles" className="hover:text-ink">Handles</Link>
          <Link href="/shop?category=cabinet-knobs" className="hover:text-ink">Knobs</Link>
          <Link href="/track-order" className="hover:text-ink">Track order</Link>
        </nav>

        <Link
          href="/cart"
          className="font-body text-sm text-ink underline decoration-nickel decoration-1 underline-offset-4 hover:decoration-brass"
        >
          Cart{itemCount > 0 ? ` (${itemCount})` : ""}
        </Link>
      </div>
    </header>
  );
}
