import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DemandeVendeurScreen extends StatefulWidget {
  const DemandeVendeurScreen({super.key});

  @override
  State<DemandeVendeurScreen> createState() => _DemandeVendeurScreenState();
}

class _DemandeVendeurScreenState extends State<DemandeVendeurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedRole = -1;
  bool _isLoading = false;

  final List<_RoleOption> _roles = [
    _RoleOption(
      icon: '🏠',
      titre: 'Propriétaire immobilier',
      description: 'Je mets des logements en location',
    ),
    _RoleOption(
      icon: '🛒',
      titre: 'Commerçant / Boutique',
      description: 'Je vends des produits depuis ma boutique',
    ),
    _RoleOption(
      icon: '📦',
      titre: 'Vendeur indépendant',
      description: 'Je vends des articles sur la marketplace',
    ),
    _RoleOption(
      icon: '🏠🛒',
      titre: 'Propriétaire + Commerçant',
      description: 'Je loue des logements ET je vends des produits',
    ),
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _envoyerDemande() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre type d\'activité'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;
    try {
      await supabase.from('demandes_compte').insert({
        'nom': _nomController.text.trim(),
        'email': _emailController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'type_activite': _roles[_selectedRole].titre,
        'description': _descriptionController.text.trim(),
      });
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi. Réessayez.'),
            backgroundColor: MboaColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

    void _showSuccessDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MboaSizes.radiusXl),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MboaColors.verified.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('✅', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Demande envoyée !',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MboaColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Un administrateur Mboa va étudier votre demande et vous contacter sur WhatsApp ou email sous 24h avec vos identifiants de connexion.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: MboaColors.textMuted,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: MboaSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.main);
                  },
                  child: const Text('Visiter l\'application'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MboaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF92400E), MboaColors.secondary],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Compte Pro 🏪',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remplis ce formulaire et notre équipe te contacte sous 24h',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Bannière info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MboaColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(MboaSizes.radiusMd),
                          border: Border.all(
                            color: MboaColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ℹ️', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Un administrateur Mboa créera votre compte sur mesure et vous enverra vos identifiants de connexion sous 24h.',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: MboaColors.primary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nom complet
                      _buildLabel('Nom complet'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nomController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Jean-Paul Mbassi',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 20),

                      // Email
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'ton@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // WhatsApp
                      _buildLabel('Numéro WhatsApp'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: '+237 6XX XXX XXX',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 24),

                      // Type d'activité
                      _buildLabel('Je veux publier des annonces'),
                      const SizedBox(height: 12),
                      ...List.generate(_roles.length, (index) {
                        final role = _roles[index];
                        final isSelected = _selectedRole == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MboaColors.secondary.withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(MboaSizes.radiusMd),
                              border: Border.all(
                                color: isSelected
                                    ? MboaColors.secondary
                                    : MboaColors.border,
                                width: isSelected ? 2 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  role.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.titre,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? MboaColors.secondary
                                              : MboaColors.text,
                                        ),
                                      ),
                                      Text(
                                        role.description,
                                        style: MboaTextStyles.bodySm,
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? MboaColors.secondary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? MboaColors.secondary
                                          : MboaColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),

                      // Description
                      _buildLabel('Décrivez votre activité'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText:
                              'Ex: Je suis propriétaire de 3 chambres à Sangmelima et je vends aussi des meubles...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (v.length < 20) {
                            return 'Minimum 20 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Bouton envoyer
                      SizedBox(
                        width: double.infinity,
                        height: MboaSizes.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _envoyerDemande,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MboaColors.secondary,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Envoyer la demande'),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Visiter sans compte
                      Center(
                        child: TextButton(
                          onPressed: () => context.go(AppRoutes.main),
                          child: Text(
                            'Visiter l\'application sans compte →',
                            style: MboaTextStyles.bodySm.copyWith(
                              color: MboaColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
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

class _RoleOption {
  final String icon;
  final String titre;
  final String description;

  _RoleOption({
    required this.icon,
    required this.titre,
    required this.description,
  });
}