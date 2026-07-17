import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'ambassadeur_visite_screen.dart';

class AmbassadeurListeScreen extends StatefulWidget {
  const AmbassadeurListeScreen({super.key});

  @override
  State<AmbassadeurListeScreen> createState() => _AmbassadeurListeScreenState();
}

class _AmbassadeurListeScreenState extends State<AmbassadeurListeScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _verifications = [];

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
          .from(AppConstants.tableVerificationsTerrain)
          .select('*, proprietaire:users!verifications_terrain_user_id_fkey(nom, telephone, email)')
          .eq('ambassadeur_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _verifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'assignee':
        return '📍 À visiter';
      case 'visite_effectuee':
        return '📤 Envoyé à l\'admin';
      case 'validee':
        return '✅ Validée';
      case 'rejetee':
        return '❌ Rejetée';
      default:
        return statut;
    }
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'assignee':
        return MboaColors.boost;
      case 'visite_effectuee':
        return MboaColors.primary;
      case 'validee':
        return MboaColors.verified;
      case 'rejetee':
        return MboaColors.danger;
      default:
        return MboaColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('📋 Propriétaires assignés',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w800, color: MboaColors.text)),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
            : _verifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🧭', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          Text('Aucun propriétaire assigné pour l\'instant', style: MboaTextStyles.muted, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: MboaColors.primary,
                    onRefresh: _charger,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _verifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final verification = _verifications[index];
                        final proprietaire = verification['proprietaire'] as Map<String, dynamic>?;
                        final statut = verification['statut'] as String? ?? '';
                        return GestureDetector(
                          onTap: () async {
                            final modifie = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => AmbassadeurVisiteScreen(verification: verification)),
                            );
                            if (modifie == true) _charger();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: MboaColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(child: Text('🏠', style: TextStyle(fontSize: 20))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(proprietaire?['nom'] ?? 'Propriétaire',
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: MboaColors.text)),
                                      const SizedBox(height: 2),
                                      Text(proprietaire?['telephone'] ?? proprietaire?['email'] ?? '',
                                          style: MboaTextStyles.caption),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _couleurStatut(statut).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _libelleStatut(statut),
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, color: _couleurStatut(statut)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
