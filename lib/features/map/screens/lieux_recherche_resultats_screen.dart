import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../logement/screens/logement_detail_screen.dart';
import '../../market/screens/article_detail_screen.dart';

class LieuxRechercheResultatsScreen extends StatefulWidget {
  final String lieuNom;
  final double lat;
  final double lng;

  const LieuxRechercheResultatsScreen({
    super.key,
    required this.lieuNom,
    required this.lat,
    required this.lng,
  });

  @override
  State<LieuxRechercheResultatsScreen> createState() =>
      _LieuxRechercheResultatsScreenState();
}

class _LieuxRechercheResultatsScreenState
    extends State<LieuxRechercheResultatsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  double _rayonKm = 1.5;
  bool _isLoading = true;
  List<Map<String, dynamic>> _logements = [];
  List<Map<String, dynamic>> _articles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _rechercher();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    setState(() => _isLoading = true);
    try {
      final resultats = await Future.wait([
        _supabase.rpc('logements_proches', params: {
          'p_lat': widget.lat,
          'p_lng': widget.lng,
          'p_rayon_km': _rayonKm,
        }),
        _supabase.rpc('articles_proches', params: {
          'p_lat': widget.lat,
          'p_lng': widget.lng,
          'p_rayon_km': _rayonKm,
        }),
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
    return '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} F';
  }

  String _formatDistance(dynamic distanceKm) {
    final d = (distanceKm ?? 0) as num;
    if (d < 1) return '${(d * 1000).round()} m';
    return '${d.toStringAsFixed(1)} km';
  }

  Future<void> _ouvrirLogement(String id) async {
    try {
      final data = await _supabase
          .from('logements')
          .select('*, proprietaire:users!proprietaire_id(nom, photo_url, verified, note_globale)')
          .eq('id', id)
          .single();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LogementDetailScreen(logement: data)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger ce logement'),
              backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  Future<void> _ouvrirArticle(String id) async {
    try {
      final data = await _supabase
          .from('articles')
          .select('*, vendeur:users!vendeur_id(nom, photo_url, verified, note_globale)')
          .eq('id', id)
          .single();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: data)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger cet article'),
              backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '📍 Autour de ${widget.lieuNom}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MboaColors.text,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MboaColors.primary,
          unselectedLabelColor: MboaColors.textMuted,
          indicatorColor: MboaColors.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: '🏠 Logements (${_logements.length})'),
            Tab(text: '🛒 Market (${_articles.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Sélecteur de rayon ──────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rayon de recherche : ${_rayonKm < 1 ? '${(_rayonKm * 1000).round()} m' : '${_rayonKm.toStringAsFixed(1)} km'}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MboaColors.text,
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: MboaColors.primary,
                    thumbColor: MboaColors.primary,
                    inactiveTrackColor: MboaColors.border,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _rayonKm,
                    min: AppConstants.rayonsRechercheKm.first,
                    max: AppConstants.rayonsRechercheKm.last,
                    divisions: AppConstants.rayonsRechercheKm.length - 1,
                    label: _rayonKm < 1
                        ? '${(_rayonKm * 1000).round()} m'
                        : '${_rayonKm.toStringAsFixed(1)} km',
                    onChanged: (v) {
                      final proche = AppConstants.rayonsRechercheKm
                          .reduce((a, b) => (v - a).abs() < (v - b).abs() ? a : b);
                      setState(() => _rayonKm = proche);
                    },
                    onChangeEnd: (_) => _rechercher(),
                  ),
                ),
              ],
            ),
          ),

          // ── Résultats ────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: MboaColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListeLogements(),
                      _buildListeArticles(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeLogements() {
    if (_logements.isEmpty) {
      return _buildVide('Aucun logement dans ce rayon');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _logements.length,
      itemBuilder: (context, index) {
        final l = _logements[index];
        final photos = l['photos'] as List? ?? [];
        return GestureDetector(
          onTap: () => _ouvrirLogement(l['id']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                    child: photos.isNotEmpty
                        ? Image.network(photos[0], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Text('🏠', style: TextStyle(fontSize: 30))))
                        : const Center(child: Text('🏠', style: TextStyle(fontSize: 30))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l['titre'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: MboaColors.text)),
                      const SizedBox(height: 4),
                      Text('${_formatPrix(l['prix'])}/mois',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: MboaColors.primary)),
                      const SizedBox(height: 6),
                      _buildBadgeDistance(l['distance_km']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListeArticles() {
    if (_articles.isEmpty) {
      return _buildVide('Aucun article dans ce rayon');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final a = _articles[index];
        final photos = a['photos'] as List? ?? [];
        return GestureDetector(
          onTap: () => _ouvrirArticle(a['id']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                    child: photos.isNotEmpty
                        ? Image.network(photos[0], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Text('📦', style: TextStyle(fontSize: 30))))
                        : const Center(child: Text('📦', style: TextStyle(fontSize: 30))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['titre'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: MboaColors.text)),
                      const SizedBox(height: 4),
                      Text(_formatPrix(a['prix']),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: MboaColors.accent)),
                      const SizedBox(height: 6),
                      _buildBadgeDistance(a['distance_km']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeDistance(dynamic distanceKm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MboaColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_walk_rounded, size: 12, color: MboaColors.primary),
          const SizedBox(width: 3),
          Text(
            _formatDistance(distanceKm),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: MboaColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVide(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(message, style: MboaTextStyles.muted, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Essayez d\'élargir le rayon de recherche',
                style: MboaTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
