import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-mboa-border bg-mboa-card">
      <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        <div className="grid gap-8 sm:grid-cols-3">
          <div>
            <div className="text-lg font-extrabold text-mboa-text">Mboa</div>
            <p className="mt-2 text-sm leading-relaxed text-mboa-text-muted">
              Ton premier ami dans une nouvelle ville. Trouve un logement et
              tout ce dont tu as besoin à Sangmelima, avant même d&apos;arriver.
            </p>
          </div>
          <div>
            <div className="text-sm font-bold text-mboa-text">Explorer</div>
            <ul className="mt-3 space-y-2 text-sm text-mboa-text-muted">
              <li>
                <Link href="/logements" className="hover:text-mboa-primary">
                  Logements
                </Link>
              </li>
              <li>
                <Link href="/marketplace" className="hover:text-mboa-primary">
                  Marketplace
                </Link>
              </li>
            </ul>
          </div>
          <div>
            <div className="text-sm font-bold text-mboa-text">Compte</div>
            <ul className="mt-3 space-y-2 text-sm text-mboa-text-muted">
              <li>
                <Link href="/login" className="hover:text-mboa-primary">
                  Connexion
                </Link>
              </li>
              <li>
                <Link href="/register" className="hover:text-mboa-primary">
                  Inscription étudiant
                </Link>
              </li>
            </ul>
          </div>
        </div>
        <div className="mt-8 border-t border-mboa-border pt-6 text-xs text-mboa-text-muted">
          © {new Date().getFullYear()} Mboa — Sangmelima, Cameroun.
        </div>
      </div>
    </footer>
  );
}
