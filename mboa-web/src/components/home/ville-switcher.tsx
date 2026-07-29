"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { setVille } from "@/app/ville-actions";
import { distanceMetres } from "@/lib/utils/geo";
import type { VilleModel } from "@/lib/data/villes";

// Miroir du sélecteur de ville de home_screen.dart : pill affichant la
// ville courante, dépliable vers la liste des villes couvertes. Détection
// GPS automatique une seule fois si aucun cookie n'existe encore (premier
// passage) — VilleService fait pareil côté mobile (SharedPreferences).
export function VilleSwitcher({
  villes,
  villeActuelle,
  cookiePresent,
}: {
  villes: VilleModel[];
  villeActuelle: VilleModel;
  cookiePresent: boolean;
}) {
  const [open, setOpen] = useState(false);
  const router = useRouter();
  const detectionLancee = useRef(false);

  useEffect(() => {
    if (cookiePresent || detectionLancee.current) return;
    if (!("geolocation" in navigator)) return;
    detectionLancee.current = true;

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        let plusProche: VilleModel | null = null;
        let distanceMin = Infinity;
        for (const v of villes) {
          const d = distanceMetres(latitude, longitude, v.lat, v.lng);
          if (d <= v.rayonCouvertureKm * 1000 && d < distanceMin) {
            distanceMin = d;
            plusProche = v;
          }
        }
        if (plusProche && plusProche.nom !== villeActuelle.nom) {
          setVille(plusProche.nom).then(() => router.refresh());
        }
      },
      () => {},
      { timeout: 8000 },
    );
    // Volontairement une seule exécution (ref) : ni villes ni villeActuelle
    // ne doivent la redéclencher (villeActuelle change justement en
    // réaction à cet effet).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cookiePresent]);

  async function choisir(nom: string) {
    setOpen(false);
    if (nom === villeActuelle.nom) return;
    await setVille(nom);
    router.refresh();
  }

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="mt-1 flex items-center gap-1 text-xs text-white/70"
      >
        📍 {villeActuelle.nom}
        <span className="text-[9px]">▾</span>
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute left-0 top-6 z-50 w-56 overflow-hidden rounded-mboa-lg border border-mboa-border bg-white shadow-lg">
            <p className="px-4 py-2.5 text-xs font-bold text-mboa-text-muted">Villes couvertes</p>
            {villes.map((v) => (
              <button
                key={v.id}
                type="button"
                onClick={() => choisir(v.nom)}
                className={`flex w-full items-center gap-2 px-4 py-2.5 text-left text-sm ${
                  v.nom === villeActuelle.nom
                    ? "bg-mboa-primary/8 font-bold text-mboa-primary"
                    : "text-mboa-text hover:bg-mboa-background"
                }`}
              >
                📍 {v.nom}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
