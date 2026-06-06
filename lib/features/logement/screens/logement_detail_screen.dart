import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LogementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> logement;
  const LogementDetailScreen({super.key, required this.logement});

  @override
  State<LogementDetailScreen> createState() => _LogementDetailScreenState();
}

class _LogementDetailScreenState extends State<LogementDetailScreen> {
  bool _isFavori = false;
  int _currentPhoto = 0;

  final List<String> _emojisPhotos = ['🏠', '🛏', '🚿', '🍳'];

  final List<Map<String, dynamic>> _proximite = [
    {'icon': '🎓', 'label': 'Campus IUT', 'dist': '650m', 'color': 0xFF2D6A4F},
    {'icon': '🏥', 'label': 'Hôpital District', 'dist': '1.4km', 'color': 0xFFEF4444},
    {'icon': '🛒', 'label': 'Grand Marché', 'dist': '500m', 'color': 0xFFF4A261},
    {'icon': '🚔', 'label': 'Commissariat', 'dist': '800m', 'color': 0xFF1A1A2E},
    {'icon': '💊', 'label': 'Pharmacie', 'dist': '300m', 'color': 0xFF10B981},
  ];

  final List<Map<String, dynamic>> _avis = [
    {
      'nom': 'Armel K.',
      'initiales': 'AK',
      'note': 5,
      'date': 'Mars 2025',
      'commentaire': 'Chambre très propre, propriétaire sérieux et disponible. Je recommande vivement !',
    },
    {
      'nom': 'Fatima N.',
      'initiales': 'FN',
      'note': 4,
      'date': 'Fév. 2025',
      'commentaire': 'Bon rapport qualité/prix. Quartier calme et bien situé par rapport au campus.',
    },
  ];

  String _formatPrix(int prix) {
    return prix.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        ) +
        ' FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.logement;
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: Stack(
        children: [
          // ── Contenu scrollable ─────────────────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Galerie photos ──────────────────────
                _buildGalerie(),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Titre & badges ──────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              l['titre'],
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: MboaColors.text,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (l['verified'])
                            _buildBadge('✅ Vérifié', MboaColors.verified),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Quartier
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: MboaColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${l['quartier']} · Sangmelima',
                            style: MboaTextStyles.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Prix + note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatPrix(l['prix']),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: MboaColors.primary,
                                ),
                              ),
                              const Text(
                                'par mois',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: MboaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: MboaColors.boost, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${l['note']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: MboaColors.text,
                                ),
                              ),
                              Text(
                                '  (${l['avis']} avis)',
                                style: MboaTextStyles.muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Infos rapides
                      Row(
                        children: [
                          _buildInfoChip(
                              '📐', '${l['surface']}m²'),
                          const SizedBox(width: 10),
                          _buildInfoChip('🏠', l['type']),
                          const SizedBox(width: 10),
                          _buildInfoChip('✅', 'Disponible'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Équipements ─────────────────
                      _buildSectionTitle('Équipements'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (l['equipements'] as List)
                            .map<Widget>((eq) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: MboaColors.primary
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: MboaColors.primary
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    '✓  $eq',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: MboaColors.primary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // ── Proximité ───────────────────
                      _buildSectionTitle('📍 Points de proximité'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(MboaSizes.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: _proximite.map((p) {
                            final isLast = _proximite.last == p;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Color(p['color'])
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(p['icon'],
                                              style: const TextStyle(
                                                  fontSize: 18)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          p['label'],
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: MboaColors.text,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(p['color'])
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          p['dist'],
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(p['color']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(height: 1, indent: 16),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bouton carte
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Voir sur la carte'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Propriétaire ────────────────
                      _buildSectionTitle('👤 Propriétaire'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(MboaSizes.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: MboaColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                    (l['proprietaire'] ?? '??')
                                        .toString()
                                        .split(' ')
                                        .map((e) => e.isNotEmpty ? e[0] : '')
                                      .take(2)
                                      .join(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l['proprietaire']?.toString() ?? 'Propriétaire inconnu',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: MboaColors.text,
                                    ),
                                  ),
                                  const Text(
                                    'Membre depuis 2022',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: MboaColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (l['verified'])
                              _buildBadge('✅ Vérifié', MboaColors.verified),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Avis ────────────────────────
                      _buildSectionTitle(
                          '⭐ Avis (${l['avis']})'),
                      const SizedBox(height: 12),
                      ..._avis.map((a) => _buildAvisCard(a)),

                      // Signaler
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _showSignalementDialog(),
                          icon: const Icon(Icons.flag_outlined,
                              size: 16, color: MboaColors.danger),
                          label: const Text(
                            'Signaler cette annonce',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: MboaColors.danger,
                            ),
                          ),
                        ),
                      ),

                      // Espace pour les boutons fixes
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Boutons fixes en bas ───────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Appeler
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Appeler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Message
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_rounded,
                          size: 18),
                      label: const Text('Envoyer un message'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Back button ────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: MboaColors.text),
              ),
            ),
          ),

          // ── Favori button ──────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: () => setState(() => _isFavori = !_isFavori),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  _isFavori
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: MboaColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalerie() {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _emojisPhotos.length,
            onPageChanged: (i) => setState(() => _currentPhoto = i),
            itemBuilder: (context, index) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: MboaColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    _emojisPhotos[index],
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
              );
            },
          ),
          // Indicateur photos
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentPhoto + 1} / ${_emojisPhotos.length}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Boost badge
          if (widget.logement['boosted'])
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildBadge('🔥 Annonce boostée', MboaColors.boost),
            ),
        ],
      ),
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: MboaColors.primaryLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avis['initiales'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MboaColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avis['nom'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    Text(
                      avis['date'],
                      style: MboaTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < avis['note']
                        ? MboaColors.boost
                        : MboaColors.border,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            avis['commentaire'],
            style: MboaTextStyles.body.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: MboaColors.text,
      ),
    );
  }

  Widget _buildInfoChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MboaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
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
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showSignalementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        ),
        title: const Text(
          '🚨 Signaler cette annonce',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Fausse annonce',
            'Arnaque',
            'Prix incorrect',
            'Contenu inapproprié',
            'Annonce dupliquée',
          ].map((r) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signalement envoyé. Merci !'),
                  backgroundColor: MboaColors.primary,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MboaColors.border),
                ),
              ),
              child: Text(
                r,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: MboaColors.text,
                ),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}