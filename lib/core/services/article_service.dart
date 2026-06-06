import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article_model.dart';
import '../constants/app_constants.dart';

class ArticleService {
  final _supabase = Supabase.instance.client;

  // ── Liste des articles avec filtres ──────────────────────
  Future<List<ArticleModel>> getArticles({
    String? categorie,
    String? etat,
    String? search,
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    var query = _supabase
        .from(AppConstants.tableArticles)
        .select('*, vendeur:users!vendeur_id(nom, photo_url, verified, note_globale)')
        .eq('statut', 'disponible');

    if (categorie != null && categorie != 'Tous') {
      query = query.eq('categorie', categorie);
    }

    if (etat != null && etat != 'Tous') {
      query = query.eq('etat', etat);
    }

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'titre.ilike.%$search%,description.ilike.%$search%',
      );
    }

    final data = await query
        .order('boosted', ascending: false)
        .order('date_publication', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((item) => ArticleModel.fromMap(item))
        .toList();
  }

  // ── Détail d'un article ───────────────────────────────────
  Future<ArticleModel?> getArticle(String id) async {
    try {
      final data = await _supabase
          .from(AppConstants.tableArticles)
          .select('*, vendeur:users!vendeur_id(nom, photo_url, verified, note_globale)')
          .eq('id', id)
          .single();

      await _supabase
          .from(AppConstants.tableArticles)
          .update({'vues': (data['vues'] ?? 0) + 1})
          .eq('id', id);

      return ArticleModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // ── Publier un article ────────────────────────────────────
  Future<String?> publierArticle(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(AppConstants.tableArticles)
          .insert(data)
          .select('id')
          .single();
      return response['id'] as String;
    } catch (e) {
      return null;
    }
  }

  // ── Marquer comme vendu ───────────────────────────────────
  Future<void> marquerVendu(String id) async {
    await _supabase
        .from(AppConstants.tableArticles)
        .update({'statut': 'vendu'})
        .eq('id', id);
  }

  // ── Mes articles ──────────────────────────────────────────
  Future<List<ArticleModel>> getMesArticles(String vendeurId) async {
    final data = await _supabase
        .from(AppConstants.tableArticles)
        .select()
        .eq('vendeur_id', vendeurId)
        .order('date_publication', ascending: false);

    return (data as List)
        .map((item) => ArticleModel.fromMap(item))
        .toList();
  }

  // ── Signaler un article ───────────────────────────────────
  Future<void> signalerArticle({
    required String articleId,
    required String signaleurId,
    required String raison,
  }) async {
    await _supabase.from('signalements').insert({
      'signaleur_id': signaleurId,
      'cible_type': 'annonce',
      'cible_id': articleId,
      'raison': raison,
    });

    final article = await _supabase
        .from(AppConstants.tableArticles)
        .select('signalements')
        .eq('id', articleId)
        .single();

    final nbSignalements = (article['signalements'] ?? 0) + 1;

    await _supabase
        .from(AppConstants.tableArticles)
        .update({'signalements': nbSignalements})
        .eq('id', articleId);

    if (nbSignalements >= AppConstants.seuilSignalement) {
      await _supabase
          .from(AppConstants.tableArticles)
          .update({'statut': 'vendu'})
          .eq('id', articleId);
    }
  }
}