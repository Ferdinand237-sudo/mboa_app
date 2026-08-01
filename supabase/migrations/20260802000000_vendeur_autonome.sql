-- Inscription vendeur autonome : le candidat crée directement son compte
-- (email + mot de passe, comme un étudiant) et choisit lui-même sa ville et
-- sa catégorie d'activité au moment de la demande, au lieu de laisser
-- l'admin inventer un mot de passe et re-choisir les permissions à la main.
-- L'admin n'a plus qu'à lire puis valider en un clic (catégorie et ville
-- pré-remplies, toujours modifiables avant validation) — voir
-- HISTORIQUE_PROJET_MBOA.md.
--
-- Le mot de passe ne transite jamais par ces tables : il passe par
-- supabase.auth.signUp(), exactement comme register/etudiant. Chaque
-- demande a donc systématiquement un user_id (plus de branche "nouveau
-- compte" avec mot de passe choisi par l'admin, la mise à niveau de
-- compte existant devient le seul chemin pour les nouvelles demandes).

alter table public.demandes_compte
  add column if not exists ville text,
  add column if not exists sous_roles_demandees text[];

-- Ville déclarée par le vendeur à l'inscription : sert de repli quand le
-- GPS est indisponible (logement) ou n'existe pas (article, aucune
-- position captée) — la détection GPS au moment de publier reste
-- prioritaire quand elle est disponible, voir publier_screen.dart /
-- form-logement.tsx / form-article.tsx.
alter table public.users
  add column if not exists ville text;
