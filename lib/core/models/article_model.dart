class ArticleModel {
  final String id;
  final String titre;
  final String description;
  final String categorie;
  final String etat;
  final double prix;
  final bool negociable;
  final List<String> photos;
  final String vendeurId;
  final String? vendeurNom;
  final String? vendeurPhoto;
  final bool vendeurVerified;
  final double vendeurNote;
  final String statut;
  final double? lat;
  final double? lng;
  final bool boosted;
  final int vues;
  final int signalements;
  final DateTime datePublication;

  ArticleModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.etat,
    required this.prix,
    this.negociable = false,
    this.photos = const [],
    required this.vendeurId,
    this.vendeurNom,
    this.vendeurPhoto,
    this.vendeurVerified = false,
    this.vendeurNote = 0.0,
    this.statut = 'disponible',
    this.lat,
    this.lng,
    this.boosted = false,
    this.vues = 0,
    this.signalements = 0,
    required this.datePublication,
  });

  bool get isDisponible => statut == 'disponible';
  bool get isVendu      => statut == 'vendu';

  String get prixFormate =>
      '${prix.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  String get photoprincipale =>
      photos.isNotEmpty ? photos.first : '';

  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    return ArticleModel(
      id: map['id'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      categorie: map['categorie'] ?? 'Divers',
      etat: map['etat'] ?? 'Bon état',
      prix: (map['prix'] ?? 0).toDouble(),
      negociable: map['negociable'] ?? false,
      photos: map['photos'] != null ? List<String>.from(map['photos']) : [],
      vendeurId: map['vendeur_id'] ?? '',
      vendeurNom: map['vendeur_nom'],
      vendeurPhoto: map['vendeur_photo'],
      vendeurVerified: map['vendeur_verified'] ?? false,
      vendeurNote: (map['vendeur_note'] ?? 0.0).toDouble(),
      statut: map['statut'] ?? 'disponible',
      lat: map['lat'] != null ? (map['lat']).toDouble() : null,
      lng: map['lng'] != null ? (map['lng']).toDouble() : null,
      boosted: map['boosted'] ?? false,
      vues: map['vues'] ?? 0,
      signalements: map['signalements'] ?? 0,
      datePublication: map['date_publication'] != null
          ? DateTime.parse(map['date_publication'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'categorie': categorie,
      'etat': etat,
      'prix': prix,
      'negociable': negociable,
      'photos': photos,
      'vendeur_id': vendeurId,
      'statut': statut,
      'lat': lat,
      'lng': lng,
      'boosted': boosted,
      'vues': vues,
      'signalements': signalements,
      'date_publication': datePublication.toIso8601String(),
    };
  }
}