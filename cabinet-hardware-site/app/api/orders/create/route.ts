import { NextResponse } from "next/server";
import { getServiceClient } from "@/lib/supabase";

type IncomingLine = {
  variantId: string;
  quantity: number;
};

export async function POST(request: Request) {
  const body = await request.json();
  const { customerName, email, phone, shippingAddress, lines } = body as {
    customerName: string;
    email: string;
    phone: string;
    shippingAddress: Record<string, string>;
    lines: IncomingLine[];
  };

  if (!customerName || !email || !lines?.length) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  const supabase = getServiceClient();

  // Re-fetch each variant server-side — never trust the price/stock the
  // browser sends, since that's easy to tamper with in devtools.
  const variantIds = lines.map((l) => l.variantId);
  const { data: variants, error: variantError } = await supabase
    .from("product_variants")
    .select("id, price, stock_qty, product_id, products(name), variant_attribute_values(attribute_value_id, attribute_values(value))")
    .in("id", variantIds);

  if (variantError || !variants) {
    return NextResponse.json({ error: "Could not verify products" }, { status: 500 });
  }

  const orderItems = [];
  let subtotal = 0;

  for (const line of lines) {
    const variant = variants.find((v: any) => v.id === line.variantId);
    if (!variant) {
      return NextResponse.json({ error: "One of the items is no longer available" }, { status: 400 });
    }
    if (variant.stock_qty < line.quantity) {
      return NextResponse.json(
        { error: `Not enough stock for one of the items. Only ${variant.stock_qty} left.` },
        { status: 400 }
      );
    }

    const variantLabel = (variant as any).variant_attribute_values
      .map((j: any) => j.attribute_values?.value)
      .filter(Boolean)
      .join(" / ");

    const lineTotal = variant.price * line.quantity;
    subtotal += lineTotal;

    orderItems.push({
      product_id: variant.product_id,
      variant_id: variant.id,
      product_name: (variant as any).products?.name ?? "Product",
      variant_label: variantLabel,
      quantity: line.quantity,
      unit_price: variant.price,
    });
  }

  // Create the order
  const { data: order, error: orderError } = await supabase
    .from("orders")
    .insert({
      customer_name: customerName,
      email,
      phone,
      shipping_address: shippingAddress,
      subtotal,
      total: subtotal, // no shipping/tax logic yet — add here when ready
      payment_method: "bank_transfer",
    })
    .select()
    .single();

  if (orderError || !order) {
    return NextResponse.json({ error: "Could not create the order" }, { status: 500 });
  }

  // Attach order_id now that we have it, then insert items
  const { error: itemsError } = await supabase
    .from("order_items")
    .insert(orderItems.map((item) => ({ ...item, order_id: order.id })));

  if (itemsError) {
    return NextResponse.json({ error: "Could not save order items" }, { status: 500 });
  }

  // Decrement stock for each variant
  for (const line of lines) {
    const variant = variants.find((v: any) => v.id === line.variantId)!;
    await supabase
      .from("product_variants")
      .update({ stock_qty: variant.stock_qty - line.quantity })
      .eq("id", line.variantId);
  }

  const { data: bankAccounts } = await supabase
    .from("bank_accounts")
    .select("id, bank_name, account_title, account_number, ifsc_or_routing, sort_order, active")
    .eq("active", true)
    .order("sort_order");

  const { data: bankSettings } = await supabase.from("bank_settings").select("instructions").single();

  return NextResponse.json({
    orderNumber: order.order_number,
    total: order.total,
    bankAccounts: bankAccounts ?? [],
    instructions: bankSettings?.instructions ?? "Please use your Order Number as the payment reference.",
  });
}
