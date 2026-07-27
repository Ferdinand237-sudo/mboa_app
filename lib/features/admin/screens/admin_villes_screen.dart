import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AdminVillesScreen extends StatefulWidget {
  const AdminVillesScreen({super.key});

  @override
  State<AdminVillesScreen> createState() => _AdminVillesScreenState();
}

class _AdminVillesScreenState extends State<AdminVillesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _villes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerVilles();
  }

  Future<void> _chargerVilles() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('villes').select().order('ordre_affichage');
      if (mounted) {
        setState(() {
          _villes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActif(String id, bool actif) async {
    try {
      await _supabase.from('villes').update({'actif': !actif}).eq('id', id);
      // Retire l'état de VilleService (rayon/liste potentiellement obsolètes
      // ailleurs dans l'app tant qu'un redémarrage ne recharge pas), et
      // recharge la liste locale de cet écran.
      await _chargerVilles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  Future<void> _ouvrirFormulaire({Map<String, dynamic>? ville}) async {
    final nomController = TextEditingController(text: ville?['nom'] ?? '');
    final latController = TextEditingController(text: ville != null ? '${ville['lat']}' : '');
    final lngController = TextEditingController(text: ville != null ? '${ville['lng']}' : '');
    final rayonController = TextEditingController(text: ville != null ? '${ville['rayon_couverture_km']}' : '30');
    final ordreController = TextEditingController(
        text: ville != null ? '${ville['ordre_affichage']}' : '${_villes.length}');

    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusLg)),
        title: Text(
          ville == null ? '📍 Ajouter une ville' : '✏️ Modifier ${ville['nom']}',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom de la ville',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusMd)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusMd)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusMd)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: rayonController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Rayon de couverture (km)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusMd)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ordreController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Ordre d\'affichage',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(MboaSizes.radiusMd)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(ville == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    final lat = double.tryParse(latController.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(lngController.text.trim().replaceAll(',', '.'));
    final rayon = double.tryParse(rayonController.text.trim().replaceAll(',', '.')) ?? 30;
    final ordre = int.tryParse(ordreController.text.trim()) ?? 0;

    if (nomController.text.trim().isEmpty || lat == null || lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nom, latitude et longitude sont obligatoires'), backgroundColor: MboaColors.danger),
        );
      }
      return;
    }

    try {
      final valeurs = {
        'nom': nomController.text.trim(),
        'lat': lat,
        'lng': lng,
        'rayon_couverture_km': rayon,
        'ordre_affichage': ordre,
      };
      if (ville == null) {
        await _supabase.from('villes').insert(valeurs);
      } else {
        await _supabase.from('villes').update(valeurs).eq('id', ville['id']);
      }
      await _chargerVilles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ville == null ? '✅ Ville ajoutée' : '✅ Ville mise à jour'), backgroundColor: MboaColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement'), backgroundColor: MboaColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: MboaColors.text,
        title: const Text(
          'Villes couvertes',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, color: MboaColors.text),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MboaColors.primary,
        onPressed: () => _ouvrirFormulaire(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MboaColors.primary))
          : _villes.isEmpty
              ? Center(
                  child: Text('Aucune ville pour le moment', style: MboaTextStyles.muted),
                )
              : RefreshIndicator(
                  color: MboaColors.primary,
                  onRefresh: _chargerVilles,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _villes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ville = _villes[index];
                      final actif = ville['actif'] == true;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _ouvrirFormulaire(ville: ville),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ville['nom'] ?? '',
                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: MboaColors.text),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${ville['lat']}, ${ville['lng']} · rayon ${ville['rayon_couverture_km']}km · ordre ${ville['ordre_affichage']}',
                                      style: MboaTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Switch(
                              value: actif,
                              activeThumbColor: MboaColors.primary,
                              onChanged: (_) => _toggleActif(ville['id'], actif),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
