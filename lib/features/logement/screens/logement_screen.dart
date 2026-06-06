import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'logement_detail_screen.dart';

class LogementScreen extends StatefulWidget {
  const LogementScreen({super.key});

  @override
  State<LogementScreen> createState() => _LogementScreenState();
}

class _LogementScreenState extends State<LogementScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'Tous';
  double _prixMax = 60000;
  String _selectedDistance = 'Toutes';
  List<String> _selectedEquipements = [];
  bool _showFiltres = false;

  final List<Map<String, dynamic>> _logements = [
    {
      'id': '1',
      'titre': 'Chambre meublée - Centre ville',
      'prix': 20000,
      'type': 'Chambre',
      'distance': '650m du campus',
      'distanceVal': 650,
      'note': 4.7,
      'avis': 23,
      'boosted': true,
      'verified': true,
      'quartier': 'Mvog-Ada',
      'emoji': '🏠',
      'equipements': ['Wifi', 'Eau courante', 'Électricité', 'Meublé'],
      'surface': 14,
      'statut': 'disponible',
      'proprietaire': 'Louise D.',
    },
    {
      'id': '2',
      'titre': 'Studio moderne - Quartier calme',
      'prix': 35000,
      'type': 'Studio',
      'distance': '1.2km du campus',
      'distanceVal': 1200,
      'note': 4.5,
      'avis': 15,
      'boosted': false,
      'verified': true,
      'quartier': 'Nkol-Eton',
      'emoji': '🏢',
      'equipements': ['Wifi', 'Eau courante', 'Électricité', 'Meublé', 'Cuisine'],
      'surface': 22,
      'statut': 'disponible',
      'proprietaire': 'Jean P.',
    },
    {
      'id': '3',
      'titre': 'Chambre simple - Proche marché',
      'prix': 15000,
      'type': 'Chambre',
      'distance': '900m du campus',
      'distanceVal': 900,
      'note': 4.2,
      'avis': 8,
      'boosted': false,
      'verified': false,
      'quartier': 'Mvog-Mbi',
      'emoji': '🏡',
      'equipements': ['Eau courante', 'Électricité'],
      'surface': 10,
      'statut': 'disponible',
      'proprietaire': 'Marie S.',
    },
    {
      'id': '4',
      'titre': 'Appartement 2 pièces lumineux',
      'prix': 55000,
      'type': 'Appartement',
      'distance': '2km du campus',
      'distanceVal': 2000,
      'note': 4.9,
      'avis': 41,
      'boosted': true,
      'verified': true,
      'quartier': 'Centre',
      'emoji': '🏗️',
      'equipements': ['Wifi', 'Eau courante', 'Électricité', 'Meublé', 'Cuisine', 'Salon'],
      'surface': 38,
      'statut': 'disponible',
      'proprietaire': 'Thomas K.',
    },
    {
      'id': '5',
      'titre': 'Chambre meublée - Près de l\'IUT',
      'prix': 18000,
      'type': 'Chambre',
      'distance': '300m du campus',
      'distanceVal': 300,
      'note': 4.6,
      'avis': 19,
      'boosted': false,
      'verified': true,
      'quartier': 'Elig-Essono',
      'emoji': '🏘',
      'equipements': ['Eau courante', 'Électricité', 'Meublé'],
      'surface': 12,
      'statut': 'disponible',
      'proprietaire': 'Sophie B.',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    return _logements.where((l) {
      final matchType = _selectedType == 'Tous' || l['type'] == _selectedType;
      final matchPrix = l['prix'] <= _prixMax;
      final matchSearch = _searchController.text.isEmpty ||
          l['titre'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
          l['quartier'].toLowerCase().contains(_searchController.text.toLowerCase());
      final matchDist = _selectedDistance == 'Toutes' ||
          (_selectedDistance == '< 500m' && l['distanceVal'] < 500) ||
          (_selectedDistance == '< 1km' && l['distanceVal'] < 1000) ||
          (_selectedDistance == '< 2km' && l['distanceVal'] < 2000);
      final matchEquip = _selectedEquipements.isEmpty ||
          _selectedEquipements.every((e) => (l['equipements'] as List).contains(e));
      return matchType && matchPrix && matchSearch && matchDist && matchEquip;
    }).toList()
      ..sort((a, b) {
        if (a['boosted'] && !b['boosted']) return -1;
        if (!a['boosted'] && b['boosted']) return 1;
        if (a['verified'] && !b['verified']) return -1;
        if (!a['verified'] && b['verified']) return 1;
        return (b['note'] as double).compareTo(a['note'] as double);
      });
  }

  String _formatPrix(int prix) {
    return prix.toString().replaceAllMapped(
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
            // ── Header fixe ──────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  const Text(
                    '🏘 Logement',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Barre de recherche
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
                                    hintText: 'Quartier, type...',
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
                                        size: 18, color: MboaColors.textMuted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bouton filtre
                      GestureDetector(
                        onTap: () => setState(() => _showFiltres = !_showFiltres),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _showFiltres
                                ? MboaColors.primary
                                : MboaColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _showFiltres
                                  ? MboaColors.primary
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

                  // Filtres types (chips horizontaux)
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['Tous', 'Chambre', 'Studio', 'Appartement']
                          .map((type) {
                        final isSelected = _selectedType == type;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MboaColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? MboaColors.primary
                                    : MboaColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
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

                  // Panel filtres avancés
                  if (_showFiltres) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Prix max
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Budget maximum',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: MboaColors.text,
                          ),
                        ),
                        Text(
                          _formatPrix(_prixMax.toInt()),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: MboaColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: MboaColors.primary,
                        inactiveTrackColor: MboaColors.border,
                        thumbColor: MboaColors.primary,
                        overlayColor: MboaColors.primary.withOpacity(0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _prixMax,
                        min: AppConstants.prixMin,
                        max: AppConstants.prixMax,
                        divisions: 39,
                        onChanged: (v) => setState(() => _prixMax = v),
                      ),
                    ),

                    // Distance
                    const Text(
                      'Distance du campus',
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
                        children: ['Toutes', '< 500m', '< 1km', '< 2km']
                            .map((d) {
                          final isSelected = _selectedDistance == d;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDistance = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? MboaColors.primaryLight
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? MboaColors.primaryLight
                                      : MboaColors.border,
                                ),
                              ),
                              child: Text(
                                d,
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

                    // Reset
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = 'Tous';
                        _prixMax = 60000;
                        _selectedDistance = 'Toutes';
                        _selectedEquipements = [];
                        _showFiltres = false;
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} logement${filtered.length > 1 ? 's' : ''} trouvé${filtered.length > 1 ? 's' : ''}',
                    style: MboaTextStyles.muted,
                  ),
                  const Spacer(),
                  const Icon(Icons.sort_rounded,
                      size: 16, color: MboaColors.textMuted),
                  const SizedBox(width: 4),
                  const Text(
                    'Pertinence',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MboaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Liste ────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildLogementTile(filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogementTile(Map<String, dynamic> l) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LogementDetailScreen(logement: l),
        ),
      ),
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
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(MboaSizes.radiusLg),
                bottomLeft: Radius.circular(MboaSizes.radiusLg),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 130,
                    decoration: const BoxDecoration(
                      gradient: MboaColors.cardGradient,
                    ),
                    child: Center(
                      child: Text(l['emoji'],
                          style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                  if (l['boosted'])
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge('🔥', MboaColors.boost),
                    ),
                ],
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges
                    Row(
                      children: [
                        if (l['verified'])
                          _buildBadge('✅ Vérifié', MboaColors.verified),
                        if (l['boosted']) const SizedBox(width: 4),
                        if (l['boosted'])
                          _buildBadge('🔥 Boost', MboaColors.boost),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      l['titre'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: MboaColors.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          l['distance'],
                          style: MboaTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      _formatPrix(l['prix']),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: MboaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: MboaColors.boost),
                        const SizedBox(width: 3),
                        Text(
                          '${l['note']}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MboaColors.text,
                          ),
                        ),
                        Text(
                          '  ·  ${l['surface']}m²',
                          style: MboaTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Flèche
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: MboaColors.textMuted),
            ),
          ],
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
            'Aucun logement trouvé',
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
              _selectedType = 'Tous';
              _prixMax = 60000;
              _selectedDistance = 'Toutes';
              _selectedEquipements = [];
              _searchController.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: MboaColors.primary,
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}