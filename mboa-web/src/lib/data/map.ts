import { createClient } from "@/lib/supabase/server";

// Miroir de _chargerDonnees (map_screen.dart) : uniquement les logements
// géolocalisés, publiés et disponibles.
export type MapLogement = {
  id: string;
  titre: string;
  type: string;
  prix: number;
  quartier: string | null;
  ville: string;
  photos: string[];
  lat: number;
  lng: number;
  boosted: boolean;
  proprietaireVerified: boolean;
};

export type MapLieu = {
  id: string;
  nom: string;
  categorie: string;
  lat: number;
  lng: number;
};

export async function getMapData(ville: string): Promise<{ logements: MapLogement[]; lieuxPublics: MapLieu[] }> {
  const supabase = await createClient();

  const [logementsRes, lieuxRes] = await Promise.all([
    supabase
      .from("logements")
      .select("id, titre, type, prix, quartier, ville, photos, lat, lng, boosted, proprietaire:users!proprietaire_id(verified)")
      .eq("statut", "disponible")
      .eq("statut_moderation", "publie")
      .eq("ville", ville)
      .not("lat", "is", null)
      .not("lng", "is", null),
    supabase.from("lieux_publics").select("id, nom, categorie, lat, lng").eq("ville", ville),
  ]);

  type LogementRow = {
    id: string;
    titre: string | null;
    type: string | null;
    prix: number | null;
    quartier: string | null;
    ville: string | null;
    photos: string[] | null;
    lat: number | null;
    lng: number | null;
    boosted: boolean | null;
    proprietaire: { verified: boolean } | null;
  };

  const logements = ((logementsRes.data ?? []) as unknown as LogementRow[])
    .filter((l) => l.lat != null && l.lng != null)
    .map((l) => ({
      id: l.id,
      titre: l.titre ?? "",
      type: l.type ?? "Chambre",
      prix: l.prix ?? 0,
      quartier: l.quartier,
      ville: l.ville ?? ville,
      photos: l.photos ?? [],
      lat: l.lat as number,
      lng: l.lng as number,
      boosted: l.boosted === true,
      proprietaireVerified: l.proprietaire?.verified === true,
    }));

  const lieuxPublics = (lieuxRes.data ?? []).map((l) => ({
    id: String(l.id),
    nom: l.nom ?? "",
    categorie: l.categorie ?? "autre",
    lat: Number(l.lat),
    lng: Number(l.lng),
  }));

  return { logements, lieuxPublics };
}
