import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';
import '../../logement/screens/logement_screen.dart';
import '../../market/screens/market_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../profil/screens/profil_screen.dart';
import '../../logement/screens/publier_screen.dart';
import '../../logement/screens/gestion_screen.dart';
import '../../../app/router.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _userRole = 'visiteur';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerRole();
  }

  Future<void> _chargerRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      final role = data['role'] ?? 'visiteur';

      // Rediriger l'admin vers son interface
      if (role == 'admin' && mounted) {
        context.go(AppRoutes.admin);
        return;
      }

      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── Navigation Visiteur ───────────────────────────────────
  List<Widget> get _screensVisiteur => [
    HomeScreen(
      onNavigateLogement: () => setState(() => _currentIndex = 1),
      onNavigateMarket: () => setState(() => _currentIndex = 2),
    ),
    const LogementScreen(),
    const MarketScreen(),
    const ChatScreen(),
    ProfilScreen(onOuvrirMessages: () => setState(() => _currentIndex = 3)),
  ];

  List<_NavItem> get _navItemsVisiteur => [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.apartment_rounded, label: 'Logement'),
    _NavItem(icon: Icons.storefront_rounded, label: 'Market'),
    _NavItem(icon: Icons.chat_bubble_rounded, label: 'Chat'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  // ── Navigation Vendeur ────────────────────────────────────
  List<Widget> get _screensVendeur => [
    HomeScreen(
      onNavigateLogement: () => setState(() => _currentIndex = 1),
      onNavigateMarket: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MarketScreen()),
      ),
    ),
    const GestionScreen(),
    const PublierScreen(),
    const ChatScreen(),
    ProfilScreen(onOuvrirMessages: () => setState(() => _currentIndex = 3)),
  ];

  List<_NavItem> get _navItemsVendeur => [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.list_alt_rounded, label: 'Gestion'),
    _NavItem(icon: Icons.add_circle_rounded, label: 'Publier'),
    _NavItem(icon: Icons.chat_bubble_rounded, label: 'Messages'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  bool get _isVendeur => _userRole == 'vendeur';

  List<Widget> get _screens =>
      _isVendeur ? _screensVendeur : _screensVisiteur;

  List<_NavItem> get _navItems =>
      _isVendeur ? _navItemsVendeur : _navItemsVisiteur;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MboaColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: MboaColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
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
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isActive = _currentIndex == index;

              // Bouton Publier spécial pour vendeur
              if (_isVendeur && index == 2) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _currentIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: MboaColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: MboaColors.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? MboaColors.primary
                                : MboaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

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
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}