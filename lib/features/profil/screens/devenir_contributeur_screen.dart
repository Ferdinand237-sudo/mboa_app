import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class DevenirContributeurScreen extends StatefulWidget {
  final bool dejaVendeur;
  const DevenirContributeurScreen({super.key, this.dejaVendeur = false});

  @override
  State<DevenirContributeurScreen> createState() => _DevenirContributeurScreenState();
}

class _DevenirContributeurScreenState extends State<DevenirContributeurScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedRole = -1;
  bool _isLoading = false;
  bool _envoye = false;

  final List<_RoleOption> _roles = [
    _RoleOption(icon: '🏠', titre: 'Propriétaire immobilier', description: 'Je mets des logements en location'),
    _RoleOption(icon: '🛒', titre: 'Commerçant / Boutique', description: 'Je vends des produits depuis ma boutique'),
    _RoleOption(icon: '📦', titre: 'Vendeur indépendant', description: 'Je vends des articles sur la marketplace'),
  ];

  @override
  void dispose() {
    _whatsappController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _envoyerDemande() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionne ton type d\'activité'), backgroundColor: MboaColors.danger),
      );
      return;
    }
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final profil = await _supabase.from('users').select('nom').eq('id', user.id).single();
      await _supabase.from('demandes_compte').insert({
        'user_id': user.id,
        'nom': profil['nom'],
        'email': user.email,
        'whatsapp': _whatsappController.text.trim(),
        'type_activite': _roles[_selectedRole].titre,
        'description': _descriptionController.text.trim(),
        'statut': 'en-attente',
      });
      if (mounted) setState(() => _envoye = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi. Réessayez.'), backgroundColor: MboaColors.danger),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: MboaColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.dejaVendeur ? 'Étendre mes activités' : 'Devenir contributeur',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: MboaColors.text),
        ),
      ),
      body: SafeArea(
        child: _envoye ? _buildConfirmation() : _buildFormulaire(),
      ),
    );
  }

  Widget _buildFormulaire() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.dejaVendeur
                  ? 'Ajoute une nouvelle activité à ton compte existant : ton mot de passe ne change pas, l\'administrateur ajoute simplement les permissions demandées.'
                  : 'Deviens propriétaire ou vendeur sur Mboa : ton compte étudiant sera mis à niveau par l\'administrateur, sans nouveau mot de passe.',
              style: MboaTextStyles.body.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('Je suis...',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: MboaColors.text)),
            const SizedBox(height: 12),
            ...List.generate(_roles.length, (index) {
              final role = _roles[index];
              final isSelected = _selectedRole == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedRole = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? MboaColors.primary.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                    border: Border.all(color: isSelected ? MboaColors.primary : MboaColors.border, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Text(role.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(role.titre,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? MboaColors.primary : MboaColors.text)),
                            Text(role.description, style: MboaTextStyles.caption),
                          ],
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check_circle_rounded, color: MboaColors.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text('WhatsApp',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: MboaColors.text)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+237 6XX XXX XXX', prefixIcon: Icon(Icons.phone_outlined)),
              validator: Validators.telephone,
            ),
            const SizedBox(height: 16),
            const Text('Décris ton activité',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: MboaColors.text)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Ex : je loue 3 chambres près du campus IUT'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: MboaSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _envoyerDemande,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Envoyer la demande'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            const Text('Demande envoyée !',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: MboaColors.text)),
            const SizedBox(height: 10),
            Text(
              'L\'administrateur va examiner ta demande. Ton compte sera mis à jour automatiquement dès validation, avec les mêmes identifiants de connexion.',
              style: MboaTextStyles.body.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: MboaSizes.buttonHeight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour au profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  final String icon;
  final String titre;
  final String description;
  _RoleOption({required this.icon, required this.titre, required this.description});
}
