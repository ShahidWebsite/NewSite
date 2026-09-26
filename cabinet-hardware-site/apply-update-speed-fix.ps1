# ============================================================================
# Speed fix: homepage + product pages were either re-fetching from the
# database on every single visit (homepage), or getting cached forever with
# no way for admin edits to reach the live site (product pages). This
# updates both to check the database at most once a minute.
#
# Domain: no change needed. www.siqbalhwc.com is already live and the
# canonical/social-share tags are already pointing at it correctly.
# ============================================================================

# 1. Always work from a clean, up-to-date copy
cd "$HOME/Desktop/NewSite"
git pull origin main

# 2. Homepage: stop re-fetching on every visit, cache for 60 seconds instead
$homepagePath = "cabinet-hardware-site/app/page.tsx"
$homepage = Get-Content -LiteralPath $homepagePath -Raw
$oldHomepageBlock = @'
// Without this, Next.js bakes the homepage into a static snapshot at build
// time — so new products/photos added later through /admin would never show
// up here until the next deploy. This makes it fetch fresh data every visit.
export const dynamic = "force-dynamic";
'@
$newHomepageBlock = @'
// Cached and served instantly, then re-checked in the background at most
// once a minute — new products/photos added through /admin still appear
// quickly, but visitors aren't stuck waiting on a database round-trip
// (previously this was "force-dynamic", which hit the database on every
// single homepage visit).
export const revalidate = 60;
'@
if ($homepage -notmatch [regex]::Escape($oldHomepageBlock)) {
    Write-Host "SKIPPED homepage edit -- expected text not found (file may already be updated). Check app/page.tsx manually." -ForegroundColor Yellow
} else {
    $homepage = $homepage -replace [regex]::Escape($oldHomepageBlock), $newHomepageBlock
    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $homepagePath), $homepage, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host "Updated: app/page.tsx"
}

# 3. Product pages: add a 60-second cache window so price/stock edits made
#    in /admin actually reach the live product page instead of being cached
#    indefinitely until the next deploy
$productPagePath = "cabinet-hardware-site/app/products/[slug]/page.tsx"
$productPage = Get-Content -LiteralPath $productPagePath -Raw
$anchor = '} from "@/lib/seo";'
$insertAfterAnchor = @'
} from "@/lib/seo";

// Without this, a product page (no generateStaticParams here) gets rendered
// once on first visit and then cached indefinitely — so a price or stock
// change made in /admin would NOT show up on the live page until the next
// deploy. This re-checks each product page against the database at most
// once a minute instead.
export const revalidate = 60;
'@
if ($productPage -match [regex]::Escape("export const revalidate = 60;")) {
    Write-Host "SKIPPED product page edit -- revalidate already present." -ForegroundColor Yellow
} elseif ($productPage -notmatch [regex]::Escape($anchor)) {
    Write-Host "SKIPPED product page edit -- expected text not found. Check app/products/[slug]/page.tsx manually." -ForegroundColor Yellow
} else {
    $productPage = $productPage -replace [regex]::Escape($anchor), $insertAfterAnchor
    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $productPagePath), $productPage, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host "Updated: app/products/[slug]/page.tsx"
}

# 4. Commit and push -- Vercel picks this up automatically
git add .
git commit -m "Cache homepage and product pages for 60s instead of always-fresh/never-refreshed"
git push origin main

Write-Host ""
Write-Host "Done -- check https://vercel.com for the new deployment in a minute or two." -ForegroundColor Green
Write-Host "Domain check: www.siqbalhwc.com is already live and correctly configured, no change was needed there." -ForegroundColor Green
