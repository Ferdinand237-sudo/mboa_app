class AppConstants {
  AppConstants._();

  // ── Nom de l'application ──────────────────────────────────
  static const String appName        = 'Mboa';
  static const String appSlogan      = 'Ton premier ami dans une nouvelle ville';
  static const String appVersion     = '1.0.0';

  // ── Supabase ──────────────────────────────────────────────
  // Tu remplaceras ces valeurs après la config Supabase
  static const String supabaseUrl     = 'https://vodmsndqahmxdsqpayrd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvZG1zbmRxYWhteGRzcXBheXJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwNjAzNTQsImV4cCI6MjA5OTYzNjM1NH0.6htojTsGc1EfSZygNrFq4I7tvv8k8vmhnATdofVEM6I';

  // ── Ville par défaut ──────────────────────────────────────
  static const String defaultVille   = 'Sangmelima';
  static const double defaultLat     = 2.9333;
  static const double defaultLng     = 11.9833;

  // ── Collections Supabase (tables) ─────────────────────────
  static const String tableUsers          = 'users';
  static const String tableLogements      = 'logements';
  static const String tableArticles       = 'articles';
  static const String tableConversations  = 'conversations';
  static const String tableMessages       = 'messages';
  static const String tableAvis           = 'avis';
  static const String tableSignalements   = 'signalements';

  // ── Storage Supabase (buckets) ────────────────────────────
  static const String bucketLogements     = 'logements';
  static const String bucketArticles      = 'articles';
  static const String bucketProfils       = 'profils';
  static const String bucketBoutiques     = 'boutiques';

  // ── Pagination ────────────────────────────────────────────
  static const int pageSize              = 10;
  static const int pageSizeVisiteur      = 4;

  // ── Règles métier ─────────────────────────────────────────
  static const int maxPhotosLogement     = 10;
  static const int minPhotosLogement     = 3;
  static const int maxPhotosArticle      = 5;
  static const int minPhotosArticle      = 1;
  static const int seuilSignalement      = 5;
  static const int maxAnnoncesParJour    = 5;
  static const int joursAvantExpiration  = 60;
  static const double tailleMaxImageMb   = 5.0;

  // ── Points d'intérêt par défaut ───────────────────────────
  static const List<Map<String, dynamic>> pointsInteret = [
    {'label': 'Campus IUT',       'icon': '🎓', 'type': 'campus'},
    {'label': 'Hôpital District', 'icon': '🏥', 'type': 'hopital'},
    {'label': 'Grand Marché',     'icon': '🛒', 'type': 'marche'},
    {'label': 'Commissariat',     'icon': '🚔', 'type': 'police'},
    {'label': 'Pharmacie',        'icon': '💊', 'type': 'pharmacie'},
  ];

  // ── Types de logement ─────────────────────────────────────
  static const List<String> typesLogement = [
    'Chambre',
    'Studio',
    'Appartement',
  ];

  // ── Équipements disponibles ───────────────────────────────
  static const List<Map<String, String>> equipements = [
    {'label': 'Wifi',        'icon': '📶'},
    {'label': 'Eau courante','icon': '🚿'},
    {'label': 'Électricité', 'icon': '💡'},
    {'label': 'Meublé',      'icon': '🪑'},
    {'label': 'Cuisine',     'icon': '🍳'},
    {'label': 'Salon',       'icon': '🛋'},
    {'label': 'Sécurité',    'icon': '🔒'},
    {'label': 'Parking',     'icon': '🚗'},
  ];

  // ── Catégories Marketplace ────────────────────────────────
  static const List<Map<String, String>> categoriesMarket = [
    {'label': 'Literie',      'icon': '🛏'},
    {'label': 'Mobilier',     'icon': '🪑'},
    {'label': 'Cuisine',      'icon': '🍳'},
    {'label': 'Électronique', 'icon': '💨'},
    {'label': 'Scolaire',     'icon': '📚'},
    {'label': 'Divers',       'icon': '📦'},
  ];

  // ── États des articles ────────────────────────────────────
  static const List<String> etatsArticle = [
    'Neuf',
    'Très bon état',
    'Bon état',
    'Correct',
  ];

  // ── Rôles utilisateurs ────────────────────────────────────
  static const String roleVisiteur     = 'visiteur';
  static const String roleVendeur      = 'vendeur';
  static const String roleAdmin        = 'admin';

  // ── Sous-rôles vendeur ────────────────────────────────────
  static const String sousRoleProprietaire       = 'proprietaire';
  static const String sousRoleCommercant         = 'commercant';
  static const String sousRoleVendeurIndependant = 'vendeur_independant';

  // ── Statuts annonces ──────────────────────────────────────
  static const String statutDisponible  = 'disponible';
  static const String statutReserve     = 'reserve';
  static const String statutLoue        = 'loue';
  static const String statutVendu       = 'vendu';

  // ── Raisons de signalement ───────────────────────────────
  static const List<String> raisonsSignalement = [
    'Fausse annonce',
    'Arnaque',
    'Contenu inapproprié',
    'Prix incorrect',
    'Annonce dupliquée',
    'Autre',
  ];

  // ── Prix min/max filtre ───────────────────────────────────
  static const double prixMin = 5000;
  static const double prixMax = 200000;

  // ── Distances filtre ──────────────────────────────────────
  static const List<Map<String, dynamic>> filtresDistance = [
    {'label': 'Moins de 500m', 'valeur': 500},
    {'label': 'Moins de 1km',  'valeur': 1000},
    {'label': 'Moins de 2km',  'valeur': 2000},
    {'label': 'Toutes',        'valeur': 0},
  ];
}