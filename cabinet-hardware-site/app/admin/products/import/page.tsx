"use client";

import { useState } from "react";
import Link from "next/link";
import * as XLSX from "xlsx";
import { supabase } from "@/lib/supabase";

const HEADERS = [
  "Product Name",
  "Category",
  "Description",
  "Base Price",
  "Material",
  "Weight",
  "Weight Unit",
  "Finish",
  "Size",
  "Variant Price",
  "Stock Qty",
  "SKU",
] as const;

type RawRow = Record<(typeof HEADERS)[number], string>;

type ParsedVariant = {
  rowNumber: number;
  finish: string;
  size: string;
  price: number | null;
  stock: number;
  sku: string;
  error: string | null;
};

type ParsedProduct = {
  name: string;
  category: string;
  description: string;
  basePrice: number | null;
  material: string;
  weight: string;
  weightUnit: string;
  variants: ParsedVariant[];
  errors: string[]; // product-level errors (blocks import entirely)
};

function slugify(text: string) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
}

function cell(row: any, key: string): string {
  const v = row[key];
  if (v === undefined || v === null) return "";
  return String(v).trim();
}

function downloadTemplate() {
  const exampleRows = [
    {
      "Product Name": "Classic Bar Handle",
      Category: "Cabinet Handles",
      Description: "Solid brass bar handle with a brushed finish.",
      "Base Price": 250,
      Material: "Brass",
      Weight: 85,
      "Weight Unit": "g",
      Finish: "Golden",
      Size: "128mm",
      "Variant Price": 250,
      "Stock Qty": 40,
      SKU: "CBH-128-GLD",
    },
    {
      "Product Name": "Classic Bar Handle",
      Category: "Cabinet Handles",
      Description: "",
      "Base Price": "",
      Material: "",
      Weight: "",
      "Weight Unit": "",
      Finish: "Matte Black",
      Size: "128mm",
      "Variant Price": 260,
      "Stock Qty": 25,
      SKU: "CBH-128-MBK",
    },
    {
      "Product Name": "Classic Bar Handle",
      Category: "Cabinet Handles",
      Description: "",
      "Base Price": "",
      Material: "",
      Weight: "",
      "Weight Unit": "",
      Finish: "Golden",
      Size: "192mm",
      "Variant Price": 310,
      "Stock Qty": 15,
      SKU: "CBH-192-GLD",
    },
    {
      "Product Name": "Round Cabinet Knob",
      Category: "Cabinet Knobs",
      Description: "Simple round knob, sold individually.",
      "Base Price": 120,
      Material: "Zinc Alloy",
      Weight: 30,
      "Weight Unit": "g",
      Finish: "Chrome",
      Size: "",
      "Variant Price": 120,
      "Stock Qty": 60,
      SKU: "",
    },
  ];

  const instructions = [
    ["How to use this template"],
    [""],
    ["1. One row = one buyable variant (a specific Finish + Size combination)."],
    ["2. To add a product with multiple Finishes/Sizes, repeat the Product Name on multiple rows — one row per variant — like the 'Classic Bar Handle' example below."],
    ["3. Only fill in Description, Base Price, Material, Weight and Weight Unit on the FIRST row for a product — leave them blank on the other variant rows for that same product."],
    ["4. Required on every row: Product Name, Category, Variant Price."],
    ["5. Leave Finish and/or Size blank if the product doesn't come in different finishes or sizes."],
    ["6. Base Price is what's shown on the catalog page (e.g. \"From Rs. 250\"). If left blank, it's set automatically to the lowest Variant Price for that product."],
    ["7. Stock Qty left blank is treated as 0 (out of stock) — the product will still import, just show as sold out until you update the stock."],
    ["8. This import does NOT add photos — add those afterwards from each product's edit page in /admin/products."],
    ["9. Category is created automatically if it doesn't already exist yet — spelling must match exactly to reuse an existing one (check /admin/categories)."],
    [""],
    ["Suggested values already used on this site (not required, just for consistency):"],
    ["Finish: Golden, Matte Black, Chrome, Antique Brass, Silver"],
    ["Size: 96mm, 128mm, 160mm, 192mm"],
    ["Material: Zinc Alloy, Brass, Aluminum, Iron, Stainless Steel"],
    ["Weight Unit: g, kg"],
  ];

  const wb = XLSX.utils.book_new();
  const wsProducts = XLSX.utils.json_to_sheet(exampleRows, { header: HEADERS as unknown as string[] });
  wsProducts["!cols"] = HEADERS.map((h) => ({ wch: Math.max(14, h.length + 2) }));
  XLSX.utils.book_append_sheet(wb, wsProducts, "Products");

  const wsInstructions = XLSX.utils.aoa_to_sheet(instructions);
  wsInstructions["!cols"] = [{ wch: 100 }];
  XLSX.utils.book_append_sheet(wb, wsInstructions, "Instructions");

  XLSX.writeFile(wb, "product-import-template.xlsx");
}

export default function ImportProductsPage() {
  const [fileName, setFileName] = useState<string | null>(null);
  const [products, setProducts] = useState<ParsedProduct[]>([]);
  const [parseError, setParseError] = useState<string | null>(null);
  const [importing, setImporting] = useState(false);
  const [progress, setProgress] = useState<{ done: number; total: number } | null>(null);
  const [results, setResults] = useState<{ imported: string[]; failed: { name: string; message: string }[] } | null>(null);

  function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;

    setResults(null);
    setParseError(null);
    setFileName(file.name);

    const reader = new FileReader();
    reader.onload = (evt) => {
      try {
        const data = evt.target?.result;
        const wb = XLSX.read(data, { type: "array" });
        const sheetName = wb.SheetNames.includes("Products") ? "Products" : wb.SheetNames[0];
        const ws = wb.Sheets[sheetName];
        const rows: any[] = XLSX.utils.sheet_to_json(ws, { defval: "" });

        if (rows.length === 0) {
          setParseError("That file doesn't have any product rows in it.");
          setProducts([]);
          return;
        }

        const groups = new Map<string, ParsedProduct>();

        rows.forEach((raw, i) => {
          const rowNumber = i + 2; // account for header row, 1-indexed for humans
          const name = cell(raw, "Product Name");
          if (!name) return; // silently skip fully blank rows

          const key = name.toLowerCase();
          if (!groups.has(key)) {
            groups.set(key, {
              name,
              category: "",
              description: "",
              basePrice: null,
              material: "",
              weight: "",
              weightUnit: "g",
              variants: [],
              errors: [],
            });
          }
          const product = groups.get(key)!;

          const category = cell(raw, "Category");
          if (category && !product.category) product.category = category;
          const description = cell(raw, "Description");
          if (description && !product.description) product.description = description;
          const material = cell(raw, "Material");
          if (material && !product.material) product.material = material;
          const weight = cell(raw, "Weight");
          if (weight && !product.weight) product.weight = weight;
          const weightUnit = cell(raw, "Weight Unit");
          if (weightUnit && product.weightUnit === "g") product.weightUnit = weightUnit;
          const basePriceStr = cell(raw, "Base Price");
          if (basePriceStr && product.basePrice === null) {
            const n = Number(basePriceStr);
            if (!Number.isNaN(n)) product.basePrice = n;
          }

          const priceStr = cell(raw, "Variant Price");
          const priceNum = Number(priceStr);
          const stockStr = cell(raw, "Stock Qty");
          const stockNum = stockStr ? Number(stockStr) : 0;

          let error: string | null = null;
          if (!priceStr || Number.isNaN(priceNum) || priceNum <= 0) {
            error = "Variant Price is missing or not a valid number";
          } else if (stockStr && Number.isNaN(stockNum)) {
            error = "Stock Qty is not a valid number";
          }

          product.variants.push({
            rowNumber,
            finish: cell(raw, "Finish"),
            size: cell(raw, "Size"),
            price: error ? null : priceNum,
            stock: Number.isNaN(stockNum) ? 0 : stockNum,
            sku: cell(raw, "SKU"),
            error,
          });
        });

        const parsed = Array.from(groups.values()).map((p) => {
          const errors: string[] = [];
          if (!p.category) errors.push("Missing Category");
          if (p.variants.every((v) => v.error)) errors.push("Every variant row has an invalid Variant Price");
          return { ...p, errors };
        });

        setProducts(parsed);
        if (parsed.length === 0) {
          setParseError("Found rows, but none had a Product Name filled in.");
        }
      } catch (err: any) {
        setParseError("Couldn't read that file — make sure it's the .xlsx template, unedited in structure.");
        setProducts([]);
      }
    };
    reader.readAsArrayBuffer(file);
  }

  async function uniqueSlug(base: string): Promise<string> {
    let slug = base;
    let suffix = 2;
    // Rare in practice (two products slugifying to the same thing, or
    // re-importing a file that was already imported) — this just avoids
    // a confusing unique-constraint error in that case.
    while (true) {
      const { data } = await supabase.from("products").select("id").eq("slug", slug).maybeSingle();
      if (!data) return slug;
      slug = `${base}-${suffix}`;
      suffix += 1;
    }
  }

  async function findOrCreateCategory(name: string): Promise<string> {
    const { data: existing } = await supabase
      .from("categories")
      .select("id")
      .ilike("name", name)
      .maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase
      .from("categories")
      .insert({ name, slug: slugify(name) })
      .select()
      .single();
    if (error) throw error;
    return created.id;
  }

  async function findOrCreateAttribute(attrName: string) {
    const { data: existing } = await supabase.from("attributes").select("id").eq("name", attrName).maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase.from("attributes").insert({ name: attrName }).select().single();
    if (error) throw error;
    return created.id;
  }

  async function findOrCreateAttributeValue(attributeId: string, value: string) {
    const { data: existing } = await supabase
      .from("attribute_values")
      .select("id")
      .eq("attribute_id", attributeId)
      .eq("value", value)
      .maybeSingle();
    if (existing) return existing.id;
    const { data: created, error } = await supabase
      .from("attribute_values")
      .insert({ attribute_id: attributeId, value })
      .select()
      .single();
    if (error) throw error;
    return created.id;
  }

  async function handleImport() {
    const importable = products.filter((p) => p.errors.length === 0);
    if (importable.length === 0) return;

    setImporting(true);
    setProgress({ done: 0, total: importable.length });
    const imported: string[] = [];
    const failed: { name: string; message: string }[] = [];

    for (const p of importable) {
      try {
        const categoryId = await findOrCreateCategory(p.category);

        const validVariants = p.variants.filter((v) => !v.error && v.price !== null);
        const basePrice = p.basePrice ?? Math.min(...validVariants.map((v) => v.price!));

        const specs: Record<string, string> = {};
        if (p.material) specs["Material"] = p.material;
        if (p.weight) specs["Weight"] = `${p.weight}${p.weightUnit || "g"}`;

        const { data: product, error: productError } = await supabase
          .from("products")
          .insert({
            name: p.name,
            slug: await uniqueSlug(slugify(p.name)),
            description: p.description || null,
            category_id: categoryId,
            base_price: basePrice,
            specs,
          })
          .select()
          .single();
        if (productError) throw productError;

        const usesFinish = validVariants.some((v) => v.finish);
        const usesSize = validVariants.some((v) => v.size);
        const finishAttrId = usesFinish ? await findOrCreateAttribute("Finish") : null;
        const sizeAttrId = usesSize ? await findOrCreateAttribute("Size") : null;

        for (const v of validVariants) {
          const { data: variant, error: variantError } = await supabase
            .from("product_variants")
            .insert({
              product_id: product.id,
              sku: v.sku || null,
              price: v.price,
              stock_qty: v.stock || 0,
            })
            .select()
            .single();
          if (variantError) throw variantError;

          const links: { variant_id: string; attribute_value_id: string }[] = [];
          if (finishAttrId && v.finish) {
            const valueId = await findOrCreateAttributeValue(finishAttrId, v.finish);
            links.push({ variant_id: variant.id, attribute_value_id: valueId });
          }
          if (sizeAttrId && v.size) {
            const valueId = await findOrCreateAttributeValue(sizeAttrId, v.size);
            links.push({ variant_id: variant.id, attribute_value_id: valueId });
          }
          if (links.length > 0) {
            const { error: linkError } = await supabase.from("variant_attribute_values").insert(links);
            if (linkError) throw linkError;
          }
        }

        imported.push(p.name);
      } catch (err: any) {
        failed.push({ name: p.name, message: err.message || "Unknown error" });
      }
      setProgress((prev) => (prev ? { ...prev, done: prev.done + 1 } : prev));
    }

    setImporting(false);
    setResults({ imported, failed });
    setProducts([]);
    setFileName(null);
  }

  const importableCount = products.filter((p) => p.errors.length === 0).length;
  const blockedCount = products.length - importableCount;

  return (
    <div className="max-w-3xl">
      <div className="flex items-center justify-between">
        <h1 className="font-display text-3xl text-ink">Import products from Excel</h1>
        <Link href="/admin/products" className="font-body text-sm text-graphite hover:text-ink">
          ← Back to products
        </Link>
      </div>
      <p className="mt-2 font-body text-sm text-graphite">
        Add many products at once by filling in a spreadsheet, instead of one-by-one. Photos
        aren't part of this — add those afterwards from each product's edit page.
      </p>

      {/* Step 1 */}
      <div className="mt-8 border border-nickel/25 p-5">
        <p className="font-body text-sm text-ink">Step 1 — get the template</p>
        <p className="mt-1 font-body text-xs text-graphite">
          Includes example rows and an Instructions tab explaining every column.
        </p>
        <button
          type="button"
          onClick={downloadTemplate}
          className="mt-3 border border-ink px-4 py-2 font-body text-sm text-ink hover:bg-ink hover:text-stone"
        >
          Download template (.xlsx)
        </button>
      </div>

      {/* Step 2 */}
      <div className="mt-6 border border-nickel/25 p-5">
        <p className="font-body text-sm text-ink">Step 2 — upload your filled-in file</p>
        <label className="mt-3 inline-block cursor-pointer border border-dashed border-nickel/50 px-4 py-2 font-body text-sm text-graphite hover:border-ink hover:text-ink">
          {fileName ? `Selected: ${fileName}` : "Choose .xlsx file…"}
          <input type="file" accept=".xlsx,.xls" onChange={handleFile} className="hidden" />
        </label>
        {parseError && <p className="mt-3 font-body text-sm text-rust">{parseError}</p>}
      </div>

      {/* Step 3 — preview */}
      {products.length > 0 && (
        <div className="mt-6 border border-nickel/25 p-5">
          <p className="font-body text-sm text-ink">Step 3 — check before importing</p>
          <p className="mt-1 font-body text-xs text-graphite">
            {importableCount} product{importableCount === 1 ? "" : "s"} ready to import
            {blockedCount > 0 && `, ${blockedCount} with problems (won't be imported until fixed)`}.
          </p>

          <div className="mt-4 divide-y divide-nickel/15 border-y border-nickel/15">
            {products.map((p, i) => (
              <div key={i} className="py-3 font-body text-sm">
                <div className="flex items-center justify-between gap-4">
                  <p className={p.errors.length > 0 ? "text-rust" : "text-ink"}>{p.name}</p>
                  <p className="text-xs text-graphite">
                    {p.category || "(no category)"} · {p.variants.length} variant
                    {p.variants.length === 1 ? "" : "s"}
                  </p>
                </div>
                {p.errors.length > 0 && (
                  <ul className="mt-1 list-disc pl-5 text-xs text-rust">
                    {p.errors.map((e, j) => (
                      <li key={j}>{e}</li>
                    ))}
                  </ul>
                )}
                {p.variants.some((v) => v.error) && (
                  <ul className="mt-1 list-disc pl-5 text-xs text-rust">
                    {p.variants
                      .filter((v) => v.error)
                      .map((v, j) => (
                        <li key={j}>
                          Row {v.rowNumber}: {v.error}
                        </li>
                      ))}
                  </ul>
                )}
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={handleImport}
            disabled={importing || importableCount === 0}
            className="mt-5 bg-ink px-5 py-2.5 font-body text-sm text-stone hover:bg-brass disabled:opacity-50"
          >
            {importing
              ? `Importing ${progress?.done ?? 0} of ${progress?.total ?? 0}…`
              : `Import ${importableCount} product${importableCount === 1 ? "" : "s"}`}
          </button>
        </div>
      )}

      {/* Results */}
      {results && (
        <div className="mt-6 border border-nickel/25 p-5">
          <p className="font-body text-sm text-ink">Done</p>
          {results.imported.length > 0 && (
            <p className="mt-2 font-body text-sm text-olive">
              Imported {results.imported.length}: {results.imported.join(", ")}
            </p>
          )}
          {results.failed.length > 0 && (
            <div className="mt-2">
              <p className="font-body text-sm text-rust">{results.failed.length} failed:</p>
              <ul className="mt-1 list-disc pl-5 font-body text-xs text-rust">
                {results.failed.map((f, i) => (
                  <li key={i}>
                    {f.name} — {f.message}
                  </li>
                ))}
              </ul>
            </div>
          )}
          <div className="mt-4 flex gap-4">
            <Link href="/admin/products" className="font-body text-sm text-ink underline hover:text-brass">
              View products
            </Link>
            <button
              type="button"
              onClick={() => setResults(null)}
              className="font-body text-sm text-graphite hover:text-ink"
            >
              Import another file
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
