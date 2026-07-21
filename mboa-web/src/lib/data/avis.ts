import { createClient } from "@/lib/supabase/server";

export type Avis = {
  id: string;
  note: number;
  commentaire: string;
  datePublication: string;
  auteurNom: string;
};

// Un avis est visible s'il a été validé par sa cible, ou automatiquement
// après 72h sans action (miroir de _chargerAvis dans les écrans détail).
async function fetchAvis(column: "annonce_id" | "cible_id", id: string): Promise<Avis[]> {
  const supabase = await createClient();
  const cutoff = new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString();

  const { data, error } = await supabase
    .from("avis")
    .select("*, auteur:users!auteur_id(nom)")
    .eq(column, id)
    .or(`valide.eq.true,date_publication.lt.${cutoff}`)
    .order("date_publication", { ascending: false });

  if (error || !data) {
    console.error("fetchAvis", error?.message);
    return [];
  }

  return (data as Record<string, unknown>[]).map((row) => {
    const auteur = (row.auteur as Record<string, unknown> | null) ?? {};
    return {
      id: String(row.id ?? ""),
      note: Number(row.note ?? 0),
      commentaire: String(row.commentaire ?? ""),
      datePublication: String(row.date_publication ?? new Date().toISOString()),
      auteurNom: String(auteur.nom ?? "Utilisateur"),
    };
  });
}

export function getAvisAnnonce(annonceId: string): Promise<Avis[]> {
  return fetchAvis("annonce_id", annonceId);
}

export function getAvisUtilisateur(cibleId: string): Promise<Avis[]> {
  return fetchAvis("cible_id", cibleId);
}
