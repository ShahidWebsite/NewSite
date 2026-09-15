-- ============================================================================
-- OPTIONAL — run this after schema.sql if you want a few sample products
-- to see the site working before adding your real catalog. Safe to skip;
-- you can delete these later from the admin panel.
-- ============================================================================

insert into categories (name, slug, sort_order) values
  ('Cabinet Handles', 'cabinet-handles', 1),
  ('Cabinet Knobs', 'cabinet-knobs', 2),
  ('Drawer Pulls', 'drawer-pulls', 3);

insert into attributes (name) values ('Finish'), ('Size');

with f as (select id from attributes where name = 'Finish'),
     s as (select id from attributes where name = 'Size')
insert into attribute_values (attribute_id, value, swatch_hex)
select f.id, v.value, v.hex from f, (values
  ('Golden', '#A9832E'),
  ('Matte Black', '#1C1B19'),
  ('Chrome', '#9B9992')
) as v(value, hex)
union all
select s.id, v.value, null from s, (values ('96mm'), ('128mm'), ('192mm')) as v(value);

-- One sample product with three variants
with cat as (select id from categories where slug = 'cabinet-handles'),
     prod as (
       insert into products (category_id, name, slug, description, specs, base_price)
       select cat.id, 'Bridge Pull Handle', 'bridge-pull-handle',
         'A slim bridge-style pull with a solid brass/zinc core. Fits standard two-screw cabinet doors and drawers.',
         '{"material": "Zinc / Brass", "weight": "85g"}'::jsonb, 450
       from cat
       returning id
     )
insert into product_variants (product_id, sku, price, stock_qty)
select prod.id, sku, price, stock from prod, (values
  ('BPH-GD-128', 450, 40),
  ('BPH-MB-128', 430, 25),
  ('BPH-CH-128', 460, 15)
) as v(sku, price, stock);

-- Link that sample product's variants to Golden / 128mm etc.
with gd as (select id from attribute_values where value = 'Golden'),
     mb as (select id from attribute_values where value = 'Matte Black'),
     ch as (select id from attribute_values where value = 'Chrome'),
     sz128 as (select id from attribute_values where value = '128mm'),
     v1 as (select id from product_variants where sku = 'BPH-GD-128'),
     v2 as (select id from product_variants where sku = 'BPH-MB-128'),
     v3 as (select id from product_variants where sku = 'BPH-CH-128')
insert into variant_attribute_values (variant_id, attribute_value_id)
select v1.id, gd.id from v1, gd
union all select v1.id, sz128.id from v1, sz128
union all select v2.id, mb.id from v2, mb
union all select v2.id, sz128.id from v2, sz128
union all select v3.id, ch.id from v3, ch
union all select v3.id, sz128.id from v3, sz128;
