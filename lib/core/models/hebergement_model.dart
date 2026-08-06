class HebergementModel {
  final String id;
  final String titre;
  final String description;
  final String typeEtablissement;
  final int capacitePersonnes;
  final double prix;
  final List<String> equipements;
  final List<String> photos;
  final String statut;
  final String statutModeration;

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
  final DateTime datePublication;

  HebergementModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.typeEtablissement,
    this.capacitePersonnes = 1,
    required this.prix,
    this.equipements = const [],
    this.photos = const [],
    this.statut = 'disponible',
    this.statutModeration = 'publie',
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
    required this.datePublication,
  });

  // ── Getters utiles ────────────────────────────────────────
  bool get isDisponible => statut == 'disponible';

  bool get enAttenteModeration => statutModeration == 'en_attente';
  bool get aVerifierModeration => statutModeration == 'a_verifier';
  bool get bloqueModeration    => statutModeration == 'bloque';

  String get prixFormate =>
      '${prix.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA / nuit';

  String get photoprincipale =>
      photos.isNotEmpty ? photos.first : '';

  // ── Depuis Supabase ───────────────────────────────────────
  factory HebergementModel.fromMap(Map<String, dynamic> map) {
    return HebergementModel(
      id: map['id'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      typeEtablissement: map['type_etablissement'] ?? 'hotel',
      capacitePersonnes: map['capacite_personnes'] ?? 1,
      prix: (map['prix'] ?? 0).toDouble(),
      equipements: map['equipements'] != null
          ? List<String>.from(map['equipements'])
          : [],
      photos: map['photos'] != null ? List<String>.from(map['photos']) : [],
      statut: map['statut'] ?? 'disponible',
      statutModeration: map['statut_moderation'] ?? 'publie',
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
      'type_etablissement': typeEtablissement,
      'capacite_personnes': capacitePersonnes,
      'prix': prix,
      'equipements': equipements,
      'photos': photos,
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
      'date_publication': datePublication.toIso8601String(),
    };
  }
}
