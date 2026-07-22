import 'package:supabase_flutter/supabase_flutter.dart';

/// Nombre total de messages non lus de l'utilisateur connecté, tous
/// azimuts confondus (badge nav Chat, cloche notifications, profil).
/// Centralisé ici pour que les différents écrans qui affichent ce
/// compteur restent cohérents entre eux.
class UnreadService {
  UnreadService._();

  static Future<int> nbMessagesNonLus() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return 0;
    try {
      final data = await supabase
          .from('conversations')
          .select('non_lu')
          .contains('participants', [user.id]);
      var total = 0;
      for (final conv in List<Map<String, dynamic>>.from(data)) {
        final nonLu = conv['non_lu'];
        if (nonLu is Map && nonLu[user.id] != null) {
          total += (nonLu[user.id] as num).toInt();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
