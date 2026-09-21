import type { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

// Utility page — useful to customers, useless in Google search results.
export const metadata: Metadata = pageMetadata({
  title: "Track Your Order | Shahid Iqbal & Co",
  path: "/track-order",
  noindex: true,
});

export default function Layout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
