-- ============================================================================
-- Adds support for general testimonials (not tied to one product) and
-- inserts the reviews pulled from the Facebook page. Safe to re-run.
-- Paste this whole file into Supabase → SQL Editor → Run.
-- ============================================================================

-- A Facebook "recommendation" is about the business as a whole, not one
-- specific product, so product_id needs to be allowed to be empty.
alter table reviews alter column product_id drop not null;

-- Prevents duplicate rows if this script is ever run more than once.
create unique index if not exists reviews_customer_created_idx on reviews(customer_name, created_at);

insert into reviews (product_id, customer_name, rating, body, approved, created_at) values
  (null, 'Irfan A.', 5, 'Highly recommended — best quality, delivered exactly as shown in the video and photos before it arrived.', true, '2024-09-18T00:00:00Z'),
  (null, 'M. Usman B.', 5, '100% satisfied and recommended.', true, '2023-09-03T00:00:00Z'),
  (null, 'Sajid R.', 5, 'Completely satisfied with their service quality and prices.', true, '2022-01-11T00:00:00Z'),
  (null, 'Sheikh Asad A.', 5, 'Completely satisfied with their service and prices.', true, '2021-07-24T00:00:00Z'),
  (null, 'Abid H.', 5, 'Created by a worthy and credible young man!', true, '2021-05-29T00:00:00Z'),
  (null, 'Aslam Emad M.', 5, 'Excellent service and quality products.', true, '2021-05-06T00:00:00Z'),
  (null, 'Haris T.', 5, 'Excellent quality products! Thank you.', true, '2020-11-05T00:00:00Z')
on conflict (customer_name, created_at) do nothing;
