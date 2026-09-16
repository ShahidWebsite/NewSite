"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    if (pathname === "/admin/login") {
      setChecked(true);
      return;
    }
    supabase.auth.getSession().then(({ data }) => {
      if (!data.session) {
        router.replace("/admin/login");
      } else {
        setChecked(true);
      }
    });
  }, [pathname, router]);

  if (pathname === "/admin/login") return <>{children}</>;
  if (!checked) return <div className="p-10 font-body text-graphite">Checking session…</div>;

  return (
    <div className="mx-auto flex max-w-6xl gap-10 px-6 py-10">
      <aside className="w-48 flex-shrink-0">
        <p className="font-display text-xl text-ink">Admin</p>
        <nav className="mt-6 space-y-2 font-body text-sm">
          <AdminLink href="/admin" label="Dashboard" />
          <AdminLink href="/admin/products" label="Products" />
          <AdminLink href="/admin/categories" label="Categories" />
          <AdminLink href="/admin/orders" label="Orders" />
        </nav>
        <button
          onClick={async () => {
            await supabase.auth.signOut();
            router.push("/admin/login");
          }}
          className="mt-8 font-body text-sm text-graphite hover:text-rust"
        >
          Sign out
        </button>
      </aside>
      <div className="flex-1">{children}</div>
    </div>
  );
}

function AdminLink({ href, label }: { href: string; label: string }) {
  return (
    <Link href={href} className="block text-graphite hover:text-ink">
      {label}
    </Link>
  );
}
