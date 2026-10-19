"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

const FULFILLMENT_STEPS = ["processing", "packed", "shipped", "delivered", "cancelled"];

function money(n: number | string | null | undefined) {
  return `Rs. ${Number(n ?? 0).toLocaleString()}`;
}

function phoneDigits(phone: string | null | undefined) {
  return (phone ?? "").replace(/[^0-9]/g, "");
}

// Turns a Pakistani number like 0311 7798157 into 923117798157 for WhatsApp links.
function whatsappNumber(phone: string | null | undefined) {
  const d = phoneDigits(phone);
  if (d.startsWith("92")) return d;
  if (d.startsWith("0")) return "92" + d.slice(1);
  return d;
}

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [openId, setOpenId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    const { data, error } = await supabase
      .from("orders")
      .select("*, order_items(*)")
      .order("created_at", { ascending: false });
    if (error) setError(error.message);
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

      {error && (
        <p className="mt-4 font-body text-sm text-rust">Could not load everything: {error}</p>
      )}

      {loading ? (
        <p className="mt-8 font-body text-graphite">Loading…</p>
      ) : orders.length === 0 ? (
        <p className="mt-8 font-body text-graphite">No orders yet.</p>
      ) : (
        <div className="mt-8 space-y-4">
          {orders.map((order) => {
            const isOpen = openId === order.id;
            const items: any[] = order.order_items ?? [];
            const addr = order.shipping_address ?? {};
            const addressLines = [
              addr.line1,
              addr.line2,
              [addr.city, addr.region].filter(Boolean).join(", "),
              [addr.postal_code, addr.country].filter(Boolean).join(" "),
            ].filter((l) => l && String(l).trim().length > 0);
            const itemCount = items.reduce((n, i) => n + (i.quantity ?? 0), 0);

            return (
              <div key={order.id} className="border border-nickel/30 p-4">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <p className="font-body text-ink">
                      {order.order_number}
                      <span className="ml-2 border border-nickel/40 px-1.5 py-0.5 font-body text-xs uppercase text-graphite">
                        {order.payment_method === "cod" ? "COD" : "Bank transfer"}
                      </span>
                    </p>
                    <p className="font-body text-sm text-graphite">
                      {order.customer_name} · {order.email}
                    </p>
                    <p className="font-body text-xs text-graphite">
                      {new Date(order.created_at).toLocaleString()} · {itemCount} item{itemCount === 1 ? "" : "s"}
                      {addr.city ? ` · ${addr.city}` : ""}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-display text-lg text-ink">{money(order.total)}</p>
                    {order.shipping_fee > 0 && (
                      <p className="font-body text-xs text-graphite">incl. {money(order.shipping_fee)} shipping</p>
                    )}
                  </div>
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

                  <button
                    onClick={() => setOpenId(isOpen ? null : order.id)}
                    className="ml-auto border border-ink px-3 py-1 font-body text-sm text-ink hover:bg-ink hover:text-white"
                  >
                    {isOpen ? "Hide details" : "View full details"}
                  </button>
                </div>

                {isOpen && (
                  <div className="mt-4 border-t border-nickel/30 pt-4">
                    <div className="grid gap-6 sm:grid-cols-2">
                      <div>
                        <p className="font-body text-xs uppercase tracking-wide text-graphite">Customer</p>
                        <p className="mt-1 font-body text-ink">{order.customer_name}</p>
                        {order.phone && (
                          <p className="font-body text-sm text-ink">
                            <a href={`tel:${order.phone}`} className="underline hover:text-brass">{order.phone}</a>
                            {" · "}
                            <a
                              href={`https://wa.me/${whatsappNumber(order.phone)}`}
                              target="_blank"
                              rel="noreferrer"
                              className="underline hover:text-brass"
                            >
                              WhatsApp
                            </a>
                          </p>
                        )}
                        <p className="font-body text-sm text-graphite">
                          <a href={`mailto:${order.email}`} className="underline hover:text-brass">{order.email}</a>
                        </p>
                      </div>

                      <div>
                        <p className="font-body text-xs uppercase tracking-wide text-graphite">Deliver to</p>
                        {addressLines.length === 0 ? (
                          <p className="mt-1 font-body text-sm text-graphite">No address saved</p>
                        ) : (
                          <div className="mt-1 font-body text-ink">
                            {addressLines.map((l, i) => (
                              <p key={i}>{l}</p>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>

                    <p className="mt-6 font-body text-xs uppercase tracking-wide text-graphite">Items to pack</p>
                    <div className="mt-2 overflow-x-auto">
                      <table className="w-full text-left font-body text-sm">
                        <thead>
                          <tr className="border-b border-nickel/30 text-graphite">
                            <th className="py-2 pr-4 font-normal">Product</th>
                            <th className="py-2 pr-4 font-normal">Variant</th>
                            <th className="py-2 pr-4 text-right font-normal">Qty</th>
                            <th className="py-2 pr-4 text-right font-normal">Unit price</th>
                            <th className="py-2 text-right font-normal">Line total</th>
                          </tr>
                        </thead>
                        <tbody>
                          {items.map((it) => (
                            <tr key={it.id} className="border-b border-nickel/20 text-ink">
                              <td className="py-2 pr-4">{it.product_name}</td>
                              <td className="py-2 pr-4">{it.variant_label || "—"}</td>
                              <td className="py-2 pr-4 text-right">{it.quantity}</td>
                              <td className="py-2 pr-4 text-right">{money(it.unit_price)}</td>
                              <td className="py-2 text-right">{money(it.unit_price * it.quantity)}</td>
                            </tr>
                          ))}
                          {items.length === 0 && (
                            <tr>
                              <td colSpan={5} className="py-3 text-graphite">No items found for this order.</td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>

                    <div className="mt-4 ml-auto max-w-xs space-y-1 font-body text-sm">
                      <div className="flex justify-between text-graphite">
                        <span>Subtotal</span>
                        <span>{money(order.subtotal)}</span>
                      </div>
                      <div className="flex justify-between text-graphite">
                        <span>Shipping</span>
                        <span>{money(order.shipping_fee)}</span>
                      </div>
                      <div className="flex justify-between border-t border-nickel/30 pt-1 font-display text-base text-ink">
                        <span>Total</span>
                        <span>{money(order.total)}</span>
                      </div>
                      {order.payment_method === "cod" && order.payment_status !== "paid" && (
                        <p className="pt-1 text-right text-xs text-rust">
                          COD: courier must collect {money(order.total)} from the customer
                        </p>
                      )}
                      {order.payment_method !== "cod" && order.payment_reference && (
                        <p className="pt-1 text-right text-xs text-graphite">
                          Payment reference: {order.payment_reference}
                        </p>
                      )}
                    </div>

                    <div className="mt-4">
                      <button
                        onClick={() => window.print()}
                        className="font-body text-sm text-graphite underline hover:text-brass"
                      >
                        Print this page (packing slip)
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}