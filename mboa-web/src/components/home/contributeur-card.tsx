import Link from "next/link";
import type { Contributeur } from "@/lib/data/home";
import { VerifiedBadge } from "@/components/ui/verified-badge";
import { initiales } from "@/lib/utils/format";

// Carte de grille (pas de largeur fixe) : occupe toute sa cellule, comme
// HomeLogementCard/HomeArticleCard juste au-dessus sur la page d'accueil,
// au lieu d'un carrousel horizontal à cartes de taille fixe.
export function ContributeurCard({ contributeur }: { contributeur: Contributeur }) {
  return (
    <Link
      href={`/vendeur/${contributeur.id}`}
      className="flex flex-col items-center gap-1.5 rounded-mboa-md bg-mboa-card p-3 text-center shadow-sm transition-shadow hover:shadow-md"
    >
      <span className="relative flex h-12 w-12 items-center justify-center rounded-full bg-mboa-primary text-sm font-extrabold text-white">
        {initiales(contributeur.nom)}
        {contributeur.verified && (
          <VerifiedBadge className="absolute -bottom-0.5 -right-0.5 h-4 w-4 rounded-full bg-white" />
        )}
      </span>
      <p className="line-clamp-1 w-full text-[11px] font-bold text-mboa-text">
        {contributeur.nom}
      </p>
      <p className="text-[10px] text-mboa-text-muted">
        ⭐ {contributeur.noteGlobale.toFixed(1)}
      </p>
    </Link>
  );
}
