# Historique complet du projet Mboa

Document généré à partir de l'historique Git réel du dépôt `mboa_app`
(30 Pull Requests à ce jour, du 6 juin au 27 juillet 2026) et des échanges
de cette collaboration. Sert de référence complète : ce qui a été construit,
modifié, corrigé, et l'état actuel du projet.

---

## 1. Vue d'ensemble

**Mboa** ("la maison, le foyer" en Duala/Beti) est une application de
recherche de logement et marketplace pour les étudiants arrivant à
Sangmélima, Cameroun — slogan *"Ton premier ami dans une nouvelle ville"*.

Le projet existe en **deux versions connectées à la même base Supabase**
(mêmes tables, mêmes règles métier, mêmes comptes) :

- **Application mobile** — Flutter (iOS/Android), développée en premier.
- **Site web** — Next.js 16 + Supabase, reproduction fidèle de l'app
  mobile écran par écran, avec quelques ajouts propres au web (visite
  guidée, etc.) explicitement demandés en cours de route.

Quatre types de comptes : **visiteur non inscrit**, **visiteur inscrit**
(étudiant), **vendeur/propriétaire/commerçant**, **administrateur**. Un
cinquième rôle, **ambassadeur**, a été ajouté en cours de projet pour les
vérifications terrain. Depuis le 27 juillet, admin et ambassadeur sont
devenus des **privilèges superposables** à un compte existant plutôt que
des rôles exclusifs (détail en section 4.9).

---

## 2. Chronologie en deux grandes phases

### Phase 1 — Application mobile Flutter (6 juin → 18 juillet 2026)

Construction de l'app mobile de zéro jusqu'à une version complète et
sécurisée : authentification, logements, marketplace, chat, profils,
publication, dashboard admin, carte, notifications push, modération IA,
vérification terrain par des ambassadeurs, temps réel.

### Phase 2 — Version Web Next.js (21 juillet → 27 juillet 2026)

Port complet de l'app Flutter vers le web (Next.js 16 + Supabase),
écran par écran, jusqu'à couverture totale, puis itérations de design,
corrections de bugs, et fonctionnalités additionnelles propres au web
(visite guidée interactive, refonte du système de rôles admin/ambassadeur).

### Phase 3 — Rattrapage mobile (27 juillet 2026)

Deux fonctionnalités nées côté web pendant la Phase 2 (rôles
admin/ambassadeur superposables, visite guidée) n'avaient pas
d'équivalent sur l'app Flutter — migration des deux vers mobile pour
revenir à une parité complète entre les deux versions (détail en
section 4.10).

---

## 3. Phase 1 — Détail des fonctionnalités mobiles

*(Reconstitué à partir des messages de commit ; cette phase n'a pas fait
l'objet de Pull Requests — commits directs sur la branche principale.)*

### Fondations
- Mise en place initiale du projet Flutter (auth, structure, thème
  `MboaColors`/`MboaSizes`/`MboaTextStyles`).
- Refonte de la Home page : recherche instantanée, grille responsive,
  géolocalisation.
- Refonte du Market (cartes carrées, favoris articles, avis conditionnels)
  et du détail logement (circuit de signalement admin).
- Chat amélioré : titre des annonces affiché, filtres, lien direct vers
  l'annonce.
- Profil public contributeur avec données réelles.
- Publication restreinte par rôle + écran Gestion (Phase 5 du plan initial).

### Carte, favoris, avis
- Carte OpenStreetMap (`flutter_map`), favoris, position GPS, avis, écran
  splash.
- Recherche géographique par lieu (rayon autour d'un point).
- Regroupement des marqueurs proches en clusters
  (`flutter_map_marker_cluster`) avec spiderfy au tap.
- Filtre par note minimum sur Logement et Market (basée sur la note du
  propriétaire/vendeur, pas de l'annonce elle-même).
- Verrouillage de "Trouve ton Mboa" et de la carte pour les visiteurs non
  connectés.

### Authentification
- Connexion/inscription Google (OAuth Supabase).
- Réinitialisation de mot de passe.
- Correctifs : icône de l'app, "se souvenir de moi", messages d'erreur
  d'inscription plus clairs.

### Sécurité et qualité
- CRUD complet (édition logement/article depuis Gestion).
- Validation stricte : email, téléphone camerounais, mot de passe, sur
  tous les formulaires.
- Durcissement RLS Supabase : anti auto-élévation de privilèges, policies
  admin, colonnes sensibles protégées par trigger, Storage scopé par
  dossier utilisateur.
- Sécurisation de l'Edge Function `create-vendor` (vérification admin
  obligatoire côté serveur, pas seulement côté client).
- Mode hors ligne : bandeau de connectivité global + cache disque des
  photos sur les écrans à fort trafic.

### Notifications push (Firebase Cloud Messaging)
- Projet Firebase lié, permissions, canal Android, jeton FCM enregistré
  automatiquement sur le profil à chaque connexion.
- Edge Function `send-notification` : notifie le destinataire d'une
  conversation à chaque nouveau message.
- Edge Function `notifier-nouvelle-annonce` : notifie les utilisateurs
  dont une alerte de recherche correspond à une nouvelle annonce.
- Déclenchement via triggers Postgres (`pg_net`), sans dépendre d'une
  configuration manuelle côté dashboard.

### Modération IA des annonces
- Chaque nouvelle annonce est analysée automatiquement après publication :
  hachage perceptuel (dHash) des photos pour détecter la réutilisation
  frauduleuse entre vendeurs, classification de contenu via Gemini
  (jamais basée sur le prix).
- Statut `statut_moderation` (`publie` / `a_verifier` / `bloque`)
  conditionnant la visibilité publique, avec repli systématique vers
  `a_verifier` en cas d'échec plutôt qu'une décision aveugle.
- Tables `moderation_ia` et `image_hashes`, Edge Function
  `moderate-annonce` déclenchée par trigger.

### Vérification terrain (rôle ambassadeur)
- Un propriétaire ne peut publier un logement qu'après une visite terrain
  validée par l'administration.
- Nouveau rôle **ambassadeur** (créé exclusivement par l'admin), chargé
  des visites : conformité du bien, justificatif, géolocalisation, photo
  d'attestation stockée dans un bucket privé dont l'accès est journalisé
  (`attestations_acces_log`) via une Edge Function dédiée
  (`get-attestation-url`).
- Écrans ambassadeur : dashboard, liste des propriétaires assignés
  (avec brouillon local hors-ligne et synchronisation automatique au
  retour de connexion), formulaire de visite.
- `admin_verifications_screen` : assignation, validation/rejet des
  visites. `admin_users_screen` : statut de vérification affiché,
  création de compte ambassadeur.

### Temps réel
- Extension du pattern déjà utilisé par le chat (canal Supabase par
  table, fermé au `dispose`) aux tableaux de bord admin/ambassadeur.
- `RealtimeTableMixin` réutilisable (`subscribeToTable()` /
  `disposeRealtimeChannels()`).
- Correction nécessaire au passage : `verifications_terrain` et
  `signalements` n'étaient pas dans la publication `supabase_realtime`
  (seules `messages` et `conversations` l'étaient) — sans cet ajout,
  aucun événement n'aurait jamais été reçu sur ces tables.

### Corrections diverses (mobile)
- Défauts de wrapping des boutons d'action sur 7 écrans, puis dans
  Gestion spécifiquement.
- Titre article sur 2 lignes dans Home, navigation Logement du vendeur.
- Libellés de statistiques invisibles sur le profil vendeur.
- Points de proximité génériques remplacés par les vrais lieux les plus
  proches.
- Timeout et message clair pour la récupération GPS.
- Rafraîchissement automatique des onglets au changement de navigation.
- Affichage des notes et nettoyage du recalcul client des avis.
- Blocage indéfini à l'upload de photos corrigé, publication accélérée.
- Crash silencieux à la création d'un ambassadeur corrigé.

### Vérification sur device réel et correctifs complémentaires (22 juillet)
Session de test manuel sur un appareil Android réel (APK installé via
`adb`, comptes de `COMPTES_TEST.md`), en parallèle du démarrage de la
Phase 2 web. A révélé un bug architectural resté invisible jusque-là :
- `conversations.non_lu` n'était initialisé qu'à la création d'une
  conversation et jamais mis à jour ensuite — ni par un trigger serveur,
  ni par le code client à l'envoi d'un message. Vérifié en insérant un
  message de test directement en base : le compteur restait à 0 quel que
  soit le nombre réel de messages non lus. Bug silencieux (aucune
  erreur, juste un badge qui ne s'affichait jamais) présent depuis
  l'origine de la fonctionnalité chat, sur mobile comme sur web. Corrigé
  par un trigger d'incrémentation à l'insertion d'un message et une
  fonction RPC de remise à zéro à la lecture
  (`supabase/migrations/20260722120000_non_lu_messages.sql`).
- Boutons retour/favori flottants du détail logement plaqués en position
  fixe au-dessus de la galerie photo : restaient visibles par-dessus le
  texte une fois la galerie scrollée hors de vue. Masqués au-delà du
  seuil de la galerie via un `ScrollController`.
- Bouton "Appeler" tronqué en "Appe..." sur écran étroit (détail
  logement, détail article, profil vendeur) : l'ellipsis empêchait le
  débordement de layout mais pas la troncature du mot lui-même ;
  padding resserré pour lui redonner la place nécessaire.

Création à cette occasion de `GUIDE_SESSIONS.md`, catalogue des pièges
techniques récurrents du projet (types Postgrest, RLS silencieuse,
colonnes jamais alimentées, timeouts réseau manquants, race conditions
sur des listes rechargées...), à consulter avant de coder et à enrichir
quand un nouveau piège générique apparaît.

---

## 4. Phase 2 — Détail des fonctionnalités Web (mboa-web)

### 4.1 — Démarrage et périmètre initial (PR #1)
Choix de **Next.js 16** plutôt que Flutter Web pour un vrai rendu
SSR/SEO sur les annonces. Premier périmètre : accueil, liste + détail
logements et marketplace (filtres, recherche, limite 4 annonces pour les
visiteurs non connectés), connexion/inscription étudiant, profil. Design
system porté depuis `MboaColors`/`MboaSizes` vers des tokens Tailwind,
police Poppins.

Puis reconstruction complète pour coller au détail exact de l'app
mobile :
- **Accueil** : header dégradé, Explorer, Logements récents, "Trouve ton
  Mboa" (géolocalisation navigateur + RPC `logements_proches`, verrouillé
  si non connecté), Bons plans Market, Contributeurs Mboa.
- **Logements / Marketplace** : filtres live, tuiles/cartes fidèles au
  mobile, bannière de verrouillage visiteur.
- **Fiches détail** : galerie, favoris, points de proximité, fiche
  propriétaire/vendeur, avis, signalement, barre de contact fixe.
- **Authentification** : sélecteur de type de compte (étudiant/
  commerçant), formulaire de demande de compte pro, "se souvenir de moi",
  connexion Google, mot de passe oublié/réinitialisation.
- **Profil** : header dégradé + stats, favoris (retrait optimiste),
  édition avec upload photo, alertes de recherche, devenir contributeur,
  avis à modérer, notifications.
- **Parcours vendeur** : Publier/Gestion/modifier logement/article,
  upload photos vers Supabase Storage, position GPS via
  `navigator.geolocation`, attente de la modération IA via un canal
  Realtime dédié.
- **Chat** : liste de conversations, filtres, badge non-lus, conversation
  temps réel, marquage lu automatique, formulaire d'avis.
- **Carte interactive** (`react-leaflet`) avec clustering, comme mobile.
- **Interface admin complète** (`/admin`) : dashboard, utilisateurs
  (certifier/bannir/créer ambassadeur), annonces (boost/suspendre/
  supprimer), signalements (traiter/rejeter/suspendre avec message au
  propriétaire), demandes Pro (Edge Function `create-vendor`),
  vérifications terrain.
- **Interface ambassadeur** (`/ambassadeur`) : dashboard, liste assignée
  (Realtime filtré), formulaire de visite terrain.

Fin du portage : **couverture complète de toutes les pages de l'app**
côté web (PR #1, un seul PR massif suivi d'itérations).

### 4.2 — Corrections post-lancement (PR #2 à #9)
- Autorisation de `images.unsplash.com` pour les photos de démo
  (bloqué par `next/image` par défaut).
- Documentation du déploiement Vercel et des incidents rencontrés.
- Logo Mboa ajouté, footer redesigné, onglet Chat dans le header, fix du
  badge non-lu.
- Navigation chat lente corrigée, badge non-lu au retour de page corrigé,
  footer masqué sur conversation/carte.
- Note vendeur précisée partout ("Note globale du vendeur"), vrai badge
  vert pour les comptes certifiés (au lieu d'un badge générique), bouton
  Message du profil vendeur branché sur le vrai chat.
- Admin connecté redirigé automatiquement vers `/admin` (miroir du
  comportement mobile — **comportement retiré depuis**, voir 4.9).

### 4.3 — Responsive et finitions visuelles (PR #10 à #22)
- Overflow mobile du formulaire logement corrigé ; onglets admin/
  ambassadeur déplacés dans le header plutôt qu'une barre séparée.
- Affichage grand écran amélioré : cartes contributeurs adaptatives,
  conteneurs élargis, écart gauche/droite sur grand écran.
- Bannières hero arrondies partout, zone vide du chat corrigée sur grand
  écran, onglet actif visuellement distinct.
- Application installable (PWA).
- **Espace de conversation agrandi** pour bien couvrir le cadre.
- **Images cliquables en plein écran**, fermables en glissant vers le bas
  ou via une croix (`image-lightbox.tsx`).
- **Système de notifications in-app** (cloche avec badge, liste
  déroulante) — miroir du système mobile.
- **Vraie pastille de certification** (badge à encoches SVG) remplaçant
  l'ancien "✅" texte, sur 7 écrans.
- Bug "25 logements affichés vs 34 sur la carte" corrigé : un plafond de
  budget par défaut invisible filtrait silencieusement la liste.
- Icône de filtre remplacée par l'icône "tune" (comme mobile), au lieu
  d'un engrenage qui suggérait des paramètres généraux.

### 4.4 — Authentification web (PR #12 à #15)
- Lien de confirmation email de l'inscription corrigé (`redirectTo`
  manquant).
- Route `/auth/callback` ajoutée — sans elle, la connexion Google ne
  fonctionnait jamais côté web.
- Validation du mot de passe assouplie à 6 caractères minimum, sans
  contrainte de composition (web **et** mobile, alignés).
- Filet de sécurité si le code OAuth Google atterrit hors de
  `/auth/callback` (Supabase retombant sur le Site URL du dashboard).

### 4.5 — Notifications admin et modération (PR #23)
- Notifications in-app pour l'administrateur : nouvelle demande de
  compte, nouveau signalement — même mécanisme que les notifications de
  message.
- Synchronisation modération IA / signalements : un signalement généré
  par la détection IA, une fois traité, n'apparaît plus comme signalement
  distinct dans l'onglet Signalements alors qu'il l'a déjà été.
- Filtre des utilisateurs par rôle dans l'admin, pour faciliter la
  recherche à mesure que la base grandit.

### 4.6 — Assistant Mboa : chat support automatique (PR #24)
Conversation support automatique appelée **Assistant Mboa**, créée pour
chaque nouveau compte, liée à l'ensemble des administrateurs :
- Un message envoyé par l'utilisateur est visible par tous les
  administrateurs jusqu'à ce que l'un d'eux réponde.
- Le premier administrateur qui répond est assigné (claim atomique via
  `UPDATE ... WHERE assigned_admin_id IS NULL`) : la conversation
  disparaît ensuite du chat des autres administrateurs et tous les
  messages suivants de cet utilisateur lui sont dirigés.
- Migration SQL : colonnes `is_support`/`assigned_admin_id` sur
  `conversations`, policies RLS d'exception pour les admins, trigger de
  création automatique à l'inscription, backfill pour les comptes
  existants.
- Edge Function `send-notification` étendue pour router les push vers
  l'admin assigné ou diffuser à tous les admins tant que personne n'a
  répondu.

### 4.7 — Réassignation des photos de démonstration
Analyse des annonces existantes en base pour repérer des photos
incohérentes avec le titre/la description (le hasard des seeds de démo
avait mélangé les catégories) : suppression de 3 annonces de test,
réassignation des photos par catégorie sur les annonces restantes,
correction d'une vraie erreur de catégorisation ("Livres scolaires"
classé en "Literie"). Travail effectué directement en base (pas de PR
de code — changement de données).

### 4.8 — Visite guidée interactive (onboarding tour) (PR #25, #26, #27)
Système de prise en main façon "product tour" :
- Bulle qui pointe successivement vers les éléments clés de l'interface
  (halo + flèche), avec **Suivant / Précédent / Passer**.
- **Accueil visiteur non inscrit** : logo, recherche, Logement, Market,
  Carte, Chat, inscription — lancement automatique une seule fois par
  navigateur, en plus d'un bouton pour la relancer.
- Étendu ensuite à **tous les rôles** avec un bouton *"🧭 Comment
  utiliser ?"* dans le coin du hero, déclenché au clic uniquement :
  accueil vendeur (Mes annonces/Publier/Messages/profil), accueil
  visiteur inscrit (+ notifications/profil), page **Publier** (photos,
  position GPS, envoi), page **Gestion** (onglets, statut d'une annonce,
  actions Modifier/Suspendre/Supprimer).
- Moteur générique (`GuidedTour`) qui saute automatiquement une étape
  dont la cible n'existe pas pour le rôle/les permissions courants (ex.
  compte à permission unique → pas d'onglets), au lieu de bloquer sur une
  bulle vide ; ouvre/referme le menu hamburger mobile à la volée quand
  l'onglet visé y est caché.
- **Bug corrigé (PR #27)** : sur mobile, le halo ne capturait pas bien
  les boutons de géolocalisation et Publier, tout en bas de longs
  formulaires. Cause : délai fixe de 220 ms après le défilement,
  insuffisant sur les longs scrolls mobile. Remplacé par une attente de
  stabilisation réelle de la position (mesure en boucle jusqu'à ce
  qu'elle ne bouge plus), plus un recalcul sur `scroll` en plus du
  `resize`.

### 4.9 — Rôles admin/ambassadeur superposables (PR #28)
Refonte du modèle de rôles : auparavant `role` était exclusif (visiteur
**ou** vendeur **ou** admin **ou** ambassadeur), avec redirection forcée
vers `/admin` sur chaque page pour un compte admin.

- Un administrateur peut désormais **nommer administrateur** ou
  **ambassadeur** n'importe quel utilisateur existant, en un clic depuis
  la liste des utilisateurs — en plus de la création de compte neuf déjà
  en place pour les ambassadeurs.
- La personne promue **garde l'expérience de son compte initial**
  (visiteur ou vendeur) et gagne en plus un lien **"Administration"** /
  **"Espace ambassadeur"** dans son profil, avec un **"← Mon compte"**
  pour revenir à tout moment — au lieu d'être redirigée de force.
- Base de données : colonnes `users.est_admin` / `users.est_ambassadeur`
  (booléens superposés à `role`, qui redevient l'identité de base
  visiteur/vendeur). `is_admin()` et toutes les policies RLS qui
  testaient `role = 'admin'` directement couvrent maintenant aussi
  `est_admin` ; idem pour les triggers de notification et les Edge
  Functions `create-vendor`/`create-ambassadeur`/`send-notification`.
  Backfill des 3 comptes admin/ambassadeur réels existants sans perte de
  privilège.
- Web : navigation du header devenue sensible au chemin courant (tabs
  admin/ambassadeur uniquement sous `/admin` ou `/ambassadeur`),
  suppression de la redirection forcée après connexion et sur chaque
  requête, badges multiples dans la liste des utilisateurs.

---

## 5. Phase 3 — Rattrapage mobile : rôles superposables + visite guidée (PR #30)

Après la refonte des rôles côté web (4.9), un problème concret est
apparu : la migration base de données (`role → est_admin/est_ambassadeur`)
avait déjà été appliquée aux comptes réels, mais le code mobile testait
encore `role == 'admin'` littéralement (`UserModel.isAdmin`,
`MainScreen`) — les comptes admin/ambassadeur réels étaient donc
**verrouillés hors de leur propre espace sur mobile** depuis cette
migration. Corrigé en portant le modèle complet, pas seulement le
correctif minimal :

- **Rôles superposables (mobile)** : `MainScreen` ne redirige plus de
  force ; `AmbassadeurScreen` devient un espace autonome au même titre
  qu'`AdminScreen` (route `/ambassadeur`), accessible depuis
  "Espaces privilégiés" dans le profil, avec un retour explicite vers
  la navigation de base ("← Mon compte", ajouté aussi à `AdminScreen`).
  `admin_users_screen.dart` gagne les bascules **Nommer admin** /
  **Nommer ambassadeur** et l'affichage de badges multiples.
  `UserModel` gagne `estAdmin`/`estAmbassadeur` (getters, `fromMap`,
  `toMap`, `copyWith`).
- **Visite guidée (mobile)** : portage du moteur `GuidedTour` web en
  Dart (`lib/core/onboarding/`) — même logique de halo + bulle
  Suivant/Précédent/Passer, mais positionnée via `GlobalKey` Flutter
  plutôt que des sélecteurs `data-tour` (pas d'équivalent DOM en
  Flutter). Une étape dont la cible n'est pas montée pour le rôle/état
  courant est sautée automatiquement, comme sur le web. Bouton
  *"🧭 Comment utiliser ?"* sur l'accueil (visiteur/étudiant/vendeur),
  Publier et Gestion ; lancement automatique unique pour le visiteur
  non connecté sur l'accueil (`SharedPreferences`, équivalent mobile du
  `localStorage` web).
- **Contrainte particulière** : aucun SDK Flutter n'était disponible
  dans l'environnement de développement au moment d'écrire ce code —
  tout a été relu manuellement (pas de vérification par compilateur)
  jusqu'à ce que `flutter analyze` soit installé après coup, qui n'a
  révélé aucune erreur sur le nouveau code. À cette occasion, nettoyage
  de code mort préexistant signalé par l'outil (3 champs jamais lus,
  un dossier d'assets déclaré mais inexistant).

---

## 5bis. Phase 4 — Support multi-villes : Sangmelima, Kribi, Ébolowa (27-28 juillet 2026)

Mboa ne couvrait qu'une seule ville depuis le début du projet, codée en
dur des deux côtés (centre de carte, détection GPS, libellés). Ferdinand
a demandé l'extension à Kribi et Ébolowa, avec sélection manuelle
possible à tout moment depuis l'accueil, détection automatique par GPS
par défaut, et repli vers la liste des villes couvertes quand la
position détectée n'en fait pas partie (ou que la ville détectée n'a pas
encore d'annonces). Décision actée : liste des villes gérable par un
admin via une table Supabase plutôt qu'une liste figée dans le code, pour
pouvoir en ajouter une 4ᵉ sans republier l'app. Implémenté mobile
d'abord (device réel à tester), web à porter ensuite.

- **Migration `20260727000000_multi_ville.sql`** : nouvelle table
  `villes` (nom, lat/lng, rayon de couverture, actif, ordre d'affichage)
  seedée avec les 3 villes, lecture publique / écriture `is_admin()`.
  Colonne `ville` ajoutée à `lieux_publics` (n'en avait aucune) + backfill
  à Sangmelima. Backfill défensif de `logements.ville`/`articles.ville`
  (toujours du texte libre écrit à la main côté client jusqu'ici, jamais
  une vraie donnée choisie par l'utilisateur).
- **Bug préexistant corrigé au passage** : les 4 policies RLS de
  `lieux_publics` utilisaient encore `role = 'admin'` en dur, jamais
  migrées vers `is_admin()` lors de la refonte des rôles superposables
  (§4.9) — un admin `est_admin`-only ne pouvait donc pas gérer les lieux
  publics. Corrigé dans la même migration puisqu'elle touchait déjà
  cette table.
- **`VilleService`** (mobile, `lib/core/services/ville_service.dart`) :
  singleton à accès direct plutôt qu'un provider Riverpod — constat fait
  en analysant le code existant qu'aucun écran mobile n'utilise Riverpod
  aujourd'hui (seuls le router et des providers d'auth inutilisés),
  introduire du `ConsumerState` partout aurait été disproportionné pour
  un état aussi simple. Détecte la ville active la plus proche de la
  position GPS parmi celles couvertes (au lieu d'un seul centre codé en
  dur comme avant), persiste le choix en `SharedPreferences`, expose un
  helper de "ville la plus proche d'une position" réutilisé par la carte
  et par Publier.
- **Écrans mobiles adaptés** : Home (sélecteur de ville dans le header,
  logements récents/bons plans Market et Trouve ton Mboa filtrés/
  recentrés sur la ville choisie, proposition automatique de la liste des
  villes si la ville détectée n'a pas d'annonces), Logement/Market
  (filtre ville sur les listes complètes, même garde-fou anti-race-
  condition que le filtre prix/note du 22/07), Carte (centre dynamique,
  filtrage par ville, tag automatique de la ville la plus proche sur
  "Ajouter un lieu ici"), Publier (ville du logement dérivée de sa
  position GPS captée, ville de l'article dérivée du contexte ville
  courant du vendeur puisqu'aucune position n'est captée pour un
  article), nouvel écran admin "Villes couvertes" (ajout/édition/
  activation).
- **Migration appliquée le 28/07**, avec un aller-retour : premier essai
  échoué sur `column "ville" does not exist` — `articles` n'avait en
  réalité jamais eu de colonne `ville` en base (contrairement à
  `logements`), le code qui la lisait (`article_detail_screen.dart`) l'a
  donc toujours reçue absente/`null` en silence depuis le début du
  projet. `alter table articles add column if not exists ville` ajouté,
  et le reste du script rendu rejouable sans risque (`drop policy if
  exists` systématique avant chaque `create policy`) pour pouvoir le
  recoller tel quel après un échec partiel.
- **Reste à faire** : portage web (cookie + Server Action pour partager
  la ville sélectionnée entre les Server Components, la persistance
  client seule ne suffisant pas côté web contrairement au mobile).

---

## 5ter. Phase 4 (suite) — Polish visite guidée et navigation admin (28 juillet 2026)

Après la mise en service du multi-villes, deux séries de retours de
Ferdinand testés et corrigés le même jour.

### Visite guidée (`lib/core/onboarding/`)
- **Double soulignement coloré sur tout le texte de la bulle**, repéré
  sur device réel. Cause : la bulle est montée via un `OverlayEntry` sur
  l'`Overlay` racine (`GuidedTour.show`), donc en dehors du `Scaffold` —
  sans ancêtre `Material`, Flutter affiche tout `Text` avec son style de
  repli de debug (double soulignement coloré très visible), pas un style
  volontaire de l'app. Corrigé en enveloppant le contenu de
  `_GuidedTourView` dans `Material(type: MaterialType.transparency)`.
- **Bouton "🧭 Comment utiliser ?"** avec libellé texte faisait déborder
  "Bienvenue sur Mboa" et poussait la cloche de notifications hors de
  l'écran sur téléphone étroit (constaté sur capture device réel).
  `TourButton` gagne un paramètre `iconOnly`, activé uniquement sur
  l'accueil (Publier/Gestion gardent le libellé, où la place ne manque
  pas). Nouvelle 1ʳᵉ étape de la visite ("🧭 Ton guide, toujours là") qui
  présente ce bouton comme le moyen de relancer la visite plus tard,
  pour compenser la perte du texte explicite.
- **Étape "📍 Trouve ton Mboa" ajoutée** (visiteur et étudiant) : section
  jusque-là absente de la visite alors qu'elle est présentée comme l'une
  des fonctionnalités les plus puissantes de l'app.
- **Dernière étape "Crée ton compte" mal ciblée** ("ne prend pas le
  bouton, juste les éléments du bas" — retour Ferdinand). Cause : le
  rectangle du halo n'est calculé qu'une fois au moment d'atteindre
  l'étape ; si le contenu au-dessus (Logements récents, chargé en
  réseau) finit sa mise en page juste après, la position réelle du
  bouton a bougé et le halo reste figé sur l'ancienne position. Ajout
  d'une re-mesure de rattrapage 400 ms après le calcul initial.
- Vérifié pas à pas sur device réel (captures à chaque étape) après
  correction, y compris la dernière étape.

### Navigation admin (`admin_screen.dart`)
- Barre du bas réduite de 7 éléments (6 onglets + "Mon compte") à
  **5 onglets** : Dashboard, Utilisateurs, Annonces, Signalements,
  Vérifs. Signalements et Vérifs gardés en priorité car ce sont les deux
  seuls onglets à badge temps réel (urgence) ; Demandes et Mon compte
  déplacés dans un **menu hamburger** (icône ☰ à côté du bouton
  déconnexion sur le Dashboard, `Drawer` standard Flutter) — le
  Dashboard a déjà son alerte "🚨 Actions requises" pour rattraper les
  demandes en attente.
- **Comportement clarifié en testant** (pas un bug) : se connecter avec
  un compte admin n'a jamais redirigé automatiquement vers le dashboard
  admin — depuis la refonte des rôles superposables (§4.9), il faut
  passer par Profil → "Administration". Le dashboard admin n'est donc
  jamais le point d'entrée direct après connexion, y compris pour un
  compte purement admin.
- Vérifié sur device réel : barre à 5 onglets, ouverture du menu,
  "Demandes" et "Mon compte" fonctionnels.

### Reste en suspens
- **Assistant Mboa côté mobile** (parité avec le web, §4.6) : recherche
  faite (backend déjà en place — table `conversations` avec
  `is_support`/`assigned_admin_id`, trigger de création automatique,
  RLS, comptage non-lu déjà adapté — portage 100% client mobile,
  aucune nouvelle migration nécessaire), implémentation pas encore
  commencée.

---

## 5quater. Phase 4 (suite) — Jeu de données de test Kribi/Ébolowa (28 juillet 2026)

La couverture multi-villes (§5bis) rendait Kribi et Ébolowa sélectionnables
mais vides : aucune annonce, aucun lieu public, aucun compte vendeur.
Ferdinand a demandé un jeu de données réaliste pour les deux villes —
vrais quartiers, vrais lieux publics géocodés (pas de coordonnées
inventées), comptes vendeurs de test avec mots de passe consignés, photos
cohérentes par type d'annonce, et tout pré-validé pour contourner le
circuit de vérification qui bloque normalement la publication d'un
nouveau compte propriétaire.

- **Migration `20260728000000_seed_kribi_ebolowa.sql`** : crée 4 comptes
  vendeurs (`auth.users` + `auth.identities` insérés directement en SQL —
  aucune clé service_role disponible dans cet environnement pour passer
  par l'API Admin/l'Edge Function `create-vendor`, donc reproduction
  manuelle du même résultat : mot de passe hashé via `pgcrypto`,
  `email_confirmed_at` renseigné, `raw_user_meta_data` avec `role:
  'vendeur'`), 42 logements (21 chacun pour les 2 comptes propriétaires,
  répartis également 7 Chambre / 7 Studio / 7 Appartement par ville),
  52 articles (26 chacun pour les 2 comptes commerçants) et 14 lieux
  publics. Volume monté en trois temps à la demande de Ferdinand avant
  collage dans le SQL Editor (3→6→21 logements et 3→6→26 articles par
  ville — le dernier palier réutilise les 5 quartiers déjà géocodés par
  ville plutôt que d'en inventer de nouveaux, une même ville ayant
  légitimement plusieurs annonces dans le même quartier). Testée de bout
  en bout avant livraison sur un Postgres local (schéma reconstitué à
  partir du code de l'app, faute d'accès à la vraie base) : exécution
  propre, ré-exécution sans doublon confirmée après chaque ajout.
- **Comptes créés** (mots de passe à changer si ces comptes servent au-delà
  des tests) :

  | Ville | Nom | Email | Mot de passe | Rôle |
  |---|---|---|---|---|
  | Kribi | Émilienne Mbarga | emilienne.mbarga@mboa-test.cm | `MboaKribi2026!` | propriétaire |
  | Kribi | Serge Nkoulou | serge.nkoulou@mboa-test.cm | `MboaKribi2026!` | commerçant / vendeur indépendant |
  | Ébolowa | Odette Ayissi | odette.ayissi@mboa-test.cm | `MboaEbolowa2026!` | propriétaire |
  | Ébolowa | Bruno Essomba | bruno.essomba@mboa-test.cm | `MboaEbolowa2026!` | commerçant / vendeur indépendant |

- **Contournement du blocage de publication** : un nouveau compte
  `proprietaire` a normalement `compte_actif_publication = false` tant
  qu'un ambassadeur n'a pas validé une vérification terrain (§Partie 2,
  `verifications_terrain`). Les 4 comptes sont créés directement avec
  `compte_actif_publication = true` et `verified = true`, sans ligne
  `verifications_terrain` factice associée (aurait pollué le tableau de
  bord admin avec de fausses visites "validées" sans ambassadeur
  réel) — décision de ne pas simuler cette partie du flux.
- **Triggers désactivés le temps de l'insertion** (`alter table ...
  disable trigger user` / `enable trigger user`, dans une transaction
  `begin`/`commit` pour tout annuler proprement en cas d'échec) : sans
  ça, le trigger de modération IA aurait déclenché un appel HTTP inutile
  vers l'Edge Function `moderate-annonce` pour chaque annonce, et le
  trigger de protection des colonnes de confiance (`verified`,
  `compte_actif_publication`, `statut_moderation`...) les aurait
  silencieusement réinitialisées — ces triggers vérifient `is_admin()`/
  `auth.role() = 'service_role'`, tous deux vides dans une session brute
  de l'éditeur SQL Supabase.
- **Quartiers et lieux publics** : noms et coordonnées obtenus par
  recherche web puis géocodage OpenStreetMap Nominatim (pas de
  coordonnées inventées), une ville par ligne :
  - Kribi : Bella, Afan Mabé, Ngoyé, Dombé, Mpango pour les logements
    (Bella utilisé deux fois, sur une chambre et un appartement) ;
    Hôpital de District de Kribi, Marché Central, École Maternelle
    Publique, Cathédrale Saint-Joseph, Pharmacie de l'Atlantique, Brigade
    de Gendarmerie de Kribi 1, Aéroport de Kribi comme lieux publics.
    Exception documentée : le quartier Bella (confirmé réel via
    recherche web) n'a pas de résultat Nominatim direct — coordonnées
    approximées près du centre côtier déjà géocodé (cathédrale/hôpital),
    pas une vraie mesure.
  - Ébolowa : New-Bell, Elat, Ngalan I, Mekalat, Biyeyem pour les
    logements (Elat utilisé deux fois, sur un studio et un appartement) ;
    Hôpital Régional, Marché Central, Lycée d'Ébolowa, Cathédrale
    Sainte-Anne-et-Joachim, Pharmacie du Bercail, Commissariat Central,
    Université d'Ébolowa comme lieux publics.
- **Photos** : URLs Unsplash stables (`images.unsplash.com/photo-<id>`),
  chacune vérifiée accessible (`curl` HTTP 200) avant intégration,
  choisies par cohérence avec le type d'annonce (chambre/studio/
  appartement pour les logements ; literie/mobilier/électronique/
  cuisine/scolaire/divers pour les articles). Pas d'upload réel dans le
  Storage Supabase — l'app affiche les photos via `Image.network`/
  `NetworkImage` simple, donc une URL externe stable fonctionne à
  l'identique d'une image hébergée sur Supabase.
- **`COMPTES_TEST.md`** : fichier référencé à plusieurs endroits de cet
  historique (§3, §9) mais introuvable dans le dépôt (ni suivi ni
  untracked, aucune trace dans `git log`) — les mots de passe ci-dessus
  sont donc consignés uniquement ici pour l'instant.
- **Non vérifié sur device réel** : cette migration n'a pas encore été
  collée dans le SQL Editor Supabase par Ferdinand au moment de la
  rédaction (pas d'accès direct à la base de production depuis cet
  environnement) — à confirmer après exécution, notamment que les
  nouvelles annonces apparaissent bien dans Logement/Market/Carte une
  fois Kribi/Ébolowa sélectionnées.

---

## 5quinquies. Portage mobile de l'Assistant Mboa (29 juillet 2026)

Ferdinand a constaté que l'Assistant Mboa (chat support, déjà en
production côté web depuis §4.6) ne s'affichait pas dans le chat mobile,
et voulait que tout le monde — étudiants comme admin — puisse en
bénéficier sur l'app comme sur le site. Le backend existait déjà en
entier (migration `20260726000000_assistant_mboa.sql` : conversation
support `is_support=true` créée automatiquement à l'inscription de tout
compte non-admin, `assigned_admin_id` figé sur le premier admin qui
répond, RLS et compteur de non-lus déjà adaptés) — portage 100% client
côté mobile, miroir de `mboa-web/src/components/chat/{chat-list,
conversation-view}.tsx` et `src/lib/data/chat.ts`.

- **`chat_screen.dart` (`ChatScreen`)** : détecte `estAdmin` (role='admin'
  OU privilège superposé `est_admin`, pas juste role) au chargement, puis
  branche vers deux chargements distincts — `_chargerConversationsMembre`
  (conversations classiques + toujours sa propre conversation Assistant
  Mboa, visible même sans message échangé, comme point d'entrée
  permanent) ou `_chargerConversationsAdmin` (file d'attente : uniquement
  les conversations support non assignées ou assignées à cet admin,
  jamais les conversations classiques d'un autre utilisateur). Badge 🤖
  sur l'avatar à la place de 💬 pour les distinguer dans la liste.
- **`ConversationScreen`** : nouveaux paramètres `isSupport`,
  `estAdminViewer`, `assignedAdminId`. Sous-titre d'en-tête contextuel
  pour un admin sur une conversation support ("🆕 Non assigné" / "Pris en
  charge" / "✅ Assigné à vous"), bouton "Laisser un avis" masqué
  (Assistant Mboa n'a pas de vendeur à noter). Prise en charge atomique à
  la première réponse d'un admin (`update ... where assigned_admin_id is
  null`, gagnée par le premier qui l'exécute, comme sur le web) —
  au-delà, la conversation disparaît de la file des autres admins.
  `_marquerLus` ne remet le compteur non-lu à zéro que si l'appelant est
  membre ou admin déjà assigné : un admin qui ouvre juste une conversation
  non assignée sans y répondre ne doit pas la faire paraître traitée aux
  yeux des autres admins.
- **Bug préexistant corrigé au passage** (même famille que lieux_publics,
  §5bis, et pas une coïncidence : cette migration date du 26/07, la veille
  de la refonte des rôles superposables du 27/07, PR #28 — jamais mise à
  jour depuis) : les 4 policies RLS de `20260726000000_assistant_mboa.sql`
  et le repli de notification "aucun admin assigné" utilisaient encore
  `role = 'admin'` en dur — un admin par privilège superposé (`est_admin
  = true`, role resté 'visiteur'/'vendeur') ne voyait donc aucune
  conversation Assistant Mboa du tout, sur aucune plateforme. Très
  probablement la cause réelle du symptôme signalé par Ferdinand, en plus
  de l'absence pure et simple de l'écran mobile. Migration
  `20260729000000_fix_assistant_mboa_est_admin.sql` : les 4 policies et
  le repli de notification passent à `is_admin()`/`role = 'admin' or
  est_admin = true` ; `marquer_conversation_lue()` (RPC utilisée par le
  mobile pour remettre le compteur à zéro, absente du web qui fait sa
  propre écriture directe) exigeait `auth.uid() = any(participants)`,
  toujours faux pour un admin sur une conversation support puisque
  `participants` ne contient que l'étudiant — corrigé pour accepter aussi
  un admin sur une ligne `is_support`.
- **Navigation admin** : entrée "🤖 Assistant Mboa" ajoutée au menu
  hamburger de `admin_screen.dart` (à côté de "Demandes", même style de
  badge rouge que le nombre de conversations non assignées) et carte
  "🚨 Actions requises" sur le Dashboard quand ce nombre est supérieur à
  zéro — miroir du lien "🤖 Assistant Mboa" dans `NAV_LINKS_ADMIN`
  (`header-client.tsx`, web).
- Testé : `flutter analyze` propre (seuls les avertissements
  `withOpacity`/`prefer_const` préexistants, non liés à ce changement) ;
  migration de correctif rejouée deux fois sur un Postgres local (schéma
  reconstitué) sans erreur.
- **Non vérifié sur device réel** au moment de la rédaction — la
  migration de correctif doit d'abord être collée dans le SQL Editor
  Supabase (sans elle, un admin par privilège superposé continuera à ne
  rien voir, même avec l'écran mobile en place).

---

## 5sexies. Notifications admin complètes : push app fermée + centre in-app unifié (29-30 juillet 2026)

Ferdinand a demandé qu'un admin soit notifié — in-app et push, y compris
app fermée — pour tout message, demande de compte ou signalement, avec
ouverture directe du bon écran au tap et compteur qui se vide pour cette
notification précise. En creusant, deux manques distincts empêchaient déjà
ça de fonctionner pour lui :

1. **Même bug `role='admin'` que §5bis/§5quinquies**, cette fois dans
   `notifications_admin.sql` (25/07) : les triggers in-app demande/
   signalement, et le filtre `notifierTousAdmins()` de l'Edge Function
   `send-notification`, ne ciblaient que `role = 'admin'` — un admin par
   privilège superposé ne recevait donc ni in-app ni push pour ces deux
   évènements. Corrigé dans `20260730000000_notifications_admin_push_complet.sql`
   (`role = 'admin' or est_admin = true`) et dans `send-notification/index.ts`.
2. **Aucun trigger n'appelait `send-notification` sur `messages`** —
   contrairement à `demandes_compte`/`signalements` qui ont chacun leur
   trigger `_push` explicite, alors que l'Edge Function sait déjà router
   ce cas (admin assigné, ou tous les admins tant qu'Assistant Mboa n'est
   pas pris en charge). Code mort faute de déclencheur ; ajouté
   (`trg_notifier_nouveau_message_push`). ⚠️ Si un Database Webhook
   existait déjà côté dashboard sur `messages` → `send-notification`, à
   supprimer pour éviter un double push (pas vérifiable depuis cet
   environnement, aucun accès direct à la configuration du projet).
3. **Le centre de notifications mobile (`notifications_screen.dart`)
   n'avait jamais lu la table `public.notifications`** : elle reconstruisait
   une liste ad-hoc à partir de `conversations.non_lu` et `avis` avec un
   repère de dernière visite en `SharedPreferences`, alors que cette table
   existe justement pour ça depuis le 24/07 ("mobile plus tard si besoin" —
   jamais fait). Conséquence directe : demandes/signalements n'y
   apparaissaient jamais côté mobile, quel que soit le type de compte
   admin. Réécrite pour lire `public.notifications` (miroir exact de
   `mboa-web/src/components/profil/notifications-list.tsx`), avec marquage
   lu **par notification tapée**, pas en bloc à l'ouverture — le compteur
   de la cloche (`NotificationsScreen.compterNonLues()`, home_screen.dart)
   requête maintenant `count(*) where lu = false` sur la même table.
4. **Ouverture directe du bon écran au tap, y compris app fermée** :
   aucun code n'existait pour ça (`onMessageOpenedApp`/`getInitialMessage`
   absents, seul le handler d'arrière-plan minimal de `main.dart` était en
   place). Ajouté :
   - `rootNavigatorKey` global (`app/router.dart`, passé à `GoRouter`) pour
     pousser un écran depuis un contexte sans `BuildContext` (callback FCM,
     tap sur notification locale).
   - `ouvrirDepuisNotificationPush(data)` (charge utile FCM : `{type,
     conversation_id|demande_id|signalement_id}`) et `ouvrirDepuisLien(lien)`
     (notifications in-app, mêmes chemins que le web : `/chat/<id>`,
     `/admin/demandes`, `/admin/signalements`, `/logements/<id>`,
     `/marketplace/<id>`, `/vendeur/<id>`) — reconstruisent les paramètres
     de `ConversationScreen`/écran cible à partir du seul id, puisqu'une
     notification n'arrive qu'avec ça.
   - `NotificationService` : callback `onNotificationTap` branché sur les
     trois cas où une notification peut être tapée — premier plan
     (`flutter_local_notifications`, payload JSON encodé dans
     `message.data`), arrière-plan (`onMessageOpenedApp`), et app
     complètement fermée (`getInitialMessage()`, appelée depuis `main.dart`
     3s après le lancement pour laisser le temps au Navigator de GoRouter
     d'exister au-delà du splash fixe de 2s).
- Testé : `flutter analyze` propre (mêmes infos préexistantes
  `withOpacity`/`prefer_const`, rien de nouveau) ; migration rejouée sur
  Postgres local avec déclencheurs attachés manuellement (schéma non
  versionné faute d'accès direct) — confirmé qu'un compte `est_admin`-only
  reçoit désormais bien les notifications demande/signalement, qu'un
  compte visiteur classique n'en reçoit aucune, et que le trigger message
  s'exécute sans erreur.
- **Non vérifié sur device réel** au moment de la rédaction, et l'Edge
  Function `send-notification` corrigée doit être redéployée par
  Ferdinand (`supabase functions deploy send-notification --project-ref
  vodmsndqahmxdsqpayrd`) — pas de clé service_role ni de lien CLI vérifié
  vers le bon projet depuis cet environnement pour le faire moi-même (le
  compte CLI authentifié ici ne liste pas ce projet parmi les siens).

---

## 5septies. Portage web du support multi-villes (30 juillet 2026)

Dernier morceau du "Reste à faire" de la §5bis : le web ne connaissait
encore que Sangmelima (constantes `DEFAULT_VILLE`/`DEFAULT_LAT`/
`DEFAULT_LNG` codées en dur partout). Porté avec la même approche que
prévue dans le plan d'origine — cookie plutôt que `localStorage`, chaque
route étant un Server Component indépendant qui doit lire la même valeur
au rendu.

- **`src/lib/data/villes.ts`** : `getVilles()` (actives, pour le
  sélecteur), `getToutesLesVilles()` (toutes, pour l'admin),
  `getVilleActuelle()` (lit le cookie `mboa_ville` via `cookies()`, repli
  sur la première ville active si absent ou obsolète — le serveur ne peut
  pas géolocaliser, contrairement au mobile).
- **`src/app/ville-actions.ts`** (`setVille`, Server Action) : écrit le
  cookie (1 an, `sameSite: lax`) puis `revalidatePath("/", "layout")`
  pour que toutes les pages (accueil, logements, marketplace, carte,
  publier) repartent d'un rendu serveur frais avec la nouvelle ville.
- **`VilleSwitcher`** (`components/home/ville-switcher.tsx`, sur l'accueil
  uniquement pour cette itération, comme prévu) : pill "📍 Ville ▾" en
  lieu et place du texte "📍 Sangmelima" codé en dur dans `HeroHeader`.
  Détection GPS automatique une seule fois si aucun cookie n'existe
  encore (ville active la plus proche dans son rayon de couverture),
  sélection manuelle possible à tout moment via la liste déroulante —
  miroir de `VilleService` (mobile), cookie à la place de
  `SharedPreferences`.
- **Filtrage par ville** : `getHomeLogements`/`getHomeArticles`/
  `getLieuxPublics`/`getLogements`/`getArticles`/`getMapData` prennent
  toutes un paramètre `ville` (sauf l'appel de `getLieuxPublics` depuis la
  page détail d'un logement, où la distance réelle au point suffit déjà à
  filtrer — rendu optionnel plutôt que de forcer une ville qu'on ne
  connaît pas encore à cet endroit du chargement). Les Server Actions de
  recherche (`searchLogements`, `searchArticles`) lisent la ville
  elles-mêmes via `getVilleActuelle()`, pas de prop-drilling depuis le
  client.
- **`TrouveTonMboa`** : centre par défaut = celui de `villeActuelle` (plus
  Sangmelima en dur), position GPS retenue seulement si dans le rayon de
  couverture de cette ville — miroir exact de
  `_resoudreReferenceProximite` (home_screen.dart). Remonté avec
  `key={villeActuelle.nom}` par la page plutôt qu'un `setState`
  synchrone dans un effet au changement de ville (`react-hooks/
  set-state-in-effect`, seule vraie erreur de lint rencontrée pendant ce
  portage).
- **Carte** (`map-view.tsx`) : centre par défaut et libellé "Sangmelima"
  → `villeActuelle`. L'ajout de lieu public par l'admin reste hors
  périmètre web (n'existait déjà pas avant cette session, propre au
  mobile).
- **Publication** (`form-logement.tsx`/`form-article.tsx`) : logement →
  ville dérivée de la position GPS captée (la plus proche parmi les
  villes actives dans son rayon), repli sur la ville courante si aucune
  position ou hors couverture ; article → ville actuellement parcourue
  (aucune position captée pour un article, comme sur mobile).
- **Bug préexistant corrigé au passage** : `form-article.tsx` n'écrivait
  la colonne `ville` nulle part (contrairement à `form-logement.tsx`) —
  exactement le même bug déjà rencontré et corrigé côté mobile
  (§5bis, "articles.ville n'existait même pas en base").
- **`/admin/villes`** (page + `villes-client.tsx`) : liste avec bascule
  actif/inactif, dialogue d'ajout/édition (nom, lat, lng, rayon, ordre),
  écritures directes via le client Supabase (RLS déjà `is_admin()`,
  migration §5bis) — miroir de `admin_villes_screen.dart`. Lien "📍
  Villes" ajouté à la nav admin (`NAV_LINKS_ADMIN`, `header-client.tsx`).
- Corrigé en chemin : trois autres endroits affichaient encore
  `logement.quartier ?? "Sangmelima"` en dur (`home-logement-card.tsx`,
  `logement-tile.tsx`, `favoris-list.ts`) — remplacés par
  `logement.ville`, la vraie donnée plutôt qu'une supposition.
- Testé : `npm run build` (TypeScript + Next.js 16/Turbopack) et
  `npm run lint` propres — `node_modules` a dû être réinstallé
  (`npm ci`, absent dans cet environnement au départ) pour pouvoir lancer
  l'un ou l'autre.
- **Non vérifié sur device réel/navigateur** au moment de la rédaction —
  build et lint uniquement, pas de test manuel du sélecteur ni de la
  détection GPS en conditions réelles.

---

## 5octies. Filtres par type de compte sur l'écran admin Utilisateurs (30 juillet 2026)

Ferdinand a signalé qu'il ne pouvait pas distinguer les différents types
d'utilisateurs sur mobile comme sur le web. En comparant les deux écrans,
les badges par carte (rôle, 👑 Admin, 🧭 Ambassadeur, statut de
vérification terrain) existaient déjà côté mobile, aussi complets que sur
`users-client.tsx` — la vraie différence était l'absence des pills de
filtre en haut de liste (`FILTRES_ROLE` côté web : Tous/Visiteurs/
Vendeurs/Ambassadeurs/Admins), qui permettent de segmenter la liste plutôt
que de la parcourir en entier.

- Ajouté à `admin_users_screen.dart` : rangée de pills horizontale
  (même style que le filtre de `admin_signalements_screen.dart`, pattern
  déjà établi dans le projet), état `_filtreRole`, getter `_usersAffiches`
  qui filtre sur `role` pour visiteur/vendeur et sur les privilèges
  superposés (`_estAdmin`/`_estAmbassadeur`, désormais des helpers
  partagés avec `_buildUserCard` plutôt que dupliqués) pour
  ambassadeur/admin — même logique de filtrage que web.
- Message "Aucun utilisateur dans ce filtre" ajouté pour le cas d'une
  liste filtrée vide, miroir du web.
- Testé : `flutter analyze` propre sur le fichier (aucune erreur, deux
  infos `prefer_const_constructors` préexistantes au style du fichier).
- **Non vérifié sur device réel** au moment de la rédaction.

---

## 5novies. Stratégie de croissance — Phase 1 : partage social des annonces (mboa-web, 29 juillet 2026)

Ferdinand a ouvert un chantier de stratégie de croissance : permettre aux
utilisateurs d'inviter d'autres personnes et de partager les annonces.
Trois leviers ont été discutés (partage social des annonces, parrainage à
crédits/paliers avec récompense financière au niveau Ambassadeur,
publication déjà partagée par les vendeurs) et un point de vigilance
explicite a été soulevé sur le parrainage : toute récompense en cascade
(commission sur les filleuls des filleuls) se rapproche structurellement
d'un schéma pyramidal, un risque légal/réputationnel réel au Cameroun —
consigné en mémoire long terme pour les prochaines sessions. Décision
actée : parrainage à un seul niveau, crédits utilisables uniquement en
interne (boost, certification) tant qu'aucun revenu récurrent ne finance
un versement réel, expérimentation démarrée côté **mboa-web uniquement**
avant tout portage mobile.

Cette section documente la Phase 1 (partage social), livrée. Les Phases 2
(parrainage à crédits/paliers) et 3 (versement réel Ambassadeur) sont
volontairement repoussées à plus tard, non commencées.

**Livré :**

- `src/lib/utils/url.ts` — `getSiteUrl()` : URL absolue déduite des
  en-têtes de la requête entrante (`host`/`x-forwarded-proto` via
  `headers()` de `next/headers`), pas de domaine codé en dur puisqu'aucune
  URL de production stable n'est encore documentée dans le projet. Fonctionne
  identiquement en local, en preview Vercel et en production.
- `generateMetadata` de `src/app/logements/[id]/page.tsx` et
  `src/app/marketplace/[id]/page.tsx` : ajout des champs `openGraph` et
  `twitter` (titre, description tronquée à 160 caractères, URL absolue de
  la page, première photo de l'annonce en image de carte 1200×630). C'est
  ce qui permet l'aperçu partiel (titre/prix/photo) affiché par
  WhatsApp/Facebook/X quand le lien est collé ou partagé — le clic renvoie
  directement vers la page de détail complète de l'annonce, déjà la cible
  naturelle de ces URLs.
- Nouveau composant `src/components/ui/share-buttons.tsx` (client
  component, icônes SVG inline pour éviter une dépendance) : boutons
  WhatsApp (`wa.me`), Facebook (`sharer.php`) et X (`intent/tweet`) via
  leurs intents web officiels. Instagram n'a aucun intent web officiel
  pour un partage de lien pré-rempli (l'app mobile ne le consomme pas) —
  repli sur `navigator.share` (ouvre le sélecteur natif du système,
  Instagram y apparaît sur mobile) ou, à défaut, copie du lien dans le
  presse-papier avec confirmation visuelle.
- Bloc `ShareButtons` inséré en bas de chaque page de détail (logement et
  article), juste avant le bouton "Signaler cette annonce" — repère "à la
  fin de l'annonce" demandé par Ferdinand.
- Testé : `npx eslint` ciblé propre, `npm run build` complet sans erreur
  TypeScript ni régression sur les 38 routes existantes.
- **Non testé en navigateur réel** (aperçu effectif WhatsApp/Facebook/X,
  comportement `navigator.share` sur mobile) au moment de la rédaction —
  l'aperçu de carte ne peut être vérifié qu'une fois le site accessible
  via une URL publique stable (WhatsApp/Facebook doivent pouvoir requêter
  l'URL pour en lire les meta tags).

**Reste à faire (Phase 2, non commencée)** : table de parrainage
(code unique par utilisateur, crédits, paliers/badges), notifications de
relance périodiques, utilisation des crédits pour boost/certification.

---

## 5decies. Stratégie de croissance — Phase 2 : parrainage à crédits/paliers (mboa-web, 31 juillet 2026)

Suite de la section 5novies. Décisions actées avec Ferdinand avant
implémentation (voir aussi [[mboa_feedback_analyse_risques]] en mémoire) :
un seul niveau de parrainage (jamais de commission sur les filleuls des
filleuls, pour écarter tout risque de dérive vers un schéma pyramidal),
crédit du parrain déclenché uniquement après une action réelle du filleul
(jamais à la simple inscription), et crédits utilisables uniquement pour du
boost — la certification (badge Vérifié) reste toujours décidée par un
admin, jamais achetée avec des crédits.

**Migration `supabase/migrations/20260731000000_parrainage.sql`** (testée
sur un schéma Postgres local reconstitué — auth.users/public.users/
messages/logements/articles/notifications mockés — avant remise à
Ferdinand, 4 scénarios vérifiés : parrainage étudiant validé au premier
message avec 10 crédits, parrainage vendeur validé à la première annonce
publiée avec 30 crédits, franchissement de palier notifié une seule fois,
anti-fraude du RPC de boost — refus si crédits insuffisants et si
l'annonce n'appartient pas à l'appelant) :

- `paliers_parrainage` : table de config (comme `villes`), pas de seuils
  codés en dur — lisible par tous, modifiable par un admin uniquement.
  5 paliers seedés : 🌱 Débrouillard(e) (0), 🔌 Connecteur du Quartier (50),
  ⭐ Grand du Mboa (150), 👑 Chef de Quartier (350), 🏆 Ambassadeur Mboa (500).
- `users.code_parrainage` (généré automatiquement, déterministe à partir de
  l'id), `parrain_id`, `credits_parrainage`.
- `parrainages` : une ligne par filleul, statut `en_attente` jusqu'à
  validation. RLS : aucune policy insert/update pour les utilisateurs,
  uniquement écrit par des fonctions `security definer` — empêche un
  utilisateur de s'auto-créditer directement via l'API.
- Le code de parrainage voyage en métadonnée auth
  (`raw_user_meta_data.code_parrain`) : capté directement au `signUp` pour
  un étudiant, ou transporté via `demandes_compte.code_parrain` jusqu'à
  l'Edge Function `create-vendor` (mise à jour pour le relire et le
  transmettre à `auth.admin.createUser`) pour un vendeur — un seul trigger
  générique (`enregistrer_parrainage`) gère les deux cas sans
  spécialisation.
- Validation + crédit : `valider_parrainage_filleul`, appelée sans
  condition depuis les triggers sur `messages`/`logements`/`articles`
  (no-op silencieux si le parrainage est déjà validé — pas besoin de
  détecter explicitement "la première" action).
- `echanger_credits_boost(annonce_type, annonce_id)` : RPC `security
  definer`, 50 crédits = 1 boost immédiat et permanent. **Pas
  d'expiration automatique (pas de "boost 7 jours" pour cette itération)**
  : ce projet n'a aucune infrastructure de tâche planifiée (ni `pg_cron`,
  ni Edge Function schedulée — vérifié par grep sur toutes les migrations),
  et bâtir une expiration fiable aurait demandé soit d'introduire cette
  infra, soit de modifier le filtrage/l'affichage `boosted` dans une
  dizaine de fichiers (home/logements/articles/carte/cartes). Écarté comme
  disproportionné pour une expérimentation ; `credits_utilisations` trace
  chaque dépense pour une évolution future.
- `demandes_compte.code_parrain` (nouvelle colonne), `notifications` :
  nouveau type `parrainage`.

**Edge Function `supabase/functions/create-vendor/index.ts`** : relit
`code_parrain` depuis la demande approuvée et le transmet en métadonnée à
la création du compte Auth. Migration confirmée appliquée en production
par Ferdinand (vérifié en lisant `paliers_parrainage`/`users.code_parrainage`
en direct via le MCP Supabase) ; `create-vendor` (v6→v7) et
`send-notification` (v7→v8, correctif `est_admin` de la section 5sexies)
redéployées avec succès le 29/07 une fois le bon compte Supabase authentifié
(le projet `vodmsndqahmxdsqpayrd` n'était pas visible depuis le compte CLI
utilisé jusque-là).

**Côté web** :

- `ReferralCapture` (montée dans `layout.tsx`, comme `InstallPrompt`) capte
  `?ref=CODE` sur n'importe quelle page et le conserve en `localStorage`
  jusqu'à l'inscription, potentiellement bien plus tard.
- `/parrainage` : code + lien à partager (réutilise `ShareButtons` de la
  Phase 1), jauge de progression vers le prochain palier, échelle des 5
  paliers, liste des filleuls avec statut.
- `/vendeur/annonces` : bouton "🚀 Booster (50 crédits)" par annonce non
  boostée, désactivé si solde insuffisant, `router.refresh()` après succès
  pour resynchroniser le solde affiché ailleurs (profil, header).
- Entrée "🎁 Mon parrainage" ajoutée au menu Profil (section "Mes
  activités"), affichant le solde de crédits.
- `UserModel` étendu (`codeParrainage`, `creditsParrainage`).
- Testé : `npx eslint` ciblé propre, `npm run build` complet sans erreur
  TypeScript (40 routes, `/parrainage` incluse).
- Test en conditions réelles démarré par Ferdinand le 29/07, une fois la
  migration en production et les Edge Functions redéployées — voir section
  5undecies pour les deux bugs (préexistants, sans lien avec le parrainage
  lui-même) découverts au passage.

**Reste à faire (Phase 3, non commencée)** : versement financier réel au
palier Ambassadeur Mboa — volontairement repoussé jusqu'à disposer de
données réelles sur l'engagement du système et d'un revenu récurrent pour
le financer.

---

## 5undecies. Quatre bugs préexistants découverts en testant le parrainage (29 juillet 2026)

En testant la Phase 2 en conditions réelles, Ferdinand a signalé deux
erreurs sans rapport avec le parrainage lui-même — diagnostiquées en
lisant directement les logs Postgres et les données du vrai projet via le
MCP Supabase (accès obtenu ce jour-là après authentification du bon compte
Supabase, voir section 6).

**1. Impossible de faire évoluer un compte étudiant en compte vendeur
(erreur 23514, violation de contrainte CHECK).** Root-cause trouvé dans
les logs : `create-vendor-dialog.tsx` (web) et `admin_demandes_screen.dart`
(mobile), dans la branche "compte existant" de la validation d'une demande
Pro, mettent à jour `demandes_compte.statut` avec la valeur `'traite'` —
qui n'existe pas dans la contrainte `demandes_compte_statut_check`
(`en-attente`/`approuve`/`rejete`). Confusion avec le vocabulaire de la
table `signalements`, où `'traite'` est une valeur valide — mêmes écrans
admin, mécanique "approuver/rejeter" similaire, probablement copié d'un
écran à l'autre. Corrigé sur les deux plateformes (`'traite'` →
`'approuve'`, la même valeur que la branche "nouveau compte" du même
formulaire) ; entrée `traite` retirée de `STATUT_STYLE`
(`demandes-client.tsx`) devenue inutile. Une demande de Ferdinand
(`Design Nickel`) était restée bloquée à `en-attente` suite à une tentative
précédente alors que son compte avait déjà bien été promu vendeur côté
`users` (les deux écritures ne sont pas transactionnelles) — corrigée
manuellement en production (`statut` → `approuve`) une fois le bug
identifié.

**2. "Assigner un ambassadeur" ne trouve aucun ambassadeur alors qu'il en
existe déjà deux.** Vérifié en base : les deux comptes (`Ambassadeur QA`,
`Ambassadeur Mboa`) ont `role='visiteur'` avec `est_ambassadeur=true` — un
ambassadeur nommé via "Nommer ambassadeur" (admin_users_screen.dart)
conserve son rôle de base, `est_ambassadeur` étant un privilège superposé
depuis la refonte de la section 4.9, jamais `role='ambassadeur'` en
pratique. Trois emplacements filtraient encore uniquement sur
`role='ambassadeur'`, oubliés lors de cette refonte (même famille de bug
que celle déjà rencontrée sur les notifications, section 5sexies) :
`admin_verifications_screen.dart` (mobile), `verifications-client.tsx` et
`lib/data/admin.ts` (`getAmbassadeurs`, web — inutilisé actuellement mais
corrigé par cohérence). Les trois passent désormais par
`role.eq.ambassadeur,est_ambassadeur.eq.true` (`.or(...)`), même logique
que `_estAmbassadeur` déjà utilisé dans `admin_users_screen.dart`.

**3. Envoi impossible du formulaire de vérification terrain assigné à un
ambassadeur.** Diagnostiqué directement dans les logs Postgres du vrai
projet (`get_logs`, service `postgres`) : `new row violates row-level
security policy for table "objects"` — le formulaire échoue au moment de
téléverser la pièce justificative (photo) dans le bucket Storage privé
`attestations-proprietaires`. La policy `storage.objects` correspondante
(définie dans `20260717010000_verification_terrain.sql`) ne vérifiait,
elle aussi, que `role = 'ambassadeur'` — exactement le même bug que le
point 2 ci-dessus, sur une troisième surface distincte (policy Storage,
pas une requête applicative). Corrigé par la migration
`20260801000000_fix_ambassadeur_storage_policy.sql` (`drop`/`create
policy`, condition étendue à `role = 'ambassadeur' or est_ambassadeur =
true`), appliquée directement en production via le MCP Supabase
(`apply_migration`, correctement tracée dans l'historique de migrations
Supabase) et vérifiée en relisant la policy après coup.

**4. Création d'un compte vendeur depuis une demande impossible (403
"Action réservée aux administrateurs").** Diagnostiqué via les logs
Edge Function (`get_logs`, service `edge-function`) : `POST | 403 |
.../functions/v1/create-vendor`. Root cause : la fonction elle-même
vérifie `callerProfile?.role !== 'admin'` sur l'appelant — même bug,
cette fois dans une Edge Function plutôt qu'une policy RLS ou une requête
applicative. Le compte admin de Ferdinand a `role='visiteur'` +
`est_admin=true`, donc rejeté systématiquement. Un balayage complet du
projet (grep ciblé sur mobile/web/SQL, puis requêtes directes sur
`pg_policies` et `pg_proc` du vrai projet pour toute condition
`role = 'admin'` sans `est_admin` associé) a trouvé deux autres Edge
Functions avec exactement le même défaut : `create-ambassadeur` et
`get-attestation-url` (cette dernière contrôle aussi l'accès de
l'ambassadeur assigné, logique inchangée). Les trois corrigées
(`role !== 'admin' && !est_admin`) et redéployées
(`create-vendor` v7→v8, `create-ambassadeur` v3→v4,
`get-attestation-url` v2→v3) ; balayage confirmé propre sur le reste
(RLS et fonctions SQL, Dart, TypeScript).

Testé : `flutter analyze` et `npx eslint` propres sur les fichiers touchés
des bugs 1 et 2 ; policy Storage vérifiée directement en base pour le bug
3 ; versions des trois Edge Functions confirmées incrémentées pour le
bug 4. **Non revérifié sur device/navigateur réel** au moment de la
rédaction — à confirmer par Ferdinand.

---

## 5duodecies. Régression auto-infligée : send-notification cassée par son propre redéploiement (29-30 juillet 2026)

Ferdinand a signalé ne plus recevoir aucune notification push. Audit
préventif de la publication d'articles (section précédente) n'ayant rien
trouvé, root-cause identifié en croisant les timestamps exacts entre
`public.notifications` (créées normalement, in-app fonctionnel) et les
logs Edge Function : chaque appel à `send-notification` déclenché par un
trigger SQL (`net.http_post`, sans header `Authorization` — ces triggers
n'en ont jamais envoyé, voir `notifier_admin_demande_compte_push`,
`notifier_admin_signalement_push`, `notifier_nouveau_message_push`)
recevait **401** depuis exactement l'heure de mon propre redéploiement de
`send-notification` plus tôt dans la session (section 5undecies, point 4).

**Cause : `supabase/config.toml` n'avait aucune section
`[functions.send-notification]`.** Seule `create-vendor` avait
`verify_jwt = false` explicitement figé. `send-notification` avait
probablement été déployée à l'origine avec `--no-verify-jwt` (manuel,
hors CLI trackée), réglage qui vit uniquement côté serveur Supabase — un
`supabase functions deploy` ultérieur sans ce flag et sans entrée
`config.toml` réactive silencieusement la vérification JWT par défaut, ce
qui rejette tout appel sans JWT valide. Un bug auto-infligé, pas un bug
préexistant comme les précédents de cette session.

Corrigé : ajout de `[functions.send-notification]` avec `verify_jwt =
false` dans `config.toml` (pour que ça ne se reproduise plus au prochain
redéploiement), redéploiement avec `--no-verify-jwt` explicite (v8→v9),
vérifié directement par un `curl` sans header Authorization simulant
l'appel d'un trigger → 200. Impact : environ 13h de push perdus (2
notifications in-app créées mais jamais poussées pendant la fenêtre),
aucune notification in-app perdue (mécanisme distinct, non affecté).

**Leçon retenue** : tout futur `supabase functions deploy` sur une
fonction appelée par un trigger SQL (sans JWT) doit soit avoir sa section
`config.toml` dédiée, soit être redéployée avec `--no-verify-jwt`
explicite — vérifier `config.toml` avant tout redéploiement d'Edge
Function dans ce projet.

---

## 6. Infrastructure technique

### Supabase (projet `vodmsndqahmxdsqpayrd`)
- **Tables principales** : `users`, `logements`, `articles`,
  `conversations`, `messages`, `avis`, `signalements`, `demandes_compte`,
  `favoris`, `lieux_publics`, `alertes_recherche`, `moderation_ia`,
  `image_hashes`, `verifications_terrain`, `attestations_acces_log`,
  `notifications`, `etude_marche_reponses`, `villes` (référence des
  villes couvertes, admin-gérable depuis le 27/07).
- **Edge Functions** : `create-vendor`, `create-ambassadeur`,
  `send-notification`, `notifier-nouvelle-annonce`, `moderate-annonce`,
  `get-attestation-url`, `debug-hash`, `swift-endpoint`.
- **RLS** : policies pour chaque rôle, fonction centrale `is_admin()`
  réutilisée par la majorité des policies admin, policies dédiées pour
  la conversation Assistant Mboa.
- **Realtime** : activé sur `messages`, `conversations`,
  `verifications_terrain`, `signalements`.
- **Triggers Postgres** (`pg_net`) : notifications in-app et push à
  l'insertion sur plusieurs tables, création automatique de la
  conversation Assistant Mboa à l'inscription.

### Déploiement
- **Web** : Vercel, déploiement automatique sur push vers la branche.
- **Mobile** : build Android/iOS Flutter.

---

## 7. Bugs notables corrigés (toutes plateformes)

| Bug | Contexte |
|---|---|
| Race condition sur les filtres prix/note | Mobile, corrigée avant le port web |
| Annonces validées par l'admin bloquées | Filtre `statut_moderation` mal appliqué |
| Badge non-lu jamais incrémenté | Bug architectural cross-plateforme : `conversations.non_lu` n'était mis à jour nulle part (ni trigger, ni client) — trouvé sur mobile via test device réel le 22/07, corrigé par trigger + RPC ; désynchronisation d'affichage similaire corrigée séparément côté web (PR #4/#5) |
| Boutons flottants chevauchant le contenu | Détail logement, mobile (`ScrollController`, 22/07) et web (PR #4), corrigés séparément le même jour |
| Bouton "Appeler" tronqué en "Appe..." | Mobile, détail logement/article/profil vendeur — l'ellipsis évitait le débordement mais pas la troncature |
| Redirect email de confirmation cassé | Web, inscription |
| Connexion Google jamais fonctionnelle (web) | Route `/auth/callback` manquante |
| 25 logements affichés vs 34 sur la carte | Plafond de budget par défaut invisible |
| Signalement IA "orphelin" après traitement | Désynchronisation avec l'onglet Signalements |
| Halo de la visite guidée décalé sur mobile | Délai fixe insuffisant après un long scroll |
| Crash silencieux à la création d'un ambassadeur | Mobile |
| Blocage indéfini à l'upload de photos | Mobile |
| Realtime jamais reçu sur verifications_terrain/signalements | Tables absentes de la publication `supabase_realtime` |
| Comptes admin/ambassadeur réels verrouillés hors de leur espace | Mobile, après la migration `est_admin`/`est_ambassadeur` côté web (4.9) — `UserModel.isAdmin`/`MainScreen` testaient encore `role == 'admin'` littéralement |
| `lieux_publics` inaccessible aux admins `est_admin`-only | RLS jamais migrée de `role='admin'` vers `is_admin()` lors de la refonte des rôles (4.9), trouvé en implémentant le multi-villes le 27/07 |
| `articles.ville` n'a jamais existé en base | Colonne absente depuis l'origine (contrairement à `logements.ville`), lue en silence comme `null` ; trouvé en appliquant la migration multi-villes le 28/07 |
| Bulle de la visite guidée soulignée en couleur (double soulignement) | Mobile, `OverlayEntry` monté hors du `Scaffold` sans ancêtre `Material` — style de repli de debug Flutter, pas un style voulu |
| Dernière étape "Crée ton compte" de la visite guidée mal ciblée | Mobile, distinct du délai de scroll déjà corrigé (ligne ci-dessus) — halo figé sur une position obsolète si le contenu au-dessus finit de charger juste après le calcul initial |

---

## 8. Tableau récapitulatif des Pull Requests

| PR | Date | Titre |
|---|---|---|
| #1 | 21/07 | Version web de Mboa — reproduction complète de l'app Flutter |
| #2 | 22/07 | Fix : autorise images.unsplash.com pour les photos de démo |
| #3 | 22/07 | Doc : déploiement Vercel et incidents de mise en production |
| #4 | 22/07 | Logo, footer redesigné, onglet Chat et fix du badge non-lu |
| #5 | 22/07 | Fix navigation chat lente, badge non-lu au retour, footer sur conversation/carte |
| #6 | 22/07 | Chat de conversation, note vendeur, badge certifié + bouton Message du profil vendeur |
| #7 | 22/07 | Branche le bouton Message du profil vendeur sur le vrai chat |
| #8 | 23/07 | Redirige un admin connecté vers /admin, comme sur mobile |
| #9 | 23/07 | Redéclenche le déploiement Vercel |
| #10 | 23/07 | Fix overflow mobile du formulaire logement + onglets admin/ambassadeur dans le header |
| #11 | 23/07 | Améliore l'affichage grand écran |
| #12 | 23/07 | Fixe le lien de confirmation email de l'inscription web |
| #13 | 23/07 | Ajoute la route /auth/callback |
| #14 | 23/07 | Assouplit la validation du mot de passe (web + mobile) |
| #15 | 23/07 | Filet de sécurité OAuth Google |
| #16 | 24/07 | Écart gauche/droite sur grand écran |
| #17 | 24/07 | Bannières hero arrondies, zone vide du chat sur grand écran |
| #18 | 24/07 | Zone blanche du chat, coins arrondis, onglet actif, app installable |
| #19 | 24/07 | Bannières de tête restantes + conversation moins compressée |
| #20 | 24/07 | Conversation plus large, photos plein écran, notifications en direct, pastille de certification |
| #21 | 24/07 | Retire le plafond de budget par défaut invisible |
| #22 | 24/07 | Icône de filtre "tune" (comme mobile) |
| #23 | 26/07 | Notifications admin, fix signalement IA, filtre par rôle |
| #24 | 26/07 | Assistant Mboa : conversation support automatique |
| #25 | 26/07 | Visite guidée pour les nouveaux visiteurs |
| #26 | 26/07 | Visite guidée : vendeurs, visiteurs inscrits, Publier/Gestion |
| #27 | 27/07 | Fix : décalage du halo de la visite guidée sur mobile |
| #28 | 27/07 | Admin/ambassadeur deviennent des privilèges superposables |
| #29 | 27/07 | Doc : ajoute l'historique complet du projet Mboa |
| #30 | 27/07 | Mobile : parité admin/ambassadeur + visite guidée |

*Toutes fusionnées dans `main`, y compris la #30 — confirmée fusionnée
et synchronisée en local le 27/07 (fast-forward propre, `flutter
analyze` sans erreur après fusion, aucun conflit entre les correctifs
mobile du 22/07 et le travail web/notifications qui a suivi).*

---

## 9. État actuel

- **Mobile** : app Flutter complète — auth, logements, market, chat,
  profil, publication, admin, ambassadeur (désormais des privilèges
  superposables comme sur le web, voir section 5), modération IA,
  vérification terrain, notifications push, temps réel, mode hors
  ligne, visite guidée interactive (accueil/Publier/Gestion).
- **Web** : couverture intégrale des écrans mobiles, plus le modèle de
  rôles admin/ambassadeur superposables et la visite guidée — les deux
  désormais également disponibles côté mobile (PR #30, non encore
  vérifiée sur device réel au moment de la rédaction).
- **Parité mobile/web** : atteinte sur le plan fonctionnel après le
  rattrapage de la Phase 3. Reste une différence de méthode : le web
  utilise `data-tour` + sélecteurs DOM pour la visite guidée, le mobile
  utilise des `GlobalKey` Flutter (pas d'équivalent direct entre les
  deux plateformes).
- **Pistes ouvertes** (mentionnées en cours de route, non traitées) :
  clé API Gemini en quota dépassé (modération IA de contenu inopérante
  depuis plusieurs tentatives, seul le hachage perceptuel anti-fraude
  fonctionne).
- **Campagne de test manuel sur device réel** (Android, via `adb`,
  comptes de `COMPTES_TEST.md`) commencée le 22/07 : parcours visiteur
  non inscrit et étudiant connecté couverts, ayant mené aux correctifs
  de la section 3 ("Vérification sur device réel"). Parcours
  vendeur/propriétaire et administrateur restent à tester, mis en pause
  à la demande de Ferdinand pour reprise ultérieure.
- **Synchronisation dépôt local/distant vérifiée le 27/07** : fast-forward
  propre vers `main` (jusqu'à la PR #30 incluse), aucun commit local
  perdu, `flutter analyze` sans erreur après fusion.
- **Multi-villes (27-28/07)** : Sangmelima/Kribi/Ébolowa couvertes côté
  mobile (voir Phase 4, section 5bis), migration appliquée en base de
  production. Portage web pas commencé.
- **Visite guidée et navigation admin (28/07, section 5ter)** : tous les
  correctifs vérifiés sur device réel — bulle sans soulignement de
  debug, bouton icône seule sur l'accueil, étape Trouve ton Mboa,
  dernière étape correctement ciblée, barre admin à 5 onglets, menu
  hamburger (Demandes/Mon compte) fonctionnel.
- **Assistant Mboa côté mobile (29/07, section 5quinquies)** : implémenté
  et vérifié en production (migration collée avec succès) — chat/liste
  admin-aware, prise en charge atomique, menu admin dédié.
- **Jeu de données de test Kribi/Ébolowa (28/07, section 5quater)** :
  migration `20260728000000_seed_kribi_ebolowa.sql` écrite, testée contre
  un schéma reconstitué en local, exécutée avec succès en production —
  4 comptes vendeurs pré-validés, 42 logements, 52 articles, 14 lieux
  publics géocodés.
- **Notifications admin complètes (29-30/07, section 5sexies)** : bug
  `role='admin'` corrigé (in-app + push + Edge Function), trigger push
  messages ajouté, centre de notifications mobile réécrit sur la vraie
  table, ouverture directe au tap y compris app fermée. Migration collée
  et confirmée fonctionnelle en production par Ferdinand le 30/07 ; l'Edge
  Function `send-notification` corrigée reste à redéployer par lui
  (`supabase functions deploy send-notification --project-ref
  vodmsndqahmxdsqpayrd`) pour que le correctif `notifierTousAdmins` soit
  effectif côté push — pas confirmé au moment de la rédaction.
- **Multi-villes côté web (30/07, section 5septies)** : sélecteur de
  ville, filtrage complet (accueil/logements/marketplace/carte/
  publication), `/admin/villes`. `npm run build`/`lint` propres, pas
  encore testé en navigateur réel.
- **Filtres par type de compte, écran admin Utilisateurs (30/07, section
  5octies)** : pills Tous/Visiteurs/Vendeurs/Ambassadeurs/Admins ajoutées,
  miroir du web. Non vérifié sur device réel.
- **Stratégie de croissance — Phase 1 : partage social (29/07, section
  5novies)** : meta Open Graph/Twitter dynamiques + boutons de partage
  WhatsApp/Facebook/X/Instagram sur les pages détail logement et article
  côté mboa-web. `npm run build`/`lint` propres, aperçu de carte pas
  encore vérifié en conditions réelles (nécessite une URL publique
  stable). Phase 1 confirmée fonctionnelle par Ferdinand après test réel.
- **Stratégie de croissance — Phase 2 : parrainage à crédits/paliers
  (31/07, section 5decies)** : migration `20260731000000_parrainage.sql`
  écrite, testée en local puis collée et confirmée en production par
  Ferdinand ; `create-vendor` et `send-notification` redéployées le 29/07
  (voir section 6). Page `/parrainage`, bouton boost via crédits sur Mes
  annonces, capture `?ref=` sur mboa-web. Un seul niveau de parrainage et
  crédits jamais convertibles en argent pour cette itération — Phase 3
  (versement réel Ambassadeur) toujours non commencée, séquencée à
  dessein. Test réel en cours par Ferdinand, ayant révélé quatre bugs
  préexistants sans rapport avec le parrainage (section 5undecies).
- **Bugs préexistants corrigés en testant le parrainage (29/07, section
  5undecies)** : mise à niveau étudiant→vendeur bloquée par une valeur de
  statut invalide (`'traite'` au lieu de `'approuve'`), assignation
  d'ambassadeur ne trouvant aucun candidat, envoi du formulaire de
  vérification terrain bloqué par une policy Storage, et création d'un
  compte vendeur depuis une demande rejetée avec 403 — les quatre
  filtraient encore sur `role = 'admin'`/`role = 'ambassadeur'` sans tenir
  compte des privilèges superposés `est_admin`/`est_ambassadeur` (même
  famille que le bug notifications de la section 5sexies), le dernier
  dans trois Edge Functions (`create-vendor`, `create-ambassadeur`,
  `get-attestation-url`). Corrigés sur mobile, web et Edge Functions ;
  policy Storage et Edge Functions redéployées en production. Balayage
  complet du projet (app + RLS + fonctions SQL) confirmé propre après
  coup. Non revérifiés sur device/navigateur réel au moment de la
  rédaction.
- **Campagne de test manuel sur device réel** (Android, via `adb`,
  comptes de `COMPTES_TEST.md`) commencée le 22/07 : parcours visiteur
  non inscrit et étudiant connecté couverts (section 3), plus des
  vérifications ciblées le 28/07 (multi-villes, visite guidée, nav
  admin). Parcours vendeur/propriétaire et administrateur restent à
  tester de façon exhaustive, mis en pause à la demande de Ferdinand
  pour reprise ultérieure.
