import 'package:flutter/material.dart';

/// Visionneuse plein écran réutilisable : zoom (pincer), défilement
/// horizontal entre les photos, fermeture en glissant vers le bas.
class PhotoViewerFullscreen extends StatefulWidget {
  final List photos;
  final int indexDepart;
  final String placeholder;

  const PhotoViewerFullscreen({
    super.key,
    required this.photos,
    required this.indexDepart,
    this.placeholder = '🖼',
  });

  static void ouvrir(BuildContext context, List photos, int indexDepart, {String placeholder = '🖼'}) {
    if (photos.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            PhotoViewerFullscreen(photos: photos, indexDepart: indexDepart, placeholder: placeholder),
      ),
    );
  }

  @override
  State<PhotoViewerFullscreen> createState() => _PhotoViewerFullscreenState();
}

class _PhotoViewerFullscreenState extends State<PhotoViewerFullscreen> {
  late final PageController _controller;
  double _dragOffset = 0;
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.indexDepart);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
          _opacity = (1 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset.abs() > 120) {
          Navigator.pop(context);
        } else {
          setState(() {
            _dragOffset = 0;
            _opacity = 1;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: _opacity),
        body: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.photos.length,
                itemBuilder: (context, index) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Text(widget.placeholder, style: const TextStyle(fontSize: 100)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
