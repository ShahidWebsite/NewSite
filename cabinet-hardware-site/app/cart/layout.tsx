import type { Metadata } from "next";
import { pageMetadata } from "@/lib/seo";

// Utility page — useful to customers, useless in Google search results.
export const metadata: Metadata = pageMetadata({
  title: "Your Cart | Shahid Iqbal & Co",
  path: "/cart",
  noindex: true,
});

export default function Layout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
