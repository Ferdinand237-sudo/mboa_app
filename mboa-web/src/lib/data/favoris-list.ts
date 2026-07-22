import { createClient } from "@/lib/supabase/server";

// Miroir de _chargerFavoris (favoris_screen.dart).
export type FavoriItem = {
  type: "logement" | "article";
  id: string;
  titre: string;
  prix: number;
  photos: string[];
  sousTitre: string;
  verified: boolean;
};

type FavoriRow = {
  logement:
    | { id: string; titre: string; prix: number; photos: string[] | null; quartier: string | null; proprietaire: { verified: boolean } | null }
    | null;
  article:
    | { id: string; titre: string; prix: number; photos: string[] | null; etat: string | null; vendeur: { verified: boolean } | null }
    | null;
};

export async function getFavoris(userId: string): Promise<FavoriItem[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("favoris")
    .select(
      "logement:logements(id, titre, prix, photos, quartier, proprietaire:users!proprietaire_id(verified)), article:articles(id, titre, prix, photos, etat, vendeur:users!vendeur_id(verified))",
    )
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error || !data) {
    console.error("getFavoris", error?.message);
    return [];
  }

  const items: FavoriItem[] = [];
  for (const row of data as unknown as FavoriRow[]) {
    if (row.logement) {
      items.push({
        type: "logement",
        id: row.logement.id,
        titre: row.logement.titre,
        prix: row.logement.prix,
        photos: row.logement.photos ?? [],
        sousTitre: row.logement.quartier ?? "Sangmelima",
        verified: row.logement.proprietaire?.verified === true,
      });
    } else if (row.article) {
      items.push({
        type: "article",
        id: row.article.id,
        titre: row.article.titre,
        prix: row.article.prix,
        photos: row.article.photos ?? [],
        sousTitre: row.article.etat ?? "",
        verified: row.article.vendeur?.verified === true,
      });
    }
  }
  return items;
}
