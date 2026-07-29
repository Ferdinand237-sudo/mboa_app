import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { DEFAULT_VILLE, DEFAULT_LAT, DEFAULT_LNG } from "@/lib/constants";

// Miroir de VilleService (lib/core/services/ville_service.dart) : la ville
// sélectionnée est persistée dans un cookie (`mboa_ville`) plutôt qu'en
// SharedPreferences, lu ici côté serveur pour filtrer les données avant le
// premier rendu. Voir villes/actions.ts pour l'écriture du cookie.
export const VILLE_COOKIE = "mboa_ville";

export type VilleModel = {
  id: string;
  nom: string;
  lat: number;
  lng: number;
  rayonCouvertureKm: number;
  actif: boolean;
  ordreAffichage: number;
};

function villeFromRow(row: Record<string, unknown>): VilleModel {
  return {
    id: String(row.id ?? ""),
    nom: String(row.nom ?? DEFAULT_VILLE),
    lat: Number(row.lat ?? DEFAULT_LAT),
    lng: Number(row.lng ?? DEFAULT_LNG),
    rayonCouvertureKm: Number(row.rayon_couverture_km ?? 30),
    actif: row.actif !== false,
    ordreAffichage: Number(row.ordre_affichage ?? 0),
  };
}

// Villes actives, pour le sélecteur public et la détection GPS — jamais de
// liste figée dans le code, une ville ajoutée par l'admin doit apparaître
// sans déploiement (voir HISTORIQUE_PROJET_MBOA.md §5bis).
export async function getVilles(): Promise<VilleModel[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("villes")
    .select("id, nom, lat, lng, rayon_couverture_km, actif, ordre_affichage")
    .eq("actif", true)
    .order("ordre_affichage");

  if (error) {
    console.error("getVilles", error.message);
    return [];
  }
  return (data ?? []).map(villeFromRow);
}

// Toutes les villes (actives et désactivées), pour /admin/villes.
export async function getToutesLesVilles(): Promise<VilleModel[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("villes")
    .select("id, nom, lat, lng, rayon_couverture_km, actif, ordre_affichage")
    .order("ordre_affichage");

  if (error) {
    console.error("getToutesLesVilles", error.message);
    return [];
  }
  return (data ?? []).map(villeFromRow);
}

// Ville courante côté serveur : cookie si présent et toujours actif, sinon
// la première ville active par ordre d'affichage (repli déterministe côté
// SSR — contrairement au mobile, le serveur ne peut pas géolocaliser ;
// c'est VilleAutoDetect, côté client, qui affine ce choix au premier
// chargement et persiste le résultat dans le cookie).
export async function getVilleActuelle(): Promise<{ ville: VilleModel; cookiePresent: boolean }> {
  const villes = await getVilles();
  const repli =
    villes[0] ?? { id: "", nom: DEFAULT_VILLE, lat: DEFAULT_LAT, lng: DEFAULT_LNG, rayonCouvertureKm: 30, actif: true, ordreAffichage: 0 };

  const cookieStore = await cookies();
  const nomCookie = cookieStore.get(VILLE_COOKIE)?.value;
  if (!nomCookie) return { ville: repli, cookiePresent: false };

  const trouvee = villes.find((v) => v.nom === nomCookie);
  return { ville: trouvee ?? repli, cookiePresent: true };
}
