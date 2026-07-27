# Historique complet du projet Mboa

Document généré à partir de l'historique Git réel du dépôt `mboa_app`
(98 commits, 28 Pull Requests, du 6 juin au 27 juillet 2026) et des échanges
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

## 5. Infrastructure technique

### Supabase (projet `vodmsndqahmxdsqpayrd`)
- **Tables principales** : `users`, `logements`, `articles`,
  `conversations`, `messages`, `avis`, `signalements`, `demandes_compte`,
  `favoris`, `lieux_publics`, `alertes_recherche`, `moderation_ia`,
  `image_hashes`, `verifications_terrain`, `attestations_acces_log`,
  `notifications`, `etude_marche_reponses`.
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

## 6. Bugs notables corrigés (toutes plateformes)

| Bug | Contexte |
|---|---|
| Race condition sur les filtres prix/note | Mobile, corrigée avant le port web |
| Annonces validées par l'admin bloquées | Filtre `statut_moderation` mal appliqué |
| Badge non-lu jamais incrémenté | Web, détail logement |
| Boutons flottants chevauchant le contenu | Web, détail logement |
| Redirect email de confirmation cassé | Web, inscription |
| Connexion Google jamais fonctionnelle (web) | Route `/auth/callback` manquante |
| 25 logements affichés vs 34 sur la carte | Plafond de budget par défaut invisible |
| Signalement IA "orphelin" après traitement | Désynchronisation avec l'onglet Signalements |
| Halo de la visite guidée décalé sur mobile | Délai fixe insuffisant après un long scroll |
| Crash silencieux à la création d'un ambassadeur | Mobile |
| Blocage indéfini à l'upload de photos | Mobile |
| Realtime jamais reçu sur verifications_terrain/signalements | Tables absentes de la publication `supabase_realtime` |

---

## 7. Tableau récapitulatif des Pull Requests (mboa-web)

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

*Toutes fusionnées dans `main`.*

---

## 8. État actuel

- **Mobile** : app Flutter complète — auth, logements, market, chat,
  profil, publication, admin, ambassadeur, modération IA, vérification
  terrain, notifications push, temps réel, mode hors ligne.
- **Web** : couverture intégrale des écrans mobiles, plus une visite
  guidée interactive propre au web et un modèle de rôles admin/
  ambassadeur superposables plus flexible que sur mobile pour l'instant.
- **Pistes ouvertes** (mentionnées en cours de route, non traitées) :
  clé API Gemini en quota dépassé (modération IA de contenu inopérante
  depuis plusieurs tentatives, seul le hachage perceptuel anti-fraude
  fonctionne) ; le modèle de rôles superposables (est_admin/
  est_ambassadeur) n'a pas encore d'équivalent côté app Flutter mobile.
