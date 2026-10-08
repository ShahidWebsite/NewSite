/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    outputFileTracingIncludes: {
      "/api/catalogue": [
        "./node_modules/pdfkit/js/data/**",
        "./node_modules/pdfkit/js/standard-fonts/**",
      ],
    },
  },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "*.supabase.co",
      },
    ],
  },
  // 301 redirects: the domain used to run an old WordPress/WooCommerce shop that
  // Google still remembers. Without these, every old link is a dead 404.
  async redirects() {
    return [
      // siqbalhwc.com -> www.siqbalhwc.com (one canonical host)
      {
        source: "/:path*",
        has: [{ type: "host", value: "siqbalhwc.com" }],
        destination: "https://www.siqbalhwc.com/:path*",
        permanent: true,
      },
      // /product-category/* and /product/* are handled by app/product-category and app/product,
      // which redirect each old URL to the closest matching page instead of a blanket /shop.
      { source: "/product-tag/:path*", destination: "/shop", permanent: true },
      { source: "/category/:path*", destination: "/blog", permanent: true },
      { source: "/my-account/:path*", destination: "/track-order", permanent: true },
      { source: "/wishlist/:path*", destination: "/shop", permanent: true },
    ];
  },
};

export default nextConfig;
