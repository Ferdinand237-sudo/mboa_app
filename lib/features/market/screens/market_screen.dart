import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'article_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _searchController = TextEditingController();
  String _selectedCategorie = 'Tous';
  String _selectedEtat = 'Tous';
  bool _showFiltres = false;

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = true;

  final List<Map<String, String>> _categories = [
    {'label': 'Tous', 'icon': '🛍'},
    {'label': 'Literie', 'icon': '🛏'},
    {'label': 'Mobilier', 'icon': '🪑'},
    {'label': 'Cuisine', 'icon': '🍳'},
    {'label': 'Électronique', 'icon': '💨'},
    {'label': 'Divers', 'icon': '📦'},
  ];

  List<Map<String, dynamic>> get _filtered {
    return _articles.where((a) {
      final matchCat = _selectedCategorie == 'Tous' ||
          a['categorie'] == _selectedCategorie;
      final matchEtat =
          _selectedEtat == 'Tous' || a['etat'] == _selectedEtat;
      final matchSearch = _searchController.text.isEmpty ||
          a['titre']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchCat && matchEtat && matchSearch;
    }).toList()
      ..sort((a, b) {
        if (a['boosted'] && !b['boosted']) return -1;
        if (!a['boosted'] && b['boosted']) return 1;
        return (b['vendeurNote'] as double)
            .compareTo(a['vendeurNote'] as double);
      });
  }

  @override
  void initState() {
    super.initState();
    _chargerArticles();
  }

  Future<void> _chargerArticles() async {
    try {
      final data = await _supabase
          .from('articles')
          .select('*, vendeur:users!vendeur_id(nom, verified)')
          .eq('statut', 'disponible')
          .order('boosted', ascending: false)
          .order('date_publication', ascending: false)
          .limit(200);
      if (mounted) {
        setState(() {
          _articles = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatPrix(int prix) {
    return prix
            .toString()
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            ) +
        ' FCFA';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MboaColors.border),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.search_rounded,
                                  color: MboaColors.textMuted, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    hintText: 'Lit, table, frigo...',
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
                              if (_searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(Icons.close_rounded,
                                        size: 18,
                                        color: MboaColors.textMuted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showFiltres = !_showFiltres),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _showFiltres
                                ? MboaColors.secondary
                                : MboaColors.background,
                            borderRadius: BorderRadius.circular(12),
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
                            _selectedCategorie == cat['label'];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedCategorie = cat['label']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MboaColors.secondary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  cat['label']!,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
                          'Correct'
                        ].map((etat) {
                          final isSelected = _selectedEtat == etat;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedEtat = etat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? MboaColors.accent
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
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
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategorie = 'Tous';
                        _selectedEtat = 'Tous';
                        _showFiltres = false;
                        _searchController.clear();
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
                  ],
                ],
              ),
            ),

            // ── Résultats ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} article${filtered.length > 1 ? 's' : ''} trouvé${filtered.length > 1 ? 's' : ''}',
                    style: MboaTextStyles.muted,
                  ),
                ],
              ),
            ),

            // ── Grille ───────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (filtered.isEmpty
                      ? _buildEmpty()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildArticleCard(filtered[index]);
                          },
                        )),
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(MboaSizes.radiusLg),
                topRight: Radius.circular(MboaSizes.radiusLg),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MboaColors.secondary.withValues(alpha: 0.25),
                          MboaColors.accent.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(a['emoji'],
                          style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                  if (a['boosted'])
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge('🔥 Boost', MboaColors.boost),
                    ),
                  if (a['negociable'])
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildBadge('💬 Négociable', MboaColors.primary),
                    ),
                ],
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['titre'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: MboaColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a['etat'],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: MboaColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrix(a['prix']),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: MboaColors.accent,
                      ),
                    ),
                    const Spacer(),
                    // Vendeur + bouton contact
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 11, color: MboaColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            a['vendeur'],
                            style: MboaTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: MboaColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_rounded,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Contacter',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 60)),
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
        ],
      ),
    );
  }
}