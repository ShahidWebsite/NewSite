// Regional wholesale guides. These pages exist for hardware-shop buyers who find us
// through the wholesale hub, but they follow one template, so they are kept OUT of
// Google's index (noindex) and out of the sitemap, to avoid thin / doorway-page signals.
// The pages stay reachable by link. Remove a slug from NOINDEX_REGION_SLUGS only once the
// page has genuinely unique content.

export const WHOLESALE_HUB_SLUG = "wholesale-cabinet-handles-knobs-supplier-pakistan";
export const LAHORE_GUIDE_SLUG = "cabinet-handles-knobs-lahore-where-to-buy";

export const NOINDEX_REGION_SLUGS = [
  "cabinet-handles-wholesale-islamabad-rawalpindi",
  "cabinet-handles-wholesale-karachi-sindh",
  "cabinet-handles-wholesale-azad-kashmir-mirpur",
  "cabinet-handles-wholesale-faisalabad-multan-sialkot-punjab",
  "cabinet-handles-wholesale-nowshera-khyber-pakhtunkhwa",
];

// For schema.org areaServed: based in Lahore, delivering all over Pakistan (Country: Pakistan is added in layout).
export const AREA_CITIES = ["Lahore"];
export const AREA_REGIONS = ["Punjab", "Sindh", "Khyber Pakhtunkhwa", "Islamabad Capital Territory"];
