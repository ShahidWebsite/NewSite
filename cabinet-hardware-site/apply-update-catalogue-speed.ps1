# ============================================================================
# Speed fix: the "Download Catalogue" PDF was being rebuilt completely from
# scratch on every single click -- re-downloading every product photo over
# the network and re-rendering the whole PDF -- with zero caching. This
# caches the generated PDF for 30 minutes, so only the first download after
# a change (or after 30 minutes) pays that cost; everyone else gets an
# instant copy.
# ============================================================================

# 1. Always work from a clean, up-to-date copy
cd "$HOME/Desktop/NewSite"
git pull origin main

# 2. Rewrite the whole file (it's short, and this avoids any risk of a
#    partial/fragile text match on a file this size)
$routePath = "cabinet-hardware-site/app/api/catalogue/route.ts"
$existing = Get-Content -LiteralPath $routePath -Raw

if ($existing -match [regex]::Escape("export const revalidate = 1800")) {
    Write-Host "SKIPPED catalogue route edit -- already updated." -ForegroundColor Yellow
} else {
    $newRoute = @'
// app/api/catalogue/route.ts
//
// GET /api/catalogue → generates and streams back a PDF built from
// whatever products/variants were live in Supabase as of the last
// regeneration.
//
// Cached for 30 minutes: building this PDF re-downloads every product
// photo and re-renders the whole document, which is genuinely slow
// (that's what was making "Download Catalogue" feel unfair) — there's no
// reason to pay that cost on every single click. The first download after
// data changes (or after 30 minutes) regenerates it; everyone else in that
// window gets an instant cached copy. If you need a brand-new catalogue
// to go out sooner than that (e.g. right after a big price update),
// just redeploy — that always busts this cache immediately.

import { NextResponse } from 'next/server';
import { renderToBuffer } from '@react-pdf/renderer';
import React from 'react';
import { getCatalogueData } from '@/lib/catalogue-data';
import { CataloguePDF } from '@/lib/CataloguePDF';

export const revalidate = 1800; // 30 minutes

export async function GET() {
  try {
    const data = await getCatalogueData();

    const pdfBuffer = await renderToBuffer(
      React.createElement(CataloguePDF, {
        data,
        logoUrl: 'https://www.siqbalhwc.com/logo.png?v=3',
      }) as any
    );

    return new NextResponse(new Uint8Array(pdfBuffer), {
      status: 200,
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': 'attachment; filename="Shahid-Iqbal-Co-Catalogue.pdf"',
        'Cache-Control': 'public, max-age=0, s-maxage=1800, stale-while-revalidate=300',
      },
    });
  } catch (err) {
    console.error('Catalogue PDF generation failed:', err);
    return NextResponse.json(
      { error: 'Could not generate the catalogue right now. Please try again shortly.' },
      { status: 500 }
    );
  }
}
'@
    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $routePath), $newRoute, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host "Updated: app/api/catalogue/route.ts"
}

# 3. Commit and push -- Vercel picks this up automatically
git add .
git commit -m "Cache catalogue PDF for 30 minutes instead of rebuilding it on every download"
git push origin main

Write-Host ""
Write-Host "Done -- check https://vercel.com for the new deployment in a minute or two." -ForegroundColor Green
Write-Host "After it deploys: the FIRST catalogue download will still take a few seconds" -ForegroundColor Green
Write-Host "(that one has to actually build the PDF). Every download after that, for the" -ForegroundColor Green
Write-Host "next 30 minutes, should feel instant." -ForegroundColor Green
