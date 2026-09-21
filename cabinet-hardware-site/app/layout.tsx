import type { Metadata } from "next";
import Script from "next/script";
import "./globals.css";
import { CartProvider } from "@/lib/cart-context";
import { supabase } from "@/lib/supabase";
import { BRAND, SITE_URL, ogImageUrl } from "@/lib/seo";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

// Header + footer show your real categories, so new categories appear in the
// menu automatically. Re-checked at most once a minute.
export const revalidate = 60;

// Set NEXT_PUBLIC_GA_ID in Vercel (Project Settings → Environment Variables)
// to turn Google Analytics on. Until then this renders nothing, so it's
// safe to ship even before the owner has a GA4 property set up.
const GA_ID = process.env.NEXT_PUBLIC_GA_ID;
// NOTE: there is intentionally NO canonical here. A canonical set in the root
// layout is inherited by every page that doesn't set its own, which made About,
// Shipping, Privacy etc. all claim "I'm a copy of the homepage". Each page now
// sets its own canonical via pageMetadata() in lib/seo.ts.
export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Shahid Iqbal & Co — Cabinet Handles & Knobs in Lahore",
    template: "%s",
  },
  description:
    "Door handles, cabinet handles, knobs, and furniture pulls, specialized in brass. Based in Lahore — order online with bank transfer and track your delivery.",
  applicationName: BRAND,
  // Fallback social-share card for any page that doesn't set its own.
  openGraph: {
    type: "website",
    siteName: BRAND,
    locale: "en_PK",
    images: [{ url: ogImageUrl(), width: 1200, height: 630, alt: BRAND }],
  },
  twitter: { card: "summary_large_image", images: [ogImageUrl()] },
};

async function getNavCategories() {
  const { data } = await supabase.from("categories").select("name, slug").order("sort_order").limit(8);
  return (data ?? []) as { name: string; slug: string }[];
}

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
  url: SITE_URL,
  logo: `${SITE_URL}/logo.png`,
  image: `${SITE_URL}/logo.png`,
  areaServed: { "@type": "Country", name: "Pakistan" },
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

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const categories = await getNavCategories();
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
          <Header categories={categories} />
          <main>{children}</main>
          <Footer categories={categories} />
        </CartProvider>
      </body>
    </html>
  );
}
