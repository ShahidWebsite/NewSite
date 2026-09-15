export type Category = {
  id: string;
  name: string;
  slug: string;
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

export type BankSettings = {
  account_title: string;
  bank_name: string;
  account_number: string;
  ifsc_or_routing: string;
  instructions: string;
};
