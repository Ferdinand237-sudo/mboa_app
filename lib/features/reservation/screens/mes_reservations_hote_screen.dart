import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class MesReservationsHoteScreen extends StatefulWidget {
  const MesReservationsHoteScreen({super.key});

  @override
  State<MesReservationsHoteScreen> createState() => _MesReservationsHoteScreenState();
}

class _MesReservationsHoteScreenState extends State<MesReservationsHoteScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reservations = [];
  String _filtre = 'en_attente';

  final _filtres = const [
    {'valeur': 'en_attente', 'label': 'En attente'},
    {'valeur': 'confirmee', 'label': 'Confirmées'},
    {'valeur': 'refusee', 'label': 'Refusées'},
    {'valeur': 'annulee', 'label': 'Annulées'},
  ];

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
          .select('*, hebergement:hebergements(titre, photos), visiteur:users!visiteur_id(nom, telephone)')
          .eq('proprietaire_id', userId)
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

  List<Map<String, dynamic>> get _reservationsFiltrees =>
      _reservations.where((r) => r['statut'] == _filtre).toList();

  Future<void> _repondre(Map<String, dynamic> reservation, String statut) async {
    try {
      await _supabase
          .from(AppConstants.tableReservations)
          .update({'statut': statut})
          .eq('id', reservation['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statut == 'confirmee' ? '✅ Réservation confirmée' : 'Réservation refusée'),
            backgroundColor: statut == 'confirmee' ? MboaColors.verified : MboaColors.textMuted,
          ),
        );
        _charger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  String _formatDate(dynamic d) {
    if (d == null) return '';
    final date = DateTime.parse(d.toString());
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('📅 Réservations reçues',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
          : RefreshIndicator(
              color: MboaColors.primary,
              onRefresh: _charger,
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: _filtres.map((f) {
                        final isSelected = _filtre == f['valeur'];
                        final count = _reservations.where((r) => r['statut'] == f['valeur']).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filtre = f['valeur']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? MboaColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? MboaColors.primary : MboaColors.border),
                              ),
                              child: Text('${f['label']} ($count)',
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : MboaColors.text)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: _reservationsFiltrees.isEmpty
                        ? Center(child: Text('Aucune réservation ici', style: MboaTextStyles.muted))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reservationsFiltrees.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _buildCard(_reservationsFiltrees[index]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final hebergement = r['hebergement'] as Map<String, dynamic>? ?? {};
    final visiteur = r['visiteur'] as Map<String, dynamic>? ?? {};
    final photos = hebergement['photos'] as List? ?? [];
    final enAttente = r['statut'] == 'en_attente';

    return Container(
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
                    Text(hebergement['titre'] ?? 'Hébergement',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                    Text('${visiteur['nom'] ?? 'Visiteur'}${visiteur['telephone'] != null ? ' · ${visiteur['telephone']}' : ''}',
                        style: MboaTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: MboaColors.textMuted),
              const SizedBox(width: 6),
              Text('${_formatDate(r['date_debut'])} → ${_formatDate(r['date_fin'])}', style: MboaTextStyles.bodySm),
              const SizedBox(width: 12),
              const Icon(Icons.people_outline_rounded, size: 14, color: MboaColors.textMuted),
              const SizedBox(width: 4),
              Text('${r['nb_personnes'] ?? 1}', style: MboaTextStyles.bodySm),
            ],
          ),
          if ((r['message'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('« ${r['message']} »', style: MboaTextStyles.caption),
          ],
          if (enAttente) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _repondre(r, 'refusee'),
                    style: OutlinedButton.styleFrom(foregroundColor: MboaColors.danger, side: const BorderSide(color: MboaColors.danger)),
                    child: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _repondre(r, 'confirmee'),
                    style: ElevatedButton.styleFrom(backgroundColor: MboaColors.verified),
                    child: const Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
