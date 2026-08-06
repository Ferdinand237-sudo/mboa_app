import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/ville_service.dart';
import '../../../core/models/ville_model.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _selectedRole = -1;
  bool _isLoading = false;
  List<VilleModel> _villes = [];
  String? _selectedVille;

  final List<_RoleOption> _roles = [
    _RoleOption(
      icon: '🏠',
      titre: 'Propriétaire immobilier',
      description: 'Je mets des logements en location',
      sousRoles: ['proprietaire'],
    ),
    _RoleOption(
      icon: '🛒',
      titre: 'Commerçant / Boutique',
      description: 'Je vends des produits depuis ma boutique',
      sousRoles: ['commercant'],
    ),
    _RoleOption(
      icon: '📦',
      titre: 'Vendeur indépendant',
      description: 'Je vends des articles sur la marketplace',
      sousRoles: ['vendeur_independant'],
    ),
    _RoleOption(
      icon: '🏠🛒',
      titre: 'Propriétaire + Commerçant',
      description: 'Je loue des logements ET je vends des produits',
      sousRoles: ['proprietaire', 'commercant'],
    ),
    _RoleOption(
      icon: '🏨',
      titre: 'Hôtel / Motel / Auberge',
      description: 'Je propose des chambres ou logements à réserver',
      sousRoles: ['hotelier'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _chargerVilles();
  }

  Future<void> _chargerVilles() async {
    await VilleService.instance.init();
    if (!mounted) return;
    setState(() {
      _villes = VilleService.instance.villesActives;
      if (_villes.isNotEmpty) _selectedVille = _villes.first.nom;
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    if (_selectedVille == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre ville'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: MboaColors.danger,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'nom': _nomController.text.trim(),
          'telephone': _whatsappController.text.trim(),
          'role': 'visiteur',
        },
      );
      final userId = response.user?.id;
      if (userId == null) throw Exception('Compte non créé');

      // Sert de repli à la publication (GPS prioritaire pour un logement,
      // aucun GPS pour un article) — voir publier_screen.dart.
      await supabase.from('users').update({'ville': _selectedVille}).eq('id', userId);

      await supabase.from('demandes_compte').insert({
        'user_id': userId,
        'nom': _nomController.text.trim(),
        'email': _emailController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'type_activite': _roles[_selectedRole].titre,
        'sous_roles_demandees': _roles[_selectedRole].sousRoles,
        'ville': _selectedVille,
        'description': _descriptionController.text.trim(),
      });
      if (mounted) _showSuccessDialog();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: MboaColors.danger),
        );
      }
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
                'Compte créé, demande envoyée !',
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
                'Tu peux déjà te connecter avec ton email et ton mot de passe. Un administrateur Mboa va étudier ta demande Pro et l\'activer sous 24h.',
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
                    context.go(AppRoutes.login);
                  },
                  child: const Text('Me connecter'),
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
                      'Crée ton compte, notre équipe valide ta demande sous 24h',
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
                                'Ton compte est créé immédiatement avec le mot de passe que tu choisis ici. Un administrateur Mboa valide ensuite ta demande Pro, généralement sous 24h.',
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
                        validator: Validators.email,
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
                        validator: Validators.telephone,
                      ),
                      const SizedBox(height: 20),

                      // Mot de passe
                      _buildLabel('Mot de passe'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: Validators.motDePasse,
                      ),
                      const SizedBox(height: 20),

                      // Confirmer le mot de passe
                      _buildLabel('Confirmer le mot de passe'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: Validators.motDePasse,
                      ),
                      const SizedBox(height: 20),

                      // Ville
                      _buildLabel('Ta ville'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedVille,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        hint: const Text('Chargement…'),
                        items: _villes
                            .map((v) => DropdownMenuItem(value: v.nom, child: Text(v.nom)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedVille = v),
                        validator: (v) => v == null ? 'Requis' : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tes annonces apparaîtront par défaut dans cette ville.',
                        style: MboaTextStyles.caption,
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
  final List<String> sousRoles;

  _RoleOption({
    required this.icon,
    required this.titre,
    required this.description,
    required this.sousRoles,
  });
}