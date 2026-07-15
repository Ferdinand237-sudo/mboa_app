import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoadingUsers = true;
  bool _isLoadingDemandes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerUsers();
    _chargerDemandes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _chargerDemandes() async {
    try {
      final data = await _supabase
          .from('demandes_compte')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _demandes = List<Map<String, dynamic>>.from(data);
          _isLoadingDemandes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDemandes = false);
    }
  }

  Future<void> _creerCompteVendeur(
      Map<String, dynamic> demande) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    List<String> selectedSousRoles = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
          ),
          title: const Text(
            '✅ Créer le compte',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info demandeur
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MboaColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          demande['nom'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          demande['email'] ?? '',
                          style: MboaTextStyles.muted,
                        ),
                        Text(
                          '📱 ${demande['whatsapp'] ?? ''}',
                          style: MboaTextStyles.muted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          demande['type_activite'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: MboaColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          demande['description'] ?? '',
                          style: MboaTextStyles.bodySm,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mot de passe temporaire
                  const Text(
                    'Mot de passe temporaire',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Min. 6 caractères',
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? 'Minimum 6 caractères'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Sous-rôles
                  const Text(
                    'Permissions',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    {'label': '🏠 Propriétaire immobilier', 'value': 'proprietaire'},
                    {'label': '🛒 Commerçant boutique', 'value': 'commercant'},
                    {'label': '📦 Vendeur indépendant', 'value': 'vendeur_independant'},
                  ].map((opt) {
                    final isSelected = selectedSousRoles.contains(opt['value']);
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        if (isSelected) {
                          selectedSousRoles.remove(opt['value']);
                        } else {
                          selectedSousRoles.add(opt['value']!);
                        }
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? MboaColors.primary.withValues(alpha: 0.08)
                              : MboaColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? MboaColors.primary
                                : MboaColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt['label']!,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? MboaColors.primary
                                      : MboaColors.text,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: MboaColors.primary, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (selectedSousRoles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sélectionne au moins une permission'),
                      backgroundColor: MboaColors.danger,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await _validerDemande(
                  demande: demande,
                  password: passwordController.text,
                  sousRoles: selectedSousRoles,
                );
              },
              child: const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validerDemande({
    required Map<String, dynamic> demande,
    required String password,
    required List<String> sousRoles,
  }) async {
    try {
      // Appel de l'Edge Function
      final response = await _invokeCreateVendorFunction(
        {
          'nom': demande['nom'],
          'email': demande['email'],
          'password': password,
          'whatsapp': demande['whatsapp'],
          'sousRoles': sousRoles,
          'demandeId': demande['id'],
        },
      );

      if (response.status == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Compte créé pour ${demande['nom']} !'),
              backgroundColor: MboaColors.primary,
            ),
          );
          _chargerDemandes();
          // Rafraîchir users si la méthode existe
          if (mounted) setState(() {});
        }
      } else {
        final error = response.status == 404
            ? 'Fonction Supabase introuvable (create-vendor / create-vendeur).'
            : response.data?['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $error'),
              backgroundColor: MboaColors.danger,
            ),
          );
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

  Future<dynamic> _invokeCreateVendorFunction(
      Map<String, dynamic> body) async {
    final functionNames = [
      'create-vendor',
      'create-vendeur',
      'create_vendor',
      'createVendeur',
    ];
    dynamic lastResponse;

    for (final functionName in functionNames) {
      try {
        final response = await _supabase.functions.invoke(
          functionName,
          body: body,
        );
        if (response.status != 404) {
          return response;
        }
        lastResponse = response;
      } catch (e) {
        final message = e.toString().toLowerCase();
        if (message.contains('404') || message.contains('not found')) {
          continue;
        }
        rethrow;
      }
    }

    return lastResponse;
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: MboaColors.primary,
                    indicatorWeight: 3,
                    labelColor: MboaColors.primary,
                    unselectedLabelColor: MboaColors.textMuted,
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      const Tab(text: 'Tous les comptes'),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Demandes'),
                            if (_demandes
                                .where((d) =>
                                    d['statut'] == 'en-attente')
                                .isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MboaColors.danger,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_demandes.where((d) => d['statut'] == 'en-attente').length}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Contenu ──────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Utilisateurs
                  _isLoadingUsers
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

                  // Tab Demandes
                  _isLoadingDemandes
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: MboaColors.primary,
                          ),
                        )
                      : RefreshIndicator(
                          color: MboaColors.primary,
                          onRefresh: _chargerDemandes,
                          child: _demandes.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text('📭',
                                          style: TextStyle(
                                              fontSize: 50)),
                                      SizedBox(height: 12),
                                      Text(
                                        'Aucune demande',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: MboaColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _demandes.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    return _buildDemandeCard(
                                        _demandes[index]);
                                  },
                                ),
                        ),
                ],
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

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final statut = demande['statut'] ?? 'en-attente';
    Color statutColor;
    switch (statut) {
      case 'approuve':
        statutColor = MboaColors.verified;
        break;
      case 'rejete':
        statutColor = MboaColors.danger;
        break;
      default:
        statutColor = MboaColors.boost;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        border: Border.all(
          color: statut == 'en-attente'
              ? MboaColors.boost.withValues(alpha: 0.4)
              : MboaColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  demande['nom'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MboaColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statutColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statut == 'en-attente'
                      ? '⏳ En attente'
                      : statut == 'approuve'
                          ? '✅ Approuvé'
                          : '❌ Rejeté',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statutColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            demande['email'] ?? '',
            style: MboaTextStyles.muted,
          ),
          Text(
            '📱 ${demande['whatsapp'] ?? ''}',
            style: MboaTextStyles.muted,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: MboaColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              demande['type_activite'] ?? '',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MboaColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            demande['description'] ?? '',
            style: MboaTextStyles.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (statut == 'en-attente') ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                // Rejeter
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await _supabase
                          .from('demandes_compte')
                          .update({'statut': 'rejete'})
                          .eq('id', demande['id']);
                      _chargerDemandes();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: MboaColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: MboaColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded,
                              size: 16,
                              color: MboaColors.danger),
                          SizedBox(width: 6),
                          Text(
                            'Rejeter',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: MboaColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Approuver
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _creerCompteVendeur(demande),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: MboaColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Créer le compte',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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