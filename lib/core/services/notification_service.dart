import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifications push (Firebase Cloud Messaging) : jeton de l'appareil,
/// permissions, canal Android et affichage local quand l'app est au
/// premier plan (FCM n'affiche pas automatiquement de notification
/// système dans ce cas, contrairement à l'arrière-plan/app fermée).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _canalId = 'mboa_activite';
  static const _canalNom = 'Messages et activité Mboa';

  bool _initialise = false;

  Future<void> initialiser() async {
    if (_initialise) return;
    _initialise = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const canalAndroid = AndroidNotificationChannel(
      _canalId,
      _canalNom,
      description: 'Nouveaux messages, annonces et alertes Mboa',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canalAndroid);

    FirebaseMessaging.onMessage.listen(_afficherNotificationLocale);
    _messaging.onTokenRefresh.listen((_) => enregistrerToken());

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        enregistrerToken();
      }
    });

    if (Supabase.instance.client.auth.currentUser != null) {
      await enregistrerToken();
    }
  }

  /// Récupère le jeton FCM de l'appareil et l'enregistre sur le profil
  /// de l'utilisateur connecté, pour que le serveur puisse lui envoyer
  /// des notifications ciblées.
  Future<void> enregistrerToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token}).eq('id', userId);
    } catch (_) {}
  }

  Future<void> _afficherNotificationLocale(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNom,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
