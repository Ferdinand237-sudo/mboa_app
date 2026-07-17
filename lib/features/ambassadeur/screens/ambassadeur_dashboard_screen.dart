import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AmbassadeurDashboardScreen extends StatefulWidget {
  const AmbassadeurDashboardScreen({super.key});

  @override
  State<AmbassadeurDashboardScreen> createState() => _AmbassadeurDashboardScreenState();
}

class _AmbassadeurDashboardScreenState extends State<AmbassadeurDashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _nom;
  int _nbAssignes = 0;
  int _nbEnAttenteAdmin = 0;
  int _nbValidees = 0;
  int _nbRejetees = 0;

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
    try {
      final resultats = await Future.wait<dynamic>([
        _supabase.from('users').select('nom').eq('id', userId).single(),
        _supabase
            .from(AppConstants.tableVerificationsTerrain)
            .select('statut')
            .eq('ambassadeur_id', userId),
      ]);

      final profil = resultats[0] as Map<String, dynamic>;
      final verifications = List<Map<String, dynamic>>.from(resultats[1] as List);

      if (mounted) {
        setState(() {
          _nom = profil['nom'];
          _nbAssignes = verifications
              .where((v) => v['statut'] == AppConstants.statutVerificationAssignee)
              .length;
          _nbEnAttenteAdmin = verifications
              .where((v) => v['statut'] == AppConstants.statutVerificationVisiteEffectuee)
              .length;
          _nbValidees = verifications
              .where((v) => v['statut'] == AppConstants.statutVerificationValidee)
              .length;
          _nbRejetees = verifications
              .where((v) => v['statut'] == AppConstants.statutVerificationRejetee)
              .length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
            : RefreshIndicator(
                color: MboaColors.primary,
                onRefresh: _charger,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('🧭 Ambassadeur Mboa',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: MboaColors.text)),
                    const SizedBox(height: 4),
                    Text('Bonjour ${_nom ?? ''}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: MboaColors.textMuted)),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard('🏠', 'À visiter', _nbAssignes, MboaColors.boost),
                        _buildStatCard('📤', 'En attente admin', _nbEnAttenteAdmin, MboaColors.primary),
                        _buildStatCard('✅', 'Validées', _nbValidees, MboaColors.verified),
                        _buildStatCard('❌', 'Rejetées', _nbRejetees, MboaColors.danger),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MboaColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: MboaColors.primary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Retrouve la liste de tes propriétaires assignés dans l\'onglet "Assignés".',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: MboaColors.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const Spacer(),
          Text('$count',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: MboaColors.textMuted)),
        ],
      ),
    );
  }
}
