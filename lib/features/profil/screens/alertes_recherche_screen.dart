import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../logement/screens/logement_detail_screen.dart';
import '../../market/screens/article_detail_screen.dart';

class AlertesRechercheScreen extends StatefulWidget {
  const AlertesRechercheScreen({super.key});

  @override
  State<AlertesRechercheScreen> createState() => _AlertesRechercheScreenState();
}

class _AlertesRechercheScreenState extends State<AlertesRechercheScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _alertes = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('alertes_recherche')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _alertes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _supprimer(String id) async {
    try {
      await _supabase.from('alertes_recherche').delete().eq('id', id);
      if (mounted) setState(() => _alertes.removeWhere((a) => a['id'] == id));
    } catch (_) {}
  }

  Future<void> _executerAlerte(Map<String, dynamic> alerte) async {
    final criteres = alerte['criteres'] as Map<String, dynamic>? ?? {};
    final type = alerte['type'];
    try {
      List<Map<String, dynamic>> resultats;
      if (type == 'logement') {
        var query = _supabase.from('logements').select('*, proprietaire:users!proprietaire_id(nom, verified)').eq('statut', 'disponible');
        if (criteres['type'] != null && criteres['type'] != 'Tous') query = query.eq('type', criteres['type']);
        if (criteres['prixMax'] != null) query = query.lte('prix', criteres['prixMax'] as int);
        final data = await query.order('date_publication', ascending: false);
        resultats = List<Map<String, dynamic>>.from(data);
      } else {
        var query = _supabase.from('articles').select('*, vendeur:users!vendeur_id(nom, verified)').eq('statut', 'disponible');
        if (criteres['categorie'] != null && criteres['categorie'] != 'Tous') query = query.eq('categorie', criteres['categorie']);
        if (criteres['etat'] != null && criteres['etat'] != 'Tous') query = query.eq('etat', criteres['etat']);
        final data = await query.order('date_publication', ascending: false);
        resultats = List<Map<String, dynamic>>.from(data);
      }
      if (mounted) _afficherResultats(alerte['libelle'], type, resultats);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la recherche'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  void _afficherResultats(String libelle, String type, List<Map<String, dynamic>> resultats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$libelle (${resultats.length})',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
              const SizedBox(height: 14),
              Expanded(
                child: resultats.isEmpty
                    ? Center(child: Text('Aucun résultat pour le moment', style: MboaTextStyles.muted))
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: resultats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = resultats[index];
                          final photos = item['photos'] as List? ?? [];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => type == 'logement'
                                      ? LogementDetailScreen(logement: item)
                                      : ArticleDetailScreen(article: item),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                                      child: photos.isNotEmpty
                                          ? Image.network(photos[0], fit: BoxFit.cover)
                                          : Center(child: Text(type == 'logement' ? '🏠' : '📦')),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(item['titre'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('🔔 Mes alertes de recherche',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: MboaColors.text)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
          : _alertes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔔', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        const Text('Aucune alerte enregistrée',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text)),
                        const SizedBox(height: 8),
                        Text(
                          'Depuis les filtres de Logement ou Market, appuie sur "Enregistrer comme alerte" pour retrouver facilement une recherche.',
                          style: MboaTextStyles.muted,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alertes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final a = _alertes[index];
                    return GestureDetector(
                      onTap: () => _executerAlerte(a),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Text(a['type'] == 'logement' ? '🏠' : '📦', style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(a['libelle'] ?? '',
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: MboaColors.text)),
                            ),
                            GestureDetector(
                              onTap: () => _supprimer(a['id']),
                              child: const Icon(Icons.delete_outline_rounded, color: MboaColors.danger, size: 20),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
