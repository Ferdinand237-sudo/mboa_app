import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'app/router.dart';

// Doit rester une fonction top-level : appelée par le système dans un
// isolate séparé quand l'app est fermée et qu'une notification arrive.
@pragma('vm:entry-point')
Future<void> _gererMessageArrierePlan(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Notifications push (Firebase) ─────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_gererMessageArrierePlan);

  // ── Orientation portrait uniquement ──────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Couleur de la barre de statut ─────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Initialisation Supabase ───────────────────────────────
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // ── Notifications : permissions, canal Android, jeton ─────
  await NotificationService.instance.initialiser();
  NotificationService.instance.onNotificationTap = ouvrirDepuisNotificationPush;

  runApp(
    const ProviderScope(
      child: MboaApp(),
    ),
  );

  // App lancée depuis zéro par un tap sur la notification (pas juste
  // ramenée au premier plan) : le Navigator de GoRouter doit exister avant
  // de pouvoir y empiler un écran, d'où l'attente au-delà du délai fixe du
  // splash (2s, splash_screen.dart) avant de traiter getInitialMessage.
  Future.delayed(const Duration(seconds: 3), () {
    NotificationService.instance.gererLancementDepuisNotification();
  });
}