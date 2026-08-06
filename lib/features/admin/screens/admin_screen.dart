import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/router.dart';
import '../../map/screens/map_screen.dart';
import 'admin_users_screen.dart';
import 'admin_annonces_screen.dart';
import 'admin_signalements_screen.dart';
import 'admin_demandes_screen.dart';
import 'admin_verifications_screen.dart';
import 'admin_villes_screen.dart';
import 'admin_reservations_screen.dart';
import '../../../core/mixins/refreshable_state.dart';
import '../../../core/services/ville_service.dart';
import '../../chat/screens/chat_screen.dart';
// import 'admin_demandes_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  // Onglets 3 (Signalements) et 4 (Vérifs) : badge temps réel affiché
  // quand un élément arrive pendant que l'admin est sur un autre onglet
  // (voir CLAUDE.md, section temps réel).
  static const int _indexSignalements = 3;
  static const int _indexVerifications = 4;
  int _badgeSignalements = 0;
  int _badgeVerifications = 0;

  // Barre réduite à 5 onglets (constat : 6 onglets + "Mon compte" saturait
  // la barre). Demandes et "Mon compte" passent dans le menu hamburger du
  // Dashboard (_DashboardTab) — Signalements et Vérifs restent dans la
  // barre car ce sont les deux seuls onglets à badge temps réel (urgence),
  // le Dashboard a déjà son alerte "Actions requises" pour rattraper
  // Demandes.
  //
  // Signalements et Vérifs ont déjà leur propre abonnement realtime
  // (voir CLAUDE.md) : pas de clé de rafraîchissement nécessaire pour eux.
  final _dashboardKey = GlobalKey<State>();
  final _usersKey = GlobalKey<State>();
  final _annoncesKey = GlobalKey<State>();

  List<GlobalKey<State>?> get _refreshKeys =>
      [_dashboardKey, _usersKey, _annoncesKey, null, null];

  final List<_AdminNavItem> _navItems = [
    _AdminNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _AdminNavItem(icon: Icons.people_rounded, label: 'Utilisateurs'),
    _AdminNavItem(icon: Icons.list_alt_rounded, label: 'Annonces'),
    _AdminNavItem(icon: Icons.flag_rounded, label: 'Signalements'),
    _AdminNavItem(icon: Icons.verified_user_rounded, label: 'Vérifs'),
  ];

  List<Widget> get _screens => [
    _DashboardTab(key: _dashboardKey),
    AdminUsersScreen(key: _usersKey),
    AdminAnnoncesScreen(key: _annoncesKey),
    AdminSignalementsScreen(
      onNouvelElement: () {
        if (_currentIndex != _indexSignalements && mounted) {
          setState(() => _badgeSignalements++);
        }
      },
    ),
    AdminVerificationsScreen(
      onNouvelElement: () {
        if (_currentIndex != _indexVerifications && mounted) {
          setState(() => _badgeVerifications++);
        }
      },
    ),
  ];

  int _badgePourOnglet(int index) {
    if (index == _indexSignalements) return _badgeSignalements;
    if (index == _indexVerifications) return _badgeVerifications;
    return 0;
  }

  void _selectionnerOnglet(int index) {
    setState(() {
      _currentIndex = index;
      if (index == _indexSignalements) _badgeSignalements = 0;
      if (index == _indexVerifications) _badgeVerifications = 0;
    });
    final state = _refreshKeys[index]?.currentState;
    if (state is RefreshableState) (state as RefreshableState).refresh();
  }

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
              children: [
                ...List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isActive = _currentIndex == index;
                  final badge = _badgePourOnglet(index);
                  return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectionnerOnglet(index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
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
                            if (badge > 0)
                              Positioned(
                                top: 0,
                                right: 6,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: MboaColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
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
              ],
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
  const _DashboardTab({super.key});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> with RefreshableState {
  final _supabase = Supabase.instance.client;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _chargerStats();
    // Un admin peut arriver ici directement (redirection au login) sans
    // jamais monter HomeScreen, seul autre point d'entrée qui initialise
    // VilleService — nécessaire pour "Gérer la carte" et l'écran villes.
    VilleService.instance.init();
  }

  @override
  Future<void> refresh() => _chargerStats();

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        title: const Text(
          'Déconnexion',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Es-tu sûr de vouloir te déconnecter ?',
          style: TextStyle(fontFamily: 'Poppins', color: MboaColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go(AppRoutes.onboarding);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MboaColors.danger),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
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
        // Conversations Assistant Mboa non encore prises en charge par un
        // admin (voir migration 20260726000000_assistant_mboa.sql) : même
        // logique "actions requises" que demandes/signalements.
        final assistant = await _supabase
          .from('conversations')
          .select('id')
          .eq('is_support', true)
          .not('dernier_message', 'is', null)
          .isFilter('assigned_admin_id', null);

      if (mounted) {
        setState(() {
          _stats = {
            'users': (users as List).length,
            'logements': (logements as List).length,
            'articles': (articles as List).length,
            'signalements': (signalements as List).length,
            'demandes': (demandes as List).length,
            'assistant': (assistant as List).length,
          };
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Widget _buildMenu(BuildContext context) {
    final nbDemandes = _stats['demandes'] ?? 0;
    final nbAssistant = _stats['assistant'] ?? 0;
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MboaColors.text,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mail_rounded, color: MboaColors.primary),
              title: const Text('Demandes', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              trailing: nbDemandes > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: MboaColors.danger, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        '$nbDemandes',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDemandesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded, color: MboaColors.primary),
              title: const Text('Assistant Mboa', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              trailing: nbAssistant > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: MboaColors.danger, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        '$nbAssistant',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_rounded, color: MboaColors.primary),
              title: const Text('Réservations', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReservationsScreen()));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.arrow_back_rounded, color: MboaColors.textMuted),
              title: const Text('Mon compte', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.main);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MboaColors.background,
      drawer: _buildMenu(context),
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
                        Row(
                          children: [
                            // Onglets Demandes + Mon compte, retirés de la
                            // barre du bas pour la ramener à 5 éléments.
                            GestureDetector(
                              onTap: () => _scaffoldKey.currentState?.openDrawer(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Bouton déconnexion
                            GestureDetector(
                              onTap: () => _confirmerDeconnexion(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
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
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stats rapides
                    Row(
                      children: [
                        _buildQuickStat(
                          '👥',
                          _isLoadingStats ? '…' : '${_stats['users'] ?? 0}',
                          'Utilisateurs',
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          '🏠',
                          _isLoadingStats ? '…' : '${_stats['logements'] ?? 0}',
                          'Logements',
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          '🛒',
                          _isLoadingStats ? '…' : '${_stats['articles'] ?? 0}',
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
                        (_stats['demandes'] ?? 0) > 0 ||
                        (_stats['assistant'] ?? 0) > 0) ...[
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDemandesScreen(),
                            ),
                          ),
                        ),
                      if ((_stats['signalements'] ?? 0) > 0)
                        _buildAlertCard(
                          icon: '🚩',
                          titre: 'Signalements',
                          desc:
                              '${_stats['signalements']} signalement(s) à traiter',
                          color: MboaColors.danger,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSignalementsScreen(),
                            ),
                          ),
                        ),
                      if ((_stats['assistant'] ?? 0) > 0)
                        _buildAlertCard(
                          icon: '🤖',
                          titre: 'Assistant Mboa',
                          desc:
                              '${_stats['assistant']} conversation(s) en attente de réponse',
                          color: MboaColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatScreen(),
                            ),
                          ),
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
                      icon: Icons.map_rounded,
                      titre: 'Gérer la carte',
                      desc:
                          'Ajouter des lieux publics (écoles, hôpitaux, marchés...) visibles par tous',
                      color: MboaColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      icon: Icons.location_city_rounded,
                      titre: 'Villes couvertes',
                      desc:
                          'Ajouter, désactiver ou ajuster une ville couverte par Mboa',
                      color: MboaColors.accent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminVillesScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      icon: Icons.person_add_rounded,
                      titre: 'Créer un compte vendeur',
                      desc:
                          'Approuver et créer un compte pour un commerçant ou propriétaire',
                      color: MboaColors.secondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDemandesScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      icon: Icons.rocket_launch_rounded,
                      titre: 'Booster une annonce',
                      desc:
                          'Mettre en avant une annonce logement ou marketplace',
                      color: MboaColors.boost,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAnnoncesScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      icon: Icons.verified_rounded,
                      titre: 'Certifier un vendeur',
                      desc:
                          'Attribuer le badge Vérifié à un vendeur de confiance',
                      color: MboaColors.verified,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminUsersScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      icon: Icons.block_rounded,
                      titre: 'Gérer les bannissements',
                      desc:
                          'Bannir ou réactiver un compte utilisateur',
                      color: MboaColors.danger,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminUsersScreen(),
                        ),
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