// lib/CataloguePDF.tsx
//
// The visual design of the catalogue. Renders server-side with
// @react-pdf/renderer (no headless browser needed — works fine on
// Vercel's serverless functions). Edit the BRAND object and styles
// below to adjust colors/copy; the layout logic doesn't need to change.

import React from 'react';
import { Document, Page, Text, View, Image, StyleSheet } from '@react-pdf/renderer';
import type { CatalogueCategory, CatalogueProduct, CatalogueVariant } from './catalogue-data';

const BRAND = {
  name: 'Shahid Iqbal & Co',
  tagline: 'Dream Hardware at your Door Step',
  phone: '+92 311 7798157',
  address: '218/18 Ferozepur Road, near WAPDA Hospital, Lahore, Pakistan',
  website: 'www.siqbalhwc.com',
  gold: '#B8860B',
  dark: '#1A1A1A',
  cream: '#F5F1EA',
};

const styles = StyleSheet.create({
  page: {
    paddingTop: 40,
    paddingBottom: 60,
    paddingHorizontal: 36,
    fontSize: 10,
    fontFamily: 'Helvetica',
    color: '#222222',
  },
  coverPage: {
    backgroundColor: BRAND.dark,
    color: '#ffffff',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 0,
  },
  coverLogo: { width: 72, height: 72, marginBottom: 20 },
  coverTagline: { fontSize: 11, color: BRAND.gold, letterSpacing: 1, marginBottom: 8 },
  coverTitle: { fontSize: 30, fontFamily: 'Helvetica-Bold', marginBottom: 6, textAlign: 'center' },
  coverSubtitle: { fontSize: 11, color: '#cccccc', marginBottom: 40 },
  coverFooter: { position: 'absolute', bottom: 40, alignItems: 'center' },
  coverFooterText: { fontSize: 9, color: '#aaaaaa', marginTop: 2 },

  categoryHeader: {
    fontSize: 16,
    fontFamily: 'Helvetica-Bold',
    color: BRAND.dark,
    marginBottom: 4,
    borderBottomWidth: 2,
    borderBottomColor: BRAND.gold,
    paddingBottom: 6,
  },
  grid: { flexDirection: 'row', flexWrap: 'wrap', marginTop: 14, justifyContent: 'space-between' },
  card: {
    width: '48%',
    marginBottom: 18,
    borderWidth: 1,
    borderColor: '#e5e0d8',
    borderRadius: 4,
    padding: 10,
  },
  cardImage: { width: '100%', height: 110, objectFit: 'contain', marginBottom: 8, backgroundColor: BRAND.cream },
  cardImagePlaceholder: { width: '100%', height: 110, marginBottom: 8, backgroundColor: BRAND.cream },
  cardName: { fontSize: 11, fontFamily: 'Helvetica-Bold', marginBottom: 3 },
  cardModelCode: { fontSize: 8, color: '#999999', marginBottom: 2 },
  cardSpec: { fontSize: 9, color: '#555555', marginBottom: 2 },
  cardPrice: { fontSize: 11, fontFamily: 'Helvetica-Bold', color: BRAND.gold, marginTop: 4 },
  soldOut: { fontSize: 8, color: '#B00020', marginTop: 2 },

  footer: {
    position: 'absolute',
    bottom: 20,
    left: 36,
    right: 36,
    flexDirection: 'row',
    justifyContent: 'space-between',
    fontSize: 8,
    color: '#888888',
    borderTopWidth: 0.5,
    borderTopColor: '#dddddd',
    paddingTop: 6,
  },
});

function priceLabel(variants: CatalogueVariant[]) {
  const prices = variants.map((v) => v.price).filter((p) => p != null);
  if (!prices.length) return '';
  const min = Math.min(...prices);
  const max = Math.max(...prices);
  return min === max ? `From Rs. ${min}` : `Rs. ${min} - Rs. ${max}`;
}

function isSoldOut(variants: CatalogueVariant[]) {
  return variants.length > 0 && variants.every((v) => v.stock_qty <= 0);
}

// Collects every distinct value seen for each attribute name across all
// variants — e.g. Finish: Matte Black / Golden, Size: 128mm / 160mm —
// plus material from specs, into one readable line per product.
function specLine(p: CatalogueProduct) {
  const byAttr: Record<string, Set<string>> = {};
  for (const v of p.variants) {
    for (const [attrName, attrValue] of Object.entries(v.attributes)) {
      if (!byAttr[attrName]) byAttr[attrName] = new Set();
      byAttr[attrName].add(attrValue);
    }
  }
  const parts: string[] = [];
  if (p.material) parts.push(p.material);
  for (const [attrName, values] of Object.entries(byAttr)) {
    parts.push(`${attrName}: ${Array.from(values).join(' / ')}`);
  }
  return parts.join('   •   ');
}

export function CataloguePDF({
  data,
  logoUrl,
}: {
  data: CatalogueCategory[];
  logoUrl?: string;
}) {
  const generatedDate = new Date().toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });

  return (
    <Document title={`${BRAND.name} — Product Catalogue`}>
      {/* Cover page */}
      <Page size="A4" style={[styles.page, styles.coverPage]}>
        {logoUrl && <Image src={logoUrl} style={styles.coverLogo} />}
        <Text style={styles.coverTagline}>{BRAND.tagline.toUpperCase()}</Text>
        <Text style={styles.coverTitle}>Product Catalogue</Text>
        <Text style={styles.coverSubtitle}>Generated {generatedDate}</Text>
        <View style={styles.coverFooter}>
          <Text style={styles.coverFooterText}>{BRAND.website}</Text>
          <Text style={styles.coverFooterText}>{BRAND.phone}</Text>
          <Text style={styles.coverFooterText}>{BRAND.address}</Text>
        </View>
      </Page>

      {/* One page (auto-overflows to more) per category */}
      {data.map(({ category, products }) => (
        <Page key={category} size="A4" style={styles.page} wrap>
          <Text style={styles.categoryHeader}>{category}</Text>
          <View style={styles.grid}>
            {products.map((p) => (
              <View key={p.id} style={styles.card} wrap={false}>
                {p.image_url ? (
                  <Image src={p.image_url} style={styles.cardImage} />
                ) : (
                  <View style={styles.cardImagePlaceholder} />
                )}
                <Text style={styles.cardName}>{p.name}</Text>
                {p.model_code && <Text style={styles.cardModelCode}>Model: {p.model_code}</Text>}
                {specLine(p) !== '' && <Text style={styles.cardSpec}>{specLine(p)}</Text>}
                <Text style={styles.cardPrice}>{priceLabel(p.variants)}</Text>
                {isSoldOut(p.variants) && <Text style={styles.soldOut}>Currently sold out</Text>}
              </View>
            ))}
          </View>
          <View style={styles.footer} fixed>
            <Text>{BRAND.name} — {BRAND.website}</Text>
            <Text render={({ pageNumber, totalPages }) => `${pageNumber} / ${totalPages}`} />
          </View>
        </Page>
      ))}

      {data.length === 0 && (
        <Page size="A4" style={[styles.page, styles.coverPage]}>
          <Text style={styles.coverTitle}>Catalogue coming soon</Text>
          <Text style={styles.coverSubtitle}>Products are being added — please check back shortly.</Text>
        </Page>
      )}
    </Document>
  );
}
