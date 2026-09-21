import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata({
  title: 'Shipping & Delivery Across Pakistan | Shahid Iqbal & Co',
  description:
    'How we pack and deliver door handles, cabinet handles and knobs from Lahore across Pakistan, and how to track your order.',
  path: '/shipping',
});

export default function ShippingPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Shipping Policy</h1>
      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>
          <strong className="text-ink">Editor's note (remove this box once reviewed):</strong>{" "}
          This is a starting draft so the page exists and isn't blank — please confirm actual
          courier, timelines, and charges with the owner and edit the placeholders below
          before publishing.
        </p>
        <div>
          <h2 className="font-display text-xl text-ink">Processing time</h2>
          <p className="mt-2">
            Orders are typically packed and handed to courier within [1–2 business days] of
            payment confirmation.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Delivery time &amp; charges</h2>
          <p className="mt-2">
            Within Lahore: [delivery estimate]. Nationwide (rest of Pakistan): [delivery
            estimate]. Shipping charges, if any, are shown at checkout before you confirm your
            order.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Order tracking</h2>
          <p className="mt-2">
            Once your order ships, you can check its status anytime on the{" "}
            <a href="/track-order" className="text-ink underline hover:text-brass">
              Track an order
            </a>{" "}
            page using your order number and email.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Questions</h2>
          <p className="mt-2">
            For anything shipping-related, message us on WhatsApp at +92 311 7798157.
          </p>
        </div>
      </div>
    </div>
  );
}
