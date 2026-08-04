import { createClient } from "@/lib/supabase/server";
import { logementFromRow, articleFromRow, type LogementModel, type ArticleModel } from "@/lib/types/models";

// Miroir exact des requêtes de home_screen.dart : ordre, filtres et
// limites identiques pour que l'accueil web affiche les mêmes annonces
// que l'app mobile.

const SELECT_LOGEMENT_HOME =
  "*, proprietaire:users!proprietaire_id(nom, verified, note_globale, nb_avis)";
const SELECT_ARTICLE_HOME = "*, vendeur:users!vendeur_id(nom, verified)";

export async function getHomeLogements(ville: string): Promise<LogementModel[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("logements")
    .select(SELECT_LOGEMENT_HOME)
    .eq("statut", "disponible")
    .eq("statut_moderation", "publie")
    .eq("ville", ville)
    .order("boosted", { ascending: false })
    .order("date_publication", { ascending: false })
    .limit(6);

  if (error) {
    console.error("getHomeLogements", error.message);
    return [];
  }
  return (data ?? []).map(logementFromRow);
}

export async function getHomeArticles(ville: string): Promise<ArticleModel[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("articles")
    .select(SELECT_ARTICLE_HOME)
    .eq("statut", "disponible")
    .eq("statut_moderation", "publie")
    .contains("ville", [ville])
    .order("boosted", { ascending: false })
    .order("date_publication", { ascending: false })
    .limit(6);

  if (error) {
    console.error("getHomeArticles", error.message);
    return [];
  }
  return (data ?? []).map(articleFromRow);
}

export type Contributeur = {
  id: string;
  nom: string;
  verified: boolean;
  boosted: boolean;
  noteGlobale: number;
};

export async function getContributeurs(): Promise<Contributeur[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("users")
    .select("id, nom, verified, boosted, note_globale")
    .eq("role", "vendeur")
    .eq("actif", true)
    .order("verified", { ascending: false })
    .order("boosted", { ascending: false })
    .order("note_globale", { ascending: false })
    .limit(8);

  if (error) {
    console.error("getContributeurs", error.message);
    return [];
  }
  return (data ?? []).map((row) => ({
    id: String(row.id ?? ""),
    nom: String(row.nom ?? "Vendeur"),
    verified: Boolean(row.verified),
    boosted: Boolean(row.boosted),
    noteGlobale: Number(row.note_globale ?? 0),
  }));
}

export type LieuPublic = {
  id: string;
  nom: string;
  categorie: string;
  lat: number;
  lng: number;
};

// ville omise : utilisé par la page détail d'un logement (proximité
// calculée par distance réelle à son lat/lng, la ville importe peu tant
// que la distance filtre déjà les résultats pertinents) — voir
// logements/[id]/page.tsx, seul appelant sans ville explicite.
export async function getLieuxPublics(ville?: string): Promise<LieuPublic[]> {
  const supabase = await createClient();
  let query = supabase.from("lieux_publics").select("id, nom, categorie, lat, lng");
  if (ville) query = query.eq("ville", ville);
  const { data, error } = await query.order("nom");

  if (error) {
    console.error("getLieuxPublics", error.message);
    return [];
  }
  return (data ?? []).map((row) => ({
    id: String(row.id ?? ""),
    nom: String(row.nom ?? ""),
    categorie: String(row.categorie ?? "autre"),
    lat: Number(row.lat ?? 0),
    lng: Number(row.lng ?? 0),
  }));
}
