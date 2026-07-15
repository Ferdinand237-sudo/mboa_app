import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AdminSignalementsScreen extends StatefulWidget {
  const AdminSignalementsScreen({super.key});

  @override
  State<AdminSignalementsScreen> createState() =>
      _AdminSignalementsScreenState();
}

class _AdminSignalementsScreenState
    extends State<AdminSignalementsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _signalements = [];
  bool _isLoading = true;
  String _filtre = 'en-attente';

  @override
  void initState() {
    super.initState();
    _chargerSignalements();
  }

  Future<void> _chargerSignalements() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('signalements')
          .select('*, signaleur:users!signaleur_id(nom, email)');

      if (_filtre != 'tous') {
        query = query.eq('statut', _filtre);
      }

      final data = await query
          .order('date_signalement', ascending: false);

      if (mounted) {
        setState(() {
          _signalements = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _traiterSignalement(
      String id, String statut) async {
    await _supabase
        .from('signalements')
        .update({'statut': statut})
        .eq('id', id);
    _chargerSignalements();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            statut == 'traite'
                ? '✅ Signalement traité'
                : '❌ Signalement rejeté',
          ),
          backgroundColor: statut == 'traite'
              ? MboaColors.verified
              : MboaColors.textMuted,
        ),
      );
    }
  }

  Future<void> _supprimerAnnonce(
      String cibleId, String cibleType, String signalementId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        title: const Text(
          '🗑 Supprimer l\'annonce',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Cette action supprimera définitivement l\'annonce signalée.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MboaColors.danger,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final table = cibleType == 'annonce'
          ? 'logements'
          : 'utilisateurs';
      if (cibleType == 'annonce') {
        // Essayer logements d'abord puis articles
        try {
          await _supabase
              .from('logements')
              .delete()
              .eq('id', cibleId);
        } catch (_) {
          await _supabase
              .from('articles')
              .delete()
              .eq('id', cibleId);
        }
      } else {
        await _supabase
            .from(table)
            .delete()
            .eq('id', cibleId);
      }
      await _traiterSignalement(signalementId, 'traite');
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🚨 Signalements',
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
                          color: MboaColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_signalements.where((s) => s['statut'] == 'en-attente').length} en attente',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MboaColors.danger,
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
                        'traite',
                        'rejete',
                        'tous',
                      ].map((f) {
                        final isSelected = _filtre == f;
                        final label = f == 'en-attente'
                            ? '⏳ En attente'
                            : f == 'traite'
                                ? '✅ Traités'
                                : f == 'rejete'
                                    ? '❌ Rejetés'
                                    : '📋 Tous';
                        return GestureDetector(
                          onTap: () {
                            setState(() => _filtre = f);
                            _chargerSignalements();
                          },
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.only(right: 8),
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
                  : _signalements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text('🎉',
                                  style:
                                      TextStyle(fontSize: 50)),
                              const SizedBox(height: 12),
                              Text(
                                _filtre == 'en-attente'
                                    ? 'Aucun signalement en attente'
                                    : 'Aucun signalement',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: MboaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: MboaColors.primary,
                          onRefresh: _chargerSignalements,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _signalements.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _buildSignalementCard(
                                    _signalements[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalementCard(
      Map<String, dynamic> signalement) {
    final statut = signalement['statut'] ?? 'en-attente';
    final signaleur = signalement['signaleur'];
    final cibleType = signalement['cible_type'] ?? 'annonce';

    Color statutColor;
    switch (statut) {
      case 'traite':
        statutColor = MboaColors.verified;
        break;
      case 'rejete':
        statutColor = MboaColors.textMuted;
        break;
      default:
        statutColor = MboaColors.danger;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        border: Border.all(
          color: statut == 'en-attente'
              ? MboaColors.danger.withValues(alpha: 0.3)
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          MboaColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('🚩',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        cibleType == 'annonce'
                            ? '📋 Annonce signalée'
                            : cibleType == 'utilisateur'
                                ? '👤 Utilisateur signalé'
                                : '⭐ Avis signalé',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MboaColors.text,
                        ),
                      ),
                      if (signaleur != null)
                        Text(
                          'Par ${signaleur['nom'] ?? 'Inconnu'}',
                          style: MboaTextStyles.caption,
                        ),
                    ],
                  ),
                ],
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
                      : statut == 'traite'
                          ? '✅ Traité'
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
          const SizedBox(height: 12),

          // ── Raison ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MboaColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Raison : ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    Text(
                      signalement['raison'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: MboaColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (signalement['description'] != null &&
                    signalement['description'].isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    signalement['description'],
                    style: MboaTextStyles.bodySm,
                  ),
                ],
              ],
            ),
          ),

          // ── Actions ──────────────────────────────
          if (statut == 'en-attente') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                // Rejeter le signalement
                Expanded(
                  child: GestureDetector(
                    onTap: () => _traiterSignalement(
                        signalement['id'], 'rejete'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 9),
                      decoration: BoxDecoration(
                        color: MboaColors.textMuted
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: MboaColors.border,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.thumb_down_outlined,
                              size: 14,
                              color: MboaColors.textMuted),
                          SizedBox(width: 5),
                          Text(
                            'Ignorer',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MboaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Traiter sans supprimer
                Expanded(
                  child: GestureDetector(
                    onTap: () => _traiterSignalement(
                        signalement['id'], 'traite'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 9),
                      decoration: BoxDecoration(
                        color: MboaColors.verified
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: MboaColors.verified
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 14,
                              color: MboaColors.verified),
                          SizedBox(width: 5),
                          Text(
                            'Résoudre',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MboaColors.verified,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Supprimer l'annonce
                GestureDetector(
                  onTap: () => _supprimerAnnonce(
                    signalement['cible_id'],
                    cibleType,
                    signalement['id'],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: MboaColors.danger
                          .withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: MboaColors.danger
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: MboaColors.danger,
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