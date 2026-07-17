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
  static const String tableModerationIa   = 'moderation_ia';
  static const String tableImageHashes    = 'image_hashes';
  static const String tableVerificationsTerrain    = 'verifications_terrain';
  static const String tableAttestationsAccesLog    = 'attestations_acces_log';

  // ── Storage Supabase (buckets) ────────────────────────────
  static const String bucketLogements     = 'logements';
  static const String bucketArticles      = 'articles';
  static const String bucketProfils       = 'profils';
  static const String bucketBoutiques     = 'boutiques';
  static const String bucketAttestations  = 'attestations-proprietaires';

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

  // ── Catégories de lieux publics (ajoutés par l'admin sur la carte) ──
  static const List<Map<String, dynamic>> categoriesLieuxPublics = [
    {'valeur': 'ecole',        'label': 'École',        'icon': '🎓', 'color': 0xFF2D6A4F},
    {'valeur': 'eglise',       'label': 'Église',       'icon': '⛪', 'color': 0xFFF4A261},
    {'valeur': 'hopital',      'label': 'Hôpital',      'icon': '🏥', 'color': 0xFFEF4444},
    {'valeur': 'marche',       'label': 'Marché',       'icon': '🛒', 'color': 0xFFF4A261},
    {'valeur': 'pharmacie',    'label': 'Pharmacie',    'icon': '💊', 'color': 0xFF10B981},
    {'valeur': 'commissariat', 'label': 'Commissariat', 'icon': '🚔', 'color': 0xFF1A1A2E},
    {'valeur': 'autre',        'label': 'Autre',        'icon': '📍', 'color': 0xFF6B7280},
  ];

  // ── Rayons de recherche autour d'un lieu (km) ─────────────
  static const List<double> rayonsRechercheKm = [0.5, 1, 1.5, 2, 3, 5];

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
  static const String roleAmbassadeur  = 'ambassadeur';

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

  // Raison utilisée par l'Edge Function moderate-annonce pour les
  // signalements générés automatiquement (non choisie dans raisonsSignalement,
  // qui reste réservée aux signalements saisis par un utilisateur).
  static const String raisonDetectionIa = 'detection_ia';

  // ── Statuts de modération IA (Partie 1) ───────────────────
  static const String statutModerationEnAttente = 'en_attente';
  static const String statutModerationPublie    = 'publie';
  static const String statutModerationAVerifier = 'a_verifier';
  static const String statutModerationBloque    = 'bloque';

  // ── Statuts de vérification terrain (Partie 2) ────────────
  static const String statutVerificationEnAttenteAssignation = 'en_attente_assignation';
  static const String statutVerificationAssignee              = 'assignee';
  static const String statutVerificationVisiteEffectuee        = 'visite_effectuee';
  static const String statutVerificationValidee                = 'validee';
  static const String statutVerificationRejetee                = 'rejetee';

  // ── Types de justificatif (jamais le numéro de pièce en clair) ──
  static const List<String> typesJustificatif = [
    'Carte Nationale d\'Identité',
    'Passeport',
    'Titre de propriété',
    'Acte de vente',
    'Autre document officiel',
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

  // ── Nombre de colonnes de grille selon la largeur d'écran ──
  static int gridColumns(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }
}