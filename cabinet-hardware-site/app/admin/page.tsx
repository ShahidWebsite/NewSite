"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default function AdminDashboard() {
  const [stats, setStats] = useState<{ products: number; pendingOrders: number; lowStock: number } | null>(
    null
  );

  useEffect(() => {
    async function load() {
      const [{ count: products }, { count: pendingOrders }, { data: variants }] = await Promise.all([
        supabase.from("products").select("*", { count: "exact", head: true }),
        supabase.from("orders").select("*", { count: "exact", head: true }).eq("payment_status", "pending"),
        supabase.from("product_variants").select("stock_qty").lte("stock_qty", 5),
      ]);
      setStats({
        products: products ?? 0,
        pendingOrders: pendingOrders ?? 0,
        lowStock: variants?.length ?? 0,
      });
    }
    load();
  }, []);

  return (
    <div>
      <h1 className="font-display text-3xl text-ink">Dashboard</h1>
      <div className="mt-8 grid grid-cols-3 gap-6">
        <StatCard label="Products" value={stats?.products} href="/admin/products" />
        <StatCard label="Pending payments" value={stats?.pendingOrders} href="/admin/orders" />
        <StatCard label="Low stock (≤5)" value={stats?.lowStock} href="/admin/products" />
      </div>
    </div>
  );
}

function StatCard({ label, value, href }: { label: string; value?: number; href: string }) {
  return (
    <Link href={href} className="block border border-nickel/30 p-6 hover:border-ink">
      <p className="font-body text-sm text-graphite">{label}</p>
      <p className="mt-2 font-display text-3xl text-ink">{value ?? "—"}</p>
    </Link>
  );
}
