"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

const FULFILLMENT_STEPS = ["processing", "packed", "shipped", "delivered", "cancelled"];

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const { data } = await supabase.from("orders").select("*").order("created_at", { ascending: false });
    setOrders(data ?? []);
    setLoading(false);
  }

  useEffect(() => {
    load();
  }, []);

  async function markPaid(id: string) {
    await supabase.from("orders").update({ payment_status: "paid" }).eq("id", id);
    load();
  }

  async function updateFulfillment(id: string, status: string) {
    await supabase.from("orders").update({ fulfillment_status: status }).eq("id", id);
    load();
  }

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Orders</h1>

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : orders.length === 0 ? (
        <p className="mt-8 font-body text-graphite">No orders yet.</p>
      ) : (
        <div className="mt-8 space-y-4">
          {orders.map((order) => (
            <div key={order.id} className="border border-nickel/30 p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="font-body text-ink">{order.order_number}</p>
                  <p className="font-body text-sm text-graphite">
                    {order.customer_name} · {order.email}
                  </p>
                </div>
                <p className="font-display text-lg text-ink">Rs. {order.total.toLocaleString()}</p>
              </div>

              <div className="mt-3 flex flex-wrap items-center gap-4">
                <div className="flex items-center gap-2">
                  <span className="font-body text-sm text-graphite">Payment:</span>
                  <span
                    className={`font-body text-sm ${
                      order.payment_status === "paid" ? "text-olive" : "text-rust"
                    }`}
                  >
                    {order.payment_status}
                  </span>
                  {order.payment_status !== "paid" && (
                    <button
                      onClick={() => markPaid(order.id)}
                      className="font-body text-sm text-ink underline hover:text-brass"
                    >
                      Mark as paid
                    </button>
                  )}
                </div>

                <div className="flex items-center gap-2">
                  <span className="font-body text-sm text-graphite">Fulfillment:</span>
                  <select
                    value={order.fulfillment_status}
                    onChange={(e) => updateFulfillment(order.id, e.target.value)}
                    className="border border-nickel/50 bg-transparent px-2 py-1 font-body text-sm text-ink"
                  >
                    {FULFILLMENT_STEPS.map((s) => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
