import React from "react";
import Link from "next/link";

// A deliberately small markdown renderer for blog posts. It builds React
// elements directly (never raw HTML), so post content can't inject scripts.
//
// Supported: ## / ### headings, paragraphs, - bullet lists, 1. numbered lists,
// > quotes, --- dividers, | tables |, ![images](url), **bold**, *italic*,
// `code` and [links](url).

export type Block =
  | { type: "h2" | "h3"; text: string; id: string }
  | { type: "p"; text: string }
  | { type: "ul" | "ol"; items: string[] }
  | { type: "quote"; text: string }
  | { type: "hr" }
  | { type: "table"; head: string[]; rows: string[][] }
  | { type: "img"; alt: string; src: string };

export function headingId(text: string) {
  return stripInline(text)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

export function stripInline(text: string) {
  return text
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/\*([^*]+)\*/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\s+/g, " ")
    .trim();
}

function splitRow(line: string) {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split("|")
    .map((c) => c.trim());
}

const TABLE_SEPARATOR = /^\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?$/;

export function parseMarkdown(source: string): Block[] {
  const lines = source.replace(/\r\n?/g, "\n").split("\n");
  const blocks: Block[] = [];
  let para: string[] = [];

  const flushPara = () => {
    if (para.length) {
      blocks.push({ type: "p", text: para.join(" ").trim() });
      para = [];
    }
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trimEnd();
    const trimmed = line.trim();

    if (!trimmed) {
      flushPara();
      continue;
    }

    const heading = trimmed.match(/^(#{1,4})\s+(.+)$/);
    if (heading) {
      flushPara();
      const text = heading[2].trim();
      blocks.push({ type: heading[1].length <= 2 ? "h2" : "h3", text, id: headingId(text) });
      continue;
    }

    if (/^-{3,}$/.test(trimmed)) {
      flushPara();
      blocks.push({ type: "hr" });
      continue;
    }

    const image = trimmed.match(/^!\[([^\]]*)\]\(([^)\s]+)\)$/);
    if (image) {
      flushPara();
      blocks.push({ type: "img", alt: image[1], src: image[2] });
      continue;
    }

    if (trimmed.startsWith("|") && i + 1 < lines.length && TABLE_SEPARATOR.test(lines[i + 1].trim())) {
      flushPara();
      const head = splitRow(trimmed);
      const rows: string[][] = [];
      i += 2;
      while (i < lines.length && lines[i].trim().startsWith("|")) {
        rows.push(splitRow(lines[i]));
        i++;
      }
      i--; // the for-loop will advance again
      blocks.push({ type: "table", head, rows });
      continue;
    }

    if (/^>\s?/.test(trimmed)) {
      flushPara();
      const quote: string[] = [];
      while (i < lines.length && /^>\s?/.test(lines[i].trim())) {
        quote.push(lines[i].trim().replace(/^>\s?/, ""));
        i++;
      }
      i--;
      blocks.push({ type: "quote", text: quote.join(" ") });
      continue;
    }

    if (/^[-*]\s+/.test(trimmed)) {
      flushPara();
      const items: string[] = [];
      while (i < lines.length && /^[-*]\s+/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^[-*]\s+/, ""));
        i++;
      }
      i--;
      blocks.push({ type: "ul", items });
      continue;
    }

    if (/^\d+[.)]\s+/.test(trimmed)) {
      flushPara();
      const items: string[] = [];
      while (i < lines.length && /^\d+[.)]\s+/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^\d+[.)]\s+/, ""));
        i++;
      }
      i--;
      blocks.push({ type: "ol", items });
      continue;
    }

    para.push(trimmed);
  }
  flushPara();
  return blocks;
}

// ---------------------------------------------------------------------------
// Helpers used by the blog pages and the admin form
// ---------------------------------------------------------------------------

export function extractHeadings(source: string) {
  return parseMarkdown(source)
    .filter((b): b is Extract<Block, { type: "h2" | "h3" }> => b.type === "h2")
    .map((b) => ({ id: b.id, text: stripInline(b.text) }));
}

// Any "## Frequently asked questions" section followed by "### Question?"
// headings becomes FAQ structured data automatically — no extra admin work.
export function extractFaqs(source: string): { q: string; a: string }[] {
  const blocks = parseMarkdown(source);
  const faqs: { q: string; a: string }[] = [];
  let inFaq = false;
  let current: { q: string; a: string[] } | null = null;

  const push = () => {
    if (current && current.a.length) faqs.push({ q: current.q, a: current.a.join(" ") });
    current = null;
  };

  for (const b of blocks) {
    if (b.type === "h2") {
      push();
      inFaq = /faq|frequently asked/i.test(b.text);
      continue;
    }
    if (!inFaq) continue;
    if (b.type === "h3") {
      push();
      current = { q: stripInline(b.text), a: [] };
    } else if (current) {
      if (b.type === "p") current.a.push(stripInline(b.text));
      else if (b.type === "ul" || b.type === "ol") current.a.push(b.items.map(stripInline).join("; "));
    }
  }
  push();
  return faqs;
}

export function firstParagraph(source: string) {
  const p = parseMarkdown(source).find((b) => b.type === "p");
  return p && p.type === "p" ? stripInline(p.text) : "";
}

export function readingMinutes(source: string) {
  const words = stripInline(source).split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.round(words / 200));
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

function safeHref(href: string) {
  return /^(https?:\/\/|mailto:|tel:|\/|#)/i.test(href) ? href : "#";
}

const INLINE = /(\*\*[^*]+\*\*|\*[^*\s][^*]*\*|`[^`]+`|\[[^\]]+\]\([^)\s]+\))/g;

function renderInline(text: string, keyPrefix: string): React.ReactNode[] {
  return text.split(INLINE).map((part, i) => {
    const key = `${keyPrefix}-${i}`;
    if (!part) return null;
    if (part.startsWith("**") && part.endsWith("**")) return <strong key={key} className="font-medium text-ink">{part.slice(2, -2)}</strong>;
    if (part.startsWith("`") && part.endsWith("`")) return <code key={key} className="bg-nickel/15 px-1 text-[0.9em]">{part.slice(1, -1)}</code>;
    if (part.startsWith("*") && part.endsWith("*") && part.length > 2) return <em key={key}>{part.slice(1, -1)}</em>;
    const link = part.match(/^\[([^\]]+)\]\(([^)\s]+)\)$/);
    if (link) {
      const href = safeHref(link[2]);
      const cls = "text-ink underline decoration-brass decoration-2 underline-offset-4 hover:text-brass";
      if (href.startsWith("/")) return <Link key={key} href={href} className={cls}>{link[1]}</Link>;
      return (
        <a key={key} href={href} className={cls} rel="noopener noreferrer" target={href.startsWith("http") ? "_blank" : undefined}>
          {link[1]}
        </a>
      );
    }
    return <React.Fragment key={key}>{part}</React.Fragment>;
  });
}

export function Markdown({ source }: { source: string }) {
  const blocks = parseMarkdown(source);

  return (
    <div className="font-body text-[17px] leading-relaxed text-graphite">
      {blocks.map((b, i) => {
        const key = `b${i}`;
        switch (b.type) {
          case "h2":
            return (
              <h2 key={key} id={b.id} className="mt-14 scroll-mt-24 font-display text-3xl leading-tight text-ink">
                {renderInline(b.text, key)}
              </h2>
            );
          case "h3":
            return (
              <h3 key={key} id={b.id} className="mt-9 scroll-mt-24 font-display text-2xl leading-snug text-ink">
                {renderInline(b.text, key)}
              </h3>
            );
          case "p":
            return <p key={key} className="mt-4">{renderInline(b.text, key)}</p>;
          case "ul":
            return (
              <ul key={key} className="mt-4 list-disc space-y-2 pl-6 marker:text-brass">
                {b.items.map((it, j) => <li key={j}>{renderInline(it, `${key}-${j}`)}</li>)}
              </ul>
            );
          case "ol":
            return (
              <ol key={key} className="mt-4 list-decimal space-y-2 pl-6 marker:text-brass">
                {b.items.map((it, j) => <li key={j}>{renderInline(it, `${key}-${j}`)}</li>)}
              </ol>
            );
          case "quote":
            return (
              <blockquote key={key} className="mt-6 border-l-2 border-brass pl-5 font-display text-xl italic text-ink">
                {renderInline(b.text, key)}
              </blockquote>
            );
          case "hr":
            return <hr key={key} className="my-10 border-nickel/30" />;
          case "img":
            return (
              // eslint-disable-next-line @next/next/no-img-element
              <img key={key} src={b.src} alt={b.alt} loading="lazy" className="mt-6 w-full border border-nickel/20" />
            );
          case "table":
            return (
              <div key={key} className="mt-6 overflow-x-auto">
                <table className="w-full border-collapse text-left text-[15px]">
                  <thead>
                    <tr className="border-b border-ink/40">
                      {b.head.map((h, j) => (
                        <th key={j} className="py-2 pr-4 font-medium text-ink">{renderInline(h, `${key}-h${j}`)}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {b.rows.map((row, r) => (
                      <tr key={r} className="border-b border-nickel/25 align-top">
                        {row.map((cell, c) => (
                          <td key={c} className="py-2 pr-4">{renderInline(cell, `${key}-${r}-${c}`)}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            );
        }
      })}
    </div>
  );
}
