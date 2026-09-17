import { Metadata } from "next";

export const metadata: Metadata = {
  title: "About Us — Shahid Iqbal & Co",
  description:
    "Shahid Iqbal & Co is a Lahore-based hardware retailer specializing in brass door handles, cabinet handles, knobs, and furniture pulls.",
};

export default function AboutPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="font-display text-4xl text-ink">About Shahid Iqbal &amp; Co</h1>
      <p className="mt-2 font-body text-brass">Dream Hardware at your Door Step</p>

      <div className="mt-8 space-y-5 font-body text-graphite">
        <p>
          Shahid Iqbal &amp; Co is a Lahore-based hardware retailer specializing in door
          handles, cabinet handles, knobs, and furniture pulls — with a particular focus on
          brass hardware.
        </p>
        <p>
          Every listing on this site shows exact specs — size, finish, material, and hole
          spacing — before you order, so what arrives is what you measured for. No guessing,
          no surprises when your cabinets or doors are ready to be fitted.
        </p>
        <p>
          We work with both individual homeowners fitting out a new kitchen or bedroom, and
          contractors and carpenters sourcing hardware in bulk for a project.
        </p>
        <p>
          Have a question before you order, or need a bulk/wholesale quote? Reach out on
          WhatsApp or call us directly — details below.
        </p>
      </div>

      <div className="mt-10 border-t border-nickel/30 pt-6 font-body text-sm text-graphite">
        <p className="text-ink">Shahid Iqbal &amp; Co</p>
        <p className="mt-2">WhatsApp / Call: +92 311 7798157</p>
        <p>218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan</p>
        <p className="mt-2">
          <a
            href="https://www.facebook.com/siqbalhwc"
            className="text-ink underline hover:text-brass"
            target="_blank"
            rel="noopener noreferrer"
          >
            facebook.com/siqbalhwc
          </a>
          {" · "}
          <a
            href="https://www.instagram.com/siqbalco"
            className="text-ink underline hover:text-brass"
            target="_blank"
            rel="noopener noreferrer"
          >
            @siqbalco
          </a>
        </p>
      </div>
    </div>
  );
}
