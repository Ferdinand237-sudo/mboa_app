-- Réservation d'hébergements (hôtels, motels, auberges, appartements
-- meublés). Une ligne = une chambre/suite/appartement réservable, pas un
-- établissement : l'identité de l'établissement (nom, façade, description)
-- réutilise nom_commerce/description_commerce/photo_commerce/
-- emplacement_commerce déjà présents sur users (même rôle que pour un
-- commercant aujourd'hui). Colonnes alignées sur logements/articles pour
-- réutiliser tout le pattern de publication/modération existant.
create table public.hebergements (
  id uuid primary key default extensions.uuid_generate_v4(),
  titre text not null,
  description text not null default '',
  type_etablissement text not null
    check (type_etablissement = any (array['hotel'::text,'motel'::text,'auberge'::text,'appart_hotel'::text,'residence_meublee'::text])),
  capacite_personnes integer not null default 1,
  -- integer comme logements.prix/articles.prix (pas numeric : PostgREST
  -- sérialise numeric en string JSON pour préserver la précision, ce qui
  -- casserait les casts `as int` déjà utilisés côté client sur ce champ).
  prix integer not null,
  equipements text[] not null default '{}',
  photos text[] not null default '{}',
  statut text not null default 'disponible'
    check (statut = any (array['disponible'::text,'suspendu'::text])),
  statut_moderation text not null default 'en_attente'
    check (statut_moderation = any (array['en_attente'::text,'publie'::text,'a_verifier'::text,'bloque'::text])),
  adresse_approx text,
  quartier text,
  ville text not null default 'Sangmelima',
  lat double precision,
  lng double precision,
  proprietaire_id uuid not null references public.users(id) on delete cascade,
  boosted boolean not null default false,
  vues integer not null default 0,
  signalements integer not null default 0,
  date_publication timestamptz not null default now()
);

alter table public.hebergements enable row level security;

create policy "Hebergements visibles par tous" on public.hebergements
  for select using (true);

create policy "Vendeur publie ses hebergements" on public.hebergements
  for insert with check (auth.uid() = proprietaire_id);

create policy "Vendeur modifie ses hebergements" on public.hebergements
  for update using (auth.uid() = proprietaire_id);

create policy "Admin modifie tous les hebergements" on public.hebergements
  for update using (is_admin());

create policy "Vendeur supprime ses hebergements" on public.hebergements
  for delete using (auth.uid() = proprietaire_id);

create policy "Admin supprime tous les hebergements" on public.hebergements
  for delete using (is_admin());

-- ── Bucket photos (public, même pattern que logements/articles) ────
insert into storage.buckets (id, name, public)
values ('hebergements', 'hebergements', true)
on conflict (id) do nothing;

create policy "Photos hebergements publiques" on storage.objects
  for select using (bucket_id = 'hebergements');

create policy "Vendeur upload photo hebergement" on storage.objects
  for insert with check (
    bucket_id = 'hebergements'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "User gere ses propres fichiers hebergements" on storage.objects
  for update using (
    bucket_id = 'hebergements'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "User supprime ses propres fichiers hebergements" on storage.objects
  for delete using (
    bucket_id = 'hebergements'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── Vues (RPC dédiée, même pattern que increment_vues_logement) ────
create or replace function public.increment_vues_hebergement(p_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.hebergements set vues = coalesce(vues, 0) + 1 where id = p_id;
$$;

grant execute on function public.increment_vues_hebergement(uuid) to anon, authenticated;

-- ── Modération IA (mirroir du pattern logements/articles) ──────────
create or replace function public.proteger_colonnes_confiance_hebergements()
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
end;
$function$;

create trigger trg_proteger_colonnes_confiance_hebergements
  before update on public.hebergements
  for each row execute function public.proteger_colonnes_confiance_hebergements();

create trigger trg_moderer_nouvel_hebergement
  after insert on public.hebergements
  for each row execute function public.moderer_nouvelle_annonce();

alter table public.moderation_ia drop constraint moderation_ia_annonce_type_check;
alter table public.moderation_ia add constraint moderation_ia_annonce_type_check
  check (annonce_type = any (array['logement'::text,'article'::text,'hebergement'::text]));

alter table public.image_hashes drop constraint image_hashes_annonce_type_check;
alter table public.image_hashes add constraint image_hashes_annonce_type_check
  check (annonce_type = any (array['logement'::text,'article'::text,'hebergement'::text]));
