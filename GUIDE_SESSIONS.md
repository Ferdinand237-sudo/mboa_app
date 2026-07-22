# Guide des sessions de travail — Mboa App

Document vivant, construit à partir des 33 commits du projet (06/06 → 22/07/2026)
et des sessions de debug qui ont suivi. Objectif : ne pas refaire deux fois la
même erreur, et transmettre les réflexes qui ont réellement évité des bugs.

Ce n'est **pas** un doublon de CLAUDE.md (qui reste la référence pour
l'architecture, les tables Supabase, les conventions de code obligatoires et
la liste des écrans). Ici : les pièges déjà tombés dedans, et la façon de
travailler qui a fonctionné.

**À faire à chaque session significative** : si un nouveau bug de la même
famille qu'une des règles ci-dessous apparaît, ou qu'un nouveau piège
générique est découvert, ajouter une entrée. Si une règle s'avère fausse ou
obsolète, la corriger plutôt que d'empiler une exception à côté.

---

## 1. Où en est le projet

- **Juin 2026** — squelette initial (auth, navigation par rôle, écrans de
  base branchés sur Supabase).
- **15–16 juillet** — carte OSM + recherche géographique, favoris, GPS à la
  publication, OAuth Google, refonte complète Home/Market/Chat/Profil avec
  vraies données partout, sécurisation (RLS, validation stricte, CRUD,
  mode hors ligne).
- **16–17 juillet** — notifications push FCM, **modération IA des annonces**
  (hash perceptuel + Gemini → `statut_moderation`), **vérification terrain**
  des propriétaires (rôle ambassadeur, visite obligatoire avant publication),
  **temps réel** sur les tableaux de bord admin/ambassadeur.
- **17–18 juillet** — vague de corrections trouvées en testant sur device
  réel (notes affichées à 0, filtre note, upload photo qui bloquait
  indéfiniment).
- **Reste à faire** : voir la section "Fonctionnalités À IMPLÉMENTER" de
  CLAUDE.md (splash screen/icône définitifs, build APK release systématique).

Comprendre cette chronologie évite de re-proposer une fonctionnalité déjà
livrée, ou de "corriger" un choix qui était en fait déjà une deuxième
correction d'un problème plus ancien.

---

## 2. Pièges récurrents (le plus important de ce document)

Chaque entrée : symptôme observé → cause réelle → règle à appliquer
systématiquement. Commit de référence entre parenthèses.

1. **Mismatch de type silencieux avec Postgrest.** Un `double` (ex: valeur
   de `Slider`) envoyé tel quel à une colonne `integer` fait échouer la
   requête entière en 400 — sans que ça saute aux yeux en lisant le code.
   → Toujours caster explicitement (`.toInt()`) une valeur numérique issue
   d'un widget Flutter avant de filtrer dessus. (`dd2599a`)

2. **`.order()` sans `ascending:` trie en descendant par défaut** côté
   `postgrest-dart` (contre-intuitif si on vient d'autres ORM). Toujours
   expliciter `ascending: true/false`, ne jamais compter sur le défaut.
   (`dd2599a`)

3. **RLS bloque silencieusement un UPDATE inter-utilisateurs.** Un client
   qui tente de modifier la ligne d'un *autre* utilisateur (ex: recalculer
   `users.note_globale` depuis l'écran de chat) voit son update passer
   "sans erreur" — Postgrest ne lève rien, c'est juste 0 ligne affectée.
   Le bug est donc invisible côté client, seul le résultat final (note
   jamais mise à jour) le trahit.
   → Ne jamais écrire côté client sur une ligne qui n'appartient pas à
   l'utilisateur courant. Laisser un trigger serveur (`SECURITY DEFINER`)
   s'en charger, et si un recalcul ne semble jamais s'appliquer, vérifier
   RLS avant de chercher ailleurs. (`4f53736`)

4. **Colonnes "mortes" jamais alimentées vs. la vraie source jointe.**
   `logements.note_globale`, `logements.nb_avis`, `articles.nb_avis`
   existent en base mais ne sont jamais écrites (les avis notent le
   propriétaire/vendeur, pas l'annonce) — la vraie donnée vit sur `users`
   et doit être lue via la jointure `proprietaire:`/`vendeur:`.
   → Avant d'afficher un champ, vérifier qui l'écrit réellement (grep sur
   `.update({'<colonne>':` dans tout le repo, pas seulement supposer que la
   colonne du même nom sur la table affichée est la bonne). Ce bug est
   réapparu deux fois sur des écrans différents (`4f53736`, `7a820c9`) —
   probablement pas la dernière.

5. **Flux de statut sans chemin de retour testé.** Tout mécanisme qui pose
   un statut intermédiaire (`en_attente`, `a_verifier`, `bloque`,
   `suspendu`...) doit avoir, pour *chacune* de ses branches de sortie, un
   code qui ramène explicitement l'état à la normale. Exemple réel : la
   modération IA passe une annonce en `a_verifier` et crée un signalement ;
   les boutons admin "Résoudre"/"Ignorer" ne faisaient que fermer le
   signalement sans jamais republier `statut_moderation` → l'annonce restait
   invisible pour toujours, y compris dans le tableau de gestion du vendeur.
   → Quand on ajoute une écriture de statut "bloquant", chercher
   immédiatement tous les chemins qui doivent l'inverser, et vérifier qu'au
   moins un test manuel parcourt le cycle complet aller-retour, pas
   seulement l'aller. (correction du 22/07, voir historique de session —
   pas encore committée au moment de la rédaction de ce guide)

6. **Opérations réseau sans timeout = blocage indéfini sans exception.**
   `SupabaseStorage.upload()` et `Geolocator.getCurrentPosition()` peuvent
   rester en attente indéfiniment sur un réseau faible, sans jamais
   déclencher de `catch` — l'UI reste bloquée sur "Chargement..." sans
   message, très dur à diagnostiquer à distance (fonctionnait en dev sur
   bon wifi). → Tout appel réseau déclenché depuis un bouton utilisateur
   doit avoir un `.timeout(Duration(...))` explicite avec un message clair
   en cas de dépassement. (`4c73ee6`, `7a820c9`)

7. **`BuildContext` réutilisé après un `Navigator.pop()`/await sans
   vérifier `mounted`.** Crash "Null check operator used on a null value",
   uniquement visible sur device réel (jamais en hot-reload). → Après tout
   `await` suivi d'un usage de `context` dans une fonction async, vérifier
   `mounted` juste avant, pas seulement en tête de fonction. (`eeef50c`)

8. **Race condition sur les listes rechargées à chaque interaction.** Un
   `Slider.onChanged` ou un champ de recherche qui redéclenche l'appel
   réseau à chaque frappe/tick peut recevoir les réponses dans le désordre :
   une requête partie tôt avec un filtre plus large répond après une
   requête plus récente et écrase ses résultats avec des données qui ne
   correspondent plus aux filtres affichés à l'écran. → Garder un compteur
   de requête (`_requestId`), incrémenté à chaque appel, et ignorer toute
   réponse dont l'id ne correspond plus au dernier appel lancé. Ajouter un
   debounce sur les champs texte/sliders en plus, pour la charge réseau.
   (correction du 22/07, pas encore committée)

9. **Une table absente de la publication `supabase_realtime` ne déclenche
   jamais aucun événement**, sans erreur ni log côté client — l'abonnement
   `onPostgresChanges` reste juste silencieux pour toujours.
   → Si "le temps réel ne semble rien recevoir", vérifier en premier
   `ALTER PUBLICATION supabase_realtime ADD TABLE ...` avant de chercher un
   bug dans le code Flutter. (`d821c4b`, oubli initial sur
   `verifications_terrain`/`signalements`)

10. **Libellés de boutons qui passent à la ligne sur petit écran.** Row de
    boutons d'action (Suspendre/Supprimer, Appeler/Message, etc.) qui tient
    très bien dans l'éditeur/l'aperçu large, mais casse le mot en deux sur
    un écran étroit réel. → Systématiquement tester ces Row sur une largeur
    d'écran étroite (ou envelopper le texte avec `Flexible` +
    `overflow: TextOverflow.ellipsis` par défaut). Réapparu sur 8 écrans
    différents avant d'être traité comme une règle générale. (`9d03fd0`,
    `611cab5`)

11. **Edge Function renommée/introuvable côté dashboard Supabase.** Un
    renommage accidentel (ex: `create-vendor` devenu `swift-endpoint`) fait
    échouer l'appel côté client sans message clair — juste une erreur
    réseau générique. → Si un appel Edge Function échoue de façon opaque,
    vérifier en premier le nom exact déployé (`supabase functions list`)
    avant de suspecter la logique métier. (`67f10bc`)

12. **Action utilisateur critique sans gestion d'erreur = UI bloquée.**
    `signOut()` appelé sans `try/catch` pouvait laisser la navigation
    bloquée après un simple accroc réseau, obligeant l'utilisateur à
    cliquer deux fois sur "Se déconnecter" pour que ça finisse par marcher.
    → Toute action déclenchée par un bouton doit faire progresser l'UI
    (fermer le dialogue, naviguer, afficher une erreur) même si l'appel
    réseau sous-jacent échoue. (`dd2599a`)

---

## 3. Processus qui a fait ses preuves

- **Le build ne se fait QUE via GitHub Actions** (`.github/workflows/`),
  jamais localement (iOS/Android). Confirmé explicitement le 22/07/2026 —
  ne pas lancer `flutter run`/`flutter build` pour Android/iOS en local, et
  ne pas proposer de le faire. `flutter analyze` reste le bon outil de
  vérification rapide en session.
- **Les tests fonctionnels sur device réel ont trouvé des bugs que
  `flutter analyze` ne peut pas voir** : upload bloqué indéfiniment, crash
  ambassadeur, wrapping de boutons, GPS qui ne timeout jamais. Après un
  changement UI ou un flux critique (paiement, publication, modération),
  prévoir explicitement ce passage — et si ce n'est pas possible dans la
  session en cours, le dire clairement plutôt que de conclure "terminé".
- **Messages de commit qui expliquent le "pourquoi"/la cause racine**, pas
  juste "quoi" a changé — cohérent sur l'ensemble des 33 commits, à
  poursuivre (ex: "storage.upload() n'a aucun timeout, donc une connexion
  qui stalle bloque l'écran indéfiniment" plutôt que "fix upload").
- **Rétrocompatibilité pensée à chaque nouvelle colonne/flux** : par
  exemple `compte_actif_publication` a été ajoutée sans casser les comptes
  propriétaires déjà existants. Se poser la question à chaque migration :
  "qu'arrive-t-il aux lignes déjà en base ?"
- **Réutiliser les patterns déjà en place plutôt que d'en inventer un
  nouveau** : `RealtimeTableMixin` centralise l'abonnement/désabonnement
  realtime (réservé aux écrans admin/ambassadeur, volontairement absent des
  listes publiques à fort trafic — voir CLAUDE.md) ; `PhotoViewerFullscreen`
  est partagé entre détail logement et détail article plutôt que dupliqué.

---

## 4. Check-list avant de considérer une tâche terminée

- [ ] `flutter analyze` propre sur les fichiers touchés (pas seulement
      "pas d'erreur" — relire aussi les nouveaux warnings).
- [ ] Chemin nominal *et* au moins un cas limite vérifiés manuellement si
      l'UI est concernée ; sinon le dire explicitement à l'utilisateur.
- [ ] Tout flux qui pose un statut "bloquant" a un chemin de retour, et ce
      chemin a été identifié explicitement (règle n°5 ci-dessus).
- [ ] Types passés aux filtres Supabase vérifiés (`int` vs `double`
      notamment).
- [ ] Aucune tentative de mise à jour d'une ligne appartenant à un autre
      utilisateur depuis le client (RLS).
- [ ] Appels réseau déclenchés par un bouton/slider/champ texte protégés
      contre les réponses hors-ordre et/ou debouncés si l'action peut se
      répéter rapidement.
- [ ] CLAUDE.md mis à jour si un écran, une table ou une convention a
      changé ; ce guide mis à jour si un nouveau piège générique a été
      découvert.

---

## 5. Où trouver quoi

| Document | Contenu |
|---|---|
| `CLAUDE.md` | Architecture, conventions de code obligatoires, structure des écrans, tables Supabase, temps réel |
| `Amelioration_Mboa_App.md` | Cahier des charges initial du projet (largement réalisé — référence historique de l'intention produit) |
| `COMPTES_TEST.md` | Comptes de test pour les différents rôles |
| `GUIDE_SESSIONS.md` (ce document) | Pièges récurrents et processus de travail, à enrichir à chaque session |
