import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/router.dart';
import 'logement_detail_screen.dart';

class LogementScreen extends StatefulWidget {
  const LogementScreen({super.key});

  @override
  State<LogementScreen> createState() => _LogementScreenState();
}

class _LogementScreenState extends State<LogementScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _logements = [];
  bool _isLoading = true;
  String _selectedType = 'Tous';
  double _prixMax = 60000;
  String _selectedDistance = 'Toutes';
  bool _showFiltres = false;

  @override
  void initState() {
    super.initState();
    _chargerLogements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerLogements() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('logements')
          .select('*, proprietaire:users!proprietaire_id(nom, photo_url, verified)')
          .eq('statut', 'disponible');

      if (_selectedType != 'Tous') {
        query = query.eq('type', _selectedType);
      }

      query = query.lte('prix', _prixMax.toInt());

      if (_searchController.text.isNotEmpty) {
        query = query.or(
          'titre.ilike.%${_searchController.text}%,quartier.ilike.%${_searchController.text}%',
        );
      }

      final data = await query
          .order('boosted', ascending: false)
          .order('note_globale', ascending: false)
          .order('date_publication', ascending: false);

      if (mounted) {
        setState(() {
          _logements = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isLoggedIn => _supabase.auth.currentUser != null;

  List<Map<String, dynamic>> get _displayedLogements => _isLoggedIn
      ? _logements
      : _logements.take(AppConstants.pageSizeVisiteur).toList();

  bool get _showLimitBanner =>
      !_isLoggedIn && _logements.length > AppConstants.pageSizeVisiteur;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header fixe ──────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                      _chargerLogements(),
                                  decoration:
                                      const InputDecoration(
                                    hintText:
                                        'Quartier, type...',
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
                                    _chargerLogements();
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
                                ? MboaColors.primary
                                : MboaColors.background,
                            borderRadius:
                                BorderRadius.circular(12),
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

                  // Filtres types
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'Tous',
                        'Chambre',
                        'Studio',
                        'Appartement'
                      ].map((type) {
                        final isSelected =
                            _selectedType == type;
                        return GestureDetector(
                          onTap: () {
                            setState(
                                () => _selectedType = type);
                            _chargerLogements();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            margin: const EdgeInsets.only(
                                right: 8),
                            padding: const EdgeInsets
                                .symmetric(
                                horizontal: 16,
                                vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MboaColors.primary
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(20),
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

                  // Filtres avancés
                  if (_showFiltres) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                        overlayColor: MboaColors.primary
                            .withValues(alpha: 0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _prixMax,
                        min: AppConstants.prixMin,
                        max: AppConstants.prixMax,
                        divisions: 39,
                        onChanged: (v) {
                          setState(() => _prixMax = v);
                          _chargerLogements();
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = 'Tous';
                        _prixMax = 60000;
                        _selectedDistance = 'Toutes';
                        _showFiltres = false;
                        _searchController.clear();
                        _chargerLogements();
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

            // ── Résultats ────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(
                    _isLoading
                        ? 'Chargement...'
                        : '${_logements.length} logement${_logements.length > 1 ? 's' : ''} trouvé${_logements.length > 1 ? 's' : ''}',
                    style: MboaTextStyles.muted,
                  ),
                  const Spacer(),
                  const Icon(Icons.sort_rounded,
                      size: 16,
                      color: MboaColors.textMuted),
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

            // ── Liste ────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: MboaColors.primary),
                    )
                  : _logements.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: MboaColors.primary,
                          onRefresh: _chargerLogements,
                          child: ListView.separated(
                            padding: const EdgeInsets
                                .fromLTRB(20, 0, 20, 20),
                            itemCount: _displayedLogements.length +
                                (_showLimitBanner ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              if (index >=
                                  _displayedLogements.length) {
                                return _buildLimitBanner();
                              }
                              return _buildLogementTile(
                                  _displayedLogements[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogementTile(Map<String, dynamic> l) {
    final isLoggedIn =
        _supabase.auth.currentUser != null;
    final proprietaire = l['proprietaire'];

    return GestureDetector(
      onTap: () {
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Connectez-vous pour voir les détails'),
              backgroundColor: MboaColors.primary,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LogementDetailScreen(logement: l),
          ),
        );
      },
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
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft:
                    Radius.circular(MboaSizes.radiusLg),
                bottomLeft:
                    Radius.circular(MboaSizes.radiusLg),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 130,
                    decoration: const BoxDecoration(
                      gradient: MboaColors.cardGradient,
                    ),
                    child: l['photos'] != null &&
                            (l['photos'] as List).isNotEmpty
                        ? Image.network(
                            l['photos'][0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(
                              child: Text('🏠',
                                  style: TextStyle(
                                      fontSize: 44)),
                            ),
                          )
                        : const Center(
                            child: Text('🏠',
                                style: TextStyle(
                                    fontSize: 44)),
                          ),
                  ),
                  if (l['boosted'] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge(
                          '🔥', MboaColors.boost),
                    ),
                ],
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (l['boosted'] == true)
                          _buildBadge(
                              '🔥 Boost', MboaColors.boost),
                        if (l['boosted'] == true)
                          const SizedBox(width: 4),
                        if (proprietaire?['verified'] ==
                            true)
                          _buildBadge('✅ Vérifié',
                              MboaColors.verified),
                      ],
                    ),
                    if (l['boosted'] == true ||
                        proprietaire?['verified'] == true)
                      const SizedBox(height: 6),
                    Text(
                      l['titre'] ?? '',
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
                        const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: MboaColors.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          l['quartier'] ?? 'Sangmelima',
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
                            size: 13,
                            color: MboaColors.boost),
                        const SizedBox(width: 3),
                        Text(
                          '${l['note_globale'] ?? 0}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MboaColors.text,
                          ),
                        ),
                        Text(
                          '  ·  ${l['surface'] ?? '?'}m²',
                          style: MboaTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: MboaColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MboaColors.primaryDark, MboaColors.primary],
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
            'Créez un compte gratuit pour découvrir tous les logements disponibles à Sangmelima',
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
                foregroundColor: MboaColors.primary,
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
              _searchController.clear();
              _chargerLogements();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
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
      padding: const EdgeInsets.symmetric(
          horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color.withValues(alpha: 0.3)),
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