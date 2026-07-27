import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';
import '../../logement/screens/logement_screen.dart';
import '../../market/screens/market_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../profil/screens/profil_screen.dart';
import '../../logement/screens/publier_screen.dart';
import '../../logement/screens/gestion_screen.dart';
import '../../../core/mixins/refreshable_state.dart';
import '../../../core/services/unread_service.dart';
import '../../../core/onboarding/tour_step.dart';
import '../../../core/onboarding/tour_texts.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _userRole = 'visiteur';
  bool _isLoading = true;
  int _nbMessagesNonLus = 0;

  // Un seul canal pour toute la durée de vie de l'écran racine (pas un
  // par item de liste) : coût négligeable, contrairement au realtime sur
  // les listes publiques à fort trafic évité ailleurs (voir CLAUDE.md).
  RealtimeChannel? _canalConversations;

  // Clés utilisées pour déclencher un rafraîchissement explicite au
  // changement d'onglet : IndexedStack garde tous les onglets montés en
  // permanence, donc leur initState ne se relance jamais tout seul.
  final _homeKey = GlobalKey<State>();
  final _logementKey = GlobalKey<State>();
  final _marketKey = GlobalKey<State>();
  final _chatKey = GlobalKey<State>();
  final _profilKey = GlobalKey<State>();
  final _gestionKey = GlobalKey<State>();
  final _publierKey = GlobalKey<State>();

  // ── Cibles de la visite guidée (voir core/onboarding) ─────────────
  // Portées par MainScreen car elles couvrent à la fois des éléments du
  // header de HomeScreen (passés en paramètre, voir plus bas) et des items
  // de la bottom nav bar définie ici — les deux sont dans le même arbre de
  // widgets au moment du build, donc atteignables par les mêmes GlobalKeys.
  final _tourLogoKey = GlobalKey();
  final _tourRechercheKey = GlobalKey();
  final _tourCarteKey = GlobalKey();
  final _tourNotifKey = GlobalKey();
  final _tourRegisterKey = GlobalKey();
  final _tourNavLogementKey = GlobalKey();
  final _tourNavMarketKey = GlobalKey();
  final _tourNavChatKey = GlobalKey();
  final _tourNavProfilKey = GlobalKey();
  final _tourNavGestionKey = GlobalKey();
  final _tourNavPublierKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _chargerRole();
    _chargerNbMessagesNonLus();
    _ecouterConversations();
  }

  @override
  void dispose() {
    if (_canalConversations != null) {
      Supabase.instance.client.removeChannel(_canalConversations!);
    }
    super.dispose();
  }

  Future<void> _chargerNbMessagesNonLus() async {
    final nb = await UnreadService.nbMessagesNonLus();
    if (mounted) setState(() => _nbMessagesNonLus = nb);
  }

  void _ecouterConversations() {
    _canalConversations = Supabase.instance.client
        .channel('main_screen_conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (_) => _chargerNbMessagesNonLus(),
        )
        .subscribe();
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

      // Admin/ambassadeur sont désormais des privilèges superposés à un
      // compte visiteur/vendeur normal (est_admin/est_ambassadeur, voir
      // roles_multiples_admin_ambassadeur) : on n'y redirige plus de force,
      // le compte garde sa navigation habituelle et accède à son espace
      // dédié via le profil (voir profil_screen.dart, "Espaces privilégiés").
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool get _isLoggedIn => Supabase.instance.client.auth.currentUser != null;

  // Visite guidée de l'accueil : le contenu dépend du rôle/statut de
  // connexion, comme sur le web (TOUR_HOME_VISITEUR/ETUDIANT/VENDEUR).
  List<TourStep> get _tourStepsHome {
    if (_isVendeur) {
      return buildTourSteps(
        [_tourLogoKey, _tourNavGestionKey, _tourNavPublierKey, _tourNavChatKey, _tourNavProfilKey],
        tourHomeVendeurTexts,
      );
    }
    if (_isLoggedIn) {
      return buildTourSteps(
        [
          _tourLogoKey,
          _tourRechercheKey,
          _tourNavLogementKey,
          _tourNavMarketKey,
          _tourCarteKey,
          _tourNavChatKey,
          _tourNotifKey,
          _tourNavProfilKey,
        ],
        tourHomeEtudiantTexts,
      );
    }
    return buildTourSteps(
      [
        _tourLogoKey,
        _tourRechercheKey,
        _tourNavLogementKey,
        _tourNavMarketKey,
        _tourCarteKey,
        _tourNavChatKey,
        _tourRegisterKey,
      ],
      tourHomeVisiteurTexts,
    );
  }

  // Lancement automatique (une fois) réservé au visiteur non connecté sur
  // l'accueil, comme sur le web (voir SEEN_KEY_HOME_VISITEUR côté web).
  String? get _tourAutoOpenKey => (!_isVendeur && !_isLoggedIn) ? 'tour_seen_home_visiteur' : null;

  // ── Navigation Visiteur ───────────────────────────────────
  List<Widget> get _screensVisiteur => [
    HomeScreen(
      key: _homeKey,
      onNavigateLogement: () => _onTabTapped(1),
      onNavigateMarket: () => _onTabTapped(2),
      tourLogoKey: _tourLogoKey,
      tourRechercheKey: _tourRechercheKey,
      tourCarteKey: _tourCarteKey,
      tourNotifKey: _tourNotifKey,
      tourRegisterKey: _tourRegisterKey,
      tourSteps: _tourStepsHome,
      tourAutoOpenKey: _tourAutoOpenKey,
    ),
    LogementScreen(key: _logementKey),
    MarketScreen(key: _marketKey),
    ChatScreen(key: _chatKey),
    ProfilScreen(key: _profilKey, onOuvrirMessages: () => _onTabTapped(3)),
  ];

  List<GlobalKey<State>?> get _refreshKeysVisiteur =>
      [_homeKey, _logementKey, _marketKey, _chatKey, _profilKey];

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
      key: _homeKey,
      onNavigateLogement: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LogementScreen()),
      ),
      onNavigateMarket: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MarketScreen()),
      ),
      tourLogoKey: _tourLogoKey,
      tourRechercheKey: _tourRechercheKey,
      tourCarteKey: _tourCarteKey,
      tourNotifKey: _tourNotifKey,
      tourRegisterKey: _tourRegisterKey,
      tourSteps: _tourStepsHome,
      tourAutoOpenKey: _tourAutoOpenKey,
    ),
    GestionScreen(key: _gestionKey),
    PublierScreen(key: _publierKey),
    ChatScreen(key: _chatKey),
    ProfilScreen(key: _profilKey, onOuvrirMessages: () => _onTabTapped(3)),
  ];

  List<GlobalKey<State>?> get _refreshKeysVendeur =>
      [_homeKey, _gestionKey, _publierKey, _chatKey, _profilKey];

  List<_NavItem> get _navItemsVendeur => [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.list_alt_rounded, label: 'Gestion'),
    _NavItem(icon: Icons.add_circle_rounded, label: 'Publier'),
    _NavItem(icon: Icons.chat_bubble_rounded, label: 'Messages'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  // Ambassadeur (comme admin) n'est plus un mode exclusif de la nav
  // principale mais un privilège superposé, avec son propre espace dédié
  // accessible depuis le profil (voir AmbassadeurScreen, router.dart) —
  // la nav de base reste toujours vendeur/visiteur.
  bool get _isVendeur => _userRole == 'vendeur';

  List<Widget> get _screens => _isVendeur ? _screensVendeur : _screensVisiteur;

  List<_NavItem> get _navItems =>
      _isVendeur ? _navItemsVendeur : _navItemsVisiteur;

  List<GlobalKey<State>?> get _refreshKeys =>
      _isVendeur ? _refreshKeysVendeur : _refreshKeysVisiteur;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    final state = _refreshKeys[index]?.currentState;
    if (state is RefreshableState) (state as RefreshableState).refresh();
    _chargerNbMessagesNonLus();
  }

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

  GlobalKey? _tourKeyForNavIndex(int index) {
    if (_isVendeur) {
      switch (index) {
        case 1:
          return _tourNavGestionKey;
        case 2:
          return _tourNavPublierKey;
        case 3:
          return _tourNavChatKey;
        case 4:
          return _tourNavProfilKey;
      }
    } else {
      switch (index) {
        case 1:
          return _tourNavLogementKey;
        case 2:
          return _tourNavMarketKey;
        case 3:
          return _tourNavChatKey;
        case 4:
          return _tourNavProfilKey;
      }
    }
    return null;
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
              final tourKey = _tourKeyForNavIndex(index);

              // Bouton Publier spécial pour vendeur
              if (_isVendeur && index == 2) {
                return Expanded(
                  child: KeyedSubtree(
                    key: tourKey,
                    child: GestureDetector(
                    onTap: () => _onTabTapped(index),
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
                  ),
                );
              }

              return Expanded(
                child: KeyedSubtree(
                  key: tourKey,
                  child: GestureDetector(
                  onTap: () => _onTabTapped(index),
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
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              item.icon,
                              color: isActive
                                  ? MboaColors.primary
                                  : MboaColors.textMuted,
                              size: 24,
                            ),
                            // Onglet Chat/Messages : index 3, aussi bien
                            // chez visiteur que vendeur.
                            if (index == 3 && _nbMessagesNonLus > 0)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  decoration: BoxDecoration(
                                    color: MboaColors.danger,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _nbMessagesNonLus > 9 ? '9+' : '$_nbMessagesNonLus',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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