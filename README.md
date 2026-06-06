# Mboa App

**Mboa** est une application Flutter conçue pour accompagner les nouveaux arrivants dans une ville avec:
- recherche et partage de logements,
- marketplace pour l’équipement de la maison,
- messagerie et support local,
- profils et gestion de compte.

## 📌 Présentation

Mboa est structuré autour de plusieurs fonctionnalités clés:
- Authentification et onboarding
- Navigation principale avec onglets
- Profil utilisateur et paramètres
- Recherche de logements
- Marketplace d’articles
- Chat et notifications
- Intégration Supabase pour backend et auth

## 🧱 Architecture du projet

Le code est organisé en modules dans `lib/`:
- `app/` : point d’entrée, routeur, configuration globale
- `core/` : constantes, thèmes, modèles, services et utilitaires
- `features/` : fonctionnalités métier (auth, home, logement, market, chat, profil, admin, map)
- `widgets/` : composants réutilisables

## ⚙️ Dépendances principales

- `flutter_riverpod` + `riverpod_annotation`
- `supabase_flutter`
- `go_router`
- `google_maps_flutter`
- `geolocator`, `geocoding`
- `image_picker`, `flutter_image_compress`
- `cached_network_image`, `flutter_svg`, `shimmer`
- `shared_preferences`, `connectivity_plus`

## 🚀 Installation

1. Cloner le dépôt:
   ```bash
   git clone <url-du-repo>
   cd mboa_app
   ```

2. Installer les dépendances:
   ```bash
   flutter pub get
   ```

3. Configurer Supabase:
   - Les valeurs actuelles sont dans `lib/core/constants/app_constants.dart`
   - Remplacez `supabaseUrl` et `supabaseAnonKey` par vos propres clés Supabase

## 🧪 Exécuter l’application

- Sur émulateur / appareil Android:
  ```bash
  flutter run
  ```

- Build APK de release:
  ```bash
  flutter build apk --release
  ```

- Build iOS (sur macOS):
  ```bash
  flutter build ios --release
  ```

## 🧩 Structure des routes

Le routeur est défini dans `lib/app/router.dart`.
Routes principales:
- `/` : onboarding
- `/login` : connexion
- `/register` : inscription
- `/demande-vendeur` : demande vendeur
- `/main` : écran principal de l’application
- `/register/etudiant` : inscription étudiant

## 🔐 Configuration Supabase

Les clés Supabase sont actuellement codées dans:
- `lib/core/constants/app_constants.dart`

Pour une meilleure sécurité, il est recommandé de les déplacer vers des variables d’environnement ou un fichier de configuration sécurisé.

## 🧠 Tests

Un test de base existe dans `test/widget_test.dart`.

Pour lancer les tests:
```bash
flutter test
```

## ✨ Recommendations

- Ajouter des tests unitaires et widget supplémentaires
- Externaliser la configuration Supabase hors du code source
- Ajouter une localisation si besoin
- Factoriser la logique Supabase dans des services/providers dédiés

## 📝 Notes

L’application utilise une orientation portrait uniquement et un thème personnalisé via `lib/core/theme/app_theme.dart`.

---

Merci de contribuer à Mboa ! N’hésite pas à compléter ce README avec des captures d’écran et des captures de flux métier lorsque l’application évolue.
samples, guidance on mobile development, and a full API reference.
