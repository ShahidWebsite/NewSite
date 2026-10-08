import { permanentRedirect } from "next/navigation";
import { categoryPathFor } from "@/lib/legacy-redirect";

export const dynamic = "force-dynamic";

// Old WooCommerce category URL (/product-category/...) -> closest category page.
export default async function LegacyCategoryRedirect({ params }: { params: { path: string[] } }) {
  permanentRedirect(await categoryPathFor(params.path.join(" ")));
}
