import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_theme.dart';

/// Bandeau global affiché en surimpression quand l'appareil perd la connexion internet.
/// Envelopper l'écran racine (MainScreen) avec ce widget pour une couverture app-wide.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _horsLigne = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _verifierEtat();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final horsLigne = results.every((r) => r == ConnectivityResult.none);
      if (mounted) setState(() => _horsLigne = horsLigne);
    });
  }

  Future<void> _verifierEtat() async {
    final results = await Connectivity().checkConnectivity();
    final horsLigne = results.every((r) => r == ConnectivityResult.none);
    if (mounted) setState(() => _horsLigne = horsLigne);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_horsLigne)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: MboaColors.danger,
                  borderRadius: BorderRadius.circular(MboaSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pas de connexion internet — certaines données affichées peuvent être obsolètes',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
