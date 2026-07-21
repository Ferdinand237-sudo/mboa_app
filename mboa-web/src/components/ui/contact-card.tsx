import Link from "next/link";
import { Rating } from "@/components/ui/rating";
import { initiales } from "@/lib/utils/format";

export function ContactCard({
  nom,
  verified,
  note,
  nbAvis,
  isLoggedIn,
}: {
  nom: string;
  verified: boolean;
  note: number;
  nbAvis?: number;
  isLoggedIn: boolean;
}) {
  return (
    <div className="rounded-mboa-xl border border-mboa-border bg-mboa-card p-5">
      <div className="flex items-center gap-3">
        <span className="flex h-12 w-12 items-center justify-center rounded-full bg-mboa-primary text-sm font-bold text-white">
          {initiales(nom)}
        </span>
        <div>
          <div className="flex items-center gap-1.5 text-sm font-bold text-mboa-text">
            {nom}
            {verified && <span title="Vérifié">✓</span>}
          </div>
          <Rating note={note} nbAvis={nbAvis} />
        </div>
      </div>

      {isLoggedIn ? (
        <p className="mt-4 rounded-mboa-md bg-mboa-background px-3 py-2.5 text-xs text-mboa-text-muted">
          La messagerie est disponible sur l&apos;app mobile Mboa pour le
          moment — le chat web arrive bientôt.
        </p>
      ) : (
        <Link
          href="/login"
          className="mt-4 block w-full rounded-mboa-lg bg-mboa-primary py-3 text-center text-sm font-bold text-white"
        >
          Se connecter pour contacter
        </Link>
      )}
    </div>
  );
}
