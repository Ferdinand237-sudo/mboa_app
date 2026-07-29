-- Phase 2 de la stratégie de croissance : parrainage à crédits/paliers
-- (mboa-web uniquement pour cette expérimentation, voir
-- HISTORIQUE_PROJET_MBOA.md). Décisions actées avec Ferdinand :
--   - Un seul niveau de parrainage : le parrain n'est jamais crédité pour
--     les filleuls de son filleul (pas de cascade -> pas de dérive vers un
--     schéma pyramidal).
--   - Le crédit ne se déclenche qu'après une action réelle du filleul
--     (premier message envoyé, ou première annonce publiée pour un
--     vendeur), jamais à la simple inscription -> limite la création de
--     faux comptes pour farmer des crédits.
--   - Les crédits ne débloquent que du boost (visibilité). La certification
--     (badge Vérifié) reste toujours décidée par un admin, jamais achetée.

-- ── Paliers ──────────────────────────────────────────────────────────────
-- Table de config plutôt que des seuils codés en dur : un admin doit
-- pouvoir les ajuster sans redéploiement (comme public.villes).
create table public.paliers_parrainage (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  icone text not null default '⭐',
  seuil_credits integer not null,
  ordre integer not null,
  created_at timestamptz not null default now()
);

alter table public.paliers_parrainage enable row level security;

create policy "Lecture publique des paliers de parrainage"
  on public.paliers_parrainage for select
  using (true);

create policy "Admin gère les paliers de parrainage"
  on public.paliers_parrainage for all
  using (public.is_admin())
  with check (public.is_admin());

insert into public.paliers_parrainage (nom, icone, seuil_credits, ordre) values
  ('Débrouillard(e)', '🌱', 0, 1),
  ('Connecteur du Quartier', '🔌', 50, 2),
  ('Grand du Mboa', '⭐', 150, 3),
  ('Chef de Quartier', '👑', 350, 4),
  ('Ambassadeur Mboa', '🏆', 500, 5)
on conflict do nothing;

-- Renvoie le palier le plus élevé atteint pour un nombre de crédits donné.
create or replace function public.palier_pour_credits(p_credits integer)
returns table (nom text, icone text, seuil_credits integer, ordre integer)
language sql
stable
set search_path to 'public'
as $$
  select nom, icone, seuil_credits, ordre from public.paliers_parrainage
  where seuil_credits <= p_credits
  order by seuil_credits desc
  limit 1;
$$;

-- ── Colonnes de parrainage sur users ─────────────────────────────────────
alter table public.users
  add column if not exists code_parrainage text,
  add column if not exists parrain_id uuid references public.users(id),
  add column if not exists credits_parrainage integer not null default 0;

-- Backfill déterministe à partir de l'id (pas de boucle de retry
-- nécessaire : collision impossible tant que les uuid restent uniques).
update public.users
set code_parrainage = upper(substr(replace(id::text, '-', ''), 1, 8))
where code_parrainage is null;

alter table public.users alter column code_parrainage set not null;

create unique index if not exists users_code_parrainage_idx on public.users (code_parrainage);

-- Génère le code de tout nouveau compte automatiquement.
create or replace function public.generer_code_parrainage()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.code_parrainage is null then
    new.code_parrainage := upper(substr(replace(new.id::text, '-', ''), 1, 8));
  end if;
  return new;
end;
$$;

drop trigger if exists trg_generer_code_parrainage on public.users;
create trigger trg_generer_code_parrainage
before insert on public.users
for each row execute function public.generer_code_parrainage();

-- ── Suivi des parrainages ────────────────────────────────────────────────
-- Un filleul par ligne (unique sur filleul_id) : statut en_attente jusqu'à
-- ce qu'il réalise une action réelle, qui seule déclenche le crédit du
-- parrain (public.valider_parrainage_filleul).
create table public.parrainages (
  id uuid primary key default gen_random_uuid(),
  parrain_id uuid not null references public.users(id) on delete cascade,
  filleul_id uuid not null references public.users(id) on delete cascade unique,
  type_filleul text not null check (type_filleul in ('visiteur', 'vendeur')),
  credits_attribues integer not null default 0,
  statut text not null default 'en_attente' check (statut in ('en_attente', 'valide')),
  created_at timestamptz not null default now(),
  valide_at timestamptz
);

create index parrainages_parrain_id_idx on public.parrainages (parrain_id);

alter table public.parrainages enable row level security;

create policy "Parrain lit ses parrainages"
  on public.parrainages for select
  using (auth.uid() = parrain_id);

create policy "Admin lit tous les parrainages"
  on public.parrainages for select
  using (public.is_admin());

-- Pas de policy insert/update pour les utilisateurs : uniquement écrit par
-- les fonctions security definer ci-dessous, jamais directement par le
-- client (empêche un utilisateur de s'auto-créditer).

-- Enregistre un parrainage en attente lorsqu'un compte est créé avec un
-- code de parrainage en métadonnée auth (raw_user_meta_data.code_parrain) :
-- signUp direct pour un étudiant/visiteur, ou create-vendor pour un
-- vendeur approuvé depuis une demande portant elle-même le code (voir
-- demandes_compte.code_parrain plus bas).
create or replace function public.enregistrer_parrainage()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_code text;
  v_parrain_id uuid;
begin
  select raw_user_meta_data ->> 'code_parrain' into v_code from auth.users where id = new.id;
  if v_code is null then
    return new;
  end if;

  select id into v_parrain_id from public.users
  where code_parrainage = upper(v_code) and id <> new.id;

  if v_parrain_id is null then
    return new;
  end if;

  update public.users set parrain_id = v_parrain_id where id = new.id;

  insert into public.parrainages (parrain_id, filleul_id, type_filleul)
  values (v_parrain_id, new.id, case when new.role = 'vendeur' then 'vendeur' else 'visiteur' end)
  on conflict (filleul_id) do nothing;

  return new;
end;
$$;

drop trigger if exists trg_enregistrer_parrainage on public.users;
create trigger trg_enregistrer_parrainage
after insert on public.users
for each row execute function public.enregistrer_parrainage();

-- ── Validation + crédit ──────────────────────────────────────────────────
-- Notifie et crédite le parrain une fois que son filleul a réalisé une
-- action réelle. No-op silencieux si aucun parrainage en attente (permet
-- d'appeler cette fonction sans condition depuis plusieurs triggers).
create or replace function public.valider_parrainage_filleul(p_filleul_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_parrainage public.parrainages%rowtype;
  v_credits integer;
  v_credits_avant integer;
  v_credits_apres integer;
  v_palier_avant text;
  v_palier_apres text;
begin
  select * into v_parrainage from public.parrainages
  where filleul_id = p_filleul_id and statut = 'en_attente';

  if not found then
    return;
  end if;

  v_credits := case v_parrainage.type_filleul when 'vendeur' then 30 else 10 end;

  select credits_parrainage into v_credits_avant from public.users where id = v_parrainage.parrain_id;
  v_credits_apres := v_credits_avant + v_credits;

  update public.parrainages
  set statut = 'valide', credits_attribues = v_credits, valide_at = now()
  where id = v_parrainage.id;

  update public.users set credits_parrainage = v_credits_apres where id = v_parrainage.parrain_id;

  select nom into v_palier_avant from public.palier_pour_credits(v_credits_avant);
  select nom into v_palier_apres from public.palier_pour_credits(v_credits_apres);

  insert into public.notifications (user_id, type, titre, corps, lien)
  values (
    v_parrainage.parrain_id,
    'parrainage',
    '🎉 +' || v_credits || ' crédits de parrainage',
    'Un(e) ' || (case v_parrainage.type_filleul when 'vendeur' then 'vendeur' else 'étudiant(e)' end)
      || ' que tu as invité(e) est maintenant actif(ve) sur Mboa.',
    '/parrainage'
  );

  if v_palier_apres is distinct from v_palier_avant then
    insert into public.notifications (user_id, type, titre, corps, lien)
    values (
      v_parrainage.parrain_id,
      'parrainage',
      '🏅 Nouveau palier débloqué : ' || v_palier_apres,
      'Continue à inviter pour aller encore plus loin !',
      '/parrainage'
    );
  end if;
end;
$$;

-- Déclencheurs de validation : premier message envoyé (couvre tous les
-- types de filleuls) et première annonce publiée (couvre spécifiquement le
-- cas vendeur, qui peut ainsi être crédité même sans avoir encore
-- envoyé de message). valider_parrainage_filleul ne fait rien après la
-- première validation (plus de ligne 'en_attente'), donc pas besoin de
-- détecter explicitement "le premier" évènement.
create or replace function public.declencher_validation_parrainage_message()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.valider_parrainage_filleul(new.expediteur_id);
  return new;
end;
$$;

drop trigger if exists trg_valider_parrainage_message on public.messages;
create trigger trg_valider_parrainage_message
after insert on public.messages
for each row execute function public.declencher_validation_parrainage_message();

create or replace function public.declencher_validation_parrainage_logement()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.valider_parrainage_filleul(new.proprietaire_id);
  return new;
end;
$$;

drop trigger if exists trg_valider_parrainage_logement on public.logements;
create trigger trg_valider_parrainage_logement
after insert on public.logements
for each row execute function public.declencher_validation_parrainage_logement();

create or replace function public.declencher_validation_parrainage_article()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.valider_parrainage_filleul(new.vendeur_id);
  return new;
end;
$$;

drop trigger if exists trg_valider_parrainage_article on public.articles;
create trigger trg_valider_parrainage_article
after insert on public.articles
for each row execute function public.declencher_validation_parrainage_article();

-- ── Demande de compte vendeur : transporte le code jusqu'à create-vendor ──
-- Un vendeur ne s'inscrit pas directement (compte créé par un admin, voir
-- create-vendor) : le code capté à l'arrivée sur le site doit donc être
-- conservé sur la demande pour être repris à la création réelle du compte.
alter table public.demandes_compte add column if not exists code_parrain text;

-- ── Notifications : nouveau type 'parrainage' ────────────────────────────
alter table public.notifications drop constraint notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type in ('message', 'avis', 'annonce', 'demande', 'signalement', 'parrainage'));

-- ── Dépense de crédits : boost ───────────────────────────────────────────
create table public.credits_utilisations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  motif text not null,
  credits_depenses integer not null,
  annonce_type text,
  annonce_id uuid,
  created_at timestamptz not null default now()
);

alter table public.credits_utilisations enable row level security;

create policy "User lit ses utilisations de crédits"
  on public.credits_utilisations for select
  using (auth.uid() = user_id);

create policy "Admin lit toutes les utilisations de crédits"
  on public.credits_utilisations for select
  using (public.is_admin());

-- 50 crédits = 1 boost, appliqué immédiatement sans expiration (pas
-- d'infrastructure de tâche planifiée dans ce projet -- un boost à durée
-- limitée est laissé pour une itération future, voir
-- HISTORIQUE_PROJET_MBOA.md). Certification jamais concernée : reste
-- décidée par un admin uniquement.
create or replace function public.echanger_credits_boost(p_annonce_type text, p_annonce_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_cout constant integer := 50;
  v_credits integer;
  v_proprietaire uuid;
begin
  if p_annonce_type not in ('logement', 'article') then
    raise exception 'Type d''annonce invalide';
  end if;

  if p_annonce_type = 'logement' then
    select proprietaire_id into v_proprietaire from public.logements where id = p_annonce_id;
  else
    select vendeur_id into v_proprietaire from public.articles where id = p_annonce_id;
  end if;

  if v_proprietaire is distinct from auth.uid() then
    raise exception 'Cette annonce ne vous appartient pas';
  end if;

  select credits_parrainage into v_credits from public.users where id = auth.uid();

  if v_credits is null or v_credits < v_cout then
    raise exception 'Crédits insuffisants (% requis)', v_cout;
  end if;

  update public.users set credits_parrainage = credits_parrainage - v_cout where id = auth.uid();

  if p_annonce_type = 'logement' then
    update public.logements set boosted = true where id = p_annonce_id;
  else
    update public.articles set boosted = true where id = p_annonce_id;
  end if;

  insert into public.credits_utilisations (user_id, motif, credits_depenses, annonce_type, annonce_id)
  values (auth.uid(), 'boost', v_cout, p_annonce_type, p_annonce_id);
end;
$$;
