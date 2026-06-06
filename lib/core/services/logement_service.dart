import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/logement_model.dart';
import '../constants/app_constants.dart';

class LogementService {
  final _supabase = Supabase.instance.client;

  // ── Liste des logements avec filtres ──────────────────────
  Future<List<LogementModel>> getLogements({
    String? type,
    double? prixMax,
    String? search,
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    var query = _supabase
        .from(AppConstants.tableLogements)
        .select('*, proprietaire:users!proprietaire_id(nom, photo_url, verified)')
        .eq('statut', 'disponible');

    if (type != null && type != 'Tous') {
      query = query.eq('type', type);
    }

    if (prixMax != null) {
      query = query.lte('prix', prixMax);
    }

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'titre.ilike.%$search%,quartier.ilike.%$search%,description.ilike.%$search%',
      );
    }

    final data = await query
        .order('boosted', ascending: false)
        .order('note_globale', ascending: false)
        .order('date_publication', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((item) => LogementModel.fromMap(item))
        .toList();
  }

  // ── Détail d'un logement ──────────────────────────────────
  Future<LogementModel?> getLogement(String id) async {
    try {
      final data = await _supabase
          .from(AppConstants.tableLogements)
          .select('*, proprietaire:users!proprietaire_id(nom, photo_url, verified)')
          .eq('id', id)
          .single();

      await _supabase
          .from(AppConstants.tableLogements)
          .update({'vues': (data['vues'] ?? 0) + 1})
          .eq('id', id);

      return LogementModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // ── Publier un logement ───────────────────────────────────
  Future<String?> publierLogement(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(AppConstants.tableLogements)
          .insert(data)
          .select('id')
          .single();
      return response['id'] as String;
    } catch (e) {
      return null;
    }
  }

  // ── Modifier un logement ──────────────────────────────────
  Future<void> modifierLogement(
      String id, Map<String, dynamic> data) async {
    await _supabase
        .from(AppConstants.tableLogements)
        .update(data)
        .eq('id', id);
  }

  // ── Supprimer un logement ─────────────────────────────────
  Future<void> supprimerLogement(String id) async {
    await _supabase
        .from(AppConstants.tableLogements)
        .delete()
        .eq('id', id);
  }

  // ── Logements d'un propriétaire ───────────────────────────
  Future<List<LogementModel>> getMesLogements(
      String proprietaireId) async {
    final data = await _supabase
        .from(AppConstants.tableLogements)
        .select()
        .eq('proprietaire_id', proprietaireId)
        .order('date_publication', ascending: false);

    return (data as List)
        .map((item) => LogementModel.fromMap(item))
        .toList();
  }

  // ── Signaler un logement ──────────────────────────────────
  Future<void> signalerLogement({
    required String logementId,
    required String signaleurId,
    required String raison,
  }) async {
    await _supabase.from('signalements').insert({
      'signaleur_id': signaleurId,
      'cible_type': 'annonce',
      'cible_id': logementId,
      'raison': raison,
    });

    final logement = await _supabase
        .from(AppConstants.tableLogements)
        .select('signalements')
        .eq('id', logementId)
        .single();

    final nbSignalements = (logement['signalements'] ?? 0) + 1;

    await _supabase
        .from(AppConstants.tableLogements)
        .update({'signalements': nbSignalements})
        .eq('id', logementId);

    if (nbSignalements >= AppConstants.seuilSignalement) {
      await _supabase
          .from(AppConstants.tableLogements)
          .update({'statut': 'reserve'})
          .eq('id', logementId);
    }
  }
}