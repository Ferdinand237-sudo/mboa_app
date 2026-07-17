import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/router.dart';
import 'edit_profil_screen.dart';
import 'favoris_screen.dart';
import 'avis_moderation_screen.dart';
import 'devenir_contributeur_screen.dart';
import 'alertes_recherche_screen.dart';

class ProfilScreen extends StatefulWidget {
  final VoidCallback? onOuvrirMessages;

  const ProfilScreen({super.key, this.onOuvrirMessages});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  static const _prefsNotificationsKey = 'notifications_activees';

  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  int _nbFavoris = 0;
  int _nbAlertes = 0;
  int _nbMessagesNonLus = 0;
  int _nbAvisEnAttente = 0;
  bool _notificationsActivees = true;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
    _chargerNbFavoris();
    _chargerNbMessagesNonLus();
    _chargerPreferenceNotifications();
    _chargerNbAvisEnAttente();
    _chargerNbAlertes();
  }

  Future<void> _chargerNbAlertes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('alertes_recherche')
          .select('id')
          .eq('user_id', user.id);
      if (mounted) setState(() => _nbAlertes = List.from(data).length);
    } catch (_) {}
  }

  Future<void> _chargerNbAvisEnAttente() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('avis')
          .select('id')
          .eq('cible_id', user.id)
          .eq('valide', false)
          .not('annonce_id', 'is', null);
      if (mounted) setState(() => _nbAvisEnAttente = List.from(data).length);
    } catch (_) {}
  }

  Future<void> _chargerPreferenceNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _notificationsActivees =
          prefs.getBool(_prefsNotificationsKey) ?? true);
    }
  }

  Future<void> _basculerNotifications(bool valeur) async {
    setState(() => _notificationsActivees = valeur);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsNotificationsKey, valeur);
  }

  Future<void> _chargerNbMessagesNonLus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('conversations')
          .select('non_lu')
          .contains('participants', [user.id]);
      int total = 0;
      for (final conv in List<Map<String, dynamic>>.from(data)) {
        final nonLu = conv['non_lu'];
        if (nonLu is Map && nonLu[user.id] != null) {
          total += (nonLu[user.id] as num).toInt();
        }
      }
      if (mounted) setState(() => _nbMessagesNonLus = total);
    } catch (_) {}
  }

  Future<void> _chargerNbFavoris() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('favoris')
          .select('id')
          .eq('user_id', user.id);
      if (mounted) {
        setState(() => _nbFavoris = List.from(data).length);
      }
    } catch (_) {}
  }

  Future<void> _chargerProfil() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();
      setState(() {
        _user = data;
        _isLoading = false;
      });
    } catch (e) {
      // Si profil pas encore créé on utilise les données Auth
      setState(() {
        _user = {
          'nom': currentUser.userMetadata?['nom'] ?? 'Utilisateur',
          'email': currentUser.email ?? '',
          'role': currentUser.userMetadata?['role'] ?? 'visiteur',
          'verified': false,
          'telephone': currentUser.userMetadata?['telephone'] ?? '',
          'date_inscription': currentUser.createdAt,
          'note_globale': 0.0,
          'nb_avis': 0,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _ouvrirModifierProfil() async {
    if (_user == null) return;
    final modifie = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilScreen(user: _user!),
      ),
    );
    if (modifie == true) {
      _chargerProfil();
    }
  }

  Future<void> _ouvrirAlertes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlertesRechercheScreen()),
    );
    _chargerNbAlertes();
  }

  void _ouvrirChangerMotDePasse() {
    final formKey = GlobalKey<FormState>();
    final nouveauController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
          ),
          title: const Text(
            '🔒 Changer le mot de passe',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nouveauController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe',
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Minimum 6 caractères'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                  ),
                  validator: (v) => v != nouveauController.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await _supabase.auth.updateUser(
                          UserAttributes(password: nouveauController.text),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Mot de passe mis à jour'),
                              backgroundColor: MboaColors.primary,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors du changement de mot de passe'),
                              backgroundColor: MboaColors.danger,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirConfidentialite() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        title: const Text(
          '🛡 Confidentialité',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Mboa protège tes données personnelles : ton numéro WhatsApp et ton '
          'email ne sont visibles que par les vendeurs/propriétaires avec qui '
          'tu échanges via le chat de l\'application. Aucune donnée n\'est '
          'partagée avec des tiers.',
          style: TextStyle(fontFamily: 'Poppins', color: MboaColors.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _ouvrirAideSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        title: const Text(
          '💬 Aide & Support',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Une question ou un problème avec ton compte, une annonce ou un '
          'paiement ? Contacte l\'équipe Mboa via le chat de l\'application ou '
          'par WhatsApp au support Mboa.',
          style: TextStyle(fontFamily: 'Poppins', color: MboaColors.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _ouvrirAPropos() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/logo/logo_mboa.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Text('🏘', style: TextStyle(fontSize: 32)),
        ),
      ),
      applicationLegalese: AppConstants.appSlogan,
    );
  }

  bool get _isConnected => _supabase.auth.currentUser != null;

  String get _initiales {
    final nom = _user?['nom'] ?? '';
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (nom.isNotEmpty) return nom.substring(0, 1).toUpperCase();
    return 'U';
  }

  String get _dateInscription {
    try {
      final date = DateTime.parse(
          _user?['date_inscription'] ?? DateTime.now().toIso8601String());
      final mois = [
        '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${mois[date.month]} ${date.year}';
    } catch (_) {
      return 'Récemment';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MboaColors.background,
        body: Center(
          child: CircularProgressIndicator(color: MboaColors.primary),
        ),
      );
    }
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: _isConnected ? _buildConnected() : _buildNotConnected(),
    );
  }

  Widget _buildConnected() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: MboaColors.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mon Profil',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: _ouvrirModifierProfil,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Avatar
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: _user?['photo_url'] != null
                        ? ClipOval(
                            child: Image.network(
                              _user!['photo_url'],
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  _initiales,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                      child: Text(
                        _initiales,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nom
                  Text(
                    _user?['nom'] ?? 'Utilisateur',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    _user?['email'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_user?['verified'] == true)
                        _buildHeaderBadge(
                          '✅ Compte vérifié',
                          MboaColors.verified,
                        ),
                      if (_user?['verified'] == true)
                        const SizedBox(width: 8),
                      _buildHeaderBadge(
                        '📅 Depuis $_dateInscription',
                        Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('$_nbFavoris', 'Favoris', '❤️'),
                        _buildStatDivider(),
                        _buildStat('$_nbAlertes', 'Alertes', '🔔'),
                        _buildStatDivider(),
                        _buildStat('$_nbMessagesNonLus', 'Messages', '💬'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Mes activités ────────────────────────────────
          _buildSection(
            titre: 'Mes activités',
            items: [
              _buildMenuItem(
                icon: Icons.favorite_rounded,
                color: MboaColors.danger,
                label: 'Mes favoris',
                badge: '$_nbFavoris',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FavorisScreen(),
                    ),
                  );
                  _chargerNbFavoris();
                },
              ),
              _buildMenuItem(
                icon: Icons.notifications_rounded,
                color: MboaColors.boost,
                label: 'Mes alertes de recherche',
                badge: '$_nbAlertes',
                onTap: _ouvrirAlertes,
              ),
              _buildMenuItem(
                icon: Icons.chat_bubble_rounded,
                color: MboaColors.primary,
                label: 'Mes messages',
                badge: '$_nbMessagesNonLus',
                onTap: () {
                  if (widget.onOuvrirMessages != null) {
                    widget.onOuvrirMessages!();
                  }
                },
              ),
              if (_user?['role'] == 'vendeur')
                _buildMenuItem(
                  icon: Icons.star_rate_rounded,
                  color: MboaColors.boost,
                  label: 'Avis à modérer',
                  badge: '$_nbAvisEnAttente',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AvisModerationScreen(),
                      ),
                    );
                    _chargerNbAvisEnAttente();
                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Mon compte ───────────────────────────────────
          _buildSection(
            titre: 'Mon compte',
            items: [
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                color: MboaColors.primary,
                label: 'Modifier mon profil',
                onTap: _ouvrirModifierProfil,
              ),
              _buildMenuItem(
                icon: Icons.phone_outlined,
                color: MboaColors.primaryLight,
                label: 'Mon WhatsApp',
                subtitle: _user?['telephone'] ?? 'Non renseigné',
                onTap: _ouvrirModifierProfil,
              ),
              _buildMenuItem(
                icon: Icons.lock_outline_rounded,
                color: MboaColors.textMuted,
                label: 'Changer le mot de passe',
                onTap: _ouvrirChangerMotDePasse,
              ),
              if (_user?['role'] == 'visiteur')
                _buildMenuItem(
                  icon: Icons.storefront_outlined,
                  color: MboaColors.secondary,
                  label: 'Devenir contributeur',
                  subtitle: 'Publier des logements ou articles',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DevenirContributeurScreen()),
                  ),
                ),
              if (_user?['role'] == 'vendeur')
                _buildMenuItem(
                  icon: Icons.add_business_outlined,
                  color: MboaColors.secondary,
                  label: 'Étendre mes activités',
                  subtitle: 'Ajouter logements et/ou articles',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DevenirContributeurScreen(dejaVendeur: true)),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Paramètres ───────────────────────────────────
          _buildSection(
            titre: 'Paramètres',
            items: [
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                color: MboaColors.secondary,
                label: 'Notifications',
                trailing: Switch(
                  value: _notificationsActivees,
                  onChanged: _basculerNotifications,
                  activeColor: MboaColors.primary,
                ),
                onTap: () => _basculerNotifications(!_notificationsActivees),
              ),
              _buildMenuItem(
                icon: Icons.shield_outlined,
                color: MboaColors.primary,
                label: 'Confidentialité',
                onTap: _ouvrirConfidentialite,
              ),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                color: MboaColors.primaryLight,
                label: 'Aide & Support',
                onTap: _ouvrirAideSupport,
              ),
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                color: MboaColors.textMuted,
                label: 'À propos de Mboa',
                subtitle: 'Version ${AppConstants.appVersion}',
                onTap: _ouvrirAPropos,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Rôle utilisateur ─────────────────────────────
          if (_user?['role'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MboaColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                  border: Border.all(
                    color: MboaColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('👤', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Type de compte',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: MboaColors.textMuted,
                          ),
                        ),
                        Text(
                          _user?['role'] == 'vendeur'
                              ? '🏪 Vendeur / Commerçant'
                              : _user?['role'] == 'admin'
                                  ? '👑 Administrateur'
                                  : _user?['role'] == 'ambassadeur'
                                      ? '🧭 Ambassadeur Mboa'
                                      : '🎓 Étudiant / Visiteur',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: MboaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── Déconnexion ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _showLogoutDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: MboaColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                  border: Border.all(
                    color: MboaColors.danger.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: MboaColors.danger, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Déconnexion',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Vue non connecté ───────────────────────────────────────
  Widget _buildNotConnected() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: MboaColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mon Profil',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: MboaColors.text,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Veuillez créer un compte pour configurer votre profil et accéder à toutes les fonctionnalités.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: MboaColors.textMuted,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: MboaSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('Créer un compte'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: MboaSizes.buttonHeight,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets helpers ────────────────────────────────────────
  Widget _buildSection({
    required String titre,
    required List<Widget> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              titre,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MboaColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String label,
    String? subtitle,
    String? badge,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: MboaColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MboaColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: MboaTextStyles.caption),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: MboaColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MboaColors.primary,
                  ),
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: MboaColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildHeaderBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  bool _isLoggingOut = false;

  void _showLogoutDialog() {
    if (_isLoggingOut) return;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
          ),
          title: const Text(
            'Déconnexion',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Es-tu sûr de vouloir te déconnecter ?',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: MboaColors.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoggingOut
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      setDialogState(() => _isLoggingOut = true);
                      setState(() => _isLoggingOut = true);
                      try {
                        await Supabase.instance.client.auth.signOut();
                      } catch (_) {
                        // On force la déconnexion locale même si l'appel
                        // réseau échoue : l'utilisateur ne doit jamais
                        // rester bloqué sur un compte qu'il veut quitter.
                      }
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (mounted) context.go(AppRoutes.onboarding);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: MboaColors.danger,
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }
}