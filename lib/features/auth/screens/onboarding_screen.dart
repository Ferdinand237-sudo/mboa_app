import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _slides = [
    _OnboardingData(
      emoji: '🏠',
      titre: 'Trouve ton logement',
      description:
          'Chambres, studios, appartements… Trouve le logement idéal à Sangmelima avant même ton arrivée.',
    ),
    _OnboardingData(
      emoji: '🛒',
      titre: 'Équipe ton chez-toi',
      description:
          'Lits, tables, électroménager… La marketplace Mboa te connecte aux meilleurs bons plans autour de toi.',
    ),
    _OnboardingData(
      emoji: '🗺️',
      titre: 'Explore ta ville',
      description:
          'Visualise les distances avec le campus, l\'hôpital, le marché et tous les commerces autour de ton logement.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: MboaColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Logo ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    // Logo image
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/logo/logo_mboa.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('🏘', style: TextStyle(fontSize: 50)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mboa',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Ton premier ami dans une nouvelle ville',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Slides ──────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _SlideWidget(data: _slides[index]);
                  },
                ),
              ),

              // ── Indicateur de page ───────────────────────────
              SmoothPageIndicator(
                controller: _pageController,
                count: _slides.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: Colors.white,
                  dotColor: Colors.white.withValues(alpha: 0.4),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                ),
              ),

              // ── Boutons ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  children: [
                    // Se connecter
                    SizedBox(
                      width: double.infinity,
                      height: MboaSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: MboaColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MboaSizes.radiusLg,
                            ),
                          ),
                          elevation: 0,
                          textStyle: MboaTextStyles.button,
                        ),
                        child: const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // S'inscrire
                    SizedBox(
                      width: double.infinity,
                      height: MboaSizes.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () => context.push(AppRoutes.register),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MboaSizes.radiusLg,
                            ),
                          ),
                          textStyle: MboaTextStyles.button,
                        ),
                        child: const Text('S\'inscrire'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Visiter sans compte
                    TextButton(
                      onPressed: () => context.go(AppRoutes.main),
                      child: Text(
                        'Visiter sans compte →',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
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

// widget - slide
class _SlideWidget extends StatelessWidget {
  final _OnboardingData data;
  const _SlideWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 44),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.titre,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Modèle de données slide ───────────────────────────────────
class _OnboardingData {
  final String emoji;
  final String titre;
  final String description;

  _OnboardingData({
    required this.emoji,
    required this.titre,
    required this.description,
  });
}