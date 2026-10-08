// Short, genuinely useful text shown under each category grid. Written once per
// category so every category page has its own unique content (Google ranks pages
// that explain something, not bare product grids).

type Copy = { heading: string; paragraphs: string[] };

const SHOP =
  "In Lahore, visit Shahid Iqbal & Co at 218/18 Ferozepur Road, near WAPDA Hospital. Anywhere else in Pakistan, order online with bank transfer or Cash on Delivery and we deliver to your city. Hardware shops can ask for wholesale rates on WhatsApp at +92 311 7798157.";

const COPY: Record<string, Copy> = {
  "cabinet-handles": {
    heading: "Cabinet handles in Lahore and across Pakistan",
    paragraphs: [
      "Our cabinet handles cover kitchen doors, drawers and wardrobes, in golden, matte black, chrome and other finishes, and in aluminium and zinc alloy. Every listing states the size and hole spacing, so you can match it to the screw holes already drilled in your cabinet.",
      "To choose the right size, measure the centre-to-centre distance between the two screw holes, then pick a handle with the same hole spacing. Common spacings are 96mm, 128mm, 160mm and 192mm. Our buying guides explain how to measure and which finish suits which room.",
      SHOP,
    ],
  },
  "cabinet-knob": {
    heading: "Cabinet knobs in Lahore and across Pakistan",
    paragraphs: [
      "Cabinet knobs suit drawers, small cupboards and lighter doors. They fix with a single screw, so there is no hole spacing to match; just check that the screw length suits the thickness of your door or drawer front.",
      "Browse knobs in golden, matte black, chrome and antique finishes. Each listing shows the size and finish before you order.",
      SHOP,
    ],
  },
  "main-door-handle": {
    heading: "Main door handles in Lahore and across Pakistan",
    paragraphs: [
      "Main door handles take heavy daily use, so material matters. Brass is a strong choice for Lahore's heat and monsoon humidity because it resists wear better than thin plated finishes.",
      "Before ordering, check your door thickness and the position of the existing fixing holes so the handle fits without extra drilling. Our guide on choosing a main door handle walks through it.",
      SHOP,
    ],
  },
  hinges: {
    heading: "Hinges in Lahore and across Pakistan",
    paragraphs: [
      "Hinges for doors, cabinets and furniture, listed with their size and weight so you can match what you are replacing. Measure the length of your existing hinge and the thickness of the door before ordering.",
      SHOP,
    ],
  },
  "brass-knob-antique-knob": {
    heading: "Brass and antique knobs in Lahore and across Pakistan",
    paragraphs: [
      "Brass knobs and antique-style knobs for cabinets, drawers and furniture, including decorative shapes. Solid brass wears well and keeps its look for years, which is why it is our specialty.",
      SHOP,
    ],
  },
};

export function categoryCopy(slug: string, name: string): Copy {
  return (
    COPY[slug] ?? {
      heading: `${name} in Lahore and across Pakistan`,
      paragraphs: [
        `${name} with the size, finish and material shown on every listing, so you know what you are buying before it arrives.`,
        SHOP,
      ],
    }
  );
}
