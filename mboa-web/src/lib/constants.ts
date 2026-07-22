// Constantes métier — miroir de lib/core/constants/app_constants.dart
// Gardées synchronisées avec l'app Flutter : mêmes tables, mêmes règles.

export const APP_NAME = "Mboa";
export const APP_SLOGAN = "Ton premier ami dans une nouvelle ville";

export const DEFAULT_VILLE = "Sangmelima";
export const DEFAULT_LAT = 2.9333;
export const DEFAULT_LNG = 11.9833;

export const TABLE_USERS = "users";
export const TABLE_LOGEMENTS = "logements";
export const TABLE_ARTICLES = "articles";
export const TABLE_AVIS = "avis";

export const BUCKET_LOGEMENTS = "logements";
export const BUCKET_ARTICLES = "articles";
export const BUCKET_PROFILS = "profils";
export const BUCKET_BOUTIQUES = "boutiques";

export const PAGE_SIZE = 10;
export const PAGE_SIZE_VISITEUR = 4;

export const TYPES_LOGEMENT = ["Chambre", "Studio", "Appartement"] as const;

export const EQUIPEMENTS: { label: string; icon: string }[] = [
  { label: "Wifi", icon: "📶" },
  { label: "Eau courante", icon: "🚿" },
  { label: "Électricité", icon: "💡" },
  { label: "Meublé", icon: "🪑" },
  { label: "Cuisine", icon: "🍳" },
  { label: "Salon", icon: "🛋" },
  { label: "Sécurité", icon: "🔒" },
  { label: "Parking", icon: "🚗" },
];

export const CATEGORIES_MARKET: { label: string; icon: string }[] = [
  { label: "Literie", icon: "🛏" },
  { label: "Mobilier", icon: "🪑" },
  { label: "Cuisine", icon: "🍳" },
  { label: "Électronique", icon: "💨" },
  { label: "Scolaire", icon: "📚" },
  { label: "Divers", icon: "📦" },
];

export const ETATS_ARTICLE = ["Neuf", "Très bon état", "Bon état", "Correct"] as const;

export const PRIX_MIN = 5000;
export const PRIX_MAX = 200000;

export const ROLE_VISITEUR = "visiteur";
export const ROLE_VENDEUR = "vendeur";
export const ROLE_ADMIN = "admin";
export const ROLE_AMBASSADEUR = "ambassadeur";

// Miroir de _categorieStyleProximite dans logement_detail_screen.dart.
export const CATEGORIE_STYLE_PROXIMITE: Record<string, { icon: string; color: string }> = {
  ecole: { icon: "🎓", color: "#2D6A4F" },
  hopital: { icon: "🏥", color: "#EF4444" },
  marche: { icon: "🛒", color: "#F4A261" },
  pharmacie: { icon: "💊", color: "#10B981" },
  eglise: { icon: "⛪", color: "#6B7280" },
  autre: { icon: "📍", color: "#1A1A2E" },
};
