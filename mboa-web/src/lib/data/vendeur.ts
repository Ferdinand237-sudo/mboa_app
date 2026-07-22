import { createClient } from "@/lib/supabase/server";
import { userFromRow, logementFromRow, articleFromRow, type UserModel, type LogementModel, type ArticleModel } from "@/lib/types/models";

export type VendeurProfil = {
  user: UserModel;
  logements: LogementModel[];
  articles: ArticleModel[];
};

export async function getVendeurProfil(id: string): Promise<VendeurProfil | null> {
  const supabase = await createClient();

  const [userRes, logementsRes, articlesRes] = await Promise.all([
    supabase.from("users").select().eq("id", id).single(),
    supabase
      .from("logements")
      .select("*, proprietaire:users!proprietaire_id(nom, verified, note_globale, nb_avis)")
      .eq("proprietaire_id", id)
      .eq("statut", "disponible")
      .order("date_publication", { ascending: false }),
    supabase
      .from("articles")
      .select("*, vendeur:users!vendeur_id(nom, verified)")
      .eq("vendeur_id", id)
      .eq("statut", "disponible")
      .order("date_publication", { ascending: false }),
  ]);

  if (userRes.error || !userRes.data) return null;

  return {
    user: userFromRow(userRes.data),
    logements: (logementsRes.data ?? []).map(logementFromRow),
    articles: (articlesRes.data ?? []).map(articleFromRow),
  };
}
