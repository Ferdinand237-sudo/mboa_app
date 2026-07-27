import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/router.dart';
import '../../../core/mixins/refreshable_state.dart';
import 'ambassadeur_dashboard_screen.dart';
import 'ambassadeur_liste_screen.dart';

// Espace ambassadeur : conteneur autonome (Dashboard + Assignés), au même
// titre que AdminScreen. Accessible depuis le profil (lien "Espace
// ambassadeur", voir profil_screen.dart) pour tout compte avec le privilège
// estAmbassadeur, superposé à un compte visiteur/vendeur normal — pas
// remplacé par lui. Le dernier onglet ramène explicitement au compte de
// base plutôt que de compter uniquement sur le retour matériel/geste iOS.
class AmbassadeurScreen extends StatefulWidget {
  const AmbassadeurScreen({super.key});

  @override
  State<AmbassadeurScreen> createState() => _AmbassadeurScreenState();
}

class _AmbassadeurScreenState extends State<AmbassadeurScreen> {
  int _currentIndex = 0;

  final _dashboardKey = GlobalKey<State>();

  List<GlobalKey<State>?> get _refreshKeys => [_dashboardKey, null];

  final List<_AmbassadeurNavItem> _navItems = [
    _AmbassadeurNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _AmbassadeurNavItem(icon: Icons.people_alt_rounded, label: 'Assignés'),
  ];

  List<Widget> get _screens => [
    AmbassadeurDashboardScreen(key: _dashboardKey),
    // AmbassadeurListeScreen a déjà son propre abonnement realtime (voir
    // CLAUDE.md) : pas besoin de la rafraîchir manuellement ici.
    const AmbassadeurListeScreen(),
  ];

  void _selectionnerOnglet(int index) {
    setState(() => _currentIndex = index);
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
              color: Colors.black.withValues(alpha: 0.08),
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
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectionnerOnglet(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? MboaColors.primary.withValues(alpha: 0.12)
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
                // Retour au compte de base : jamais "actif" (ne remplace pas
                // _currentIndex, navigue simplement hors de cet espace).
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.main),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          color: MboaColors.textMuted,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Mon compte',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: MboaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbassadeurNavItem {
  final IconData icon;
  final String label;
  _AmbassadeurNavItem({required this.icon, required this.label});
}
