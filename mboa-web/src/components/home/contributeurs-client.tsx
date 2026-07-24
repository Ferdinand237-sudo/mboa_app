"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { SearchIcon } from "@/components/ui/icons";
import { Photo } from "@/components/ui/photo";
import { initiales } from "@/lib/utils/format";
import type { UserModel } from "@/lib/types/models";

// Miroir de contributeurs_screen.dart.
export function ContributeursClient({ contributeurs }: { contributeurs: UserModel[] }) {
  const [recherche, setRecherche] = useState("");

  const filtres = useMemo(() => {
    const q = recherche.trim().toLowerCase();
    if (!q) return contributeurs;
    return contributeurs.filter(
      (c) => c.nom.toLowerCase().includes(q) || (c.nomCommerce ?? "").toLowerCase().includes(q),
    );
  }, [contributeurs, recherche]);

  return (
    <div>
      <div className="rounded-b-[32px] bg-white px-5 pb-4 pt-1 shadow-sm">
        <div className="mx-auto flex h-[46px] max-w-2xl items-center gap-2 rounded-xl border border-mboa-border bg-mboa-background px-3">
          <SearchIcon className="h-5 w-5 shrink-0 text-mboa-text-muted" />
          <input
            value={recherche}
            onChange={(e) => setRecherche(e.target.value)}
            placeholder="Rechercher un vendeur, une boutique..."
            className="min-w-0 flex-1 bg-transparent text-sm text-mboa-text outline-none placeholder:text-mboa-text-muted"
          />
        </div>
      </div>

      <div className="mx-auto max-w-7xl px-5 py-5 pb-10">
        {filtres.length === 0 ? (
          <p className="py-16 text-center text-sm text-mboa-text-muted">Aucun contributeur trouvé</p>
        ) : (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
            {filtres.map((c) => (
              <Link
                key={c.id}
                href={`/vendeur/${c.id}`}
                className="flex flex-col items-center rounded-mboa-lg bg-mboa-card p-3.5 text-center shadow-sm"
              >
                <div className="relative h-14 w-14 shrink-0 overflow-hidden rounded-full bg-mboa-primary">
                  {c.photoUrl ? (
                    <Photo src={c.photoUrl} alt={c.nom} className="rounded-full" />
                  ) : (
                    <span className="flex h-full w-full items-center justify-center text-xl font-extrabold text-white">
                      {initiales(c.nom)}
                    </span>
                  )}
                  {c.verified && (
                    <span className="absolute bottom-0 right-0 flex h-[18px] w-[18px] items-center justify-center rounded-full bg-mboa-verified text-[9px] text-white ring-[1.5px] ring-white">
                      ✓
                    </span>
                  )}
                </div>
                <p className="mt-2 line-clamp-1 w-full text-xs font-bold text-mboa-text">{c.nom}</p>
                <p className="mt-0.5 line-clamp-1 w-full text-[11px] text-mboa-text-muted">
                  {c.nomCommerce ?? "Contributeur Mboa"}
                </p>
                <p className="mt-1.5 flex items-center justify-center gap-1 text-[11px] font-semibold text-mboa-text">
                  ⭐ {c.noteGlobale.toFixed(1)}
                  <span className="text-mboa-text-muted">({c.nbAvis})</span>
                </p>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
