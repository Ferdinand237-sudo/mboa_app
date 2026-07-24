"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { formatPrix } from "@/lib/utils/format";
import type { AdminAnnonce } from "@/lib/data/admin";

// Miroir de AdminAnnoncesScreen (admin_annonces_screen.dart).
export function AnnoncesClient({
  logements: initialLogements,
  articles: initialArticles,
}: {
  logements: AdminAnnonce[];
  articles: AdminAnnonce[];
}) {
  const [logements, setLogements] = useState(initialLogements);
  const [articles, setArticles] = useState(initialArticles);
  const [tab, setTab] = useState<"logements" | "articles">("logements");
  const [toDelete, setToDelete] = useState<AdminAnnonce | null>(null);
  const [busy, setBusy] = useState(false);

  function update(annonce: AdminAnnonce, patch: Partial<AdminAnnonce>) {
    const setList = annonce.table === "logements" ? setLogements : setArticles;
    setList((prev) => prev.map((a) => (a.id === annonce.id ? { ...a, ...patch } : a)));
  }

  async function toggleBoost(annonce: AdminAnnonce) {
    const supabase = createClient();
    const { error } = await supabase.from(annonce.table).update({ boosted: !annonce.boosted }).eq("id", annonce.id);
    if (!error) update(annonce, { boosted: !annonce.boosted });
  }

  async function toggleStatut(annonce: AdminAnnonce) {
    const nouveau = annonce.statut === "disponible" ? "reserve" : "disponible";
    const supabase = createClient();
    const { error } = await supabase.from(annonce.table).update({ statut: nouveau }).eq("id", annonce.id);
    if (!error) update(annonce, { statut: nouveau });
  }

  async function supprimer() {
    if (!toDelete) return;
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase.from(toDelete.table).delete().eq("id", toDelete.id);
    setBusy(false);
    if (!error) {
      const setList = toDelete.table === "logements" ? setLogements : setArticles;
      setList((prev) => prev.filter((a) => a.id !== toDelete.id));
    }
    setToDelete(null);
  }

  const liste = tab === "logements" ? logements : articles;

  return (
    <div>
      <div className="rounded-b-[32px] bg-white px-5 pt-4 shadow-sm">
        <div className="mx-auto max-w-4xl">
          <h1 className="text-[22px] font-extrabold text-mboa-text">📋 Annonces</h1>
          <p className="mt-1 text-sm text-mboa-text-muted">
            {logements.length + articles.length} annonces au total
          </p>
          <div className="mt-3 flex gap-1 border-b border-mboa-border">
            <button
              type="button"
              onClick={() => setTab("logements")}
              className={`border-b-[3px] px-4 py-3 text-[13px] font-bold ${
                tab === "logements" ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
              }`}
            >
              🏠 Logements ({logements.length})
            </button>
            <button
              type="button"
              onClick={() => setTab("articles")}
              className={`border-b-[3px] px-4 py-3 text-[13px] font-bold ${
                tab === "articles" ? "border-mboa-primary text-mboa-primary" : "border-transparent text-mboa-text-muted"
              }`}
            >
              🛒 Articles ({articles.length})
            </button>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-4xl px-4 py-4 pb-10">
        {liste.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-center">
            <span className="text-5xl" aria-hidden>
              📭
            </span>
            <p className="mt-3 text-base font-semibold text-mboa-text-muted">
              {tab === "logements" ? "Aucun logement publié" : "Aucun article publié"}
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-2.5">
            {liste.map((a) => (
              <div
                key={a.id}
                className={`rounded-mboa-lg border bg-mboa-card p-3.5 shadow-sm ${
                  a.boosted
                    ? "border-mboa-boost/40"
                    : a.signalements > 0
                      ? "border-mboa-danger/30"
                      : "border-mboa-border"
                }`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 flex-1">
                    <p className="line-clamp-2 text-sm font-bold text-mboa-text">{a.titre}</p>
                    {a.vendeurNom && <p className="mt-0.5 text-xs text-mboa-text-muted">Par {a.vendeurNom}</p>}
                  </div>
                  <div className="flex shrink-0 flex-col items-end gap-1">
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${
                        a.statut === "disponible"
                          ? "bg-mboa-verified/12 text-mboa-verified"
                          : "bg-mboa-text-muted/12 text-mboa-text-muted"
                      }`}
                    >
                      {a.statut}
                    </span>
                    {a.boosted && (
                      <span className="rounded-full bg-mboa-boost/12 px-2 py-0.5 text-[10px] font-bold text-mboa-boost">
                        🔥 Boost
                      </span>
                    )}
                  </div>
                </div>

                <div className="mt-2 flex flex-wrap items-center gap-2">
                  <span
                    className={`rounded-lg px-2 py-1 text-[10px] font-semibold ${
                      a.table === "logements" ? "bg-mboa-primary/8 text-mboa-primary" : "bg-mboa-accent/8 text-mboa-accent"
                    }`}
                  >
                    💰 {formatPrix(a.prix)}
                  </span>
                  {a.infoSecondaire && (
                    <span
                      className={`rounded-lg px-2 py-1 text-[10px] font-semibold ${
                        a.table === "logements" ? "bg-mboa-text-muted/8 text-mboa-text-muted" : "bg-mboa-secondary/8 text-mboa-secondary"
                      }`}
                    >
                      {a.table === "logements" ? "📍" : "📦"} {a.infoSecondaire}
                    </span>
                  )}
                  {a.signalements > 0 && (
                    <span className="ml-auto rounded-full bg-mboa-danger/10 px-2 py-1 text-[10px] font-bold text-mboa-danger">
                      🚩 {a.signalements} signal.
                    </span>
                  )}
                </div>

                <div className="mt-3 flex gap-2 border-t border-mboa-border pt-2.5">
                  <button
                    type="button"
                    onClick={() => toggleBoost(a)}
                    className={`flex-1 rounded-mboa-md border px-2 py-2 text-[11px] font-bold ${
                      a.boosted
                        ? "border-mboa-boost/40 bg-mboa-boost/12 text-mboa-boost"
                        : "border-mboa-boost/40 text-mboa-boost"
                    }`}
                  >
                    {a.boosted ? "🚀 Boosté" : "🚀 Booster"}
                  </button>
                  <button
                    type="button"
                    onClick={() => toggleStatut(a)}
                    className={`flex-1 rounded-mboa-md border px-2 py-2 text-[11px] font-bold ${
                      a.statut === "disponible"
                        ? "border-mboa-text-muted/40 text-mboa-text-muted"
                        : "border-mboa-verified/40 text-mboa-verified"
                    }`}
                  >
                    {a.statut === "disponible" ? "⏸ Suspendre" : "▶ Activer"}
                  </button>
                  <button
                    type="button"
                    onClick={() => setToDelete(a)}
                    aria-label="Supprimer"
                    className="rounded-mboa-md border border-mboa-danger/30 bg-mboa-danger/8 px-3 py-2 text-mboa-danger"
                  >
                    🗑
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <ConfirmDialog
        open={toDelete !== null}
        onClose={() => setToDelete(null)}
        title="🗑 Supprimer"
        body="Es-tu sûr de vouloir supprimer cette annonce ? Cette action est irréversible."
        confirmLabel="Supprimer"
        busy={busy}
        onConfirm={supprimer}
      />
    </div>
  );
}
