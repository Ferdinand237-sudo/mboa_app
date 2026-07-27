class VilleModel {
  final String id;
  final String nom;
  final double lat;
  final double lng;
  final double rayonCouvertureKm;
  final bool actif;
  final int ordreAffichage;

  VilleModel({
    required this.id,
    required this.nom,
    required this.lat,
    required this.lng,
    this.rayonCouvertureKm = 30,
    this.actif = true,
    this.ordreAffichage = 0,
  });

  factory VilleModel.fromMap(Map<String, dynamic> map) {
    return VilleModel(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      rayonCouvertureKm: (map['rayon_couverture_km'] ?? 30).toDouble(),
      actif: map['actif'] ?? true,
      ordreAffichage: map['ordre_affichage'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'lat': lat,
      'lng': lng,
      'rayon_couverture_km': rayonCouvertureKm,
      'actif': actif,
      'ordre_affichage': ordreAffichage,
    };
  }
}
