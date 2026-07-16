import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../chat/screens/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final resultats = <Map<String, dynamic>>[];

      // Messages non lus
      final conversations = await _supabase
          .from('conversations')
          .select('id, participants, dernier_message, dernier_message_date, non_lu')
          .contains('participants', [user.id]);
      for (final conv in List<Map<String, dynamic>>.from(conversations)) {
        final nonLu = conv['non_lu'];
        final nb = (nonLu is Map && nonLu[user.id] != null) ? (nonLu[user.id] as num).toInt() : 0;
        if (nb > 0) {
          resultats.add({
            'type': 'message',
            'texte': '$nb nouveau${nb > 1 ? 'x' : ''} message${nb > 1 ? 's' : ''} : ${conv['dernier_message'] ?? ''}',
            'date': conv['dernier_message_date'],
            'conversationId': conv['id'],
          });
        }
      }

      // Avis reçus récemment
      final avis = await _supabase
          .from('avis')
          .select('note, commentaire, date_publication, auteur:users!auteur_id(nom)')
          .eq('cible_id', user.id)
          .order('date_publication', ascending: false)
          .limit(10);
      for (final a in List<Map<String, dynamic>>.from(avis)) {
        final auteur = a['auteur'] as Map<String, dynamic>?;
        resultats.add({
          'type': 'avis',
          'texte': '${auteur?['nom'] ?? 'Un utilisateur'} vous a donné ${a['note']} ⭐',
          'date': a['date_publication'],
        });
      }

      resultats.sort((x, y) {
        final dx = DateTime.tryParse(x['date']?.toString() ?? '') ?? DateTime(2000);
        final dy = DateTime.tryParse(y['date']?.toString() ?? '') ?? DateTime(2000);
        return dy.compareTo(dx);
      });

      if (mounted) {
        setState(() {
          _notifications = resultats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('🔔 Notifications',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
          : _notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔕', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        const Text('Aucune notification',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text)),
                        const SizedBox(height: 8),
                        Text('Tu seras notifié ici des nouveaux messages et avis.',
                            style: MboaTextStyles.muted, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: MboaColors.primary,
                  onRefresh: _charger,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isMessage = n['type'] == 'message';
                      return GestureDetector(
                        onTap: isMessage
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                                )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (isMessage ? MboaColors.primary : MboaColors.boost).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(isMessage ? '💬' : '⭐', style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['texte'] ?? '',
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: MboaColors.text)),
                                    const SizedBox(height: 2),
                                    Text(_formatDate(n['date']?.toString()), style: MboaTextStyles.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
