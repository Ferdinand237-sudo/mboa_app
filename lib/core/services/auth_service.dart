import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // ── Utilisateur courant ───────────────────────────────────
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get currentUserId => currentUser?.id;

  // ── Stream d'état de connexion ────────────────────────────
  Stream<AuthState> get authStateStream =>
      _supabase.auth.onAuthStateChange;

  // ── Inscription Étudiant ──────────────────────────────────
  Future<AuthResponse> inscrireEtudiant({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    String? telephone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nom': '$prenom $nom',
        'telephone': telephone,
        'role': AppConstants.roleVisiteur,
      },
    );
    return response;
  }

  // ── Connexion ─────────────────────────────────────────────
  Future<AuthResponse> connecter({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // ── Déconnexion ───────────────────────────────────────────
  Future<void> deconnecter() async {
    await _supabase.auth.signOut();
  }

  // ── Réinitialisation mot de passe ─────────────────────────
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // ── Récupérer le profil utilisateur ──────────────────────
  Future<UserModel?> getProfil(String userId) async {
    try {
      final data = await _supabase
          .from(AppConstants.tableUsers)
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // ── Mettre à jour le profil ───────────────────────────────
  Future<void> updateProfil({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _supabase
        .from(AppConstants.tableUsers)
        .update(data)
        .eq('id', userId);
  }

  // ── Envoyer demande compte commerçant ─────────────────────
  Future<void> envoyerDemandeCommercant({
    required String nom,
    required String email,
    required String whatsapp,
    required String typeActivite,
    required String description,
  }) async {
    await _supabase
        .from('demandes_compte')
        .insert({
          'nom': nom,
          'email': email,
          'whatsapp': whatsapp,
          'type_activite': typeActivite,
          'description': description,
        });
  }
}