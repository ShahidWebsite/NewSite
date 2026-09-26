# Onboarding Guide — Shahid Iqbal & Co Website
**Updated: September 2026, after a live audit + three shipped fixes**
**Owner: Shahid Iqbal (non-technical — read "Working with the owner" before doing anything else)**

This replaces the original onboarding doc, which had drifted out of date — several
features it listed as "not built yet" (reviews, blog, COD, bank-accounts admin) were
already live, and the domain it described as "not yet connected" has been connected
since. Everything below was verified directly against the live repo and the live site,
not assumed from old notes.

---

## 1. What this is

A standalone e-commerce website for **Shahid Iqbal & Co**, a hardware retailer in Lahore
("Dream Hardware at your Door Step" — door handles, cabinet handles, knobs, furniture
pulls, specialized in brass).

**Confirmed live and correctly configured as of this writing:**
- Domain: **www.siqbalhwc.com** — connected, resolving, canonical/OG/JSON-LD all correctly
  pointing at it.
- Real product photography and a real catalog are live (not placeholder data).

**Business reference (keep this consistent everywhere — Google/SEO cares about exact
match):**
- Name: Shahid Iqbal & Co
- Phone: +92 311 7798157
- Address: 218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan
- Facebook: facebook.com/siqbalhwc
- Instagram: @siqbalco

**Still deferred (per original design decision, not re-confirmed this round):**
- No connection to the owner's other ERP system (Oneaccounts). If revisited, there's
  separate earlier design work for a multi-tenant, SaaS-style version of this — don't
  merge that thinking into this standalone site's schema (no `tenant_id` anywhere here)
  without a clear decision from the owner first.

---

## 2. Working with the owner — read this first

Shahid is **not a developer**. He can:
- Copy-paste and run exact commands you give him (PowerShell, `git`, SQL in Supabase's SQL Editor)
- Click through step-by-step UI instructions (Vercel/Supabase/GitHub dashboards)
- Take screenshots when something goes wrong

He **cannot**:
- Read a diff or a code file and know what changed or why
- Debug an error message on his own
- Judge whether a change is safe before running it

**Practical implication:** never hand him a raw code file and say "replace this." Give him
either (a) a single runnable script that does the whole job, or (b) a fully worked GitHub
Desktop / dashboard walkthrough, one click at a time. This applies to AI assistants
continuing this project too — assume every instruction needs to survive being followed
literally by someone who doesn't know what a "root directory" is.

---

## 3. Where everything lives

| What | Where |
|---|---|
| Code | github.com/ShahidWebsite/NewSite (public repo, `main` branch) |
| Hosting | Vercel — project "website", auto-deploys on every push to `main` |
| Database | Supabase (Postgres + Auth + Storage) |
| Domain | **www.siqbalhwc.com — connected and live** |

**Vercel project settings you must not break:**
- Root Directory: `cabinet-hardware-site`
- Environment variables (Production): `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` — names must match exactly, the code reads them literally.
- `NEXT_PUBLIC_SITE_URL` is **not required** — `lib/seo.ts` already falls back to
  `https://www.siqbalhwc.com` if it's unset, and that's been confirmed correct on the
  live site. Setting it explicitly is optional, not a fix for anything currently broken.

Ask the owner for access to all three (GitHub, Vercel, Supabase) as a collaborator/member —
don't ask him to hand over his personal login.

---

## 4. How to get the code

**If you're a developer:**
```powershell
git clone https://github.com/ShahidWebsite/NewSite.git
cd NewSite/cabinet-hardware-site
npm install
```
Create `.env.local` (copy `.env.example`) with the three Supabase values from
Project Settings → API. Then `npm run dev` — site runs at http://localhost:3000.

**If you're an AI assistant with shell/network access (e.g. a Claude session with the
bash tool and `github.com` reachable):** don't ask Shahid to paste code or upload files.
Just clone the repo yourself —

```bash
git clone https://github.com/ShahidWebsite/NewSite.git
```

— read what you need directly, and work from a real, current copy. The repo is public,
so this works with no credentials. This is meaningfully better than working from
descriptions or from files the owner tries to copy-paste, since he can't reliably do that
anyway (see section 2).

**Database schema:** `schema.sql` alone is now out of date. A fresh Supabase project
needs `schema.sql` **and every migration file**, run in this order:
1. `schema.sql`
2. `migration-13-seo-and-blog.sql`
3. `migration-bank-accounts.sql`
4. `migration-contact-and-shipping.sql`
5. `migration-reviews.sql`
6. `migration-testimonials.sql`
7. `storage-setup.sql`

(`sample-data.sql` is optional demo data, not required.)

---

## 5. How to share data / apply fixes — the established workflow

This is how changes have actually been made to this project, and it works well. Don't
deviate from it without a good reason:

1. **Clone the real repo and reproduce the issue there** — not from a description of
   the code, and not from a partial copy Shahid has locally (his local copy can drift;
   always start from a fresh `git pull` or fresh clone).
2. **Make the change, then actually test it before sending it** — type-check
   (`npx tsc --noEmit`), and if it touches a script Shahid will run, simulate his real
   environment (Windows PowerShell, CRLF line endings — see pitfalls below) rather than
   just eyeballing the diff. Several real bugs in this project were only caught this way.
3. **Package the change as a single PowerShell script**, following the standard shape:
   - `cd` to `$HOME/Desktop/NewSite`, `git pull origin main`
   - Apply the edit (targeted text replace for small changes, a full-file here-string
     rewrite for anything larger or higher-risk)
   - `git add .`, `git commit -m "..."`, `git push origin main`
   - Print a plain-English "Done, check Vercel" message at the end
   - Make it **safe to run twice** — check whether the change is already applied and
     print a `SKIPPED` message instead of erroring or double-applying
4. **Give Shahid one exact command to paste**, e.g.:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\apply-update-xyz.ps1"
   ```
   Never ask him to open the script, read it, or explain what it does — just what to run.
5. **He never touches code, never resolves a merge conflict, never reads a diff.** If a
   script can't apply cleanly (file already changed, text not found), it should say so in
   plain language and stop — not guess.

---

## 6. Hard-learned pitfalls for update scripts (read before writing another one)

These are real bugs that shipped and had to be fixed, kept here so they don't repeat:

- **Save `.ps1` files as UTF-8 *with a BOM*.** Windows PowerShell 5.1 (the default
  `powershell.exe`, distinct from PowerShell 7's `pwsh.exe`) reads scripts without a BOM
  using the system's ANSI codepage, not UTF-8 — this silently corrupts any non-ASCII
  character (em dashes, curly quotes) into garbage bytes and breaks here-string parsing
  with confusing errors like `The 'from' keyword is not supported`.
- **Windows checks out files with CRLF line endings**, even though this repo's source
  (and Git internally) uses LF. A multi-line text match/replace that assumes LF-only
  content will silently fail to match on a real Windows machine even though it works
  fine when you test it — normalize line endings (`-replace "\`r\`n", "\`n"`) before
  comparing or replacing multi-line blocks. Single-line anchors aren't affected by this,
  only multi-line ones.
- **Use `-LiteralPath`, never plain `-Path`, for any file path containing `[` or `]`**
  (e.g. `app/products/[slug]/page.tsx`). PowerShell's default path parameter treats
  square brackets as a wildcard character class, so `Get-Content`/`Set-Content` on
  a bracketed path can silently fail to find the file it's clearly sitting right next to.
- **Prefer `[System.IO.File]::WriteAllText(..., (New-Object System.Text.UTF8Encoding($true)))`
  over `Set-Content`** for writing file contents back. It's more predictable across
  PowerShell versions and avoids `Set-Content`/`-NoNewline` parameter quirks seen when
  the input value was unexpectedly null (itself usually a symptom of the bracket-path
  bug above — fix that first and this stops mattering).
- **The pile of `apply-update-*.ps1` scripts committed to the repo root
  (`apply-update-1.ps1` through `apply-update-15.ps1`, plus several named ones) is
  accumulating clutter.** They're harmless (one-off, already applied), but worth
  archiving into a `scripts/history/` folder or deleting once confirmed applied, so the
  repo root doesn't keep growing indefinitely.

---

## 7. Tech stack

- **Next.js 14** (App Router), TypeScript, Tailwind CSS
- **Supabase**: Postgres database, Auth (admin login only — customers don't need accounts), Storage (for product images)
- **No separate backend** — API routes live inside Next.js itself (`app/api/**`)
- **Payments:** bank transfer **and** Cash on Delivery via Leopard Courier (COD was added
  after the original build — no longer bank-transfer-only)
- **PDF generation:** `@react-pdf/renderer`, used for the downloadable product catalogue

---

## 8. Repo structure (verified current, not assumed)

```
cabinet-hardware-site/
  app/
    page.tsx                        → homepage (ISR, revalidate: 60s)
    [category]/page.tsx             → category listing (e.g. /cabinet-handles), filterable
    shop/page.tsx                   → full catalog listing
    products/[slug]/page.tsx        → product detail (ISR, revalidate: 60s)
    about/, contact/, privacy/, returns/, shipping/, terms/  → static content pages
    blog/, blog/[slug]/             → buying-guide articles (ISR, revalidate: 60s)
    cart/, checkout/                → cart state (localStorage) + bank-transfer/COD checkout
    track-order/                    → public order lookup (order number + email)
    og/route.tsx                    → dynamic Open Graph image generation
    sitemap.ts, robots.ts           → auto-generated, revalidate hourly
    admin/                          → password-protected admin:
      page.tsx, login/
      products/ (list, new, [id]/edit, import — bulk Excel import)
      orders/, categories/, blog/ (list, new, [id]/edit)
      bank-accounts/               → edit bank transfer details (built; earlier docs
                                      said this needed building — it doesn't anymore)
      shipping-settings/, reviews/, enquiries/
    api/
      catalogue/route.ts           → generates the downloadable PDF catalogue (cached 30 min)
      orders/create, orders/track  → server-side order creation & lookup
      enquiries/create             → B2B/bulk enquiry form submission
  components/                       → Header, Footer, ProductCard, ProductGallery,
                                       VariantSelector, StockBadge, Testimonials,
                                       ProductReviews, ReviewForm, BlogCard, ContactForm,
                                       ShareButtons, ShopBrowser, SortSelect,
                                       CatalogueDownloadButton
    admin/                          → BlogPostForm, PresetSelect, SeoFields
  lib/
    supabase.ts                    → two clients: public (anon key) and service (bypasses RLS, API-routes only)
    cart-context.tsx               → client-side cart, localStorage-backed
    shop-data.ts                   → catalog/filter query logic
    catalogue-data.ts, CataloguePDF.tsx → PDF catalogue data fetch + layout
    seo.ts                         → SITE_URL, metadata helpers, structured data
    shipping.ts, markdown.tsx, constants.ts, types.ts
  schema.sql                       → base tables + RLS — run this FIRST in a fresh project
  migration-*.sql (x5)             → schema evolution since schema.sql — run these too (see section 4)
  storage-setup.sql                → Supabase Storage bucket config
  sample-data.sql                  → optional demo data
  README.md                       → also stale in places — trust this doc over it for now
```

**Data model in one paragraph:** `products` hold shared info (name, description, specs
JSON, base price for display). `attributes`/`attribute_values` define things like Finish
and Size. `product_variants` are the actual buyable SKUs (one row per Finish+Size
combination) with their own price/stock. `orders`/`order_items` are standard. `bank_settings`
is a single-row table holding the account details shown to customers at checkout —
editable via `/admin/bank-accounts` now, not just Supabase's Table Editor.

**Row Level Security (RLS):** public (anon key) can read active catalog data and insert
orders, but can never read orders back — order tracking goes through `/api/orders/track`
using the service-role key, which checks order number + email match server-side.
Any authenticated Supabase user is treated as admin (single-owner store — if you ever add
staff accounts with different permission levels, this needs tightening).

---

## 9. Known gaps (current, re-checked — not carried over blindly)

- **Catalogue PDF image weight:** the PDF embeds full-resolution product photos with no
  resizing/compression step. The 30-minute cache (see below) hides most of the cost, but
  the first build in each window is still heavier than it needs to be. Would need a
  resize step (e.g. `sharp`, not currently a dependency) before embedding.
- **No order-status notifications:** customers must manually revisit `/track-order` — no
  email/SMS/WhatsApp ping when admin updates status.
- **Cart is `localStorage`-only:** no recovery if a customer switches devices or clears
  their browser.
- **Image upload in admin:** per earlier review, the product form took an image URL
  rather than a file upload — **not re-verified this round**, confirm before relying on
  this.
- **Repo clutter:** ~18 one-off `apply-update-*.ps1` scripts committed to the repo root
  (see section 6).
- **README.md is stale** in places — this document supersedes it; consider replacing
  README.md's content with (or linking to) this file so future contributors don't get
  misled the way this document's predecessor did.

## 10. Recently fixed (for context — don't re-do these)

- Homepage was `force-dynamic` (hit the database on every single visit) → now cached,
  `revalidate = 60`.
- Product pages had no cache refresh at all (admin edits could get stuck until next
  deploy) → now `revalidate = 60`.
- Catalogue PDF was rebuilt from scratch (re-downloading every product photo) on every
  single click → now cached for 30 minutes (`revalidate = 1800` + matching `Cache-Control`
  header).
