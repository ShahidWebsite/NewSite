// Adds the Shahid Iqbal & Co logo as a light watermark to a photo, in the
// browser, BEFORE it is uploaded. Every admin upload goes through this, so
// nothing reaches the store without the logo on it.

export const WATERMARK = {
  opacity: 0.28, // 0 = invisible, 1 = solid. 0.28 = light but visible
  sizeRatio: 0.16, // logo size as a share of the photo's shorter side
  marginRatio: 0.03, // gap from the bottom-right corner
  maxSide: 3000, // photos bigger than this are scaled down (still very sharp)
  jpegQuality: 0.92,
};

// Files made by the watermark tool are named "wm-...". This is how the
// "watermark old photos" page knows which pictures are already done.
export function isWatermarkedUrl(url: string): boolean {
  const last = decodeURIComponent(url.split("?")[0]).split("/").pop() ?? "";
  return last.includes("wm-");
}

let logoPromise: Promise<HTMLImageElement> | null = null;
function loadLogo(): Promise<HTMLImageElement> {
  if (!logoPromise) {
    logoPromise = new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => {
        logoPromise = null;
        reject(new Error("logo file /logo.png could not be loaded"));
      };
      img.src = "/logo.png";
    });
  }
  return logoPromise;
}

async function loadPhoto(file: File): Promise<ImageBitmap | HTMLImageElement> {
  if (typeof createImageBitmap === "function") {
    try {
      return await createImageBitmap(file, { imageOrientation: "from-image" });
    } catch {
      /* fall through to the <img> route */
    }
  }
  const url = URL.createObjectURL(file);
  try {
    return await new Promise<HTMLImageElement>((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error("this file is not a readable image"));
      img.src = url;
    });
  } finally {
    URL.revokeObjectURL(url);
  }
}

export async function watermarkImage(file: File): Promise<File> {
  if (!file.type.startsWith("image/")) return file;
  if (file.name.startsWith("wm-")) return file; // already done

  try {
    const [photo, logo] = await Promise.all([loadPhoto(file), loadLogo()]);
    const srcW = "naturalWidth" in photo ? photo.naturalWidth : photo.width;
    const srcH = "naturalHeight" in photo ? photo.naturalHeight : photo.height;

    const scale = Math.min(1, WATERMARK.maxSide / Math.max(srcW, srcH));
    const w = Math.round(srcW * scale);
    const h = Math.round(srcH * scale);

    const canvas = document.createElement("canvas");
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("browser could not create a drawing surface");
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = "high";

    const keepPng = file.type === "image/png";
    if (!keepPng) {
      ctx.fillStyle = "#ffffff"; // JPEG has no transparency
      ctx.fillRect(0, 0, w, h);
    }
    ctx.drawImage(photo as CanvasImageSource, 0, 0, w, h);

    const side = Math.max(48, Math.round(Math.min(w, h) * WATERMARK.sizeRatio));
    const logoH = Math.round(side * (logo.naturalHeight / logo.naturalWidth));
    const margin = Math.round(Math.min(w, h) * WATERMARK.marginRatio);
    ctx.globalAlpha = WATERMARK.opacity;
    ctx.drawImage(logo, w - side - margin, h - logoH - margin, side, logoH);
    ctx.globalAlpha = 1;

    const mime = keepPng ? "image/png" : "image/jpeg";
    const blob: Blob | null = await new Promise((resolve) =>
      canvas.toBlob(resolve, mime, WATERMARK.jpegQuality)
    );
    if (!blob) throw new Error("could not save the watermarked picture");

    const base = file.name.replace(/\.[^.]+$/, "");
    const ext = keepPng ? "png" : "jpg";
    return new File([blob], `wm-${base}.${ext}`, { type: mime });
  } catch (err: any) {
    throw new Error(
      `Could not add the logo watermark to "${file.name}" (${err?.message ?? "unknown problem"}). Nothing was uploaded.`
    );
  }
}