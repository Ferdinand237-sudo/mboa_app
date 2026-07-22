"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Dialog } from "@/components/ui/dialog";
import type { AdminDemande } from "@/lib/data/admin";

const PERMISSIONS = [
  { label: "🏠 Propriétaire immobilier", value: "proprietaire" },
  { label: "🛒 Commerçant boutique", value: "commercant" },
  { label: "📦 Vendeur indépendant", value: "vendeur_independant" },
];

const FUNCTION_NAMES = ["create-vendor", "create-vendeur", "create_vendor", "createVendeur"];

// Miroir de _creerCompteVendeur (admin_demandes_screen.dart) : formulaire de
// création (nouveau compte via Edge Function) ou de mise à niveau (compte
// étudiant existant, simple changement de rôle/sous_roles).
export function CreateVendorDialog({
  demande,
  onClose,
  onSuccess,
}: {
  demande: AdminDemande;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [password, setPassword] = useState("");
  const [sousRoles, setSousRoles] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const compteExistant = demande.userId != null;

  async function invokeCreateVendor(body: Record<string, unknown>) {
    const supabase = createClient();
    for (const name of FUNCTION_NAMES) {
      const response = await supabase.functions.invoke(name, { body });
      if (!response.error) return response;
    }
    return null;
  }

  async function valider() {
    if (sousRoles.length === 0) {
      setError("Sélectionne au moins une permission");
      return;
    }
    if (!compteExistant && password.length < 6) {
      setError("Minimum 6 caractères");
      return;
    }
    setError(null);
    setLoading(true);
    const supabase = createClient();

    try {
      if (compteExistant) {
        const { data: existing } = await supabase
          .from("users")
          .select("sous_roles")
          .eq("id", demande.userId as string)
          .single();
        const current: string[] = existing?.sous_roles ?? [];
        const merged = [...new Set([...current, ...sousRoles])];
        const { error: updateError } = await supabase
          .from("users")
          .update({ role: "vendeur", sous_roles: merged })
          .eq("id", demande.userId as string);
        if (updateError) throw updateError;
        await supabase.from("demandes_compte").update({ statut: "traite" }).eq("id", demande.id);
      } else {
        const response = await invokeCreateVendor({
          nom: demande.nom,
          email: demande.email,
          password,
          whatsapp: demande.whatsapp,
          sousRoles,
          demandeId: demande.id,
        });
        if (!response) throw new Error("Fonction Supabase introuvable");
      }
      onSuccess();
    } catch {
      setError("Erreur lors de la création du compte");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Dialog open onClose={onClose}>
      <h2 className="text-base font-extrabold text-mboa-text">✅ Créer le compte vendeur</h2>

      <div className="mt-3 rounded-mboa-md bg-mboa-primary/6 p-3">
        <p className="text-sm font-bold text-mboa-text">{demande.nom}</p>
        <p className="text-xs text-mboa-text-muted">{demande.email}</p>
        <p className="text-xs text-mboa-text-muted">📱 {demande.whatsapp}</p>
        <span className="mt-1.5 inline-block rounded-lg bg-mboa-secondary/10 px-2 py-1 text-[11px] font-semibold text-mboa-secondary">
          {demande.typeActivite}
        </span>
        <p className="mt-1.5 line-clamp-3 text-xs text-mboa-text-muted">{demande.description}</p>
      </div>

      {compteExistant ? (
        <p className="mt-3 rounded-mboa-md bg-mboa-verified/8 p-2.5 text-[11px] text-mboa-text">
          👤 Compte existant : le rôle sera simplement mis à jour, sans nouveau mot de passe.
        </p>
      ) : (
        <label className="mt-3 flex flex-col gap-1.5">
          <span className="text-xs font-semibold text-mboa-text">Mot de passe temporaire</span>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Min. 6 caractères"
            className="rounded-mboa-md border border-mboa-border bg-mboa-background px-3.5 py-2.5 text-sm text-mboa-text outline-none focus:border-2 focus:border-mboa-primary"
          />
        </label>
      )}

      <p className="mt-3 text-xs font-semibold text-mboa-text">Permissions accordées</p>
      <div className="mt-2 flex flex-col gap-2">
        {PERMISSIONS.map((p) => {
          const isSelected = sousRoles.includes(p.value);
          return (
            <button
              key={p.value}
              type="button"
              onClick={() =>
                setSousRoles((prev) => (isSelected ? prev.filter((v) => v !== p.value) : [...prev, p.value]))
              }
              className={`flex items-center justify-between rounded-mboa-md border-[1.5px] px-3 py-2.5 text-left text-sm ${
                isSelected ? "border-mboa-primary bg-mboa-primary/8 text-mboa-primary" : "border-mboa-border bg-mboa-background text-mboa-text"
              }`}
            >
              {p.label}
              {isSelected && <span>✓</span>}
            </button>
          );
        })}
      </div>

      {error && <p className="mt-3 text-xs font-semibold text-mboa-danger">{error}</p>}

      <div className="mt-5 flex justify-end gap-3">
        <button type="button" onClick={onClose} className="rounded-mboa-md px-4 py-2 text-sm font-semibold text-mboa-text-muted">
          Annuler
        </button>
        <button
          type="button"
          onClick={valider}
          disabled={loading}
          className="rounded-mboa-md bg-mboa-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
        >
          {loading ? "..." : compteExistant ? "Mettre à jour le compte" : "Créer le compte"}
        </button>
      </div>
    </Dialog>
  );
}
