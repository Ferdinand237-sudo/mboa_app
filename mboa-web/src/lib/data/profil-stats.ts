import { createClient } from "@/lib/supabase/server";

// Miroir de _chargerNbFavoris / _chargerNbAlertes / _chargerNbMessagesNonLus /
// _chargerNbAvisEnAttente dans profil_screen.dart.
export type ProfilStats = {
  nbFavoris: number;
  nbAlertes: number;
  nbMessagesNonLus: number;
  nbAvisEnAttente: number;
};

export async function getProfilStats(userId: string, role: string): Promise<ProfilStats> {
  const supabase = await createClient();

  const [favorisRes, alertesRes, conversationsRes, avisRes] = await Promise.all([
    supabase.from("favoris").select("id", { count: "exact", head: true }).eq("user_id", userId),
    supabase.from("alertes_recherche").select("id", { count: "exact", head: true }).eq("user_id", userId),
    supabase.from("conversations").select("non_lu").contains("participants", [userId]),
    role === "vendeur"
      ? supabase
          .from("avis")
          .select("id", { count: "exact", head: true })
          .eq("cible_id", userId)
          .eq("valide", false)
          .not("annonce_id", "is", null)
      : Promise.resolve({ count: 0 }),
  ]);

  let nbMessagesNonLus = 0;
  for (const conv of conversationsRes.data ?? []) {
    const nonLu = conv.non_lu as Record<string, number> | null;
    if (nonLu && typeof nonLu[userId] === "number") nbMessagesNonLus += nonLu[userId];
  }

  return {
    nbFavoris: favorisRes.count ?? 0,
    nbAlertes: alertesRes.count ?? 0,
    nbMessagesNonLus,
    nbAvisEnAttente: avisRes.count ?? 0,
  };
}
