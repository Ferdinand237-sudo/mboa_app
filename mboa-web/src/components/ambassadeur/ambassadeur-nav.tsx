"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const TABS = [
  { href: "/ambassadeur", label: "Dashboard", icon: "📊" },
  { href: "/ambassadeur/assignes", label: "Assignés", icon: "📋" },
];

// Miroir de la nav Ambassadeur de main_screen.dart (Dashboard / Assignés).
export function AmbassadeurNav() {
  const pathname = usePathname();
  return (
    <nav className="sticky top-16 z-40 border-b border-mboa-border bg-white">
      <div className="mx-auto flex max-w-3xl gap-1 px-4">
        {TABS.map((t) => {
          const isActive = pathname === t.href;
          return (
            <Link
              key={t.href}
              href={t.href}
              className={`flex items-center gap-1.5 border-b-[3px] px-3.5 py-3 text-[13px] font-bold ${
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
