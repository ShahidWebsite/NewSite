-- ============================================================================
-- One-time setup for product photo uploads. Run this once in Supabase's
-- SQL Editor (safe to re-run — uses "if not exists" / "on conflict" guards).
-- ============================================================================

-- Create a public storage bucket for product photos
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

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
