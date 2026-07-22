import { createClient } from "@/lib/supabase/server";

export type LogementProcheFull = {
  id: string;
  titre: string;
  prix: number;
  quartier: string | null;
  photos: string[];
  distanceKm: number;
};

export type ArticleProcheFull = {
  id: string;
  titre: string;
  prix: number;
  photos: string[];
  distanceKm: number;
};

export async function getLogementsProches(
  lat: number,
  lng: number,
  rayonKm: number,
): Promise<LogementProcheFull[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("logements_proches", {
    p_lat: lat,
    p_lng: lng,
    p_rayon_km: rayonKm,
  });

  if (error || !data) {
    console.error("getLogementsProches", error?.message);
    return [];
  }

  return (data as Record<string, unknown>[]).map((row) => ({
    id: String(row.id ?? ""),
    titre: String(row.titre ?? ""),
    prix: Number(row.prix ?? 0),
    quartier: row.quartier ? String(row.quartier) : null,
    photos: Array.isArray(row.photos) ? (row.photos as string[]) : [],
    distanceKm: Number(row.distance_km ?? 0),
  }));
}

export async function getArticlesProches(
  lat: number,
  lng: number,
  rayonKm: number,
): Promise<ArticleProcheFull[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("articles_proches", {
    p_lat: lat,
    p_lng: lng,
    p_rayon_km: rayonKm,
  });

  if (error || !data) {
    console.error("getArticlesProches", error?.message);
    return [];
  }

  return (data as Record<string, unknown>[]).map((row) => ({
    id: String(row.id ?? ""),
    titre: String(row.titre ?? ""),
    prix: Number(row.prix ?? 0),
    photos: Array.isArray(row.photos) ? (row.photos as string[]) : [],
    distanceKm: Number(row.distance_km ?? 0),
  }));
}
