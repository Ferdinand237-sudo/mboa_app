import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class EditProfilScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilScreen({super.key, required this.user});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _telephoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user['nom'] ?? '');
    _telephoneController =
        TextEditingController(text: widget.user['telephone'] ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await _supabase.from('users').update({
        'nom': _nomController.text.trim(),
        'telephone': _telephoneController.text.trim(),
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
              const Text(
                'Nom complet',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MboaColors.text,
                ),
              ),
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
              const Text(
                'WhatsApp',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MboaColors.text,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+237 6XX XXX XXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
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
}
