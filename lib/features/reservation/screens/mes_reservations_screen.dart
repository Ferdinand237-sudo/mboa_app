import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../hebergement/screens/hebergement_detail_screen.dart';

class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});

  @override
  State<MesReservationsScreen> createState() => _MesReservationsScreenState();
}

class _MesReservationsScreenState extends State<MesReservationsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reservations = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from(AppConstants.tableReservations)
          .select('*, hebergement:hebergements(id, titre, photos, ville, prix, type_etablissement, description, capacite_personnes, equipements, statut_moderation, boosted, vues, signalements, proprietaire_id, date_publication)')
          .eq('visiteur_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _reservations = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _annuler(Map<String, dynamic> r) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusXl)),
        title: const Text('Annuler cette demande ?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MboaColors.danger),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await _supabase.from(AppConstants.tableReservations).update({'statut': 'annulee'}).eq('id', r['id']);
      _charger();
    } catch (_) {}
  }

  String _formatDate(dynamic d) {
    if (d == null) return '';
    final date = DateTime.parse(d.toString());
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'confirmee':
        return MboaColors.verified;
      case 'refusee':
        return MboaColors.danger;
      case 'annulee':
        return MboaColors.textMuted;
      default:
        return MboaColors.boost;
    }
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'confirmee':
        return '✅ Confirmée';
      case 'refusee':
        return '❌ Refusée';
      case 'annulee':
        return 'Annulée';
      default:
        return '⏳ En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('📅 Mes réservations',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
          : _reservations.isEmpty
              ? Center(child: Text('Aucune demande de réservation pour le moment', style: MboaTextStyles.muted))
              : RefreshIndicator(
                  color: MboaColors.primary,
                  onRefresh: _charger,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildCard(_reservations[index]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final hebergement = r['hebergement'] as Map<String, dynamic>?;
    final photos = hebergement?['photos'] as List? ?? [];
    final statut = r['statut'] as String? ?? 'en_attente';

    return GestureDetector(
      onTap: hebergement == null
          ? null
          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => HebergementDetailScreen(hebergement: hebergement))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                    child: photos.isNotEmpty
                        ? Image.network(photos[0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🏨')))
                        : const Center(child: Text('🏨')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hebergement?['titre'] ?? 'Hébergement supprimé',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                      Text('${_formatDate(r['date_debut'])} → ${_formatDate(r['date_fin'])}', style: MboaTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _couleurStatut(statut).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(_libelleStatut(statut),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: _couleurStatut(statut))),
                ),
              ],
            ),
            if (statut == 'en_attente') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _annuler(r),
                  style: TextButton.styleFrom(foregroundColor: MboaColors.danger),
                  child: const Text('Annuler la demande', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
