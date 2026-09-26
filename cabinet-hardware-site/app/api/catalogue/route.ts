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