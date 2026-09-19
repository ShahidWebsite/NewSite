import type { Metadata } from "next";
import Script from "next/script";
import "./globals.css";
import { CartProvider } from "@/lib/cart-context";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

// Set NEXT_PUBLIC_GA_ID in Vercel (Project Settings → Environment Variables)
// to turn Google Analytics on. Until then this renders nothing, so it's
// safe to ship even before the owner has a GA4 property set up.
const GA_ID = process.env.NEXT_PUBLIC_GA_ID;
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || "https://www.siqbalhwc.com";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Shahid Iqbal & Co — Cabinet Handles & Knobs in Lahore",
    template: "%s",
  },
  description:
    "Door handles, cabinet handles, knobs, and furniture pulls, specialized in brass. Based in Lahore — order online with bank transfer and track your delivery.",
  alternates: { canonical: "/" },
};

// LocalBusiness structured data — tells Google exactly who you are, where
// you're located, and how to reach you, matching your Facebook Page (NAP
// consistency matters for local search ranking). Update the URL fields once
// the real domain and phone are confirmed live.
const localBusinessJsonLd = {
  "@context": "https://schema.org",
  "@type": "HardwareStore",
  name: "Shahid Iqbal & Co",
  slogan: "Dream Hardware at your Door Step",
  telephone: "+92-311-7798157",
  email: "siqbalhwc@gmail.com",
  url: "https://www.siqbalhwc.com",
  address: {
    "@type": "PostalAddress",
    streetAddress: "218/18 Ferozepur Road, near WAPDA Hospital",
    addressLocality: "Lahore",
    addressCountry: "PK",
  },
  sameAs: [
    "https://www.facebook.com/siqbalhwc",
    "https://www.instagram.com/siqbalco",
  ],
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(localBusinessJsonLd) }}
        />
        {GA_ID && (
          <>
            <Script src={`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`} strategy="afterInteractive" />
            <Script id="ga4-init" strategy="afterInteractive">
              {`
                window.dataLayer = window.dataLayer || [];
                function gtag(){dataLayer.push(arguments);}
                gtag('js', new Date());
                gtag('config', '${GA_ID}');
              `}
            </Script>
          </>
        )}
      </head>
      <body className="font-body">
        <CartProvider>
          <Header />
          <main>{children}</main>
          <Footer />
        </CartProvider>
      </body>
    </html>
  );
}
