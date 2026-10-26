-- ============================================================================
-- Brand name fix: some guides say "Siqbal & Co." instead of "Shahid Iqbal & Co".
-- Google and customers should see one consistent business name everywhere.
-- Paste into Supabase -> SQL Editor and click Run. Safe to run more than once.
--
-- Text-only: it only changes the wrong spelling; nothing else in the guides.
-- ============================================================================

create or replace function pg_temp.fix_brand(t text, in_title boolean default false)
returns text language sql immutable as $f$
  select case
    when t is null then null
    when in_title then replace(replace(t, 'Siqbal & Co.', 'Shahid Iqbal & Co'), 'Siqbal & Co', 'Shahid Iqbal & Co')
    else replace(replace(replace(t, 'Siqbal & Co.,', 'Shahid Iqbal & Co,'), 'Siqbal & Co.', 'Shahid Iqbal & Co.'), 'Siqbal & Co', 'Shahid Iqbal & Co')
  end
$f$;

update blog_posts set
  title           = pg_temp.fix_brand(title, true),
  excerpt         = pg_temp.fix_brand(excerpt),
  content         = pg_temp.fix_brand(content),
  seo_title       = pg_temp.fix_brand(seo_title, true),
  seo_description = pg_temp.fix_brand(seo_description),
  updated_at      = now()
where title ilike '%Siqbal & Co%'
   or excerpt ilike '%Siqbal & Co%'
   or content ilike '%Siqbal & Co%'
   or seo_title ilike '%Siqbal & Co%'
   or seo_description ilike '%Siqbal & Co%';

-- Check: this should return 0 rows afterwards.
select slug from blog_posts
where content ilike '%Siqbal & Co%' or seo_title ilike '%Siqbal & Co%' or title ilike '%Siqbal & Co%';
