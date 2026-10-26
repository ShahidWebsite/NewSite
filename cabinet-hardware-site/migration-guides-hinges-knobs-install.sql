-- ============================================================================
-- New buying guides: piano hinges, brass & antique knobs, and fitting handles.
-- Paste this whole block into Supabase -> SQL Editor and click Run.
-- Safe to run more than once (it updates the same three guides, never duplicates).
--
-- These topics were missing from the guides section. The links inside them point
-- only to pages that already exist (category pages and your other guides).
-- ============================================================================

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$piano-hinges-guide-sizes-materials-how-to-fit$t$, $t$Piano Hinges in Pakistan: Sizes, Materials and How to Fit Them$t$, $t$Hinges$t$, $t$A piano hinge (continuous hinge) runs the full length of a door, lid or flap. Here is how to choose the size and material, cut it to length and fit it so it opens smoothly.$t$,
$md$
A piano hinge is one long hinge that runs the full height or width of a door, lid or flap, instead of two or three small hinges. It is also called a **continuous hinge**. Because it supports the door along its whole edge, it keeps long or heavy panels straight and stops them sagging. This guide from **Shahid Iqbal & Co**, a Lahore supplier of furniture hardware, explains how to choose one, how to cut it to length and how to fit it.

## What is a piano hinge?

A piano hinge is two long metal leaves joined by a single pin that runs through all the knuckles. It got its name from piano lids, which it was first used on. Today you will find it on:

- fold-down flaps and drop-leaf tables
- long cupboard, wardrobe and locker doors
- display cabinets, toolboxes and storage boxes
- lids, counters and service hatches
- shop fittings, kitchen worktop flaps and workshop benches

## Piano hinge or ordinary butt hinges?

| | Piano hinge | Two or three butt hinges |
|---|---|---|
| Support | Along the whole edge | At a few points only |
| Sagging on long doors | Very little | Can sag between hinges |
| Look | Continuous line, can be hidden or neat | Hinge knuckles visible at set points |
| Fitting | Many screws, needs careful alignment | Quick to fit |
| Best for | Long, heavy or lift-up panels | Standard cupboard and room doors |

If a door or flap is long and narrow, a piano hinge is usually the better choice. For a normal cupboard door, ordinary hinges are simpler.

## Choosing the material

- **Iron or mild steel.** The most affordable option. Fine for dry indoor furniture. If the coating is scratched it can rust, so keep it away from damp areas.
- **Stainless steel.** Resists rust. A good choice for kitchens, bathrooms and anywhere humid. Read our [material comparison](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles).
- **Brass.** Looks warm and decorative, resists corrosion and suits classic furniture and display cabinets. It is softer than steel, so do not use it for very heavy loads.
- **Aluminium.** Light and rust-free, suited to light lids and small flaps.

## Choosing the size

Piano hinges are described by a few measurements. Check each one on the product listing before you order:

1. **Length.** Hinges are sold in long strips and can be cut shorter. Choose a strip at least as long as the edge you are fitting.
2. **Open width.** The width of both leaves laid flat. This decides how much of the door and the frame the hinge covers.
3. **Thickness.** Thicker metal carries more weight and bends less.
4. **Hole spacing and screw size.** Make sure the screws that fit your hinge suit your board (see below).

For heavier doors choose a wider, thicker hinge. Do not use a thin, light hinge on a heavy panel.

## How to cut a piano hinge to length

1. Measure the edge you will fit and mark the hinge.
2. Hold the hinge steady in a vice or clamp it to a bench.
3. Cut through the leaves and the pin together with a fine-tooth hacksaw, or a cutting disc if you have one.
4. File the cut end smooth so it does not catch or scratch.
5. Check that the hinge opens and closes freely before fitting.

## How to fit a piano hinge

1. **Mark the position.** Decide whether the hinge will sit on the surface or be recessed. Mark a straight line along the edge.
2. **Fit the hinge to the frame first.** Hold it against the line with the knuckle facing the right way and mark each screw hole.
3. **Drill pilot holes** for every screw. In chipboard and MDF this stops the board splitting and helps the screws grip.
4. **Fix with matching screws.** Use screws that sit flush with the leaf and are short enough not to push through the other side.
5. **Fit the door or flap.** Support it level, mark the other leaf, drill and fix.
6. **Check the swing.** If it binds, loosen the screws a little and adjust.

## Common mistakes

- Using a hinge that is too thin for the weight of the door.
- Skipping pilot holes, so the board splits or the screws pull out.
- Fitting only a few screws. A piano hinge works best with a screw in every hole.
- Not lining the two leaves up, which makes the door twist or rub.
- Choosing iron for a damp room where it will rust.

## Order piano hinges from Lahore

Browse our [hinges](/hinges) or send us the length and material you need on WhatsApp at +92 311 7798157 and we will tell you what we have in stock. We supply home owners, carpenters and hardware shops across Pakistan, with delivery by bank transfer or Cash on Delivery. Shops can read about [wholesale orders](/blog/wholesale-cabinet-handles-knobs-supplier-pakistan).

## Frequently asked questions

### What is a piano hinge used for?

It is used on long doors, lids and fold-down flaps where support is needed along the whole edge, such as drop-leaf tables, display cabinets, toolboxes and long cupboard doors.

### Can I cut a piano hinge to a shorter length?

Yes. Cut it with a fine-tooth hacksaw or a cutting disc, cutting through the pin as well, then file the end smooth.

### Which material is best for a piano hinge in humid weather?

Stainless steel or brass resist rust better than plain iron, so they suit kitchens, bathrooms and humid rooms.

### How many screws does a piano hinge need?

Use a screw in every hole. The load is then spread across the whole length, which is the whole point of a piano hinge.

### Where can I buy piano hinges in Lahore?

At Shahid Iqbal & Co, 218/18 Ferozepur Road, near WAPDA Hospital, Lahore, or online with delivery across Pakistan.
$md$,
$t$Piano Hinges in Pakistan: Sizes, Materials, Fitting$t$, $t$How to choose a piano (continuous) hinge: material, size, cutting to length and fitting. Hinges from a Lahore supplier with delivery across Pakistan.$t$, true, now() - interval '3 hours')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt, content = excluded.content,
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$brass-antique-cabinet-knobs-guide-pakistan$t$, $t$Brass and Antique Cabinet Knobs: Sizes, Styles and How to Choose$t$, $t$Knobs$t$, $t$Solid brass and antique-style knobs suit dressing tables, wardrobes and classic furniture. Learn how knobs differ from pull handles, how big they should be and where to place them.$t$,
$md$
A cabinet knob is a single-fixing handle that you grip with your fingers. Brass and antique-style knobs, in shapes such as leaves, flowers, birds and butterflies, are popular for dressing tables, wardrobes, bedside tables and classic furniture. This guide from **Shahid Iqbal & Co**, a Lahore supplier that specialises in brass hardware, explains how to choose the right knob.

## Knob or pull handle?

| | Knob | Pull handle |
|---|---|---|
| Fixing | One screw, one hole | Two screws, two holes |
| Best on | Small doors, drawers, dressing tables | Wide drawers, wardrobes, kitchens |
| Grip | Fingertips | Whole hand |
| Look | Decorative, classic | Clean, modern or classic |

Neither is better in every case. A common approach is **knobs on doors and small drawers, pull handles on wide drawers**, in the same finish so the set looks coordinated. See our [cabinet knobs](/cabinet-knob) and [cabinet handles](/cabinet-handles).

## Why brass?

Brass looks warm and rich, and it does not rust like iron does. It ages gracefully and can be polished to bring the shine back. Our guide to [brass, stainless steel and zinc alloy](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles) compares them for Pakistan's heat and humidity. Solid brass costs more than zinc alloy and is the usual choice for pieces you want to last.

## Choosing the style

- **Leaf, flower and butterfly knobs** suit dressing tables, jewellery chests and bedroom furniture.
- **Bird and animal knobs** are popular on children's furniture and decorative pieces.
- **Plain round or ball knobs** work almost anywhere and suit a simple, classic look.

Match the knob to the age and style of the furniture. A decorative knob on a modern flat-panel kitchen can look out of place, while a plain round one fits nearly anything.

## Choosing the finish

Golden and antique brass finishes suit warm woods, cream and white paint. Antique finishes hide fingerprints better and look older. Our [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) covers matte black, golden and chrome.

## Size and fixing

Check these on the product page:

- **Diameter.** Knobs commonly range from small knobs for jewellery boxes to larger ones for wardrobe doors. Bigger furniture usually looks better with a bigger knob.
- **Projection.** How far it sticks out. Make sure it clears neighbouring doors and drawers when they open.
- **The screw.** Most knobs fix with one machine screw through the door into a threaded hole in the knob. Check the screw length against your door thickness. Thicker doors need a longer screw.
- **Hole size.** You only need a single hole, so measure the hole size your knob needs before you drill.

## Where to put knobs

These are common starting points, not strict rules:

- **Cupboard doors:** about 50 to 75 mm in from the edge of the door that opens, near the top corner on base units and the bottom corner on wall units.
- **Narrow drawers:** one knob in the centre.
- **Wide drawers:** two knobs, roughly a quarter and three-quarters of the way across.

Fitting is covered step by step in our [guide to installing handles and knobs](/blog/how-to-install-cabinet-handles-and-knobs).

## Caring for brass knobs

Wipe with a soft dry cloth. Avoid harsh chemicals and abrasive pads, which damage the finish. See [how to clean and care for brass handles](/blog/how-to-clean-and-care-for-brass-matte-black-chrome-handles).

## Brass knobs for hardware shops

Hardware shops and carpenters across Pakistan order decorative brass knobs from us in trade quantities. See [how to order wholesale](/blog/how-to-order-wholesale-cabinet-handles-from-lahore).

## Frequently asked questions

### How big should a cabinet knob be?

Choose a size in proportion to the door or drawer. Small furniture suits small knobs, and large wardrobes suit larger ones. Check the diameter and projection on the product page.

### How many knobs does a wide drawer need?

Two knobs placed roughly a quarter and three-quarters of the way across looks balanced and is easier to open than one.

### Are brass knobs better than zinc alloy knobs?

Brass is heavier, ages well and can be polished, so it suits pieces meant to last. Zinc alloy costs less and works well for everyday furniture.

### Do I need special screws for thick doors?

If your door is thicker than the screw supplied, you need a longer machine screw of the same thread. Check before drilling.

### Where can I buy brass cabinet knobs in Lahore?

At Shahid Iqbal & Co, 218/18 Ferozepur Road, near WAPDA Hospital, Lahore, or online with delivery across Pakistan.
$md$,
$t$Brass & Antique Cabinet Knobs: Sizes and Styles Guide$t$, $t$How to choose brass and antique cabinet knobs: knob vs pull, size, style, finish and placement. From a Lahore supplier, delivered across Pakistan.$t$, true, now() - interval '2 hours')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt, content = excluded.content,
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();

insert into blog_posts (slug, title, tag, excerpt, content, seo_title, seo_description, published, published_at)
values ($t$how-to-install-cabinet-handles-and-knobs$t$, $t$How to Install Cabinet Handles and Knobs: Marking, Drilling and Fitting$t$, $t$Installation$t$, $t$A step-by-step guide to fitting cabinet handles and knobs neatly: how to mark the holes, drill without splitting the board, choose the right screws and line up a whole set.$t$,
$md$
Fitting a handle takes a few minutes, but a crooked or badly drilled handle shows every time you open the door. This guide from **Shahid Iqbal & Co** shows how to mark, drill and fit cabinet handles and knobs so that they line up and stay tight.

## What you need

- the handles or knobs and the screws that came with them
- a tape measure and a pencil
- masking tape
- a drill and drill bits
- a screwdriver (hand tightening gives the best feel)
- a scrap piece of wood to drill onto
- a spirit level or a straight edge

## Step 1: Check the hole spacing

For a two-hole handle, the size is the distance between the centres of the two screw holes. If you are replacing old handles, measure your existing holes and choose a new handle with the same spacing. Our guide [how to measure cabinet handle hole spacing](/blog/how-to-measure-cabinet-handle-hole-spacing) explains this in detail. Drilling new holes is only needed if the spacing is different. Our [handle size guide](/blog/cabinet-handle-size-guide-drawers-doors-wardrobes) helps you choose a suitable size.

## Step 2: Decide the position

Handles look best when they are placed consistently across the whole set. These are common starting points:

- **Cupboard doors:** about 50 to 75 mm from the edge that opens. Near the top corner on base units, near the bottom corner on wall units.
- **Drawers:** in the centre of the drawer front. On wide drawers, use two knobs or a longer handle.
- **Wardrobe doors:** roughly at hand height, lined up across all doors.

## Step 3: Make a template

Mark the hole positions once, on a strip of card or thin plywood, and use it for every door and drawer. This is far quicker and more accurate than measuring each one, and it keeps the whole set identical.

1. Cut a piece of card the size of a door corner.
2. Mark and punch the holes in the card.
3. Hold the card in the same corner of each door and mark through the holes.

## Step 4: Drill the holes

1. Put masking tape over the marked spots so the surface does not chip.
2. Use a bit slightly bigger than the screw. For a common M4 screw, around 4.5 to 5 mm is typical, but check what your handle needs.
3. Hold the door flat on a scrap piece of wood so the back does not splinter.
4. Drill straight through, at a steady speed, not too hard.
5. Remove the tape and clear the dust.

Practise on a spare piece of the same board first if you have one.

## Step 5: Check the screws

Handles are fixed with screws that go from the inside of the door into the handle. The screw must be:

- the same thread as the handle
- long enough to reach the handle, which means the thickness of the door plus the depth the thread goes into the handle

If your door is thicker than normal, the screws supplied may be too short. A hardware shop can supply longer screws with the same thread.

## Step 6: Fit and tighten

1. Place the handle on the front of the door.
2. Push the screws through from the inside.
3. Start both screws by hand so they do not cross-thread.
4. Tighten evenly, one then the other. Stop when snug. Over-tightening can crack the board or strip the thread.
5. Check that the handle is straight and does not turn.

Check again after a few weeks, because screws can loosen slightly with use.

## Fitting knobs

Knobs need just one hole. Drill it at the position you marked, push the screw through from inside and thread it into the knob. Tighten until the knob is firm and does not spin. [Brass and antique knobs](/blog/brass-antique-cabinet-knobs-guide-pakistan) usually need the same care as handles.

## Common mistakes

- Measuring each door separately, so handles end up at different heights.
- Drilling without a scrap board behind, which splinters the back.
- Over-tightening and cracking the door or damaging the screw thread.
- Using screws that are too short for a thick door.
- Choosing a handle that is too big and hits the next door when it opens.

## Need help choosing?

Send us your measurements on WhatsApp at +92 311 7798157 and we will help you pick handles, knobs or [hinges](/hinges) that fit. Orders ship across Pakistan by bank transfer or Cash on Delivery.

## Frequently asked questions

### How far from the edge should a cabinet handle be?

A common position is about 50 to 75 mm from the edge of the door that opens. Keep it the same on every door.

### Do I need to drill new holes when I change handles?

Not if the new handle has the same hole spacing as the old one. Measure the centre-to-centre distance before you buy.

### What size drill bit should I use?

Use a bit slightly larger than the screw so it passes through the door. For many handles that is around 4.5 to 5 mm, but check the thread of your handle.

### Why does my handle keep coming loose?

The screws may be slightly too short, or may not be tightened evenly. Check the length and tighten again. Do not over-tighten.

### Can I fit handles on a thick wooden door?

Yes, but you may need longer screws with the same thread. Measure the thickness of the door first.
$md$,
$t$How to Install Cabinet Handles and Knobs (Step by Step)$t$, $t$Step-by-step guide to fitting cabinet handles and knobs: marking, drilling, screw length and tightening. For homes, carpenters and shops in Pakistan.$t$, true, now() - interval '1 hour')
on conflict (slug) do update set
  title = excluded.title, tag = excluded.tag, excerpt = excluded.excerpt, content = excluded.content,
  seo_title = excluded.seo_title, seo_description = excluded.seo_description,
  published = true, updated_at = now();
