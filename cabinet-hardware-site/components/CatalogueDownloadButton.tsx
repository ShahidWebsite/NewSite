// components/CatalogueDownloadButton.tsx
//
// Drop this into Header.tsx or Footer.tsx wherever you want the
// "Download Catalogue" link to appear. It calls /api/catalogue,
// which builds the PDF fresh from Supabase on every click, and
// triggers a normal browser download once it's ready.

'use client';

import { useState } from 'react';

export function CatalogueDownloadButton() {
  const [loading, setLoading] = useState(false);

  async function handleDownload() {
    setLoading(true);
    try {
      const res = await fetch('/api/catalogue');
      if (!res.ok) throw new Error('Failed to generate catalogue');
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'Shahid-Iqbal-Co-Catalogue.pdf';
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (err) {
      alert('Sorry, the catalogue could not be generated. Please try again in a moment.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <button
      onClick={handleDownload}
      disabled={loading}
      style={{
        backgroundColor: 'transparent',
        color: '#2A2825',
        padding: '8px 16px',
        borderRadius: 999,
        border: '1px solid #9B9992',
        fontWeight: 500,
        fontSize: 14,
        cursor: loading ? 'default' : 'pointer',
        opacity: loading ? 0.7 : 1,
      }}
    >
      {loading ? 'Preparing catalogue…' : 'Download Catalogue (PDF)'}
    </button>
  );
}
