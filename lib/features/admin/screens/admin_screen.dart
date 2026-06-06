import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/router.dart';
import 'admin_users_screen.dart';
import 'admin_annonces_screen.dart';
import 'admin_signalements_screen.dart';
// import 'admin_demandes_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  final List<_AdminNavItem> _navItems = [
    _AdminNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _AdminNavItem(icon: Icons.people_rounded, label: 'Utilisateurs'),
    _AdminNavItem(icon: Icons.list_alt_rounded, label: 'Annonces'),
    _AdminNavItem(icon: Icons.flag_rounded, label: 'Signalements'),
  ];

  final List<Widget> _screens = [
    const _DashboardTab(),
    const AdminUsersScreen(),
    const AdminAnnoncesScreen(),
    const AdminSignalementsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isActive = _currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _currentIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? MboaColors.primary.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            item.icon,
                            color: isActive
                                ? MboaColors.primary
                                : MboaColors.textMuted,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? MboaColors.primary
                                : MboaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ════════════════════════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _supabase = Supabase.instance.client;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    try {
        final users = await _supabase.from('users').select('id');
        final logements = await _supabase.from('logements').select('id');
        final articles = await _supabase.from('articles').select('id');
        final signalements = await _supabase
          .from('signalements')
          .select('id')
          .eq('statut', 'en-attente');
        final demandes = await _supabase
          .from('demandes_compte')
          .select('id')
          .eq('statut', 'en-attente');

      if (mounted) {
        setState(() {
          _stats = {
            'users': (users as List).length,
            'logements': (logements as List).length,
            'articles': (articles as List).length,
            'signalements': (signalements as List).length,
            'demandes': (demandes as List).length,
          };
        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header Admin ──────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: MboaColors.primaryGradient,
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour Admin 👋',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const Text(
                              'Dashboard Mboa',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Bouton déconnexion
                        GestureDetector(
                          onTap: () async {
                            await Supabase.instance.client.auth
                                .signOut();
                            if (context.mounted) {
                              context.go(AppRoutes.onboarding);
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stats rapides
                    Row(
                      children: [
                        _buildQuickStat(
                          '👥',
                          '${_stats['users'] ?? 0}',
                          'Utilisateurs',
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          '🏠',
                          '${_stats['logements'] ?? 0}',
                          'Logements',
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          '🛒',
                          '${_stats['articles'] ?? 0}',
                          'Articles',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Alertes ───────────────────────
                    if ((_stats['signalements'] ?? 0) > 0 ||
                        (_stats['demandes'] ?? 0) > 0) ...[
                      const Text(
                        '🚨 Actions requises',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MboaColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((_stats['demandes'] ?? 0) > 0)
                        _buildAlertCard(
                          icon: '📨',
                          titre: 'Demandes de compte',
                          desc:
                              '${_stats['demandes']} demande(s) en attente d\'approbation',
                          color: MboaColors.secondary,
                          onTap: () {},
                        ),
                      if ((_stats['signalements'] ?? 0) > 0)
                        _buildAlertCard(
                          icon: '🚩',
                          titre: 'Signalements',
                          desc:
                              '${_stats['signalements']} signalement(s) à traiter',
                          color: MboaColors.danger,
                          onTap: () {},
                        ),
                      const SizedBox(height: 24),
                    ],

                    // ── Actions rapides ───────────────
                    const Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildActionCard(
                      icon: Icons.person_add_rounded,
                      titre: 'Créer un compte vendeur',
                      desc:
                          'Approuver et créer un compte pour un commerçant ou propriétaire',
                      color: MboaColors.primary,
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.rocket_launch_rounded,
                      titre: 'Booster une annonce',
                      desc:
                          'Mettre en avant une annonce logement ou marketplace',
                      color: MboaColors.boost,
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.verified_rounded,
                      titre: 'Certifier un vendeur',
                      desc:
                          'Attribuer le badge Vérifié à un vendeur de confiance',
                      color: MboaColors.verified,
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.block_rounded,
                      titre: 'Gérer les bannissements',
                      desc:
                          'Bannir ou réactiver un compte utilisateur',
                      color: MboaColors.danger,
                      onTap: () {},
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

  Widget _buildQuickStat(
      String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String icon,
    required String titre,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: MboaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String titre,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MboaColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: MboaColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: MboaColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AdminNavItem {
  final IconData icon;
  final String label;
  _AdminNavItem({required this.icon, required this.label});
}