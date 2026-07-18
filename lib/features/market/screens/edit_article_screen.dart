import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class EditArticleScreen extends StatefulWidget {
  final Map<String, dynamic> article;
  const EditArticleScreen({super.key, required this.article});

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  late final TextEditingController _titreController;
  late final TextEditingController _descController;
  late final TextEditingController _prixController;

  late String _selectedCategorie;
  late String _selectedEtat;
  late bool _negociable;
  late bool _accepteAvis;
  late List<String> _photosExistantes;
  final List<File> _nouvellesPhotos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.article;
    _titreController = TextEditingController(text: a['titre'] ?? '');
    _descController = TextEditingController(text: a['description'] ?? '');
    _prixController = TextEditingController(text: '${a['prix'] ?? ''}');
    _selectedCategorie = a['categorie'] ?? AppConstants.categoriesMarket.first['label'];
    _selectedEtat = a['etat'] ?? 'Bon état';
    _negociable = a['negociable'] == true;
    _accepteAvis = a['accepte_avis'] == true;
    _photosExistantes = List<String>.from(a['photos'] ?? []);
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
    if (_totalPhotos >= AppConstants.maxPhotosArticle) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${AppConstants.maxPhotosArticle} photos'), backgroundColor: MboaColors.danger),
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
      await _supabase.storage.from(AppConstants.bucketArticles).upload(fileName, entry.value).timeout(const Duration(seconds: 30));
      return _supabase.storage.from(AppConstants.bucketArticles).getPublicUrl(fileName);
    }));
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalPhotos < AppConstants.minPhotosArticle) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Au moins 1 photo requise'), backgroundColor: MboaColors.danger),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final nouvellesUrls = await _uploadNouvellesPhotos();
      await _supabase.from(AppConstants.tableArticles).update({
        'titre': _titreController.text.trim(),
        'description': _descController.text.trim(),
        'categorie': _selectedCategorie,
        'etat': _selectedEtat,
        'prix': int.parse(_prixController.text.trim().replaceAll(' ', '')),
        'negociable': _negociable,
        'accepte_avis': _accepteAvis,
        'photos': [..._photosExistantes, ...nouvellesUrls],
      }).eq('id', widget.article['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Article mis à jour'), backgroundColor: MboaColors.secondary),
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
        title: const Text('✏️ Modifier l\'article',
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
              Text('$_totalPhotos/${AppConstants.maxPhotosArticle} photos', style: MboaTextStyles.caption),
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
                    if (_totalPhotos < AppConstants.maxPhotosArticle)
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
              _buildLabel('Catégorie'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.categoriesMarket.map((cat) {
                  final isSelected = _selectedCategorie == cat['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategorie = cat['label']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? MboaColors.secondary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? MboaColors.secondary : MboaColors.border, width: 1.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(cat['icon']!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(cat['label']!,
                            style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : MboaColors.text)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildLabel('État'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.etatsArticle.map((etat) {
                  final isSelected = _selectedEtat == etat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEtat = etat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? MboaColors.accent : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? MboaColors.accent : MboaColors.border, width: 1.5),
                      ),
                      child: Text(etat,
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : MboaColors.text)),
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
              _buildLabel('Prix (FCFA)'),
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
                    Switch(value: _negociable, onChanged: (v) => setState(() => _negociable = v), activeColor: MboaColors.primary),
                    const Text('Négociable',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: MboaColors.text)),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Switch(value: _accepteAvis, onChanged: (v) => setState(() => _accepteAvis = v), activeColor: MboaColors.primary),
                const Expanded(
                  child: Text('Autoriser les avis et notes sur cet article',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: MboaColors.text)),
                ),
              ]),
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
