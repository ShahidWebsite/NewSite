// Re-mounts on every page change, giving a short fade-and-rise between pages.
// Server component: adds no JavaScript to the page.
export default function Template({ children }: { children: React.ReactNode }) {
  return <div className="page-in">{children}</div>;
}
