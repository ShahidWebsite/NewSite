import { NextResponse } from "next/server";
import { getServiceClient } from "@/lib/supabase";

export async function POST(request: Request) {
  const body = await request.json();
  const { name, phone, email, message, enquiryType } = body as {
    name: string;
    phone: string;
    email?: string;
    message: string;
    enquiryType: "general" | "bulk_wholesale";
  };

  if (!name?.trim() || !phone?.trim() || !message?.trim()) {
    return NextResponse.json({ error: "Name, phone, and a message are required." }, { status: 400 });
  }

  const supabase = getServiceClient();

  const { error } = await supabase.from("enquiries").insert({
    name: name.trim(),
    phone: phone.trim(),
    email: email?.trim() || null,
    message: message.trim(),
    enquiry_type: enquiryType === "bulk_wholesale" ? "bulk_wholesale" : "general",
  });

  if (error) {
    return NextResponse.json({ error: "Could not save your message. Please try WhatsApp instead." }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}