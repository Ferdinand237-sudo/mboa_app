"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const TABS = [
  { href: "/admin", label: "Dashboard", icon: "📊" },
  { href: "/admin/utilisateurs", label: "Utilisateurs", icon: "👥" },
  { href: "/admin/annonces", label: "Annonces", icon: "📋" },
  { href: "/admin/signalements", label: "Signalements", icon: "🚨" },
  { href: "/admin/demandes", label: "Demandes", icon: "📨" },
  { href: "/admin/verifications", label: "Vérifs", icon: "🧭" },
];

// Miroir de la bottom nav de AdminScreen (admin_screen.dart), transposée en
// barre d'onglets horizontale sous le header du site.
export function AdminNav() {
  const pathname = usePathname();
  return (
    <nav className="sticky top-16 z-40 border-b border-mboa-border bg-white">
      <div className="mx-auto flex max-w-6xl gap-1 overflow-x-auto px-4">
        {TABS.map((t) => {
          const isActive = pathname === t.href;
          return (
            <Link
              key={t.href}
              href={t.href}
              className={`flex shrink-0 items-center gap-1.5 border-b-[3px] px-3.5 py-3 text-[13px] font-bold ${
                isActive ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
              }`}
            >
              <span aria-hidden>{t.icon}</span>
              {t.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
