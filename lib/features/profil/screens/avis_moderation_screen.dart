import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AvisModerationScreen extends StatefulWidget {
  const AvisModerationScreen({super.key});

  @override
  State<AvisModerationScreen> createState() => _AvisModerationScreenState();
}

class _AvisModerationScreenState extends State<AvisModerationScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _avisEnAttente = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('avis')
          .select('*, auteur:users!auteur_id(nom)')
          .eq('cible_id', userId)
          .eq('valide', false)
          .not('annonce_id', 'is', null)
          .order('date_publication', ascending: false);
      final avis = List<Map<String, dynamic>>.from(data);

      // annonce_id n'a pas de FK unique (logement ou article) : on
      // récupère les titres séparément plutôt que via une jointure.
      final annonceIds = avis.map((a) => a['annonce_id']).whereType<String>().toSet().toList();
      if (annonceIds.isNotEmpty) {
        final titresLogements = await _supabase.from('logements').select('id, titre').filter('id', 'in', annonceIds);
        final titresArticles = await _supabase.from('articles').select('id, titre').filter('id', 'in', annonceIds);
        final mapTitres = <String, String>{
          for (final l in List<Map<String, dynamic>>.from(titresLogements)) l['id']: l['titre'] ?? '',
          for (final a in List<Map<String, dynamic>>.from(titresArticles)) a['id']: a['titre'] ?? '',
        };
        for (final a in avis) {
          a['titre_annonce'] = mapTitres[a['annonce_id']];
        }
      }

      if (mounted) {
        setState(() {
          _avisEnAttente = avis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approuver(String avisId) async {
    try {
      await _supabase.from('avis').update({'valide': true}).eq('id', avisId);
      if (mounted) {
        setState(() => _avisEnAttente.removeWhere((a) => a['id'] == avisId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Avis publié'), backgroundColor: MboaColors.verified),
        );
      }
    } catch (_) {}
  }

  Future<void> _refuser(String avisId, String cibleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusXl)),
        title: const Text('Refuser cet avis ?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'L\'avis sera supprimé et ne sera jamais publié. La note déjà comptée dans votre score sera retirée.',
          style: TextStyle(fontFamily: 'Poppins', color: MboaColors.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MboaColors.danger),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _supabase.from('avis').delete().eq('id', avisId);

      final avisData = await _supabase.from('avis').select('note').eq('cible_id', cibleId);
      final notes = List<Map<String, dynamic>>.from(avisData);
      await _supabase.from('users').update({
        'note_globale': notes.isEmpty ? 0 : double.parse((notes.fold<int>(0, (s, a) => s + ((a['note'] ?? 0) as int)) / notes.length).toStringAsFixed(1)),
        'nb_avis': notes.length,
      }).eq('id', cibleId);

      if (mounted) {
        setState(() => _avisEnAttente.removeWhere((a) => a['id'] == avisId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis refusé et supprimé'), backgroundColor: MboaColors.textMuted),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('⭐ Avis à modérer',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
          : _avisEnAttente.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        const Text('Rien à modérer',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text)),
                        const SizedBox(height: 8),
                        Text('Les nouveaux avis sur vos annonces apparaîtront ici.', style: MboaTextStyles.muted, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: MboaColors.primary,
                  onRefresh: _charger,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _avisEnAttente.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final a = _avisEnAttente[index];
                      final auteur = a['auteur'] as Map<String, dynamic>?;
                      final titreAnnonce = a['titre_annonce'] as String?;
                      final note = (a['note'] ?? 0) as int;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(auteur?['nom'] ?? 'Utilisateur',
                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                                ),
                                Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < note ? MboaColors.boost : MboaColors.border))),
                              ],
                            ),
                            if (titreAnnonce != null && titreAnnonce.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('à propos de « $titreAnnonce »', style: MboaTextStyles.caption),
                            ],
                            if ((a['commentaire'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(a['commentaire'], style: MboaTextStyles.body.copyWith(height: 1.5)),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _refuser(a['id'], a['cible_id']),
                                    style: OutlinedButton.styleFrom(foregroundColor: MboaColors.danger, side: const BorderSide(color: MboaColors.danger)),
                                    child: const Text('Refuser'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _approuver(a['id']),
                                    style: ElevatedButton.styleFrom(backgroundColor: MboaColors.verified),
                                    child: const Text('Approuver'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
