import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';

class EditProfilScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilScreen({super.key, required this.user});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _telephoneController;
  bool _isSaving = false;

  File? _nouvellePhotoProfil;
  File? _nouvellePhotoCouverture;
  String? _photoProfilUrl;
  String? _photoCouvertureUrl;

  bool get _estContributeur => widget.user['role'] == 'vendeur';

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user['nom'] ?? '');
    _telephoneController =
        TextEditingController(text: widget.user['telephone'] ?? '');
    _photoProfilUrl = widget.user['photo_url'];
    _photoCouvertureUrl = widget.user['photo_commerce'];
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto({required bool couverture}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() {
      if (couverture) {
        _nouvellePhotoCouverture = File(picked.path);
      } else {
        _nouvellePhotoProfil = File(picked.path);
      }
    });
  }

  Future<String?> _uploadPhoto(File fichier, String bucket) async {
    final userId = _supabase.auth.currentUser!.id;
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from(bucket).upload(
          fileName,
          fichier,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabase.storage.from(bucket).getPublicUrl(fileName);
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      if (_nouvellePhotoProfil != null) {
        _photoProfilUrl =
            await _uploadPhoto(_nouvellePhotoProfil!, AppConstants.bucketProfils);
      }
      if (_nouvellePhotoCouverture != null) {
        _photoCouvertureUrl = await _uploadPhoto(
            _nouvellePhotoCouverture!, AppConstants.bucketBoutiques);
      }

      await _supabase.from('users').update({
        'nom': _nomController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        if (_photoProfilUrl != null) 'photo_url': _photoProfilUrl,
        if (_photoCouvertureUrl != null) 'photo_commerce': _photoCouvertureUrl,
      }).eq('id', userId);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du profil'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: MboaColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modifier mon profil',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MboaColors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_estContributeur) ...[
                _buildLabel('Photo de couverture (boutique)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _choisirPhoto(couverture: true),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                      gradient: LinearGradient(colors: [
                        MboaColors.secondary.withValues(alpha: 0.25),
                        MboaColors.accent.withValues(alpha: 0.15),
                      ]),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                      child: _nouvellePhotoCouverture != null
                          ? Image.file(_nouvellePhotoCouverture!, fit: BoxFit.cover, width: double.infinity)
                          : _photoCouvertureUrl != null
                              ? Image.network(_photoCouvertureUrl!, fit: BoxFit.cover, width: double.infinity,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.add_a_photo_outlined, color: MboaColors.textMuted)))
                              : const Center(child: Icon(Icons.add_a_photo_outlined, color: MboaColors.textMuted)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildLabel('Photo de profil'),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => _choisirPhoto(couverture: false),
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MboaColors.primary.withValues(alpha: 0.1),
                        ),
                        child: ClipOval(
                          child: _nouvellePhotoProfil != null
                              ? Image.file(_nouvellePhotoProfil!, fit: BoxFit.cover, width: 90, height: 90)
                              : _photoProfilUrl != null
                                  ? Image.network(_photoProfilUrl!, fit: BoxFit.cover, width: 90, height: 90,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 40, color: MboaColors.primary))
                                  : const Icon(Icons.person_rounded, size: 40, color: MboaColors.primary),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: MboaColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Nom complet'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ton nom complet',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('WhatsApp'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+237 6XX XXX XXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => Validators.telephone(v, required: false),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: MboaSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _enregistrer,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: MboaColors.text,
      ),
    );
  }
}
