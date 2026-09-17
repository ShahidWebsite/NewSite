"use client";

import { useState } from "react";
import Image from "next/image";
import { ProductImage } from "@/lib/types";

export default function ProductGallery({
  images,
  productName,
}: {
  images: ProductImage[];
  productName: string;
}) {
  const [activeIndex, setActiveIndex] = useState(0);
  const active = images[activeIndex];

  return (
    <div>
      <div className="relative aspect-square overflow-hidden bg-nickel/10">
        {active ? (
          <Image
            src={active.url}
            alt={productName}
            fill
            sizes="(min-width: 768px) 50vw, 100vw"
            className="object-cover"
            priority={activeIndex === 0}
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center font-display text-2xl italic text-nickel">
            {productName}
          </div>
        )}
      </div>

      {images.length > 1 && (
        <div className="mt-3 flex gap-2 overflow-x-auto">
          {images.map((img, i) => (
            <button
              key={img.id}
              type="button"
              onClick={() => setActiveIndex(i)}
              aria-label={`Show image ${i + 1} of ${images.length}`}
              aria-current={i === activeIndex}
              className={`relative h-16 w-16 flex-shrink-0 overflow-hidden border ${
                i === activeIndex ? "border-ink" : "border-nickel/30 hover:border-nickel"
              }`}
            >
              <Image src={img.url} alt="" fill sizes="64px" className="object-cover" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
