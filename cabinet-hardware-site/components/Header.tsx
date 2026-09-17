"use client";

import { useState } from "react";
import Link from "next/link";
import { useCart } from "@/lib/cart-context";

export default function Header() {
  const { lines } = useCart();
  const itemCount = lines.reduce((sum, l) => sum + l.quantity, 0);
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="border-b border-nickel/30">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Link href="/" className="flex items-center gap-3">
          <img src="/logo.png?v=2" alt="Shahid Iqbal & Co logo" className="h-11 w-11" />
          <span className="font-display text-2xl tracking-tight text-ink">
            Shahid Iqbal &amp; Co
          </span>
        </Link>

        <nav className="hidden items-center gap-8 font-body text-sm text-graphite md:flex">
          <Link href="/shop" className="hover:text-ink">Shop</Link>
          <Link href="/shop?category=cabinet-handles" className="hover:text-ink">Handles</Link>
          <Link href="/shop?category=cabinet-knobs" className="hover:text-ink">Knobs</Link>
          <Link href="/track-order" className="hover:text-ink">Track order</Link>
        </nav>

        <div className="flex items-center gap-4">
          <Link
            href="/cart"
            className="font-body text-sm text-ink underline decoration-nickel decoration-1 underline-offset-4 hover:decoration-brass"
          >
            Cart{itemCount > 0 ? ` (${itemCount})` : ""}
          </Link>
          <button
            type="button"
            onClick={() => setMenuOpen((v) => !v)}
            className="flex h-9 w-9 flex-col items-center justify-center gap-1.5 md:hidden"
            aria-label="Toggle menu"
            aria-expanded={menuOpen}
          >
            <span className="block h-px w-5 bg-ink" />
            <span className="block h-px w-5 bg-ink" />
            <span className="block h-px w-5 bg-ink" />
          </button>
        </div>
      </div>

      {menuOpen && (
        <nav className="flex flex-col gap-1 border-t border-nickel/20 px-6 py-4 font-body text-sm text-graphite md:hidden">
          <Link href="/shop" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Shop</Link>
          <Link href="/shop?category=cabinet-handles" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Handles</Link>
          <Link href="/shop?category=cabinet-knobs" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Knobs</Link>
          <Link href="/track-order" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Track order</Link>
        </nav>
      )}
    </header>
  );
}
