import { permanentRedirect } from "next/navigation";
import { productPathFor } from "@/lib/legacy-redirect";

export const dynamic = "force-dynamic";

// Old WooCommerce product URL (/product/<slug>) -> best matching product or category.
export default async function LegacyProductRedirect({ params }: { params: { slug: string } }) {
  permanentRedirect(await productPathFor(params.slug));
}
