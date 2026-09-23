// app/api/catalogue/route.ts
//
// GET /api/catalogue → generates and streams back a PDF built from
// whatever products/variants are live in Supabase RIGHT NOW.
// Never cached (force-dynamic + no-store), so every click reflects
// your latest stock, prices, and images — including ones you added
// five minutes ago.

import { NextResponse } from 'next/server';
import { renderToBuffer } from '@react-pdf/renderer';
import React from 'react';
import { getCatalogueData } from '@/lib/catalogue-data';
import { CataloguePDF } from '@/lib/CataloguePDF';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

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
        'Cache-Control': 'no-store',
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
