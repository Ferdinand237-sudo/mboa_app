import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/demande_vendeur_screen.dart';
import '../features/home/screens/main_screen.dart';
import '../features/auth/screens/register_etudiant_screen.dart';
import '../features/admin/screens/admin_screen.dart';
import '../features/admin/screens/admin_demandes_screen.dart';
import '../features/admin/screens/admin_signalements_screen.dart';
import '../features/ambassadeur/screens/ambassadeur_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/logement/screens/logement_detail_screen.dart';
import '../features/market/screens/article_detail_screen.dart';
import '../features/profil/screens/profil_vendeur_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';

// ── Navigation globale (hors arbre de widgets) ──────────────────
// Nécessaire pour ouvrir un écran depuis une notification (push reçue app
// fermée/arrière-plan, ou tap sur le centre de notifications in-app) : ces
// callbacks n'ont pas de BuildContext à disposition, contrairement à un
// GestureDetector classique.
final rootNavigatorKey = GlobalKey<NavigatorState>();

// ── Noms des routes ───────────────────────────────────────────
class AppRoutes {
  static const String splash         = '/';
  static const String onboarding     = '/onboarding';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String demandeVendeur = '/demande-vendeur';
  static const String main           = '/main';
  static const String registerEtudiant  = '/register/etudiant';
  static const String admin = '/admin';
  static const String ambassadeur = '/ambassadeur';
  static const String resetPassword = '/reset-password';
}

// ── Écoute les changements d'état d'authentification (utile pour la
// redirection automatique après une connexion OAuth via navigateur) ──
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ── Provider du router ────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final refreshStream =
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange);
  ref.onDispose(refreshStream.dispose);

  // Bascule automatiquement vers l'écran de nouveau mot de passe dès que
  // Supabase détecte le lien de réinitialisation reçu par email.
  late final GoRouter router;
  final recoverySub =
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      router.go(AppRoutes.resetPassword);
    }
  });
  ref.onDispose(recoverySub.cancel);

  router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.registerEtudiant,
        AppRoutes.demandeVendeur,
      ].contains(state.matchedLocation);

      // Connecté → aller sur main
      if (isLoggedIn && (isOnboarding || isAuthRoute)) {
        return AppRoutes.main;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.demandeVendeur,
        builder: (context, state) => const DemandeVendeurScreen(),
      ),
      GoRoute(
        path: AppRoutes.main,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerEtudiant,
        builder: (context, state) => const RegisterEtudiantScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: AppRoutes.ambassadeur,
        builder: (context, state) => const AmbassadeurScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
    ],
  );
  return router;
});

// ── Ouverture directe depuis une notification ───────────────────
// Deux formats de charge utile à router vers le bon écran :
//  - `data` FCM (push) : {type, conversation_id|demande_id|signalement_id},
//    voir supabase/functions/send-notification/index.ts.
//  - `lien` texte (notifications in-app, table public.notifications) :
//    mêmes chemins que mboa-web (/chat/<id>, /admin/demandes,
//    /admin/signalements, /logements/<id>, /marketplace/<id>,
//    /vendeur/<id>) — voir notifications_admin.sql / notifications_inapp.sql.

void _pousser(Widget screen) {
  rootNavigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
}

Future<void> ouvrirDepuisNotificationPush(Map<String, dynamic> data) async {
  switch (data['type'] as String?) {
    case 'message':
      final id = data['conversation_id'] as String?;
      if (id != null) await _ouvrirConversationParId(id);
      break;
    case 'demande':
      _pousser(const AdminDemandesScreen());
      break;
    case 'signalement':
      _pousser(const AdminSignalementsScreen());
      break;
  }
}

Future<void> ouvrirDepuisLien(String lien) async {
  if (lien.startsWith('/chat/')) {
    await _ouvrirConversationParId(lien.substring('/chat/'.length));
  } else if (lien == '/admin/demandes') {
    _pousser(const AdminDemandesScreen());
  } else if (lien == '/admin/signalements') {
    _pousser(const AdminSignalementsScreen());
  } else if (lien.startsWith('/logements/')) {
    await _ouvrirLogement(lien.substring('/logements/'.length));
  } else if (lien.startsWith('/marketplace/')) {
    await _ouvrirArticle(lien.substring('/marketplace/'.length));
  } else if (lien.startsWith('/vendeur/')) {
    await _ouvrirVendeur(lien.substring('/vendeur/'.length));
  }
}

// Reconstruit les mêmes paramètres que _buildConversationTile
// (chat_screen.dart) pour une conversation isolée, sans être passé par la
// liste — nécessaire car une notification arrive avec un simple id.
Future<void> _ouvrirConversationParId(String conversationId) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;
  try {
    final conv = await supabase
        .from('conversations')
        .select('*')
        .eq('id', conversationId)
        .maybeSingle();
    if (conv == null) return;

    final profil = await supabase
        .from('users')
        .select('role, est_admin')
        .eq('id', userId)
        .maybeSingle();
    final estAdmin = profil != null &&
        (profil['role'] == 'admin' || profil['est_admin'] == true);

    final isSupport = conv['is_support'] == true;
    final participants = List<String>.from(conv['participants'] ?? []);

    Map<String, dynamic> autreUser;
    String autreId;
    if (isSupport && !estAdmin) {
      autreUser = const {'nom': 'Assistant Mboa', 'photo_url': null, 'verified': true};
      autreId = userId;
    } else {
      autreId = isSupport
          ? (participants.isNotEmpty ? participants.first : userId)
          : participants.firstWhere((id) => id != userId, orElse: () => userId);
      final u = await supabase.from('users').select('nom, photo_url, verified').eq('id', autreId).maybeSingle();
      autreUser = u ?? {'nom': 'Utilisateur'};
    }

    final annonceId = conv['annonce_id']?.toString();
    final annonceType = conv['annonce_type'] as String?;
    String? annonceTitre;
    if (annonceId != null && annonceType != null) {
      final table = annonceType == 'logement' ? 'logements' : 'articles';
      final a = await supabase.from(table).select('titre').eq('id', annonceId).maybeSingle();
      annonceTitre = a?['titre'] as String?;
    }
    final emoji = annonceType == 'logement' ? '🏠' : '🛒';
    final sujet = isSupport
        ? (estAdmin ? '💬 Assistant Mboa' : '💬 Support Mboa')
        : (annonceTitre != null && annonceTitre.isNotEmpty)
            ? '$emoji $annonceTitre'
            : (annonceType == 'logement' ? '🏠 Logement' : '🛒 Article');

    _pousser(ConversationScreen(
      conversationId: conversationId,
      autreUser: autreUser,
      autreId: autreId,
      sujet: sujet,
      annonceId: annonceId,
      annonceType: annonceType,
      isSupport: isSupport,
      estAdminViewer: estAdmin,
      assignedAdminId: conv['assigned_admin_id'] as String?,
    ));
  } catch (_) {}
}

Future<void> _ouvrirLogement(String id) async {
  try {
    final data = await Supabase.instance.client
        .from('logements')
        .select('*, proprietaire:users!proprietaire_id(nom, photo_url, verified, note_globale)')
        .eq('id', id)
        .single();
    _pousser(LogementDetailScreen(logement: data));
  } catch (_) {}
}

Future<void> _ouvrirArticle(String id) async {
  try {
    final data = await Supabase.instance.client
        .from('articles')
        .select('*, vendeur:users!vendeur_id(nom, photo_url, verified, note_globale)')
        .eq('id', id)
        .single();
    _pousser(ArticleDetailScreen(article: data));
  } catch (_) {}
}

Future<void> _ouvrirVendeur(String id) async {
  try {
    final data = await Supabase.instance.client.from('users').select('*').eq('id', id).single();
    _pousser(ProfilVendeurScreen(vendeur: data));
  } catch (_) {}
}