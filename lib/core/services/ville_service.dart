import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ville_model.dart';

/// Singleton d'accès direct, comme _supabase = Supabase.instance.client
/// utilisé partout ailleurs dans l'app — aucun écran ne consomme Riverpod
/// aujourd'hui (seuls app.dart/router.dart et des providers d'auth inutilisés
/// existent), donc introduire du ConsumerState pour un état aussi simple
/// aurait été disproportionné. Les écrans écoutent [selectedVille] via
/// addListener en initState et appellent leur propre refresh(), comme le
/// mixin RefreshableState déjà utilisé pour le rafraîchissement inter-onglet.
class VilleService {
  VilleService._();
  static final VilleService instance = VilleService._();

  static const _keyVilleChoisie = 'ville_choisie';

  final _supabase = Supabase.instance.client;

  /// null tant qu'aucune ville n'a été résolue (chargement) OU que la
  /// position détectée ne correspond à aucune ville couverte — c'est ce
  /// null qui doit déclencher l'affichage du sélecteur de villes côté UI,
  /// jamais un repli silencieux vers une ville par défaut.
  final ValueNotifier<VilleModel?> selectedVille = ValueNotifier(null);

  List<VilleModel> villesActives = [];
  bool _initialise = false;

  Future<void> init() async {
    if (_initialise) return;
    _initialise = true;

    try {
      final data = await _supabase
          .from('villes')
          .select()
          .eq('actif', true)
          .order('ordre_affichage');
      villesActives = (data as List)
          .map((v) => VilleModel.fromMap(v))
          .toList();
    } catch (_) {
      return;
    }
    if (villesActives.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final nomSauvegarde = prefs.getString(_keyVilleChoisie);
      if (nomSauvegarde != null) {
        final ville = villesActives
            .where((v) => v.nom == nomSauvegarde)
            .cast<VilleModel?>()
            .firstWhere((_) => true, orElse: () => null);
        if (ville != null) {
          selectedVille.value = ville;
          return;
        }
      }
    } catch (_) {}

    await _detecterParGps();
  }

  Future<void> _detecterParGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 15),
      );
      final ville = villeProchePosition(position.latitude, position.longitude);
      if (ville != null) {
        selectedVille.value = ville;
        _persister(ville.nom);
      }
    } catch (_) {
      // Signal GPS indisponible/faible : selectedVille reste null, l'UI
      // affiche le sélecteur de villes couvertes plutôt qu'un repli silencieux.
    }
  }

  /// Ville active la plus proche d'une position donnée, dans la limite de
  /// son rayon de couverture — réutilisée par la carte (tag d'un nouveau
  /// lieu) et Publier (ville d'un logement) pour ne pas dupliquer ce calcul.
  VilleModel? villeProchePosition(double lat, double lng) {
    VilleModel? plusProche;
    double? distanceMin;
    for (final ville in villesActives) {
      final distanceM = Geolocator.distanceBetween(lat, lng, ville.lat, ville.lng);
      if (distanceM <= ville.rayonCouvertureKm * 1000) {
        if (distanceMin == null || distanceM < distanceMin) {
          distanceMin = distanceM;
          plusProche = ville;
        }
      }
    }
    return plusProche;
  }

  /// Ville active portant ce nom, ou null si aucune (ville désactivée
  /// depuis, ou nom vide) — utilisé pour convertir la ville déclarée au
  /// profil d'un vendeur (texte libre en base) en VilleModel exploitable.
  VilleModel? villeParNom(String? nom) {
    if (nom == null) return null;
    for (final v in villesActives) {
      if (v.nom == nom) return v;
    }
    return null;
  }

  Future<void> selectVille(VilleModel ville) async {
    selectedVille.value = ville;
    await _persister(ville.nom);
  }

  Future<void> _persister(String nom) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyVilleChoisie, nom);
    } catch (_) {}
  }
}
