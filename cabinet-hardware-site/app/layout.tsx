import type { Metadata } from "next";
import "./globals.css";
import { CartProvider } from "@/lib/cart-context";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Shahid Iqbal & Co — Dream Hardware at your Door Step",
  description:
    "Door handles, cabinet handles, knobs, and furniture pulls, specialized in brass. Based in Lahore — order online with bank transfer and track your delivery.",
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
