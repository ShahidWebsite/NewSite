"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

export default function AdminLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);

    if (error) {
      setError("Incorrect email or password.");
      return;
    }
    router.push("/admin");
  }

  return (
    <div className="mx-auto max-w-sm px-6 py-24">
      <h1 className="font-display text-3xl text-ink">Admin login</h1>
      <form onSubmit={handleSubmit} className="mt-8 space-y-4">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="Email"
          required
          className="w-full border border-nickel/50 bg-transparent px-3 py-2 font-body text-ink focus:border-ink"
        />
        <div className="relative">
          <input
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Password"
            required
            className="w-full border border-nickel/50 bg-transparent px-3 py-2 pr-16 font-body text-ink focus:border-ink"
          />
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            className="absolute right-2 top-1/2 -translate-y-1/2 font-body text-xs text-graphite hover:text-ink"
          >
            {showPassword ? "Hide" : "Show"}
          </button>
        </div>
        {error && <p className="font-body text-sm text-rust">{error}</p>}
        <button
          type="submit"
          disabled={loading}
          className="w-full bg-ink py-2 font-body text-sm text-stone hover:bg-brass disabled:opacity-60"
        >
          {loading ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </div>
  );
}
