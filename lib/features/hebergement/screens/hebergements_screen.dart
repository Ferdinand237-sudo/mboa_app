import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ville_service.dart';
import 'hebergement_detail_screen.dart';

class HebergementsScreen extends StatefulWidget {
  const HebergementsScreen({super.key});

  @override
  State<HebergementsScreen> createState() => _HebergementsScreenState();
}

class _HebergementsScreenState extends State<HebergementsScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;
  List<Map<String, dynamic>> _hebergements = [];
  String _typeSelectionne = 'Tous';

  @override
  void initState() {
    super.initState();
    VilleService.instance.selectedVille.addListener(_charger);
    _charger();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    VilleService.instance.selectedVille.removeListener(_charger);
    super.dispose();
  }

  Future<void> _charger() async {
    final ville = VilleService.instance.selectedVille.value;
    if (ville == null) {
      setState(() { _hebergements = []; _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from(AppConstants.tableHebergements)
          .select('*, proprietaire:users!proprietaire_id(nom, nom_commerce, photo_commerce, verified, note_globale, nb_avis)')
          .eq('statut', 'disponible')
          .eq('statut_moderation', 'publie')
          .eq('ville', ville.nom);

      if (_typeSelectionne != 'Tous') {
        query = query.eq('type_etablissement', _typeSelectionne);
      }
      if (_searchController.text.isNotEmpty) {
        query = query.ilike('titre', '%${_searchController.text}%');
      }

      final data = await query
          .order('boosted', ascending: false)
          .order('date_publication', ascending: false);
      if (mounted) {
        setState(() {
          _hebergements = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _charger);
  }

  String _formatPrix(dynamic prix) {
    final p = (prix ?? 0) as int;
    return '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded, color: MboaColors.text),
                      ),
                      const SizedBox(width: 12),
                      const Text('🏨 Hôtels & Hébergements',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: MboaColors.text)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: MboaColors.background,
                      borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                      border: Border.all(color: MboaColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18, color: MboaColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Rechercher un hôtel, une chambre...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFiltreChip('Tous', 'Tous'),
                        ...AppConstants.typesEtablissement.map((t) => _buildFiltreChip(t['valeur']!, '${t['icon']} ${t['label']}')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
                  : VilleService.instance.selectedVille.value == null
                      ? Center(child: Text('Sélectionnez une ville depuis l\'accueil', style: MboaTextStyles.muted))
                      : _hebergements.isEmpty
                          ? Center(child: Text('Aucun hébergement dans cette ville pour le moment', style: MboaTextStyles.muted))
                          : RefreshIndicator(
                              color: MboaColors.primary,
                              onRefresh: _charger,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _hebergements.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) => _buildCard(_hebergements[index]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltreChip(String valeur, String label) {
    final isSelected = _typeSelectionne == valeur;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _typeSelectionne = valeur);
          _charger();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? MboaColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? MboaColors.primary : MboaColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : MboaColors.text)),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> h) {
    final photos = h['photos'] as List? ?? [];
    final proprietaire = h['proprietaire'] as Map<String, dynamic>? ?? {};
    final nomEtablissement = proprietaire['nom_commerce'] ?? proprietaire['nom'] ?? 'Établissement';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HebergementDetailScreen(hebergement: h))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(MboaSizes.radiusLg)),
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
                child: photos.isNotEmpty
                    ? Image.network(photos[0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🏨', style: TextStyle(fontSize: 28))))
                    : const Center(child: Text('🏨', style: TextStyle(fontSize: 28))),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(h['titre'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                        ),
                        if (h['boosted'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: MboaColors.boost.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                            child: const Text('🔥', style: TextStyle(fontSize: 10)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(nomEtablissement, maxLines: 1, overflow: TextOverflow.ellipsis, style: MboaTextStyles.caption),
                    const SizedBox(height: 6),
                    Text(_formatPrix(h['prix']),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: MboaColors.primary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: MboaColors.boost),
                        const SizedBox(width: 2),
                        Text('${proprietaire['note_globale'] ?? 0}', style: MboaTextStyles.caption),
                        const SizedBox(width: 2),
                        Text('(${proprietaire['nb_avis'] ?? 0})', style: MboaTextStyles.caption),
                        const SizedBox(width: 10),
                        const Icon(Icons.people_outline_rounded, size: 13, color: MboaColors.textMuted),
                        const SizedBox(width: 2),
                        Text('${h['capacite_personnes'] ?? 1}', style: MboaTextStyles.caption),
                      ],
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
}
