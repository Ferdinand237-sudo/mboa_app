import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'admin_demandes_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  Map<String, String> _statutVerificationParUser = {};
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _chargerUsers();
  }

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
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
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

            // ── Contenu ──────────────────────────────
            Expanded(
              child: _isLoadingUsers
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: MboaColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      color: MboaColors.primary,
                      onRefresh: _chargerUsers,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _buildUserCard(
                              _users[index]);
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

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'admin':
        roleColor = MboaColors.accent;
        roleLabel = '👑 Admin';
        break;
      case 'vendeur':
        roleColor = MboaColors.secondary;
        roleLabel = '🏪 Vendeur';
        break;
      case 'ambassadeur':
        roleColor = MboaColors.primaryDark;
        roleLabel = '🧭 Ambassadeur';
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
                        if (_statutVerificationParUser.containsKey(user['id']))
                          _buildBadgeVerification(_statutVerificationParUser[user['id']]!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (role != 'admin') ...[
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
        ],
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