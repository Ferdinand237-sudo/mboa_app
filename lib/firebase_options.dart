// Généré manuellement à partir de android/app/google-services.json
// (projet Firebase "mboa-39325"). Android uniquement pour l'instant —
// à régénérer avec `flutterfire configure` si iOS est ajouté un jour.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) return android;
    throw UnsupportedError(
      'DefaultFirebaseOptions n\'a été configuré que pour Android.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCT54H5LQUASZNJhhfOgjTIqjIiPwvDYhY',
    appId: '1:1074104199846:android:706f84561c33198b8be267',
    messagingSenderId: '1074104199846',
    projectId: 'mboa-39325',
    storageBucket: 'mboa-39325.firebasestorage.app',
  );
}
