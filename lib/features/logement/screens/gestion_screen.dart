import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../logement/screens/logement_detail_screen.dart';
import '../../market/screens/article_detail_screen.dart';
import 'edit_logement_screen.dart';
import '../../market/screens/edit_article_screen.dart';

class GestionScreen extends StatefulWidget {
  const GestionScreen({super.key});

  @override
  State<GestionScreen> createState() => _GestionScreenState();
}

class _GestionScreenState extends State<GestionScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  TabController? _tabController;
  bool _isLoading = true;
  bool _peutLogement = false;
  bool _peutArticle = false;
  List<Map<String, dynamic>> _logements = [];
  List<Map<String, dynamic>> _articles = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final profil = await _supabase.from('users').select('sous_roles').eq('id', userId).single();
      final sousRoles = List<String>.from(profil['sous_roles'] ?? []);
      final peutLogement = sousRoles.contains('proprietaire');
      final peutArticle = sousRoles.contains('commercant') || sousRoles.contains('vendeur_independant');

      final resultats = await Future.wait([
        if (peutLogement)
          _supabase.from('logements').select().eq('proprietaire_id', userId).order('date_publication', ascending: false)
        else
          Future.value(<Map<String, dynamic>>[]),
        if (peutArticle)
          _supabase.from('articles').select().eq('vendeur_id', userId).order('date_publication', ascending: false)
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _peutLogement = peutLogement;
          _peutArticle = peutArticle;
          _logements = List<Map<String, dynamic>>.from(resultats[0] as List);
          _articles = List<Map<String, dynamic>>.from(resultats[1] as List);
          if (peutLogement && peutArticle) {
            _tabController = TabController(length: 2, vsync: this);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatut(String table, Map<String, dynamic> item) async {
    final nouveauStatut = item['statut'] == 'disponible' ? 'suspendu' : 'disponible';
    try {
      await _supabase.from(table).update({'statut': nouveauStatut}).eq('id', item['id']);
      if (mounted) setState(() => item['statut'] = nouveauStatut);
    } catch (_) {}
  }

  Future<void> _supprimer(String table, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusXl)),
        title: const Text('Supprimer cette annonce ?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('Cette action est définitive.', style: TextStyle(fontFamily: 'Poppins', color: MboaColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MboaColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _supabase.from(table).delete().eq('id', id);
      if (mounted) {
        setState(() {
          _logements.removeWhere((l) => l['id'] == id);
          _articles.removeWhere((a) => a['id'] == id);
        });
      }
    } catch (_) {}
  }

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MboaColors.background,
        body: Center(child: CircularProgressIndicator(color: MboaColors.primary)),
      );
    }

    if (!_peutLogement && !_peutArticle) {
      return const Scaffold(
        backgroundColor: MboaColors.background,
        body: Center(child: Text('Aucune annonce à gérer', style: MboaTextStyles.muted)),
      );
    }

    if (!(_peutLogement && _peutArticle)) {
      return Scaffold(
        backgroundColor: MboaColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('📋 Gestion',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: MboaColors.text)),
        ),
        body: RefreshIndicator(
          color: MboaColors.primary,
          onRefresh: _charger,
          child: _peutLogement ? _buildListeLogements() : _buildListeArticles(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('📋 Gestion',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: MboaColors.text)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MboaColors.primary,
          unselectedLabelColor: MboaColors.textMuted,
          indicatorColor: MboaColors.primary,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: '🏠 Logements (${_logements.length})'),
            Tab(text: '🛒 Articles (${_articles.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: MboaColors.primary,
        onRefresh: _charger,
        child: TabBarView(
          controller: _tabController,
          children: [_buildListeLogements(), _buildListeArticles()],
        ),
      ),
    );
  }

  Widget _buildListeLogements() {
    if (_logements.isEmpty) return _buildVide('🏠', 'Aucun logement publié');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _logements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCard(
        item: _logements[index],
        table: 'logements',
        emoji: '🏠',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LogementDetailScreen(logement: _logements[index]))),
        onEdit: () async {
          final modifie = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => EditLogementScreen(logement: _logements[index])));
          if (modifie == true) _charger();
        },
      ),
    );
  }

  Widget _buildListeArticles() {
    if (_articles.isEmpty) return _buildVide('🛒', 'Aucun article publié');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCard(
        item: _articles[index],
        table: 'articles',
        emoji: '📦',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: _articles[index]))),
        onEdit: () async {
          final modifie = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => EditArticleScreen(article: _articles[index])));
          if (modifie == true) _charger();
        },
      ),
    );
  }

  Widget _buildCard({
    required Map<String, dynamic> item,
    required String table,
    required String emoji,
    required VoidCallback onTap,
    required VoidCallback onEdit,
  }) {
    final photos = item['photos'] as List? ?? [];
    final estDisponible = item['statut'] == 'disponible';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                    child: photos.isNotEmpty
                        ? Image.network(photos[0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(emoji, style: const TextStyle(fontSize: 26))))
                        : Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['titre'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                      const SizedBox(height: 3),
                      Text(_formatPrix(item['prix']),
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: MboaColors.primary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (estDisponible ? MboaColors.verified : MboaColors.textMuted).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          estDisponible ? 'Disponible' : 'Suspendu',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: estDisponible ? MboaColors.verified : MboaColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Modifier', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: MboaColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _toggleStatut(table, item),
                  icon: Icon(estDisponible ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 15),
                  label: Text(estDisponible ? 'Suspendre' : 'Réactiver', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: MboaColors.boost,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _supprimer(table, item['id']),
                  icon: const Icon(Icons.delete_outline_rounded, size: 15),
                  label: const Text('Supprimer', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: MboaColors.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVide(String emoji, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(message, style: MboaTextStyles.muted),
          ],
        ),
      ),
    );
  }
}
