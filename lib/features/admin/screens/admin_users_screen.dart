import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_demandes_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _chargerUsers();
  }

  Future<void> _chargerUsers() async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .order('date_inscription', ascending: false);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
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