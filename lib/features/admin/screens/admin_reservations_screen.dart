import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

// Supervision en lecture (+ override via la policy admin "for all" côté
// RLS, réservée aux litiges) — pas de flux d'approbation ici, ça reste la
// responsabilité de l'établissement (voir mes_reservations_hote_screen.dart).
class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reservations = [];
  String _filtre = 'tous';

  final _filtres = const [
    {'valeur': 'tous', 'label': 'Toutes'},
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
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from(AppConstants.tableReservations)
          .select('*, hebergement:hebergements(titre), visiteur:users!visiteur_id(nom), proprietaire:users!proprietaire_id(nom, nom_commerce)')
          .order('created_at', ascending: false)
          .limit(200);
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
      _filtre == 'tous' ? _reservations : _reservations.where((r) => r['statut'] == _filtre).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('📅 Réservations',
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
                              child: Text(f['label']!,
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
                        ? Center(child: Text('Aucune réservation', style: MboaTextStyles.muted))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reservationsFiltrees.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final r = _reservationsFiltrees[index];
                              final hebergement = r['hebergement'] as Map<String, dynamic>? ?? {};
                              final visiteur = r['visiteur'] as Map<String, dynamic>? ?? {};
                              final proprietaire = r['proprietaire'] as Map<String, dynamic>? ?? {};
                              final statut = r['statut'] as String? ?? 'en_attente';
                              return Container(
                                padding: const EdgeInsets.all(14),
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
                                        Expanded(
                                          child: Text(hebergement['titre'] ?? 'Hébergement',
                                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: _couleurStatut(statut).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                          child: Text(statut,
                                              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: _couleurStatut(statut))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('👤 ${visiteur['nom'] ?? '?'} → 🏨 ${proprietaire['nom_commerce'] ?? proprietaire['nom'] ?? '?'}',
                                        style: MboaTextStyles.caption),
                                    const SizedBox(height: 4),
                                    Text('${_formatDate(r['date_debut'])} → ${_formatDate(r['date_fin'])} · ${r['nb_personnes'] ?? 1} pers.',
                                        style: MboaTextStyles.caption),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
