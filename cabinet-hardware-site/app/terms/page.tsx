import { Metadata } from "next";

export const metadata: Metadata = { title: "Terms of Service — Shahid Iqbal & Co" };

export default function TermsPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Terms of Service</h1>
      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>Last updated: {new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}</p>
        <div>
          <h2 className="font-display text-xl text-ink">Orders</h2>
          <p className="mt-2">
            Placing an order on this site is an offer to purchase, which we confirm once
            payment is received. Prices are shown in Pakistani Rupees (PKR) and may change
            without notice, though a price shown at checkout will be honoured for that order.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Payment</h2>
          <p className="mt-2">
            We currently accept bank transfer only. Orders are processed once payment is
            confirmed against the order reference provided at checkout.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Product information</h2>
          <p className="mt-2">
            We aim for every listing's size, finish, material, and hole-spacing specs to be
            accurate. Colors may vary slightly from photos due to screen display differences.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Shipping &amp; returns</h2>
          <p className="mt-2">
            See our{" "}
            <a href="/shipping" className="text-ink underline hover:text-brass">Shipping Policy</a>
            {" "}and{" "}
            <a href="/returns" className="text-ink underline hover:text-brass">Returns &amp; Exchanges</a>
            {" "}pages for details.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Contact</h2>
          <p className="mt-2">
            Shahid Iqbal &amp; Co, 218/18 Ferozepur Road, near WAPDA Hospital, Lahore,
            Pakistan. WhatsApp / Call: +92 311 7798157.
          </p>
        </div>
      </div>
    </div>
  );
}
