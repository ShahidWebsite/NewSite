export type Category = {
  id: string;
  name: string;
  slug: string;
  image_url?: string | null;
};

export type ProductImage = {
  id: string;
  url: string;
  sort_order: number;
};

export type AttributeValue = {
  id: string;
  value: string;
  swatch_hex: string | null;
  attribute_id: string;
};

export type Attribute = {
  id: string;
  name: string;
  values: AttributeValue[];
};

export type Variant = {
  id: string;
  sku: string | null;
  price: number;
  stock_qty: number;
  attribute_value_ids: string[];
};

export type Product = {
  id: string;
  name: string;
  slug: string;
  model_code?: string | null;
  seo_title?: string | null;
  seo_description?: string | null;
  description: string | null;
  specs: Record<string, string>;
  base_price: number;
  status: "active" | "out_of_stock" | "discontinued";
  category_id: string | null;
  images: ProductImage[];
  variants: Variant[];
};

export type CartLine = {
  productId: string;
  productName: string;
  productSlug: string;
  variantId: string;
  variantLabel: string;
  unitPrice: number;
  quantity: number;
  imageUrl: string | null;
};

export type Review = {
  id: string;
  product_id: string | null;
  customer_name: string;
  rating: number;
  body: string;
  approved: boolean;
  created_at: string;
};

export type BankSettings = {
  account_title: string;
  bank_name: string;
  account_number: string;
  ifsc_or_routing: string;
  instructions: string;
};

export type BankAccount = {
  id: string;
  bank_name: string;
  account_title: string;
  account_number: string;
  ifsc_or_routing: string;
  sort_order: number;
  active: boolean;
};

export type BlogPost = {
  id: string;
  slug: string;
  title: string;
  tag: string | null;
  excerpt: string | null;
  content: string;
  cover_image_url: string | null;
  seo_title: string | null;
  seo_description: string | null;
  published: boolean;
  published_at: string | null;
  created_at: string;
  updated_at: string;
};
