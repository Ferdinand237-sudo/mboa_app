import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class EditHebergementScreen extends StatefulWidget {
  final Map<String, dynamic> hebergement;
  const EditHebergementScreen({super.key, required this.hebergement});

  @override
  State<EditHebergementScreen> createState() => _EditHebergementScreenState();
}

class _EditHebergementScreenState extends State<EditHebergementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  late final TextEditingController _titreController;
  late final TextEditingController _descController;
  late final TextEditingController _prixController;

  late String _selectedType;
  late int _capacitePersonnes;
  late List<String> _selectedEquipements;
  late List<String> _photosExistantes;
  final List<File> _nouvellesPhotos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final h = widget.hebergement;
    _titreController = TextEditingController(text: h['titre'] ?? '');
    _descController = TextEditingController(text: h['description'] ?? '');
    _prixController = TextEditingController(text: '${h['prix'] ?? ''}');
    _selectedType = h['type_etablissement'] ?? 'hotel';
    _capacitePersonnes = h['capacite_personnes'] ?? 1;
    _selectedEquipements = List<String>.from(h['equipements'] ?? []);
    _photosExistantes = List<String>.from(h['photos'] ?? []);
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  int get _totalPhotos => _photosExistantes.length + _nouvellesPhotos.length;

  Future<void> _ajouterPhoto() async {
    if (_totalPhotos >= AppConstants.maxPhotosHebergement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${AppConstants.maxPhotosHebergement} photos'), backgroundColor: MboaColors.danger),
      );
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
    if (picked != null) setState(() => _nouvellesPhotos.add(File(picked.path)));
  }

  Future<List<String>> _uploadNouvellesPhotos() async {
    final userId = _supabase.auth.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return Future.wait(_nouvellesPhotos.asMap().entries.map((entry) async {
      final fileName = '$userId/${timestamp}_${entry.key}.jpg';
      await _supabase.storage.from(AppConstants.bucketHebergements).upload(fileName, entry.value).timeout(const Duration(seconds: 30));
      return _supabase.storage.from(AppConstants.bucketHebergements).getPublicUrl(fileName);
    }));
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalPhotos < AppConstants.minPhotosHebergement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum ${AppConstants.minPhotosHebergement} photos requises'), backgroundColor: MboaColors.danger),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final nouvellesUrls = await _uploadNouvellesPhotos();
      await _supabase.from(AppConstants.tableHebergements).update({
        'titre': _titreController.text.trim(),
        'description': _descController.text.trim(),
        'type_etablissement': _selectedType,
        'capacite_personnes': _capacitePersonnes,
        'prix': int.parse(_prixController.text.trim().replaceAll(' ', '')),
        'equipements': _selectedEquipements,
        'photos': [..._photosExistantes, ...nouvellesUrls],
      }).eq('id', widget.hebergement['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Hébergement mis à jour'), backgroundColor: MboaColors.secondary),
        );
        Navigator.pop(context, true);
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envoi des photos trop lent. Vérifie ta connexion et réessaie.'), backgroundColor: MboaColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: MboaColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('✏️ Modifier l\'hébergement',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: MboaColors.text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('📷 Photos'),
              const SizedBox(height: 4),
              Text('$_totalPhotos/${AppConstants.maxPhotosHebergement} photos', style: MboaTextStyles.caption),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._photosExistantes.asMap().entries.map((entry) => _photoTile(
                          image: NetworkImage(entry.value),
                          onDelete: () => setState(() => _photosExistantes.removeAt(entry.key)),
                        )),
                    ..._nouvellesPhotos.asMap().entries.map((entry) => _photoTile(
                          image: FileImage(entry.value),
                          onDelete: () => setState(() => _nouvellesPhotos.removeAt(entry.key)),
                        )),
                    if (_totalPhotos < AppConstants.maxPhotosHebergement)
                      GestureDetector(
                        onTap: _ajouterPhoto,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: MboaColors.secondary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MboaColors.secondary.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined, color: MboaColors.secondary, size: 28),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Type d\'établissement'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.typesEtablissement.map((t) {
                  final isSelected = _selectedType == t['valeur'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = t['valeur']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? MboaColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? MboaColors.primary : MboaColors.border, width: 1.5),
                      ),
                      child: Text('${t['icon']} ${t['label']}',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : MboaColors.text)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildLabel('Nom de la chambre/du logement'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titreController,
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Prix par nuit (FCFA)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prixController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (int.tryParse(v.replaceAll(' ', '')) == null) return 'Invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(children: [
                    IconButton(
                      onPressed: _capacitePersonnes > 1 ? () => setState(() => _capacitePersonnes--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: MboaColors.primary,
                    ),
                    Text('$_capacitePersonnes 👤',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text)),
                    IconButton(
                      onPressed: () => setState(() => _capacitePersonnes++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: MboaColors.primary,
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Équipements disponibles'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.equipementsHebergement.map((eq) {
                  final isSelected = _selectedEquipements.contains(eq['label']);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedEquipements.remove(eq['label']);
                      } else {
                        _selectedEquipements.add(eq['label']!);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? MboaColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? MboaColors.primary : MboaColors.border, width: 1.5),
                      ),
                      child: Text(isSelected ? '✓  ${eq['label']}' : '${eq['icon']}  ${eq['label']}',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : MboaColors.text)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (v.length < 20) return 'Minimum 20 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: MboaSizes.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(backgroundColor: MboaColors.secondary),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer les modifications'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoTile({required ImageProvider image, required VoidCallback onDelete}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: image, fit: BoxFit.cover)),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: MboaColors.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String title) => Text(title,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: MboaColors.text));
}
