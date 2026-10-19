"use client";

import { usePathname } from "next/navigation";

// Floating "Chat on WhatsApp" button, shown on every public page.
// The message is pre-filled with the page the visitor is looking at, so you
// instantly know which product they are asking about.
const WHATSAPP_NUMBER = "923117798157"; // +92 311 7798157
const SITE = "https://www.siqbalhwc.com";

export default function WhatsAppButton() {
  const pathname = usePathname() || "/";

  // Never show it inside the admin area.
  if (pathname.startsWith("/admin")) return null;

  const pageUrl = `${SITE}${pathname === "/" ? "" : pathname}`;
  const text =
    pathname === "/"
      ? "Hello Shahid Iqbal & Co, I would like some help with cabinet handles / knobs."
      : `Hello Shahid Iqbal & Co, I have a question about this page: ${pageUrl}`;
  const href = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(text)}`;

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      aria-label="Chat with us on WhatsApp"
      className="fixed z-50 flex items-center gap-2 rounded-full bg-[#25D366] px-4 py-3 font-body text-sm font-medium text-white shadow-lg transition-transform hover:scale-105 hover:bg-[#1ebe5b] print:hidden"
      style={{
        right: "max(1rem, env(safe-area-inset-right))",
        bottom: "max(1rem, env(safe-area-inset-bottom))",
      }}
    >
      <svg width="24" height="24" viewBox="0 0 32 32" fill="currentColor" aria-hidden="true">
        <path d="M16.004 3C8.82 3 3 8.82 3 16c0 2.29.6 4.52 1.74 6.49L3 29l6.68-1.72A12.94 12.94 0 0 0 16.004 29C23.18 29 29 23.18 29 16S23.18 3 16.004 3zm0 23.7a10.7 10.7 0 0 1-5.46-1.5l-.39-.23-3.96 1.02 1.06-3.86-.25-.4A10.67 10.67 0 0 1 5.3 16c0-5.9 4.8-10.7 10.704-10.7S26.7 10.1 26.7 16s-4.8 10.7-10.696 10.7zm5.87-8.01c-.32-.16-1.9-.94-2.2-1.05-.3-.11-.51-.16-.73.16-.21.32-.83 1.05-1.02 1.26-.19.21-.37.24-.7.08-.32-.16-1.36-.5-2.59-1.6-.96-.85-1.6-1.9-1.79-2.22-.19-.32-.02-.5.14-.66.14-.14.32-.37.48-.56.16-.19.21-.32.32-.54.11-.21.05-.4-.03-.56-.08-.16-.73-1.76-1-2.4-.26-.63-.53-.54-.73-.55h-.62c-.21 0-.56.08-.85.4-.3.32-1.12 1.1-1.12 2.68 0 1.58 1.15 3.1 1.31 3.32.16.21 2.26 3.45 5.47 4.84.76.33 1.36.53 1.82.68.77.24 1.46.21 2.01.13.61-.09 1.9-.78 2.17-1.53.27-.75.27-1.4.19-1.53-.08-.13-.3-.21-.62-.37z" />
      </svg>
      <span className="hidden sm:inline">Chat on WhatsApp</span>
    </a>
  );
}