import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Image réseau avec cache disque (affichage instantané si déjà vue, y compris hors ligne)
/// et fallback visuel cohérent avec le design Mboa en cas d'erreur ou de chargement.
class MboaCachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final String emojiPlaceholder;

  const MboaCachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.emojiPlaceholder = '📷',
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => Container(
        color: MboaColors.border.withValues(alpha: 0.3),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: MboaColors.primary),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        decoration: const BoxDecoration(gradient: MboaColors.cardGradient),
        child: Center(child: Text(emojiPlaceholder, style: const TextStyle(fontSize: 26))),
      ),
    );
  }
}
