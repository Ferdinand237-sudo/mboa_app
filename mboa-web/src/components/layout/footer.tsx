import Image from "next/image";
import Link from "next/link";

const EXPLORER_LINKS = [
  { href: "/logements", label: "Logements" },
  { href: "/marketplace", label: "Marketplace" },
  { href: "/carte", label: "Carte" },
  { href: "/contributeurs", label: "Contributeurs" },
];

const COMPTE_LINKS = [
  { href: "/login", label: "Connexion" },
  { href: "/register/etudiant", label: "Inscription étudiant" },
  { href: "/register/vendeur", label: "Devenir vendeur" },
];

export function Footer() {
  return (
    <footer className="border-t border-mboa-border bg-mboa-primary-light/8">
      <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6">
        <div className="grid gap-10 text-center sm:grid-cols-3 sm:text-left">
          <div className="flex flex-col items-center sm:items-start">
            <Link href="/" className="flex items-center gap-2.5">
              <Image src="/logo-mboa.png" alt="Mboa" width={40} height={40} className="h-10 w-10 rounded-lg object-contain" />
              <span className="text-xl font-extrabold tracking-tight text-mboa-text">Mboa</span>
            </Link>
            <p className="mt-3 max-w-xs text-sm leading-relaxed text-mboa-text-muted">
              Ton premier ami dans une nouvelle ville. Trouve un logement et
              tout ce dont tu as besoin à Sangmelima, avant même d&apos;arriver.
            </p>
          </div>

          <div className="flex flex-col items-center sm:items-start">
            <div className="text-sm font-bold uppercase tracking-wide text-mboa-text">Explorer</div>
            <ul className="mt-4 space-y-2.5 text-sm text-mboa-text-muted">
              {EXPLORER_LINKS.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="transition-colors hover:text-mboa-primary">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div className="flex flex-col items-center sm:items-start">
            <div className="text-sm font-bold uppercase tracking-wide text-mboa-text">Compte</div>
            <ul className="mt-4 space-y-2.5 text-sm text-mboa-text-muted">
              {COMPTE_LINKS.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="transition-colors hover:text-mboa-primary">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="mt-10 flex flex-col items-center gap-2 border-t border-mboa-border pt-6 text-center text-xs text-mboa-text-muted">
          <p>© {new Date().getFullYear()} Mboa — Sangmelima, Cameroun.</p>
          <p>Fait avec ❤️ pour les étudiants de Sangmelima.</p>
        </div>
      </div>
    </footer>
  );
}
