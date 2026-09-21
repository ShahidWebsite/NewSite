import Link from "next/link";
import Image from "next/image";
import { readingMinutes } from "@/lib/markdown";
import { BlogPost } from "@/lib/types";

type CardPost = Pick<BlogPost, "slug" | "title" | "tag" | "excerpt" | "cover_image_url" | "content"> & {
  published_at?: string | null;
};

export default function BlogCard({ post }: { post: CardPost }) {
  return (
    <Link href={`/blog/${post.slug}`} className="group flex h-full flex-col">
      <div className="relative aspect-[16/10] overflow-hidden bg-blacknickel">
        {post.cover_image_url ? (
          <Image
            src={post.cover_image_url}
            alt={post.title}
            fill
            sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
            className="object-cover transition-transform duration-300 group-hover:scale-[1.03]"
          />
        ) : (
          <div className="flex h-full w-full items-end border-b-4 border-brass p-6">
            <span className="font-display text-4xl italic leading-none text-stone">{post.tag || "Guide"}</span>
          </div>
        )}
      </div>
      <h3 className="mt-4 font-display text-2xl leading-snug text-ink group-hover:text-brass">{post.title}</h3>
      {post.excerpt && <p className="mt-2 font-body text-sm text-graphite">{post.excerpt}</p>}
      <p className="mt-3 font-body text-xs text-graphite">
        {post.published_at
          ? `${new Date(post.published_at).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })} — `
          : ""}
        {readingMinutes(post.content)} min read
      </p>
    </Link>
  );
}
