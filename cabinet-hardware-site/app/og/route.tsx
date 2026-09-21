import { ImageResponse } from "next/og";

// Branded 1200x630 share card. This is the picture that appears when someone
// pastes a link to the site into WhatsApp, Facebook, Instagram DMs, LinkedIn
// or X. Blog posts pass ?title= so each one gets its own card.
export const runtime = "edge";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const title = (searchParams.get("title") || "").slice(0, 110);
  const tag = (searchParams.get("tag") || "").slice(0, 30);

  const headline = title || "Door handles, cabinet handles & knobs";
  const sub = title
    ? tag
      ? `${tag} guide from our Lahore shop`
      : "Hardware guides from our Lahore shop"
    : "Brass hardware from Lahore, delivered across Pakistan";

  const headlineSize = headline.length > 70 ? 54 : headline.length > 40 ? 64 : 76;

  return new ImageResponse(
    (
      <div
        style={{
          display: "flex",
          width: "100%",
          height: "100%",
          background: "#F7F7F7",
          position: "relative",
        }}
      >
        <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 16, background: "#A9832E", display: "flex" }} />
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
            width: "100%",
            padding: "56px 72px 56px 88px",
          }}
        >
          <div style={{ display: "flex", alignItems: "center" }}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={`${origin}/logo.png`} width={92} height={92} alt="" style={{ marginRight: 24 }} />
            <div style={{ display: "flex", fontSize: 38, color: "#2A2825", fontWeight: 700 }}>Shahid Iqbal &amp; Co</div>
          </div>

          <div style={{ display: "flex", flexDirection: "column" }}>
            <div style={{ display: "flex", fontSize: headlineSize, lineHeight: 1.1, color: "#1C1B19", fontWeight: 700, maxWidth: 1000 }}>
              {headline}
            </div>
            <div style={{ display: "flex", fontSize: 32, color: "#A9832E", marginTop: 26, fontWeight: 700 }}>{sub}</div>
          </div>

          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 26, color: "#57534C" }}>
            <div style={{ display: "flex" }}>www.siqbalhwc.com</div>
            <div style={{ display: "flex" }}>WhatsApp +92 311 7798157</div>
          </div>
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
      headers: {
        "Cache-Control": "public, max-age=86400, s-maxage=604800, stale-while-revalidate=86400",
      },
    }
  );
}
