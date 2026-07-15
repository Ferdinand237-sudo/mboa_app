# MBOA — Guide Complet pour Claude Code

## Présentation du projet
Mboa (mot signifiant "la maison, le foyer" en langue Duala/Beti du Cameroun)
est une application mobile Flutter + Supabase de recherche de logement
et marketplace pour étudiants à Sangmelima, Cameroun.

Slogan : "Ton premier ami dans une nouvelle ville"

## Problème résolu
Chaque année, les nouveaux étudiants admis à Sangmelima arrivent dans une ville
inconnue sans savoir où trouver un logement. Mboa leur permet de :
- Trouver un logement AVANT d'arriver dans la ville
- Voir les commerces et équipements autour du logement
- Acheter/vendre des équipements entre étudiants
- Contacter directement les propriétaires et vendeurs

## Les 4 types d'utilisateurs

### 1. Visiteur Non Inscrit
- Navigation : Home | Logement | Market | Chat | Profil
- Voit un nombre limité d'annonces (max 4)
- Ne peut PAS voir le détail d'une annonce
- Ne peut PAS utiliser le chat
- Profil vide avec invitation à s'inscrire

### 2. Visiteur Inscrit (étudiant)
- Navigation : Home | Logement | Market | Chat | Profil
- Accès complet à toutes les annonces
- Peut voir le détail des annonces
- Peut chatter avec vendeurs/propriétaires
- Peut laisser des avis et notes
- Peut signaler des annonces frauduleuses

### 3. Vendeur / Commerçant / Propriétaire
- Navigation : Home | Mes Annonces | Publier | Chat | Profil
- Compte créé UNIQUEMENT par l'administrateur via Edge Function
- Peut publier des annonces logement ET/OU articles
- Un seul compte peut avoir plusieurs rôles
- Sous-rôles : proprietaire | commercant | vendeur_independant

### 4. Administrateur
- Interface dédiée : Dashboard | Utilisateurs | Annonces | Signalements
- Crée les comptes vendeurs via Edge Function Supabase
- Certifie les vendeurs (badge Vérifié)
- Booste les annonces
- Modère les signalements et bannit les comptes

## Stack technique
- Flutter 3.24 (Dart) — iOS et Android
- Supabase (Auth + PostgreSQL + Storage + Realtime)
- OpenStreetMap via flutter_map + latlong2
- GoRouter pour la navigation
- Riverpod pour la gestion d'état

## Supabase (NOUVEAU PROJET)
- URL : https://vodmsndqahmxdsqpayrd.supabase.co
- Anon key : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvZG1zbmRxYWhteGRzcXBheXJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwNjAzNTQsImV4cCI6MjA5OTYzNjM1NH0.6htojTsGc1EfSZygNrFq4I7tvv8k8vmhnATdofVEM6I
- Project ref : vodmsndqahmxdsqpayrd

## Structure du projet
lib/
  app/
    app.dart                        MboaApp MaterialApp.router
    router.dart                     GoRouter + AppRoutes + redirection par rôle
  core/
    constants/
      app_constants.dart            URLs Supabase, constantes métier
    models/
      user_model.dart
      logement_model.dart
      article_model.dart
    services/
      auth_service.dart
      logement_service.dart
      article_service.dart
      chat_service.dart
      auth_provider.dart
    theme/
      app_theme.dart                MboaColors, MboaSizes, MboaTextStyles, AppTheme
  features/
    auth/screens/
      onboarding_screen.dart        FAIT
      login_screen.dart             FAIT
      register_screen.dart          FAIT
      register_etudiant_screen.dart FAIT
      demande_vendeur_screen.dart   FAIT
    home/screens/
      main_screen.dart              FAIT navigation adaptée par rôle
      home_screen.dart              FAIT données Supabase réelles
    logement/screens/
      logement_screen.dart          FAIT filtres + données réelles
      logement_detail_screen.dart   FAIT galerie proximité avis chat
      publier_screen.dart           FAIT upload photos + Supabase
    market/screens/
      market_screen.dart            FAIT filtres + données réelles
      article_detail_screen.dart    FAIT détail + chat vendeur
    chat/screens/
      chat_screen.dart              FAIT temps réel Supabase
                                    ATTENTION ConversationScreen est PUBLIC pas privé
    profil/screens/
      profil_screen.dart            FAIT données réelles
      profil_vendeur_screen.dart    FAIT profil public
    map/screens/
      map_screen.dart               A CREER
    admin/screens/
      admin_screen.dart             FAIT dashboard stats
      admin_users_screen.dart       FAIT certifier bannir créer vendeur
      admin_annonces_screen.dart    FAIT boost suspendre supprimer
      admin_signalements_screen.dart FAIT traiter rejeter
      admin_demandes_screen.dart    FAIT approuver rejeter demandes
assets/
  logo/logo_mboa.png               Logo de l'application
  fonts/                            Poppins Regular Medium SemiBold Bold ExtraBold
supabase/functions/
  create-vendor/                    Edge Function déployée pour créer comptes vendeurs

## Tables Supabase toutes créées
- users : id nom email role sous_roles verified boosted actif note_globale nb_avis nom_commerce description_commerce photo_commerce emplacement_commerce lat lng date_inscription
- logements : id titre description type prix surface photos equipements regles disponible_le statut adresse_approx quartier ville lat lng proprietaire_id boosted vues signalements note_globale nb_avis date_publication
- articles : id titre description categorie etat prix negociable photos vendeur_id statut lat lng boosted vues signalements date_publication
- conversations : id participants annonce_id annonce_type dernier_message dernier_message_date non_lu
- messages : id conversation_id expediteur_id texte lu date_envoi
- avis : id auteur_id cible_id annonce_id note commentaire valide
- signalements : id signaleur_id cible_type cible_id raison statut
- demandes_compte : id nom email whatsapp type_activite description statut

## Fonctionnalités DEJA implementees

### Authentification
- Onboarding 3 slides avec logo Mboa
- Inscription étudiant email + mot de passe via Supabase Auth
- Demande compte commerçant vers table demandes_compte
- Connexion réelle Supabase
- Déconnexion avec confirmation
- Redirection automatique par rôle au login
- Admin vers interface admin, Vendeur vers nav vendeur, Visiteur vers nav visiteur

### Navigation
- Visiteur : Home | Logement | Market | Chat | Profil
- Vendeur  : Home | Mes Annonces | Publier | Chat | Profil
- Admin    : Dashboard | Utilisateurs | Annonces | Signalements

### Home
- Salutation personnalisée avec prénom depuis Supabase
- Barre de recherche
- Catégories rapides Logement Market Carte
- Logements récents depuis Supabase
- Articles Market depuis Supabase
- Bannière Trouve ton Mboa
- Pull to refresh

### Logement
- Liste avec filtres type prix curseur
- Recherche textuelle temps réel
- Tri boostés puis vérifiés puis mieux notés puis récents
- Détail complet galerie photos equipements proximité
- Points de proximité campus hôpital marché commissariat pharmacie
- Profil propriétaire avec badge vérifié
- Avis et notes depuis Supabase
- Signalement annonce
- Bouton Envoyer un message crée conversation Supabase

### Market
- Grille 2 colonnes avec filtres catégorie état
- Recherche textuelle
- Détail article avec galerie
- Profil vendeur public
- Bouton Contacter le vendeur crée conversation Supabase

### Chat
- Liste des conversations depuis Supabase
- Messages temps réel via Supabase Realtime
- Statut lu non lu
- Badge nombre messages non lus
- ConversationScreen PUBLIC utilisé depuis logement_detail et article_detail

### Profil
- Données réelles depuis Supabase
- Initiales générées automatiquement
- Badge vérifié
- Date d inscription
- Type de compte affiché
- Déconnexion avec confirmation

### Publication Vendeurs
- Formulaire logement avec upload photos réelles image_picker
- Formulaire article avec upload photos réelles
- Validation minimum photos 3 pour logement 1 pour article
- Upload vers Supabase Storage
- Insertion en base de données

### Admin
- Dashboard statistiques users logements articles signalements
- Alertes actions requises
- Gestion utilisateurs certifier bannir réactiver
- Traitement demandes Pro via Edge Function create-vendor
- Boost suspension suppression annonces
- Modération signalements avec filtres

## Fonctionnalités A IMPLEMENTER

### PRIORITE 1 Carte OpenStreetMap
Fichier à créer : lib/features/map/screens/map_screen.dart
- Packages disponibles : flutter_map 7.0.2 et latlong2 déjà dans pubspec.yaml
- Centre : Sangmelima lat 2.9333 lng 11.9833 zoom 14.5
- Tuiles : https://tile.openstreetmap.org/{z}/{x}/{y}.png
- Marqueurs logements avec prix depuis Supabase filtrés par lat not null
- Marqueurs POI fixes :
  Campus IUT lat 2.9350 lng 11.9820
  Hôpital District lat 2.9280 lng 11.9800
  Grand Marché lat 2.9320 lng 11.9860
  Commissariat lat 2.9340 lng 11.9840
  Pharmacie lat 2.9310 lng 11.9830
- Clic sur marqueur logement affiche fiche en bas de l écran
- Bouton itinéraire ouvre OpenStreetMap externe via url_launcher
- Boutons zoom plus zoom moins recentrer
- Légende Logement Campus Hôpital Marché
- Filtres Tous Chambre Studio Appartement POI
- Accès depuis home_screen.dart bouton Carte dans section Explorer
- Accès depuis logement_detail_screen.dart bouton Voir sur la carte

### PRIORITE 2 GPS dans publication
Fichier : lib/features/logement/screens/publier_screen.dart
- Ajouter bouton Ma position avec geolocator
- Sauvegarder lat et lng dans Supabase avec l annonce
- Mini aperçu position

### PRIORITE 3 Système de Favoris
Créer table favoris dans Supabase :
  create table public.favoris (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.users(id) on delete cascade,
    logement_id uuid references public.logements(id) on delete cascade,
    created_at timestamp with time zone default now(),
    unique(user_id, logement_id)
  );
  alter table public.favoris enable row level security;
  create policy "User gère ses favoris" on public.favoris for all using (auth.uid() = user_id);
- Bouton cœur fonctionnel dans logement_detail_screen.dart
- Écran Mes favoris dans profil_screen.dart
- Compteur favoris dans profil mis à jour

### PRIORITE 4 Avis fonctionnels
- Formulaire laisser un avis note 1 à 5 plus commentaire
- Déclenché après une conversation
- Calcul automatique note_globale du vendeur
- Mise à jour nb_avis

### PRIORITE 5 Limite visiteur non inscrit
- Dans logement_screen.dart afficher max 4 annonces si non connecté
- Dans market_screen.dart afficher max 4 articles si non connecté
- Bannière Connectez-vous pour voir plus en bas de liste

### PRIORITE 6 Splash screen et icône
- Splash screen avec logo assets/logo/logo_mboa.png
- Fond couleur #2D6A4F
- Icône application depuis logo_mboa.png

### PRIORITE 7 Build APK release
- flutter build apk --release
- Vérifier permissions Android dans AndroidManifest.xml

## Conventions de code OBLIGATOIRES

### Couleurs toujours MboaColors
MboaColors.primary       #2D6A4F vert forêt
MboaColors.primaryDark   #1B4332
MboaColors.primaryLight  #52B788
MboaColors.secondary     #F4A261 orange
MboaColors.accent        #E76F51 terracotta
MboaColors.background    #F8F6F0
MboaColors.text          #1A1A2E
MboaColors.textMuted     #6B7280
MboaColors.border        #E5E7EB
MboaColors.boost         #F59E0B
MboaColors.verified      #10B981
MboaColors.danger        #EF4444

### Tailles toujours MboaSizes
MboaSizes.radiusLg       16px coins arrondis standard
MboaSizes.radiusXl       24px grands coins
MboaSizes.buttonHeight   52px hauteur boutons
MboaSizes.md             16px padding standard

### Textes toujours MboaTextStyles
MboaTextStyles.h2 h3 h4
MboaTextStyles.body bodySm
MboaTextStyles.muted caption
MboaTextStyles.button

### Règle critique opacity
JAMAIS color.withOpacity(0.5)
TOUJOURS color.withValues(alpha: 0.5)

### Règle critique Supabase
TOUJOURS entourer les appels Supabase de try catch

### Police
TOUJOURS fontFamily: 'Poppins'

### Pattern Supabase avec jointure
Construire la query avec les filtres puis awaiter séparément
Ne pas chaîner eq après select avec jointure

### Navigation
context.go(AppRoutes.main) pour nav principale
Navigator.push pour écrans détail

## Points d attention importants

1. ConversationScreen est PUBLIC dans chat_screen.dart pas privé
   utilisé depuis logement_detail_screen et article_detail_screen

2. Edge Function create-vendor doit être redéployée sur le nouveau projet
   supabase functions deploy create-vendor --project-ref vodmsndqahmxdsqpayrd

3. Realtime doit être activé sur messages et conversations
   alter publication supabase_realtime add table public.messages;
   alter publication supabase_realtime add table public.conversations;

4. flutter_map version 7 API différente des versions précédentes
   MapOptions avec initialCenter et initialZoom pas center et zoom
   TileLayer avec urlTemplate pas templateUrl
   MarkerLayer avec markers pas MarkerLayerOptions

5. Permissions Android nécessaires dans AndroidManifest.xml
   android.permission.INTERNET
   android.permission.ACCESS_FINE_LOCATION
   android.permission.ACCESS_COARSE_LOCATION
   android.permission.READ_EXTERNAL_STORAGE
   android.permission.CAMERA

6. Compte Admin à créer sur le nouveau Supabase
   Créer user dans Authentication puis
   UPDATE users SET role='admin', verified=true WHERE email='ton_email'

## Ordre de travail recommandé
1. Lire ce fichier en entier
2. flutter pub get
3. flutter run pour vérifier que l app compile
4. Créer map_screen.dart
5. Intégrer carte dans home_screen.dart
6. Ajouter GPS dans publier_screen.dart
7. Implémenter les favoris
8. Implémenter la limite visiteur
9. Splash screen et icône
10. Build APK release
11. Tester chaque fonctionnalité avant de passer à la suivante