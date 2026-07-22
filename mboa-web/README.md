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

L'ensemble des écrans de l'app Flutter est reproduit côté web, connecté à la
même base Supabase :

- **Public / visiteur** — accueil, logements (liste + détail), marketplace
  (liste + détail), profil public vendeur, recherche instantanée
  (`/recherche`), liste des contributeurs (`/contributeurs`), carte
  interactive OpenStreetMap avec regroupement en clusters (`/carte`,
  `/carte/autour`)
- **Auth** — connexion, inscription étudiant, inscription commerçant/
  propriétaire, mot de passe oublié/réinitialisation
- **Espace étudiant connecté** — profil (favoris, alertes de recherche,
  devenir contributeur, avis à modérer, notifications, modification du
  profil), messagerie temps réel (`/chat`, Supabase Realtime)
- **Espace vendeur** — publier une annonce (logement/article, upload
  photos, position GPS, modération IA), gestion des annonces, modification
  logement/article
- **Espace admin** (`/admin`) — dashboard, utilisateurs, annonces,
  signalements, demandes Pro, vérifications terrain
- **Espace ambassadeur** (`/ambassadeur`) — dashboard, propriétaires
  assignés, formulaire de visite terrain
- **Limite visiteur** : un visiteur non connecté ne voit que 4 annonces par
  liste (`PAGE_SIZE_VISITEUR`, même règle que le mobile) avec une bannière
  d'invitation à se connecter
- Toutes les pages de liste/détail sont rendues côté serveur (SSR) pour le
  référencement (`generateMetadata` par annonce)

## Ce qui n'est PAS encore fait

- Pas de tests automatisés
- Regroupement de marqueurs uniquement sur `/carte` (pas de clustering
  ailleurs, ça n'a pas de sens ailleurs de toute façon)
- Le brouillon hors-ligne du formulaire de visite ambassadeur (pensé pour
  le terrain sans réseau côté mobile) n'a pas d'équivalent web fiable :
  l'envoi échoue simplement avec un message si la connexion coupe pendant
  l'envoi, à réessayer manuellement

## Note sur le détail des annonces et les visiteurs non connectés

Le CLAUDE.md du dépôt mobile précise qu'un visiteur non inscrit "ne peut pas
voir le détail d'une annonce". Sur le web, ce choix a été volontairement
assoupli : le détail (photos, description, équipements) reste visible sans
compte — c'est tout l'intérêt du SEO — mais le bouton de contact est
gated derrière la connexion. À ajuster si vous préférez un comportement
strictement identique au mobile.

## Déploiement

Le projet est déployé sur Vercel (équipe **Teka3**, projet **mboa-web**),
connecté au dépôt GitHub `Ferdinand237-sudo/mboa_app`. Chaque merge sur
`main` déclenche automatiquement un build + déploiement en production —
plus besoin de déployer manuellement.

### Réglages du projet Vercel

Le dépôt contient à la fois l'app Flutter (racine) et l'app web
(`mboa-web/`), donc trois réglages sont indispensables dans
**Settings → Build and Deployment** et **Settings → Environments →
Production** du projet Vercel :

- **Root Directory** : `mboa-web` (sinon Next.js ne trouve pas de dossier
  `app/` à la racine du dépôt et le build échoue avec `Couldn't find any
  pages or app directory`)
- **Production Branch** : `main`
- **Environment Variables** (Production, et idéalement Preview/
  Development aussi) :
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`

  (voir `.env.local.example` pour les valeurs du projet Supabase actuel)

### Images distantes autorisées (`next.config.ts`)

`next/image` bloque tout domaine non listé dans `images.remotePatterns`.
Les photos en base viennent de deux origines (vérifié en SQL sur les
tables `logements`, `articles`, `users.photo_url`, `users.photo_commerce`) :
Supabase Storage (`vodmsndqahmxdsqpayrd.supabase.co`) et des photos de
démo Unsplash (`images.unsplash.com`). Si un nouveau domaine de photos
apparaît un jour (ex. changement de bucket, nouvelles photos de seed), il
faudra l'ajouter ici — sans ça, les images de ce domaine retombent
silencieusement sur le repli 🏠 et cassent la mise en page des cartes.

### Incidents rencontrés au premier déploiement (2026-07-22)

Deux bugs ont bloqué le tout premier déploiement automatique après
connexion de Vercel à GitHub, tous deux diagnostiqués via
`get_runtime_errors`/`get_deployment_build_logs` (MCP Vercel) :

1. **Build en échec, dossier `app` introuvable** — le Root Directory du
   projet Vercel n'était pas configuré sur `mboa-web` (déploiements
   précédents faits manuellement en CLI depuis ce dossier, donc jamais
   remarqué). Fix : réglage Root Directory ci-dessus.
2. **Site déployé mais aucune donnée nulle part** (`getHomeLogements`,
   `getArticles`, etc. en erreur silencieuse) — l'erreur runtime exacte :
   `TypeError: Cannot convert argument to a ByteString because the
   character at index 8 has a value of 8226 which is greater than 255`.
   Le caractère 8226 est `•` (point de masquage) : la valeur collée dans
   `NEXT_PUBLIC_SUPABASE_ANON_KEY` sur le dashboard Vercel contenait un
   caractère parasite (interférence probable avec un gestionnaire de mots
   de passe du navigateur au moment du collage), invalide comme valeur
   d'en-tête HTTP (`apikey`/`Authorization`) envoyé par le client
   Supabase. Fix : supprimer la variable et la recréer en collant la
   valeur directement, sans passer par un champ pré-rempli.

Après ces deux correctifs, troisième déploiement automatique (suite au
merge de la PR ajoutant `images.unsplash.com`) : propre, `0` erreur
runtime, données et images affichées normalement.
