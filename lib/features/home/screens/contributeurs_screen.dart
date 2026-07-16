import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../profil/screens/profil_vendeur_screen.dart';

class ContributeursScreen extends StatefulWidget {
  const ContributeursScreen({super.key});

  @override
  State<ContributeursScreen> createState() => _ContributeursScreenState();
}

class _ContributeursScreenState extends State<ContributeursScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _contributeurs = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('role', 'vendeur')
          .eq('actif', true)
          .order('verified', ascending: false)
          .order('boosted', ascending: false)
          .order('note_globale', ascending: false)
          .order('nb_avis', ascending: false);
      if (mounted) {
        setState(() {
          _contributeurs = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtres {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _contributeurs;
    return _contributeurs
        .where((c) =>
            (c['nom'] ?? '').toString().toLowerCase().contains(q) ||
            (c['nom_commerce'] ?? '').toString().toLowerCase().contains(q))
        .toList();
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (nom.isNotEmpty) return nom[0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = AppConstants.gridColumns(width);
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('🤝 Contributeurs',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                  const Icon(Icons.search_rounded, color: MboaColors.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un vendeur, une boutique...',
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
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
                : _filtres.isEmpty
                    ? Center(child: Text('Aucun contributeur trouvé', style: MboaTextStyles.muted))
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _filtres.length,
                        itemBuilder: (context, index) => _buildCard(_filtres[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final nom = c['nom'] ?? 'Vendeur';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilVendeurScreen(vendeur: c)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: MboaColors.primary, shape: BoxShape.circle),
                  child: c['photo_url'] != null
                      ? ClipOval(
                          child: Image.network(c['photo_url'], fit: BoxFit.cover, width: 56, height: 56,
                              errorBuilder: (_, __, ___) => Center(
                                  child: Text(_initiales(nom),
                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)))),
                        )
                      : Center(
                          child: Text(_initiales(nom),
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                ),
                if (c['verified'] == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: MboaColors.verified, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: MboaColors.text)),
            const SizedBox(height: 2),
            Text(c['nom_commerce'] ?? 'Contributeur Mboa', maxLines: 1, overflow: TextOverflow.ellipsis, style: MboaTextStyles.caption),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 13, color: MboaColors.boost),
                const SizedBox(width: 2),
                Text('${c['note_globale'] ?? 0}',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: MboaColors.text)),
                Text(' (${c['nb_avis'] ?? 0})', style: MboaTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
