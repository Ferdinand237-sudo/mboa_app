import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AdminDemandesScreen extends StatefulWidget {
  const AdminDemandesScreen({super.key});

  @override
  State<AdminDemandesScreen> createState() =>
      _AdminDemandesScreenState();
}

class _AdminDemandesScreenState
    extends State<AdminDemandesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoading = true;
  String _filtre = 'en-attente';

  @override
  void initState() {
    super.initState();
    _chargerDemandes();
  }

  Future<void> _chargerDemandes() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('demandes_compte')
          .select();

      if (_filtre != 'tous') {
        query = query.eq('statut', _filtre);
      }

      final data = await query
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _demandes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
            borderRadius:
                BorderRadius.circular(MboaSizes.radiusXl),
          ),
          title: const Text(
            '✅ Créer le compte vendeur',
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
                      color: MboaColors.primary
                          .withValues(alpha: 0.06),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MboaColors.secondary
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            demande['type_activite'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: MboaColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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

                  if (demande['user_id'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MboaColors.verified.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '👤 Compte existant : le rôle sera simplement mis à jour, sans nouveau mot de passe.',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: MboaColors.text),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Mot de passe
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
                      validator: (v) => demande['user_id'] != null
                          ? null
                          : (v == null || v.length < 6
                              ? 'Minimum 6 caractères'
                              : null),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Permissions
                  const Text(
                    'Permissions accordées',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    {
                      'label': '🏠 Propriétaire immobilier',
                      'value': 'proprietaire'
                    },
                    {
                      'label': '🛒 Commerçant boutique',
                      'value': 'commercant'
                    },
                    {
                      'label': '📦 Vendeur indépendant',
                      'value': 'vendeur_independant'
                    },
                  ].map((opt) {
                    final isSelected = selectedSousRoles
                        .contains(opt['value']);
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        if (isSelected) {
                          selectedSousRoles
                              .remove(opt['value']);
                        } else {
                          selectedSousRoles
                              .add(opt['value']!);
                        }
                      }),
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? MboaColors.primary
                                  .withValues(alpha: 0.08)
                              : MboaColors.background,
                          borderRadius:
                              BorderRadius.circular(10),
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
                              const Icon(
                                Icons.check_circle_rounded,
                                color: MboaColors.primary,
                                size: 18,
                              ),
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
                      content: Text(
                          'Sélectionne au moins une permission'),
                      backgroundColor: MboaColors.danger,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                if (demande['user_id'] != null) {
                  await _mettreAJourCompteExistant(
                    demande: demande,
                    sousRoles: selectedSousRoles,
                  );
                } else {
                  await _validerDemande(
                    demande: demande,
                    password: passwordController.text,
                    sousRoles: selectedSousRoles,
                  );
                }
              },
              child: Text(demande['user_id'] != null ? 'Mettre à jour le compte' : 'Créer le compte'),
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
  Future<void> _mettreAJourCompteExistant({
    required Map<String, dynamic> demande,
    required List<String> sousRoles,
  }) async {
    final userId = demande['user_id'];
    try {
      final existing =
          await _supabase.from('users').select('sous_roles').eq('id', userId).single();
      final currentSousRoles = List<String>.from(existing['sous_roles'] ?? []);
      final merged = {...currentSousRoles, ...sousRoles}.toList();

      await _supabase.from('users').update({
        'role': 'vendeur',
        'sous_roles': merged,
      }).eq('id', userId);

      await _supabase
          .from('demandes_compte')
          .update({'statut': 'traite'})
          .eq('id', demande['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Compte de ${demande['nom']} mis à jour !'),
            backgroundColor: MboaColors.primary,
          ),
        );
        _chargerDemandes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: MboaColors.danger),
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
  Future<void> _rejeterDemande(String id) async {
    await _supabase
        .from('demandes_compte')
        .update({'statut': 'rejete'})
        .eq('id', id);
    _chargerDemandes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande rejetée'),
          backgroundColor: MboaColors.textMuted,
        ),
      );
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
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📨 Demandes Pro',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: MboaColors.text,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: MboaColors.secondary
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_demandes.where((d) => d['statut'] == 'en-attente').length} en attente',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MboaColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filtres
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'en-attente',
                        'approuve',
                        'rejete',
                        'tous',
                      ].map((f) {
                        final isSelected = _filtre == f;
                        final label = f == 'en-attente'
                            ? '⏳ En attente'
                            : f == 'approuve'
                                ? '✅ Approuvés'
                                : f == 'rejete'
                                    ? '❌ Rejetés'
                                    : '📋 Tous';
                        return GestureDetector(
                          onTap: () {
                            setState(() => _filtre = f);
                            _chargerDemandes();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            margin: const EdgeInsets.only(
                                right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MboaColors.primary
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? MboaColors.primary
                                    : MboaColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : MboaColors.text,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Liste ────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: MboaColors.primary),
                    )
                  : _demandes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text('📭',
                                  style: TextStyle(
                                      fontSize: 50)),
                              const SizedBox(height: 12),
                              Text(
                                _filtre == 'en-attente'
                                    ? 'Aucune demande en attente'
                                    : 'Aucune demande',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: MboaColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Les demandes de compte Pro\napparaîtront ici',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: MboaColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: MboaColors.primary,
                          onRefresh: _chargerDemandes,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _demandes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildDemandeCard(
                                    _demandes[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandeCard(
      Map<String, dynamic> demande) {
    final statut = demande['statut'] ?? 'en-attente';

    Color statutColor;
    String statutLabel;
    switch (statut) {
      case 'approuve':
        statutColor = MboaColors.verified;
        statutLabel = '✅ Approuvé';
        break;
      case 'rejete':
        statutColor = MboaColors.danger;
        statutLabel = '❌ Rejeté';
        break;
      default:
        statutColor = MboaColors.boost;
        statutLabel = '⏳ En attente';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(MboaSizes.radiusLg),
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
          // ── En-tête ──────────────────────────────
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: MboaColors.secondary
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (demande['nom'] ?? 'U')
                        .toString()
                        .split(' ')
                        .map((e) =>
                            e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MboaColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      demande['nom'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    Text(
                      demande['email'] ?? '',
                      style: MboaTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statutColor
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  statutLabel,
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
          const SizedBox(height: 12),

          // ── Détails ──────────────────────────────
          Row(
            children: [
              const Icon(Icons.phone_rounded,
                  size: 14,
                  color: MboaColors.textMuted),
              const SizedBox(width: 6),
              Text(
                demande['whatsapp'] ?? '',
                style: MboaTextStyles.bodySm,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: MboaColors.secondary
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🏷 ${demande['type_activite'] ?? ''}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MboaColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MboaColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              demande['description'] ?? '',
              style: MboaTextStyles.bodySm
                  .copyWith(height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Actions ──────────────────────────────
          if (statut == 'en-attente') ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        _rejeterDemande(demande['id']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 11),
                      decoration: BoxDecoration(
                        color: MboaColors.danger
                            .withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: MboaColors.danger
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded,
                              size: 16,
                              color: MboaColors.danger),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Rejeter',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: MboaColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () =>
                        _creerCompteVendeur(demande),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 11),
                      decoration: BoxDecoration(
                        color: MboaColors.primary,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Créer le compte',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
}