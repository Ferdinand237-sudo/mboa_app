import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'guided_tour.dart';
import 'tour_step.dart';

// Bouton "🧭 Comment utiliser ?" posé dans le coin droit de chaque section
// hero concernée (accueil, Publier, Gestion...). Portage de
// mboa-web/src/components/onboarding/tour-button.tsx. Avec [autoOpenKey],
// la visite se lance aussi automatiquement une seule fois (mémorisé en
// SharedPreferences, équivalent mobile du localStorage web) — utilisé
// uniquement pour l'accueil visiteur non connecté, voir main_screen.dart.
class TourButton extends StatefulWidget {
  final List<TourStep> steps;
  final bool dark;
  final String? autoOpenKey;
  final String label;

  const TourButton({
    super.key,
    required this.steps,
    this.dark = false,
    this.autoOpenKey,
    this.label = 'Comment utiliser ?',
  });

  @override
  State<TourButton> createState() => _TourButtonState();
}

class _TourButtonState extends State<TourButton> {
  @override
  void initState() {
    super.initState();
    _tenterAutoOuverture();
  }

  Future<void> _tenterAutoOuverture() async {
    final autoOpenKey = widget.autoOpenKey;
    if (autoOpenKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(autoOpenKey) == true) return;
    } catch (_) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _ouvrir();
  }

  void _ouvrir() {
    if (widget.steps.isEmpty || GuidedTour.isShowing) return;
    GuidedTour.show(context, steps: widget.steps, onClose: _fermer);
  }

  Future<void> _fermer() async {
    final autoOpenKey = widget.autoOpenKey;
    if (autoOpenKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(autoOpenKey, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _ouvrir,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: widget.dark ? Colors.white.withValues(alpha: 0.15) : MboaColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.dark ? Colors.white.withValues(alpha: 0.4) : MboaColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧭', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.dark ? Colors.white : MboaColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
