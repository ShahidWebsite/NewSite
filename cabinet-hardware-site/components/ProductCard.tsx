import Link from "next/link";
import Image from "next/image";
import { Product } from "@/lib/types";

export default function ProductCard({ product }: { product: Product }) {
  const image = product.images[0]?.url;
  const totalStock = product.variants.reduce((sum, v) => sum + v.stock_qty, 0);

  return (
    <Link href={`/products/${product.slug}`} className="group block">
      <div className="relative aspect-square overflow-hidden bg-nickel/10">
        {image ? (
          <Image
            src={image}
            alt={product.name}
            fill
            sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
            className="object-cover transition-transform duration-300 group-hover:scale-[1.03]"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center font-display text-lg italic text-nickel">
            {product.name}
          </div>
        )}
      </div>
      <div className="mt-3 flex items-start justify-between gap-3">
        <div>
          <p className="font-body text-base text-ink">{product.name}</p>
          <p className="mt-0.5 font-body text-sm text-graphite">
            From Rs. {product.base_price.toLocaleString()}
          </p>
        </div>
        {totalStock <= 0 && (
          <span className="whitespace-nowrap font-body text-xs text-rust">Sold out</span>
        )}
      </div>
    </Link>
  );
}
