import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralise l'abonnement/désabonnement à un canal Supabase Realtime sur
/// une table, pour éviter de dupliquer ce code dans chaque écran.
///
/// Réservé aux tableaux de bord admin/ambassadeur (voir CLAUDE.md pour la
/// liste des écrans qui l'utilisent, et pourquoi les listes publiques à
/// fort trafic — logements, articles, home — n'y ont volontairement pas
/// recours).
///
/// Usage :
/// ```dart
/// class _MonEcranState extends State<MonEcran> with RealtimeTableMixin {
///   @override
///   void initState() {
///     super.initState();
///     subscribeToTable(
///       channelName: 'mon_ecran_ma_table',
///       table: 'ma_table',
///       event: PostgresChangeEvent.all,
///       onChange: (payload) { ... },
///     );
///   }
///
///   @override
///   void dispose() {
///     disposeRealtimeChannels();
///     super.dispose();
///   }
/// }
/// ```
mixin RealtimeTableMixin<T extends StatefulWidget> on State<T> {
  final List<RealtimeChannel> _realtimeChannels = [];

  RealtimeChannel subscribeToTable({
    required String channelName,
    required String table,
    required PostgresChangeEvent event,
    PostgresChangeFilter? filter,
    required void Function(PostgresChangePayload payload) onChange,
  }) {
    final channel = Supabase.instance.client.channel(channelName);
    channel
        .onPostgresChanges(
          event: event,
          schema: 'public',
          table: table,
          filter: filter,
          callback: onChange,
        )
        .subscribe();
    _realtimeChannels.add(channel);
    return channel;
  }

  /// À appeler explicitement dans le dispose() de l'écran, avant
  /// super.dispose() — un mixin ne peut pas s'y accrocher automatiquement.
  void disposeRealtimeChannels() {
    for (final channel in _realtimeChannels) {
      Supabase.instance.client.removeChannel(channel);
    }
    _realtimeChannels.clear();
  }
}
