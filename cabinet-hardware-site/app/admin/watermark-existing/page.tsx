"use client";

import { useState } from "react";
import { supabase } from "@/lib/supabase";
import { watermarkImage, isWatermarkedUrl } from "@/lib/watermark";

const STORAGE_BUCKET = "product-images";

type Job = { table: string; id: string; column: string; url: string };

export default function WatermarkExistingPage() {
  const [running, setRunning] = useState(false);
  const [log, setLog] = useState<string[]>([]);
  const [progress, setProgress] = useState<{ done: number; total: number } | null>(null);

  const say = (line: string) => setLog((l) => [...l, line]);

  async function collectJobs(): Promise<Job[]> {
    const jobs: Job[] = [];
    const pi = await supabase.from("product_images").select("id, url");
    (pi.data ?? []).forEach((r: any) => r.url && jobs.push({ table: "product_images", id: r.id, column: "url", url: r.url }));
    const cat = await supabase.from("categories").select("id, image_url");
    (cat.data ?? []).forEach((r: any) => r.image_url && jobs.push({ table: "categories", id: r.id, column: "image_url", url: r.image_url }));
    const blog = await supabase.from("blog_posts").select("id, cover_image_url");
    (blog.data ?? []).forEach((r: any) => r.cover_image_url && jobs.push({ table: "blog_posts", id: r.id, column: "cover_image_url", url: r.cover_image_url }));
    // Only photos stored in our own Supabase bucket, and not already watermarked.
    return jobs.filter((j) => j.url.includes("/storage/v1/object/public/") && !isWatermarkedUrl(j.url));
  }

  async function start() {
    setRunning(true);
    setLog([]);
    let ok = 0;
    let failed = 0;
    try {
      const jobs = await collectJobs();
      setProgress({ done: 0, total: jobs.length });
      if (jobs.length === 0) say("Nothing to do — every photo already has the watermark.");
      for (let i = 0; i < jobs.length; i++) {
        const job = jobs[i];
        try {
          const res = await fetch(job.url);
          if (!res.ok) throw new Error(`could not download (${res.status})`);
          const blob = await res.blob();
          const original = decodeURIComponent(job.url.split("?")[0].split("/").pop() || "photo.jpg");
          const file = await watermarkImage(new File([blob], original, { type: blob.type || "image/jpeg" }));
          const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-");
          const path = `wm/${Date.now()}-${cleanName}`;
          const up = await supabase.storage.from(STORAGE_BUCKET).upload(path, file);
          if (up.error) throw new Error(up.error.message);
          const newUrl = supabase.storage.from(STORAGE_BUCKET).getPublicUrl(path).data.publicUrl;
          const upd = await supabase.from(job.table).update({ [job.column]: newUrl }).eq("id", job.id);
          if (upd.error) throw new Error(upd.error.message);
          ok++;
        } catch (err: any) {
          failed++;
          say(`Skipped one photo (${job.table}): ${err.message}`);
        }
        setProgress({ done: i + 1, total: jobs.length });
      }
      say(`Finished. ${ok} photo(s) watermarked${failed ? `, ${failed} skipped (you can press the button again to retry them)` : ""}.`);
      say("Your original photos are still safely stored in the bucket — nothing was deleted.");
    } catch (err: any) {
      say(`Stopped: ${err.message}`);
    } finally {
      setRunning(false);
    }
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Watermark existing photos</h1>
      <p className="mt-3 max-w-xl font-body text-sm text-graphite">
        New photos get your logo automatically. This button does the same for all photos already on the
        site (products, categories, guide cover photos). It is safe to press more than once — photos that
        are done are skipped. Keep this page open until it says “Finished”.
      </p>
      <button
        onClick={start}
        disabled={running}
        className="mt-6 bg-ink px-6 py-3 font-body text-sm text-white disabled:opacity-50"
      >
        {running ? "Working…" : "Add watermark to old photos"}
      </button>
      {progress && (
        <p className="mt-4 font-body text-sm text-ink">
          {progress.done} of {progress.total} done
        </p>
      )}
      <ul className="mt-4 space-y-1 font-body text-sm text-graphite">
        {log.map((l, i) => (
          <li key={i}>{l}</li>
        ))}
      </ul>
    </div>
  );
}