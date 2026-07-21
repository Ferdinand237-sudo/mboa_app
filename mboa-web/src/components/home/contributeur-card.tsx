import Link from "next/link";
import type { Contributeur } from "@/lib/data/home";
import { initiales } from "@/lib/utils/format";

export function ContributeurCard({ contributeur }: { contributeur: Contributeur }) {
  return (
    <Link
      href={`/vendeur/${contributeur.id}`}
      className="flex w-[90px] shrink-0 flex-col items-center gap-1.5 rounded-mboa-md bg-mboa-card p-2.5 text-center shadow-sm"
    >
      <span className="relative flex h-11 w-11 items-center justify-center rounded-full bg-mboa-primary text-sm font-extrabold text-white">
        {initiales(contributeur.nom)}
        {contributeur.verified && (
          <span className="absolute -bottom-0.5 -right-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-mboa-verified text-[8px] text-white ring-2 ring-white">
            ✓
          </span>
        )}
      </span>
      <p className="line-clamp-1 text-[10px] font-bold text-mboa-text">
        {contributeur.nom}
      </p>
      <p className="text-[9px] text-mboa-text-muted">
        ⭐ {contributeur.noteGlobale.toFixed(1)}
      </p>
    </Link>
  );
}
