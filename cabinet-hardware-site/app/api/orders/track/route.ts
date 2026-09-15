import { NextResponse } from "next/server";
import { getServiceClient } from "@/lib/supabase";

// Public order lookup. Orders have no public SELECT policy (see schema.sql),
// so this route uses the service role key and does its own authorization
// check: the order number AND the email must both match. This prevents
// anyone from browsing orders just by guessing sequential order numbers.
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const orderNumber = searchParams.get("orderNumber")?.trim();
  const email = searchParams.get("email")?.trim().toLowerCase();

  if (!orderNumber || !email) {
    return NextResponse.json({ error: "Order number and email are required" }, { status: 400 });
  }

  const supabase = getServiceClient();

  const { data: order } = await supabase
    .from("orders")
    .select("*, order_items(*)")
    .eq("order_number", orderNumber)
    .ilike("email", email)
    .single();

  if (!order) {
    return NextResponse.json(
      { error: "No order found with that order number and email combination." },
      { status: 404 }
    );
  }

  return NextResponse.json({ order });
}
