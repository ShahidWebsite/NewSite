"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { supabase } from "@/lib/supabase";
import BlogPostForm from "@/components/admin/BlogPostForm";
import { BlogPost } from "@/lib/types";

export default function EditBlogPostPage() {
  const params = useParams();
  const [post, setPost] = useState<BlogPost | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase
      .from("blog_posts")
      .select("*")
      .eq("id", params.id as string)
      .single()
      .then(({ data }) => {
        setPost(data as BlogPost | null);
        setLoading(false);
      });
  }, [params.id]);

  if (loading) return <p className="font-body text-graphite">Loading…</p>;
  if (!post) return <p className="font-body text-rust">Post not found.</p>;

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Edit guide</h1>
      <BlogPostForm existing={post} />
    </div>
  );
}
