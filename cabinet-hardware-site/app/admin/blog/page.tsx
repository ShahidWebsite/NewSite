"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { BlogPost } from "@/lib/types";

type Row = Pick<BlogPost, "id" | "slug" | "title" | "tag" | "published" | "published_at" | "updated_at">;

export default function AdminBlogPage() {
  const [posts, setPosts] = useState<Row[] | null>(null);

  async function load() {
    const { data } = await supabase
      .from("blog_posts")
      .select("id, slug, title, tag, published, published_at, updated_at")
      .order("created_at", { ascending: false });
    setPosts((data ?? []) as Row[]);
  }

  useEffect(() => {
    load();
  }, []);

  async function handleDelete(post: Row) {
    if (!window.confirm(`Delete "${post.title}"? This cannot be undone.`)) return;
    await supabase.from("blog_posts").delete().eq("id", post.id);
    load();
  }

  async function togglePublished(post: Row) {
    const now = new Date().toISOString();
    await supabase
      .from("blog_posts")
      .update({
        published: !post.published,
        published_at: post.published_at ?? (!post.published ? now : null),
        updated_at: now,
      })
      .eq("id", post.id);
    load();
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="font-display text-3xl text-ink">Guides (blog)</h1>
        <Link href="/admin/blog/new" className="bg-ink px-4 py-2 font-body text-sm text-stone hover:bg-brass">
          + New guide
        </Link>
      </div>

      {posts === null ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : posts.length === 0 ? (
        <p className="mt-8 font-body text-graphite">
          No guides yet. If you just set up the blog, make sure the database update (SQL) has been run.
        </p>
      ) : (
        <table className="mt-8 w-full text-left font-body text-sm">
          <thead>
            <tr className="border-b border-nickel/40 text-graphite">
              <th className="py-2 font-normal">Title</th>
              <th className="py-2 font-normal">Status</th>
              <th className="py-2 font-normal" />
            </tr>
          </thead>
          <tbody>
            {posts.map((p) => (
              <tr key={p.id} className="border-b border-nickel/20">
                <td className="py-3 pr-4 text-ink">
                  {p.title}
                  {p.tag && <span className="ml-2 text-xs text-graphite">{p.tag}</span>}
                </td>
                <td className="py-3 pr-4">
                  <span className={p.published ? "text-olive" : "text-graphite"}>
                    {p.published ? "Published" : "Draft"}
                  </span>
                </td>
                <td className="space-x-4 py-3 text-right">
                  {p.published && (
                    <a href={`/blog/${p.slug}`} target="_blank" rel="noopener noreferrer" className="text-graphite hover:text-ink">
                      View
                    </a>
                  )}
                  <Link href={`/admin/blog/${p.id}/edit`} className="text-graphite hover:text-ink">Edit</Link>
                  <button onClick={() => togglePublished(p)} className="text-graphite hover:text-ink">
                    {p.published ? "Unpublish" : "Publish"}
                  </button>
                  <button onClick={() => handleDelete(p)} className="text-graphite hover:text-rust">Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
