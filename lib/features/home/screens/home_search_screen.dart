import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../logement/screens/logement_detail_screen.dart';
import '../../market/screens/article_detail_screen.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _logements = [];
  List<Map<String, dynamic>> _articles = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String texte) {
    _debounce?.cancel();
    if (texte.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _logements = [];
        _articles = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _rechercher(texte.trim()));
  }

  Future<void> _rechercher(String texte) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final resultats = await Future.wait([
        _supabase
            .from('logements')
            .select('*, proprietaire:users!proprietaire_id(nom, verified)')
            .eq('statut', 'disponible')
            .or('titre.ilike.%$texte%,quartier.ilike.%$texte%,description.ilike.%$texte%')
            .order('boosted', ascending: false)
            .limit(20),
        _supabase
            .from('articles')
            .select('*, vendeur:users!vendeur_id(nom, verified)')
            .eq('statut', 'disponible')
            .or('titre.ilike.%$texte%,description.ilike.%$texte%,categorie.ilike.%$texte%')
            .order('boosted', ascending: false)
            .limit(20),
      ]);
      if (mounted) {
        setState(() {
          _logements = List<Map<String, dynamic>>.from(resultats[0] as List);
          _articles = List<Map<String, dynamic>>.from(resultats[1] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _supabase.auth.currentUser != null;
    final total = _logements.length + _articles.length;
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 20, 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: MboaColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MboaColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search_rounded, color: MboaColors.textMuted, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              onChanged: _onChanged,
                              decoration: const InputDecoration(
                                hintText: 'Chambre, studio, table, frigo...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: MboaTextStyles.body,
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                _onChanged('');
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.close_rounded, size: 18, color: MboaColors.textMuted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !_hasSearched
                  ? _buildIntro()
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
                      : total == 0
                          ? _buildVide()
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (_logements.isNotEmpty) ...[
                                  _buildSectionLabel('🏠 Logements (${_logements.length})'),
                                  const SizedBox(height: 10),
                                  ..._logements.map((l) => _buildLogementTile(l, isLoggedIn)),
                                  const SizedBox(height: 20),
                                ],
                                if (_articles.isNotEmpty) ...[
                                  _buildSectionLabel('🛒 Market (${_articles.length})'),
                                  const SizedBox(height: 10),
                                  ..._articles.map((a) => _buildArticleTile(a)),
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Recherche instantanée',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Cherche parmi les logements et les articles du Market en tapant simplement quelques lettres.',
              style: MboaTextStyles.muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Aucun résultat pour "${_controller.text}"', style: MboaTextStyles.muted),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Text(
        label,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text),
      );

  Widget _buildLogementTile(Map<String, dynamic> l, bool isLoggedIn) {
    final photos = l['photos'] as List? ?? [];
    return GestureDetector(
      onTap: () {
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connectez-vous pour voir les détails'), backgroundColor: MboaColors.primary),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => LogementDetailScreen(logement: l)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                width: 64,
                height: 64,
                decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                child: photos.isNotEmpty
                    ? Image.network(photos[0], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Text('🏠', style: TextStyle(fontSize: 26))))
                    : const Center(child: Text('🏠', style: TextStyle(fontSize: 26))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l['titre'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                  const SizedBox(height: 3),
                  Text(_formatPrix(l['prix']),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: MboaColors.primary)),
                  Text(l['quartier'] ?? '', style: MboaTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleTile(Map<String, dynamic> a) {
    final photos = a['photos'] as List? ?? [];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                width: 64,
                height: 64,
                decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                child: photos.isNotEmpty
                    ? Image.network(photos[0], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Text('📦', style: TextStyle(fontSize: 26))))
                    : const Center(child: Text('📦', style: TextStyle(fontSize: 26))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['titre'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                  const SizedBox(height: 3),
                  Text(_formatPrix(a['prix']),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: MboaColors.accent)),
                  Text(a['etat'] ?? '', style: MboaTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
