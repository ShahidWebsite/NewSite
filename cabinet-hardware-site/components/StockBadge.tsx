export default function StockBadge({ stockQty }: { stockQty: number }) {
  if (stockQty <= 0) {
    return <span className="font-body text-sm text-rust">Out of stock</span>;
  }
  if (stockQty <= 5) {
    return <span className="font-body text-sm text-rust">Only {stockQty} left</span>;
  }
  return <span className="font-body text-sm text-olive">In stock</span>;
}
