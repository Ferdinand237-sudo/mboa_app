"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { Photo } from "@/components/ui/photo";
import { TrashIcon } from "@/components/ui/icons";
import type { AlerteItem } from "@/lib/data/alertes";

type Resultat = { id: string; titre: string; photos: string[] | null };

// Miroir de _executerAlerte + _afficherResultats (alertes_recherche_screen.dart) :
// la feuille de résultats devient un panneau ancré en bas de l'écran.
export function AlertesList({ alertes: initial }: { alertes: AlerteItem[] }) {
  const [alertes, setAlertes] = useState(initial);
  const [loadingId, setLoadingId] = useState<string | null>(null);
  const [sheet, setSheet] = useState<{
    libelle: string;
    type: "logement" | "article";
    resultats: Resultat[];
  } | null>(null);

  async function supprimer(id: string) {
    setAlertes((prev) => prev.filter((a) => a.id !== id));
    const supabase = createClient();
    await supabase.from("alertes_recherche").delete().eq("id", id);
  }

  async function executer(alerte: AlerteItem) {
    setLoadingId(alerte.id);
    const supabase = createClient();
    try {
      let resultats: Resultat[] = [];
      if (alerte.type === "logement") {
        let query = supabase.from("logements").select("id, titre, photos").eq("statut", "disponible");
        const type = alerte.criteres.type;
        if (typeof type === "string" && type !== "Tous") query = query.eq("type", type);
        const prixMax = alerte.criteres.prixMax;
        if (typeof prixMax === "number") query = query.lte("prix", prixMax);
        const { data } = await query.order("date_publication", { ascending: false });
        resultats = data ?? [];
      } else {
        let query = supabase.from("articles").select("id, titre, photos").eq("statut", "disponible");
        const categorie = alerte.criteres.categorie;
        if (typeof categorie === "string" && categorie !== "Tous") query = query.eq("categorie", categorie);
        const etat = alerte.criteres.etat;
        if (typeof etat === "string" && etat !== "Tous") query = query.eq("etat", etat);
        const { data } = await query.order("date_publication", { ascending: false });
        resultats = data ?? [];
      }
      setSheet({ libelle: alerte.libelle, type: alerte.type, resultats });
    } finally {
      setLoadingId(null);
    }
  }

  if (alertes.length === 0) {
    return (
      <div className="flex flex-col items-center px-8 py-20 text-center">
        <span className="text-5xl" aria-hidden>
          🔔
        </span>
        <p className="mt-4 text-base font-bold text-mboa-text">Aucune alerte enregistrée</p>
        <p className="mt-2 max-w-xs text-sm leading-relaxed text-mboa-text-muted">
          Depuis les filtres de Logement ou Market, appuie sur « Enregistrer comme alerte » pour
          retrouver facilement une recherche.
        </p>
      </div>
    );
  }

  return (
    <>
      <div className="mx-auto flex max-w-2xl flex-col gap-2.5 px-4 pb-10">
        {alertes.map((a) => (
          <div key={a.id} className="flex items-center gap-3 rounded-mboa-md bg-mboa-card p-3.5 shadow-sm">
            <button
              type="button"
              onClick={() => executer(a)}
              disabled={loadingId === a.id}
              className="flex flex-1 items-center gap-3 text-left"
            >
              <span className="text-xl" aria-hidden>
                {a.type === "logement" ? "🏠" : "📦"}
              </span>
              <span className="flex-1 text-[13px] font-semibold text-mboa-text">{a.libelle}</span>
              {loadingId === a.id && (
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-mboa-primary border-t-transparent" />
              )}
            </button>
            <button
              type="button"
              onClick={() => supprimer(a.id)}
              aria-label="Supprimer l'alerte"
              className="shrink-0 text-mboa-danger"
            >
              <TrashIcon className="h-5 w-5" />
            </button>
          </div>
        ))}
      </div>

      {sheet && (
        <div
          className="fixed inset-0 z-50 flex items-end bg-black/40"
          onClick={() => setSheet(null)}
        >
          <div
            className="max-h-[80vh] w-full overflow-y-auto rounded-t-3xl bg-mboa-background p-5"
            onClick={(e) => e.stopPropagation()}
          >
            <p className="text-base font-extrabold text-mboa-text">
              {sheet.libelle} ({sheet.resultats.length})
            </p>
            <div className="mt-3.5 flex flex-col gap-2.5 pb-4">
              {sheet.resultats.length === 0 ? (
                <p className="py-10 text-center text-sm text-mboa-text-muted">
                  Aucun résultat pour le moment
                </p>
              ) : (
                sheet.resultats.map((item) => (
                  <Link
                    key={item.id}
                    href={sheet.type === "logement" ? `/logements/${item.id}` : `/marketplace/${item.id}`}
                    onClick={() => setSheet(null)}
                    className="flex items-center gap-3 rounded-mboa-md bg-mboa-card p-2.5 shadow-sm"
                  >
                    <div className="relative h-[60px] w-[60px] shrink-0 overflow-hidden rounded-[10px] bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
                      <Photo src={item.photos?.[0]} alt={item.titre} />
                    </div>
                    <p className="line-clamp-2 flex-1 text-[13px] font-semibold text-mboa-text">
                      {item.titre}
                    </p>
                  </Link>
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
