"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCart } from "@/lib/cart-context";

export default function Header() {
  const { lines } = useCart();
  const router = useRouter();
  const itemCount = lines.reduce((sum, l) => sum + l.quantity, 0);
  const [menuOpen, setMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [query, setQuery] = useState("");

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    const q = query.trim();
    setSearchOpen(false);
    setMenuOpen(false);
    router.push(q ? `/shop?q=${encodeURIComponent(q)}` : "/shop");
  }

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
          <button
            type="button"
            onClick={() => setSearchOpen((v) => !v)}
            className="font-body text-sm text-graphite hover:text-ink"
            aria-label="Toggle search"
            aria-expanded={searchOpen}
          >
            Search
          </button>
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

      {searchOpen && (
        <form onSubmit={handleSearch} className="border-t border-nickel/20 px-6 py-4">
          <input
            type="text"
            autoFocus
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search handles, knobs, pulls…"
            className="w-full max-w-md border border-nickel/40 px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
          />
        </form>
      )}

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
