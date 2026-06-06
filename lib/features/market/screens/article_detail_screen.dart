import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../profil/screens/profil_vendeur_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isFavori = false;
  int _currentPhoto = 0;

  final List<String> _emojisPhotos = ['', '', '', ''];

  String _formatPrix(int prix) {
    return prix
            .toString()
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            ) +
        ' FCFA';
  }

  Color get _etatColor {
    switch (widget.article['etat']) {
      case 'Neuf':
        return MboaColors.verified;
      case 'Très bon état':
        return MboaColors.primary;
      case 'Bon état':
        return MboaColors.primaryLight;
      default:
        return MboaColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    _emojisPhotos[0] = a['emoji'];
    _emojisPhotos[1] = a['emoji'];
    _emojisPhotos[2] = a['emoji'];
    _emojisPhotos[3] = a['emoji'];

    return Scaffold(
      backgroundColor: MboaColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Galerie ──────────────────────────────
                _buildGalerie(a),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Titre & état ─────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              a['titre'],
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _etatColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _etatColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              a['etat'],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _etatColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Catégorie
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: MboaColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              a['categorie'],
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MboaColors.secondary,
                              ),
                            ),
                          ),
                          if (a['negociable']) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: MboaColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '💬 Prix négociable',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: MboaColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Prix
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              MboaColors.accent,
                              MboaColors.secondary,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(MboaSizes.radiusLg),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prix de vente',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPrix(a['prix']),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (a['negociable'])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Négociable',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Description ──────────────────
                      _buildSectionTitle('Description'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(MboaSizes.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          'Article en ${a['etat'].toString().toLowerCase()}. '
                          'Vendu car je quitte la ville après ma formation. '
                          'Disponible immédiatement. Possibilité de livraison '
                          'dans un rayon de 2km moyennant un supplément.',
                          style: MboaTextStyles.body.copyWith(height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Vendeur ──────────────────────
                      _buildSectionTitle('👤 Vendeur'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilVendeurScreen(
                              vendeur: {
                                'nom': widget.article['vendeur'],
                                'initiales': widget.article['vendeur']
                                    .toString()
                                    .split(' ')
                                    .map((e) => e[0])
                                    .take(2)
                                    .join(),
                                'type': 'Commerçant',
                                'verified': true,
                              },
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                MboaSizes.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
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
                                  color: MboaColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    a['vendeur']
                                        .toString()
                                        .split(' ')
                                        .map((e) => e[0])
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a['vendeur'],
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: MboaColors.text,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 13,
                                            color: MboaColors.boost),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${a['vendeurNote']}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: MboaColors.text,
                                          ),
                                        ),
                                        Text(
                                          '  ·  Voir le profil →',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: MboaColors.primary,
                                            fontWeight: FontWeight.w600,
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
                      ),
                      const SizedBox(height: 24),

                      // ── Infos supplémentaires ────────
                      _buildSectionTitle('ℹ️ Informations'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(MboaSizes.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('📦', 'Catégorie',
                                a['categorie']),
                            _buildInfoRow(
                                '🏷️', 'État', a['etat']),
                            _buildInfoRow('📍', 'Localisation',
                                'Sangmelima, Cameroun'),
                            _buildInfoRow('📅', 'Publié le',
                                'Il y a 2 jours',
                                isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Signaler
                      Center(
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.flag_outlined,
                              size: 16, color: MboaColors.danger),
                          label: const Text(
                            'Signaler cet article',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: MboaColors.danger,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Boutons fixes ──────────────────────────────
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
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Appeler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_rounded,
                          size: 18),
                      label: const Text('Contacter le vendeur'),
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
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildGalerie(Map<String, dynamic> a) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _emojisPhotos.length,
            onPageChanged: (i) => setState(() => _currentPhoto = i),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MboaColors.secondary.withValues(alpha: 0.4),
                      MboaColors.accent.withValues(alpha: 0.3),
                    ],
                  ),
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
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
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
          if (a['boosted'])
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: MboaColors.boost.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🔥 Annonce boostée',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
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

  Widget _buildInfoRow(String emoji, String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: MboaColors.textMuted,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MboaColors.text,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16),
      ],
    );
  }
}