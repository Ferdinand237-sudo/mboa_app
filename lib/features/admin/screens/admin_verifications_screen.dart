import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/mixins/realtime_table_mixin.dart';

class AdminVerificationsScreen extends StatefulWidget {
  // Appelé à chaque changement reçu en temps réel — le parent (AdminScreen)
  // décide s'il doit afficher un badge sur l'onglet (uniquement si cet
  // écran n'est pas l'onglet actif au moment de l'événement).
  final VoidCallback? onNouvelElement;
  const AdminVerificationsScreen({super.key, this.onNouvelElement});

  @override
  State<AdminVerificationsScreen> createState() => _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen>
    with RealtimeTableMixin<AdminVerificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _verifications = [];
  bool _isLoading = true;
  String _filtre = 'en_attente_assignation';

  @override
  void initState() {
    super.initState();
    _charger();
    // Les payloads realtime ne contiennent que les colonnes brutes de
    // verifications_terrain (pas les jointures propriétaire/ambassadeur) :
    // on se contente donc de redéclencher un chargement filtré, plutôt que
    // de fusionner manuellement un payload incomplet dans la liste.
    subscribeToTable(
      channelName: 'admin_verifications_terrain',
      table: AppConstants.tableVerificationsTerrain,
      event: PostgresChangeEvent.all,
      onChange: (payload) {
        _charger();
        widget.onNouvelElement?.call();
      },
    );
  }

  @override
  void dispose() {
    disposeRealtimeChannels();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from(AppConstants.tableVerificationsTerrain)
          .select(
              '*, proprietaire:users!verifications_terrain_user_id_fkey(nom, telephone, email), ambassadeur:users!verifications_terrain_ambassadeur_id_fkey(nom)');

      if (_filtre != 'tous') {
        query = query.eq('statut', _filtre);
      }

      final data = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _verifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assigner(Map<String, dynamic> verification) async {
    List<Map<String, dynamic>> ambassadeurs = [];
    try {
      final data = await _supabase.from('users').select('id, nom').eq('role', AppConstants.roleAmbassadeur);
      ambassadeurs = List<Map<String, dynamic>>.from(data);
    } catch (_) {}

    if (!mounted) return;
    if (ambassadeurs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun ambassadeur créé pour l\'instant'), backgroundColor: MboaColors.danger),
      );
      return;
    }

    final choisi = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusXl)),
        title: const Text('Assigner un ambassadeur', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ambassadeurs.length,
            itemBuilder: (context, index) {
              final a = ambassadeurs[index];
              return ListTile(
                leading: const Icon(Icons.person_pin_circle_rounded, color: MboaColors.primary),
                title: Text(a['nom'] ?? '', style: const TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(context, a),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );

    if (choisi == null) return;

    try {
      await _supabase.from(AppConstants.tableVerificationsTerrain).update({
        'ambassadeur_id': choisi['id'],
        'statut': AppConstants.statutVerificationAssignee,
        'date_assignation': DateTime.now().toIso8601String(),
      }).eq('id', verification['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Assigné à ${choisi['nom']}'), backgroundColor: MboaColors.primary),
        );
        _charger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'assignation'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  Future<void> _voirAttestation(Map<String, dynamic> verification) async {
    try {
      final res = await _supabase.functions.invoke('get-attestation-url', body: {
        'verificationId': verification['id'],
      });
      final url = (res.data as Map?)?['url'] as String?;
      if (url != null && mounted) {
        showDialog(
          context: context,
          builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(url))),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune attestation disponible'), backgroundColor: MboaColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger l\'attestation'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  Future<void> _traiter(Map<String, dynamic> verification, String statut) async {
    final adminId = _supabase.auth.currentUser?.id;
    try {
      await _supabase.from(AppConstants.tableVerificationsTerrain).update({
        'statut': statut,
        'admin_id': adminId,
        'date_traitement': DateTime.now().toIso8601String(),
      }).eq('id', verification['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statut == AppConstants.statutVerificationValidee ? '✅ Vérification validée' : '❌ Vérification rejetée'),
            backgroundColor: statut == AppConstants.statutVerificationValidee ? MboaColors.verified : MboaColors.textMuted,
          ),
        );
        _charger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du traitement'), backgroundColor: MboaColors.danger),
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
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧭 Vérifications terrain',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: MboaColors.text)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'en_attente_assignation',
                        'assignee',
                        'visite_effectuee',
                        'validee',
                        'rejetee',
                        'tous',
                      ].map((f) {
                        final isSelected = _filtre == f;
                        final label = {
                              'en_attente_assignation': '🕓 À assigner',
                              'assignee': '📍 Assignées',
                              'visite_effectuee': '📤 À valider',
                              'validee': '✅ Validées',
                              'rejetee': '❌ Rejetées',
                              'tous': '📋 Toutes',
                            }[f] ??
                            f;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _filtre = f);
                            _charger();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? MboaColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? MboaColors.primary : MboaColors.border, width: 1.5),
                            ),
                            child: Text(
                              label,
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
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
                  : _verifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🧭', style: TextStyle(fontSize: 50)),
                              const SizedBox(height: 12),
                              const Text('Aucune vérification', style: TextStyle(fontFamily: 'Poppins', color: MboaColors.textMuted)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: MboaColors.primary,
                          onRefresh: _charger,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _verifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _buildCard(_verifications[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> verification) {
    final proprietaire = verification['proprietaire'] as Map<String, dynamic>?;
    final ambassadeur = verification['ambassadeur'] as Map<String, dynamic>?;
    final statut = verification['statut'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(proprietaire?['nom'] ?? 'Propriétaire',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: MboaColors.text)),
          const SizedBox(height: 2),
          Text(proprietaire?['telephone'] ?? proprietaire?['email'] ?? '', style: MboaTextStyles.caption),
          if (ambassadeur != null) ...[
            const SizedBox(height: 6),
            Text('👤 Ambassadeur : ${ambassadeur['nom']}', style: MboaTextStyles.caption),
          ],
          if (verification['conformite_bien'] != null) ...[
            const SizedBox(height: 6),
            Text(
              verification['conformite_bien'] == true ? '✅ Bien conforme' : '⚠️ Bien non conforme',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: verification['conformite_bien'] == true ? MboaColors.verified : MboaColors.danger,
              ),
            ),
          ],
          if (verification['type_justificatif'] != null) ...[
            const SizedBox(height: 4),
            Text('📄 ${verification['type_justificatif']}', style: MboaTextStyles.caption),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (statut == AppConstants.statutVerificationEnAttenteAssignation)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _assigner(verification),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Assigner un ambassadeur'),
                style: ElevatedButton.styleFrom(backgroundColor: MboaColors.primary, foregroundColor: Colors.white),
              ),
            )
          else if (statut == AppConstants.statutVerificationVisiteEffectuee) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _voirAttestation(verification),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Voir l\'attestation'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _traiter(verification, AppConstants.statutVerificationRejetee),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Rejeter'),
                    style: ElevatedButton.styleFrom(backgroundColor: MboaColors.textMuted, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _traiter(verification, AppConstants.statutVerificationValidee),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(backgroundColor: MboaColors.verified, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (statut == AppConstants.statutVerificationValidee ? MboaColors.verified : MboaColors.boost)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statut == AppConstants.statutVerificationValidee
                    ? '✅ Validée'
                    : statut == AppConstants.statutVerificationRejetee
                        ? '❌ Rejetée'
                        : '📍 En attente de visite',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statut == AppConstants.statutVerificationValidee ? MboaColors.verified : MboaColors.boost,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
