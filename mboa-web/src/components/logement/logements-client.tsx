"use client";

import { useEffect, useMemo, useState } from "react";
import { searchLogements, enregistrerAlerteLogement } from "@/app/logements/actions";
import { LogementTile } from "@/components/logement/logement-tile";
import { LimitBanner } from "@/components/ui/limit-banner";
import type { LogementModel } from "@/lib/types/models";
import { TYPES_LOGEMENT, PRIX_MIN, PRIX_MAX, PAGE_SIZE_VISITEUR } from "@/lib/constants";
import { formatPrix } from "@/lib/utils/format";

const TYPES = ["Tous", ...TYPES_LOGEMENT];
const NOTES = [0, 3, 4, 5];

export function LogementsClient({
  initialLogements,
  isLoggedIn,
}: {
  initialLogements: LogementModel[];
  isLoggedIn: boolean;
}) {
  const [search, setSearch] = useState("");
  const [type, setType] = useState("Tous");
  const [prixMax, setPrixMax] = useState(60000);
  const [noteMin, setNoteMin] = useState(0);
  const [showFiltres, setShowFiltres] = useState(false);
  const [result, setResult] = useState({ key: "", data: initialLogements });
  const [alerteMsg, setAlerteMsg] = useState<string | null>(null);

  const searchKey = JSON.stringify({ search, type, prixMax });
  const loading = result.key !== searchKey;
  const logements = result.key === searchKey ? result.data : initialLogements;

  useEffect(() => {
    const handle = setTimeout(() => {
      searchLogements({
        type: type === "Tous" ? undefined : type,
        prixMax,
        search: search || undefined,
      }).then((data) => {
        setResult({ key: searchKey, data });
      });
    }, 300);
    return () => clearTimeout(handle);
  }, [search, type, prixMax, searchKey]);

  const logementsFiltres = useMemo(
    () =>
      noteMin === 0
        ? logements
        : logements.filter((l) => l.proprietaireNoteGlobale >= noteMin),
    [logements, noteMin],
  );

  const displayed = isLoggedIn
    ? logementsFiltres
    : logementsFiltres.slice(0, PAGE_SIZE_VISITEUR);
  const showLimitBanner = !isLoggedIn && logementsFiltres.length > PAGE_SIZE_VISITEUR;

  function reinitialiser() {
    setType("Tous");
    setPrixMax(60000);
    setNoteMin(0);
    setSearch("");
    setShowFiltres(false);
  }

  async function enregistrerAlerte() {
    if (!isLoggedIn) {
      setAlerteMsg("Connectez-vous pour enregistrer une alerte");
      return;
    }
    const libelle =
      type === "Tous"
        ? `Logements jusqu'à ${formatPrix(prixMax)}`
        : `${type} jusqu'à ${formatPrix(prixMax)}`;
    const { error } = await enregistrerAlerteLogement(libelle, { type, prixMax });
    setAlerteMsg(error ? "Erreur lors de l'enregistrement" : "🔔 Alerte enregistrée !");
  }

  return (
    <div>
      <div className="border-b border-mboa-border bg-mboa-card px-5 py-4 sm:px-6">
        <div className="mx-auto max-w-7xl">
          <h1 className="text-xl font-extrabold text-mboa-text sm:text-2xl">
            🏘 Logement
          </h1>

          <div className="mt-3 flex gap-2.5">
            <div className="flex flex-1 items-center rounded-mboa-md border border-mboa-border bg-mboa-background px-3">
              <span className="text-mboa-text-muted">🔍</span>
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Quartier, type..."
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
                  ? "border-mboa-primary bg-mboa-primary text-white"
                  : "border-mboa-border bg-mboa-background text-mboa-text-muted"
              }`}
              aria-label="Filtres"
            >
              ⚙️
            </button>
          </div>

          <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
            {TYPES.map((t) => (
              <button
                key={t}
                onClick={() => setType(t)}
                className={`shrink-0 rounded-mboa-full border px-4 py-1.5 text-xs font-semibold ${
                  type === t
                    ? "border-mboa-primary bg-mboa-primary text-white"
                    : "border-mboa-border bg-mboa-card text-mboa-text"
                }`}
              >
                {t}
              </button>
            ))}
          </div>

          {showFiltres && (
            <div className="mt-3.5 border-t border-mboa-border pt-3.5">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-mboa-text">
                  Budget maximum
                </span>
                <span className="text-xs font-bold text-mboa-primary">
                  {formatPrix(prixMax)}
                </span>
              </div>
              <input
                type="range"
                min={PRIX_MIN}
                max={PRIX_MAX}
                step={5000}
                value={prixMax}
                onChange={(e) => setPrixMax(Number(e.target.value))}
                className="mt-2 w-full accent-mboa-primary"
              />

              <p className="mt-3 text-xs font-semibold text-mboa-text">
                Note minimum
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
                  className="text-xs font-semibold text-mboa-primary"
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
            : `${displayed.length} logement${displayed.length > 1 ? "s" : ""} trouvé${displayed.length > 1 ? "s" : ""}`}
        </p>

        {!loading && logements.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-center">
            <p className="text-5xl">🔍</p>
            <p className="mt-4 text-base font-bold text-mboa-text">
              Aucun logement trouvé
            </p>
            <p className="mt-1 text-sm text-mboa-text-muted">
              Essaye de modifier tes filtres
            </p>
            <button
              onClick={reinitialiser}
              className="mt-5 rounded-mboa-full bg-mboa-primary px-6 py-2.5 text-sm font-bold text-white"
            >
              Réinitialiser les filtres
            </button>
          </div>
        ) : (
          <div className="mt-4 grid grid-cols-1 gap-3.5 sm:grid-cols-2 lg:grid-cols-3">
            {displayed.map((l) => (
              <LogementTile key={l.id} logement={l} />
            ))}
            {showLimitBanner && (
              <div className="sm:col-span-2 lg:col-span-3">
                <LimitBanner
                  variant="primary"
                  message="Créez un compte gratuit pour découvrir tous les logements disponibles à Sangmelima"
                />
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
