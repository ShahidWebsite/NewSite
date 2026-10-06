import Link from "next/link";
import { REGIONS, WHOLESALE_HUB_SLUG } from "@/lib/regions";

export default function Footer({ categories = [] }: { categories?: { name: string; slug: string }[] }) {
  return (
    <footer className="px-3 pb-6 pt-16">
      <div className="mx-auto max-w-[1500px] rounded-2xl bg-blacknickel px-8 py-14 text-stone shadow-lg md:px-12">
        <div className="grid gap-10 sm:grid-cols-2 md:grid-cols-4">
          <div>
            <div className="flex items-center gap-3">
              <img src="/logo.png?v=3" alt="Shahid Iqbal & Co logo" className="h-10 w-10" />
              <p className="font-display text-xl">Shahid Iqbal &amp; Co</p>
            </div>
            <p className="mt-3 max-w-prose font-body text-sm text-stone/70">
              Dream Hardware at your Door Step — wholesale and retail cabinet
              handles, knobs, door handles and furniture pulls from Lahore,
              specialized in brass. Serving hardware shops across Pakistan.
            </p>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Shop</p>
            <ul className="space-y-2">
              <li><Link href="/shop" className="hover:text-brass">All products</Link></li>
              {categories.map((c) => (
                <li key={c.slug}>
                  <Link href={`/${c.slug}`} className="hover:text-brass">{c.name}</Link>
                </li>
              ))}
              <li><Link href={`/blog/${WHOLESALE_HUB_SLUG}`} className="hover:text-brass">Wholesale supplier</Link></li>
              <li><Link href="/blog" className="hover:text-brass">Guides &amp; tips</Link></li>
              <li><Link href="/track-order" className="hover:text-brass">Track an order</Link></li>
              <li><Link href="/about" className="hover:text-brass">About us</Link></li>
              <li><Link href="/contact" className="hover:text-brass">Contact &amp; bulk enquiries</Link></li>
            </ul>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Policies</p>
            <ul className="space-y-2">
              <li><Link href="/shipping" className="hover:text-brass">Shipping</Link></li>
              <li><Link href="/returns" className="hover:text-brass">Returns &amp; Exchanges</Link></li>
              <li><Link href="/privacy" className="hover:text-brass">Privacy Policy</Link></li>
              <li><Link href="/terms" className="hover:text-brass">Terms of Service</Link></li>
            </ul>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Get in touch</p>
            <ul className="space-y-2 text-stone/80">
              <li>WhatsApp / Call: +92 311 7798157</li>
              <li>218/18 Ferozepur Road, near WAPDA Hospital, Lahore</li>
              <li>
                <a href="https://www.facebook.com/siqbalhwc" className="hover:text-brass" target="_blank" rel="noopener noreferrer">
                  facebook.com/siqbalhwc
                </a>
              </li>
              <li>
                <a href="https://www.instagram.com/siqbalco" className="hover:text-brass" target="_blank" rel="noopener noreferrer">
                  Instagram: @siqbalco
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-10 border-t border-stone/10 pt-6 font-body text-xs text-stone/60">
          <p className="mb-2 text-stone/50">We supply from Lahore to</p>
          <ul className="flex flex-wrap gap-x-5 gap-y-1">
            {REGIONS.map((r) => (
              <li key={r.slug}>
                <Link href={`/blog/${r.slug}`} className="hover:text-brass">{r.name}</Link>
              </li>
            ))}
          </ul>
        </div>

        <p className="mt-6 border-t border-stone/10 pt-6 font-body text-xs text-stone/40">
          © {new Date().getFullYear()} Shahid Iqbal &amp; Co. All rights reserved.
        </p>
      </div>
    </footer>
  );
}