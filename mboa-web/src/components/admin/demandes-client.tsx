"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { FilterPills } from "@/components/admin/filter-pills";
import { CreateVendorDialog } from "@/components/admin/create-vendor-dialog";
import { initiales } from "@/lib/utils/format";
import type { AdminDemande } from "@/lib/data/admin";

const FILTRES = [
  { value: "en-attente", label: "⏳ En attente" },
  { value: "approuve", label: "✅ Approuvés" },
  { value: "rejete", label: "❌ Rejetés" },
  { value: "tous", label: "📋 Tous" },
] as const;

const STATUT_STYLE: Record<string, { label: string; color: string }> = {
  approuve: { label: "✅ Approuvé", color: "text-mboa-verified bg-mboa-verified/12" },
  traite: { label: "✅ Traité", color: "text-mboa-verified bg-mboa-verified/12" },
  rejete: { label: "❌ Rejeté", color: "text-mboa-danger bg-mboa-danger/12" },
  "en-attente": { label: "⏳ En attente", color: "text-mboa-boost bg-mboa-boost/12" },
};

// Miroir de AdminDemandesScreen (admin_demandes_screen.dart).
export function DemandesClient({ demandes: initial }: { demandes: AdminDemande[] }) {
  const [demandes, setDemandes] = useState(initial);
  const [filtre, setFiltre] = useState<(typeof FILTRES)[number]["value"]>("en-attente");
  const [dialogDemande, setDialogDemande] = useState<AdminDemande | null>(null);

  const affichees = filtre === "tous" ? demandes : demandes.filter((d) => d.statut === filtre);
  const nbEnAttente = demandes.filter((d) => d.statut === "en-attente").length;

  async function rejeter(id: string) {
    const supabase = createClient();
    const { error } = await supabase.from("demandes_compte").update({ statut: "rejete" }).eq("id", id);
    if (!error) setDemandes((prev) => prev.map((d) => (d.id === id ? { ...d, statut: "rejete" } : d)));
  }

  function onCreated(id: string) {
    setDemandes((prev) => prev.map((d) => (d.id === id ? { ...d, statut: "traite" } : d)));
    setDialogDemande(null);
  }

  return (
    <div>
      <div className="bg-white px-5 pt-4">
        <div className="mx-auto max-w-4xl">
          <div className="flex items-center justify-between">
            <h1 className="text-[22px] font-extrabold text-mboa-text">📨 Demandes Pro</h1>
            <span className="rounded-full bg-mboa-secondary/10 px-3 py-1.5 text-xs font-bold text-mboa-secondary">
              {nbEnAttente} en attente
            </span>
          </div>
          <div className="mt-3 pb-3">
            <FilterPills options={FILTRES.slice()} value={filtre} onChange={setFiltre} />
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-4xl px-4 py-4 pb-10">
        {affichees.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-center">
            <span className="text-5xl" aria-hidden>
              📭
            </span>
            <p className="mt-3 text-base font-semibold text-mboa-text-muted">
              {filtre === "en-attente" ? "Aucune demande en attente" : "Aucune demande"}
            </p>
            <p className="mt-1 text-sm text-mboa-text-muted">Les demandes de compte Pro apparaîtront ici</p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {affichees.map((d) => {
              const style = STATUT_STYLE[d.statut] ?? STATUT_STYLE["en-attente"];
              return (
                <div key={d.id} className="rounded-mboa-lg border border-mboa-border bg-mboa-card p-4 shadow-sm">
                  <div className="flex items-center gap-3">
                    <span className="flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-full bg-mboa-secondary/12 text-base font-bold text-mboa-secondary">
                      {initiales(d.nom)}
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-[15px] font-bold text-mboa-text">{d.nom}</p>
                      <p className="truncate text-xs text-mboa-text-muted">{d.email}</p>
                    </div>
                    <span className={`shrink-0 rounded-full px-2.5 py-1 text-[10px] font-bold ${style.color}`}>
                      {style.label}
                    </span>
                  </div>

                  <p className="mt-3 flex items-center gap-1.5 text-sm text-mboa-text-muted">📞 {d.whatsapp}</p>
                  <span className="mt-1.5 inline-block rounded-lg bg-mboa-secondary/8 px-2.5 py-1 text-xs font-semibold text-mboa-secondary">
                    🏷 {d.typeActivite}
                  </span>
                  <p className="mt-2 rounded-mboa-md bg-mboa-background p-2.5 text-sm leading-relaxed text-mboa-text">
                    {d.description}
                  </p>

                  {d.statut === "en-attente" && (
                    <div className="mt-3.5 flex gap-2.5 border-t border-mboa-border pt-2.5">
                      <button
                        type="button"
                        onClick={() => rejeter(d.id)}
                        className="flex-1 rounded-mboa-md border border-mboa-danger/30 bg-mboa-danger/6 py-2.5 text-sm font-bold text-mboa-danger"
                      >
                        ✕ Rejeter
                      </button>
                      <button
                        type="button"
                        onClick={() => setDialogDemande(d)}
                        className="flex-[2] rounded-mboa-md bg-mboa-primary py-2.5 text-sm font-bold text-white"
                      >
                        👤 Créer le compte
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {dialogDemande && (
        <CreateVendorDialog
          demande={dialogDemande}
          onClose={() => setDialogDemande(null)}
          onSuccess={() => onCreated(dialogDemande.id)}
        />
      )}
    </div>
  );
}
