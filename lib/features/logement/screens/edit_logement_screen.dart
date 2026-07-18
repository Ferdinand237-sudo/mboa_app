import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class EditLogementScreen extends StatefulWidget {
  final Map<String, dynamic> logement;
  const EditLogementScreen({super.key, required this.logement});

  @override
  State<EditLogementScreen> createState() => _EditLogementScreenState();
}

class _EditLogementScreenState extends State<EditLogementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  late final TextEditingController _titreController;
  late final TextEditingController _descController;
  late final TextEditingController _prixController;
  late final TextEditingController _surfaceController;
  late final TextEditingController _quartierController;

  late String _selectedType;
  late List<String> _selectedEquipements;
  late List<String> _photosExistantes;
  final List<File> _nouvellesPhotos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final l = widget.logement;
    _titreController = TextEditingController(text: l['titre'] ?? '');
    _descController = TextEditingController(text: l['description'] ?? '');
    _prixController = TextEditingController(text: '${l['prix'] ?? ''}');
    _surfaceController = TextEditingController(text: l['surface'] != null ? '${l['surface']}' : '');
    _quartierController = TextEditingController(text: l['quartier'] ?? '');
    _selectedType = l['type'] ?? 'Chambre';
    _selectedEquipements = List<String>.from(l['equipements'] ?? []);
    _photosExistantes = List<String>.from(l['photos'] ?? []);
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _prixController.dispose();
    _surfaceController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  int get _totalPhotos => _photosExistantes.length + _nouvellesPhotos.length;

  Future<void> _ajouterPhoto() async {
    if (_totalPhotos >= AppConstants.maxPhotosLogement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${AppConstants.maxPhotosLogement} photos'), backgroundColor: MboaColors.danger),
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
      await _supabase.storage.from(AppConstants.bucketLogements).upload(fileName, entry.value).timeout(const Duration(seconds: 30));
      return _supabase.storage.from(AppConstants.bucketLogements).getPublicUrl(fileName);
    }));
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalPhotos < AppConstants.minPhotosLogement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum ${AppConstants.minPhotosLogement} photos requises'), backgroundColor: MboaColors.danger),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final nouvellesUrls = await _uploadNouvellesPhotos();
      await _supabase.from(AppConstants.tableLogements).update({
        'titre': _titreController.text.trim(),
        'description': _descController.text.trim(),
        'type': _selectedType,
        'prix': int.parse(_prixController.text.trim().replaceAll(' ', '')),
        'surface': _surfaceController.text.trim().isNotEmpty ? double.parse(_surfaceController.text.trim()) : null,
        'photos': [..._photosExistantes, ...nouvellesUrls],
        'equipements': _selectedEquipements,
        'quartier': _quartierController.text.trim(),
      }).eq('id', widget.logement['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Logement mis à jour'), backgroundColor: MboaColors.primary),
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
        title: const Text('✏️ Modifier le logement',
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
              Text('$_totalPhotos/${AppConstants.maxPhotosLogement} photos', style: MboaTextStyles.caption),
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
                    if (_totalPhotos < AppConstants.maxPhotosLogement)
                      GestureDetector(
                        onTap: _ajouterPhoto,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: MboaColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MboaColors.primary.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined, color: MboaColors.primary, size: 28),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Type de logement'),
              const SizedBox(height: 12),
              Row(
                children: AppConstants.typesLogement.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        margin: EdgeInsets.only(right: type != AppConstants.typesLogement.last ? 10 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? MboaColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? MboaColors.primary : MboaColors.border, width: 1.5),
                        ),
                        child: Text(type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : MboaColors.text)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildLabel('Titre'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titreController,
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Prix / mois (FCFA)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _prixController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (int.tryParse(v.replaceAll(' ', '')) == null) return 'Invalide';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Surface (m²)'),
                        const SizedBox(height: 8),
                        TextFormField(controller: _surfaceController, keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Quartier'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quartierController,
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
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
              const SizedBox(height: 20),
              _buildLabel('Équipements'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.equipements.map((eq) {
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: MboaSizes.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _enregistrer,
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
