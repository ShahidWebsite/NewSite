"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCart } from "@/lib/cart-context";
import { CatalogueDownloadButton } from "@/components/CatalogueDownloadButton";

export default function Header({ categories = [] }: { categories?: { name: string; slug: string }[] }) {
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
    <>
      {/* Top information bar (scrolls away; the floating menu below stays) */}
      <div className="bg-blacknickel font-body text-xs text-stone/75">
        <div className="mx-auto flex max-w-[1500px] flex-wrap items-center justify-between gap-x-6 gap-y-1 px-3 py-2.5">
          <span className="hidden sm:inline">218/18 Ferozepur Road, near WAPDA Hospital, Lahore</span>
          <span className="flex flex-wrap items-center gap-x-6 gap-y-1">
            <Link href="/track-order" className="hover:text-stone">Track order</Link>
            <span className="hover:text-stone"><CatalogueDownloadButton variant="link" /></span>
            <a href="tel:+923117798157" className="hover:text-stone">+92 311 7798157</a>
          </span>
        </div>
      </div>

    {/* Solid band behind the floating menu, so page content never shows
        around or through it while scrolling. */}
    <header className="sticky top-0 z-40 bg-stone px-3 pb-2 pt-3">
      <div className="mx-auto max-w-[1500px] rounded-2xl border border-nickel/30 bg-[#FBF8F2] shadow-[0_8px_24px_-12px_rgba(42,40,37,0.35)]">
      <div className="flex items-center justify-between gap-4 px-5 py-3">
        <Link href="/" className="flex items-center gap-3">
          <img src="/logo.png?v=3" alt="Shahid Iqbal & Co logo" className="h-11 w-11" />
          <span className="font-display text-2xl tracking-tight text-ink">
            Shahid Iqbal &amp; Co
          </span>
        </Link>

        <nav className="hidden items-center gap-6 font-body text-sm text-graphite lg:flex">
          <Link href="/shop" className="link-slide hover:text-ink">Shop</Link>
          {categories.slice(0, 4).map((c) => (
            <Link key={c.slug} href={`/${c.slug}`} className="link-slide hover:text-ink">{c.name}</Link>
          ))}
          <Link href="/blog" className="link-slide hover:text-ink">Guides</Link>
        </nav>

        <div className="flex items-center gap-4">
          {searchOpen ? (
            <form onSubmit={handleSearch} className="flex items-center gap-2">
              <input
                type="text"
                autoFocus
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Escape") {
                    setSearchOpen(false);
                    setQuery("");
                  }
                }}
                onBlur={() => {
                  if (!query.trim()) setSearchOpen(false);
                }}
                placeholder="Search…"
                className="w-32 border-b border-nickel/50 bg-transparent px-0.5 py-1 font-body text-sm text-ink outline-none placeholder:text-graphite/60 focus:border-ink sm:w-48"
              />
              <button
                type="button"
                onClick={() => {
                  setSearchOpen(false);
                  setQuery("");
                }}
                aria-label="Close search"
                className="text-graphite hover:text-ink"
              >
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                  <path d="M1 1L13 13M13 1L1 13" stroke="currentColor" strokeWidth="1.3" />
                </svg>
              </button>
            </form>
          ) : (
            <button
              type="button"
              onClick={() => setSearchOpen(true)}
              className="text-graphite hover:text-ink"
              aria-label="Open search"
            >
              <svg width="17" height="17" viewBox="0 0 17 17" fill="none">
                <circle cx="7" cy="7" r="5.5" stroke="currentColor" strokeWidth="1.3" />
                <path d="M11.5 11.5L15.5 15.5" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
              </svg>
            </button>
          )}
          <a
            href="https://wa.me/923117798157"
            target="_blank"
            rel="noopener noreferrer"
            className="hidden h-10 items-center gap-2 rounded-full bg-blacknickel px-5 font-body text-sm font-medium text-stone transition-colors hover:bg-ink sm:flex"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#C9A24A" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M21 11.5a8.4 8.4 0 0 1-12.4 7.4L3 20.5l1.7-5.4A8.4 8.4 0 1 1 21 11.5z" />
            </svg>
            WhatsApp
          </a>
          <Link
            href="/cart"
            className="flex h-10 items-center gap-2 rounded-full border border-nickel/40 px-4 font-body text-sm text-ink transition-colors hover:border-brass hover:text-brass"
          >
            Cart
            {itemCount > 0 && (
              <span key={itemCount} className="bump inline-block">{` (${itemCount})`}</span>
            )}
          </Link>
          <button
            type="button"
            onClick={() => setMenuOpen((v) => !v)}
            className="flex h-9 w-9 flex-col items-center justify-center gap-1.5 lg:hidden"
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
        <nav className="menu-in flex flex-col gap-1 border-t border-nickel/20 px-6 py-4 font-body text-sm text-graphite lg:hidden">
          <Link href="/shop" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Shop</Link>
          {categories.map((c) => (
            <Link key={c.slug} href={`/${c.slug}`} onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">{c.name}</Link>
          ))}
          <Link href="/blog" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Guides</Link>
          <Link href="/track-order" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Track order</Link>
          <Link href="/contact" onClick={() => setMenuOpen(false)} className="py-2 hover:text-ink">Contact</Link>
        </nav>
      )}
      </div>
    </header>
    </>
  );
}