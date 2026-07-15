import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../chat/screens/chat_screen.dart';
import '../../map/screens/map_screen.dart';

class LogementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> logement;
  const LogementDetailScreen({super.key, required this.logement});

  @override
  State<LogementDetailScreen> createState() =>
      _LogementDetailScreenState();
}

class _LogementDetailScreenState
    extends State<LogementDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _isFavori = false;
  int _currentPhoto = 0;

  final List<Map<String, dynamic>> _proximite = [
    {'icon': '🎓', 'label': 'Campus IUT', 'dist': '650m', 'color': 0xFF2D6A4F},
    {'icon': '🏥', 'label': 'Hôpital District', 'dist': '1.4km', 'color': 0xFFEF4444},
    {'icon': '🛒', 'label': 'Grand Marché', 'dist': '500m', 'color': 0xFFF4A261},
    {'icon': '🚔', 'label': 'Commissariat', 'dist': '800m', 'color': 0xFF1A1A2E},
    {'icon': '💊', 'label': 'Pharmacie', 'dist': '300m', 'color': 0xFF10B981},
  ];

  List<Map<String, dynamic>> _avis = [];
  bool _isLoadingAvis = true;

  @override
  void initState() {
    super.initState();
    _chargerAvis();
    _verifierFavori();
  }

  Future<void> _verifierFavori() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('favoris')
          .select()
          .eq('user_id', user.id)
          .eq('logement_id', widget.logement['id'])
          .maybeSingle();
      if (mounted) setState(() => _isFavori = data != null);
    } catch (_) {}
  }

  Future<void> _toggleFavori() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour ajouter aux favoris'),
          backgroundColor: MboaColors.primary,
        ),
      );
      return;
    }

    final nouveauStatut = !_isFavori;
    setState(() => _isFavori = nouveauStatut);

    try {
      if (nouveauStatut) {
        await _supabase.from('favoris').insert({
          'user_id': user.id,
          'logement_id': widget.logement['id'],
        });
      } else {
        await _supabase
            .from('favoris')
            .delete()
            .eq('user_id', user.id)
            .eq('logement_id', widget.logement['id']);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavori = !nouveauStatut);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _chargerAvis() async {
    try {
      final data = await _supabase
          .from('avis')
          .select('*, auteur:users!auteur_id(nom)')
          .eq('annonce_id', widget.logement['id'])
          .order('date_publication', ascending: false);
      if (mounted) {
        setState(() {
          _avis = List<Map<String, dynamic>>.from(data);
          _isLoadingAvis = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAvis = false);
    }
  }

  Future<void> _ouvrirChat() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour envoyer un message'),
          backgroundColor: MboaColors.primary,
        ),
      );
      return;
    }

    final logement = widget.logement;
    final proprietaireId = logement['proprietaire_id'];

    if (proprietaireId == null ||
        proprietaireId == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas vous contacter vous-même'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }

    try {
      // Chercher conversation existante
      final existing = await _supabase
          .from('conversations')
          .select()
          .contains('participants', [user.id, proprietaireId])
          .eq('annonce_id', logement['id'])
          .maybeSingle();

      String conversationId;

      if (existing != null) {
        conversationId = existing['id'];
      } else {
        // Créer une nouvelle conversation
        final response = await _supabase
            .from('conversations')
            .insert({
              'participants': [user.id, proprietaireId],
              'annonce_id': logement['id'],
              'annonce_type': 'logement',
              'non_lu': {
                user.id: 0,
                proprietaireId: 0,
              },
            })
            .select('id')
            .single();
        conversationId = response['id'];
      }

      // Récupérer infos propriétaire
      Map<String, dynamic> autreUser = {};
      try {
        autreUser = await _supabase
            .from('users')
            .select('nom, photo_url, verified')
            .eq('id', proprietaireId)
            .single();
      } catch (_) {
        final proprietaire = logement['proprietaire'];
        if (proprietaire is Map) {
          autreUser = Map<String, dynamic>.from(proprietaire);
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: conversationId,
              autreUser: autreUser,
              autreId: proprietaireId,
              sujet:
                  '🏠 ${logement['titre'] ?? 'Logement'}',
              annonceId: logement['id']?.toString(),
              annonceType: 'logement',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
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

  String _getInitiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nom.isNotEmpty ? nom[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.logement;
    final proprietaire = l['proprietaire']
        as Map<String, dynamic>? ?? {};
    final photos = l['photos'] as List? ?? [];
    final equipements = l['equipements'] as List? ?? [];

    return Scaffold(
      backgroundColor: MboaColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Galerie ──────────────────────────
                _buildGalerie(photos, l),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ── Titre ────────────────────
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              l['titre'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: MboaColors.text,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (proprietaire['verified'] ==
                              true)
                            _buildBadge('✅ Vérifié',
                                MboaColors.verified),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: MboaColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${l['quartier'] ?? ''} · Sangmelima',
                            style: MboaTextStyles.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Prix ─────────────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                                  color: MboaColors.boost,
                                  size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${l['note_globale'] ?? 0}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: MboaColors.text,
                                ),
                              ),
                              Text(
                                '  (${l['nb_avis'] ?? 0} avis)',
                                style: MboaTextStyles.muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Infos rapides ─────────────
                      Row(
                        children: [
                          _buildInfoChip('📐',
                              '${l['surface'] ?? '?'}m²'),
                          const SizedBox(width: 10),
                          _buildInfoChip(
                              '🏠', l['type'] ?? ''),
                          const SizedBox(width: 10),
                          _buildInfoChip(
                              '✅', 'Disponible'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Équipements ───────────────
                      _buildSectionTitle('Équipements'),
                      const SizedBox(height: 12),
                      equipements.isEmpty
                          ? Text('Non renseignés',
                              style: MboaTextStyles.muted)
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: equipements
                                  .map<Widget>((eq) =>
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal:
                                                    12,
                                                vertical: 7),
                                        decoration:
                                            BoxDecoration(
                                          color: MboaColors
                                              .primary
                                              .withValues(
                                                  alpha:
                                                      0.08),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      20),
                                          border: Border.all(
                                            color: MboaColors
                                                .primary
                                                .withValues(
                                                    alpha:
                                                        0.2),
                                          ),
                                        ),
                                        child: Text(
                                          '✓  $eq',
                                          style:
                                              const TextStyle(
                                            fontFamily:
                                                'Poppins',
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color: MboaColors
                                                .primary,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                      const SizedBox(height: 24),

                      // ── Proximité ─────────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle(
                              '📍 Points de proximité'),
                          if (l['lat'] != null &&
                              l['lng'] != null)
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MapScreen(
                                      focusLogement: l),
                                ),
                              ),
                              child: const Text(
                                'Voir sur la carte →',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: MboaColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                                  MboaSizes.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children:
                              _proximite.map((p) {
                            final isLast =
                                _proximite.last == p;
                            return Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                          horizontal: 16,
                                          vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration:
                                            BoxDecoration(
                                          color: Color(
                                                  p['color'])
                                              .withValues(
                                                  alpha:
                                                      0.1),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      10),
                                        ),
                                        child: Center(
                                          child: Text(
                                              p['icon'],
                                              style: const TextStyle(
                                                  fontSize:
                                                      18)),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: 12),
                                      Expanded(
                                        child: Text(
                                          p['label'],
                                          style:
                                              const TextStyle(
                                            fontFamily:
                                                'Poppins',
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight
                                                    .w500,
                                            color: MboaColors
                                                .text,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal:
                                                    10,
                                                vertical: 4),
                                        decoration:
                                            BoxDecoration(
                                          color: Color(
                                                  p['color'])
                                              .withValues(
                                                  alpha:
                                                      0.1),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      20),
                                        ),
                                        child: Text(
                                          p['dist'],
                                          style: TextStyle(
                                            fontFamily:
                                                'Poppins',
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            color: Color(
                                                p['color']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                      height: 1,
                                      indent: 16),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Propriétaire ──────────────
                      _buildSectionTitle('👤 Propriétaire'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                                  MboaSizes.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.05),
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
                                  _getInitiales(
                                      proprietaire['nom'] ??
                                          'P'),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    proprietaire['nom'] ??
                                        'Propriétaire',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: MboaColors.text,
                                    ),
                                  ),
                                  const Text(
                                    'Propriétaire Mboa',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color:
                                          MboaColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (proprietaire['verified'] ==
                                true)
                              _buildBadge('✅ Vérifié',
                                  MboaColors.verified),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Avis ──────────────────────
                      _buildSectionTitle(
                          '⭐ Avis (${_avis.length})'),
                      const SizedBox(height: 12),
                      _isLoadingAvis
                          ? const Center(
                              child:
                                  CircularProgressIndicator(
                                      color:
                                          MboaColors.primary),
                            )
                          : _avis.isEmpty
                              ? Container(
                                  padding:
                                      const EdgeInsets.all(
                                          16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(
                                            MboaSizes.radiusMd),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Aucun avis pour l\'instant',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color:
                                            MboaColors.textMuted,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _avis
                                      .map((a) =>
                                          _buildAvisCard(a))
                                      .toList(),
                                ),

                      // Signaler
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              _showSignalementDialog(),
                          icon: const Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color: MboaColors.danger),
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
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Boutons fixes ─────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.08),
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
                      icon: const Icon(
                          Icons.phone_rounded,
                          size: 18),
                      label: const Text('Appeler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _ouvrirChat,
                      icon: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 18),
                      label: const Text(
                          'Envoyer un message'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Back button ───────────────────────────
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
                      color: Colors.black
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: MboaColors.text),
              ),
            ),
          ),

          // ── Favori button ─────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: _toggleFavori,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.1),
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

  Widget _buildGalerie(
      List photos, Map<String, dynamic> l) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          photos.isNotEmpty
              ? PageView.builder(
                  itemCount: photos.length,
                  onPageChanged: (i) =>
                      setState(() => _currentPhoto = i),
                  itemBuilder: (context, index) =>
                      Image.network(
                    photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(
                      decoration: const BoxDecoration(
                        gradient: MboaColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Text('🏠',
                            style:
                                TextStyle(fontSize: 100)),
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: MboaColors.primaryGradient,
                  ),
                  child: const Center(
                    child: Text('🏠',
                        style: TextStyle(fontSize: 100)),
                  ),
                ),
          if (photos.length > 1)
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
                  '${_currentPhoto + 1} / ${photos.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (l['boosted'] == true)
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildBadge(
                  '🔥 Annonce boostée', MboaColors.boost),
            ),
        ],
      ),
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avis) {
    final auteur = avis['auteur']
        as Map<String, dynamic>? ?? {};
    final nom = auteur['nom'] ?? 'Utilisateur';
    final note = avis['note'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(MboaSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: MboaColors.primaryLight
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitiales(nom),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    Text(
                      avis['date_publication'] != null
                          ? _formatDate(
                              avis['date_publication'])
                          : '',
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
                    color: i < note
                        ? MboaColors.boost
                        : MboaColors.border,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            avis['commentaire'] ?? '',
            style: MboaTextStyles.body
                .copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      const mois = [
        '',
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Jun',
        'Jul',
        'Aoû',
        'Sep',
        'Oct',
        'Nov',
        'Déc'
      ];
      return '${mois[date.month]} ${date.year}';
    } catch (_) {
      return '';
    }
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
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MboaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji,
              style: const TextStyle(fontSize: 14)),
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
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
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
          borderRadius:
              BorderRadius.circular(MboaSizes.radiusXl),
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
          ]
              .map((r) => GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final user = _supabase.auth.currentUser;
                      if (user != null) {
                        await _supabase
                            .from('signalements')
                            .insert({
                          'signaleur_id': user.id,
                          'cible_type': 'annonce',
                          'cible_id':
                              widget.logement['id'],
                          'raison': r,
                        });
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Signalement envoyé. Merci !'),
                            backgroundColor:
                                MboaColors.primary,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: MboaColors.border),
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
                  ))
              .toList(),
        ),
      ),
    );
  }
}