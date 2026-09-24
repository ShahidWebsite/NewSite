import { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";
import ContactForm from "@/components/ContactForm";

export const metadata: Metadata = pageMetadata({
  title: "Contact Us & Bulk / Wholesale Enquiries — Shahid Iqbal & Co",
  description:
    "Get in touch with Shahid Iqbal & Co for questions, custom orders, or bulk/wholesale pricing on cabinet handles, knobs, and door hardware. WhatsApp, call, or send a message — Lahore, Pakistan.",
  path: "/contact",
});

export default function ContactPage() {
  return (
    <div className="mx-auto max-w-4xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">Contact &amp; Bulk Enquiries</h1>
      <p className="mt-3 max-w-prose font-body text-graphite">
        Questions about a product, a custom order, or pricing for a contractor / wholesale
        quantity? Send us a message below, on WhatsApp, or by phone — we usually reply the same
        day.
      </p>

      <div className="mt-10 grid gap-10 md:grid-cols-[1fr_1.2fr]">
        <div className="space-y-6 font-body text-sm">
          <div>
            <p className="text-graphite">WhatsApp / Call</p>
            <a href="tel:+923117798157" className="text-lg text-ink underline hover:text-brass">
              +92 311 7798157
            </a>
          </div>
          <div>
            <p className="text-graphite">Visit us</p>
            <p className="text-ink">218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan</p>
          </div>
          <div>
            <p className="text-graphite">Bulk / wholesale orders</p>
            <p className="text-ink">
              Contractors and carpenters — tell us the products, finishes, and quantities you
              need in the form and we&rsquo;ll come back with a quote.
            </p>
          </div>
          <div className="flex gap-4 pt-2">
            <a
              href="https://www.facebook.com/siqbalhwc"
              target="_blank"
              rel="noopener noreferrer"
              className="text-ink underline hover:text-brass"
            >
              Facebook
            </a>
            <a
              href="https://www.instagram.com/siqbalco"
              target="_blank"
              rel="noopener noreferrer"
              className="text-ink underline hover:text-brass"
            >
              Instagram
            </a>
          </div>
        </div>

        <ContactForm />
      </div>
    </div>
  );
}