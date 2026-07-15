import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../logement/screens/logement_detail_screen.dart';
import '../../market/screens/article_detail_screen.dart';
import '../../map/screens/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _logements = [];
  List<Map<String, dynamic>> _articles = [];
  bool _isLoadingLogements = true;
  bool _isLoadingArticles = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    await Future.wait([
      _chargerLogements(),
      _chargerArticles(),
      _chargerUser(),
    ]);
  }

  Future<void> _chargerUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase
            .from('users')
            .select('nom')
            .eq('id', user.id)
            .single();
        if (mounted) {
          setState(() => _userName = data['nom']);
        }
      } catch (_) {
        final meta = user.userMetadata;
        if (mounted) {
          setState(() => _userName = meta?['nom'] ?? 'Visiteur');
        }
      }
    }
  }

  Future<void> _chargerLogements() async {
    try {
      final data = await _supabase
          .from('logements')
          .select('*, proprietaire:users!proprietaire_id(nom, verified)')
          .eq('statut', 'disponible')
          .order('boosted', ascending: false)
          .order('date_publication', ascending: false)
          .limit(5);
      if (mounted) {
        setState(() {
          _logements = List<Map<String, dynamic>>.from(data);
          _isLoadingLogements = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLogements = false);
    }
  }

  Future<void> _chargerArticles() async {
    try {
      final data = await _supabase
          .from('articles')
          .select('*, vendeur:users!vendeur_id(nom, verified)')
          .eq('statut', 'disponible')
          .order('boosted', ascending: false)
          .order('date_publication', ascending: false)
          .limit(6);
      if (mounted) {
        setState(() {
          _articles = List<Map<String, dynamic>>.from(data);
          _isLoadingArticles = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingArticles = false);
    }
  }

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return p.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        ) +
        ' FCFA';
  }

  String get _prenom {
    if (_userName == null) return 'Visiteur';
    final parts = _userName!.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : 'Visiteur';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: RefreshIndicator(
        color: MboaColors.primary,
        onRefresh: _chargerDonnees,
        child: CustomScrollView(
          slivers: [
            // ── AppBar ───────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: MboaColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: MboaColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bonjour $_prenom 👋',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const Text(
                                    'Bienvenue sur Mboa',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppConstants.defaultVille,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Stack(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: MboaColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Barre recherche
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                const Icon(Icons.search_rounded,
                                    color: MboaColors.textMuted,
                                    size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Chambre, studio, meuble...',
                                    style: MboaTextStyles.muted,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: MboaColors.primary,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Catégories ─────────────────────
                    _buildSectionTitle('Explorer', null),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildCategoryCard(
                            '🏠', 'Logement', MboaColors.primary, null),
                        const SizedBox(width: 12),
                        _buildCategoryCard(
                            '🛒', 'Market', MboaColors.secondary, null),
                        const SizedBox(width: 12),
                        _buildCategoryCard(
                          '🗺️',
                          'Carte',
                          MboaColors.accent,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MapScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Logements récents ───────────────
                    _buildSectionTitle(
                        '🏘 Logements récents', 'Voir tout'),
                    const SizedBox(height: 14),
                    _isLoadingLogements
                        ? _buildShimmerLogements()
                        : _logements.isEmpty
                            ? _buildEmptySection(
                                'Aucun logement disponible')
                            : SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _logements.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 14),
                                  itemBuilder: (context, index) {
                                    return _buildLogementCard(
                                        _logements[index]);
                                  },
                                ),
                              ),
                    const SizedBox(height: 28),

                    // ── Bannière ────────────────────────
                    _buildStatsBanner(),
                    const SizedBox(height: 28),

                    // ── Market ──────────────────────────
                    _buildSectionTitle(
                        '🛒 Bons plans Market', 'Voir tout'),
                    const SizedBox(height: 14),
                    _isLoadingArticles
                        ? _buildShimmerArticles()
                        : _articles.isEmpty
                            ? _buildEmptySection(
                                'Aucun article disponible')
                            : GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: _articles.length,
                                itemBuilder: (context, index) {
                                  return _buildArticleCard(
                                      _articles[index]);
                                },
                              ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MboaColors.text,
          ),
        ),
        if (action != null)
          Text(
            '$action →',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MboaColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(
      String emoji, String label, Color color, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child:
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MboaColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogementCard(Map<String, dynamic> l) {
    final isLoggedIn = _supabase.auth.currentUser != null;
    return GestureDetector(
      onTap: () {
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connectez-vous pour voir les détails'),
              backgroundColor: MboaColors.primary,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LogementDetailScreen(logement: l),
          ),
        );
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(MboaSizes.radiusLg),
                topRight: Radius.circular(MboaSizes.radiusLg),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: MboaColors.cardGradient,
                    ),
                    child: l['photos'] != null &&
                            (l['photos'] as List).isNotEmpty
                        ? Image.network(
                            l['photos'][0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('🏠',
                                  style: TextStyle(fontSize: 44)),
                            ),
                          )
                        : const Center(
                            child: Text('🏠',
                                style: TextStyle(fontSize: 44)),
                          ),
                  ),
                  if (l['boosted'] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge('🔥 Boost', MboaColors.boost),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 15,
                        color: MboaColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l['titre'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MboaColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatPrix(l['prix']),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 11, color: MboaColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          l['quartier'] ?? 'Sangmelima',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: MboaColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 12, color: MboaColors.boost),
                      const SizedBox(width: 2),
                      Text(
                        '${l['note_globale'] ?? 0}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: MboaColors.text,
                        ),
                      ),
                      Text(
                        ' (${l['nb_avis'] ?? 0})',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: MboaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> a) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(article: a),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(MboaSizes.radiusLg),
                topRight: Radius.circular(MboaSizes.radiusLg),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MboaColors.secondary.withValues(alpha: 0.3),
                          MboaColors.accent.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                    child: a['photos'] != null &&
                            (a['photos'] as List).isNotEmpty
                        ? Image.network(
                            a['photos'][0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('📦',
                                  style: TextStyle(fontSize: 38)),
                            ),
                          )
                        : const Center(
                            child: Text('📦',
                                style: TextStyle(fontSize: 38)),
                          ),
                  ),
                  if (a['boosted'] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge('🔥', MboaColors.boost),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['titre'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MboaColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a['etat'] ?? '',
                    style: MboaTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrix(a['prix']),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.accent,
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

  Widget _buildStatsBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MboaColors.primaryDark, MboaColors.primary],
        ),
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trouve ton Mboa 🏘',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Logements disponibles à Sangmelima',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Rechercher →',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MboaColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Text('🏠', style: TextStyle(fontSize: 60)),
        ],
      ),
    );
  }

  // ── Shimmer loading ────────────────────────────────────────
  Widget _buildShimmerLogements() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Container(
          width: 200,
          decoration: BoxDecoration(
            color: MboaColors.border,
            borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerArticles() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: MboaColors.border,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
      ),
      child: Center(
        child: Text(
          message,
          style: MboaTextStyles.muted,
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}