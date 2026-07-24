"use client";

import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import type { UserModel } from "@/lib/types/models";
import { initiales } from "@/lib/utils/format";

// Miroir de _navItemsVisiteur (main_screen.dart) : Home | Logement | Market
// | Chat | Profil. Home et Profil sont déjà dans le header (logo + menu
// compte), donc seuls Logement/Market/Chat restent dans NAV_LINKS.
const NAV_LINKS_VISITEUR = [
  { href: "/logements", label: "Logement" },
  { href: "/marketplace", label: "Market" },
  { href: "/chat", label: "Chat" },
];

// Miroir de _navItemsVendeur (main_screen.dart) : Home | Gestion | Publier
// | Messages | Profil.
const NAV_LINKS_VENDEUR = [
  { href: "/vendeur/annonces", label: "Mes annonces" },
  { href: "/vendeur/publier", label: "Publier" },
  { href: "/chat", label: "Messages" },
];

// Miroir de la bottom nav de AdminScreen (admin_screen.dart). Intégrés
// directement au header (au lieu d'une barre horizontale séparée en
// dessous) pour réutiliser le même mécanisme que les autres rôles : pastilles
// en ligne sur desktop, menu hamburger à déplier sur mobile.
const NAV_LINKS_ADMIN = [
  { href: "/admin", label: "Dashboard" },
  { href: "/admin/utilisateurs", label: "Utilisateurs" },
  { href: "/admin/annonces", label: "Annonces" },
  { href: "/admin/signalements", label: "Signalements" },
  { href: "/admin/demandes", label: "Demandes" },
  { href: "/admin/verifications", label: "Vérifs" },
];

// Miroir de _navItemsAmbassadeur (main_screen.dart) : Dashboard / Assignés.
const NAV_LINKS_AMBASSADEUR = [
  { href: "/ambassadeur", label: "Dashboard" },
  { href: "/ambassadeur/assignes", label: "Assignés" },
];

// Un lien est actif sur sa propre page ainsi que sur ses sous-pages
// (ex. Chat reste actif sur /chat/[id]), sauf "/" traité à part pour ne
// pas allumer tous les onglets en même temps.
function estActif(pathname: string, href: string): boolean {
  return href === "/" ? pathname === "/" : pathname === href || pathname.startsWith(`${href}/`);
}

export function HeaderClient({ user }: { user: UserModel | null }) {
  const [open, setOpen] = useState(false);
  const router = useRouter();
  const pathname = usePathname();

  async function handleLogout() {
    const supabase = createClient();
    await supabase.auth.signOut();
    setOpen(false);
    router.push("/");
    router.refresh();
  }

  // Miroir de _navItemsVendeur (main_screen.dart) : Gestion + Publier
  // remplacent Logement + Market une fois connecté comme vendeur.
  const NAV_LINKS =
    user?.role === "vendeur"
      ? NAV_LINKS_VENDEUR
      : user?.role === "admin"
        ? NAV_LINKS_ADMIN
        : user?.role === "ambassadeur"
          ? NAV_LINKS_AMBASSADEUR
          : NAV_LINKS_VISITEUR;

  // Admin (6 onglets) et ambassadeur passent uniquement par le menu à
  // déplier plutôt que des pastilles en ligne dans le header, même sur
  // desktop : plus simple qu'une barre horizontale chargée.
  const menuSeulement = user?.role === "admin" || user?.role === "ambassadeur";

  return (
    <header className="sticky top-0 z-50 border-b border-mboa-border bg-mboa-card/95 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6">
        <Link href="/" className="flex items-center gap-2 shrink-0">
          <Image src="/logo-mboa.png" alt="Mboa" width={36} height={36} className="h-9 w-9 rounded-lg object-contain" priority />
          <span className="text-lg font-extrabold tracking-tight text-mboa-text">
            Mboa
          </span>
        </Link>

        {!menuSeulement && (
          <nav className="hidden items-center gap-1 md:flex">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`rounded-mboa-md px-4 py-2 text-sm font-semibold transition-colors ${
                  estActif(pathname, link.href)
                    ? "bg-mboa-primary-light/8 text-mboa-primary"
                    : "text-mboa-text-muted hover:bg-mboa-background hover:text-mboa-primary"
                }`}
              >
                {link.label}
              </Link>
            ))}
          </nav>
        )}

        <div className="hidden items-center gap-3 md:flex">
          {user ? (
            <>
              <Link
                href="/profil"
                className={`flex items-center gap-2 rounded-mboa-full py-1 pl-1 pr-3 text-sm font-semibold transition-colors ${
                  estActif(pathname, "/profil")
                    ? "bg-mboa-primary-light/8 text-mboa-primary"
                    : "text-mboa-text hover:bg-mboa-background"
                }`}
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-mboa-primary text-xs font-bold text-white">
                  {initiales(user.nom)}
                </span>
                {user.nom.split(" ")[0]}
              </Link>
              <button
                onClick={handleLogout}
                className="rounded-mboa-lg px-4 py-2 text-sm font-semibold text-mboa-text-muted transition-colors hover:text-mboa-danger"
              >
                Déconnexion
              </button>
            </>
          ) : (
            <>
              <Link
                href="/login"
                className="rounded-mboa-lg px-4 py-2 text-sm font-semibold text-mboa-text transition-colors hover:bg-mboa-background"
              >
                Connexion
              </Link>
              <Link
                href="/register"
                className="rounded-mboa-lg bg-mboa-primary px-5 py-2.5 text-sm font-bold text-white transition-colors hover:bg-mboa-primary-dark"
              >
                S&apos;inscrire
              </Link>
            </>
          )}
        </div>

        <button
          className={`flex h-10 w-10 items-center justify-center rounded-mboa-md text-mboa-text ${menuSeulement ? "" : "md:hidden"}`}
          onClick={() => setOpen((v) => !v)}
          aria-label="Menu"
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            {open ? (
              <path d="M6 6l12 12M18 6L6 18" strokeLinecap="round" />
            ) : (
              <path d="M4 7h16M4 12h16M4 17h16" strokeLinecap="round" />
            )}
          </svg>
        </button>
      </div>

      {open && (
        <div className={`border-t border-mboa-border bg-mboa-card px-4 py-3 ${menuSeulement ? "" : "md:hidden"}`}>
          <nav className="flex flex-col gap-1">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setOpen(false)}
                className={`rounded-mboa-md px-3 py-2.5 text-sm font-semibold ${
                  estActif(pathname, link.href)
                    ? "bg-mboa-primary-light/8 text-mboa-primary"
                    : "text-mboa-text hover:bg-mboa-background"
                }`}
              >
                {link.label}
              </Link>
            ))}
            {/* Le menu du hamburger reste ouvert en permanence pour
                admin/ambassadeur (menuSeulement) : profil/déconnexion sont
                déjà visibles inline juste à côté sur desktop, inutile de les
                dupliquer ici hors du vrai contexte mobile. */}
            <div className={`my-2 h-px bg-mboa-border ${menuSeulement ? "md:hidden" : ""}`} />
            <div className={menuSeulement ? "flex flex-col gap-1 md:hidden" : "contents"}>
              {user ? (
                <>
                  <Link
                    href="/profil"
                    onClick={() => setOpen(false)}
                    className={`rounded-mboa-md px-3 py-2.5 text-sm font-semibold ${
                      estActif(pathname, "/profil")
                        ? "bg-mboa-primary-light/8 text-mboa-primary"
                        : "text-mboa-text hover:bg-mboa-background"
                    }`}
                  >
                    Mon profil
                  </Link>
                  <button
                    onClick={handleLogout}
                    className="rounded-mboa-md px-3 py-2.5 text-left text-sm font-semibold text-mboa-danger hover:bg-mboa-background"
                  >
                    Déconnexion
                  </button>
                </>
              ) : (
                <>
                  <Link
                    href="/login"
                    onClick={() => setOpen(false)}
                    className="rounded-mboa-md px-3 py-2.5 text-sm font-semibold text-mboa-text hover:bg-mboa-background"
                  >
                    Connexion
                  </Link>
                  <Link
                    href="/register"
                    onClick={() => setOpen(false)}
                    className="rounded-mboa-lg bg-mboa-primary px-3 py-2.5 text-center text-sm font-bold text-white"
                  >
                    S&apos;inscrire
                  </Link>
                </>
              )}
            </div>
          </nav>
        </div>
      )}
    </header>
  );
}
