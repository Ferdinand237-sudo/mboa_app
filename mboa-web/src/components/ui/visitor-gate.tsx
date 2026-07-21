import Link from "next/link";

// Bannière affichée sous les 4 premières annonces pour un visiteur non
// connecté — même règle que pageSizeVisiteur côté Flutter (PRIORITÉ 5).
export function VisitorGate() {
  return (
    <div className="col-span-full flex flex-col items-center gap-3 rounded-mboa-xl border border-mboa-border bg-mboa-card p-8 text-center">
      <span className="text-3xl" aria-hidden>
        🔒
      </span>
      <p className="max-w-sm text-sm text-mboa-text-muted">
        Connecte-toi pour voir toutes les annonces disponibles à Sangmelima et
        contacter directement les propriétaires et vendeurs.
      </p>
      <div className="flex gap-3">
        <Link
          href="/login"
          className="rounded-mboa-lg border border-mboa-primary px-5 py-2.5 text-sm font-bold text-mboa-primary"
        >
          Connexion
        </Link>
        <Link
          href="/register"
          className="rounded-mboa-lg bg-mboa-primary px-5 py-2.5 text-sm font-bold text-white"
        >
          Créer un compte
        </Link>
      </div>
    </div>
  );
}
