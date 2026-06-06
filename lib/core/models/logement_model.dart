class LogementModel {
  final String id;
  final String titre;
  final String description;
  final String type;
  final double prix;
  final double? surface;
  final List<String> photos;
  final List<String> equipements;
  final List<String> regles;
  final DateTime? disponibleLe;
  final String statut;

  // Localisation
  final String? adresseApprox;
  final String? quartier;
  final String ville;
  final double? lat;
  final double? lng;

  // Propriétaire
  final String proprietaireId;
  final String? proprietaireNom;
  final String? proprietairePhoto;
  final bool proprietaireVerified;

  // Stats
  final bool boosted;
  final int vues;
  final int signalements;
  final double noteGlobale;
  final int nbAvis;
  final DateTime datePublication;

  LogementModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.type,
    required this.prix,
    this.surface,
    this.photos = const [],
    this.equipements = const [],
    this.regles = const [],
    this.disponibleLe,
    this.statut = 'disponible',
    this.adresseApprox,
    this.quartier,
    this.ville = 'Sangmelima',
    this.lat,
    this.lng,
    required this.proprietaireId,
    this.proprietaireNom,
    this.proprietairePhoto,
    this.proprietaireVerified = false,
    this.boosted = false,
    this.vues = 0,
    this.signalements = 0,
    this.noteGlobale = 0.0,
    this.nbAvis = 0,
    required this.datePublication,
  });

  // ── Getters utiles ────────────────────────────────────────
  bool get isDisponible => statut == 'disponible';
  bool get isReserve    => statut == 'reserve';
  bool get isLoue       => statut == 'loue';

  String get prixFormate =>
      '${prix.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  String get photoprincipale =>
      photos.isNotEmpty ? photos.first : '';

  // ── Depuis Supabase ───────────────────────────────────────
  factory LogementModel.fromMap(Map<String, dynamic> map) {
    return LogementModel(
      id: map['id'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'Chambre',
      prix: (map['prix'] ?? 0).toDouble(),
      surface: map['surface'] != null ? (map['surface']).toDouble() : null,
      photos: map['photos'] != null ? List<String>.from(map['photos']) : [],
      equipements: map['equipements'] != null
          ? List<String>.from(map['equipements'])
          : [],
      regles: map['regles'] != null ? List<String>.from(map['regles']) : [],
      disponibleLe: map['disponible_le'] != null
          ? DateTime.parse(map['disponible_le'])
          : null,
      statut: map['statut'] ?? 'disponible',
      adresseApprox: map['adresse_approx'],
      quartier: map['quartier'],
      ville: map['ville'] ?? 'Sangmelima',
      lat: map['lat'] != null ? (map['lat']).toDouble() : null,
      lng: map['lng'] != null ? (map['lng']).toDouble() : null,
      proprietaireId: map['proprietaire_id'] ?? '',
      proprietaireNom: map['proprietaire_nom'],
      proprietairePhoto: map['proprietaire_photo'],
      proprietaireVerified: map['proprietaire_verified'] ?? false,
      boosted: map['boosted'] ?? false,
      vues: map['vues'] ?? 0,
      signalements: map['signalements'] ?? 0,
      noteGlobale: (map['note_globale'] ?? 0.0).toDouble(),
      nbAvis: map['nb_avis'] ?? 0,
      datePublication: map['date_publication'] != null
          ? DateTime.parse(map['date_publication'])
          : DateTime.now(),
    );
  }

  // ── Vers Supabase ─────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'type': type,
      'prix': prix,
      'surface': surface,
      'photos': photos,
      'equipements': equipements,
      'regles': regles,
      'disponible_le': disponibleLe?.toIso8601String(),
      'statut': statut,
      'adresse_approx': adresseApprox,
      'quartier': quartier,
      'ville': ville,
      'lat': lat,
      'lng': lng,
      'proprietaire_id': proprietaireId,
      'boosted': boosted,
      'vues': vues,
      'signalements': signalements,
      'note_globale': noteGlobale,
      'nb_avis': nbAvis,
      'date_publication': datePublication.toIso8601String(),
    };
  }
}