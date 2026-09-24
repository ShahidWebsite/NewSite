-- ============================================================================
-- Adds: 1) Contact / Bulk Enquiry form storage, 2) weight-based shipping
-- settings for the new Cash on Delivery (Leopard Courier) option, and
-- 3) the columns needed to record that shipping fee on each order.
-- Safe to re-run — every statement below is idempotent.
-- Paste this whole file into Supabase → SQL Editor → Run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONTACT / BULK ENQUIRY FORM
-- Every submission from /contact lands here. Public (anon key) can insert
-- but never read back — same pattern as orders. You review these in
-- /admin/enquiries.
-- ----------------------------------------------------------------------------
create table if not exists enquiries (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  phone        text not null,
  email        text,
  message      text not null,
  enquiry_type text not null default 'general' check (enquiry_type in ('general', 'bulk_wholesale')),
  status       text not null default 'new' check (status in ('new', 'contacted', 'closed')),
  created_at   timestamptz not null default now()
);

alter table enquiries enable row level security;

drop policy if exists public_insert_enquiries on enquiries;
drop policy if exists admin_all_enquiries on enquiries;

create policy public_insert_enquiries on enquiries for insert with check (true);
create policy admin_all_enquiries on enquiries for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create index if not exists idx_enquiries_created on enquiries(created_at desc);

-- ----------------------------------------------------------------------------
-- SHIPPING (weight-based COD rate card)
-- Single row, editable in /admin/shipping-settings. total_shipping_fee =
-- base_fee + per_kg_rate × ceil(order_weight_kg). Shown to customers at
-- checkout and recomputed server-side (never trusted from the browser) when
-- the order is actually created.
-- ----------------------------------------------------------------------------
create table if not exists shipping_settings (
  id           integer primary key default 1 check (id = 1), -- enforces a single row
  base_fee     numeric(12,2) not null default 150,
  per_kg_rate  numeric(12,2) not null default 100,
  courier_name text not null default 'Leopard Courier',
  updated_at   timestamptz not null default now()
);

insert into shipping_settings (id) values (1) on conflict (id) do nothing;

alter table shipping_settings enable row level security;

drop policy if exists public_read_shipping_settings on shipping_settings;
drop policy if exists admin_all_shipping_settings on shipping_settings;

-- Public can read it (needed to show a live shipping estimate at checkout)
-- but never write it.
create policy public_read_shipping_settings on shipping_settings for select using (true);
create policy admin_all_shipping_settings on shipping_settings for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ----------------------------------------------------------------------------
-- PRODUCT SHIPPING WEIGHT
-- Numeric grams, used only for the shipping calculation (separate from the
-- free-text "Weight" spec shown on the product page). Falls back to a
-- reasonable default in code if a product was created before this existed.
-- ----------------------------------------------------------------------------
alter table products add column if not exists weight_grams integer;

-- ----------------------------------------------------------------------------
-- ORDERS: record the shipping fee actually charged, and allow COD
-- ----------------------------------------------------------------------------
alter table orders add column if not exists shipping_fee numeric(12,2) not null default 0;

alter table orders drop constraint if exists orders_payment_method_check;
alter table orders add constraint orders_payment_method_check
  check (payment_method in ('bank_transfer', 'cod', 'razorpay', 'stripe'));