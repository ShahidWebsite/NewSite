-- ============================================================================
-- Adds product reviews. Safe to re-run.
-- Paste this whole file into Supabase → SQL Editor → Run.
-- ============================================================================

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  customer_name text not null,
  rating int not null check (rating between 1 and 5),
  body text not null,
  approved boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists reviews_product_id_idx on reviews(product_id);

alter table reviews enable row level security;

drop policy if exists public_read_approved_reviews on reviews;
drop policy if exists public_insert_reviews on reviews;
drop policy if exists admin_all_reviews on reviews;

-- Shoppers can only ever see reviews an admin has approved
create policy public_read_approved_reviews on reviews for select using (approved = true);

-- Anyone can submit a review — it stays hidden until approved
create policy public_insert_reviews on reviews for insert with check (approved = false);

-- Admin (any authenticated user) can see/approve/delete everything
create policy admin_all_reviews on reviews for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
