import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _selectedType = -1; // 0 = étudiant, 1 = commerçant

  final List<_AccountType> _types = [
    _AccountType(
      icon: '🎓',
      titre: 'Étudiant / Visiteur',
      description: 'Je cherche un logement ou des bons plans',
      couleur: MboaColors.primary,
    ),
    _AccountType(
      icon: '🏪',
      titre: 'Commerçant / Propriétaire',
      description: 'Je veux publier des annonces sur Mboa',
      couleur: MboaColors.secondary,
    ),
  ];

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
                  gradient: MboaColors.primaryGradient,
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
                          color: Colors.white.withOpacity(0.2),
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
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/logo/logo_mboa.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('🏘', style: TextStyle(fontSize: 22)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mboa',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choisis ton type de compte pour commencer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Contenu ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Je suis...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MboaColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sélectionne le profil qui te correspond',
                      style: MboaTextStyles.muted,
                    ),
                    const SizedBox(height: 20),

                    // Cartes de sélection
                    ...List.generate(_types.length, (index) {
                      final type = _types[index];
                      final isSelected = _selectedType == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? type.couleur.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                            border: Border.all(
                              color: isSelected ? type.couleur : MboaColors.border,
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: type.couleur.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    type.icon,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type.titre,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? type.couleur
                                            : MboaColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      type.description,
                                      style: MboaTextStyles.bodySm,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? type.couleur
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? type.couleur
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

                    const SizedBox(height: 8),

                    // Bouton continuer
                    SizedBox(
                      width: double.infinity,
                      height: MboaSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _selectedType == -1
                            ? null
                            : () {
                                if (_selectedType == 0) {
                                  context.push(AppRoutes.registerEtudiant);
                                } else {
                                  context.push(AppRoutes.demandeVendeur);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: MboaColors.border,
                          disabledForegroundColor: MboaColors.textMuted,
                        ),
                        child: const Text('Continuer'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Séparateur
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou', style: MboaTextStyles.muted),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google
                    SizedBox(
                      width: double.infinity,
                      height: MboaSizes.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'G',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: MboaColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Continuer avec Google',
                              style: MboaTextStyles.button.copyWith(
                                color: MboaColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Lien connexion
                    Center(
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.login),
                        child: RichText(
                          text: const TextSpan(
                            style: MboaTextStyles.body,
                            children: [
                              TextSpan(
                                text: 'Déjà un compte ? ',
                                style: TextStyle(color: MboaColors.textMuted),
                              ),
                              TextSpan(
                                text: 'Se connecter',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  color: MboaColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountType {
  final String icon;
  final String titre;
  final String description;
  final Color couleur;

  _AccountType({
    required this.icon,
    required this.titre,
    required this.description,
    required this.couleur,
  });
}