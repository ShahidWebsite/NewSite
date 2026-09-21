import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata({
  title: 'Privacy Policy | Shahid Iqbal & Co',
  description:
    'How Shahid Iqbal & Co collects, uses and protects your personal information when you shop or contact us.',
  path: '/privacy',
});

export default function PrivacyPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Privacy Policy</h1>
      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>Last updated: {new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}</p>
        <div>
          <h2 className="font-display text-xl text-ink">Information we collect</h2>
          <p className="mt-2">
            When you place an order, we collect your name, delivery address, phone number,
            and email address so we can fulfill and let you track your order. We don't
            require an account to shop — no password or profile is created.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">How we use it</h2>
          <p className="mt-2">
            Order details are used only to process, ship, and let you track your purchase,
            and to contact you about that order if needed. We don't sell or share your
            information with third parties for marketing purposes.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Payment information</h2>
          <p className="mt-2">
            We currently accept bank transfer only — we never collect or store card details
            on this site.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Cookies &amp; analytics</h2>
          <p className="mt-2">
            We may use basic, privacy-respecting analytics (such as Google Analytics) to
            understand how visitors use the site, so we can improve it. This data is
            aggregated and not used to personally identify you.
          </p>
        </div>
        <div>
          <h2 className="font-display text-xl text-ink">Contact us</h2>
          <p className="mt-2">
            Questions about your data? Message us on WhatsApp at +92 311 7798157 or via our{" "}
            <a href="https://www.facebook.com/siqbalhwc" className="text-ink underline hover:text-brass" target="_blank" rel="noopener noreferrer">
              Facebook page
            </a>
            .
          </p>
        </div>
      </div>
    </div>
  );
}
