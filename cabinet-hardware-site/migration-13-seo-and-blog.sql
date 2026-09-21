-- ============================================================================
-- Update 13: product model codes + automatic SEO, and the Guides (blog).
-- Paste this WHOLE block into Supabase -> SQL Editor -> Run.
-- Safe to run more than once. Run it BEFORE running the PowerShell update.
-- ============================================================================

-- 1) Products: a separate model code (e.g. DHB001) so the product NAME can be
--    a proper descriptive name, plus SEO fields the site fills in automatically.
alter table products add column if not exists model_code text;
alter table products add column if not exists seo_title text;
alter table products add column if not exists seo_description text;
alter table products add column if not exists updated_at timestamptz default now();

-- Keep today's names as model codes (only for products that don't have one yet).
update products set model_code = name where model_code is null;

-- Give products that are currently named ONLY by their code a descriptive name,
-- e.g. "DHB001" becomes "Brass Main Door Handle DHB001". Web addresses (slugs)
-- are NOT changed, so existing links keep working. Any name can be edited later
-- in Admin -> Products.
update products p
set name = trim(concat_ws(' ',
      nullif(p.specs->>'Material', ''),
      case when c.name ~* 's$' and c.name !~* 'ss$' then left(c.name, length(c.name) - 1) else c.name end,
      p.model_code))
from categories c
where p.category_id = c.id
  and p.name = p.model_code
  and p.model_code is not null;

-- 2) Guides (blog)
create table if not exists blog_posts (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  tag text,
  excerpt text,
  content text not null default '',
  cover_image_url text,
  seo_title text,
  seo_description text,
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists blog_posts_published_idx on blog_posts (published, published_at desc);

alter table blog_posts enable row level security;

drop policy if exists public_read_blog_posts on blog_posts;
drop policy if exists admin_all_blog_posts on blog_posts;

create policy public_read_blog_posts on blog_posts
  for select using (published = true);

create policy admin_all_blog_posts on blog_posts
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- 3) Six starter guides (published). Edit or delete them any time in Admin -> Guides.
insert into blog_posts (slug, title, tag, excerpt, content, published, published_at) values

('how-to-measure-cabinet-handle-hole-spacing',
 'How to Measure Cabinet Handle Hole Spacing',
 'Sizing',
 'The one measurement that decides whether a two-hole handle fits your cabinet — and how to take it in two minutes with just a ruler.',
 $md$
Buying a handle that doesn't fit is the most common — and most avoidable — hardware mistake. The measurement that decides whether a two-hole handle fits is **hole spacing**, also called centre-to-centre distance. This guide shows you how to measure it in two minutes.

## What hole spacing means

Hole spacing is the distance from the **centre of one screw hole to the centre of the other**. It is not the same as the handle's overall length. A handle with 128mm hole spacing is usually longer than 128mm in total, because the handle extends past the screws at each end.

## How to measure it, step by step

1. If there is an old handle, unscrew it so you can see the two holes in the door or drawer.
2. Lay a ruler or tape across both holes. Line up the zero mark with the **centre** of the first hole.
3. Read the number at the centre of the second hole. That is your hole spacing.
4. Note it in millimetres — handles are usually specified in millimetres, so this saves converting later.
5. Measure the thickness of the door or drawer front as well. It tells you how long the screws need to be.

If your cabinets are new and have no holes yet, choose the handle first and then drill to match its hole spacing. A paper strip marked with the two hole centres makes it easy to drill every handle in exactly the same position.

## Common hole spacings

| Hole spacing | Approx. inches | Typical use |
|---|---|---|
| 64mm | 2.5 in | Small drawers, cupboard doors |
| 96mm | 3.8 in | Kitchen drawers and doors |
| 128mm | 5 in | Standard drawers, larger doors |
| 160mm | 6.3 in | Wide drawers, wardrobe doors |
| 192mm | 7.6 in | Large drawers, tall doors |
| 224mm and 256mm | 8.8 and 10 in | Very wide drawers, wardrobes |

These are standard sizes, so matching handles exist for almost any existing cabinet. The "typical use" column is a guide, not a rule — see our [cabinet handle size guide](/blog/cabinet-handle-size-guide-drawers-doors-wardrobes) for choosing the right length for your drawers and doors.

## What if my holes don't match a standard size?

Some older or custom cabinets have non-standard spacing. You have two easy options: use a single-hole knob and fill the spare hole with wood filler, or send us your measurement on WhatsApp and we will suggest the closest match. Browse our [cabinet handles](/shop?category=cabinet-handles) and [cabinet knobs](/shop?category=cabinet-knob) — every listing shows the exact size.

## Frequently asked questions

### Is hole spacing the same as handle length?

No. Hole spacing is the distance between the two screw holes. The overall length of the handle is longer, because the ends extend beyond the screws. Always match hole spacing when you are replacing an existing handle.

### Do knobs need hole spacing?

No. A knob is fixed with a single screw, so there is only one hole and nothing to match. You only need to check that the screw is long enough for the thickness of your door or drawer.

### Can I fit a handle with a different hole spacing?

Only if you are willing to drill new holes and fill the old ones. A 128mm handle will not fit holes that are 160mm apart, so measure before you order.
$md$,
 true, now() - interval '6 days'),

('brass-vs-stainless-steel-vs-zinc-alloy-handles',
 'Brass vs Stainless Steel vs Zinc Alloy Handles',
 'Materials',
 'How the most common handle materials compare for feel, durability and upkeep, and which one suits your kitchen, wardrobe or main door.',
 $md$
The material decides how a handle feels in your hand, how it ages and how long it lasts. Here is how the most common materials compare, so you can choose for the room — not just the look.

## Brass

Brass is a dense copper-and-zinc alloy. It is heavy, solid and does not rust, because it contains no iron. Over time brass can darken and develop a warm patina, unless it has been lacquered to keep it bright. It usually costs more than other materials, but it is the traditional choice for pieces meant to last, especially main door handles.

## Stainless steel

Stainless steel resists rust and stains and is very strong, which makes it a sensible choice for kitchens and bathrooms. It has a cool, modern look, and brushed finishes hide fingerprints well. It is harder to form into ornate shapes, so designs tend to be simpler.

## Zinc alloy

Zinc alloy is cast in a mould, which allows detailed shapes at a lower price. The colour you see is a plated or coated finish over the base metal, so the quality of that finish matters most. It works well for wardrobes and bedrooms where handles are touched less often, but heavy daily use can wear a thin coating.

## Aluminium

Aluminium is light and does not rust. It is softer than the other metals and can dent or scratch, so it suits light-use cupboards better than busy kitchen drawers.

## Quick comparison

| Material | Feel | How it ages | Best for |
|---|---|---|---|
| Brass | Heavy, solid | Warm patina, or stays bright if lacquered | Main doors, kitchens, long-term use |
| Stainless steel | Solid, cool | Very little change | Kitchens, bathrooms |
| Zinc alloy | Medium weight | Depends on the finish quality | Wardrobes, bedrooms, low-traffic doors |
| Aluminium | Light | Can scratch or dent | Light-use cupboards |

## Which should you choose?

- **Kitchen:** brass or stainless steel. Steam, grease and frequent cleaning are hard on thin finishes.
- **Bedroom and wardrobe:** zinc alloy or brass, depending on budget.
- **Bathroom:** stainless steel or brass, because of moisture.
- **Main door:** brass. It is exposed to sun, dust and rain and is handled every day.

Lahore's hot summers and monsoon humidity are tough on thin plated finishes, so a solid metal such as brass or stainless steel is the safer long-term choice for hardware you touch every day.

## How to judge quality when you shop

- **Weight:** solid pieces feel noticeably heavier than hollow or thin ones.
- **Finish:** it should look even, with no rough patches or bubbles.
- **Edges and threads:** casting edges should be smooth and screw threads clean.
- **Honest listings:** the material should be stated clearly in the product specifications. Browse [door handles](/shop?category=main-door-handle) or [cabinet handles](/shop?category=cabinet-handles) to compare.

## Frequently asked questions

### Is brass better than zinc alloy?

Generally brass is more durable and feels more substantial, while zinc alloy offers detailed designs at a lower price. For rarely used doors, a well-finished zinc alloy handle can be good value.

### Will brass rust?

No. Rust needs iron, and brass contains none. Brass can tarnish or darken over time, which is normal. Our [care guide](/blog/how-to-clean-and-care-for-brass-matte-black-chrome-handles) explains how to keep it looking good.

### Which material is best for humid areas?

Stainless steel and brass both cope well with moisture. Avoid thin-plated handles in bathrooms and kitchens if you want them to last.
$md$,
 true, now() - interval '5 days'),

('matte-black-golden-chrome-choosing-a-handle-finish',
 'Matte Black, Golden or Chrome? Choosing a Handle Finish',
 'Finishes',
 'A practical guide to picking a handle finish that suits your cabinet colour, your taps and lights, and how much cleaning you want to do.',
 $md$
Finish is the first thing people notice about a handle, and it is the hardest to change later. Here is how to choose one that suits your cabinets and room, and how each finish behaves in daily use.

## The main finishes

**Golden (brass tone)** is warm and classic. It stands out beautifully against white, navy and forest green, and looks rich on dark wood. Polished gold shows fingerprints more than satin or brushed versions.

**Matte black** is modern and high-contrast. It looks sharp on white, grey and light wood cabinets and hides fingerprints better than polished finishes. In kitchens, grease marks can show, so a quick regular wipe keeps it looking crisp.

**Chrome** is bright, cool and neutral. It matches taps and appliances easily. It shows fingerprints and water spots, but wipes clean in seconds.

**Antique brass** is a darker, aged tone that suits traditional and vintage interiors and hides everyday wear.

**Silver** is a soft, neutral metal tone that sits quietly in the background of almost any room.

## Which finish goes with which cabinet colour?

| Cabinet colour | Finishes that work well |
|---|---|
| White | Matte black, golden or chrome |
| Natural or light wood | Matte black or antique brass |
| Dark wood | Golden or antique brass |
| Navy or green | Golden |
| Grey | Matte black or chrome |

## Match the rest of the room

Look at the taps, light fittings and door hardware around your handles. A simple rule that works: choose one **dominant metal** and at most one **accent**. Mixing finishes is fine when it looks deliberate — for example, matte black handles with a golden light fitting — but three or four different metals in one room looks accidental.

## Practical tips before you order

- **Order everything for a room at the same time.** The exact shade of a finish can vary slightly between batches, so handles bought months apart may not match perfectly.
- **Think about the light.** Warm lighting makes golden finishes glow and can soften chrome; cool white light does the opposite.
- **Consider how often you will clean.** Brushed and satin finishes forgive fingerprints. Polished chrome needs wiping more often.
- **Ask for help.** Send us a photo of your cabinets on WhatsApp and we will suggest a finish. You can browse [cabinet handles](/shop?category=cabinet-handles) and [knobs](/shop?category=cabinet-knob) in each finish.

## Frequently asked questions

### Can I mix different finishes in one room?

Yes, if it is deliberate. Keep one dominant metal for most of the hardware and repeat any accent finish at least twice so it looks planned.

### Which finish is easiest to keep clean?

Brushed and satin finishes hide fingerprints best. Chrome shows marks but wipes clean very easily. Read our [care guide](/blog/how-to-clean-and-care-for-brass-matte-black-chrome-handles) for the right cleaning method for each finish.

### Does matte black wear off?

A matte black coating can wear at the edges with heavy use, especially if it is scrubbed with abrasive cleaners. Clean it with a soft damp cloth and mild soap and it will last much longer.
$md$,
 true, now() - interval '4 days'),

('cabinet-handle-size-guide-drawers-doors-wardrobes',
 'Cabinet Handle Size Guide for Drawers, Doors and Wardrobes',
 'Sizing',
 'How long should a handle be for a drawer, a kitchen door or a wardrobe? Simple proportion rules, a quick-reference table and where to position handles.',
 $md$
Once you know your hole spacing (see our guide on [how to measure hole spacing](/blog/how-to-measure-cabinet-handle-hole-spacing)), the next question is size: how long should the handle be? The answer depends on what it is fitted to. A handle that is too small looks lost on a wide drawer, and one that is too big overwhelms a small cupboard.

## Simple proportion rules

- **Drawers:** a handle about one third of the drawer front's width usually looks balanced. On narrow drawers it can be up to about half the width.
- **Wide drawers:** on drawers wider than about 75 cm, consider two handles placed roughly a quarter and three quarters of the way across, or one long handle.
- **Doors:** a handle or knob sits near the edge opposite the hinges. Tall doors suit a vertical handle.
- **Small cupboards:** knobs or short handles look best and are easier to place neatly.

## Quick reference

| Fitted to | Suggested hole spacing | Notes |
|---|---|---|
| Small cupboard door (up to about 40 cm wide) | Knob, or 64–96mm | Knobs keep small doors uncluttered |
| Kitchen drawer (40–60 cm wide) | 96–128mm | Centre it on the drawer front |
| Wide drawer (60–90 cm wide) | 128–192mm | Or two handles on very wide drawers |
| Tall wardrobe door | 160–256mm, fitted vertically | Easier to grip at a comfortable height |

These are starting points. Your own cabinets and taste matter more than any table.

## Where to position handles

- **Drawers:** centred left to right, and centred or slightly above the middle vertically.
- **Base cabinet doors:** near the top corner, opposite the hinge side.
- **Wall cabinet doors:** near the bottom corner, opposite the hinge side.
- **Distance from the edge:** about 5 cm from the corner is a comfortable, common position.
- **Use a template:** cut a small piece of card with the hole positions marked, so every handle lands in exactly the same place.

## Knob or handle?

Knobs are neat on small doors and drawers, but they offer less grip. Handles are easier to pull with wet or full hands and suit larger and heavier fronts. Many kitchens use knobs on doors and handles on drawers for a consistent, practical look. Browse our [cabinet knobs](/shop?category=cabinet-knob) and [cabinet handles](/shop?category=cabinet-handles).

## Check the clearance

Before you commit, hold the handle against the door and check that it will not knock against a neighbouring door, an appliance or a corner cabinet when it opens.

## Frequently asked questions

### Can I use a longer handle than the one I have now?

Only if the hole spacing matches, or you are prepared to drill new holes and fill the old ones. A longer handle with the same hole spacing will fit the existing holes.

### How many handles does a wide drawer need?

For very wide drawers, two handles spread evenly are easier to use and keep the drawer from twisting as it opens. One long handle can also work if it is centred.

### What size handle is best for a wardrobe door?

Longer handles of around 160mm to 256mm hole spacing, fitted vertically, are a popular choice because they are easy to grip and look proportionate on tall doors.
$md$,
 true, now() - interval '3 days'),

('how-to-choose-a-main-door-handle',
 'How to Choose a Main Door Handle for Your Home',
 'Door hardware',
 'Door thickness, lock type, handle size, material and fitting: a practical checklist for choosing a main door handle that fits and lasts.',
 $md$
The main door handle is the first thing visitors touch and the piece of hardware used most every day. Choosing well means checking a few measurements first. This checklist covers what to look at before you order.

## Start with the door

- **Door thickness.** Most doors fall somewhere between 35 mm and 50 mm thick, but measure yours. It affects the bolt and screw length you need.
- **The lock.** Does your door have a mortise lock (fitted inside the door), a rim lock (fitted on the surface) or a separate latch? The handle must work with it.
- **Existing fixing holes.** If you are replacing a handle, measure the distance between the fixing holes, centre to centre, and check whether the handle is fixed from one side or through the door.

## Pull handle or lever handle?

**Pull handles** are fixed bars you grip and pull. They suit main entrance doors that have their own lock. **Lever handles** turn to operate a latch and are common on interior doors. Knowing which your door uses saves an expensive mistake.

## Choosing the size

Long pull handles from around 400 mm up to well over a metre are common on tall or wide entrance doors. A good rule is to pick a length that looks proportionate to the door and is easy to grip with your whole hand. Door handles are usually fitted at around 100 cm from the floor, which is comfortable for most people.

## Material and finish

An outside door is exposed to sun, dust and rain, so material matters more than on an indoor cabinet. Solid brass is a long-lasting choice for main doors, and it ages gracefully. Read our comparison of [handle materials](/blog/brass-vs-stainless-steel-vs-zinc-alloy-handles) for more, or see the [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) to match your door and gate.

## A handle is not a lock

A handle makes the door easy to use, but security comes from the lock, hinges and door frame. Choose your lock separately and make sure the handle and lock work together.

## Fitting checklist

1. Measure door thickness and hole spacing before ordering.
2. Check the handle's projection so it clears the door frame and wall.
3. Use the fixings supplied, and confirm the screws or bolts are long enough for your door.
4. Drilling into solid wood or metal doors needs the right tools — consider a carpenter.
5. Tighten fixings firmly but not over-tight, and re-check them after a few weeks.

Browse our [main door handles](/shop?category=main-door-handle), and message us on WhatsApp with your measurements if you would like a second opinion.

## Frequently asked questions

### Can I change the handle without changing the lock?

Often yes, if the new handle's fixing holes line up with the existing ones or the handle is a simple pull fitted on the surface. Send us your measurements to check.

### What height should a main door handle be?

Around 100 cm from the floor is common, but follow the position of your existing handle or lock, and consider the people who use the door every day.

### How do I know if I need a pull handle or a lever handle?

If the door opens by pulling a fixed bar and locks with a separate lock, you need a pull handle. If the handle turns to release a latch, you need a lever handle.
$md$,
 true, now() - interval '2 days'),

('how-to-clean-and-care-for-brass-matte-black-chrome-handles',
 'How to Clean and Care for Brass, Matte Black and Chrome Handles',
 'Care',
 'Most hardware damage comes from the wrong cleaner. Here is what is safe for brass, matte black and chrome — and what to avoid.',
 $md$
Most damage to handles and knobs comes from the wrong cleaner, not from everyday use. The good news is that the safest method is also the simplest, and it works on nearly every finish.

## The basic routine

1. Mix a little mild dish soap into warm water.
2. Wipe the handle with a soft cloth or microfibre cloth wrung out well.
3. Wipe again with a cloth dampened with clean water.
4. **Dry immediately** with a soft dry cloth to prevent water spots.

In kitchens, do this every week or two, because grease builds up quietly and dulls the finish. Elsewhere, once a month is plenty.

## Brass

Most decorative brass hardware is lacquered to keep it bright. Treat lacquered brass like any coated finish: soap and water only. **Do not use metal polish on it**, because polish strips the lacquer and leaves patchy, tarnished spots. If a piece is unlacquered and has dulled, a brass polish used exactly as its label says will bring the shine back — or you can leave it to develop its natural patina, which many people prefer.

## Matte black

Matte black finishes are easily damaged by scrubbing. Use a damp microfibre cloth and mild soap. Avoid scouring powders, abrasive pads and polishes — they can burnish the coating into shiny patches or wear it away, especially at the edges.

## Chrome

Chrome cleans easily with soap and water. Dry it afterwards to avoid water spots. Avoid bleach and strong acid or chlorine-based cleaners, which can pit or dull the surface.

## Golden and other plated finishes

Treat these gently, like lacquered brass: mild soap, soft cloth, no abrasives, and no harsh chemicals. A thin plated layer can wear through if it is scrubbed.

## What to avoid on every finish

- Bleach and strong household cleaners
- Steel wool, scouring pads and gritty powders
- Spraying cleaner directly onto the handle — spray onto the cloth instead so liquid does not seep into the screw fittings
- Leaving wet cloths or soapy water sitting on the surface

## Keep handles firm

Every few months, check that handles are tight. A wobbling handle loosens further with use. Tighten gently by hand, because over-tightening can strip the thread or crack the fixing.

## Choosing hardware that is easy to keep clean

Brushed and satin finishes hide fingerprints, while polished chrome and gold show them more but wipe clean easily. Our [finish guide](/blog/matte-black-golden-chrome-choosing-a-handle-finish) explains the differences, and you can compare [cabinet handles](/shop?category=cabinet-handles) in each finish.

## Frequently asked questions

### How often should I clean my handles?

Every week or two in kitchens, and about once a month elsewhere. Wipe up splashes and grease as soon as you notice them.

### Can I use vinegar or lemon to clean handles?

Acidic cleaners can damage some coatings and finishes, so mild soap and water is the safer choice. If you want to try something else, test it on a hidden spot first.

### Why has my handle gone dull?

Usually it is built-up grease, dust or hand oils, which soap and water will lift. If the finish itself has worn through, cleaning will not restore it, and replacing the handle is the practical fix.
$md$,
 true, now() - interval '1 day')

on conflict (slug) do nothing;
