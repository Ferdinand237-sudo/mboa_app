import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/mixins/refreshable_state.dart';
import 'admin_demandes_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with RefreshableState {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  Map<String, String> _statutVerificationParUser = {};
  bool _isLoadingUsers = true;
  // Miroir de FILTRES_ROLE (users-client.tsx) : absent côté mobile jusqu'ici,
  // seuls les badges par carte permettaient de distinguer les types de
  // comptes, sans façon de segmenter la liste complète.
  String _filtreRole = 'tous';

  static const _filtresRole = [
    {'valeur': 'tous', 'label': 'Tous'},
    {'valeur': 'visiteur', 'label': '🎓 Visiteurs'},
    {'valeur': 'vendeur', 'label': '🏪 Vendeurs'},
    {'valeur': 'ambassadeur', 'label': '🧭 Ambassadeurs'},
    {'valeur': 'admin', 'label': '👑 Admins'},
  ];

  bool _estAdmin(Map<String, dynamic> u) => u['role'] == 'admin' || u['est_admin'] == true;
  bool _estAmbassadeur(Map<String, dynamic> u) =>
      u['role'] == 'ambassadeur' || u['est_ambassadeur'] == true;

  List<Map<String, dynamic>> get _usersAffiches {
    switch (_filtreRole) {
      case 'admin':
        return _users.where(_estAdmin).toList();
      case 'ambassadeur':
        return _users.where(_estAmbassadeur).toList();
      case 'tous':
        return _users;
      default:
        return _users.where((u) => u['role'] == _filtreRole).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _chargerUsers();
  }

  @override
  Future<void> refresh() => _chargerUsers();

  Future<void> _chargerUsers() async {
    try {
      final resultats = await Future.wait<dynamic>([
        _supabase.from('users').select().order('date_inscription', ascending: false),
        _supabase.from(AppConstants.tableVerificationsTerrain).select('user_id, statut'),
      ]);
      final users = List<Map<String, dynamic>>.from(resultats[0] as List);
      final verifications = List<Map<String, dynamic>>.from(resultats[1] as List);

      if (mounted) {
        setState(() {
          _users = users;
          _statutVerificationParUser = {
            for (final v in verifications) v['user_id'] as String: v['statut'] as String,
          };
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _creerAmbassadeur() async {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final whatsappController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusXl)),
        title: const Text('🧭 Créer un ambassadeur', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe temporaire'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: whatsappController,
                  decoration: const InputDecoration(labelText: 'WhatsApp (optionnel)'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext);
              try {
                final response = await _supabase.functions.invoke('create-ambassadeur', body: {
                  'nom': nomController.text.trim(),
                  'email': emailController.text.trim(),
                  'password': passwordController.text,
                  'whatsapp': whatsappController.text.trim(),
                });
                if (response.status == 200) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Ambassadeur ${nomController.text.trim()} créé'), backgroundColor: MboaColors.primary),
                    );
                    _chargerUsers();
                  }
                } else {
                  final error = (response.data as Map?)?['error'] ?? 'Erreur inconnue';
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $error'), backgroundColor: MboaColors.danger),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: MboaColors.danger),
                  );
                }
              }
            },
            child: const Text('Créer le compte'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActif(
        String userId, bool currentValue) async {
      try {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(MboaSizes.radiusXl),
            ),
            title: Text(
              currentValue ? '🚫 Bannir ce compte' : '✅ Réactiver ce compte',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            content: Text(
              currentValue
                  ? 'Ce compte sera banni et l\'utilisateur ne pourra plus se connecter.'
                  : 'Ce compte sera réactivé et l\'utilisateur pourra se reconnecter.',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: MboaColors.textMuted,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentValue
                      ? MboaColors.danger
                      : MboaColors.verified,
                ),
                child: Text(
                  currentValue ? 'Bannir' : 'Réactiver',
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await _supabase
              .from('users')
              .update({'actif': !currentValue})
              .eq('id', userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  currentValue
                      ? '🚫 Compte banni'
                      : '✅ Compte réactivé',
                ),
                backgroundColor: currentValue
                    ? MboaColors.danger
                    : MboaColors.verified,
              ),
            );
            _chargerUsers();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : ${e.toString()}'),
              backgroundColor: MboaColors.danger,
            ),
          );
        }
      }
    }

  Future<void> _toggleVerified(
      String userId, bool currentValue) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
          ),
          title: Text(
            currentValue
                ? '🚫 Retirer la certification'
                : '✅ Certifier ce compte',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Text(
            currentValue
                ? 'Cette action retirera la certification de ce compte.'
                : 'Cette action certifiera ce compte.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: MboaColors.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentValue
                    ? MboaColors.danger
                    : MboaColors.verified,
              ),
              child: Text(currentValue ? 'Décertifier' : 'Certifier'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _supabase
            .from('users')
            .update({'verified': !currentValue})
            .eq('id', userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentValue
                    ? '🚫 Certification retirée'
                    : '✅ Compte certifié',
              ),
              backgroundColor: currentValue
                  ? MboaColors.danger
                  : MboaColors.verified,
            ),
          );
          _chargerUsers();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _togglePrivilege({
    required String userId,
    required String champ,
    required bool currentValue,
    required String titreOn,
    required String titreOff,
    required String bodyOn,
    required String bodyOff,
    required String labelOn,
    required String labelOff,
  }) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
          ),
          title: Text(
            currentValue ? titreOff : titreOn,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Text(
            currentValue ? bodyOff : bodyOn,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: MboaColors.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    currentValue ? MboaColors.danger : MboaColors.verified,
              ),
              child: Text(currentValue ? labelOff : labelOn),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _supabase
            .from('users')
            .update({champ: !currentValue})
            .eq('id', userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentValue ? '✅ $titreOff' : '✅ $titreOn'),
              backgroundColor:
                  currentValue ? MboaColors.danger : MboaColors.verified,
            ),
          );
          _chargerUsers();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _toggleEstAdmin(String userId, bool currentValue) => _togglePrivilege(
        userId: userId,
        champ: 'est_admin',
        currentValue: currentValue,
        titreOn: '👑 Nommer administrateur',
        titreOff: 'Retirer les droits administrateur',
        bodyOn:
            'Ce compte garde son expérience actuelle (visiteur ou vendeur) et gagne en plus un accès "Administration" dans son profil.',
        bodyOff: 'Ce compte perdra l\'accès à l\'espace d\'administration.',
        labelOn: 'Nommer administrateur',
        labelOff: 'Retirer',
      );

  Future<void> _toggleEstAmbassadeur(String userId, bool currentValue) => _togglePrivilege(
        userId: userId,
        champ: 'est_ambassadeur',
        currentValue: currentValue,
        titreOn: '🧭 Nommer ambassadeur',
        titreOff: 'Retirer les droits ambassadeur',
        bodyOn:
            'Ce compte garde son expérience actuelle et gagne en plus un accès "Espace ambassadeur" dans son profil.',
        bodyOff: 'Ce compte perdra l\'accès à l\'espace ambassadeur.',
        labelOn: 'Nommer ambassadeur',
        labelOff: 'Retirer',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '👥 Utilisateurs',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.text,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _creerAmbassadeur,
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                        label: const Text('Ambassadeur'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDemandesScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.mail_rounded, size: 16),
                        label: const Text('Demandes Pro'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Filtres par type de compte ────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filtresRole.map((f) {
                    final isSelected = _filtreRole == f['valeur'];
                    return GestureDetector(
                      onTap: () => setState(() => _filtreRole = f['valeur']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? MboaColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? MboaColors.primary : MboaColors.border,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f['label']!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : MboaColors.text,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Contenu ──────────────────────────────
            Expanded(
              child: _isLoadingUsers
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: MboaColors.primary,
                      ),
                    )
                  : _usersAffiches.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun utilisateur dans ce filtre',
                            style: MboaTextStyles.muted,
                          ),
                        )
                      : RefreshIndicator(
                      color: MboaColors.primary,
                      onRefresh: _chargerUsers,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _usersAffiches.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _buildUserCard(
                              _usersAffiches[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'visiteur';
    final isActif = user['actif'] ?? true;
    final isVerified = user['verified'] ?? false;
    // role reste l'identité de base (visiteur/vendeur) ; est_admin/
    // est_ambassadeur sont des privilèges superposés, affichés comme des
    // badges en plus plutôt que remplaçant le badge de rôle.
    final estAdmin = _estAdmin(user);
    final estAmbassadeur = _estAmbassadeur(user);

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'vendeur':
        roleColor = MboaColors.secondary;
        roleLabel = '🏪 Vendeur';
        break;
      default:
        roleColor = MboaColors.primary;
        roleLabel = '🎓 Visiteur';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        border: Border.all(
          color: isActif ? MboaColors.border : MboaColors.danger.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (user['nom'] ?? 'U')
                        .toString()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['nom'] ?? 'Inconnu',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: MboaColors.text,
                            ),
                          ),
                        ),
                        if (isVerified)
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: MboaColors.verified,
                          ),
                      ],
                    ),
                    Text(
                      user['email'] ?? '',
                      style: MboaTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                        ),
                        if (estAdmin)
                          _buildPrivilegeBadge('👑 Admin', MboaColors.accent),
                        if (estAmbassadeur)
                          _buildPrivilegeBadge('🧭 Ambassadeur', MboaColors.primaryDark),
                        if (_statutVerificationParUser.containsKey(user['id']))
                          _buildBadgeVerification(_statutVerificationParUser[user['id']]!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!estAdmin) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Certifier
                _buildActionBtn(
                  icon: isVerified
                      ? Icons.verified_rounded
                      : Icons.verified_outlined,
                  label: isVerified ? 'Certifié' : 'Certifier',
                  color: MboaColors.verified,
                  onTap: () => _toggleVerified(
                      user['id'], isVerified),
                ),
                // Activer/Bannir
                _buildActionBtn(
                  icon: isActif
                      ? Icons.block_rounded
                      : Icons.check_circle_outlined,
                  label: isActif ? 'Bannir' : 'Réactiver',
                  color: isActif
                      ? MboaColors.danger
                      : MboaColors.verified,
                  onTap: () =>
                      _toggleActif(user['id'], isActif),
                ),
              ],
            ),
          ],

          // Attribution des privilèges admin/ambassadeur : choisir parmi
          // les utilisateurs existants, sans passer par la création d'un
          // nouveau compte (voir _creerAmbassadeur pour un compte neuf).
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionBtn(
                icon: estAdmin ? Icons.shield_rounded : Icons.shield_outlined,
                label: estAdmin ? 'Admin' : 'Nommer admin',
                color: MboaColors.accent,
                onTap: () => _toggleEstAdmin(user['id'], estAdmin),
              ),
              _buildActionBtn(
                icon: estAmbassadeur ? Icons.explore_rounded : Icons.explore_outlined,
                label: estAmbassadeur ? 'Ambassadeur' : 'Nommer ambassadeur',
                color: MboaColors.primaryDark,
                onTap: () => _toggleEstAmbassadeur(user['id'], estAmbassadeur),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildBadgeVerification(String statut) {
    final Color color;
    final String label;
    switch (statut) {
      case 'assignee':
        color = MboaColors.boost;
        label = '📍 Visite en cours';
        break;
      case 'visite_effectuee':
        color = MboaColors.primary;
        label = '📤 À valider';
        break;
      case 'validee':
        color = MboaColors.verified;
        label = '✅ Vérifié terrain';
        break;
      case 'rejetee':
        color = MboaColors.danger;
        label = '❌ Vérif. rejetée';
        break;
      default:
        color = MboaColors.textMuted;
        label = '🕓 À assigner';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}