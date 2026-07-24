"use client";

import { useEffect, useMemo, useState } from "react";
import { searchArticles, enregistrerAlerteArticle } from "@/app/marketplace/actions";
import { ArticleCard } from "@/components/market/article-card";
import { LimitBanner } from "@/components/ui/limit-banner";
import type { ArticleModel } from "@/lib/types/models";
import { CATEGORIES_MARKET, ETATS_ARTICLE, PAGE_SIZE_VISITEUR } from "@/lib/constants";

const CATEGORIES = [{ label: "Tous", icon: "🛍" }, ...CATEGORIES_MARKET];
const ETATS = ["Tous", ...ETATS_ARTICLE];
const NOTES = [0, 3, 4, 5];

export function MarketplaceClient({
  initialArticles,
  isLoggedIn,
}: {
  initialArticles: ArticleModel[];
  isLoggedIn: boolean;
}) {
  const [search, setSearch] = useState("");
  const [categorie, setCategorie] = useState("Tous");
  const [etat, setEtat] = useState("Tous");
  const [noteMin, setNoteMin] = useState(0);
  const [showFiltres, setShowFiltres] = useState(false);
  const [result, setResult] = useState({ key: "", data: initialArticles });
  const [alerteMsg, setAlerteMsg] = useState<string | null>(null);

  const searchKey = JSON.stringify({ search, categorie, etat });
  const loading = result.key !== searchKey;
  const articles = result.key === searchKey ? result.data : initialArticles;

  useEffect(() => {
    const handle = setTimeout(() => {
      searchArticles({
        categorie: categorie === "Tous" ? undefined : categorie,
        etat: etat === "Tous" ? undefined : etat,
        search: search || undefined,
      }).then((data) => {
        setResult({ key: searchKey, data });
      });
    }, 300);
    return () => clearTimeout(handle);
  }, [search, categorie, etat, searchKey]);

  const articlesFiltres = useMemo(
    () =>
      noteMin === 0
        ? articles
        : articles.filter((a) => a.vendeurNote >= noteMin),
    [articles, noteMin],
  );

  const displayed = isLoggedIn
    ? articlesFiltres
    : articlesFiltres.slice(0, PAGE_SIZE_VISITEUR);
  const showLimitBanner = !isLoggedIn && articlesFiltres.length > PAGE_SIZE_VISITEUR;

  function reinitialiser() {
    setCategorie("Tous");
    setEtat("Tous");
    setNoteMin(0);
    setSearch("");
    setShowFiltres(false);
  }

  async function enregistrerAlerte() {
    if (!isLoggedIn) {
      setAlerteMsg("Connectez-vous pour enregistrer une alerte");
      return;
    }
    const libelle = [categorie !== "Tous" ? categorie : null, etat !== "Tous" ? etat : null]
      .filter(Boolean)
      .join(" · ");
    const { error } = await enregistrerAlerteArticle(
      libelle || "Tous les articles Market",
      { categorie, etat },
    );
    setAlerteMsg(error ? "Erreur lors de l'enregistrement" : "🔔 Alerte enregistrée !");
  }

  return (
    <div>
      <div className="rounded-b-[32px] bg-mboa-card px-5 py-4 shadow-sm sm:px-6">
        <div className="mx-auto max-w-7xl">
          <h1 className="text-xl font-extrabold text-mboa-text sm:text-2xl">
            🛒 Market
          </h1>

          <div className="mt-3 flex gap-2.5">
            <div className="flex flex-1 items-center rounded-mboa-md border border-mboa-border bg-mboa-background px-3">
              <span className="text-mboa-text-muted">🔍</span>
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Lit, table, frigo..."
                className="w-full bg-transparent px-2 py-2.5 text-sm outline-none"
              />
              {search && (
                <button
                  onClick={() => setSearch("")}
                  className="text-mboa-text-muted"
                  aria-label="Effacer"
                >
                  ✕
                </button>
              )}
            </div>
            <button
              onClick={() => setShowFiltres((v) => !v)}
              className={`flex h-[42px] w-[42px] shrink-0 items-center justify-center rounded-mboa-md border ${
                showFiltres
                  ? "border-mboa-secondary bg-mboa-secondary text-white"
                  : "border-mboa-border bg-mboa-background text-mboa-text-muted"
              }`}
              aria-label="Filtres"
            >
              ⚙️
            </button>
          </div>

          <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
            {CATEGORIES.map((c) => (
              <button
                key={c.label}
                onClick={() => setCategorie(c.label)}
                className={`flex shrink-0 items-center gap-1.5 rounded-mboa-full border px-3.5 py-1.5 text-xs font-semibold ${
                  categorie === c.label
                    ? "border-mboa-secondary bg-mboa-secondary text-white"
                    : "border-mboa-border bg-mboa-card text-mboa-text"
                }`}
              >
                <span>{c.icon}</span>
                {c.label}
              </button>
            ))}
          </div>

          {showFiltres && (
            <div className="mt-3.5 border-t border-mboa-border pt-3.5">
              <p className="text-xs font-semibold text-mboa-text">
                État de l&apos;article
              </p>
              <div className="mt-2 flex gap-2 overflow-x-auto pb-1">
                {ETATS.map((e) => (
                  <button
                    key={e}
                    onClick={() => setEtat(e)}
                    className={`shrink-0 rounded-mboa-full border px-3.5 py-1 text-[11px] font-semibold ${
                      etat === e
                        ? "border-mboa-accent bg-mboa-accent text-white"
                        : "border-mboa-border bg-mboa-card text-mboa-text"
                    }`}
                  >
                    {e}
                  </button>
                ))}
              </div>

              <p className="mt-3 text-xs font-semibold text-mboa-text">
                Note minimum du vendeur
              </p>
              <div className="mt-2 flex gap-2">
                {NOTES.map((n) => (
                  <button
                    key={n}
                    onClick={() => setNoteMin(n)}
                    className={`rounded-mboa-full border px-3.5 py-1 text-[11px] font-semibold ${
                      noteMin === n
                        ? "border-mboa-boost bg-mboa-boost text-white"
                        : "border-mboa-border bg-mboa-card text-mboa-text"
                    }`}
                  >
                    {n === 0 ? "Toutes" : `⭐ ${n}+`}
                  </button>
                ))}
              </div>

              <div className="mt-3 flex items-center justify-between">
                <button
                  onClick={reinitialiser}
                  className="text-xs font-semibold text-mboa-danger"
                >
                  Réinitialiser les filtres
                </button>
                <button
                  onClick={enregistrerAlerte}
                  className="text-xs font-semibold text-mboa-secondary"
                >
                  🔔 Enregistrer comme alerte
                </button>
              </div>
              {alerteMsg && (
                <p className="mt-2 text-xs text-mboa-text-muted">{alerteMsg}</p>
              )}
            </div>
          )}
        </div>
      </div>

      <div className="mx-auto max-w-7xl px-5 py-4 sm:px-6">
        <p className="text-xs text-mboa-text-muted">
          {loading
            ? "Chargement..."
            : `${displayed.length} article${displayed.length > 1 ? "s" : ""} trouvé${displayed.length > 1 ? "s" : ""}`}
        </p>

        {!loading && articles.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-center">
            <p className="text-5xl">🔍</p>
            <p className="mt-4 text-base font-bold text-mboa-text">
              Aucun article trouvé
            </p>
            <p className="mt-1 text-sm text-mboa-text-muted">
              Essaye de modifier tes filtres
            </p>
            <button
              onClick={reinitialiser}
              className="mt-5 rounded-mboa-full bg-mboa-secondary px-6 py-2.5 text-sm font-bold text-white"
            >
              Réinitialiser les filtres
            </button>
          </div>
        ) : (
          <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
            {displayed.map((a) => (
              <ArticleCard key={a.id} article={a} />
            ))}
            {showLimitBanner && (
              <div className="col-span-2 sm:col-span-3 lg:col-span-4 xl:col-span-5">
                <LimitBanner
                  variant="accent"
                  message="Créez un compte gratuit pour découvrir tous les articles du Market"
                />
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
