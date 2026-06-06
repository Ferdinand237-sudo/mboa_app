import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  // ── Créer ou récupérer une conversation ───────────────────
  Future<String> getOuCreerConversation({
    required String userId,
    required String vendeurId,
    required String annonceId,
    required String annonceType,
  }) async {
    // Chercher conversation existante
    final existing = await _supabase
        .from(AppConstants.tableConversations)
        .select('id')
        .contains('participants', [userId, vendeurId])
        .eq('annonce_id', annonceId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Créer une nouvelle conversation
    final response = await _supabase
        .from(AppConstants.tableConversations)
        .insert({
          'participants': [userId, vendeurId],
          'annonce_id': annonceId,
          'annonce_type': annonceType,
          'non_lu': {userId: 0, vendeurId: 0},
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  // ── Mes conversations ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMesConversations(
      String userId) async {
    final data = await _supabase
        .from(AppConstants.tableConversations)
        .select('''
          *,
          messages(
            texte, date_envoi, expediteur_id
          )
        ''')
        .contains('participants', [userId])
        .order('dernier_message_date', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── Messages d'une conversation ───────────────────────────
  Stream<List<Map<String, dynamic>>> getMessages(
      String conversationId) {
    return _supabase
        .from(AppConstants.tableMessages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('date_envoi');
  }

  // ── Envoyer un message ────────────────────────────────────
  Future<void> envoyerMessage({
    required String conversationId,
    required String expediteurId,
    required String texte,
  }) async {
    // Insérer le message
    await _supabase.from(AppConstants.tableMessages).insert({
      'conversation_id': conversationId,
      'expediteur_id': expediteurId,
      'texte': texte,
    });

    // Mettre à jour la conversation
    await _supabase
        .from(AppConstants.tableConversations)
        .update({
          'dernier_message': texte,
          'dernier_message_date': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  // ── Marquer messages comme lus ────────────────────────────
  Future<void> marquerLus({
    required String conversationId,
    required String userId,
  }) async {
    await _supabase
        .from(AppConstants.tableMessages)
        .update({'lu': true})
        .eq('conversation_id', conversationId)
        .neq('expediteur_id', userId);
  }
}