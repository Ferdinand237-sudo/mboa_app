export type TourStep = {
  target: string;
  title: string;
  body: string;
};

// Chaque target correspond à un attribut data-tour posé sur l'élément réel
// (header-client.tsx, hero-header.tsx, category-cards.tsx, pages
// vendeur/publier et vendeur/annonces). Une étape dont la cible n'existe
// pas pour le rôle/les permissions courants (onglet absent, formulaire
// différent...) est sautée automatiquement par GuidedTour plutôt que de
// bloquer la visite sur une bulle vide — voir guided-tour.tsx.

// Visiteur non connecté sur l'accueil : découverte complète, jusqu'à
// l'inscription. Seule étape lancée automatiquement (une fois) à l'arrivée,
// voir SEEN_KEY_HOME_VISITEUR dans tour-button.tsx.
export const TOUR_HOME_VISITEUR: TourStep[] = [
  {
    target: "logo",
    title: "Bienvenue sur Mboa 👋",
    body: "Ton premier ami dans une nouvelle ville. Fais un tour rapide pour découvrir comment ça marche, ça prend 30 secondes.",
  },
  {
    target: "recherche",
    title: "🔍 Cherche un logement",
    body: "Tape ce que tu cherches — chambre, studio, meublé — pour lancer une recherche en un instant.",
  },
  {
    target: "nav-logements",
    title: "🏠 Logement",
    body: "Trouve un logement avant même d'arriver à Sangmelima : photos, prix, commerces et équipements autour.",
  },
  {
    target: "nav-marketplace",
    title: "🛒 Market",
    body: "Achète ou vends du matériel entre étudiants : lits, bureaux, livres, électroménager...",
  },
  {
    target: "cat-carte",
    title: "🗺️ Carte",
    body: "Repère les logements, le campus, l'hôpital et le marché directement sur la carte.",
  },
  {
    target: "nav-chat",
    title: "💬 Chat",
    body: "Discute en direct avec les propriétaires et les vendeurs, dès que tu as un compte.",
  },
  {
    target: "register",
    title: "Crée ton compte",
    body: "Inscris-toi gratuitement pour débloquer le détail des annonces, le chat et les avis. On y va ?",
  },
];

// Visiteur inscrit (étudiant connecté) sur l'accueil : pas de rappel
// d'inscription, mais notifications + profil en plus.
export const TOUR_HOME_ETUDIANT: TourStep[] = [
  {
    target: "logo",
    title: "Content de te revoir 👋",
    body: "Petit rappel de ce que tu peux faire sur Mboa, ça prend 30 secondes.",
  },
  {
    target: "recherche",
    title: "🔍 Cherche un logement",
    body: "Tape ce que tu cherches — chambre, studio, meublé — pour lancer une recherche en un instant.",
  },
  {
    target: "nav-logements",
    title: "🏠 Logement",
    body: "Consulte le détail des annonces, les avis et les commerces autour de chaque logement.",
  },
  {
    target: "nav-marketplace",
    title: "🛒 Market",
    body: "Achète ou vends du matériel entre étudiants : lits, bureaux, livres, électroménager...",
  },
  {
    target: "cat-carte",
    title: "🗺️ Carte",
    body: "Repère les logements, le campus, l'hôpital et le marché directement sur la carte.",
  },
  {
    target: "nav-chat",
    title: "💬 Chat",
    body: "Discute en direct avec les propriétaires et les vendeurs, retrouve toutes tes conversations ici.",
  },
  {
    target: "notifications",
    title: "🔔 Notifications",
    body: "Sois averti dès qu'on te répond ou qu'une nouvelle annonce peut t'intéresser.",
  },
  {
    target: "profil",
    title: "👤 Ton profil",
    body: "Retrouve tes favoris, tes avis et les informations de ton compte.",
  },
];

// Vendeur / propriétaire sur l'accueil : navigation dédiée (Mes annonces,
// Publier, Messages).
export const TOUR_HOME_VENDEUR: TourStep[] = [
  {
    target: "logo",
    title: "Bienvenue dans ton espace vendeur 👋",
    body: "Voici comment gérer tes annonces et discuter avec tes clients depuis Mboa.",
  },
  {
    target: "nav-vendeur/annonces",
    title: "📋 Mes annonces",
    body: "Retrouve, modifie, suspends ou supprimes tous tes logements et articles publiés.",
  },
  {
    target: "nav-vendeur/publier",
    title: "➕ Publier",
    body: "Ajoute un nouveau logement ou article en quelques minutes.",
  },
  {
    target: "nav-chat",
    title: "💬 Messages",
    body: "Réponds directement aux étudiants intéressés par tes annonces.",
  },
  {
    target: "profil",
    title: "👤 Ton profil",
    body: "Vérifie ton badge de certification, tes informations et ta note moyenne.",
  },
];

// Page Publier (publier_screen.dart) : prise en main du formulaire.
export const TOUR_PUBLIER: TourStep[] = [
  {
    target: "publier-hero",
    title: "➕ Bienvenue sur Publier",
    body: "Remplis ce formulaire pour mettre en ligne un logement ou un article. Il sera visible par tous les étudiants après vérification.",
  },
  {
    target: "publier-tabs",
    title: "Choisis le type d'annonce",
    body: "Bascule entre Logement et Article selon ce que tu veux publier.",
  },
  {
    target: "publier-photos",
    title: "📷 Ajoute de bonnes photos",
    body: "Des photos nettes et représentatives donnent bien plus envie de contacter — privilégie la lumière du jour.",
  },
  {
    target: "publier-gps",
    title: "📍 Active ta position",
    body: "Elle permet d'afficher automatiquement le campus, l'hôpital et le marché les plus proches sur l'annonce.",
  },
  {
    target: "publier-submit",
    title: "🚀 Envoie ton annonce",
    body: "Une fois envoyée, elle est vérifiée puis publiée automatiquement. Suis son statut dans Mes annonces.",
  },
];

// Page Gestion / Mes annonces (gestion_screen.dart) : prise en main de la
// liste et des actions sur une annonce.
export const TOUR_GESTION: TourStep[] = [
  {
    target: "gestion-hero",
    title: "📋 Bienvenue dans Gestion",
    body: "Retrouve ici toutes tes annonces publiées, logements et articles réunis au même endroit.",
  },
  {
    target: "gestion-tabs",
    title: "Logements / Articles",
    body: "Bascule entre tes deux catégories d'annonces.",
  },
  {
    target: "gestion-annonce",
    title: "Chaque annonce en un coup d'œil",
    body: "Le badge indique si elle est Disponible ou Suspendue, et son état de vérification si besoin.",
  },
  {
    target: "gestion-actions",
    title: "Modifier, suspendre, supprimer",
    body: "Trois actions rapides sur chaque annonce : modifie les infos, suspends-la temporairement ou supprime-la.",
  },
];
