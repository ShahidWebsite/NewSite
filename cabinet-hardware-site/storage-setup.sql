-- ============================================================================
-- One-time setup for product photo uploads.
--
-- IMPORTANT: before running this, create the storage bucket itself via the
-- Supabase Dashboard (not SQL) — this is the reliable way:
--   1. Go to Storage in the left sidebar
--   2. Click "New bucket"
--   3. Name it exactly: product-images
--   4. Turn ON "Public bucket"
--   5. Click Save
-- THEN run this SQL below to set the upload/delete permissions.
-- Safe to re-run.
-- ============================================================================

drop policy if exists "Public read product images" on storage.objects;
drop policy if exists "Admin upload product images" on storage.objects;
drop policy if exists "Admin delete product images" on storage.objects;

-- Anyone can view images (needed so photos show up on the public storefront)
create policy "Public read product images"
on storage.objects for select
using (bucket_id = 'product-images');

-- Only logged-in admin users can upload
create policy "Admin upload product images"
on storage.objects for insert
with check (bucket_id = 'product-images' and auth.role() = 'authenticated');

-- Only logged-in admin users can delete
create policy "Admin delete product images"
on storage.objects for delete
using (bucket_id = 'product-images' and auth.role() = 'authenticated');
