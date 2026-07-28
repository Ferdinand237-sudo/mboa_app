-- Support multi-villes : Mboa ne couvrait que Sangmelima jusqu'ici (centre
-- de carte, détection GPS et libellés codés en dur côté mobile ET web).
-- Cette migration fait de la liste des villes couvertes une donnée gérable
-- par un admin (nouvelle ville sans republication de l'app), au lieu d'une
-- constante dans le code des deux plateformes.

-- ── Table de référence des villes ────────────────────────────
create table if not exists public.villes (
  id uuid default uuid_generate_v4() primary key,
  nom text not null unique,
  lat double precision not null,
  lng double precision not null,
  rayon_couverture_km double precision not null default 30,
  actif boolean not null default true,
  ordre_affichage integer not null default 0,
  created_at timestamp with time zone default now()
);

alter table public.villes enable row level security;

-- Lecture publique : même un visiteur non connecté doit voir la liste des
-- villes couvertes (sélecteur d'accueil, repli GPS hors zone).
-- drop if exists avant chaque create : rend le script rejouable tel quel
-- si une exécution précédente s'est arrêtée en cours de route.
drop policy if exists "Tout le monde peut voir les villes" on public.villes;
create policy "Tout le monde peut voir les villes" on public.villes
  for select using (true);

-- Écriture réservée à l'admin, via is_admin() (couvre role='admin' ET le
-- privilège superposable est_admin) et non un check role='admin' brut —
-- voir plus bas pour lieux_publics qui avait cet oubli.
drop policy if exists "Admin gere les villes" on public.villes;
create policy "Admin gere les villes" on public.villes
  for all using (public.is_admin()) with check (public.is_admin());

-- Coordonnées de centre-ville approximatives, ajustables ensuite depuis
-- l'écran admin sans nouvelle migration.
insert into public.villes (nom, lat, lng, rayon_couverture_km, ordre_affichage) values
  ('Sangmelima', 2.9333, 11.9833, 30, 1),
  ('Kribi', 2.95, 9.91, 30, 2),
  ('Ébolowa', 2.90, 11.15, 30, 3)
on conflict (nom) do nothing;

-- ── lieux_publics : ajout de la ville ────────────────────────
-- Nullable pour ne rien casser entre le déploiement de cette migration et
-- celui de l'app qui commence à la renseigner ; backfill défensif des
-- lieux existants, tous réellement à Sangmelima.
alter table public.lieux_publics add column if not exists ville text;
update public.lieux_publics set ville = 'Sangmelima' where ville is null;

-- Correctif au passage : ces 4 policies utilisaient encore role = 'admin'
-- en dur, jamais migrées vers is_admin() lors de la refonte des rôles
-- superposables (voir HISTORIQUE_PROJET_MBOA.md §4.9) — un admin
-- est_admin-only ne pouvait donc pas gérer les lieux publics. Corrigé ici
-- car cette migration touche déjà lieux_publics.
drop policy if exists "Seul un admin peut ajouter des lieux" on public.lieux_publics;
drop policy if exists "Seul un admin peut modifier des lieux" on public.lieux_publics;
drop policy if exists "Seul un admin peut supprimer des lieux" on public.lieux_publics;
drop policy if exists "Admin ajoute des lieux" on public.lieux_publics;
drop policy if exists "Admin modifie des lieux" on public.lieux_publics;
drop policy if exists "Admin supprime des lieux" on public.lieux_publics;

create policy "Admin ajoute des lieux" on public.lieux_publics
  for insert with check (public.is_admin());

create policy "Admin modifie des lieux" on public.lieux_publics
  for update using (public.is_admin());

create policy "Admin supprime des lieux" on public.lieux_publics
  for delete using (public.is_admin());

-- ── Backfill défensif logements/articles ─────────────────────
-- logements.ville était toujours écrite en dur à 'Sangmelima' côté client.
-- articles.ville n'existait même pas en base : le code qui la lit
-- (article_detail_screen.dart) l'a toujours lue absente/null en silence,
-- aucune colonne ne l'ayant jamais portée — vérifié après l'échec de ce
-- backfill sur la première exécution de cette migration (colonne
-- inexistante). Toutes les annonces existantes sont réellement à
-- Sangmelima (seule ville couverte jusqu'ici).
alter table public.articles add column if not exists ville text;
update public.logements set ville = 'Sangmelima' where ville is null or ville = '';
update public.articles set ville = 'Sangmelima' where ville is null or ville = '';
