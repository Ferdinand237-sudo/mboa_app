import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';

// Miroir de mboa-web/src/components/profil/notifications-list.tsx et
// notification-bell.tsx : lit directement la table public.notifications
// (alimentée par les triggers SQL sur messages/avis/annonces/demandes/
// signalements — voir 20260724000000_notifications_inapp.sql et
// 20260725000000_notifications_admin.sql), plutôt que l'ancienne
// reconstruction ad-hoc à partir de conversations.non_lu/avis qui ignorait
// entièrement cette table (et donc les demandes/signalements côté admin).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const _icones = {
    'message': '💬',
    'avis': '⭐',
    'annonce': '🏘',
    'demande': '📨',
    'signalement': '🚨',
  };

  /// Nombre de notifications non lues, pour la pastille sur la cloche (Home).
  static Future<int> compterNonLues() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return 0;
    try {
      final data = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('lu', false);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

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
      final data = await _supabase
          .from('notifications')
          .select('id, type, titre, corps, lien, lu, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Ne marque lue que la notification tapée (pas toute la liste) : miroir
  // exact de notifications-list.tsx, pour que le compteur de la cloche ne
  // baisse que d'une unité à chaque fois, pas d'un coup.
  Future<void> _ouvrir(Map<String, dynamic> n) async {
    if (n['lu'] != true) {
      setState(() => n['lu'] = true);
      try {
        await _supabase.from('notifications').update({'lu': true}).eq('id', n['id']);
      } catch (_) {}
    }
    final lien = n['lien'] as String?;
    if (lien != null) ouvrirDepuisLien(lien);
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
                        Text('Tu seras notifié ici des nouveaux messages, avis et annonces correspondant à tes alertes.',
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
                      final type = n['type'] as String? ?? 'message';
                      final estLu = n['lu'] == true;
                      final icone = NotificationsScreen._icones[type] ?? '🔔';
                      return GestureDetector(
                        onTap: () => _ouvrir(n),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: estLu ? Colors.white : MboaColors.primary.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                            border: estLu ? null : Border.all(color: MboaColors.primary.withValues(alpha: 0.15)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (type == 'signalement' ? MboaColors.danger : MboaColors.primary)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(icone, style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['titre'] ?? '',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: estLu ? FontWeight.w600 : FontWeight.w700,
                                          color: MboaColors.text,
                                        )),
                                    if ((n['corps'] as String?)?.isNotEmpty == true) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        n['corps'],
                                        style: MboaTextStyles.bodySm,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(_formatDate(n['created_at']?.toString()), style: MboaTextStyles.caption),
                                  ],
                                ),
                              ),
                              if (!estLu)
                                Container(
                                  width: 9,
                                  height: 9,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: const BoxDecoration(color: MboaColors.secondary, shape: BoxShape.circle),
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
