import Link from "next/link";

export default function Footer() {
  return (
    <footer className="mt-24 bg-blacknickel text-stone">
      <div className="mx-auto max-w-6xl px-6 py-14">
        <div className="grid gap-10 md:grid-cols-3">
          <div>
            <div className="flex items-center gap-3">
              <img src="/logo.png" alt="Shahid Iqbal & Co logo" className="h-10 w-10" />
              <p className="font-display text-xl">Shahid Iqbal &amp; Co</p>
            </div>
            <p className="mt-3 max-w-prose font-body text-sm text-stone/70">
              Dream Hardware at your Door Step — door handles, cabinet
              handles, knobs, and furniture pulls, specialized in brass.
            </p>
          </div>

          <div className="font-body text-sm">
            <p className="mb-3 text-stone/50">Shop</p>
            <ul className="space-y-2">
              <li><Link href="/shop" className="hover:text-brass">All products</Link></li>
              <li><Link href="/track-order" className="hover:text-brass">Track an order</Link></li>
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

        <p className="mt-12 border-t border-stone/10 pt-6 font-body text-xs text-stone/40">
          © {new Date().getFullYear()} Shahid Iqbal &amp; Co. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
