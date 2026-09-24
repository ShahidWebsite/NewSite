import ProductCard from "@/components/ProductCard";
import SortSelect from "@/components/SortSelect";
import { Product } from "@/lib/types";
import { PAGE_SIZE } from "@/lib/shop-data";

type Category = { id: string; name: string; slug: string };

export default function ShopBrowser({
  basePath,
  heading,
  activeCategorySlug,
  categories,
  filterOptions,
  products,
  hasMore,
  color,
  size,
  q,
  sort,
  limit,
}: {
  basePath: string; // "/shop" or "/{category-slug}" — where filter/sort links point
  heading: string;
  activeCategorySlug?: string; // set only on a /{category-slug} route
  categories: Category[];
  filterOptions: { colors: any[]; sizes: any[] };
  products: Product[];
  hasMore: boolean;
  color?: string;
  size?: string;
  q?: string;
  sort?: string;
  limit: number;
}) {
  // Category switch: goes to the other category's own clean path, carrying
  // color/size/sort/q along (never carries a "category" query param — the
  // path itself is the category now).
  function categoryHref(slug?: string) {
    const params = new URLSearchParams();
    if (color) params.set("color", color);
    if (size) params.set("size", size);
    if (sort) params.set("sort", sort);
    if (q) params.set("q", q);
    const qs = params.toString();
    const path = slug ? `/${slug}` : "/shop";
    return qs ? `${path}?${qs}` : path;
  }

  // Color/size/sort toggle: stays on the current basePath (whether that's
  // /shop or a category page), just changes the query string.
  function filterHref(next: { color?: string; size?: string }) {
    const params = new URLSearchParams();
    const nextColor = next.color !== undefined ? next.color : color;
    const nextSize = next.size !== undefined ? next.size : size;
    if (nextColor) params.set("color", nextColor);
    if (nextSize) params.set("size", nextSize);
    if (q) params.set("q", q);
    if (sort) params.set("sort", sort);
    const qs = params.toString();
    return qs ? `${basePath}?${qs}` : basePath;
  }

  function loadMoreHref() {
    const params = new URLSearchParams();
    if (color) params.set("color", color);
    if (size) params.set("size", size);
    if (q) params.set("q", q);
    if (sort) params.set("sort", sort);
    params.set("limit", String(limit + PAGE_SIZE));
    return `${basePath}?${params.toString()}`;
  }

  function clearFiltersHref() {
    const params = new URLSearchParams();
    if (sort) params.set("sort", sort);
    const qs = params.toString();
    return qs ? `${basePath}?${qs}` : basePath;
  }

  return (
    <div className="mx-auto max-w-[1400px] px-6 py-16">
      <h1 className="font-display text-4xl text-ink">{heading}</h1>

      <div className="mt-8 grid gap-8 md:grid-cols-[200px_1fr]">
        {/* Filters sidebar — stacks above the grid on mobile */}
        <aside className="space-y-6">
          <div>
            <p className="mb-2 font-body text-sm text-graphite">Category</p>
            <div className="flex flex-wrap gap-2 md:flex-col md:items-start md:gap-1">
              <a
                href={categoryHref(undefined)}
                className={`font-body text-sm ${!activeCategorySlug ? "text-ink underline" : "text-graphite hover:text-ink"}`}
              >
                All
              </a>
              {categories.map((cat) => (
                <a
                  key={cat.id}
                  href={categoryHref(cat.slug)}
                  className={`font-body text-sm ${activeCategorySlug === cat.slug ? "text-ink underline" : "text-graphite hover:text-ink"}`}
                >
                  {cat.name}
                </a>
              ))}
            </div>
          </div>

          {filterOptions.colors.length > 0 && (
            <div>
              <p className="mb-2 font-body text-sm text-graphite">Color</p>
              <div className="flex flex-wrap gap-2">
                {filterOptions.colors.map((c: any) => (
                  <a
                    key={c.id}
                    href={color === c.value ? filterHref({ color: undefined }) : filterHref({ color: c.value })}
                    className={`flex items-center gap-1.5 border px-2 py-1 font-body text-xs ${
                      color === c.value ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite"
                    }`}
                  >
                    {c.swatch_hex && (
                      <span className="h-2.5 w-2.5 rounded-full border border-black/10" style={{ backgroundColor: c.swatch_hex }} />
                    )}
                    {c.value}
                  </a>
                ))}
              </div>
            </div>
          )}

          {filterOptions.sizes.length > 0 && (
            <div>
              <p className="mb-2 font-body text-sm text-graphite">Size</p>
              <div className="flex flex-wrap gap-2">
                {filterOptions.sizes.map((s: any) => (
                  <a
                    key={s.id}
                    href={size === s.value ? filterHref({ size: undefined }) : filterHref({ size: s.value })}
                    className={`border px-2 py-1 font-body text-xs ${
                      size === s.value ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite"
                    }`}
                  >
                    {s.value}
                  </a>
                ))}
              </div>
            </div>
          )}

          {(color || size) && (
            <a href={clearFiltersHref()} className="inline-block font-body text-xs text-graphite underline hover:text-ink">
              Clear all filters
            </a>
          )}
        </aside>

        {/* Results */}
        <div>
          <div className="mb-6 flex items-center justify-between gap-4">
            <p className="font-body text-sm text-graphite">
              {q && (
                <>
                  {products.length === 0 ? "No matches" : `Showing results`} for &ldquo;{q}&rdquo;
                  {" · "}
                  <a href={basePath} className="underline hover:text-ink">
                    Clear search
                  </a>
                </>
              )}
            </p>
            <SortSelect />
          </div>

          {products.length === 0 ? (
            <p className="font-body text-graphite">
              No products match these filters — try clearing one, or browse all products.
            </p>
          ) : (
            <>
              <div className="grid gap-x-6 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
                {products.map((p) => (
                  <ProductCard key={p.id} product={p} />
                ))}
              </div>
              {hasMore && (
                <div className="mt-10 text-center">
                  <a
                    href={loadMoreHref()}
                    className="inline-block border border-ink px-6 py-2 font-body text-sm text-ink hover:bg-ink hover:text-stone"
                  >
                    Load more
                  </a>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}