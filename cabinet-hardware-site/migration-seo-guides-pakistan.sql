-- ============================================================================
-- SEO update: Pakistan-wide + wholesale focus for ALL guides (blog posts).
-- Paste this whole block into Supabase -> SQL Editor and click Run.
-- Safe to run more than once. It will:
--   * rewrite the 6 existing guides (same web addresses, so no SEO is lost)
--   * add 9 new guides (wholesale hub, Islamabad, Sindh, AJK, Punjab, KPK,
--     stocking guide, how-to-order, Lahore)
--   * keep any cover photos / photos you already placed in the guides
-- ============================================================================

create or replace function pg_temp.keep_images(old_c text, new_c text)
returns text language plpgsql as $f$
declare ln text; extra text := ''; p int;
begin
  if old_c is null then return new_c; end if;
  for ln in select trim(l) from regexp_split_to_table(old_c, E'\n') as l loop
    if ln ~ '^!\[[^\]]*\]\([^)[:space:]]+\)$'
       and position(substring(ln from '\(([^)[:space:]]+)\)') in new_c) = 0 then
      extra := extra || ln || E'\n\n';
    end if;
  end loop;
  if extra = '' then return new_c; end if;
  p := position(E'\n## ' in new_c);
  if p = 0 then return new_c || E'\n\n' || extra; end if;
  return substr(new_c, 1, p) || extra || substr(new_c, p + 1);
end $f$;

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$wholesale-cabinet-handles-knobs-supplier-pakistan$t$, $t$Wholesale Cabinet Handles & Knobs Supplier in Pakistan — Dealing from Lahore$t$, $t$Wholesale$t$, $t$Shahid Iqbal & Co supplies cabinet handles, knobs and furniture hardware in wholesale quantities from Lahore to hardware shops across Punjab, Sindh, Azad Kashmir, Khyber Pakhtunkhwa and Islamabad.$t$,
$md$
If you run a hardware shop, a furniture workshop or a cabinet-making business anywhere in Pakistan, you need a supplier who stocks the sizes and finishes your customers actually ask for, ships reliably and quotes trade rates. **Shahid Iqbal & Co** is a cabinet and furniture hardware supplier dealing from Lahore, Pakistan. Most of our customers are hardware shops and trade buyers, and we also sell single pieces to retail customers.

## What we supply

- **Cabinet handles** in standard hole spacings, from small drawer handles to long wardrobe handles
- **Cabinet knobs** and drawer pulls for kitchens, bedrooms and offices
- **Door handles and main door pull handles**, with a specialty in **brass**
- **Furniture hardware** for cabinet makers and carpenters

Finishes include golden (brass tone), matte black, chrome, antique brass and silver. Read our [material comparison](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles) and [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) to see what sells well in each.

## Who we serve

We supply from Lahore to hardware shops and trade customers across **Punjab, Sindh, Azad Kashmir, Khyber Pakhtunkhwa and Islamabad**. We already send orders to Karachi, Larkana, Jacobabad, Faisalabad, Multan, Sialkot, Mirpur, Nowshera and Azad Kashmir, and we welcome new dealers in every other city. Pick your region:

- [Wholesale handles for Islamabad and Rawalpindi](/blog/cabinet-handles-wholesale-islamabad-rawalpindi)
- [Wholesale handles for Karachi and Sindh](/blog/cabinet-handles-wholesale-karachi-sindh)
- [Wholesale handles for Azad Kashmir (AJK) and Mirpur](/blog/cabinet-handles-wholesale-azad-kashmir-mirpur)
- [Wholesale handles for Faisalabad, Multan, Sialkot and Punjab](/blog/cabinet-handles-wholesale-faisalabad-multan-sialkot-punjab)
- [Wholesale handles for Nowshera and Khyber Pakhtunkhwa](/blog/cabinet-handles-wholesale-nowshera-khyber-pakhtunkhwa)
- [Lahore customers: where to buy, retail and wholesale](/blog/cabinet-handles-knobs-lahore-where-to-buy)

## Why hardware shops buy from us

- **Lahore stock, shipped to your city.** One supplier for handles, knobs and door hardware.
- **Exact specifications on every listing.** Hole spacing, size, finish and material are stated, so your counter staff and your customers know what they are buying.
- **Brass specialists.** Solid brass is the hardest-wearing option for Pakistan's heat and humidity.
- **Simple ordering.** Order on the website, or send your list on WhatsApp. See [how to order wholesale from Lahore](/blog/how-to-order-wholesale-cabinet-handles-from-lahore).
- **Retail too.** If you only need a few pieces for your own home, you can buy at retail from the same shop.

## Get a trade quote

Send your product list, finishes and quantities on WhatsApp at +92 311 7798157, or use the [bulk enquiry form](/contact). We reply with trade rates and delivery details. Not sure what to stock? Read [what a hardware shop should stock](/blog/what-hardware-shops-should-stock-cabinet-handles-knobs).

## Frequently asked questions

### Who is the best wholesale cabinet handle supplier in Pakistan?

We cannot judge ourselves, but we can tell you what we offer: trade rates, Lahore stock, a brass specialty, clear specifications and delivery to hardware shops across Pakistan. Ask for a quote and compare.

### Do you sell cabinet handles wholesale or retail?

Both. Wholesale and trade customers such as hardware shops are our main buyers. We also sell single pieces and small orders at retail.

### Do you supply hardware shops outside Lahore?

Yes. We send orders to Karachi, Larkana, Jacobabad, Faisalabad, Multan, Sialkot, Mirpur, Nowshera, Azad Kashmir and other cities by courier or cargo.

### What is the minimum order for wholesale?

It depends on the product and finish. Tell us what you need on WhatsApp and we will confirm the minimum and the trade rate.

### Where is your shop in Lahore?

218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan. Phone and WhatsApp: +92 311 7798157.
$md$,
$t$Wholesale Cabinet Handles & Knobs Pakistan | Lahore Supplier$t$, $t$Wholesale cabinet handles, knobs and furniture hardware from Lahore to hardware shops in Punjab, Sindh, AJK, KPK and Islamabad. Brass specialists.$t$, true, now() - interval '0 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$cabinet-handles-wholesale-islamabad-rawalpindi$t$, $t$Cabinet Handles & Knobs Wholesale for Islamabad and Rawalpindi — Supplied from Lahore$t$, $t$Wholesale$t$, $t$Hardware shops, carpenters and interior contractors in Islamabad and Rawalpindi can order cabinet handles, knobs and brass door hardware wholesale from Shahid Iqbal & Co, Lahore.$t$,
$md$
Islamabad and Rawalpindi are busy markets for kitchens, wardrobes and office furniture, and hardware shops there need steady supplies of handles and knobs. **Shahid Iqbal & Co** supplies cabinet and furniture hardware from Lahore to shops and trade buyers in **Islamabad, Rawalpindi** and nearby towns. We work mainly as a wholesaler, and we also serve retail customers.

## What Islamabad and Rawalpindi buyers order

- **Cabinet handles** for kitchen drawers and doors, with 96mm and 128mm hole spacing among the most common sizes
- **Long wardrobe handles** of 160mm to 256mm for tall doors
- **Cabinet knobs** for small cupboards and children's furniture
- **Brass main door handles** for houses and apartments, our specialty
- Finishes in golden, matte black, chrome and antique brass

Use our [size guide](/blog/cabinet-handle-size-guide-drawers-doors-wardrobes) to pick sizes, and the [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) to match modern and traditional interiors.

## Who we supply

- Hardware shops and building-material dealers
- Carpenters, cabinet makers and furniture workshops
- Interior designers, contractors and builders
- Individual home owners who want a few pieces

## How ordering works from Islamabad

1. Browse the [shop](/shop) or send your list on WhatsApp at +92 311 7798157.
2. We confirm availability, trade rates and delivery details.
3. Pay by bank transfer, or choose Cash on Delivery through Leopard Courier where available.
4. We dispatch from Lahore, and you can follow progress on the [order tracking page](/track-order).

See the full process in [how to order wholesale cabinet handles from Lahore](/blog/how-to-order-wholesale-cabinet-handles-from-lahore).

## Why buy from a Lahore supplier

Lahore is a major hub for hardware supply in Pakistan. Buying direct from a Lahore wholesaler means you deal with one shop for handles, knobs and door hardware, instead of several middlemen. See our [wholesale supplier overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan) for everything we offer.

## Frequently asked questions

### Do you supply cabinet handles wholesale in Islamabad?

Yes. We supply hardware shops and trade buyers in Islamabad and Rawalpindi from our Lahore shop and ship orders by courier or cargo.

### Can I buy a single handle in Islamabad from you?

Yes. We also sell at retail, so you can order a few pieces for your home. Wholesale rates apply to trade quantities.

### How do I get trade rates in Islamabad?

Send your products, finishes and quantities on WhatsApp at +92 311 7798157 or fill in the [bulk enquiry form](/contact).

### Do you sell brass door handles for Islamabad homes?

Yes, solid brass is our specialty. See our [guide to choosing a main door handle](/blog/how-to-choose-a-main-door-handle).

### Can I pay on delivery?

Cash on Delivery through Leopard Courier is available where the courier covers your address. Bank transfer is always available. Ask us to confirm for your city.
$md$,
$t$Cabinet Handles Wholesale Islamabad & Rawalpindi | Lahore$t$, $t$Wholesale cabinet handles, knobs and brass door handles for Islamabad and Rawalpindi hardware shops. Supplied from Lahore. Retail also available.$t$, true, now() - interval '1 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$cabinet-handles-wholesale-karachi-sindh$t$, $t$Cabinet Handles & Knobs Wholesale for Karachi and Sindh — Supplied from Lahore$t$, $t$Wholesale$t$, $t$Hardware shops in Karachi, Larkana, Jacobabad and across Sindh can order cabinet handles, knobs and brass door hardware wholesale from Shahid Iqbal & Co in Lahore.$t$,
$md$
Sindh is one of the regions we already supply most often. **Shahid Iqbal & Co** sends cabinet handles, knobs and furniture hardware from Lahore to hardware shops in **Karachi, Larkana, Jacobabad** and other Sindh towns. Most of our buyers there are trade customers, and we also serve retail orders.

## Products for Sindh hardware shops

- **Cabinet handles** in standard sizes for kitchens, wardrobes and office furniture
- **Cabinet knobs and drawer pulls** for everyday furniture
- **Door handles and main door pull handles**, with a specialty in solid brass
- Finishes including golden, matte black, chrome, antique brass and silver

Karachi's coastal humidity is hard on thin plated finishes, which is why many shops stock solid brass and stainless options. See our [material comparison](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles) and [care guide](/blog/how-to-clean-and-care-for-brass-matte-black-chrome-handles).

## Supplying Karachi, Larkana and Jacobabad

Shops in smaller cities like Larkana and Jacobabad often cannot find a full range locally. By ordering a mixed assortment from Lahore, you can offer customers more sizes and finishes without travelling to a big market. Read [what a hardware shop should stock](/blog/what-hardware-shops-should-stock-cabinet-handles-knobs) to plan your first order.

## How ordering works from Sindh

1. Send your list on WhatsApp at +92 311 7798157 or use the [bulk enquiry form](/contact).
2. We confirm stock, trade rates and delivery details.
3. Pay by bank transfer, or by Cash on Delivery through Leopard Courier where it covers your address.
4. We dispatch from Lahore, and you can follow the order on the [tracking page](/track-order).

More detail in [how to order wholesale from Lahore](/blog/how-to-order-wholesale-cabinet-handles-from-lahore).

## Frequently asked questions

### Do you supply cabinet handles wholesale in Karachi?

Yes. We supply hardware shops and trade buyers in Karachi from Lahore and ship by courier or cargo.

### Can a shop in Larkana or Jacobabad order from you?

Yes. We already send orders to both cities. Message us with your list and we will confirm rates and delivery.

### Which handle material is best for Karachi's humid weather?

Solid brass and stainless steel handle humidity better than thin-plated zinc alloy.

### Do you also sell retail in Sindh?

Yes. Individual customers can order a few pieces. Trade rates apply to wholesale quantities.

### Where do you ship from?

Our shop is at 218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan.
$md$,
$t$Cabinet Handles Wholesale Karachi & Sindh | Lahore Supplier$t$, $t$Wholesale cabinet handles, knobs and door hardware for hardware shops in Karachi, Larkana, Jacobabad and Sindh. Supplied from Lahore. Retail too.$t$, true, now() - interval '2 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$cabinet-handles-wholesale-azad-kashmir-mirpur$t$, $t$Cabinet Handles & Knobs Wholesale for Azad Kashmir (AJK) and Mirpur — Supplied from Lahore$t$, $t$Wholesale$t$, $t$Hardware shops and furniture makers in Mirpur and across Azad Kashmir can order cabinet handles, knobs and brass door hardware wholesale from Shahid Iqbal & Co in Lahore.$t$,
$md$
We already deliver to **Azad Kashmir (AJK)**, including **Mirpur**. **Shahid Iqbal & Co** is a Lahore-based supplier of cabinet handles, knobs and furniture hardware. Hardware shops and furniture workshops in AJK are among our regular trade customers, and we also take retail orders.

## What AJK buyers order

- **Cabinet handles and knobs** for kitchens, wardrobes and drawers
- **Brass door handles** for homes, built to last through summer heat and mountain-region humidity
- **Furniture hardware** for local carpenters and workshops
- Finishes in golden, matte black, chrome, antique brass and silver

Not sure which sizes to pick? Our [size guide](/blog/cabinet-handle-size-guide-drawers-doors-wardrobes) and [hole spacing guide](/blog/how-to-measure-cabinet-handle-hole-spacing) explain it simply.

## Why a Lahore supplier works for AJK shops

Many AJK shops would otherwise travel to a large city to restock. Ordering from Lahore lets you build a mixed assortment, check the exact specifications on each listing and have it delivered. Our [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan) shows the full range.

## How to order from Azad Kashmir

1. Send your list on WhatsApp at +92 311 7798157, or use the [bulk enquiry form](/contact).
2. We confirm availability, trade rates and delivery arrangements for your town.
3. Pay by bank transfer. Cash on Delivery depends on courier coverage, so ask us to confirm for your address.
4. We dispatch from Lahore, and you can follow the order on the [tracking page](/track-order).

## Frequently asked questions

### Do you deliver cabinet handles to Azad Kashmir?

Yes. We send orders to AJK, including Mirpur, by courier or cargo.

### Can I order wholesale handles in Mirpur?

Yes. Send us your list on WhatsApp for trade rates.

### Do you sell to individuals in AJK?

Yes. We also sell single pieces and small orders at retail.

### Is Cash on Delivery available in AJK?

It depends on the courier's coverage for your address. Bank transfer is always available. Ask us before ordering.

### How do I know my order is on its way?

Use the [order tracking page](/track-order) with your order number and email.
$md$,
$t$Cabinet Handles Wholesale AJK & Mirpur | Lahore Supplier$t$, $t$Wholesale cabinet handles, knobs and brass door hardware for hardware shops in Azad Kashmir (AJK) and Mirpur. Supplied from Lahore. Retail too.$t$, true, now() - interval '3 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$cabinet-handles-wholesale-faisalabad-multan-sialkot-punjab$t$, $t$Cabinet Handles & Knobs Wholesale for Faisalabad, Multan, Sialkot and Punjab$t$, $t$Wholesale$t$, $t$Hardware shops in Faisalabad, Multan, Sialkot and across Punjab can order cabinet handles, knobs and brass door hardware wholesale from Shahid Iqbal & Co, Lahore.$t$,
$md$
Punjab is our home market. **Shahid Iqbal & Co** supplies cabinet handles, knobs and furniture hardware from Lahore to hardware shops in **Faisalabad, Multan, Sialkot** and other Punjab cities. Most of our buyers are trade customers, and we sell at retail too.

## Products for Punjab hardware shops

- **Cabinet handles** in 64mm to 256mm hole spacing
- **Cabinet knobs and drawer pulls**
- **Brass door handles and main door pull handles**, our specialty
- Finishes in golden, matte black, chrome, antique brass and silver

Punjab summers are hot and monsoon humidity is heavy, so solid brass and stainless steel outlast thin plated finishes. See our [material comparison](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles).

## Faisalabad, Multan and Sialkot

Faisalabad, Multan and Sialkot all have active furniture and construction trades, and shops there benefit from a supplier close enough for quick restocking. We already send orders to all three. If you are in Gujranwala, Sargodha, Bahawalpur or elsewhere in Punjab, the same process applies.

## Lahore customers

If you are in Lahore, you can visit us at 218/18 Ferozepur Road, near WAPDA Hospital. See [where to buy cabinet handles and knobs in Lahore](/blog/cabinet-handles-knobs-lahore-where-to-buy).

## How to order

1. Browse the [shop](/shop) or send your list on WhatsApp at +92 311 7798157.
2. We confirm stock, trade rates and delivery details.
3. Pay by bank transfer, or Cash on Delivery through Leopard Courier where available.
4. Track the order on the [tracking page](/track-order).

Read [how to order wholesale from Lahore](/blog/how-to-order-wholesale-cabinet-handles-from-lahore) for details.

## Frequently asked questions

### Do you supply cabinet handles wholesale in Faisalabad?

Yes. We regularly supply hardware shops in Faisalabad from Lahore.

### Can Multan hardware shops order from you?

Yes. We already send orders to Multan. Send your list for trade rates.

### Do you supply Sialkot?

Yes. Sialkot shops and workshops can order by courier or cargo.

### Do you sell retail as well?

Yes. Single pieces and small orders are welcome at retail rates.

### How do I get a wholesale price list?

Message +92 311 7798157 on WhatsApp with the products and quantities you need.
$md$,
$t$Cabinet Handles Wholesale Faisalabad, Multan, Sialkot | Punjab$t$, $t$Wholesale cabinet handles, knobs and brass door hardware for shops in Faisalabad, Multan, Sialkot and Punjab. Supplied from Lahore. Retail too.$t$, true, now() - interval '4 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$cabinet-handles-wholesale-nowshera-khyber-pakhtunkhwa$t$, $t$Cabinet Handles & Knobs Wholesale for Nowshera and Khyber Pakhtunkhwa$t$, $t$Wholesale$t$, $t$Hardware shops in Nowshera and across Khyber Pakhtunkhwa can order cabinet handles, knobs and brass door hardware wholesale from Shahid Iqbal & Co in Lahore.$t$,
$md$
We already supply **Nowshera**, and the same service is available across **Khyber Pakhtunkhwa (KPK)**. **Shahid Iqbal & Co** is a Lahore-based supplier of cabinet handles, knobs and furniture hardware, working mainly with hardware shops and trade buyers, and also selling at retail.

## What KPK hardware shops order

- **Cabinet handles and knobs** for kitchens, wardrobes and drawers
- **Brass door handles** for homes and shops
- **Furniture hardware** for local carpenters and workshops
- Finishes in golden, matte black, chrome, antique brass and silver

See the [size guide](/blog/cabinet-handle-size-guide-drawers-doors-wardrobes) and [what a hardware shop should stock](/blog/what-hardware-shops-should-stock-cabinet-handles-knobs).

## Ordering from Nowshera and KPK

1. Send your list on WhatsApp at +92 311 7798157, or use the [bulk enquiry form](/contact).
2. We confirm availability, trade rates and delivery arrangements.
3. Pay by bank transfer, or Cash on Delivery through Leopard Courier where it covers your address.
4. We dispatch from Lahore. Follow the order on the [tracking page](/track-order).

See [how to order wholesale from Lahore](/blog/how-to-order-wholesale-cabinet-handles-from-lahore). Our [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan) covers the whole range.

## Frequently asked questions

### Do you supply cabinet handles to Nowshera?

Yes. We already send orders to Nowshera.

### Can hardware shops in Peshawar or other KPK cities order?

Yes. Message us your location and list and we will confirm delivery options.

### Do you sell retail in KPK?

Yes. Individual customers can order a few pieces.

### Is Cash on Delivery available in KPK?

It depends on courier coverage for your address. Bank transfer is always available.
$md$,
$t$Cabinet Handles Wholesale Nowshera & KPK | Lahore Supplier$t$, $t$Wholesale cabinet handles, knobs and brass door hardware for hardware shops in Nowshera and KPK. Supplied from Lahore. Retail also available.$t$, true, now() - interval '5 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$what-hardware-shops-should-stock-cabinet-handles-knobs$t$, $t$What Should a Hardware Shop Stock? Cabinet Handles & Knobs Buying Guide for Dealers$t$, $t$Wholesale$t$, $t$A practical guide for Pakistani hardware shops on which cabinet handle sizes, knobs, finishes and brass door handles to stock, and how to start with a mixed wholesale order.$t$,
$md$
Stocking handles and knobs is about covering the sizes customers ask for most, in finishes that match local taste, without tying up money in slow movers. This guide is for hardware shop owners and dealers in Pakistan, from a Lahore supplier that serves trade buyers.

## Cover the standard sizes first

Customers replacing a handle must match the existing **hole spacing**. That makes standard sizes the core of your stock. Common spacings are 64mm, 96mm, 128mm, 160mm, 192mm and 256mm. Read [how to measure hole spacing](/blog/how-to-measure-cabinet-handle-hole-spacing) so your counter staff can help customers measure.

| Size range | Customer use | Stock level |
|---|---|---|
| 64mm and 96mm | Small drawers, cupboards | Moderate |
| 128mm | Standard drawers, doors | Highest |
| 160mm and 192mm | Wide drawers, wardrobes | Moderate |
| 224mm and 256mm | Large wardrobes | Smaller |

These are starting points. Your own sales history matters more.

## Choose finishes that sell

Golden (brass tone), matte black and chrome cover most demand, with antique brass and silver as secondary options. Our [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) explains what suits each cabinet colour, which is useful when advising customers.

## Add knobs and door handles

Knobs are cheap, fast moving and easy to display. Brass main door handles carry a higher value per piece and suit customers building or renovating. See [how to choose a main door handle](/blog/how-to-choose-a-main-door-handle).

## Stock quality you can explain

Customers ask whether a handle will rust or fade. Brass and stainless steel handle Pakistan's heat and humidity better than thin plating, as our [material comparison](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles) explains.

## Start with a mixed assortment

Rather than one large order of a single design, begin with a mix of sizes and finishes, watch what sells and reorder. Send your budget and shop type on WhatsApp at +92 311 7798157 and we will suggest an assortment. Order details are in [how to order wholesale from Lahore](/blog/how-to-order-wholesale-cabinet-handles-from-lahore).

## Frequently asked questions

### Which cabinet handle size sells most?

128mm is the most widely used standard size for drawers and doors, but check your own sales and local demand.

### Should a hardware shop stock brass handles?

Brass costs more but lasts longer and suits main doors, so it is worth stocking in the most popular designs.

### Can I start with a small wholesale order?

Yes. Message us your budget and we will suggest a mixed starter assortment and confirm minimums.

### Do you supply shops outside Lahore?

Yes. We supply hardware shops across Punjab, Sindh, Azad Kashmir, KPK and Islamabad. See our [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan).
$md$,
$t$What Hardware Shops Should Stock: Handles & Knobs Guide$t$, $t$Which cabinet handle sizes, knobs and finishes should a hardware shop stock? A dealer guide for Pakistan from a Lahore wholesale supplier.$t$, true, now() - interval '6 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$how-to-order-wholesale-cabinet-handles-from-lahore$t$, $t$How to Order Wholesale Cabinet Handles & Knobs from Lahore — Payment, Delivery and Tracking$t$, $t$Wholesale$t$, $t$Step by step: how hardware shops and trade buyers anywhere in Pakistan order cabinet handles and knobs from Shahid Iqbal & Co, pay by bank transfer or COD, and track delivery.$t$,
$md$
Ordering from a supplier in another city should be simple. Here is how hardware shops, carpenters and contractors anywhere in Pakistan order from **Shahid Iqbal & Co** in Lahore.

## Step 1: Choose your products

Browse [cabinet handles](/shop?category=cabinet-handles), [knobs](/shop?category=cabinet-knob) and [main door handles](/shop?category=main-door-handle). Every listing shows the size, finish, material and hole spacing. Our [catalogue download](/shop) on the website helps when you are choosing offline.

## Step 2: Ask for a trade quote

For wholesale quantities, send your list on WhatsApp at +92 311 7798157, or use the [bulk enquiry form](/contact). Include products, finishes, quantities and your city. We reply with trade rates and delivery details.

## Step 3: Pay

- **Bank transfer:** bank details are shown at checkout, and we can share them on WhatsApp.
- **Cash on Delivery:** available through Leopard Courier where it covers your address. Ask us to confirm for your city.

## Step 4: Dispatch from Lahore

We pack and dispatch from Lahore by courier or cargo to cities including Karachi, Larkana, Jacobabad, Faisalabad, Multan, Sialkot, Mirpur, Nowshera, Islamabad and Azad Kashmir.

## Step 5: Track your order

Enter your order number and email on the [order tracking page](/track-order). Status updates as the order is packed, shipped and delivered.

## Retail orders

Single pieces and small orders follow the same checkout on the website, at retail prices.

## Related guides

- [Wholesale supplier overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan)
- [What a hardware shop should stock](/blog/what-hardware-shops-should-stock-cabinet-handles-knobs)
- [How to measure hole spacing](/blog/how-to-measure-cabinet-handle-hole-spacing)

## Frequently asked questions

### How do I place a wholesale order from outside Lahore?

Send your list on WhatsApp or the [bulk enquiry form](/contact), agree the quote, pay, and we dispatch from Lahore.

### Can I pay by bank transfer?

Yes. Bank transfer is always available.

### Is Cash on Delivery available?

Yes where Leopard Courier covers the address. Ask before ordering.

### Can I track my order?

Yes, on the [tracking page](/track-order) using your order number and email.

### Can I order retail quantities?

Yes. Use the website checkout.
$md$,
$t$How to Order Wholesale Cabinet Handles from Lahore$t$, $t$How hardware shops across Pakistan order wholesale cabinet handles and knobs from Lahore: WhatsApp quote, bank transfer or COD, delivery, tracking.$t$, true, now() - interval '7 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$cabinet-handles-knobs-lahore-where-to-buy$t$, $t$Cabinet Handles & Knobs in Lahore — Where to Buy, Retail and Wholesale$t$, $t$Lahore$t$, $t$Looking for cabinet handles, knobs and brass door handles in Lahore? Visit Shahid Iqbal & Co on Ferozepur Road for retail or wholesale, or order online with delivery.$t$,
$md$
If you are in Lahore and need cabinet handles, knobs or door hardware, **Shahid Iqbal & Co** supplies both retail customers and trade buyers. We are on Ferozepur Road, and we also deliver across the city and Pakistan.

## Visit us

**Shahid Iqbal & Co**, 218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan. Phone and WhatsApp: +92 311 7798157.

## What you can buy in Lahore

- **Cabinet handles** for kitchens, drawers and wardrobes
- **Cabinet knobs** and drawer pulls
- **Door handles and brass main door handles**, our specialty
- Finishes in golden, matte black, chrome, antique brass and silver

## Retail or wholesale

- **Retail:** buy a few pieces for your home, in store or through the website.
- **Wholesale:** hardware shops, carpenters, contractors and interior designers can ask for trade rates. See our [wholesale supplier overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan).

## Before you buy

Measure the distance between your screw holes first. Our [hole spacing guide](/blog/how-to-measure-cabinet-handle-hole-spacing) and [size guide](/blog/cabinet-handle-size-guide-drawers-doors-wardrobes) take two minutes. Lahore's hot summers and monsoon humidity are tough on thin finishes, so see the [material comparison](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles).

## Beyond Lahore

We also supply [Islamabad](/blog/cabinet-handles-wholesale-islamabad-rawalpindi), [Karachi and Sindh](/blog/cabinet-handles-wholesale-karachi-sindh), [Azad Kashmir](/blog/cabinet-handles-wholesale-azad-kashmir-mirpur), [Faisalabad, Multan and Sialkot](/blog/cabinet-handles-wholesale-faisalabad-multan-sialkot-punjab) and [Nowshera and KPK](/blog/cabinet-handles-wholesale-nowshera-khyber-pakhtunkhwa).

## Frequently asked questions

### Where can I buy cabinet handles in Lahore?

At Shahid Iqbal & Co, 218/18 Ferozepur Road, near WAPDA Hospital, or online at www.siqbalhwc.com.

### Do you sell brass door handles in Lahore?

Yes. Brass is our specialty. See [how to choose a main door handle](/blog/how-to-choose-a-main-door-handle).

### Do you offer wholesale rates in Lahore?

Yes, for hardware shops, carpenters and contractors. Message us on WhatsApp.

### Do you deliver within Lahore?

Yes. Contact us for delivery arrangements to your area.
$md$,
$t$Cabinet Handles & Knobs in Lahore | Retail & Wholesale$t$, $t$Buy cabinet handles, knobs and brass door handles in Lahore, retail or wholesale. Shahid Iqbal & Co, Ferozepur Road. Delivery across Pakistan.$t$, true, now() - interval '8 minutes')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$how-to-measure-cabinet-handle-hole-spacing$t$, $t$How to Measure Cabinet Handle Hole Spacing (Guide for Pakistan Buyers and Hardware Shops)$t$, $t$Sizing$t$, $t$The one measurement that decides whether a two-hole handle fits your cabinet, and how to take it in two minutes with just a ruler. Useful for home owners, carpenters and hardware shops.$t$,
$md$
Buying a handle that doesn't fit is the most common and most avoidable hardware mistake. The measurement that decides it is **hole spacing**, also called centre-to-centre distance. This guide is for home owners, carpenters and hardware shop staff across Pakistan, written by a Lahore supplier that serves both retail and wholesale buyers.

## What hole spacing means

Hole spacing is the distance from the **centre of one screw hole to the centre of the other**. It is not the handle's overall length. A handle with 128mm hole spacing is longer than 128mm in total, because it extends past the screws at each end.

## How to measure it, step by step

1. If there is an old handle, unscrew it so you can see both holes.
2. Lay a ruler across the holes. Line up zero with the **centre** of the first hole.
3. Read the number at the centre of the second hole. That is your hole spacing.
4. Note it in millimetres, because handles are specified in mm.
5. Measure the thickness of the door or drawer front too. It tells you what screw length you need.

If your cabinets are new, choose the handle first and drill to match. A paper strip marked with the two hole centres makes every handle land in the same position.

## Common hole spacings

| Hole spacing | Approx. inches | Typical use |
|---|---|---|
| 64mm | 2.5 in | Small drawers, cupboard doors |
| 96mm | 3.8 in | Kitchen drawers and doors |
| 128mm | 5 in | Standard drawers, larger doors |
| 160mm | 6.3 in | Wide drawers, wardrobe doors |
| 192mm | 7.6 in | Large drawers, tall doors |
| 224mm and 256mm | 8.8 and 10 in | Very wide drawers, wardrobes |

These are standard sizes, so matching handles exist for almost any cabinet. See the [cabinet handle size guide](/blog/cabinet-handle-size-guide-drawers-doors-wardrobes) for choosing the right length.

## Tips for hardware shops

Customers often walk in with a worn handle and no measurement. Keep a steel ruler and a hole-spacing chart at the counter so you can match handles on the spot. Our guide on [what a hardware shop should stock](/blog/what-hardware-shops-should-stock-cabinet-handles-knobs) lists the sizes to keep.

## Non-standard holes

Older or custom cabinets sometimes have non-standard spacing. Use a single-hole knob and fill the spare hole, or send us your measurement on WhatsApp at +92 311 7798157 and we will suggest the closest match. Browse [cabinet handles](/shop?category=cabinet-handles) and [cabinet knobs](/shop?category=cabinet-knob). Trade buyers in Lahore, Islamabad, Karachi and across Pakistan can read our [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan).

## Frequently asked questions

### Is hole spacing the same as handle length?

No. Hole spacing is the distance between the screw holes. The overall length is longer. Always match hole spacing when replacing a handle.

### What is the most common cabinet handle size in Pakistan?

96mm and 128mm hole spacing are the most widely used standard sizes for kitchen and bedroom drawers and doors.

### Do knobs need hole spacing?

No. A knob uses a single screw. Just check the screw is long enough for the door thickness.

### Can I fit a handle with a different hole spacing?

Only by drilling new holes and filling the old ones. A 128mm handle will not fit holes 160mm apart.

### Where can I buy handles by exact hole spacing in Lahore?

At Shahid Iqbal & Co, 218/18 Ferozepur Road, Lahore, or online. Every listing shows the exact size.
$md$,
$t$How to Measure Cabinet Handle Hole Spacing | Lahore$t$, $t$Measure cabinet handle hole spacing in two minutes with a ruler. Common sizes in mm, for home owners, carpenters and hardware shops in Pakistan.$t$, true, now() - interval '1 day')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$brass-vs-stainless-steel-vs-zinc-alloy-handles$t$, $t$Brass vs Stainless Steel vs Zinc Alloy Handles — Best Material for Pakistan's Heat and Humidity$t$, $t$Materials$t$, $t$How brass, stainless steel, zinc alloy and aluminium handles compare for feel, durability and upkeep in Pakistan's climate, for home owners and hardware shops.$t$,
$md$
The material decides how a handle feels, how it ages and how long it lasts. This comparison is written by **Shahid Iqbal & Co**, a Lahore supplier that specialises in brass and serves both home owners and hardware shops across Pakistan.

## Brass

Brass is a dense copper-and-zinc alloy. It is heavy, solid and does not rust, because it contains no iron. It can darken and develop a warm patina unless it is lacquered. It usually costs more, but it is the traditional choice for pieces meant to last, especially main door handles.

## Stainless steel

Stainless steel resists rust and stains and is very strong, so it suits kitchens and bathrooms. It has a cool, modern look, and brushed finishes hide fingerprints. Designs tend to be simpler.

## Zinc alloy

Zinc alloy is cast in a mould, which allows detailed shapes at a lower price. The colour is a plated or coated finish, so finish quality matters most. It works for wardrobes and bedrooms, but heavy daily use can wear a thin coating.

## Aluminium

Aluminium is light and does not rust, but it is softer and can dent or scratch. It suits light-use cupboards.

## Quick comparison

| Material | Feel | How it ages | Best for |
|---|---|---|---|
| Brass | Heavy, solid | Warm patina, or bright if lacquered | Main doors, kitchens, long-term use |
| Stainless steel | Solid, cool | Very little change | Kitchens, bathrooms |
| Zinc alloy | Medium weight | Depends on finish quality | Wardrobes, bedrooms |
| Aluminium | Light | Can scratch or dent | Light-use cupboards |

## Which should you choose?

- **Kitchen:** brass or stainless steel
- **Bedroom and wardrobe:** zinc alloy or brass, depending on budget
- **Bathroom:** stainless steel or brass
- **Main door:** brass, because of sun, dust and rain

Summers in Lahore, Multan and Sindh are hot, monsoon humidity is heavy, and Karachi's coastal air is hard on thin plating. Solid brass or stainless steel is the safer long-term choice for hardware you touch every day.

## For hardware shops

Customers ask whether a handle will rust or fade, so stock at least a few solid brass designs. See [what a hardware shop should stock](/blog/what-hardware-shops-should-stock-cabinet-handles-knobs) and our [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan).

## How to judge quality when you shop

- **Weight:** solid pieces feel heavier than thin ones.
- **Finish:** even, with no rough patches or bubbles.
- **Edges and threads:** smooth edges and clean threads.
- **Honest listings:** material stated clearly. Browse [door handles](/shop?category=main-door-handle) or [cabinet handles](/shop?category=cabinet-handles).

## Frequently asked questions

### Is brass better than zinc alloy?

Generally brass is more durable and substantial, while zinc alloy offers detailed designs at a lower price.

### Will brass rust?

No. Rust needs iron, and brass contains none. It may tarnish, which is normal. See our [care guide](/blog/how-to-clean-and-care-for-brass-matte-black-chrome-handles).

### Which material is best for humid areas like Karachi?

Stainless steel and brass cope well with moisture. Avoid thin-plated handles in bathrooms and kitchens.

### Where can I buy brass handles wholesale in Pakistan?

Shahid Iqbal & Co supplies brass handles wholesale from Lahore to hardware shops across Pakistan. Retail orders are welcome too.
$md$,
$t$Brass vs Stainless Steel vs Zinc Alloy Handles | Pakistan$t$, $t$Compare brass, stainless steel, zinc alloy and aluminium handles for Pakistan's heat and humidity. A guide from a Lahore brass hardware supplier.$t$, true, now() - interval '1 day')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$matte-black-golden-chrome-choosing-a-handle-finish$t$, $t$Matte Black, Golden or Chrome? Choosing a Handle Finish (and What Sells in Hardware Shops)$t$, $t$Finishes$t$, $t$A practical guide to picking a handle finish that suits your cabinet colour, taps and lights, and how much cleaning you want to do. Includes tips for hardware shops.$t$,
$md$
Finish is the first thing people notice about a handle and the hardest to change later. Here is how to choose one for your cabinets, and how each finish behaves in daily use. It is written by a Lahore supplier that serves home owners and hardware shops across Pakistan.

## The main finishes

**Golden (brass tone)** is warm and classic. It stands out against white, navy and forest green and looks rich on dark wood. Polished gold shows fingerprints more than satin versions.

**Matte black** is modern and high-contrast. It suits white, grey and light wood cabinets and hides fingerprints better than polished finishes. In kitchens, wipe grease marks regularly.

**Chrome** is bright, cool and neutral. It matches taps and appliances. It shows water spots but wipes clean fast.

**Antique brass** is a darker, aged tone for traditional interiors.

**Silver** is a soft neutral tone that sits quietly in almost any room.

## Which finish goes with which cabinet colour?

| Cabinet colour | Finishes that work well |
|---|---|
| White | Matte black, golden or chrome |
| Natural or light wood | Matte black or antique brass |
| Dark wood | Golden or antique brass |
| Navy or green | Golden |
| Grey | Matte black or chrome |

## Match the rest of the room

Look at taps, lights and door hardware. Choose one **dominant metal** and at most one **accent**. Mixing can look deliberate, but three or four metals look accidental.

## Practical tips before you order

- **Order everything for a room at once.** Finish shades can vary slightly between batches.
- **Think about the light.** Warm light makes golden glow, and cool light does the opposite.
- **Consider cleaning.** Brushed and satin forgive fingerprints.
- **Ask for help.** Send a photo of your cabinets on WhatsApp at +92 311 7798157. Browse [cabinet handles](/shop?category=cabinet-handles) and [knobs](/shop?category=cabinet-knob).

## For hardware shops

Golden, matte black and chrome cover most demand, with antique brass and silver as secondary choices. Buy each design in matching batches so reorders look consistent on the shelf. See [what a hardware shop should stock](/blog/what-hardware-shops-should-stock-cabinet-handles-knobs) and the [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan).

## Frequently asked questions

### Can I mix different finishes in one room?

Yes, if it is deliberate. Keep one dominant metal and repeat any accent finish at least twice.

### Which finish is easiest to keep clean?

Brushed and satin hide fingerprints best. Read our [care guide](/blog/how-to-clean-and-care-for-brass-matte-black-chrome-handles).

### Does matte black wear off?

It can wear at the edges with heavy use or abrasive cleaners. Use a soft damp cloth and mild soap.

### Which finish do hardware shops sell most?

Golden, matte black and chrome are the core finishes. Check your own sales, since local taste differs by city.

### Can I buy handles in all these finishes wholesale?

Yes. Shahid Iqbal & Co supplies trade buyers across Pakistan from Lahore. Ask for a quote.
$md$,
$t$Matte Black, Golden or Chrome Handle Finish Guide | Pakistan$t$, $t$Choose between matte black, golden, chrome and antique brass handle finishes. A guide for home owners and hardware shops from a Lahore supplier.$t$, true, now() - interval '1 day')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$cabinet-handle-size-guide-drawers-doors-wardrobes$t$, $t$Cabinet Handle Size Guide for Drawers, Doors and Wardrobes (with Hole Spacing Chart)$t$, $t$Sizing$t$, $t$How long should a handle be for a drawer, kitchen door or wardrobe? Simple proportion rules, a quick-reference table and where to position handles.$t$,
$md$
Once you know your hole spacing (see [how to measure hole spacing](/blog/how-to-measure-cabinet-handle-hole-spacing)), the next question is size. A handle that is too small looks lost on a wide drawer, and one that is too big overwhelms a small cupboard. This guide serves home owners, carpenters and hardware shops across Pakistan.

## Simple proportion rules

- **Drawers:** a handle about one third of the drawer front's width looks balanced. On narrow drawers it can reach about half.
- **Wide drawers:** over about 75 cm, consider two handles at roughly a quarter and three quarters across, or one long handle.
- **Doors:** place the handle or knob near the edge opposite the hinges. Tall doors suit vertical handles.
- **Small cupboards:** knobs or short handles look best.

## Quick reference

| Fitted to | Suggested hole spacing | Notes |
|---|---|---|
| Small cupboard door (up to about 40 cm wide) | Knob, or 64–96mm | Knobs keep small doors uncluttered |
| Kitchen drawer (40–60 cm wide) | 96–128mm | Centre on the drawer front |
| Wide drawer (60–90 cm wide) | 128–192mm | Or two handles |
| Tall wardrobe door | 160–256mm, fitted vertically | Easier to grip |

These are starting points. Your cabinets and taste matter more than any table.

## Where to position handles

- **Drawers:** centred left to right, centred or slightly above the middle vertically.
- **Base cabinet doors:** near the top corner, opposite the hinge side.
- **Wall cabinet doors:** near the bottom corner, opposite the hinge side.
- **Distance from the edge:** about 5 cm from the corner.
- **Use a template:** a small card with hole positions marked keeps every handle identical.

![Wardrobe handle height guide](/guides/wardrobe-handle-height.png)

## Knob or handle?

Knobs are neat on small doors and drawers but offer less grip. Handles suit larger and heavier fronts. Many kitchens use knobs on doors and handles on drawers. Browse [cabinet knobs](/shop?category=cabinet-knob) and [cabinet handles](/shop?category=cabinet-handles).

## Check the clearance

Hold the handle against the door and make sure it will not knock a neighbouring door, appliance or corner cabinet.

## For carpenters and hardware shops

Carpenters usually buy one design in large quantities for a whole kitchen or wardrobe project. Match quantities in one batch so finishes are identical. Trade buyers in Lahore, Islamabad, Karachi and across Pakistan can see our [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan) and [stocking guide](/blog/what-hardware-shops-should-stock-cabinet-handles-knobs).

## Frequently asked questions

### Can I use a longer handle than the one I have now?

Only if the hole spacing matches, or you drill new holes and fill the old ones.

### How many handles does a wide drawer need?

Two evenly spaced handles are easier to use on very wide drawers. One long centred handle can also work.

### What size handle is best for a wardrobe door?

Around 160mm to 256mm hole spacing, fitted vertically, is popular.

### What handle size is best for kitchen drawers in Pakistan?

96mm and 128mm hole spacing are the most commonly used sizes.

### Do you sell all these sizes wholesale?

Yes. Shahid Iqbal & Co supplies hardware shops across Pakistan from Lahore.
$md$,
$t$Cabinet Handle Size Guide: Drawers, Doors, Wardrobes | Lahore$t$, $t$Choose the right cabinet handle size for drawers, kitchen doors and wardrobes. Proportion rules, hole spacing table and positions from a Lahore supplier.$t$, true, now() - interval '1 day')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$how-to-choose-a-main-door-handle$t$, $t$How to Choose a Main Door Handle for Your Home (Brass Door Handles in Pakistan)$t$, $t$Door hardware$t$, $t$Door thickness, lock type, handle size, material and fitting: a practical checklist for choosing a main door handle that fits and lasts.$t$,
$md$
The main door handle is the first thing visitors touch and the hardware used most every day. This checklist covers what to check before you order. It comes from **Shahid Iqbal & Co**, a Lahore supplier that specialises in brass door hardware and supplies home owners, contractors and hardware shops across Pakistan.

## Start with the door

- **Door thickness.** Most doors are between 35 mm and 50 mm thick, but measure yours.
- **The lock.** Mortise lock (inside the door), rim lock (on the surface) or a separate latch? The handle must work with it.
- **Existing fixing holes.** Measure centre to centre and check whether the handle is fixed from one side or through the door.

## Pull handle or lever handle?

**Pull handles** are fixed bars you grip and pull. They suit entrance doors with their own lock. **Lever handles** turn to operate a latch and are common on interior doors.

## Choosing the size

![Door handle size guide](/guides/door-handle-sizes.png)

Long pull handles from around 400 mm to well over a metre are common on tall or wide entrance doors. Pick a length proportionate to the door and easy to grip. Handles are usually fitted around 100 cm from the floor.

## Material and finish

Outside doors face sun, dust and rain, so material matters. Solid brass is long-lasting and ages gracefully, which is why it is our specialty. Read the [material comparison](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles) and the [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish).

## A handle is not a lock

Security comes from the lock, hinges and frame. Choose your lock separately and make sure the handle and lock work together.

## Fitting checklist

1. Measure door thickness and hole spacing before ordering.
2. Check projection so the handle clears the frame and wall.
3. Use the supplied fixings and confirm screw length.
4. Drilling solid wood or metal needs proper tools. Consider a carpenter.
5. Tighten firmly but not over-tight, and re-check after a few weeks.

Browse [main door handles](/shop?category=main-door-handle) and message us on WhatsApp at +92 311 7798157 with your measurements.

## For contractors and hardware shops

Builders and shops across Lahore, Islamabad, Karachi, Faisalabad, Multan and Azad Kashmir order brass door handles from us in trade quantities. See the [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan).

## Frequently asked questions

### Can I change the handle without changing the lock?

Often yes, if the fixing holes line up or it is a simple surface-fitted pull. Send us your measurements.

### What height should a main door handle be?

Around 100 cm from the floor is common. Follow the position of your existing handle or lock.

### How do I know if I need a pull handle or a lever handle?

If the door opens by pulling a fixed bar and has a separate lock, you need a pull handle. If the handle turns to release a latch, you need a lever.

### Where can I buy brass door handles in Lahore or Pakistan?

At Shahid Iqbal & Co, 218/18 Ferozepur Road, Lahore, or online with delivery across Pakistan. Wholesale and retail are both available.
$md$,
$t$How to Choose a Main Door Handle | Brass, Lahore$t$, $t$Choose a main door handle: door thickness, lock type, size, material and fitting. Brass door handles from a Lahore supplier with delivery across Pakistan.$t$, true, now() - interval '1 day')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$how-to-clean-and-care-for-brass-matte-black-chrome-handles$t$, $t$How to Clean and Care for Brass, Matte Black and Chrome Handles$t$, $t$Care$t$, $t$Most hardware damage comes from the wrong cleaner. Here is what is safe for brass, matte black and chrome, and what to avoid. Useful for home owners and for shops advising customers.$t$,
$md$
Most damage to handles and knobs comes from the wrong cleaner, not from daily use. The safest method is also the simplest. This guide is from a Lahore hardware supplier, and hardware shops can pass it on to customers.

## The basic routine

1. Mix a little mild dish soap into warm water.
2. Wipe with a soft or microfibre cloth wrung out well.
3. Wipe again with a cloth dampened with clean water.
4. **Dry immediately** to prevent water spots.

In kitchens, do this every week or two, because grease builds up. Elsewhere, once a month is plenty. In dusty or humid cities, wipe door handles more often.

## Brass

Most decorative brass is lacquered. Use soap and water only. **Do not use metal polish on lacquered brass**, because it strips the lacquer and leaves patchy spots. If a piece is unlacquered and dull, use brass polish exactly as the label says, or let it develop a natural patina.

## Matte black

Scrubbing damages matte black. Use a damp microfibre cloth and mild soap. Avoid scouring powders and abrasive pads.

## Chrome

Chrome cleans easily with soap and water. Dry it to avoid spots. Avoid bleach and strong acid or chlorine cleaners.

## Golden and other plated finishes

Treat them gently: mild soap, soft cloth, no abrasives or harsh chemicals. A thin plated layer can wear through if scrubbed.

## What to avoid on every finish

- Bleach and strong household cleaners
- Steel wool, scouring pads and gritty powders
- Spraying cleaner directly on the handle (spray the cloth instead)
- Leaving wet cloths or soapy water on the surface

## Keep handles firm

Every few months, check that handles are tight. Tighten by hand without over-tightening.

## Choosing hardware that is easy to keep clean

Brushed and satin finishes hide fingerprints, while polished chrome and gold show them but wipe clean. See the [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) and compare [cabinet handles](/shop?category=cabinet-handles). Solid brass lasts longest, as the [material comparison](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles) explains.

## Frequently asked questions

### How often should I clean my handles?

Every week or two in kitchens, and about once a month elsewhere.

### Can I use vinegar or lemon to clean handles?

Acidic cleaners can damage some coatings. Mild soap and water is safer. Test any alternative on a hidden spot first.

### Why has my handle gone dull?

Usually built-up grease, dust or hand oils, which soap and water will lift. If the finish has worn through, replacing the handle is the practical fix.

### Do you supply brass handles wholesale?

Yes. Shahid Iqbal & Co supplies hardware shops across Pakistan from Lahore. See the [wholesale overview](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan).
$md$,
$t$How to Clean Brass, Matte Black & Chrome Handles | Lahore$t$, $t$Clean brass, matte black and chrome handles safely. What works, what to avoid, and how often, from a Lahore hardware supplier serving all of Pakistan.$t$, true, now() - interval '1 day')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt,
  content = pg_temp.keep_images(blog_posts.content, excluded.content),
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();
