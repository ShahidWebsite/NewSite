"use client";

import { useRouter, useSearchParams, usePathname } from "next/navigation";

const OPTIONS = [
  { value: "newest", label: "Newest" },
  { value: "price_asc", label: "Price: Low to High" },
  { value: "price_desc", label: "Price: High to Low" },
];

export default function SortSelect() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const pathname = usePathname(); // "/shop" or the current clean category path, e.g. "/cabinet-handles"

  function handleChange(value: string) {
    const params = new URLSearchParams(searchParams.toString());
    params.delete("limit"); // reset pagination when sort order changes
    if (value === "newest") {
      params.delete("sort");
    } else {
      params.set("sort", value);
    }
    const qs = params.toString();
    router.push(qs ? `${pathname}?${qs}` : pathname);
  }

  return (
    <select
      defaultValue={searchParams.get("sort") ?? "newest"}
      onChange={(e) => handleChange(e.target.value)}
      className="border border-nickel/40 bg-transparent px-3 py-2 font-body text-sm text-ink outline-none focus:border-ink"
      aria-label="Sort products"
    >
      {OPTIONS.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  );
}