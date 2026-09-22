"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import SeoFields from "@/components/admin/SeoFields";
import { firstParagraph } from "@/lib/markdown";
import { generateBlogSeoDescription, generateBlogSeoTitle, slugify, truncateAtWord } from "@/lib/seo";
import { BlogPost } from "@/lib/types";

const STORAGE_BUCKET = "product-images"; // same bucket as product photos, in a "blog/" folder

export default function BlogPostForm({ existing }: { existing?: BlogPost }) {
  const router = useRouter();
  const isEdit = !!existing;

  const [title, setTitle] = useState(existing?.title ?? "");
  const [tag, setTag] = useState(existing?.tag ?? "");
  const [content, setContent] = useState(existing?.content ?? "");
  const [slugOverride, setSlugOverride] = useState<string | null>(existing ? existing.slug : null);
  const [excerptOverride, setExcerptOverride] = useState<string | null>(existing?.excerpt ? existing.excerpt : null);
  const [seoTitleOverride, setSeoTitleOverride] = useState<string | null>(existing?.seo_title || null);
  const [seoDescOverride, setSeoDescOverride] = useState<string | null>(existing?.seo_description || null);
  const [published, setPublished] = useState(existing?.published ?? false);
  const [coverUrl, setCoverUrl] = useState<string | null>(existing?.cover_image_url ?? null);
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showHelp, setShowHelp] = useState(false);
  const [insertingImage, setInsertingImage] = useState(false);
  const contentRef = useRef<HTMLTextAreaElement | null>(null);

  // ---- Automatic values, built from what's been written ----
  const slug = slugOverride ?? slugify(title);
  const autoExcerpt = truncateAtWord(firstParagraph(content), 160);
  const excerpt = excerptOverride ?? autoExcerpt;
  const autoSeoTitle = title ? generateBlogSeoTitle(title) : "";
  const autoSeoDescription = excerpt ? generateBlogSeoDescription(excerpt) : "";
  const seoTitle = seoTitleOverride ?? autoSeoTitle;
  const seoDescription = seoDescOverride ?? autoSeoDescription;

  // Uploads a photo the same way the cover photo does, then drops it into
  // the article text as a markdown image — right where the cursor is, so a
  // photo can sit next to whichever paragraph it explains (e.g. a sizing
  // diagram inside a "How to measure" guide).
  async function handleInsertImage(file: File | null) {
    if (!file) return;
    setInsertingImage(true);
    setError(null);
    try {
      const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-");
      const path = `blog/${Date.now()}-${cleanName}`;
      const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, file);
      if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);
      const url = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path).data.publicUrl;

      const textarea = contentRef.current;
      const markdown = `![](${url})`;
      if (textarea) {
        const start = textarea.selectionStart ?? content.length;
        const end = textarea.selectionEnd ?? content.length;
        const before = content.slice(0, start);
        const after = content.slice(end);
        // Keep the image on its own line, with a blank line on each side.
        const prefix = before && !before.endsWith("\n\n") ? (before.endsWith("\n") ? "\n" : "\n\n") : "";
        const suffix = after && !after.startsWith("\n\n") ? (after.startsWith("\n") ? "\n" : "\n\n") : "";
        const next = `${before}${prefix}${markdown}${suffix}${after}`;
        setContent(next);
        // Put the cursor right after the inserted image next render.
        requestAnimationFrame(() => {
          const pos = (before + prefix + markdown).length;
          textarea.focus();
          textarea.setSelectionRange(pos, pos);
        });
      } else {
        setContent((c) => `${c}${c ? "\n\n" : ""}${markdown}\n\n`);
      }
    } catch (err: any) {
      setError(err.message || "Something went wrong uploading this photo.");
    } finally {
      setInsertingImage(false);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);

    try {
      if (!slug) throw new Error("Please add a title.");

      let cover = coverUrl;
      if (coverFile) {
        const cleanName = coverFile.name.replace(/[^a-zA-Z0-9._-]/g, "-");
        const path = `blog/${Date.now()}-${cleanName}`;
        const { error: uploadError } = await supabase.storage.from(STORAGE_BUCKET).upload(path, coverFile);
        if (uploadError) throw new Error(`Image upload failed: ${uploadError.message}`);
        cover = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path).data.publicUrl;
      }

      const now = new Date().toISOString();
      const payload = {
        slug,
        title: title.trim(),
        tag: tag.trim() || null,
        excerpt: excerpt.trim() || null,
        content,
        cover_image_url: cover,
        seo_title: seoTitleOverride?.trim() || null, // null = generated automatically
        seo_description: seoDescOverride?.trim() || null,
        published,
        // First time it goes live, stamp the date; keep the original date afterwards.
        published_at: published ? existing?.published_at ?? now : existing?.published_at ?? null,
        updated_at: now,
      };

      const result = isEdit
        ? await supabase.from("blog_posts").update(payload).eq("id", existing!.id)
        : await supabase.from("blog_posts").insert(payload);
      if (result.error) {
        throw new Error(
          result.error.message.includes("duplicate")
            ? "Another post already uses this web address — change the title or the web address."
            : result.error.message
        );
      }

      router.push("/admin/blog");
    } catch (err: any) {
      setError(err.message || "Something went wrong saving this post.");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mt-8 max-w-3xl space-y-8">
      {error && (
        <div className="border-2 border-rust bg-rust/10 p-4">
          <p className="font-body text-sm font-medium text-rust">Could not save this post:</p>
          <p className="mt-1 font-body text-sm text-rust">{error}</p>
        </div>
      )}

      <div className="space-y-4">
        <label className="block">
          <span className="font-body text-sm text-graphite">Title</span>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            placeholder="e.g. How to measure cabinet handle hole spacing"
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
          />
        </label>

        <label className="block">
          <span className="font-body text-sm text-graphite">Topic (one or two words, e.g. Sizing, Materials, Care)</span>
          <input
            value={tag}
            onChange={(e) => setTag(e.target.value)}
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
          />
        </label>

        <div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Web address</span>
            <div className="mt-1 flex items-center border border-nickel/50">
              <span className="px-3 font-body text-sm text-graphite">/blog/</span>
              <input
                value={slug}
                onChange={(e) => setSlugOverride(slugify(e.target.value) || null)}
                disabled={isEdit}
                className="w-full bg-transparent py-2 pr-3 font-body text-ink disabled:text-graphite"
              />
            </div>
          </label>
          <p className="mt-1 font-body text-xs text-graphite">
            {isEdit
              ? "The web address can't be changed after publishing, so existing links keep working."
              : "Made from the title automatically. Keep it short and descriptive."}
          </p>
        </div>

        <div>
          <div className="flex items-center justify-between">
            <span className="font-body text-sm text-graphite">Article text</span>
            <div className="flex items-center gap-4">
              <label className="cursor-pointer font-body text-xs text-graphite underline hover:text-ink">
                {insertingImage ? "Uploading…" : "+ Insert photo"}
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  disabled={insertingImage}
                  onChange={(e) => {
                    handleInsertImage(e.target.files?.[0] ?? null);
                    e.target.value = "";
                  }}
                />
              </label>
              <button
                type="button"
                onClick={() => setShowHelp((v) => !v)}
                className="font-body text-xs text-graphite underline hover:text-ink"
              >
                {showHelp ? "Hide formatting help" : "Formatting help"}
              </button>
            </div>
          </div>
          <p className="mt-1 font-body text-xs text-graphite">
            Click into the article text where you want a photo to appear (e.g. right after the
            paragraph it explains), then use &quot;+ Insert photo&quot; — it drops the picture in
            at that spot.
          </p>
          {showHelp && (
            <pre className="mt-2 overflow-x-auto border border-nickel/30 bg-white/50 p-3 font-body text-xs leading-relaxed text-graphite">
{`## A big heading
### A smaller heading
Normal paragraph text. **Bold**, *italic*, [a link](/shop?category=cabinet-handles)

- A bullet point
- Another bullet point

1. First step
2. Second step

| Size | Best for |
|---|---|
| 96mm | Drawers |
| 128mm | Wardrobe doors |

![](a photo — use the "+ Insert photo" button above instead of typing this by hand)

## Frequently asked questions
### A question a customer might ask?
The answer, in a normal paragraph.`}
            </pre>
          )}
          <textarea
            ref={contentRef}
            value={content}
            onChange={(e) => setContent(e.target.value)}
            required
            rows={24}
            className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-sm leading-relaxed text-ink"
          />
          <p className="mt-1 font-body text-xs text-graphite">
            Tip: aim for 600+ words that genuinely answer a customer question. A section titled
            &quot;Frequently asked questions&quot; with a smaller heading for each question automatically
            becomes Google FAQ results.
          </p>
        </div>

        <div>
          <label className="block">
            <span className="font-body text-sm text-graphite">Short summary (shown on the Guides page)</span>
            <textarea
              value={excerpt}
              onChange={(e) => setExcerptOverride(e.target.value === "" ? null : e.target.value)}
              rows={2}
              className="mt-1 w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink"
            />
          </label>
          <p className="mt-1 font-body text-xs text-graphite">
            {excerptOverride === null ? "Taken from the first paragraph automatically." : "Using your own wording."}
            {excerptOverride !== null && (
              <button type="button" onClick={() => setExcerptOverride(null)} className="ml-2 underline hover:text-ink">
                Reset to auto
              </button>
            )}
          </p>
        </div>

        <div>
          <p className="font-body text-sm text-graphite">Cover photo (optional)</p>
          <p className="font-body text-xs text-graphite">
            If you skip this, a branded picture with the title is used automatically — including when the
            post is shared on WhatsApp or Facebook.
          </p>
          <div className="mt-2 flex items-center gap-4">
            {(coverFile || coverUrl) && (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={coverFile ? URL.createObjectURL(coverFile) : coverUrl!}
                alt=""
                className="h-20 w-32 border border-nickel/30 object-cover"
              />
            )}
            <label className="cursor-pointer border border-dashed border-nickel/50 px-4 py-2 font-body text-sm text-graphite hover:border-ink hover:text-ink">
              {coverFile || coverUrl ? "Change photo" : "+ Add photo"}
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => setCoverFile(e.target.files?.[0] ?? null)}
              />
            </label>
            {(coverFile || coverUrl) && (
              <button
                type="button"
                onClick={() => {
                  setCoverFile(null);
                  setCoverUrl(null);
                }}
                className="font-body text-sm text-graphite hover:text-rust"
              >
                Remove
              </button>
            )}
          </div>
        </div>
      </div>

      <SeoFields
        urlPreview={`www.siqbalhwc.com › blog › ${slug || "your-post"}`}
        title={seoTitle}
        description={seoDescription}
        titleIsAuto={seoTitleOverride === null}
        descriptionIsAuto={seoDescOverride === null}
        onTitleChange={(v) => setSeoTitleOverride(v === "" ? null : v)}
        onDescriptionChange={(v) => setSeoDescOverride(v === "" ? null : v)}
        onResetTitle={() => setSeoTitleOverride(null)}
        onResetDescription={() => setSeoDescOverride(null)}
      />

      <label className="flex items-center gap-3">
        <input type="checkbox" checked={published} onChange={(e) => setPublished(e.target.checked)} className="h-4 w-4" />
        <span className="font-body text-sm text-ink">
          Published — visible on the website {published ? "" : "(untick to keep it as a private draft)"}
        </span>
      </label>

      <button
        type="submit"
        disabled={saving}
        className="bg-ink px-6 py-3 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
      >
        {saving ? "Saving…" : isEdit ? "Save changes" : "Save post"}
      </button>
    </form>
  );
}
