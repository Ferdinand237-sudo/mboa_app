import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/mboa_cached_image.dart';
import '../../logement/screens/logement_detail_screen.dart';
import '../../market/screens/article_detail_screen.dart';
import '../../map/screens/map_screen.dart';
import '../../map/screens/lieux_recherche_resultats_screen.dart';
import 'home_search_screen.dart';
import 'notifications_screen.dart';
import 'contributeurs_screen.dart';
import '../../profil/screens/profil_vendeur_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateLogement;
  final VoidCallback? onNavigateMarket;

  const HomeScreen({super.key, this.onNavigateLogement, this.onNavigateMarket});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _logements = [];
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _contributeurs = [];
  bool _isLoadingLogements = true;
  bool _isLoadingArticles = true;
  bool _isLoadingContributeurs = true;
  String? _userName = Supabase.instance.client.auth.currentUser?.userMetadata?['nom'];
  bool _hasNotifications = false;

  // ── Trouve ton Mboa ──────────────────────────────────────
  double? _refLat;
  double? _refLng;
  String _refNom = 'Sangmelima';
  double _rayonKm = 2;
  bool _isLoadingProches = false;
  List<Map<String, dynamic>> _logementsProches = [];
  List<Map<String, dynamic>> _lieuxPublics = [];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
    _initTrouveTonMboa();
  }

  Future<void> _chargerDonnees() async {
    await Future.wait([
      _chargerLogements(),
      _chargerArticles(),
      _chargerUser(),
      _chargerContributeurs(),
      _verifierNotifications(),
    ]);
  }

  Future<void> _chargerUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase.from('users').select('nom').eq('id', user.id).single();
        if (mounted) setState(() => _userName = data['nom']);
      } catch (_) {
        final meta = user.userMetadata;
        if (mounted) setState(() => _userName = meta?['nom'] ?? 'Visiteur');
      }
    }
  }

  Future<void> _verifierNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final conversations = await _supabase
          .from('conversations')
          .select('non_lu')
          .contains('participants', [user.id]);
      var trouve = false;
      for (final conv in List<Map<String, dynamic>>.from(conversations)) {
        final nonLu = conv['non_lu'];
        if (nonLu is Map && ((nonLu[user.id] ?? 0) as num) > 0) {
          trouve = true;
          break;
        }
      }
      if (mounted) setState(() => _hasNotifications = trouve);
    } catch (_) {}
  }

  Future<void> _chargerLogements() async {
    try {
      final data = await _supabase
          .from('logements')
          .select('*, proprietaire:users!proprietaire_id(nom, verified)')
          .eq('statut', 'disponible')
          .order('boosted', ascending: false)
          .order('date_publication', ascending: false)
          .limit(6);
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

  Future<void> _chargerContributeurs() async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('role', 'vendeur')
          .eq('actif', true)
          .order('verified', ascending: false)
          .order('boosted', ascending: false)
          .order('note_globale', ascending: false)
          .limit(8);
      if (mounted) {
        setState(() {
          _contributeurs = List<Map<String, dynamic>>.from(data);
          _isLoadingContributeurs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingContributeurs = false);
    }
  }

  // ── Trouve ton Mboa : position réelle ou lieu choisi ─────
  Future<void> _initTrouveTonMboa() async {
    try {
      final lieux = await _supabase.from('lieux_publics').select('id, nom, categorie, lat, lng').order('nom');
      if (mounted) setState(() => _lieuxPublics = List<Map<String, dynamic>>.from(lieux));
    } catch (_) {}

    double lat = AppConstants.defaultLat;
    double lng = AppConstants.defaultLng;
    String nom = AppConstants.defaultVille;

    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition();
          final distanceVilleM = Geolocator.distanceBetween(
              position.latitude, position.longitude, AppConstants.defaultLat, AppConstants.defaultLng);
          if (distanceVilleM <= 30000) {
            lat = position.latitude;
            lng = position.longitude;
            nom = 'ta position';
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _refLat = lat;
        _refLng = lng;
        _refNom = nom;
      });
      _rechercherProches();
    }
  }

  Future<void> _rechercherProches() async {
    if (_refLat == null || _refLng == null) return;
    setState(() => _isLoadingProches = true);
    try {
      final data = await _supabase.rpc('logements_proches', params: {
        'p_lat': _refLat,
        'p_lng': _refLng,
        'p_rayon_km': _rayonKm,
      });
      if (mounted) {
        setState(() {
          _logementsProches = List<Map<String, dynamic>>.from(data as List).take(8).toList();
          _isLoadingProches = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProches = false);
    }
  }

  void _choisirLieu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choisir un lieu de référence',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
              const SizedBox(height: 14),
              if (_lieuxPublics.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Aucun lieu enregistré pour le moment', style: MboaTextStyles.muted),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _lieuxPublics.length,
                    itemBuilder: (context, index) {
                      final lieu = _lieuxPublics[index];
                      return ListTile(
                        leading: const Icon(Icons.place_rounded, color: MboaColors.primary),
                        title: Text(lieu['nom'] ?? '', style: MboaTextStyles.body),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _refLat = (lieu['lat'] as num).toDouble();
                            _refLng = (lieu['lng'] as num).toDouble();
                            _refNom = lieu['nom'] ?? 'ce lieu';
                          });
                          _rechercherProches();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  String get _prenom {
    if (_userName == null) return 'Visiteur';
    final parts = _userName!.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : 'Visiteur';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = AppConstants.gridColumns(width);
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: RefreshIndicator(
        color: MboaColors.primary,
        onRefresh: () async {
          await _chargerDonnees();
          await _rechercherProches();
        },
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
                  decoration: const BoxDecoration(gradient: MboaColors.primaryGradient),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bonjour $_prenom 👋',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                  ),
                                  const Text(
                                    'Bienvenue sur Mboa',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppConstants.defaultVille,
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                                    ),
                                    if (_hasNotifications)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(color: MboaColors.secondary, shape: BoxShape.circle),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Barre recherche
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeSearchScreen()),
                            ),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 14),
                                  const Icon(Icons.search_rounded, color: MboaColors.textMuted, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text('Chambre, studio, meublé...', style: MboaTextStyles.muted),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: MboaColors.primary, borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                                  ),
                                ],
                              ),
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
                    _buildSectionTitle('Explorer', null, null),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildCategoryCard('🏠', 'Logement', MboaColors.primary, widget.onNavigateLogement),
                        const SizedBox(width: 12),
                        _buildCategoryCard('🛒', 'Market', MboaColors.secondary, widget.onNavigateMarket),
                        const SizedBox(width: 12),
                        _buildCategoryCard(
                          '🗺️',
                          'Carte',
                          MboaColors.accent,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Logements récents ───────────────
                    _buildSectionTitle('🏘 Logements récents', 'Voir tout', widget.onNavigateLogement),
                    const SizedBox(height: 14),
                    _isLoadingLogements
                        ? _buildShimmerGrid(columns)
                        : _logements.isEmpty
                            ? _buildEmptySection('Aucun logement disponible')
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: _logements.length,
                                itemBuilder: (context, index) => _buildLogementCard(_logements[index]),
                              ),
                    const SizedBox(height: 28),

                    // ── Trouve ton Mboa ─────────────────
                    _buildTrouveTonMboa(),
                    const SizedBox(height: 28),

                    // ── Market ──────────────────────────
                    _buildSectionTitle('🛒 Bons plans Market', 'Voir tout', widget.onNavigateMarket),
                    const SizedBox(height: 14),
                    _isLoadingArticles
                        ? _buildShimmerGrid(columns)
                        : _articles.isEmpty
                            ? _buildEmptySection('Aucun article disponible')
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: _articles.length,
                                itemBuilder: (context, index) => _buildArticleCard(_articles[index]),
                              ),
                    const SizedBox(height: 28),

                    // ── Contributeurs ────────────────────
                    _buildSectionTitle('🤝 Contributeurs Mboa', 'Voir tout', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ContributeursScreen()));
                    }),
                    const SizedBox(height: 14),
                    _isLoadingContributeurs
                        ? const SizedBox(height: 120)
                        : _contributeurs.isEmpty
                            ? _buildEmptySection('Aucun contributeur pour le moment')
                            : SizedBox(
                                height: 130,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _contributeurs.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) => _buildContributeurCard(_contributeurs[index]),
                                ),
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

  Widget _buildSectionTitle(String title, String? action, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text),
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              '$action →',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: MboaColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(String emoji, String label, Color color, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: MboaColors.text)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrouveTonMboa() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [MboaColors.primaryDark, MboaColors.primary]),
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trouve ton Mboa 🏘',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Logements autour de $_refNom',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _choisirLieu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Changer 📍', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rayon
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: AppConstants.rayonsRechercheKm.map((r) {
                final isSelected = _rayonKm == r;
                return GestureDetector(
                  onTap: () {
                    setState(() => _rayonKm = r);
                    _rechercherProches();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r < 1 ? '${(r * 1000).round()} m' : '${r.toStringAsFixed(r == r.roundToDouble() ? 0 : 1)} km',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? MboaColors.primary : Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          if (_isLoadingProches)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white)))
          else if (_logementsProches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Aucun logement dans ce rayon pour l\'instant',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _logementsProches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _buildLogementProcheCard(_logementsProches[index]),
              ),
            ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _refLat == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LieuxRechercheResultatsScreen(lieuNom: _refNom, lat: _refLat!, lng: _refLng!),
                        ),
                      ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide.none,
                foregroundColor: MboaColors.primary,
              ),
              child: const Text('Voir tous les résultats →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogementProcheCard(Map<String, dynamic> l) {
    final photos = l['photos'] as List? ?? [];
    final distance = (l['distance_km'] as num?) ?? 0;
    return GestureDetector(
      onTap: () async {
        final isLoggedIn = _supabase.auth.currentUser != null;
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connectez-vous pour voir les détails'), backgroundColor: MboaColors.primary),
          );
          return;
        }
        try {
          final data = await _supabase
              .from('logements')
              .select('*, proprietaire:users!proprietaire_id(nom, photo_url, verified, note_globale)')
              .eq('id', l['id'])
              .single();
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LogementDetailScreen(logement: data)));
          }
        } catch (_) {}
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(MboaSizes.radiusMd)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(MboaSizes.radiusMd)),
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                child: photos.isNotEmpty
                    ? MboaCachedImage(url: photos[0], emojiPlaceholder: '🏠')
                    : const Center(child: Text('🏠', style: TextStyle(fontSize: 30))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l['titre'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: MboaColors.text)),
                  const SizedBox(height: 2),
                  Text(_formatPrix(l['prix']),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: MboaColors.primary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk_rounded, size: 10, color: MboaColors.textMuted),
                      const SizedBox(width: 2),
                      Text(distance < 1 ? '${(distance * 1000).round()} m' : '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: MboaColors.textMuted)),
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

  Widget _buildContributeurCard(Map<String, dynamic> c) {
    final nom = c['nom'] ?? 'Vendeur';
    final initiales = nom.trim().isNotEmpty
        ? (nom.trim().split(' ').length >= 2
            ? '${nom.trim().split(' ')[0][0]}${nom.trim().split(' ')[1][0]}'.toUpperCase()
            : nom.trim()[0].toUpperCase())
        : 'U';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfilVendeurScreen(vendeur: c)),
        );
      },
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: MboaColors.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text(initiales, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                if (c['verified'] == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(color: MboaColors.verified, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 9),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: MboaColors.text)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 10, color: MboaColors.boost),
                Text(' ${c['note_globale'] ?? 0}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: MboaColors.textMuted)),
              ],
            ),
          ],
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
            const SnackBar(content: Text('Connectez-vous pour voir les détails'), backgroundColor: MboaColors.primary),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => LogementDetailScreen(logement: l)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(MboaSizes.radiusLg), topRight: Radius.circular(MboaSizes.radiusLg)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: Container(
                      decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                      child: l['photos'] != null && (l['photos'] as List).isNotEmpty
                          ? MboaCachedImage(url: l['photos'][0], emojiPlaceholder: '🏠')
                          : const Center(child: Text('🏠', style: TextStyle(fontSize: 40))),
                    ),
                  ),
                  if (l['boosted'] == true)
                    Positioned(top: 8, left: 8, child: _buildBadge('🔥 Boost', MboaColors.boost)),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(radius: 14, backgroundColor: Colors.white70, child: Icon(Icons.favorite_border_rounded, size: 15, color: MboaColors.danger)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l['titre'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: MboaColors.text),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(_formatPrix(l['prix']), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: MboaColors.primary)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: MboaColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(l['quartier'] ?? 'Sangmelima',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: MboaColors.textMuted), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: MboaColors.boost),
                      const SizedBox(width: 2),
                      Text('${l['note_globale'] ?? 0}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: MboaColors.text)),
                      Text(' (${l['nb_avis'] ?? 0})', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: MboaColors.textMuted)),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(MboaSizes.radiusLg), topRight: Radius.circular(MboaSizes.radiusLg)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [MboaColors.secondary.withValues(alpha: 0.3), MboaColors.accent.withValues(alpha: 0.2)]),
                      ),
                      child: a['photos'] != null && (a['photos'] as List).isNotEmpty
                          ? MboaCachedImage(url: a['photos'][0], emojiPlaceholder: '📦')
                          : const Center(child: Text('📦', style: TextStyle(fontSize: 36))),
                    ),
                  ),
                  if (a['boosted'] == true) Positioned(top: 8, left: 8, child: _buildBadge('🔥', MboaColors.boost)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['titre'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: MboaColors.text),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(a['etat'] ?? '', style: MboaTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(_formatPrix(a['prix']), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: MboaColors.accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer loading ────────────────────────────────────────
  Widget _buildShimmerGrid(int columns) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: columns * 2,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: MboaColors.border, borderRadius: BorderRadius.circular(MboaSizes.radiusLg)),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(MboaSizes.radiusLg)),
      child: Center(child: Text(message, style: MboaTextStyles.muted)),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}
