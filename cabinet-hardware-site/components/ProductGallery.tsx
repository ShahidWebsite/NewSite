"use client";

import { useState } from "react";
import Image from "next/image";
import { ProductImage } from "@/lib/types";
import { productImageAlt } from "@/lib/seo";

export default function ProductGallery({
  images,
  productName,
}: {
  images: ProductImage[];
  productName: string;
}) {
  const [activeIndex, setActiveIndex] = useState(0);
  const [swapped, setSwapped] = useState(false); // fade only after a thumbnail is chosen, never on first load
  const active = images[activeIndex];

  return (
    <div>
      <div className="relative aspect-square overflow-hidden bg-nickel/10">
        {active ? (
          <div key={active.id} className={`absolute inset-0 ${swapped ? "fade-in" : ""}`}>
            <Image
              src={active.url}
              alt={productImageAlt(productName, activeIndex)}
              fill
              sizes="(min-width: 768px) 50vw, 100vw"
              className="object-cover"
              priority={activeIndex === 0}
            />
          </div>
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
              onClick={() => {
                setSwapped(true);
                setActiveIndex(i);
              }}
              aria-label={`Show image ${i + 1} of ${images.length}`}
              aria-current={i === activeIndex}
              className={`press relative h-16 w-16 flex-shrink-0 overflow-hidden border transition-colors ${
                i === activeIndex ? "border-ink" : "border-nickel/30 hover:border-nickel"
              }`}
            >
              <Image src={img.url} alt={productImageAlt(productName, i)} fill sizes="64px" className="object-cover" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
