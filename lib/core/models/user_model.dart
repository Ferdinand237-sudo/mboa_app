class UserModel {
  final String id;
  final String nom;
  final String email;
  final String? telephone;
  final String? photoUrl;
  final String role;
  final List<String> sousRoles;
  final bool verified;
  final bool boosted;
  final DateTime dateInscription;
  final bool actif;
  final double noteGlobale;
  final int nbAvis;

  // Infos commerçant (optionnelles)
  final String? nomCommerce;
  final String? descriptionCommerce;
  final String? photoCommerce;
  final String? emplacementCommerce;
  final double? lat;
  final double? lng;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    this.photoUrl,
    required this.role,
    this.sousRoles = const [],
    this.verified = false,
    this.boosted = false,
    required this.dateInscription,
    this.actif = true,
    this.noteGlobale = 0.0,
    this.nbAvis = 0,
    this.nomCommerce,
    this.descriptionCommerce,
    this.photoCommerce,
    this.emplacementCommerce,
    this.lat,
    this.lng,
  });

  // ── Getters utiles ────────────────────────────────────────
  bool get isAdmin        => role == 'admin';
  bool get isVendeur      => role == 'vendeur';
  bool get isVisiteur     => role == 'visiteur';
  bool get isProprietaire => sousRoles.contains('proprietaire');
  bool get isCommercant   => sousRoles.contains('commercant');
  bool get isVendeurIndep => sousRoles.contains('vendeur_independant');

  String get initiales {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nom.substring(0, 2).toUpperCase();
  }

  // ── Depuis Supabase ───────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'],
      photoUrl: map['photo_url'],
      role: map['role'] ?? 'visiteur',
      sousRoles: map['sous_roles'] != null
          ? List<String>.from(map['sous_roles'])
          : [],
      verified: map['verified'] ?? false,
      boosted: map['boosted'] ?? false,
      dateInscription: map['date_inscription'] != null
          ? DateTime.parse(map['date_inscription'])
          : DateTime.now(),
      actif: map['actif'] ?? true,
      noteGlobale: (map['note_globale'] ?? 0.0).toDouble(),
      nbAvis: map['nb_avis'] ?? 0,
      nomCommerce: map['nom_commerce'],
      descriptionCommerce: map['description_commerce'],
      photoCommerce: map['photo_commerce'],
      emplacementCommerce: map['emplacement_commerce'],
      lat: map['lat'] != null ? (map['lat']).toDouble() : null,
      lng: map['lng'] != null ? (map['lng']).toDouble() : null,
    );
  }

  // ── Vers Supabase ─────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'photo_url': photoUrl,
      'role': role,
      'sous_roles': sousRoles,
      'verified': verified,
      'boosted': boosted,
      'date_inscription': dateInscription.toIso8601String(),
      'actif': actif,
      'note_globale': noteGlobale,
      'nb_avis': nbAvis,
      'nom_commerce': nomCommerce,
      'description_commerce': descriptionCommerce,
      'photo_commerce': photoCommerce,
      'emplacement_commerce': emplacementCommerce,
      'lat': lat,
      'lng': lng,
    };
  }

  // ── Copie avec modifications ──────────────────────────────
  UserModel copyWith({
    String? nom,
    String? telephone,
    String? photoUrl,
    String? role,
    List<String>? sousRoles,
    bool? verified,
    bool? boosted,
    bool? actif,
    double? noteGlobale,
    int? nbAvis,
    String? nomCommerce,
    String? descriptionCommerce,
    String? photoCommerce,
    String? emplacementCommerce,
    double? lat,
    double? lng,
  }) {
    return UserModel(
      id: id,
      nom: nom ?? this.nom,
      email: email,
      telephone: telephone ?? this.telephone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      sousRoles: sousRoles ?? this.sousRoles,
      verified: verified ?? this.verified,
      boosted: boosted ?? this.boosted,
      dateInscription: dateInscription,
      actif: actif ?? this.actif,
      noteGlobale: noteGlobale ?? this.noteGlobale,
      nbAvis: nbAvis ?? this.nbAvis,
      nomCommerce: nomCommerce ?? this.nomCommerce,
      descriptionCommerce: descriptionCommerce ?? this.descriptionCommerce,
      photoCommerce: photoCommerce ?? this.photoCommerce,
      emplacementCommerce: emplacementCommerce ?? this.emplacementCommerce,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}