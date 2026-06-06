import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

// ── Provider du service Auth ──────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ── Provider de l'état de session ────────────────────────
final sessionProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateStream;
});

// ── Provider de l'utilisateur courant ────────────────────
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUserId;
  if (userId == null) return null;
  return authService.getProfil(userId);
});

// ── Provider du rôle utilisateur ─────────────────────────
final userRoleProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role ?? 'visiteur';
});

// ── Provider isLoggedIn ───────────────────────────────────
final isLoggedInProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider).valueOrNull;
  return session?.session != null;
});

// ── Notifier pour les actions auth ───────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      final user = await _authService.getProfil(userId);
      state = AsyncValue.data(user);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  // ── Inscription ────────────────────────────────────────
  Future<String?> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    String? telephone,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _authService.inscrireEtudiant(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
        telephone: telephone,
      );
      await _init();
      return null;
    } catch (e) {
      state = const AsyncValue.data(null);
      return _parseError(e.toString());
    }
  }

  // ── Connexion ──────────────────────────────────────────
  Future<String?> connecter({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _authService.connecter(
        email: email,
        password: password,
      );
      await _init();
      return null;
    } catch (e) {
      state = const AsyncValue.data(null);
      return _parseError(e.toString());
    }
  }

  // ── Déconnexion ────────────────────────────────────────
  Future<void> deconnecter() async {
    await _authService.deconnecter();
    state = const AsyncValue.data(null);
  }

  // ── Parser les erreurs Supabase ────────────────────────
  String _parseError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (error.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre email';
    }
    if (error.contains('User already registered')) {
      return 'Un compte existe déjà avec cet email';
    }
    if (error.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref,
  );
});