import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Données mock — seront remplacées par Supabase
  final List<Map<String, dynamic>> _logements = [
    {
      'id': '1',
      'titre': 'Chambre meublée - Centre ville',
      'prix': 20000,
      'type': 'Chambre',
      'distance': '650m du campus',
      'note': 4.7,
      'avis': 23,
      'boosted': true,
      'verified': true,
      'quartier': 'Mvog-Ada',
      'emoji': '🏠',
      'equipements': ['Wifi', 'Eau', 'Élec', 'Meublé'],
    },
    {
      'id': '2',
      'titre': 'Studio moderne - Quartier calme',
      'prix': 35000,
      'type': 'Studio',
      'distance': '1.2km du campus',
      'note': 4.5,
      'avis': 15,
      'boosted': false,
      'verified': true,
      'quartier': 'Nkol-Eton',
      'emoji': '🏢',
      'equipements': ['Wifi', 'Eau', 'Élec', 'Meublé', 'Cuisine'],
    },
    {
      'id': '3',
      'titre': 'Appartement 2 pièces',
      'prix': 55000,
      'type': 'Appartement',
      'distance': '2km du campus',
      'note': 4.9,
      'avis': 41,
      'boosted': true,
      'verified': true,
      'quartier': 'Centre',
      'emoji': '🏗️',
      'equipements': ['Wifi', 'Eau', 'Élec', 'Meublé', 'Cuisine', 'Salon'],
    },
  ];

  final List<Map<String, dynamic>> _articles = [
    {
      'titre': 'Lit 2 places + matelas',
      'prix': 18000,
      'etat': 'Bon état',
      'emoji': '🛏',
      'vendeur': 'Rodrigue K.',
      'boosted': true,
    },
    {
      'titre': 'Table de travail + chaise',
      'prix': 8500,
      'etat': 'Très bon état',
      'emoji': '🪑',
      'vendeur': 'Aminata D.',
      'boosted': false,
    },
    {
      'titre': 'Plaque à gaz + bonbonne',
      'prix': 12000,
      'etat': 'Bon état',
      'emoji': '🍳',
      'vendeur': 'Eric B.',
      'boosted': false,
    },
    {
      'titre': 'Mini-frigo 50L',
      'prix': 35000,
      'etat': 'Très bon état',
      'emoji': '❄️',
      'vendeur': 'Tech Store',
      'boosted': false,
    },
  ];

  String _formatPrix(int prix) {
    return '${prix.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar personnalisé ──────────────────────────
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
                        // Salutation + Notif
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour 👋',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
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
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Bouton notification
                            Stack(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
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

                        // Barre de recherche
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.search_rounded,
                                color: MboaColors.textMuted,
                                size: 20,
                              ),
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
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: MboaColors.primary,
                                  borderRadius: BorderRadius.circular(10),
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
                  // ── Catégories rapides ───────────────────
                  _buildSectionTitle('Explorer', null),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildCategoryCard('🏠', 'Logement', MboaColors.primary),
                      const SizedBox(width: 12),
                      _buildCategoryCard('🛒', 'Market', MboaColors.secondary),
                      const SizedBox(width: 12),
                      _buildCategoryCard('🗺️', 'Carte', MboaColors.accent),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Logements récents ────────────────────
                  _buildSectionTitle('🏘 Logements récents', 'Voir tout'),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _logements.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return _buildLogementCard(_logements[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Bannière stats ───────────────────────
                  _buildStatsBanner(),
                  const SizedBox(height: 28),

                  // ── Bons plans Market ────────────────────
                  _buildSectionTitle('🛒 Bons plans Market', 'Voir tout'),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      return _buildArticleCard(_articles[index]);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────
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
          GestureDetector(
            onTap: () {},
            child: Text(
              '$action →',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MboaColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  // ── Catégorie card ─────────────────────────────────────────
  Widget _buildCategoryCard(String emoji, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
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

  // ── Logement card ──────────────────────────────────────────
  Widget _buildLogementCard(Map<String, dynamic> logement) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
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
                    height: 110,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: MboaColors.cardGradient,
                    ),
                    child: Center(
                      child: Text(
                        logement['emoji'],
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        if (logement['boosted'])
                          _buildBadge('🔥 Boost', MboaColors.boost),
                        if (logement['verified'])
                          const SizedBox(width: 4),
                        if (logement['verified'])
                          _buildBadge('✅', MboaColors.verified),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
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

            // Infos
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logement['titre'],
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
                    _formatPrix(logement['prix']),
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
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: MboaColors.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          logement['distance'],
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
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: MboaColors.boost,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${logement['note']}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: MboaColors.text,
                        ),
                      ),
                      Text(
                        ' (${logement['avis']})',
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

  // ── Bannière stats ─────────────────────────────────────────
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
                  'Plus de 50 logements disponibles à Sangmelima',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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

  // ── Article card ───────────────────────────────────────────
  Widget _buildArticleCard(Map<String, dynamic> article) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MboaColors.secondary.withOpacity(0.3),
                          MboaColors.accent.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        article['emoji'],
                        style: const TextStyle(fontSize: 38),
                      ),
                    ),
                  ),
                  if (article['boosted'])
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge('🔥', MboaColors.boost),
                    ),
                ],
              ),
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['titre'],
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
                    article['etat'],
                    style: MboaTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrix(article['prix']),
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

  // ── Badge ──────────────────────────────────────────────────
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
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