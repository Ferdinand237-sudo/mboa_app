# Mboa Web

Version web de Mboa — Next.js 16 (App Router) + TypeScript + Tailwind CSS 4,
branchée sur le **même projet Supabase** que l'app mobile Flutter
(`../lib`). Les deux clients lisent/écrivent les mêmes tables
(`users`, `logements`, `articles`, ...), donc une annonce publiée depuis
l'app mobile apparaît immédiatement sur le web et inversement.

## Pourquoi une app séparée (et pas Flutter Web) ?

Choix délibéré : Flutter Web est mal indexé par les moteurs de recherche
(rendu client-only) et garde un feel "app mobile" même sur grand écran. Pour
qu'un étudiant qui tape "logement étudiant Sangmelima" sur Google tombe sur
une annonce Mboa, il fallait du vrai SSR/SEO — d'où Next.js.

## Stack

- **Next.js 16** (App Router, Turbopack, React 19)
- **TypeScript** strict
- **Tailwind CSS 4** (tokens de couleur portés depuis
  `lib/core/theme/app_theme.dart` — `MboaColors`/`MboaSizes`)
- **@supabase/ssr** pour l'auth cookie-based côté serveur (Server Components,
  Route Handlers) + client navigateur
- Police **Poppins** via `next/font/google`, comme dans l'app Flutter

## Démarrer en local

```bash
cd mboa-web
cp .env.local.example .env.local   # déjà pré-rempli avec le projet Supabase de l'app
npm install
npm run dev
```

## Ce qui est fait

- **Accueil** (`/`) — hero, recherche, logements et articles récents
- **Logements** (`/logements`, `/logements/[id]`) — liste avec filtres
  (type, prix, recherche texte), détail avec galerie/équipements/règles
- **Marketplace** (`/marketplace`, `/marketplace/[id]`) — idem pour les
  articles (catégorie, état)
- **Auth** (`/login`, `/register`) — connexion et inscription étudiant via
  Supabase Auth (email/mot de passe), miroir de `auth_service.dart`
- **Profil** (`/profil`) — infos du compte connecté, déconnexion
- **Limite visiteur** : un visiteur non connecté ne voit que 4 annonces par
  liste (`PAGE_SIZE_VISITEUR`, même règle que le mobile) avec une bannière
  d'invitation à se connecter
- Toutes les pages de liste/détail sont rendues côté serveur (SSR) pour le
  référencement (`generateMetadata` par annonce)

## Ce qui n'est PAS encore fait (prochaines étapes suggérées)

- **Chat** : pas de messagerie web pour l'instant — la fiche annonce invite
  à contacter via l'app mobile. Implémenter la messagerie temps réel
  (Supabase Realtime, comme `chat_screen.dart`) est le chantier suivant le
  plus utile.
- **Publication d'annonces** (vendeur) — `publier_screen.dart` n'a pas
  d'équivalent web
- **Espace admin / ambassadeur** — resté mobile-only pour l'instant
- **Favoris, avis, carte OSM** — non portés
- Pas de tests automatisés

## Note sur le détail des annonces et les visiteurs non connectés

Le CLAUDE.md du dépôt mobile précise qu'un visiteur non inscrit "ne peut pas
voir le détail d'une annonce". Sur le web, ce choix a été volontairement
assoupli : le détail (photos, description, équipements) reste visible sans
compte — c'est tout l'intérêt du SEO — mais le bouton de contact est
gated derrière la connexion. À ajuster si vous préférez un comportement
strictement identique au mobile.

## Déploiement

Le projet est un Next.js standard, déployable tel quel sur Vercel (ou tout
hébergeur Node). Il suffit de renseigner les variables d'environnement
`NEXT_PUBLIC_SUPABASE_URL` et `NEXT_PUBLIC_SUPABASE_ANON_KEY` (voir
`.env.local.example`) dans la configuration de la plateforme cible.
