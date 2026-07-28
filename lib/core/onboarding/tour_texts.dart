import 'tour_step.dart';

// Textes des visites guidées — portage fidèle de
// mboa-web/src/components/onboarding/tours.ts. Les cibles (GlobalKey) sont
// fournies par chaque écran (main_screen.dart, publier_screen.dart,
// gestion_screen.dart) via [buildTourSteps].

// Visiteur non connecté sur l'accueil : découverte complète, jusqu'à
// l'inscription. Seule visite lancée automatiquement (une fois), voir
// tourAutoOpenKey dans main_screen.dart.
const tourHomeVisiteurTexts = [
  TourStepText(
    title: '🧭 Ton guide, toujours là',
    body: "Retrouve ce bouton à tout moment pour relancer cette visite guidée si tu as besoin d'un rappel.",
  ),
  TourStepText(
    title: 'Bienvenue sur Mboa 👋',
    body: "Ton premier ami dans une nouvelle ville. Fais un tour rapide pour découvrir comment ça marche, ça prend 30 secondes.",
  ),
  TourStepText(
    title: '🔍 Cherche un logement',
    body: 'Tape ce que tu cherches — chambre, studio, meublé — pour lancer une recherche en un instant.',
  ),
  TourStepText(
    title: '🏠 Logement',
    body: "Trouve un logement avant même d'arriver à Sangmelima : photos, prix, commerces et équipements autour.",
  ),
  TourStepText(
    title: '🛒 Market',
    body: 'Achète ou vends du matériel entre étudiants : lits, bureaux, livres, électroménager...',
  ),
  TourStepText(
    title: '🗺️ Carte',
    body: "Repère les logements, le campus, l'hôpital et le marché directement sur la carte.",
  ),
  TourStepText(
    title: '📍 Trouve ton Mboa',
    body: "Une des sections les plus puissantes : trouve vite les logements autour de ta position ou d'un lieu que tu choisis (campus, marché...).",
  ),
  TourStepText(
    title: '💬 Chat',
    body: "Discute en direct avec les propriétaires et les vendeurs, dès que tu as un compte.",
  ),
  TourStepText(
    title: 'Crée ton compte',
    body: "Inscris-toi gratuitement pour débloquer le détail des annonces, le chat et les avis. On y va ?",
  ),
];

// Visiteur inscrit (étudiant connecté) sur l'accueil : pas de rappel
// d'inscription, mais notifications + profil en plus.
const tourHomeEtudiantTexts = [
  TourStepText(
    title: '🧭 Ton guide, toujours là',
    body: "Retrouve ce bouton à tout moment pour relancer cette visite guidée si tu as besoin d'un rappel.",
  ),
  TourStepText(
    title: 'Content de te revoir 👋',
    body: 'Petit rappel de ce que tu peux faire sur Mboa, ça prend 30 secondes.',
  ),
  TourStepText(
    title: '🔍 Cherche un logement',
    body: 'Tape ce que tu cherches — chambre, studio, meublé — pour lancer une recherche en un instant.',
  ),
  TourStepText(
    title: '🏠 Logement',
    body: 'Consulte le détail des annonces, les avis et les commerces autour de chaque logement.',
  ),
  TourStepText(
    title: '🛒 Market',
    body: 'Achète ou vends du matériel entre étudiants : lits, bureaux, livres, électroménager...',
  ),
  TourStepText(
    title: '🗺️ Carte',
    body: "Repère les logements, le campus, l'hôpital et le marché directement sur la carte.",
  ),
  TourStepText(
    title: '📍 Trouve ton Mboa',
    body: "Une des sections les plus puissantes : trouve vite les logements autour de ta position ou d'un lieu que tu choisis (campus, marché...).",
  ),
  TourStepText(
    title: '💬 Chat',
    body: 'Discute en direct avec les propriétaires et les vendeurs, retrouve toutes tes conversations ici.',
  ),
  TourStepText(
    title: '🔔 Notifications',
    body: "Sois averti dès qu'on te répond ou qu'une nouvelle annonce peut t'intéresser.",
  ),
  TourStepText(
    title: '👤 Ton profil',
    body: 'Retrouve tes favoris, tes avis et les informations de ton compte.',
  ),
];

// Vendeur / propriétaire sur l'accueil : navigation dédiée (Gestion,
// Publier, Messages).
const tourHomeVendeurTexts = [
  TourStepText(
    title: 'Bienvenue dans ton espace vendeur 👋',
    body: 'Voici comment gérer tes annonces et discuter avec tes clients depuis Mboa.',
  ),
  TourStepText(
    title: '📋 Mes annonces',
    body: 'Retrouve, modifie, suspends ou supprimes tous tes logements et articles publiés.',
  ),
  TourStepText(
    title: '➕ Publier',
    body: 'Ajoute un nouveau logement ou article en quelques minutes.',
  ),
  TourStepText(
    title: '💬 Messages',
    body: 'Réponds directement aux étudiants intéressés par tes annonces.',
  ),
  TourStepText(
    title: '👤 Ton profil',
    body: 'Vérifie ton badge de certification, tes informations et ta note moyenne.',
  ),
];

// Écran Publier : prise en main du formulaire.
const tourPublierTexts = [
  TourStepText(
    title: '➕ Bienvenue sur Publier',
    body: "Remplis ce formulaire pour mettre en ligne un logement ou un article. Il sera visible par tous les étudiants après vérification.",
  ),
  TourStepText(
    title: "Choisis le type d'annonce",
    body: 'Bascule entre Logement et Article selon ce que tu veux publier.',
  ),
  TourStepText(
    title: '📷 Ajoute de bonnes photos',
    body: 'Des photos nettes et représentatives donnent bien plus envie de contacter — privilégie la lumière du jour.',
  ),
  TourStepText(
    title: '📍 Active ta position',
    body: "Elle permet d'afficher automatiquement le campus, l'hôpital et le marché les plus proches sur l'annonce.",
  ),
  TourStepText(
    title: '🚀 Envoie ton annonce',
    body: 'Une fois envoyée, elle est vérifiée puis publiée automatiquement. Suis son statut dans Mes annonces.',
  ),
];

// Écran Gestion / Mes annonces : prise en main de la liste et des actions
// sur une annonce.
const tourGestionTexts = [
  TourStepText(
    title: '📋 Bienvenue dans Gestion',
    body: 'Retrouve ici toutes tes annonces publiées, logements et articles réunis au même endroit.',
  ),
  TourStepText(
    title: 'Logements / Articles',
    body: 'Bascule entre tes deux catégories d\'annonces.',
  ),
  TourStepText(
    title: 'Chaque annonce en un coup d\'œil',
    body: 'Le badge indique si elle est Disponible ou Suspendue, et son état de vérification si besoin.',
  ),
  TourStepText(
    title: 'Modifier, suspendre, supprimer',
    body: 'Trois actions rapides sur chaque annonce : modifie les infos, suspends-la temporairement ou supprime-la.',
  ),
];
