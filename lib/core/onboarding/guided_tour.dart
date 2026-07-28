import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tour_step.dart';

// Moteur générique de visite guidée : un halo assombri troue un rectangle
// autour de la cible de chaque étape, avec une bulle Suivant/Précédent/
// Passer. Portage de mboa-web/src/components/onboarding/guided-tour.tsx —
// `data-tour="..."` + querySelector devient ici directement une GlobalKey
// posée par l'écran appelant (voir TourStep), plus naturel côté Flutter
// qu'un registre de chaînes global.
//
// Monté via un OverlayEntry inséré sur l'Overlay racine (au-dessus de la
// nav bar et de tout le reste) plutôt que piloté par un widget "open" —
// ça réinitialise l'étape à 0 gratuitement à chaque appel de [show], sans
// state à porter côté appelant.
class GuidedTour {
  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  static void show(BuildContext context, {required List<TourStep> steps, VoidCallback? onClose}) {
    if (_entry != null || steps.isEmpty) return;
    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    void close() {
      entry.remove();
      _entry = null;
      onClose?.call();
    }

    entry = OverlayEntry(
      builder: (_) => _GuidedTourView(steps: steps, onClose: close),
    );
    _entry = entry;
    overlayState.insert(entry);
  }
}

class _GuidedTourView extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onClose;

  const _GuidedTourView({required this.steps, required this.onClose});

  @override
  State<_GuidedTourView> createState() => _GuidedTourViewState();
}

class _GuidedTourViewState extends State<_GuidedTourView> {
  int _index = 0;
  Rect? _rect;
  bool _positioning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _positionner());
  }

  Future<void> _positionner() async {
    if (_positioning) return;
    _positioning = true;
    while (mounted) {
      if (_index >= widget.steps.length) {
        widget.onClose();
        _positioning = false;
        return;
      }
      final step = widget.steps[_index];
      final ctx = step.key.currentContext;
      final box = ctx?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) {
        // Cible absente pour ce rôle/cet état (onglet non affiché, section
        // non rendue...) : on saute l'étape plutôt que de bloquer la
        // visite sur une bulle vide.
        if (_index < widget.steps.length - 1) {
          if (mounted) setState(() => _index++);
          continue;
        } else {
          widget.onClose();
          _positioning = false;
          return;
        }
      }
      await Scrollable.ensureVisible(
        ctx!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      final finalBox = step.key.currentContext?.findRenderObject();
      if (finalBox is RenderBox && finalBox.attached && finalBox.hasSize) {
        final position = finalBox.localToGlobal(Offset.zero);
        setState(() => _rect = position & finalBox.size);
      }
      // Re-mesure de rattrapage : si la cible est plus bas dans une page
      // encore en train de charger (ex. sections Logements récents/Trouve
      // ton Mboa avant les données réseau), sa position réelle peut encore
      // bouger juste après ce premier calcul — sans ça, le halo restait
      // figé sur l'ancienne position et finissait par tomber sur un autre
      // élément de la page (repéré sur l'étape "Crée ton compte", tout en
      // bas de l'accueil visiteur).
      final capturedIndex = _index;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || _index != capturedIndex) return;
        final box = step.key.currentContext?.findRenderObject();
        if (box is RenderBox && box.attached && box.hasSize) {
          final rect = box.localToGlobal(Offset.zero) & box.size;
          if (rect != _rect) setState(() => _rect = rect);
        }
      });
      break;
    }
    _positioning = false;
  }

  void _suivant() {
    if (_index == widget.steps.length - 1) {
      widget.onClose();
      return;
    }
    setState(() {
      _index++;
      _rect = null;
    });
    _positionner();
  }

  void _precedent() {
    if (_index == 0) return;
    setState(() {
      _index--;
      _rect = null;
    });
    _positionner();
  }

  @override
  Widget build(BuildContext context) {
    final rect = _rect;
    if (rect == null) return const SizedBox.shrink();
    final step = widget.steps[_index];
    // Material(transparency) : ce Stack est monté hors du Scaffold via un
    // OverlayEntry (voir GuidedTour.show), donc sans ancêtre Material.
    // Sans ça, tout le texte de la bulle hérite du DefaultTextStyle de
    // repli de Flutter — un double soulignement coloré très visible,
    // signal de debug natif indiquant l'absence de Material, pas un style
    // volontaire de l'app.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: CustomPaint(painter: _SpotlightPainter(rect: rect)),
            ),
          ),
          _TourBulle(
            rect: rect,
            index: _index,
            total: widget.steps.length,
            title: step.title,
            body: step.body,
            onSuivant: _suivant,
            onPrecedent: _index > 0 ? _precedent : null,
            onPasser: widget.onClose,
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect rect;
  const _SpotlightPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 6.0;
    final hole = RRect.fromRectAndRadius(rect.inflate(padding), const Radius.circular(14));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(hole);
    canvas.drawPath(path, Paint()..color = const Color(0xB30F172A));
    canvas.drawRRect(
      hole,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) => oldDelegate.rect != rect;
}

class _TourBulle extends StatelessWidget {
  final Rect rect;
  final int index;
  final int total;
  final String title;
  final String body;
  final VoidCallback onSuivant;
  final VoidCallback? onPrecedent;
  final VoidCallback onPasser;

  const _TourBulle({
    required this.rect,
    required this.index,
    required this.total,
    required this.title,
    required this.body,
    required this.onSuivant,
    required this.onPasser,
    this.onPrecedent,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const margin = 12.0;
    // Hauteur de bulle estimée pour décider au-dessus/en-dessous : on ne
    // connaît pas sa taille réelle avant le layout (contrairement au web,
    // qui la mesure via useLayoutEffect), donc on positionne la bulle avec
    // `bottom` plutôt que `top` quand elle passe au-dessus de la cible —
    // elle grandit alors depuis le bord bas, sans besoin de connaître sa
    // hauteur exacte à l'avance.
    const hauteurEstimee = 200.0;
    final cardWidth = (size.width - 32).clamp(220.0, 300.0).toDouble();
    final enBas = (size.height - rect.bottom) > hauteurEstimee + margin * 2 ||
        rect.top < hauteurEstimee + margin * 2;
    final centreCible = rect.left + rect.width / 2;
    final left = (centreCible - cardWidth / 2).clamp(margin, size.width - cardWidth - margin).toDouble();
    final flecheLeft = (centreCible - left).clamp(16.0, cardWidth - 16.0).toDouble();

    final carte = Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
        border: Border.all(color: MboaColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w800, color: MboaColors.text)),
              ),
              GestureDetector(
                onTap: onPasser,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close_rounded, size: 18, color: MboaColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: MboaColors.textMuted, height: 1.4)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  total,
                  (i) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index ? MboaColors.primary : MboaColors.border,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  if (onPrecedent != null)
                    GestureDetector(
                      onTap: onPrecedent,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Text('Précédent', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: MboaColors.textMuted)),
                      ),
                    ),
                  GestureDetector(
                    onTap: onSuivant,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: MboaColors.primary, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        index == total - 1 ? 'Terminer' : 'Suivant',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (index < total - 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: GestureDetector(
                  onTap: onPasser,
                  child: const Text('Passer la visite', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: MboaColors.textMuted)),
                ),
              ),
            ),
        ],
      ),
    );

    final fleche = Positioned(
      top: enBas ? -6 : null,
      bottom: enBas ? null : -6,
      left: flecheLeft - 6,
      child: Transform.rotate(
        angle: 0.785398,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
          ),
        ),
      ),
    );

    return Positioned(
      top: enBas ? rect.bottom + margin : null,
      bottom: enBas ? null : size.height - rect.top + margin,
      left: left,
      child: Stack(clipBehavior: Clip.none, children: [carte, fleche]),
    );
  }
}
