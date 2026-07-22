import Link from "next/link";

const CATEGORIES = [
  { emoji: "🏠", label: "Logement", href: "/logements", bg: "bg-mboa-primary/10" },
  { emoji: "🛒", label: "Market", href: "/marketplace", bg: "bg-mboa-secondary/10" },
  { emoji: "🗺️", label: "Carte", href: "/carte", bg: "bg-mboa-accent/10" },
];

export function CategoryCards() {
  return (
    <div className="grid grid-cols-3 gap-3">
      {CATEGORIES.map((cat) => (
        <Link
          key={cat.label}
          href={cat.href}
          className="flex flex-col items-center gap-2 rounded-mboa-lg bg-mboa-card py-4 shadow-sm transition-shadow hover:shadow-md"
        >
          <span
            className={`flex h-12 w-12 items-center justify-center rounded-2xl text-2xl ${cat.bg}`}
          >
            {cat.emoji}
          </span>
          <span className="text-xs font-semibold text-mboa-text">
            {cat.label}
          </span>
        </Link>
      ))}
    </div>
  );
}
