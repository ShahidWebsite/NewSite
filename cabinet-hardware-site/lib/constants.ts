// Preset options shown as dropdowns in the admin forms, based on what's
// actually common in this product line. "Custom…" always reveals a free-text
// box, so nothing is ever truly restricted — these are just sensible
// defaults so Shahid doesn't have to type the same values over and over
// and risk typos (e.g. "128mm" vs "128 mm" would otherwise create two
// different variants by mistake).

export const FINISH_OPTIONS = [
  "Golden",
  "Matte Black",
  "Chrome",
  "Antique Brass",
  "Silver",
  "Custom…",
];

export const SIZE_OPTIONS = ["96mm", "128mm", "160mm", "192mm", "Custom…"];

export const MATERIAL_OPTIONS = ["Zinc Alloy", "Brass", "Aluminum", "Iron", "Stainless Steel", "Custom…"];

export const WEIGHT_UNIT_OPTIONS = ["g", "kg"];
