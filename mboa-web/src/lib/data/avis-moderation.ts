import { createClient } from "@/lib/supabase/server";

// Miroir de _charger (avis_moderation_screen.dart) : annonce_id n'a pas de
// FK unique (logement ou article), donc les titres sont récupérés à part
// plutôt que via une jointure.
export type AvisAModerer = {
  id: string;
  auteurNom: string;
  note: number;
  commentaire: string;
  titreAnnonce: string | null;
};

export async function getAvisAModerer(userId: string): Promise<AvisAModerer[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("avis")
    .select("id, note, commentaire, annonce_id, auteur:users!auteur_id(nom)")
    .eq("cible_id", userId)
    .eq("valide", false)
    .not("annonce_id", "is", null)
    .order("date_publication", { ascending: false });

  if (error || !data) {
    console.error("getAvisAModerer", error?.message);
    return [];
  }

  type Row = {
    id: string;
    note: number | null;
    commentaire: string | null;
    annonce_id: string | null;
    auteur: { nom: string | null } | null;
  };
  const rows = data as unknown as Row[];

  const annonceIds = [...new Set(rows.map((r) => r.annonce_id).filter((id): id is string => !!id))];
  const titres = new Map<string, string>();
  if (annonceIds.length > 0) {
    const [logements, articles] = await Promise.all([
      supabase.from("logements").select("id, titre").in("id", annonceIds),
      supabase.from("articles").select("id, titre").in("id", annonceIds),
    ]);
    for (const l of logements.data ?? []) titres.set(l.id, l.titre ?? "");
    for (const a of articles.data ?? []) titres.set(a.id, a.titre ?? "");
  }

  return rows.map((r) => ({
    id: r.id,
    auteurNom: r.auteur?.nom ?? "Utilisateur",
    note: r.note ?? 0,
    commentaire: r.commentaire ?? "",
    titreAnnonce: r.annonce_id ? titres.get(r.annonce_id) ?? null : null,
  }));
}
