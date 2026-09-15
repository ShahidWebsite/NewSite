-- ============================================================================
-- Standalone storefront schema — no ERP linkage, single store (no multi-tenancy)
-- Run in Supabase SQL editor.
-- ============================================================================

create extension if not exists pgcrypto;

-- ----------------------------------------------------------------------------
-- CATALOG
-- ----------------------------------------------------------------------------
create table categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text not null unique,
  sort_order  integer not null default 0
);

create table products (
  id                uuid primary key default gen_random_uuid(),
  category_id       uuid references categories(id),
  name              text not null,
  slug              text not null unique,
  description       text,
  specs             jsonb not null default '{}'::jsonb, -- { material, hole_spacing, weight, ... } — shared across variants
  base_price        numeric(12,2) not null default 0,   -- shown on listing cards before a variant is picked
  seo_title         text,
  seo_description   text,
  status            text not null default 'active' check (status in ('active','out_of_stock','discontinued')),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create table product_images (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references products(id) on delete cascade,
  url         text not null,
  sort_order  integer not null default 0
);

-- Attributes describe the axes a product varies on (Finish, Size...)
create table attributes (
  id    uuid primary key default gen_random_uuid(),
  name  text not null unique          -- e.g. "Finish", "Size"
);

create table attribute_values (
  id            uuid primary key default gen_random_uuid(),
  attribute_id  uuid not null references attributes(id) on delete cascade,
  value         text not null,        -- e.g. "Matte Black", "128mm"
  swatch_hex    text,                 -- optional, used for finish color swatches in the UI
  unique (attribute_id, value)
);

-- A variant is a specific buyable combination (e.g. Matte Black + 128mm)
create table product_variants (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references products(id) on delete cascade,
  sku         text unique,
  price       numeric(12,2) not null,
  stock_qty   integer not null default 0,
  created_at  timestamptz not null default now()
);

create table variant_attribute_values (
  variant_id          uuid not null references product_variants(id) on delete cascade,
  attribute_value_id  uuid not null references attribute_values(id) on delete cascade,
  primary key (variant_id, attribute_value_id)
);

create index idx_products_category on products(category_id);
create index idx_variants_product on product_variants(product_id);
create index idx_product_images_product on product_images(product_id);

-- ----------------------------------------------------------------------------
-- BANK TRANSFER DETAILS
-- Single row — shown to every customer at checkout when they choose bank transfer.
-- ----------------------------------------------------------------------------
create table bank_settings (
  id                 integer primary key default 1 check (id = 1), -- enforces a single row
  account_title      text not null default '',
  bank_name          text not null default '',
  account_number     text not null default '',
  ifsc_or_routing    text not null default '',
  instructions       text not null default 'Please use your Order Number as the payment reference.',
  updated_at         timestamptz not null default now()
);

insert into bank_settings (id) values (1);

-- ----------------------------------------------------------------------------
-- ORDERS
-- ----------------------------------------------------------------------------
create sequence order_number_seq start 1001;

create table orders (
  id                  uuid primary key default gen_random_uuid(),
  order_number        text not null unique default ('ORD-' || nextval('order_number_seq')::text),
  customer_name       text not null,
  email               text not null,
  phone               text,
  shipping_address    jsonb not null default '{}'::jsonb, -- { line1, line2, city, region, postal_code, country }
  subtotal            numeric(12,2) not null,
  total               numeric(12,2) not null,
  payment_method      text not null default 'bank_transfer' check (payment_method in ('bank_transfer','razorpay','stripe')),
  payment_status      text not null default 'pending' check (payment_status in ('pending','paid','failed','refunded')),
  payment_reference   text,
  fulfillment_status  text not null default 'processing' check (fulfillment_status in ('processing','packed','shipped','delivered','cancelled')),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create table order_items (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null references orders(id) on delete cascade,
  product_id    uuid not null references products(id),
  variant_id    uuid not null references product_variants(id),
  product_name  text not null,   -- snapshot at time of order
  variant_label text not null,   -- e.g. "Matte Black / 128mm", snapshot at time of order
  quantity      integer not null check (quantity > 0),
  unit_price    numeric(12,2) not null
);

create index idx_orders_email on orders(email);
create index idx_order_items_order on order_items(order_id);

-- ----------------------------------------------------------------------------
-- ROW LEVEL SECURITY
--
-- Public (anon key, used by the storefront pages):
--   - Can browse active catalog data
--   - Can read bank details (they're meant to be shown to any paying customer)
--   - Can create orders (checkout) but CANNOT read any order back —
--     order tracking goes through a server-side API route instead, which
--     checks order_number + email match before returning anything.
--
-- Authenticated (you, the store owner, logged in via Supabase Auth):
--   - Full read/write on everything — this is a single-owner store, so any
--     authenticated user is treated as admin. If you ever add staff logins,
--     tighten this to check a specific role/claim instead.
-- ----------------------------------------------------------------------------

alter table categories enable row level security;
alter table products enable row level security;
alter table product_images enable row level security;
alter table attributes enable row level security;
alter table attribute_values enable row level security;
alter table product_variants enable row level security;
alter table variant_attribute_values enable row level security;
alter table bank_settings enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;

-- Public read access to catalog + bank details
create policy public_read_categories on categories for select using (true);
create policy public_read_products on products for select using (status = 'active');
create policy public_read_product_images on product_images for select using (true);
create policy public_read_attributes on attributes for select using (true);
create policy public_read_attribute_values on attribute_values for select using (true);
create policy public_read_variants on product_variants for select using (true);
create policy public_read_variant_attrs on variant_attribute_values for select using (true);
create policy public_read_bank_settings on bank_settings for select using (true);

-- Public can create orders at checkout, but never read them back directly
create policy public_insert_orders on orders for insert with check (true);
create policy public_insert_order_items on order_items for insert with check (true);

-- Admin (any authenticated user) — full access everywhere
create policy admin_all_categories on categories for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_products on products for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_product_images on product_images for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_attributes on attributes for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_attribute_values on attribute_values for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_variants on product_variants for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_variant_attrs on variant_attribute_values for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_bank_settings on bank_settings for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_orders on orders for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy admin_all_order_items on order_items for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
