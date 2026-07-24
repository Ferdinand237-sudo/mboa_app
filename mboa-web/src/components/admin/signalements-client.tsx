"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { FilterPills } from "@/components/admin/filter-pills";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { Dialog } from "@/components/ui/dialog";
import type { AdminSignalement } from "@/lib/data/admin";

const FILTRES = [
  { value: "en-attente", label: "⏳ En attente" },
  { value: "traite", label: "✅ Traités" },
  { value: "rejete", label: "❌ Rejetés" },
  { value: "tous", label: "📋 Tous" },
] as const;

const CIBLE_LABEL: Record<string, string> = {
  annonce: "📋 Annonce signalée",
  utilisateur: "👤 Utilisateur signalé",
  avis: "⭐ Avis signalé",
};

async function trouverAnnonce(cibleId: string): Promise<{ table: "logements" | "articles"; proprietaireId: string } | null> {
  const supabase = createClient();
  const { data: logement } = await supabase
    .from("logements")
    .select("proprietaire_id")
    .eq("id", cibleId)
    .maybeSingle();
  if (logement) return { table: "logements", proprietaireId: logement.proprietaire_id };
  const { data: article } = await supabase.from("articles").select("vendeur_id").eq("id", cibleId).maybeSingle();
  if (article) return { table: "articles", proprietaireId: article.vendeur_id };
  return null;
}

// Miroir de AdminSignalementsScreen (admin_signalements_screen.dart).
export function SignalementsClient({ signalements: initial }: { signalements: AdminSignalement[] }) {
  const [signalements, setSignalements] = useState(initial);
  const [filtre, setFiltre] = useState<(typeof FILTRES)[number]["value"]>("en-attente");
  const [seulementIa, setSeulementIa] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<AdminSignalement | null>(null);
  const [suspendTarget, setSuspendTarget] = useState<AdminSignalement | null>(null);
  const [raison, setRaison] = useState("");
  const [busy, setBusy] = useState(false);

  const affiches = signalements.filter((s) => {
    if (filtre !== "tous" && s.statut !== filtre) return false;
    if (seulementIa && !s.estDetectionIa) return false;
    return true;
  });
  const nbEnAttente = signalements.filter((s) => s.statut === "en-attente").length;

  function patch(id: string, statut: string) {
    setSignalements((prev) => prev.map((s) => (s.id === id ? { ...s, statut } : s)));
  }

  async function traiter(id: string, statut: "traite" | "rejete") {
    const supabase = createClient();
    const { error } = await supabase.from("signalements").update({ statut }).eq("id", id);
    if (!error) patch(id, statut);
  }

  async function supprimerAnnonce() {
    if (!deleteTarget) return;
    setBusy(true);
    const supabase = createClient();
    const annonce = await trouverAnnonce(deleteTarget.cibleId);
    if (annonce) await supabase.from(annonce.table).delete().eq("id", deleteTarget.cibleId);
    await traiter(deleteTarget.id, "traite");
    setBusy(false);
    setDeleteTarget(null);
  }

  async function suspendreAnnonce() {
    if (!suspendTarget || !raison.trim()) return;
    setBusy(true);
    const supabase = createClient();
    try {
      const annonce = await trouverAnnonce(suspendTarget.cibleId);
      if (annonce) {
        await supabase.from(annonce.table).update({ statut: "suspendu" }).eq("id", suspendTarget.cibleId);
      }
      const {
        data: { user: admin },
      } = await supabase.auth.getUser();
      if (annonce && admin) {
        const { data: conv } = await supabase
          .from("conversations")
          .insert({
            participants: [admin.id, annonce.proprietaireId],
            non_lu: { [admin.id]: 0, [annonce.proprietaireId]: 1 },
          })
          .select("id")
          .single();
        if (conv) {
          const texte = `⚠️ Une de vos annonces a été suspendue par l'administration Mboa.\n\nRaison : ${raison.trim()}`;
          await supabase.from("messages").insert({ conversation_id: conv.id, expediteur_id: admin.id, texte });
          await supabase
            .from("conversations")
            .update({
              dernier_message: `⚠️ Annonce suspendue : ${raison.trim()}`,
              dernier_message_date: new Date().toISOString(),
            })
            .eq("id", conv.id);
        }
      }
      await traiter(suspendTarget.id, "traite");
    } finally {
      setBusy(false);
      setSuspendTarget(null);
      setRaison("");
    }
  }

  return (
    <div>
      <div className="rounded-b-[32px] bg-white px-5 pt-4 shadow-sm">
        <div className="mx-auto max-w-4xl">
          <div className="flex items-center justify-between">
            <h1 className="text-[22px] font-extrabold text-mboa-text">🚨 Signalements</h1>
            <span className="rounded-full bg-mboa-danger/10 px-3 py-1.5 text-xs font-bold text-mboa-danger">
              {nbEnAttente} en attente
            </span>
          </div>
          <div className="mt-3">
            <FilterPills options={FILTRES.slice()} value={filtre} onChange={setFiltre} />
          </div>
          <div className="mt-2 pb-3">
            <button
              type="button"
              onClick={() => setSeulementIa((v) => !v)}
              className={`flex items-center gap-1.5 rounded-full border-[1.5px] px-3 py-1.5 text-[11.5px] font-semibold ${
                seulementIa ? "border-mboa-primary bg-mboa-primary/10 text-mboa-primary" : "border-mboa-border text-mboa-text-muted"
              }`}
            >
              {seulementIa ? "✓" : "🤖"} Détections IA uniquement
            </button>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-4xl px-4 py-4 pb-10">
        {affiches.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-center">
            <span className="text-5xl" aria-hidden>
              🎉
            </span>
            <p className="mt-3 text-base font-semibold text-mboa-text-muted">
              {filtre === "en-attente" ? "Aucun signalement en attente" : "Aucun signalement"}
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-2.5">
            {affiches.map((s) => (
              <div
                key={s.id}
                className={`rounded-mboa-lg border bg-mboa-card p-4 shadow-sm ${
                  s.statut === "en-attente" ? "border-mboa-danger/30" : "border-mboa-border"
                }`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-start gap-2.5">
                    <span
                      className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-lg ${
                        s.estDetectionIa ? "bg-mboa-primary/10" : "bg-mboa-danger/10"
                      }`}
                    >
                      {s.estDetectionIa ? "🤖" : "🚩"}
                    </span>
                    <div>
                      <p className="text-[13px] font-bold text-mboa-text">
                        {s.estDetectionIa ? "🤖 Détection IA — Annonce" : CIBLE_LABEL[s.cibleType] ?? "Signalement"}
                      </p>
                      <p className="text-xs text-mboa-text-muted">
                        {s.estDetectionIa ? "Analyse automatique Mboa" : s.signaleurNom ? `Par ${s.signaleurNom}` : ""}
                      </p>
                    </div>
                  </div>
                  <span
                    className={`shrink-0 rounded-full px-2.5 py-1 text-[10px] font-bold ${
                      s.statut === "traite"
                        ? "bg-mboa-verified/12 text-mboa-verified"
                        : s.statut === "rejete"
                          ? "bg-mboa-text-muted/12 text-mboa-text-muted"
                          : "bg-mboa-danger/12 text-mboa-danger"
                    }`}
                  >
                    {s.statut === "traite" ? "✅ Traité" : s.statut === "rejete" ? "❌ Rejeté" : "⏳ En attente"}
                  </span>
                </div>

                <div className="mt-3 rounded-mboa-md bg-mboa-background p-3">
                  <p className="text-xs">
                    <span className="font-bold text-mboa-text">Raison : </span>
                    <span className={`font-semibold ${s.estDetectionIa ? "text-mboa-primary" : "text-mboa-danger"}`}>
                      {s.estDetectionIa ? "Détection automatique (modération IA)" : s.raison}
                    </span>
                  </p>
                  {s.description && <p className="mt-1.5 text-sm text-mboa-text">{s.description}</p>}
                </div>

                {s.statut === "en-attente" && (
                  <div className="mt-3 flex gap-2 border-t border-mboa-border pt-2.5">
                    <button
                      type="button"
                      onClick={() => traiter(s.id, "rejete")}
                      className="flex-1 rounded-mboa-md border border-mboa-border bg-mboa-text-muted/8 py-2 text-[11px] font-bold text-mboa-text-muted"
                    >
                      👎 Ignorer
                    </button>
                    <button
                      type="button"
                      onClick={() => traiter(s.id, "traite")}
                      className="flex-1 rounded-mboa-md border border-mboa-verified/30 bg-mboa-verified/8 py-2 text-[11px] font-bold text-mboa-verified"
                    >
                      ✔ Résoudre
                    </button>
                    {s.cibleType === "annonce" && (
                      <button
                        type="button"
                        onClick={() => setSuspendTarget(s)}
                        aria-label="Suspendre l'annonce"
                        className="rounded-mboa-md border border-mboa-boost/30 bg-mboa-boost/8 px-3 py-2 text-mboa-boost"
                      >
                        ⏸
                      </button>
                    )}
                    <button
                      type="button"
                      onClick={() => setDeleteTarget(s)}
                      aria-label="Supprimer l'annonce"
                      className="rounded-mboa-md border border-mboa-danger/30 bg-mboa-danger/8 px-3 py-2 text-mboa-danger"
                    >
                      🗑
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      <ConfirmDialog
        open={deleteTarget !== null}
        onClose={() => setDeleteTarget(null)}
        title="🗑 Supprimer l'annonce"
        body="Cette action supprimera définitivement l'annonce signalée."
        confirmLabel="Supprimer"
        busy={busy}
        onConfirm={supprimerAnnonce}
      />

      <Dialog
        open={suspendTarget !== null}
        onClose={() => {
          setSuspendTarget(null);
          setRaison("");
        }}
      >
        <h2 className="text-base font-extrabold text-mboa-text">⏸ Suspendre l&apos;annonce</h2>
        <p className="mt-2 text-sm text-mboa-text-muted">
          L&apos;annonce sera masquée du public. Explique la raison au propriétaire, il recevra ce message
          directement.
        </p>
        <textarea
          value={raison}
          onChange={(e) => setRaison(e.target.value)}
          rows={3}
          placeholder="Ex : Photos non conformes au bien réel, merci de corriger."
          className="mt-3 w-full rounded-mboa-md border border-mboa-border bg-mboa-background px-3.5 py-3 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
        />
        <div className="mt-4 flex justify-end gap-3">
          <button
            type="button"
            onClick={() => {
              setSuspendTarget(null);
              setRaison("");
            }}
            className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted"
          >
            Annuler
          </button>
          <button
            type="button"
            onClick={suspendreAnnonce}
            disabled={busy || !raison.trim()}
            className="rounded-mboa-md bg-mboa-boost px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            Suspendre et prévenir
          </button>
        </div>
      </Dialog>
    </div>
  );
}
