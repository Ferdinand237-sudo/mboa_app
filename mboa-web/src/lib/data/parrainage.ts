import { createClient } from "@/lib/supabase/server";

export type PalierParrainage = {
  nom: string;
  icone: string;
  seuilCredits: number;
  ordre: number;
};

export type Filleul = {
  id: string;
  nom: string;
  type: "visiteur" | "vendeur";
  statut: "en_attente" | "valide";
  creditsAttribues: number;
  createdAt: string;
};

export type ResumeParrainage = {
  credits: number;
  paliers: PalierParrainage[];
  palierActuel: PalierParrainage;
  palierSuivant: PalierParrainage | null;
  filleuls: Filleul[];
};

function palierFromRow(row: Record<string, unknown>): PalierParrainage {
  return {
    nom: String(row.nom ?? ""),
    icone: String(row.icone ?? "⭐"),
    seuilCredits: Number(row.seuil_credits ?? 0),
    ordre: Number(row.ordre ?? 0),
  };
}

// Vue d'ensemble affichée sur /parrainage : palier atteint, progression
// vers le suivant, liste des filleuls (parrainés directement -- un seul
// niveau, jamais les filleuls des filleuls, voir HISTORIQUE_PROJET_MBOA.md).
export async function getResumeParrainage(userId: string): Promise<ResumeParrainage> {
  const supabase = await createClient();

  const [paliersRes, userRes, filleulsRes] = await Promise.all([
    supabase.from("paliers_parrainage").select("nom, icone, seuil_credits, ordre").order("ordre"),
    supabase.from("users").select("credits_parrainage").eq("id", userId).single(),
    supabase
      .from("parrainages")
      .select("id, type_filleul, statut, credits_attribues, created_at, filleul:users!filleul_id(nom)")
      .eq("parrain_id", userId)
      .order("created_at", { ascending: false }),
  ]);

  const paliers = (paliersRes.data ?? []).map(palierFromRow);
  const credits = Number(userRes.data?.credits_parrainage ?? 0);

  const atteints = paliers.filter((p) => p.seuilCredits <= credits);
  const palierActuel = atteints[atteints.length - 1] ?? paliers[0] ?? { nom: "Débrouillard(e)", icone: "🌱", seuilCredits: 0, ordre: 1 };
  const palierSuivant = paliers.find((p) => p.seuilCredits > credits) ?? null;

  const filleuls: Filleul[] = (filleulsRes.data ?? []).map((row) => {
    const filleulRow = row.filleul as { nom?: string } | { nom?: string }[] | null;
    const nom = Array.isArray(filleulRow) ? filleulRow[0]?.nom : filleulRow?.nom;
    return {
      id: String(row.id ?? ""),
      nom: nom ?? "Utilisateur",
      type: row.type_filleul === "vendeur" ? "vendeur" : "visiteur",
      statut: row.statut === "valide" ? "valide" : "en_attente",
      creditsAttribues: Number(row.credits_attribues ?? 0),
      createdAt: String(row.created_at ?? ""),
    };
  });

  return { credits, paliers, palierActuel, palierSuivant, filleuls };
}
