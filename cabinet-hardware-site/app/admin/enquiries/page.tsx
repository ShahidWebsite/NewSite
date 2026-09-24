"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Enquiry } from "@/lib/types";

const STATUS_STEPS: Enquiry["status"][] = ["new", "contacted", "closed"];

export default function AdminEnquiriesPage() {
  const [enquiries, setEnquiries] = useState<Enquiry[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const { data } = await supabase.from("enquiries").select("*").order("created_at", { ascending: false });
    setEnquiries(data ?? []);
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function updateStatus(id: string, status: string) {
    await supabase.from("enquiries").update({ status }).eq("id", id);
    load();
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Enquiries</h1>
      <p className="mt-2 font-body text-sm text-graphite">
        Messages from the Contact &amp; Bulk Enquiry page.
      </p>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : enquiries.length === 0 ? (
        <p className="mt-8 font-body text-graphite">No enquiries yet.</p>
      ) : (
        <div className="mt-8 space-y-4">
          {enquiries.map((enq) => (
            <div key={enq.id} className="border border-nickel/30 p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="font-body text-ink">
                    {enq.name}
                    {enq.enquiry_type === "bulk_wholesale" && (
                      <span className="ml-2 border border-brass px-1.5 py-0.5 font-body text-xs text-brass">
                        Bulk / wholesale
                      </span>
                    )}
                  </p>
                  <p className="font-body text-sm text-graphite">
                    {enq.phone}
                    {enq.email ? ` · ${enq.email}` : ""}
                  </p>
                </div>
                <p className="font-body text-xs text-graphite">
                  {new Date(enq.created_at).toLocaleString()}
                </p>
              </div>

              <p className="mt-3 whitespace-pre-wrap font-body text-sm text-ink">{enq.message}</p>

              <div className="mt-4 flex items-center gap-2">
                <span className="font-body text-sm text-graphite">Status:</span>
                {STATUS_STEPS.map((s) => (
                  <button
                    key={s}
                    onClick={() => updateStatus(enq.id, s)}
                    className={`border px-2 py-1 font-body text-xs capitalize ${
                      enq.status === s ? "border-ink bg-ink text-stone" : "border-nickel/40 text-graphite hover:text-ink"
                    }`}
                  >
                    {s}
                  </button>
                ))}
                <a
                  href={`https://wa.me/${enq.phone.replace(/[^\d]/g, "")}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="ml-auto font-body text-xs text-graphite underline hover:text-ink"
                >
                  Reply on WhatsApp
                </a>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}