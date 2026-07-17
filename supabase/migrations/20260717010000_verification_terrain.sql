-- Partie 2 — Vérification terrain des propriétaires
-- Nouveau rôle ambassadeur, table verifications_terrain, journal d'accès
-- aux attestations, bucket sécurisé, et triggers qui superposent la
-- fonctionnalité sans modifier le code existant (create-vendor,
-- admin_demandes_screen) qui écrit déjà sur users.sous_roles.

-- ── Rôle ambassadeur ────────────────────────────────────────
alter table public.users drop constraint users_role_check;
alter table public.users add constraint users_role_check
  check (role = any (array['visiteur'::text, 'vendeur'::text, 'admin'::text, 'ambassadeur'::text]));

-- ── compte_actif_publication ───────────────────────────────
-- Défaut 'true' à l'ajout de colonne : les comptes propriétaires déjà
-- vérifiés/actifs ne sont pas bloqués rétroactivement. Le défaut bascule
-- ensuite à 'false' pour que tout nouveau compte doive passer par la
-- vérification terrain avant de publier un logement.
alter table public.users add column compte_actif_publication boolean not null default true;
alter table public.users alter column compte_actif_publication set default false;
update public.users set compte_actif_publication = true where 'proprietaire' = any(coalesce(sous_roles, '{}'));

-- ── verifications_terrain ──────────────────────────────────
create table public.verifications_terrain (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  ambassadeur_id uuid references public.users(id) on delete set null,
  demande_compte_id uuid references public.demandes_compte(id) on delete set null,
  statut text not null default 'en_attente_assignation'
    check (statut = any (array['en_attente_assignation'::text, 'assignee'::text, 'visite_effectuee'::text, 'validee'::text, 'rejetee'::text])),
  conformite_bien boolean,
  type_justificatif text,
  notes text,
  lat double precision,
  lng double precision,
  attestation_path text,
  date_assignation timestamp with time zone,
  date_visite timestamp with time zone,
  date_traitement timestamp with time zone,
  admin_id uuid references public.users(id) on delete set null,
  created_at timestamp with time zone not null default now()
);

create index verifications_terrain_user_idx on public.verifications_terrain (user_id);
create index verifications_terrain_ambassadeur_idx on public.verifications_terrain (ambassadeur_id);
create index verifications_terrain_statut_idx on public.verifications_terrain (statut);

alter table public.verifications_terrain enable row level security;

create policy "Admin gere verifications_terrain" on public.verifications_terrain
  for all using (public.is_admin()) with check (public.is_admin());

create policy "Ambassadeur lit ses verifications" on public.verifications_terrain
  for select using (ambassadeur_id = auth.uid());

-- L'ambassadeur ne peut jamais faire passer une visite à validee/rejetee :
-- ces statuts terminaux restent une décision admin exclusive.
create policy "Ambassadeur met a jour ses visites" on public.verifications_terrain
  for update
  using (ambassadeur_id = auth.uid())
  with check (ambassadeur_id = auth.uid() and statut <> all (array['validee'::text, 'rejetee'::text]));

-- ── attestations_acces_log ─────────────────────────────────
create table public.attestations_acces_log (
  id uuid primary key default extensions.uuid_generate_v4(),
  verification_id uuid not null references public.verifications_terrain(id) on delete cascade,
  consulte_par uuid not null references public.users(id) on delete cascade,
  consulte_le timestamp with time zone not null default now()
);

alter table public.attestations_acces_log enable row level security;

create policy "Admin lit attestations_acces_log" on public.attestations_acces_log
  for select using (public.is_admin());
-- Pas de policy insert pour anon/authenticated : seule l'Edge Function
-- get-attestation-url (clé service_role) écrit dans ce journal.

-- ── Protection de compte_actif_publication ─────────────────
-- La policy "Utilisateur modifie son propre profil" sur users n'a pas de
-- restriction par colonne : sans ce correctif, un propriétaire pourrait
-- s'auto-activer en appelant lui-même update users set
-- compte_actif_publication = true. Même garde que le correctif
-- statut_moderation de la Partie 1 (admin ou service_role uniquement).
create or replace function public.proteger_colonnes_confiance_users()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if pg_trigger_depth() <= 1 and not (public.is_admin() or auth.role() = 'service_role') then
    new.role := old.role;
    new.verified := old.verified;
    new.boosted := old.boosted;
    new.note_globale := old.note_globale;
    new.nb_avis := old.nb_avis;
    new.compte_actif_publication := old.compte_actif_publication;
  end if;
  return new;
end;
$function$;

-- ── Trigger : création automatique d'une vérification terrain ─────
-- Se déclenche sur toute écriture de sous_roles ajoutant 'proprietaire',
-- que ce soit via l'Edge Function create-vendor ou la mise à jour directe
-- dans admin_demandes_screen.dart — sans modifier ni l'un ni l'autre.
create or replace function public.creer_verification_terrain_si_proprietaire()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if 'proprietaire' = any(coalesce(new.sous_roles, '{}'))
     and not ('proprietaire' = any(coalesce(old.sous_roles, '{}')))
     and not exists (select 1 from public.verifications_terrain where user_id = new.id)
  then
    insert into public.verifications_terrain (user_id, statut)
    values (new.id, 'en_attente_assignation');
  end if;
  return new;
end;
$function$;

create trigger trg_creer_verification_terrain
  after update of sous_roles on public.users
  for each row execute function public.creer_verification_terrain_si_proprietaire();

-- ── Trigger : validation d'une visite active la publication ───────
create or replace function public.activer_publication_si_valide()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.statut = 'validee' and old.statut is distinct from 'validee' then
    update public.users set compte_actif_publication = true where id = new.user_id;
  end if;
  return new;
end;
$function$;

create trigger trg_activer_publication_si_valide
  after update of statut on public.verifications_terrain
  for each row execute function public.activer_publication_si_valide();

-- ── Bucket sécurisé pour les attestations ──────────────────
insert into storage.buckets (id, name, public)
values ('attestations-proprietaires', 'attestations-proprietaires', false)
on conflict (id) do nothing;

-- Volontairement : aucune policy admin directe sur ce bucket. La lecture
-- par un admin passe uniquement par l'Edge Function get-attestation-url
-- (clé service_role, qui journalise chaque accès dans
-- attestations_acces_log) — c'est le mécanisme d'audit demandé par le
-- cahier des charges, pas une simple RLS.
create policy "Ambassadeur televerse et consulte ses attestations" on storage.objects
  for all
  using (
    bucket_id = 'attestations-proprietaires'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (select 1 from public.users where id = auth.uid() and role = 'ambassadeur')
  )
  with check (
    bucket_id = 'attestations-proprietaires'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (select 1 from public.users where id = auth.uid() and role = 'ambassadeur')
  );
