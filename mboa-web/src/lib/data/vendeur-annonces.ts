import { createClient } from "@/lib/supabase/server";

// Miroir de _chargerPermissions (publier_screen.dart) / _charger (gestion_screen.dart) :
// un compte vendeur peut avoir un ou deux sous-rôles combinés.
export type VendeurPermissions = {
  peutLogement: boolean;
  peutArticle: boolean;
  compteActifPublication: boolean;
};

export async function getVendeurPermissions(userId: string): Promise<VendeurPermissions> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("users")
    .select("sous_roles, compte_actif_publication")
    .eq("id", userId)
    .single();

  if (error || !data) {
    return { peutLogement: false, peutArticle: false, compteActifPublication: true };
  }

  const sousRoles: string[] = data.sous_roles ?? [];
  return {
    peutLogement: sousRoles.includes("proprietaire"),
    peutArticle: sousRoles.includes("commercant") || sousRoles.includes("vendeur_independant"),
    compteActifPublication: data.compte_actif_publication ?? true,
  };
}

export type MonLogement = {
  id: string;
  titre: string;
  prix: number;
  photos: string[];
  statut: string;
  statutModeration: string;
};

export type MonArticle = {
  id: string;
  titre: string;
  prix: number;
  photos: string[];
  statut: string;
  statutModeration: string;
};

export async function getMesAnnonces(
  userId: string,
  permissions: VendeurPermissions,
): Promise<{ logements: MonLogement[]; articles: MonArticle[] }> {
  const supabase = await createClient();

  const [logementsRes, articlesRes] = await Promise.all([
    permissions.peutLogement
      ? supabase
          .from("logements")
          .select("id, titre, prix, photos, statut, statut_moderation")
          .eq("proprietaire_id", userId)
          .order("date_publication", { ascending: false })
      : Promise.resolve({ data: [] }),
    permissions.peutArticle
      ? supabase
          .from("articles")
          .select("id, titre, prix, photos, statut, statut_moderation")
          .eq("vendeur_id", userId)
          .order("date_publication", { ascending: false })
      : Promise.resolve({ data: [] }),
  ]);

  type Row = {
    id: string;
    titre: string | null;
    prix: number | null;
    photos: string[] | null;
    statut: string | null;
    statut_moderation: string | null;
  };

  const map = (rows: Row[] | null | undefined) =>
    (rows ?? []).map((r) => ({
      id: r.id,
      titre: r.titre ?? "",
      prix: r.prix ?? 0,
      photos: r.photos ?? [],
      statut: r.statut ?? "disponible",
      statutModeration: r.statut_moderation ?? "publie",
    }));

  return {
    logements: map(logementsRes.data as Row[] | null),
    articles: map(articlesRes.data as Row[] | null),
  };
}

export type LogementAModifier = {
  id: string;
  titre: string;
  description: string;
  type: string;
  prix: number;
  surface: number | null;
  quartier: string | null;
  equipements: string[];
  photos: string[];
};

export async function getLogementAModifier(id: string, userId: string): Promise<LogementAModifier | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("logements")
    .select("id, titre, description, type, prix, surface, quartier, equipements, photos, proprietaire_id")
    .eq("id", id)
    .single();

  if (error || !data || data.proprietaire_id !== userId) return null;

  return {
    id: data.id,
    titre: data.titre ?? "",
    description: data.description ?? "",
    type: data.type ?? "Chambre",
    prix: data.prix ?? 0,
    surface: data.surface ?? null,
    quartier: data.quartier ?? null,
    equipements: data.equipements ?? [],
    photos: data.photos ?? [],
  };
}

export type ArticleAModifier = {
  id: string;
  titre: string;
  description: string;
  categorie: string;
  etat: string;
  prix: number;
  negociable: boolean;
  accepteAvis: boolean;
  photos: string[];
};

export async function getArticleAModifier(id: string, userId: string): Promise<ArticleAModifier | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("articles")
    .select("id, titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id")
    .eq("id", id)
    .single();

  if (error || !data || data.vendeur_id !== userId) return null;

  return {
    id: data.id,
    titre: data.titre ?? "",
    description: data.description ?? "",
    categorie: data.categorie ?? "Literie",
    etat: data.etat ?? "Bon état",
    prix: data.prix ?? 0,
    negociable: data.negociable === true,
    accepteAvis: data.accepte_avis === true,
    photos: data.photos ?? [],
  };
}
