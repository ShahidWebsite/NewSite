import { absoluteUrl } from "@/lib/seo";

// Plain links (no JavaScript needed) that open WhatsApp / Facebook with the
// page already filled in. The preview card people see comes from the page's
// Open Graph image (lib/seo.ts).
export default function ShareButtons({ path, text }: { path: string; text: string }) {
  const url = absoluteUrl(path);
  const whatsapp = `https://wa.me/?text=${encodeURIComponent(`${text} ${url}`)}`;
  const facebook = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`;
  const cls =
    "border border-nickel/50 px-3 py-1.5 font-body text-xs text-graphite transition-colors hover:border-ink hover:text-ink";

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="font-body text-xs text-graphite">Share on</span>
      <a href={whatsapp} target="_blank" rel="noopener noreferrer" className={cls}>
        WhatsApp
      </a>
      <a href={facebook} target="_blank" rel="noopener noreferrer" className={cls}>
        Facebook
      </a>
    </div>
  );
}
