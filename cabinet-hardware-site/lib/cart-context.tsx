"use client";

import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { CartLine } from "./types";

type CartContextValue = {
  lines: CartLine[];
  addLine: (line: CartLine) => void;
  updateQuantity: (variantId: string, quantity: number) => void;
  removeLine: (variantId: string) => void;
  clear: () => void;
  subtotal: number;
};

const CartContext = createContext<CartContextValue | null>(null);
const STORAGE_KEY = "cabinet-hardware-cart";

export function CartProvider({ children }: { children: ReactNode }) {
  const [lines, setLines] = useState<CartLine[]>([]);
  const [hydrated, setHydrated] = useState(false);

  // Load saved cart once on mount (client-only — localStorage isn't available during SSR)
  useEffect(() => {
    try {
      const saved = window.localStorage.getItem(STORAGE_KEY);
      if (saved) setLines(JSON.parse(saved));
    } catch {
      // corrupted or blocked storage — start with an empty cart rather than crash
    }
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(lines));
  }, [lines, hydrated]);

  function addLine(newLine: CartLine) {
    setLines((prev) => {
      const existing = prev.find((l) => l.variantId === newLine.variantId);
      if (existing) {
        return prev.map((l) =>
          l.variantId === newLine.variantId
            ? { ...l, quantity: l.quantity + newLine.quantity }
            : l
        );
      }
      return [...prev, newLine];
    });
  }

  function updateQuantity(variantId: string, quantity: number) {
    setLines((prev) =>
      quantity <= 0
        ? prev.filter((l) => l.variantId !== variantId)
        : prev.map((l) => (l.variantId === variantId ? { ...l, quantity } : l))
    );
  }

  function removeLine(variantId: string) {
    setLines((prev) => prev.filter((l) => l.variantId !== variantId));
  }

  function clear() {
    setLines([]);
  }

  const subtotal = lines.reduce((sum, l) => sum + l.unitPrice * l.quantity, 0);

  return (
    <CartContext.Provider value={{ lines, addLine, updateQuantity, removeLine, clear, subtotal }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used inside <CartProvider>");
  return ctx;
}
