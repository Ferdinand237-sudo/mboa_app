// Types miroir de lib/core/models/*.dart — mêmes noms de colonnes Supabase
// (snake_case côté base, camelCase côté TS) pour que web et mobile lisent
// exactement les mêmes tables.

export type SupabaseRow = Record<string, unknown>;

function str(v: unknown, fallback = ""): string {
  return typeof v === "string" ? v : fallback;
}
function strOrNull(v: unknown): string | null {
  return typeof v === "string" ? v : null;
}
function num(v: unknown, fallback = 0): number {
  return v == null ? fallback : Number(v as string | number);
}
function numOrNull(v: unknown): number | null {
  return v == null ? null : Number(v as string | number);
}
function bool(v: unknown, fallback = false): boolean {
  return typeof v === "boolean" ? v : fallback;
}
function strArr(v: unknown): string[] {
  return Array.isArray(v) ? v.map(String) : [];
}
function obj(v: unknown): SupabaseRow {
  return v && typeof v === "object" ? (v as SupabaseRow) : {};
}

export type UserModel = {
  id: string;
  nom: string;
  email: string;
  telephone: string | null;
  photoUrl: string | null;
  role: string;
  sousRoles: string[];
  verified: boolean;
  boosted: boolean;
  dateInscription: string;
  actif: boolean;
  noteGlobale: number;
  nbAvis: number;
  nomCommerce: string | null;
  descriptionCommerce: string | null;
  photoCommerce: string | null;
  emplacementCommerce: string | null;
  lat: number | null;
  lng: number | null;
};

export function userFromRow(row: SupabaseRow): UserModel {
  return {
    id: str(row.id),
    nom: str(row.nom),
    email: str(row.email),
    telephone: strOrNull(row.telephone),
    photoUrl: strOrNull(row.photo_url),
    role: str(row.role, "visiteur"),
    sousRoles: strArr(row.sous_roles),
    verified: bool(row.verified),
    boosted: bool(row.boosted),
    dateInscription: str(row.date_inscription, new Date().toISOString()),
    actif: bool(row.actif, true),
    noteGlobale: num(row.note_globale),
    nbAvis: num(row.nb_avis),
    nomCommerce: strOrNull(row.nom_commerce),
    descriptionCommerce: strOrNull(row.description_commerce),
    photoCommerce: strOrNull(row.photo_commerce),
    emplacementCommerce: strOrNull(row.emplacement_commerce),
    lat: numOrNull(row.lat),
    lng: numOrNull(row.lng),
  };
}

export type LogementModel = {
  id: string;
  titre: string;
  description: string;
  type: string;
  prix: number;
  surface: number | null;
  photos: string[];
  equipements: string[];
  regles: string[];
  disponibleLe: string | null;
  statut: string;
  statutModeration: string;
  adresseApprox: string | null;
  quartier: string | null;
  ville: string;
  lat: number | null;
  lng: number | null;
  proprietaireId: string;
  proprietaireNom: string | null;
  proprietairePhoto: string | null;
  proprietaireVerified: boolean;
  boosted: boolean;
  vues: number;
  signalements: number;
  noteGlobale: number;
  nbAvis: number;
  datePublication: string;
};

export function logementFromRow(row: SupabaseRow): LogementModel {
  const proprietaire = obj(row.proprietaire);
  return {
    id: str(row.id),
    titre: str(row.titre),
    description: str(row.description),
    type: str(row.type, "Chambre"),
    prix: num(row.prix),
    surface: numOrNull(row.surface),
    photos: strArr(row.photos),
    equipements: strArr(row.equipements),
    regles: strArr(row.regles),
    disponibleLe: strOrNull(row.disponible_le),
    statut: str(row.statut, "disponible"),
    statutModeration: str(row.statut_moderation, "publie"),
    adresseApprox: strOrNull(row.adresse_approx),
    quartier: strOrNull(row.quartier),
    ville: str(row.ville, "Sangmelima"),
    lat: numOrNull(row.lat),
    lng: numOrNull(row.lng),
    proprietaireId: str(row.proprietaire_id),
    proprietaireNom: strOrNull(row.proprietaire_nom) ?? strOrNull(proprietaire.nom),
    proprietairePhoto:
      strOrNull(row.proprietaire_photo) ?? strOrNull(proprietaire.photo_url),
    proprietaireVerified:
      row.proprietaire_verified != null
        ? bool(row.proprietaire_verified)
        : bool(proprietaire.verified),
    boosted: bool(row.boosted),
    vues: num(row.vues),
    signalements: num(row.signalements),
    noteGlobale: num(row.note_globale),
    nbAvis: num(row.nb_avis),
    datePublication: str(row.date_publication, new Date().toISOString()),
  };
}

export type ArticleModel = {
  id: string;
  titre: string;
  description: string;
  categorie: string;
  etat: string;
  prix: number;
  negociable: boolean;
  photos: string[];
  vendeurId: string;
  vendeurNom: string | null;
  vendeurPhoto: string | null;
  vendeurVerified: boolean;
  vendeurNote: number;
  statut: string;
  statutModeration: string;
  lat: number | null;
  lng: number | null;
  boosted: boolean;
  vues: number;
  signalements: number;
  datePublication: string;
};

export function articleFromRow(row: SupabaseRow): ArticleModel {
  const vendeur = obj(row.vendeur);
  return {
    id: str(row.id),
    titre: str(row.titre),
    description: str(row.description),
    categorie: str(row.categorie, "Divers"),
    etat: str(row.etat, "Bon état"),
    prix: num(row.prix),
    negociable: bool(row.negociable),
    photos: strArr(row.photos),
    vendeurId: str(row.vendeur_id),
    vendeurNom: strOrNull(row.vendeur_nom) ?? strOrNull(vendeur.nom),
    vendeurPhoto: strOrNull(row.vendeur_photo) ?? strOrNull(vendeur.photo_url),
    vendeurVerified:
      row.vendeur_verified != null
        ? bool(row.vendeur_verified)
        : bool(vendeur.verified),
    vendeurNote: num(row.vendeur_note ?? vendeur.note_globale),
    statut: str(row.statut, "disponible"),
    statutModeration: str(row.statut_moderation, "publie"),
    lat: numOrNull(row.lat),
    lng: numOrNull(row.lng),
    boosted: bool(row.boosted),
    vues: num(row.vues),
    signalements: num(row.signalements),
    datePublication: str(row.date_publication, new Date().toISOString()),
  };
}
