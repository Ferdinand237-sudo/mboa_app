"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

const COUT_BOOST = 50;

// Échange 50 crédits de parrainage contre un boost (voir
// public.echanger_credits_boost, migration 20260731000000_parrainage.sql).
// router.refresh() plutôt qu'un état local : le solde de crédits vit sur
// UserModel (header), pas dans ce composant, donc il faut retraverser le
// Server Component parent pour que le nouveau solde s'affiche partout.
export function BoostCreditsButton({
  annonceType,
  annonceId,
  creditsDisponibles,
}: {
  annonceType: "logement" | "article";
  annonceId: string;
  creditsDisponibles: number;
}) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [erreur, setErreur] = useState<string | null>(null);
  const assezDeCredits = creditsDisponibles >= COUT_BOOST;

  async function booster() {
    if (!assezDeCredits || busy) return;
    setBusy(true);
    setErreur(null);
    const supabase = createClient();
    const { error } = await supabase.rpc("echanger_credits_boost", {
      p_annonce_type: annonceType,
      p_annonce_id: annonceId,
    });
    setBusy(false);
    if (error) {
      setErreur("Échec du boost. Réessaie.");
      return;
    }
    router.refresh();
  }

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-0.5 py-2">
      <button
        type="button"
        onClick={booster}
        disabled={!assezDeCredits || busy}
        title={assezDeCredits ? undefined : `${COUT_BOOST} crédits requis (tu en as ${creditsDisponibles})`}
        className="flex items-center gap-1 text-[11.5px] font-semibold text-mboa-boost disabled:text-mboa-text-muted"
      >
        🚀 Booster ({COUT_BOOST} crédits)
      </button>
      {erreur && <p className="text-[10px] text-mboa-danger">{erreur}</p>}
    </div>
  );
}
