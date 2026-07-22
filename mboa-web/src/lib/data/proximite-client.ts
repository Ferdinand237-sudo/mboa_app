import { createClient } from "@/lib/supabase/client";

// Appelé côté navigateur (géolocalisation + RPC) depuis le composant
// client "Trouve ton Mboa" — miroir de _rechercherProches dans
// home_screen.dart (RPC logements_proches).
export type LogementProche = {
  id: string;
  titre: string;
  prix: number;
  photos: string[];
  distanceKm: number;
};

export async function fetchLogementsProches(
  lat: number,
  lng: number,
  rayonKm: number,
): Promise<LogementProche[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("logements_proches", {
    p_lat: lat,
    p_lng: lng,
    p_rayon_km: rayonKm,
  });

  if (error || !data) {
    console.error("fetchLogementsProches", error?.message);
    return [];
  }

  return (data as Record<string, unknown>[]).slice(0, 8).map((row) => ({
    id: String(row.id ?? ""),
    titre: String(row.titre ?? ""),
    prix: Number(row.prix ?? 0),
    photos: Array.isArray(row.photos) ? (row.photos as string[]) : [],
    distanceKm: Number(row.distance_km ?? 0),
  }));
}
