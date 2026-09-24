import { NextResponse } from "next/server";
import { getServiceClient } from "@/lib/supabase";
import { calculateShippingFee, DEFAULT_SHIPPING_SETTINGS, FALLBACK_ITEM_WEIGHT_GRAMS } from "@/lib/shipping";

type IncomingLine = {
  variantId: string;
  quantity: number;
};

export async function POST(request: Request) {
  const body = await request.json();
  const { customerName, email, phone, shippingAddress, lines, paymentMethod } = body as {
    customerName: string;
    email: string;
    phone: string;
    shippingAddress: Record<string, string>;
    lines: IncomingLine[];
    paymentMethod?: "bank_transfer" | "cod";
  };

  if (!customerName || !email || !lines?.length) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  // Only two payment methods are wired up on the storefront today — never
  // trust a value the browser sends beyond that.
  const safePaymentMethod = paymentMethod === "cod" ? "cod" : "bank_transfer";

  const supabase = getServiceClient();

  // Re-fetch each variant server-side — never trust the price/stock the
  // browser sends, since that's easy to tamper with in devtools. Also pulls
  // the product's shipping weight, needed for the COD/shipping fee below.
  const variantIds = lines.map((l) => l.variantId);
  const { data: variants, error: variantError } = await supabase
    .from("product_variants")
    .select(
      "id, price, stock_qty, product_id, products(name, weight_grams), variant_attribute_values(attribute_value_id, attribute_values(value))"
    )
    .in("id", variantIds);

  if (variantError || !variants) {
    return NextResponse.json({ error: "Could not verify products" }, { status: 500 });
  }

  const orderItems = [];
  let subtotal = 0;
  let totalWeightGrams = 0;

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

    const itemWeight = (variant as any).products?.weight_grams || FALLBACK_ITEM_WEIGHT_GRAMS;
    totalWeightGrams += itemWeight * line.quantity;

    orderItems.push({
      product_id: variant.product_id,
      variant_id: variant.id,
      product_name: (variant as any).products?.name ?? "Product",
      variant_label: variantLabel,
      quantity: line.quantity,
      unit_price: variant.price,
    });
  }

  // Weight-based shipping fee, charged either way: collected by the courier
  // on delivery for COD, or added to the bank-transfer total.
  const { data: shippingSettingsRow } = await supabase.from("shipping_settings").select("*").single();
  const shippingSettings = shippingSettingsRow ?? DEFAULT_SHIPPING_SETTINGS;
  const shippingFee = calculateShippingFee(totalWeightGrams, shippingSettings);
  const total = subtotal + shippingFee;

  // Create the order
  const { data: order, error: orderError } = await supabase
    .from("orders")
    .insert({
      customer_name: customerName,
      email,
      phone,
      shipping_address: shippingAddress,
      subtotal,
      shipping_fee: shippingFee,
      total,
      payment_method: safePaymentMethod,
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

  const base = {
    orderNumber: order.order_number,
    subtotal: order.subtotal,
    shippingFee: order.shipping_fee,
    total: order.total,
    paymentMethod: safePaymentMethod,
  };

  if (safePaymentMethod === "cod") {
    return NextResponse.json({
      ...base,
      courierName: shippingSettings.courier_name ?? "the courier",
    });
  }

  const { data: bankAccounts } = await supabase
    .from("bank_accounts")
    .select("id, bank_name, account_title, account_number, ifsc_or_routing, sort_order, active")
    .eq("active", true)
    .order("sort_order");

  const { data: bankSettings } = await supabase.from("bank_settings").select("instructions").single();

  return NextResponse.json({
    ...base,
    bankAccounts: bankAccounts ?? [],
    instructions: bankSettings?.instructions ?? "Please use your Order Number as the payment reference.",
  });
}