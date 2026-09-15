import { createClient } from "@supabase/supabase-js";

// Used in browser components and in server components for public reads.
// Safe to expose — this is the anon key, and RLS policies (see schema.sql)
// control exactly what it's allowed to touch.
export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// Used ONLY in API routes (app/api/**) — never import this into a component
// that ships to the browser. It bypasses RLS entirely.
export function getServiceClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
}
