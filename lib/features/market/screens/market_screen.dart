import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mboa_cached_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/router.dart';
import 'article_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = true;
  String _selectedCategorie = 'Tous';
  String _selectedEtat = 'Tous';
  bool _showFiltres = false;

  @override
  void initState() {
    super.initState();
    _chargerArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerArticles() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('articles')
          .select(
              '*, vendeur:users!vendeur_id(nom, photo_url, verified, note_globale)')
          .eq('statut', 'disponible');

      if (_selectedCategorie != 'Tous') {
        query = query.eq('categorie', _selectedCategorie);
      }

      if (_selectedEtat != 'Tous') {
        query = query.eq('etat', _selectedEtat);
      }

      if (_searchController.text.isNotEmpty) {
        query = query.or(
          'titre.ilike.%${_searchController.text}%,description.ilike.%${_searchController.text}%',
        );
      }

      final data = await query
          .order('boosted', ascending: false)
          .order('date_publication', ascending: false);

      if (mounted) {
        setState(() {
          _articles =
              List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return p
            .toString()
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            ) +
        ' FCFA';
  }

  Future<void> _enregistrerAlerte() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour enregistrer une alerte'), backgroundColor: MboaColors.primary),
      );
      return;
    }
    final libelle = [
      if (_selectedCategorie != 'Tous') _selectedCategorie,
      if (_selectedEtat != 'Tous') _selectedEtat,
    ].join(' · ');
    try {
      await _supabase.from('alertes_recherche').insert({
        'user_id': userId,
        'type': 'article',
        'libelle': libelle.isEmpty ? 'Tous les articles Market' : libelle,
        'criteres': {'categorie': _selectedCategorie, 'etat': _selectedEtat},
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔔 Alerte enregistrée !'), backgroundColor: MboaColors.verified),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  bool get _isLoggedIn => _supabase.auth.currentUser != null;

  List<Map<String, dynamic>> get _displayedArticles => _isLoggedIn
      ? _articles
      : _articles.take(AppConstants.pageSizeVisiteur).toList();

  bool get _showLimitBanner =>
      !_isLoggedIn && _articles.length > AppConstants.pageSizeVisiteur;

  final List<Map<String, String>> _categories = [
    {'label': 'Tous', 'icon': '🛍'},
    {'label': 'Literie', 'icon': '🛏'},
    {'label': 'Mobilier', 'icon': '🪑'},
    {'label': 'Cuisine', 'icon': '🍳'},
    {'label': 'Électronique', 'icon': '💨'},
    {'label': 'Divers', 'icon': '📦'},
  ];

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
                  const Text(
                    '🛒 Market',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recherche
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: MboaColors.background,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                                color: MboaColors.border),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(
                                  Icons.search_rounded,
                                  color: MboaColors.textMuted,
                                  size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller:
                                      _searchController,
                                  onChanged: (_) =>
                                      _chargerArticles(),
                                  decoration:
                                      const InputDecoration(
                                    hintText:
                                        'Lit, table, frigo...',
                                    border: InputBorder.none,
                                    enabledBorder:
                                        InputBorder.none,
                                    focusedBorder:
                                        InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.zero,
                                  ),
                                  style: MboaTextStyles.body,
                                ),
                              ),
                              if (_searchController
                                  .text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _chargerArticles();
                                  },
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.all(10),
                                    child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: MboaColors
                                            .textMuted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(
                            () => _showFiltres =
                                !_showFiltres),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 200),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _showFiltres
                                ? MboaColors.secondary
                                : MboaColors.background,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: _showFiltres
                                  ? MboaColors.secondary
                                  : MboaColors.border,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: _showFiltres
                                ? Colors.white
                                : MboaColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Catégories
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _categories.map((cat) {
                        final isSelected =
                            _selectedCategorie ==
                                cat['label'];
                        return GestureDetector(
                          onTap: () {
                            setState(() =>
                                _selectedCategorie =
                                    cat['label']!);
                            _chargerArticles();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            margin: const EdgeInsets.only(
                                right: 8),
                            padding: const EdgeInsets
                                .symmetric(
                                horizontal: 14,
                                vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MboaColors.secondary
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? MboaColors.secondary
                                    : MboaColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(cat['icon']!,
                                    style: const TextStyle(
                                        fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  cat['label']!,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : MboaColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Filtre état
                  if (_showFiltres) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const Text(
                      'État de l\'article',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MboaColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          'Tous',
                          'Neuf',
                          'Très bon état',
                          'Bon état',
                          'Correct',
                        ].map((etat) {
                          final isSelected =
                              _selectedEtat == etat;
                          return GestureDetector(
                            onTap: () {
                              setState(() =>
                                  _selectedEtat = etat);
                              _chargerArticles();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(
                                  milliseconds: 200),
                              margin: const EdgeInsets.only(
                                  right: 8),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? MboaColors.accent
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? MboaColors.accent
                                      : MboaColors.border,
                                ),
                              ),
                              child: Text(
                                etat,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
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
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategorie = 'Tous';
                            _selectedEtat = 'Tous';
                            _showFiltres = false;
                            _searchController.clear();
                            _chargerArticles();
                          }),
                          child: const Text(
                            'Réinitialiser les filtres',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: MboaColors.danger,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _enregistrerAlerte,
                          child: const Text(
                            '🔔 Enregistrer comme alerte',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: MboaColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Résultats ────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    _isLoading
                        ? 'Chargement...'
                        : '${_displayedArticles.length} article${_displayedArticles.length > 1 ? 's' : ''} trouvé${_displayedArticles.length > 1 ? 's' : ''}',
                    style: MboaTextStyles.muted,
                  ),
                ],
              ),
            ),

            // ── Grille ───────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: MboaColors.secondary),
                    )
                  : _articles.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: MboaColors.secondary,
                          onRefresh: _chargerArticles,
                          child: CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets
                                    .fromLTRB(20, 0, 20, 20),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        AppConstants.gridColumns(
                                            MediaQuery.of(context)
                                                .size
                                                .width),
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1,
                                  ),
                                  delegate:
                                      SliverChildBuilderDelegate(
                                    (context, index) =>
                                        _buildArticleCard(
                                            _displayedArticles[
                                                index]),
                                    childCount:
                                        _displayedArticles.length,
                                  ),
                                ),
                              ),
                              if (_showLimitBanner)
                                SliverPadding(
                                  padding: const EdgeInsets
                                      .fromLTRB(20, 0, 20, 20),
                                  sliver: SliverToBoxAdapter(
                                    child: _buildLimitBanner(),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> a) {
    final vendeur = a['vendeur'];
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
          borderRadius:
              BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Carte carrée : proportion fixe entre l'image et le bloc
        // d'informations pour ne jamais déborder quel que soit l'écran.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft:
                      Radius.circular(MboaSizes.radiusLg),
                  topRight:
                      Radius.circular(MboaSizes.radiusLg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MboaColors.secondary
                                .withValues(alpha: 0.25),
                            MboaColors.accent
                                .withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                      child: a['photos'] != null &&
                              (a['photos'] as List)
                                  .isNotEmpty
                          ? MboaCachedImage(url: a['photos'][0], emojiPlaceholder: '📦')
                          : const Center(
                              child: Text('📦',
                                  style: TextStyle(
                                      fontSize: 36)),
                            ),
                    ),
                    if (a['boosted'] == true)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _buildBadge(
                            '🔥', MboaColors.boost),
                      ),
                    if (a['negociable'] == true)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _buildBadge(
                            '💬', MboaColors.primary),
                      ),
                  ],
                ),
              ),
            ),

            // Infos
            Expanded(
              flex: 6,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      a['titre'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      a['etat'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: MboaColors.textMuted,
                      ),
                    ),
                    Text(
                      _formatPrix(a['prix']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: MboaColors.accent,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 10,
                            color: MboaColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            vendeur?['nom'] ?? 'Vendeur',
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              color: MboaColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vendeur?['verified'] == true)
                          const Icon(
                            Icons.verified_rounded,
                            size: 11,
                            color: MboaColors.verified,
                          ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_supabase.auth.currentUser ==
                            null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Connectez-vous pour contacter le vendeur'),
                              backgroundColor:
                                  MboaColors.primary,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ArticleDetailScreen(
                                    article: a),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 6),
                        decoration: BoxDecoration(
                          color: MboaColors.primary,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                                Icons.chat_bubble_rounded,
                                size: 11,
                                color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Contacter',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 7, vertical: 3),
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

  Widget _buildLimitBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MboaColors.accent,
            MboaColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
      ),
      child: Column(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          const Text(
            'Connectez-vous pour voir plus',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Créez un compte gratuit pour découvrir tous les articles du Market',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: MboaColors.accent,
              ),
              onPressed: () => context.push(AppRoutes.register),
              child: const Text('Créer un compte'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍',
              style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'Aucun article trouvé',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MboaColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essaye de modifier tes filtres',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: MboaColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() {
              _selectedCategorie = 'Tous';
              _selectedEtat = 'Tous';
              _searchController.clear();
              _chargerArticles();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: MboaColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Réinitialiser les filtres',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}