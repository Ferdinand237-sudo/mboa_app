"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { BackButton } from "@/components/ui/back-button";
import { SearchIcon } from "@/components/ui/icons";
import { Photo } from "@/components/ui/photo";
import { formatPrix } from "@/lib/utils/format";

type ResultatLogement = {
  id: string;
  titre: string;
  prix: number;
  quartier: string | null;
  photos: string[];
};
type ResultatArticle = {
  id: string;
  titre: string;
  prix: number;
  etat: string | null;
  photos: string[];
};

// Miroir de home_search_screen.dart.
export function RechercheClient() {
  const [texte, setTexte] = useState("");
  const terme = texte.trim();
  const [result, setResult] = useState<{
    key: string;
    logements: ResultatLogement[];
    articles: ResultatArticle[];
  }>({ key: "", logements: [], articles: [] });
  const loading = terme !== "" && result.key !== terme;
  const logements = result.key === terme ? result.logements : [];
  const articles = result.key === terme ? result.articles : [];

  useEffect(() => {
    if (!terme) return;
    const handle = setTimeout(() => {
      const supabase = createClient();
      const like = `%${terme}%`;
      Promise.all([
        supabase
          .from("logements")
          .select("id, titre, prix, quartier, photos")
          .eq("statut", "disponible")
          .or(`titre.ilike.${like},quartier.ilike.${like},description.ilike.${like}`)
          .order("boosted", { ascending: false })
          .limit(20),
        supabase
          .from("articles")
          .select("id, titre, prix, etat, photos")
          .eq("statut", "disponible")
          .or(`titre.ilike.${like},description.ilike.${like},categorie.ilike.${like}`)
          .order("boosted", { ascending: false })
          .limit(20),
      ]).then(([logementsRes, articlesRes]) => {
        setResult({ key: terme, logements: logementsRes.data ?? [], articles: articlesRes.data ?? [] });
      });
    }, 350);
    return () => clearTimeout(handle);
  }, [terme]);

  const total = logements.length + articles.length;

  return (
    <div>
      <div className="flex items-center gap-2 rounded-b-[32px] bg-white px-3 py-2.5 shadow-sm">
        <BackButton />
        <div className="flex h-[46px] flex-1 items-center gap-2 rounded-xl border border-mboa-border bg-mboa-background px-3">
          <SearchIcon className="h-5 w-5 shrink-0 text-mboa-text-muted" />
          <input
            autoFocus
            value={texte}
            onChange={(e) => setTexte(e.target.value)}
            placeholder="Chambre, studio, table, frigo..."
            className="min-w-0 flex-1 bg-transparent text-sm text-mboa-text outline-none placeholder:text-mboa-text-muted"
          />
          {texte && (
            <button
              type="button"
              onClick={() => setTexte("")}
              aria-label="Effacer"
              className="shrink-0 text-mboa-text-muted"
            >
              ✕
            </button>
          )}
        </div>
      </div>

      <div className="mx-auto max-w-2xl px-4 py-4 pb-10">
        {!terme && !loading ? (
          <div className="flex flex-col items-center py-20 text-center">
            <span className="text-5xl" aria-hidden>
              🔍
            </span>
            <p className="mt-4 text-base font-bold text-mboa-text">Recherche instantanée</p>
            <p className="mt-2 max-w-xs text-sm text-mboa-text-muted">
              Cherche parmi les logements et les articles du Market en tapant simplement quelques
              lettres.
            </p>
          </div>
        ) : loading ? (
          <div className="flex justify-center py-20">
            <span className="h-8 w-8 animate-spin rounded-full border-4 border-mboa-primary border-t-transparent" />
          </div>
        ) : total === 0 ? (
          <div className="flex flex-col items-center py-20 text-center">
            <span className="text-4xl" aria-hidden>
              😕
            </span>
            <p className="mt-3 text-sm text-mboa-text-muted">Aucun résultat pour &quot;{terme}&quot;</p>
          </div>
        ) : (
          <div className="flex flex-col gap-5">
            {logements.length > 0 && (
              <div>
                <p className="text-[13px] font-bold text-mboa-text">🏠 Logements ({logements.length})</p>
                <div className="mt-2.5 flex flex-col gap-2.5">
                  {logements.map((l) => (
                    <Link
                      key={l.id}
                      href={`/logements/${l.id}`}
                      className="flex items-center gap-3 rounded-mboa-md bg-mboa-card p-2.5 shadow-sm"
                    >
                      <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-[10px] bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
                        <Photo src={l.photos[0]} alt={l.titre} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-[13px] font-bold text-mboa-text">{l.titre}</p>
                        <p className="mt-0.5 text-xs font-extrabold text-mboa-primary">{formatPrix(l.prix)}</p>
                        <p className="mt-0.5 truncate text-xs text-mboa-text-muted">{l.quartier ?? ""}</p>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            )}

            {articles.length > 0 && (
              <div>
                <p className="text-[13px] font-bold text-mboa-text">🛒 Market ({articles.length})</p>
                <div className="mt-2.5 flex flex-col gap-2.5">
                  {articles.map((a) => (
                    <Link
                      key={a.id}
                      href={`/marketplace/${a.id}`}
                      className="flex items-center gap-3 rounded-mboa-md bg-mboa-card p-2.5 shadow-sm"
                    >
                      <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-[10px] bg-gradient-to-br from-mboa-primary to-mboa-primary-light">
                        <Photo src={a.photos[0]} alt={a.titre} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-[13px] font-bold text-mboa-text">{a.titre}</p>
                        <p className="mt-0.5 text-xs font-extrabold text-mboa-accent">{formatPrix(a.prix)}</p>
                        <p className="mt-0.5 truncate text-xs text-mboa-text-muted">{a.etat ?? ""}</p>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
