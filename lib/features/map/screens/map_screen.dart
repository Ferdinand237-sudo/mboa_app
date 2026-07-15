import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../logement/screens/logement_detail_screen.dart';
import 'lieux_recherche_resultats_screen.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic>? focusLogement;

  const MapScreen({super.key, this.focusLogement});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _supabase = Supabase.instance.client;
  final _mapController = MapController();

  List<Map<String, dynamic>> _logements = [];
  List<Map<String, dynamic>> _lieuxPublics = [];
  Map<String, dynamic>? _selectedLogement;
  Map<String, dynamic>? _selectedLieu;
  Position? _userPosition;
  bool _isAdmin = false;
  bool _isLoading = true;
  String _selectedFilter = 'Tous';

  // Centre de la carte (Sangmelima ou logement ciblé)
  late final LatLng _center = widget.focusLogement != null &&
          widget.focusLogement!['lat'] != null &&
          widget.focusLogement!['lng'] != null
      ? LatLng(
          (widget.focusLogement!['lat'] as num).toDouble(),
          (widget.focusLogement!['lng'] as num).toDouble(),
        )
      : const LatLng(
          AppConstants.defaultLat,
          AppConstants.defaultLng,
        );

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
    _chargerRole();
    _localiserUtilisateur();
  }

  Future<void> _chargerDonnees() async {
    try {
      final results = await Future.wait([
        _supabase
            .from('logements')
            .select('*, proprietaire:users!proprietaire_id(nom, verified)')
            .eq('statut', 'disponible')
            .not('lat', 'is', null)
            .not('lng', 'is', null),
        _supabase.from('lieux_publics').select(),
      ]);

      if (mounted) {
        setState(() {
          _logements = List<Map<String, dynamic>>.from(results[0]);
          _lieuxPublics = List<Map<String, dynamic>>.from(results[1]);
          _isLoading = false;
        });

        if (widget.focusLogement != null) {
          final id = widget.focusLogement!['id'];
          final match = _logements.firstWhere(
            (l) => l['id'] == id,
            orElse: () => widget.focusLogement!,
          );
          setState(() => _selectedLogement = match);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _chargerRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      if (mounted) setState(() => _isAdmin = data['role'] == 'admin');
    } catch (_) {}
  }

  Future<void> _localiserUtilisateur() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _userPosition = position);
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredLogements {
    if (_selectedFilter == 'Tous') return _logements;
    if (_selectedFilter == '📍 Lieux') return [];
    return _logements
        .where((l) => l['type'] == _selectedFilter)
        .toList();
  }

  bool get _afficherLieux =>
      _selectedFilter == 'Tous' || _selectedFilter == '📍 Lieux';

  Map<String, dynamic> _categorieInfo(String categorie) {
    return AppConstants.categoriesLieuxPublics.firstWhere(
      (c) => c['valeur'] == categorie,
      orElse: () => AppConstants.categoriesLieuxPublics.last,
    );
  }

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return p
            .toString()
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            ) +
        ' F';
  }

  String _formatDistanceUtilisateur(double lat, double lng) {
    if (_userPosition == null) return '';
    final metres = Geolocator.distanceBetween(
        _userPosition!.latitude, _userPosition!.longitude, lat, lng);
    return metres < 1000
        ? '${metres.round()} m de vous'
        : '${(metres / 1000).toStringAsFixed(1)} km de vous';
  }

  Future<void> _ouvrirItineraire(double lat, double lng) async {
    final origine = _userPosition != null
        ? '${_userPosition!.latitude},${_userPosition!.longitude}'
        : '';
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$origine&destination=$lat,$lng&travelmode=walking');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _ajouterLieuIci() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activez la localisation pour ajouter un lieu'),
              backgroundColor: MboaColors.danger,
            ),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation refusée'),
              backgroundColor: MboaColors.danger,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final nomController = TextEditingController();
      String categorieChoisie = 'autre';

      final confirme = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
            ),
            title: const Text(
              '📍 Ajouter un lieu ici',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: MboaColors.text,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position captée : ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                  style: MboaTextStyles.caption,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(
                    hintText: 'Nom du lieu (ex: Université Inter-États)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.categoriesLieuxPublics.map((c) {
                    final selected = categorieChoisie == c['valeur'];
                    return GestureDetector(
                      onTap: () => setDialogState(
                          () => categorieChoisie = c['valeur']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(c['color']).withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? Color(c['color'])
                                : MboaColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${c['icon']} ${c['label']}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Color(c['color'])
                                : MboaColors.text,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: nomController.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      );

      if (confirme != true || nomController.text.trim().isEmpty) return;

      await _supabase.from('lieux_publics').insert({
        'nom': nomController.text.trim(),
        'categorie': categorieChoisie,
        'lat': position.latitude,
        'lng': position.longitude,
        'cree_par': _supabase.auth.currentUser?.id,
      });

      await _chargerDonnees();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Lieu ajouté avec succès'),
            backgroundColor: MboaColors.primary,
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🗺️ Carte',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MboaColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sangmelima · ${_filteredLogements.length} logement${_filteredLogements.length > 1 ? 's' : ''} · ${_lieuxPublics.length} lieu${_lieuxPublics.length > 1 ? 'x' : ''}',
                    style: MboaTextStyles.muted,
                  ),
                  const SizedBox(height: 12),

                  // Filtres
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'Tous',
                        'Chambre',
                        'Studio',
                        'Appartement',
                        '📍 Lieux',
                      ].map((f) {
                        final isSelected =
                            _selectedFilter == f;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            margin: const EdgeInsets.only(
                                right: 8),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14,
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
                              f,
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
                ],
              ),
            ),

            // ── Carte ────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: MboaColors.primary),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _center,
                            initialZoom: 14.5,
                            onTap: (_, __) => setState(() {
                              _selectedLogement = null;
                              _selectedLieu = null;
                            }),
                          ),
                          children: [
                            // Tuiles OpenStreetMap
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.mboa.app',
                            ),

                            // Marqueur position utilisateur
                            if (_userPosition != null)
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(
                                      _userPosition!.latitude,
                                      _userPosition!.longitude),
                                  width: 22,
                                  height: 22,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white,
                                          width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ]),

                            // Marqueurs logements
                            if (_selectedFilter != '📍 Lieux')
                              MarkerLayer(
                                markers: _filteredLogements
                                    .where((l) =>
                                        l['lat'] != null &&
                                        l['lng'] != null)
                                    .map((l) {
                                  final isSelected =
                                      _selectedLogement?[
                                              'id'] ==
                                          l['id'];
                                  return Marker(
                                    point: LatLng(
                                      (l['lat'] as num)
                                          .toDouble(),
                                      (l['lng'] as num)
                                          .toDouble(),
                                    ),
                                    width: isSelected
                                        ? 120
                                        : 90,
                                    height: isSelected
                                        ? 50
                                        : 40,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedLogement = l;
                                        _selectedLieu = null;
                                      }),
                                      child:
                                          _buildLogementMarker(
                                              l, isSelected),
                                    ),
                                  );
                                }).toList(),
                              ),

                            // Marqueurs lieux publics
                            if (_afficherLieux)
                              MarkerLayer(
                                markers: _lieuxPublics.map((lieu) {
                                  final cat = _categorieInfo(
                                      lieu['categorie'] ?? 'autre');
                                  return Marker(
                                    point: LatLng(
                                      (lieu['lat'] as num).toDouble(),
                                      (lieu['lng'] as num).toDouble(),
                                    ),
                                    width: 80,
                                    height: 60,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedLieu = lieu;
                                        _selectedLogement = null;
                                      }),
                                      child: _buildLieuMarker(lieu, cat),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),

                  // ── Boutons contrôle ──────────────
                  Positioned(
                    right: 16,
                    bottom:
                        (_selectedLogement != null || _selectedLieu != null)
                            ? 240
                            : 20,
                    child: Column(
                      children: [
                        // Recentrer
                        _buildMapBtn(
                          icon: Icons.my_location_rounded,
                          onTap: () {
                            _mapController.move(
                                _center, 14.5);
                          },
                        ),
                        const SizedBox(height: 8),
                        // Zoom +
                        _buildMapBtn(
                          icon: Icons.add_rounded,
                          onTap: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController
                                      .camera.zoom +
                                  1,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Zoom -
                        _buildMapBtn(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController
                                      .camera.zoom -
                                  1,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Bouton admin : ajouter un lieu ────
                  if (_isAdmin)
                    Positioned(
                      left: 16,
                      bottom:
                          (_selectedLogement != null || _selectedLieu != null)
                              ? 240
                              : 20,
                      child: GestureDetector(
                        onTap: _ajouterLieuIci,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: MboaColors.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: MboaColors.primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_location_alt_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Ajouter un lieu ici',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Fiche logement sélectionné ────
                  if (_selectedLogement != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildLogementCard(
                          _selectedLogement!),
                    ),

                  // ── Fiche lieu public sélectionné ────
                  if (_selectedLieu != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildLieuCard(_selectedLieu!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogementMarker(
      Map<String, dynamic> l, bool isSelected) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? MboaColors.primaryDark
                : MboaColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    MboaColors.primary.withValues(alpha: 0.4),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            _formatPrix(l['prix']),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isSelected ? 11 : 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected
                ? MboaColors.primaryDark
                : MboaColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildLieuMarker(
      Map<String, dynamic> lieu, Map<String, dynamic> cat) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(cat['color'])
                .withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Color(cat['color']),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              cat['icon'],
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            lieu['nom'] ?? '',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(cat['color']),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLieuCard(Map<String, dynamic> lieu) {
    final cat = _categorieInfo(lieu['categorie'] ?? 'autre');
    final lat = (lieu['lat'] as num).toDouble();
    final lng = (lieu['lng'] as num).toDouble();
    final distance = _formatDistanceUtilisateur(lat, lng);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MboaColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(cat['color']).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(cat['icon'],
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lieu['nom'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: MboaColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      distance.isNotEmpty
                          ? '${cat['label']} · $distance'
                          : cat['label'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(cat['color']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _ouvrirItineraire(lat, lng),
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Itinéraire'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LieuxRechercheResultatsScreen(
                        lieuNom: lieu['nom'] ?? '',
                        lat: lat,
                        lng: lng,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Autour de ce lieu'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogementCard(Map<String, dynamic> l) {
    final proprietaire =
        l['proprietaire'] as Map<String, dynamic>? ?? {};
    final photos = l['photos'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(MboaSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: MboaColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      gradient: MboaColors.cardGradient,
                    ),
                    child: photos.isNotEmpty
                        ? Image.network(
                            photos[0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(
                              child: Text('🏠',
                                  style: TextStyle(
                                      fontSize: 36)),
                            ),
                          )
                        : const Center(
                            child: Text('🏠',
                                style: TextStyle(
                                    fontSize: 36)),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        l['titre'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
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
                          const SizedBox(width: 3),
                          Text(
                            l['quartier'] ?? 'Sangmelima',
                            style: MboaTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatPrix(l['prix'])}/mois',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: MboaColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (l['boosted'] == true)
                            _buildBadge(
                                '🔥', MboaColors.boost),
                          if (proprietaire['verified'] ==
                              true) ...[
                            const SizedBox(width: 4),
                            _buildBadge(
                                '✅', MboaColors.verified),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Boutons
          Padding(
            padding: const EdgeInsets.fromLTRB(
                16, 0, 16, 16),
            child: Row(
              children: [
                // Itinéraire
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _ouvrirItineraire(
                      (l['lat'] as num).toDouble(),
                      (l['lng'] as num).toDouble(),
                    ),
                    icon: const Icon(
                        Icons.directions_rounded,
                        size: 16),
                    label: const Text('Itinéraire'),
                  ),
                ),
                const SizedBox(width: 10),
                // Voir détail
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LogementDetailScreen(
                                  logement: l),
                        ),
                      );
                    },
                    icon: const Icon(
                        Icons.visibility_rounded,
                        size: 16),
                    label: const Text('Voir le logement'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child:
            Icon(icon, color: MboaColors.primary, size: 20),
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
