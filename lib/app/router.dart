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
import '../features/splash/screens/splash_screen.dart';

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
}

// ── Provider du router ────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
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
    ],
  );
});