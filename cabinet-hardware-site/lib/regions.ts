// Where we supply from Lahore. One list feeds the homepage "we supply across
// Pakistan" section, the footer links and the LocalBusiness schema, so the
// wording and the city names stay identical everywhere (Google compares them).

export const WHOLESALE_HUB_SLUG = "wholesale-cabinet-handles-knobs-supplier-pakistan";

export type Region = { name: string; cities: string; slug: string };

export const REGIONS: Region[] = [
  { name: "Islamabad & Rawalpindi", cities: "Islamabad, Rawalpindi", slug: "cabinet-handles-wholesale-islamabad-rawalpindi" },
  { name: "Karachi & Sindh", cities: "Karachi, Larkana, Jacobabad", slug: "cabinet-handles-wholesale-karachi-sindh" },
  { name: "Azad Kashmir (AJK)", cities: "Mirpur and across AJK", slug: "cabinet-handles-wholesale-azad-kashmir-mirpur" },
  { name: "Punjab", cities: "Faisalabad, Multan, Sialkot", slug: "cabinet-handles-wholesale-faisalabad-multan-sialkot-punjab" },
  { name: "Khyber Pakhtunkhwa", cities: "Nowshera and across KPK", slug: "cabinet-handles-wholesale-nowshera-khyber-pakhtunkhwa" },
  { name: "Lahore", cities: "Ferozepur Road, Lahore", slug: "cabinet-handles-knobs-lahore-where-to-buy" },
];

// For schema.org areaServed.
export const AREA_CITIES = [
  "Lahore", "Islamabad", "Rawalpindi", "Karachi", "Larkana", "Jacobabad",
  "Faisalabad", "Multan", "Sialkot", "Mirpur", "Nowshera",
];
export const AREA_REGIONS = [
  "Punjab", "Sindh", "Azad Kashmir", "Khyber Pakhtunkhwa", "Islamabad Capital Territory",
];
