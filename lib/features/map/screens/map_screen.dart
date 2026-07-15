import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../logement/screens/logement_detail_screen.dart';

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
  Map<String, dynamic>? _selectedLogement;
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

  // Points d'intérêt fixes
  final List<Map<String, dynamic>> _pointsInteret = [
    {
      'label': 'Campus IUT',
      'icon': '🎓',
      'lat': 2.9350,
      'lng': 11.9820,
      'color': 0xFF2D6A4F,
    },
    {
      'label': 'Hôpital District',
      'icon': '🏥',
      'lat': 2.9280,
      'lng': 11.9800,
      'color': 0xFFEF4444,
    },
    {
      'label': 'Grand Marché',
      'icon': '🛒',
      'lat': 2.9320,
      'lng': 11.9860,
      'color': 0xFFF4A261,
    },
    {
      'label': 'Commissariat',
      'icon': '🚔',
      'lat': 2.9340,
      'lng': 11.9840,
      'color': 0xFF1A1A2E,
    },
    {
      'label': 'Pharmacie',
      'icon': '💊',
      'lat': 2.9310,
      'lng': 11.9830,
      'color': 0xFF10B981,
    },
  ];

  @override
  void initState() {
    super.initState();
    _chargerLogements();
  }

  Future<void> _chargerLogements() async {
    try {
      final data = await _supabase
          .from('logements')
          .select(
              '*, proprietaire:users!proprietaire_id(nom, verified)')
          .eq('statut', 'disponible')
          .not('lat', 'is', null)
          .not('lng', 'is', null);

      if (mounted) {
        setState(() {
          _logements =
              List<Map<String, dynamic>>.from(data);
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

  List<Map<String, dynamic>> get _filteredLogements {
    if (_selectedFilter == 'Tous') return _logements;
    return _logements
        .where((l) => l['type'] == _selectedFilter)
        .toList();
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

  Future<void> _ouvrirItineraire(
      double lat, double lng) async {
    final url = Uri.parse(
        'https://www.openstreetmap.org/directions?from=&to=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url,
          mode: LaunchMode.externalApplication);
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
                    'Sangmelima · ${_filteredLogements.length} logement${_filteredLogements.length > 1 ? 's' : ''}',
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
                        '📍 POI',
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
                            onTap: (_, __) => setState(
                                () =>
                                    _selectedLogement =
                                        null),
                          ),
                          children: [
                            // Tuiles OpenStreetMap
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.mboa.app',
                            ),

                            // Marqueurs logements
                            if (_selectedFilter != '📍 POI')
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
                                      onTap: () => setState(
                                          () =>
                                              _selectedLogement =
                                                  l),
                                      child:
                                          _buildLogementMarker(
                                              l, isSelected),
                                    ),
                                  );
                                }).toList(),
                              ),

                            // Marqueurs POI
                            if (_selectedFilter == '📍 POI' ||
                                _selectedFilter == 'Tous')
                              MarkerLayer(
                                markers: _pointsInteret
                                    .map((poi) => Marker(
                                          point: LatLng(
                                            poi['lat'],
                                            poi['lng'],
                                          ),
                                          width: 80,
                                          height: 60,
                                          child:
                                              _buildPoiMarker(
                                                  poi),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),

                  // ── Boutons contrôle ──────────────
                  Positioned(
                    right: 16,
                    bottom: _selectedLogement != null
                        ? 220
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

                  // ── Légende ───────────────────────
                  Positioned(
                    left: 16,
                    bottom: _selectedLogement != null
                        ? 220
                        : 20,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildLegende(
                              '🏠', 'Logement',
                              MboaColors.primary),
                          const SizedBox(height: 6),
                          _buildLegende(
                              '🎓', 'Campus',
                              MboaColors.primaryLight),
                          const SizedBox(height: 6),
                          _buildLegende(
                              '🏥', 'Hôpital',
                              MboaColors.danger),
                          const SizedBox(height: 6),
                          _buildLegende(
                              '🛒', 'Marché',
                              MboaColors.secondary),
                        ],
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

  Widget _buildPoiMarker(Map<String, dynamic> poi) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(poi['color'])
                .withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Color(poi['color']),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              poi['icon'],
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
            poi['label'],
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(poi['color']),
            ),
          ),
        ),
      ],
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

  Widget _buildLegende(
      String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji,
            style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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