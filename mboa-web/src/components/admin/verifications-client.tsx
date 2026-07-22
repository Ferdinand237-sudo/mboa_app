"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { FilterPills } from "@/components/admin/filter-pills";
import { Dialog } from "@/components/ui/dialog";
import type { AdminVerification } from "@/lib/data/admin";

const FILTRES = [
  { value: "en_attente_assignation", label: "🕓 À assigner" },
  { value: "assignee", label: "📍 Assignées" },
  { value: "visite_effectuee", label: "📤 À valider" },
  { value: "validee", label: "✅ Validées" },
  { value: "rejetee", label: "❌ Rejetées" },
  { value: "tous", label: "📋 Toutes" },
] as const;

// Miroir de AdminVerificationsScreen (admin_verifications_screen.dart).
export function VerificationsClient({ verifications: initial }: { verifications: AdminVerification[] }) {
  const [verifications, setVerifications] = useState(initial);
  const [filtre, setFiltre] = useState<(typeof FILTRES)[number]["value"]>("en_attente_assignation");
  const [assignTarget, setAssignTarget] = useState<AdminVerification | null>(null);
  const [ambassadeurs, setAmbassadeurs] = useState<{ id: string; nom: string }[]>([]);
  const [loadingAmbassadeurs, setLoadingAmbassadeurs] = useState(false);
  const [attestationUrl, setAttestationUrl] = useState<string | null>(null);
  const [attestationError, setAttestationError] = useState<string | null>(null);

  const affichees = filtre === "tous" ? verifications : verifications.filter((v) => v.statut === filtre);

  function patch(id: string, updates: Partial<AdminVerification>) {
    setVerifications((prev) => prev.map((v) => (v.id === id ? { ...v, ...updates } : v)));
  }

  async function ouvrirAssignation(v: AdminVerification) {
    setAssignTarget(v);
    setLoadingAmbassadeurs(true);
    const supabase = createClient();
    const { data } = await supabase.from("users").select("id, nom").eq("role", "ambassadeur");
    setAmbassadeurs((data ?? []).map((a) => ({ id: a.id, nom: a.nom ?? "" })));
    setLoadingAmbassadeurs(false);
  }

  async function assigner(ambassadeurId: string, ambassadeurNom: string) {
    if (!assignTarget) return;
    const supabase = createClient();
    const { error } = await supabase
      .from("verifications_terrain")
      .update({
        ambassadeur_id: ambassadeurId,
        statut: "assignee",
        date_assignation: new Date().toISOString(),
      })
      .eq("id", assignTarget.id);
    if (!error) patch(assignTarget.id, { statut: "assignee", ambassadeurNom });
    setAssignTarget(null);
  }

  async function voirAttestation(v: AdminVerification) {
    setAttestationError(null);
    setAttestationUrl(null);
    const supabase = createClient();
    try {
      const res = await supabase.functions.invoke("get-attestation-url", { body: { verificationId: v.id } });
      const url = (res.data as { url?: string } | null)?.url;
      if (url) {
        setAttestationUrl(url);
      } else {
        setAttestationError("Aucune attestation disponible");
      }
    } catch {
      setAttestationError("Impossible de charger l'attestation");
    }
  }

  async function traiter(v: AdminVerification, statut: "validee" | "rejetee") {
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    const { error } = await supabase
      .from("verifications_terrain")
      .update({ statut, admin_id: user?.id, date_traitement: new Date().toISOString() })
      .eq("id", v.id);
    if (!error) patch(v.id, { statut });
  }

  return (
    <div>
      <div className="bg-white px-5 pt-4">
        <div className="mx-auto max-w-4xl">
          <h1 className="text-[22px] font-extrabold text-mboa-text">🧭 Vérifications terrain</h1>
          <div className="mt-3 pb-3">
            <FilterPills options={FILTRES.slice()} value={filtre} onChange={setFiltre} />
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-4xl px-4 py-4 pb-10">
        {affichees.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-center">
            <span className="text-5xl" aria-hidden>
              🧭
            </span>
            <p className="mt-3 text-sm text-mboa-text-muted">Aucune vérification</p>
          </div>
        ) : (
          <div className="flex flex-col gap-2.5">
            {affichees.map((v) => (
              <div key={v.id} className="rounded-mboa-lg bg-mboa-card p-3.5 shadow-sm">
                <p className="text-sm font-bold text-mboa-text">{v.proprietaireNom ?? "Propriétaire"}</p>
                {v.proprietaireContact && <p className="text-xs text-mboa-text-muted">{v.proprietaireContact}</p>}
                {v.ambassadeurNom && (
                  <p className="mt-1 text-xs text-mboa-text-muted">👤 Ambassadeur : {v.ambassadeurNom}</p>
                )}
                {v.conformiteBien != null && (
                  <p className={`mt-1 text-xs font-semibold ${v.conformiteBien ? "text-mboa-verified" : "text-mboa-danger"}`}>
                    {v.conformiteBien ? "✅ Bien conforme" : "⚠️ Bien non conforme"}
                  </p>
                )}
                {v.typeJustificatif && <p className="mt-0.5 text-xs text-mboa-text-muted">📄 {v.typeJustificatif}</p>}

                <div className="mt-3 border-t border-mboa-border pt-2.5">
                  {v.statut === "en_attente_assignation" ? (
                    <button
                      type="button"
                      onClick={() => ouvrirAssignation(v)}
                      className="w-full rounded-mboa-md bg-mboa-primary py-2.5 text-sm font-bold text-white"
                    >
                      👤 Assigner un ambassadeur
                    </button>
                  ) : v.statut === "visite_effectuee" ? (
                    <div className="flex flex-col gap-2">
                      <button
                        type="button"
                        onClick={() => voirAttestation(v)}
                        className="w-full rounded-mboa-md border border-mboa-border py-2.5 text-sm font-bold text-mboa-text"
                      >
                        📄 Voir l&apos;attestation
                      </button>
                      <div className="flex gap-2">
                        <button
                          type="button"
                          onClick={() => traiter(v, "rejetee")}
                          className="flex-1 rounded-mboa-md bg-mboa-text-muted py-2.5 text-sm font-bold text-white"
                        >
                          ✕ Rejeter
                        </button>
                        <button
                          type="button"
                          onClick={() => traiter(v, "validee")}
                          className="flex-1 rounded-mboa-md bg-mboa-verified py-2.5 text-sm font-bold text-white"
                        >
                          ✓ Valider
                        </button>
                      </div>
                    </div>
                  ) : (
                    <span
                      className={`inline-block rounded-full px-2.5 py-1 text-[11px] font-bold ${
                        v.statut === "validee"
                          ? "bg-mboa-verified/10 text-mboa-verified"
                          : v.statut === "rejetee"
                            ? "bg-mboa-danger/10 text-mboa-danger"
                            : "bg-mboa-boost/10 text-mboa-boost"
                      }`}
                    >
                      {v.statut === "validee" ? "✅ Validée" : v.statut === "rejetee" ? "❌ Rejetée" : "📍 En attente de visite"}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <Dialog open={assignTarget !== null} onClose={() => setAssignTarget(null)}>
        <h2 className="text-base font-extrabold text-mboa-text">Assigner un ambassadeur</h2>
        <div className="mt-3 max-h-72 overflow-y-auto">
          {loadingAmbassadeurs ? (
            <p className="py-6 text-center text-sm text-mboa-text-muted">Chargement...</p>
          ) : ambassadeurs.length === 0 ? (
            <p className="py-6 text-center text-sm text-mboa-danger">Aucun ambassadeur créé pour l&apos;instant</p>
          ) : (
            <div className="flex flex-col gap-1.5">
              {ambassadeurs.map((a) => (
                <button
                  key={a.id}
                  type="button"
                  onClick={() => assigner(a.id, a.nom)}
                  className="flex items-center gap-2.5 rounded-mboa-md px-3 py-2.5 text-left text-sm font-semibold text-mboa-text hover:bg-mboa-background"
                >
                  📍 {a.nom}
                </button>
              ))}
            </div>
          )}
        </div>
        <div className="mt-4 flex justify-end">
          <button
            type="button"
            onClick={() => setAssignTarget(null)}
            className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted"
          >
            Annuler
          </button>
        </div>
      </Dialog>

      <Dialog
        open={attestationUrl !== null || attestationError !== null}
        onClose={() => {
          setAttestationUrl(null);
          setAttestationError(null);
        }}
      >
        {attestationUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={attestationUrl} alt="Attestation" className="max-h-[70vh] w-full rounded-mboa-md object-contain" />
        ) : (
          <p className="text-sm text-mboa-danger">{attestationError}</p>
        )}
      </Dialog>
    </div>
  );
}
