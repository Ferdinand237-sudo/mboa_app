-- Partie 1 — Modération par intelligence artificielle
-- Tables de résultats de modération, colonne statut_moderation sur les annonces,
-- et trigger d'appel de l'Edge Function moderate-annonce (même pattern que
-- notifier_nouvelle_annonce() déjà en place sur logements/articles).

-- ── Tables ──────────────────────────────────────────────────
create table public.moderation_ia (
  id uuid primary key default extensions.uuid_generate_v4(),
  annonce_id uuid not null,
  annonce_type text not null check (annonce_type = any (array['logement'::text, 'article'::text])),
  risk_score integer not null default 0,
  decision text not null check (decision = any (array['publie'::text, 'a_verifier'::text, 'bloque'::text])),
  fraud_match boolean not null default false,
  fraud_match_annonce_id uuid,
  categories jsonb not null default '{}'::jsonb,
  erreur text,
  created_at timestamp with time zone not null default now()
);

create index moderation_ia_annonce_idx on public.moderation_ia (annonce_id, annonce_type);

create table public.image_hashes (
  id uuid primary key default extensions.uuid_generate_v4(),
  annonce_id uuid not null,
  annonce_type text not null check (annonce_type = any (array['logement'::text, 'article'::text])),
  vendeur_id uuid not null references public.users(id) on delete cascade,
  image_url text not null,
  hash text not null,
  created_at timestamp with time zone not null default now()
);

create index image_hashes_vendeur_idx on public.image_hashes (vendeur_id);
create index image_hashes_annonce_idx on public.image_hashes (annonce_id, annonce_type);

alter table public.moderation_ia enable row level security;
alter table public.image_hashes enable row level security;

-- Lecture réservée à l'admin ; seule l'Edge Function (clé service_role,
-- qui contourne RLS) écrit dans ces deux tables.
create policy "Admin lit moderation_ia" on public.moderation_ia
  for select using (public.is_admin());

create policy "Admin lit image_hashes" on public.image_hashes
  for select using (public.is_admin());

-- ── Colonne statut_moderation ──────────────────────────────
-- Défaut 'publie' à l'ajout de colonne : les annonces déjà en ligne restent
-- visibles rétroactivement. On bascule ensuite le défaut sur 'en_attente'
-- pour que toute nouvelle annonce parte en attente d'analyse IA.
alter table public.logements
  add column statut_moderation text not null default 'publie'
  check (statut_moderation = any (array['en_attente'::text, 'publie'::text, 'a_verifier'::text, 'bloque'::text]));
alter table public.logements alter column statut_moderation set default 'en_attente';

alter table public.articles
  add column statut_moderation text not null default 'publie'
  check (statut_moderation = any (array['en_attente'::text, 'publie'::text, 'a_verifier'::text, 'bloque'::text]));
alter table public.articles alter column statut_moderation set default 'en_attente';

create index logements_statut_moderation_idx on public.logements (statut_moderation);
create index articles_statut_moderation_idx on public.articles (statut_moderation);

-- ── Fix : autoriser le service_role à écrire les colonnes protégées ──
-- proteger_colonnes_confiance_* resette silencieusement certaines colonnes
-- si l'appelant n'est pas admin. auth.uid() est vide pour les appels
-- service_role (Edge Functions), donc is_admin() y est toujours faux :
-- sans ce correctif, l'Edge Function ne pourrait ni écrire
-- statut_moderation, ni incrémenter signalements. Effet de bord positif :
-- corrige aussi l'incrémentation de "signalements" par un signalement
-- utilisateur classique (logement_service.dart / article_service.dart),
-- qui était jusqu'ici silencieusement annulée par ce même trigger.
create or replace function public.proteger_colonnes_confiance_logements()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or auth.role() = 'service_role') then
    new.boosted := old.boosted;
    new.vues := old.vues;
    new.signalements := old.signalements;
    new.note_globale := old.note_globale;
    new.nb_avis := old.nb_avis;
    new.statut_moderation := old.statut_moderation;
  end if;
  return new;
end; $function$;

create or replace function public.proteger_colonnes_confiance_articles()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or auth.role() = 'service_role') then
    new.boosted := old.boosted;
    new.vues := old.vues;
    new.signalements := old.signalements;
    new.statut_moderation := old.statut_moderation;
  end if;
  return new;
end; $function$;

-- ── Trigger d'appel de l'Edge Function moderate-annonce ────────────
-- Même pattern que public.notifier_nouvelle_annonce().
create or replace function public.moderer_nouvelle_annonce()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  perform net.http_post(
    url := 'https://vodmsndqahmxdsqpayrd.supabase.co/functions/v1/moderate-annonce',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object('table', TG_TABLE_NAME, 'record', to_jsonb(new))
  );
  return new;
end;
$function$;

create trigger trg_moderer_nouveau_logement after insert on public.logements
  for each row execute function public.moderer_nouvelle_annonce();

create trigger trg_moderer_nouvel_article after insert on public.articles
  for each row execute function public.moderer_nouvelle_annonce();
