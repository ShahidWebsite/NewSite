import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata({
  title: 'Returns & Exchanges | Shahid Iqbal & Co',
  description:
    'Our returns and exchange policy for handles, knobs and door hardware ordered from Shahid Iqbal & Co, Lahore.',
  path: '/returns',
});

export default function ReturnsPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Returns &amp; Exchanges</h1>
      <div className="mt-8 space-y-5 font-body text-graphite">
        <div>
          <h2 className="font-display text-xl text-ink">Return window</h2>
          <p className="mt-2">
            If a product arrives damaged, defective, or different from what you ordered,
            contact us within 7 days of delivery and we'll arrange a replacement or refund.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Condition for returns</h2>
          <p className="mt-2">
            Items must be unused, in their original packaging, with all parts included.
            Custom or bulk/wholesale orders may not be eligible for return — ask before
            ordering if you're unsure.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">How to start a return</h2>
          <p className="mt-2">
            Message us on WhatsApp at +92 311 7798157 with your order number and photos of
            the issue, and we'll take it from there.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Refunds</h2>
          <p className="mt-2">
            Approved refunds are sent by bank transfer to the account used for the original
            payment, within 7 business days of approval.
          </p>
        </div>
      </div>
    </div>
  );
}
