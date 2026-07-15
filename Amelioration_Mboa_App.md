				AMÉLIORATION DE Mboa App

	1- Déconnexion
le bouton se déconnecter doit permettre une déconnexion sécurisée et rapide de l'application avec possibilité de permettre à un autre utilisateur de se connecter sans soucis. Car actuellement on doit cliquer deux fois sur se déconnecter et valider deux fois pour vraiment se déconnecter cela doit être fait proprement !
Travail à faire : permettre une décoonnexion propre et sécurisé de l'application.

	2- Connexion
- le bouton se souvenir de moi ne conserve que l'email et ne conserve pas le mot de passe. il doit pouvoir conserver et le mot de passe ainsi que l'adresse mail pour une connexion rapide afin d'améliorer l'expérience utilisateur.
- Etre rediriger directement sur l'interface du compte utilisateur connecté une fois qu'on a terminer l'inscription avec Google qui marche super bien, sauf qu'une fois de retour sur l'application est tape encore sur se connecter avant que la page s'ouvre naturellement sans besoin d'entrer quoi que ce soit.
- coder la page de mot de passe oublié et vérifié avec un processus complet de réinitialisation de mot de passe que tu vas tester sur mon téléphone après.

	3- Home
- Activer la barre de recherche sur la section hero et faire fonctionner les différents filtres de façon optimale pour tout filtrer. la barre de recherche doit doit permettre une recherche instantanée en entrant des caractères ça doit déjà afficher les articles et biens immobiliers correspondants aux caractères saisies.
- Actviver les boutons Logement et Market sur la section Explorée pour qu'il renvoit respectivement aux onglets Logement et Market comme le bouton Carte permet de voir la carte.
- Activer les liens voir plus des zones d'affichage des logements et des articles.
- Les cartes d'affichages de logement doivent afficher les logements avec le même design d'affichage des articles plus bas et permettre un affichage verticale sur colonne proportionnelle à la taille de l'écran et non afficher sur l'horizontal comme maintenant. Plus l'écran est petit plus le nombre de colonnes d'affichage diminue et inversement plus la taille de l'écran est grand plus le nombre de colonnes d'affichages augmente.
- Activer le bouton de notifications qui est sur la section hero
- Activer la section trouve ton Mboa pour qu'il puisse présenter les Mboa les plus proches de l'endroit où se trouve la personne en captant sa géolocalisation, le résultat doit afficher des logements filtrés par rapport à sa position ou bien s'il n'est pas dans la ville de sangmelima on lui propose de choisir un lieu et de voir l'ensemble des Mboa proches de ce lieu comme par exemple il peut choisir un campus et là on lui affiche les Mboa qui sont autour de ce lieu précis question d'affiner sa recherche cette section d'affichage des logements est différentes de la section mère parce qu'elle présente déjà des logements sur la base du lieu choisit par l'étudiant ou le visiteur et aussi dans cette politique d'affichage sont mis en avant les logements booster, mieux notés etc... Mais la priorité est donnée au logement proche de cette zone et aussi il peut affiner le rayon au km à la ronde du lieu choisit.
- afficher les contributeurs de Mboa : une liste des profils des propriétaires et vendeurs de Mboa classé selon les critères suivant : son mis en avant les contributeurs certifiés, ayant un nombre d'étoiles élevés, ayant un grand nombre d'articles soumis dans la Market...etc. Et mettre un lien voir plus qui affiche tous les contributeurs avec possibilités de filtrer et rechercher un contributeur en particulier !

	4- Logement
Le problème actuel de cette page est qu'elle ne charge aucun logement présent dans la base de données. Donc il faut revoir les appels en base de données qui sont faites par l'application afin de retrouver ce qui bloque l'affichage des logements. L'affichage des cartes de logements doit respecter les principes déjà défini plus haut.
La zone de recherche et des filtres doivent être optimisé comme décrit en amont.

	4.1 - Détail d'un logement
- Défilemment automatique des images du logement en fonction d'une période de temps défini
- Possibilité de cliquer sur la zone des images pour bien voir les images et en glissant du haut vers le bas on puisse refermer l'image et continuer à inspecter les détails sans aucun soucis.
- Rendre possible la notation et l'avis du visiteur connecter sur un bien dont il regarde les détails. Il lit les avis existant sur le bien et leur note et à la possibilité de noter et rédiger un avis : la noter (nombre d'étoiles) est afficher directement dans le scrore total d'étoile du bien tandis que l'avis rédiger est soumis au propriétaire qui peut décider de la rendre public avant qu'elle n'apparaisse publiquement ou bien la supprimer pour éviter qu'elle n'apparaisse. un avis qui n'a pas été supprimé après 72h est publié automatiquement et pourra toujours être supprimer par le propriétaire à tout moment.
- lorsqu'on signal un bien le signalement doit être véritablement envoyer à l'administrateur qui peux disposer des privilèges nécessaires pour suspendre temporairement l'article et contacter son propriétaire ou bien le supprimer de l'application en envoyant un message au propriétaire lui indiquant les raisons de la suspension ou de la suppression de l'annonce de l'application.
- pouvoir cliquer sur le profil d'un propriétaire comme c'est déjà le cas avec les profils des vendeurs cotés articles et voir le profil du propriétaire afin de renforcer la confiance. Sur tous les profils des contributeurs on pourra choisir de leur donner une étoile qui est une façon de mieux les classer dans la liste des contributeurs sur la Home page de l'application.
- rendre le bouton appeler actif et permettre qu'il affiche le numéro de téléphone renseigner par le propriétaire avec une option lancer l'appel qui ouvre directement l'application d'appel du téléphone de la personne.

	5. Market
La taille des cartes des articles doit être la même en longueur (hauteur) et en largeur. le nom ou titre de l'article doit tenir sur une ligne, l'état de l'article sur la ligne qui suit, puis le prix sur la ligne qui suit, le nom du prorpiétaire sur la suivante et enfin le bouton contacter doit être placer dans la carte et non exterieur à la carte comme actuellement et un espace doit être respecté entre les cartes de chaque article. Et tout comme avec les cartes des logements le nombre de colonnes d'affichage doit varier avec la taille de l'écran de l'appareil. deux colonnes pour les pétits écrans et plus pour les grands écrans.
la barre de recherche doit être optimisée comme décrit plus haut.

	5.1 détails d'un article
- Permettre de voir l'image en grand en cliquant deçu
- Les images de l'article doivent défiler à intervalle de temps régulier
- La possibilité de noter un article et de donner son avis lorsque que le vendeur à donner la possibilité de noter un article pour les articles vendues en séries par exemple et ne pas donner la possibilité de donner un avis pour les articles uniques par exemple qui sont vendus puis rétirer de l'application par le vendeur.
- lorsqu'un visiteur like un article son like doit être pris en compte et ajoute l'article dans la liste de ses favoris et cela est valable pour les logements.

	5.2 - Profil vendeur
Lorsqu'on visite actuellement le profil d'un vendeur on voit des informations génériques qui ne sont pas celles qui sont liées à la personne. Chaque information liées au profil doit pouvoir provenir de la base de données. On doit avoir une phot de profil du vendeur et une photo de couverture du vendeur qui doivent s'afficher. Toutes les notes, statistiques affichées doivent être vraies. On doit pouvoir cliquer sur chacune des ses photos pour bien le voir. une photo de profil peut être le logo de la boite de la personne, sa propre photo et la photo de couverture une image de son local par exemple.
-Les boutons Annonces et Avis sont mélangés dans la section héro et se retrouve collé. Il faut les séparer afin de rendre bien visible ces boutons.
- Rendre cliquable la zone emplacement boutique et ouvrir la carte pour voir l'itinéraire jusqu'à la boutique lorsque le vendeur à au préalable renseigner ses coordonnées de sa boutique et si il ne l'a pas fait on renvoie un chaleureux message poli et courtois indiquant que l'emplacement n'a pas été défini par le commerçant.
- les artciles du vendeur doivent s'afficher avec toutes leur informations y compris avec les images qui y vont avec exactement comme s'affichent dans la Market.
- un client bien-sur donne ou non une étoile au profil pour le classement côté affichage des contributeurs sur la Home page.
- Tous les avis affichés doivent être les avis qui ont été fait envers le propriétaire. Ce sont les avis qui sont donnés lors des conversations qui s'affichent à ce niveau ce qui est différents des avis fait pour un article ou un logement bien évidemment !!
- Et bien évidemment ces améliorations concernent tous les profils des contributeurs : propriétaires ou vendeurs de l'application.

	6. Chat
- La liste des conversations doit en plus d'afficher le nom mais aussi afficher le titre de l'article ou du logement en référence pour faciliter et aider la recherche d'une conversation lorsque le fil de discussion devient trop long.
- permettre de filtrer les conversations par type de biens : logement(puis filtrer ses sous catégories ensuite) ou articles(avec filtre en plus sur les sous catégories), par date aussi etc.. afin de faciliter à l'utilisateur de retrouver rapidement une conversation sans devoir se perdre dans le flux des échanges.
- à l'interieur d'une conversation on doit pouvoir revoir le nom du bien et non juste voir sa catégorie comme actuellement où c'est écrit article ou logement au lieu d'écrire le nom ou le titre exacte du bien en question. il faut aussi ajouter un lien vers l'article pour pouvoir le voir et revenir directement dans la conversation dès qu'on clique sur le bouton retour du téléphone. cela est valable avec les conversations avec un propriétaire de logement.
- une conversation apparait dans la liste des conversations uniquement quand l'un à envoyer un message à l'autre c'est-à-dire que lorsque l'échange de message a été établit.
- actuellement la chronologie d'affichage des messages dans une conversations en mal orientée. Les messages anciens sont mis en avant comme s'il venait d'être envoyés alors que les nouveaux messages sont mis vers le haut de la conversation comme s'ils ont été envoyé depuis. Donc c'est un leger détail à corriger absolument.

	7. Profil
- Possibilité de mettre une photo de profil pour tout le monde et une photo de couverture lorsqu'on ait contributeur.
- Favoris, Alertes et Messages doivent collecter les vraies données liées au compte et non des données génériques.
- rendre vivante les alertes de recherches dans toutes l'application.
- mettre un lien devenir contributeur qui permet à un visiteur connecter ou un étudiant à devenir soit propriétaire soit vendeur pour les étudiants qui vendent des articles en ligne à leur camarade de classe. Il soumet le formulaire à l'administrateur et ce dernier est chargé d'analyser sa demande et de modifier son type de compte pour le faire passer au compte client sans avoir besoin de lui donner un nouveau mot de passe.
- mettre un lien aussi pour un commerçant/vendeur qui veut publier des annonces de logement en ajoutant à son compte la possibilité de publier et les logements et les articles conformement a la section ci-dessous sur la contrainte de publication des produits logements et articles dans l'application.

	8. Publier
- Donner la possibilité de recevoir des avis sur un article qui sera vendu en série ou de ne pas donner
- Définir sa position en entrant des coordonnées qui permettent d'avoir des données sur la distance entre nous et l'endroit où se trouve le bien.
- Lorsqu'on veut publier un logement on doit avoir une liste d'endroit publier sur la carte et cliquer sur les endroits publics en question afin d'afficher le logement avec les distances exactement par rapport à un lieu donné comme le campus, un centre de santé en gros avec les noms exacte avec lesquels ces lieux ont été enregstré dans la carte par l'administrateur
- Les contributeurs doivent effectuer un CRUD complet sur leur produit.
- Un contributeur qui est vendeur n'a pas droit d'avoir la section publier un logement il a droit uniquement a voir la section qui concerne les articles et pareilles pour un propriétaire de logement il ne doit pas voir la zone de publication des articles seulement les contributeurs dont le compte a été créé avec la double identité propriétaire et vendeur peut avoir ses deux options de publications. Car actuellement on a des contributeurs qui peuvent être des commerçants qui ont des biens immobiliers(logements) qu'ils veulenet aussi mettre en location. Donc un contributeur doit voir la liste de produits et effectuer un CRUD complet sur chacun d'eux. 

	9. Annonces
Remplacer cet onglet par l'onglet gestion qui permet de gerer les produits de chaque contributeur en fonction de leur sous rôle défini à la céation de leur compte.
Par contre les liens actuels du Home comme les voir plus permettent d'afficher correctement les logements, articles et contributeurs comme s'est le cas pour les visiteurs/étudiants.
