-- Demande de réservation sur un hébergement. Mise en relation uniquement
-- (v1) : Mboa n'encaisse rien, l'établissement confirme/refuse et gère le
-- paiement lui-même. Machine à états modélisée sur verifications_terrain
-- (seul précédent réel dans ce projet d'un workflow d'approbation avec RLS
-- empêchant le demandeur de trancher lui-même un statut terminal).
create table public.reservations (
  id uuid primary key default extensions.uuid_generate_v4(),
  hebergement_id uuid not null references public.hebergements(id) on delete cascade,
  visiteur_id uuid not null references public.users(id) on delete cascade,
  proprietaire_id uuid not null references public.users(id) on delete cascade,
  date_debut date not null,
  date_fin date not null check (date_fin > date_debut),
  nb_personnes integer not null default 1,
  message text,
  statut text not null default 'en_attente'
    check (statut = any (array['en_attente'::text,'confirmee'::text,'refusee'::text,'annulee'::text])),
  date_reponse timestamptz,
  created_at timestamptz not null default now()
);

create index reservations_hebergement_idx on public.reservations (hebergement_id);
create index reservations_visiteur_idx on public.reservations (visiteur_id);
create index reservations_proprietaire_idx on public.reservations (proprietaire_id);
create index reservations_statut_idx on public.reservations (statut);

alter table public.reservations enable row level security;

-- proprietaire_id vérifié contre le vrai propriétaire de l'hébergement
-- (empêche un visiteur de spoofer la cible de sa demande).
create policy "Visiteur cree une demande de reservation" on public.reservations
  for insert
  with check (
    visiteur_id = auth.uid()
    and statut = 'en_attente'
    and proprietaire_id = (select proprietaire_id from public.hebergements where id = hebergement_id)
  );

create policy "Visiteur lit ses reservations" on public.reservations
  for select using (visiteur_id = auth.uid());

create policy "Proprietaire lit les reservations de ses hebergements" on public.reservations
  for select using (proprietaire_id = auth.uid());

create policy "Admin lit toutes les reservations" on public.reservations
  for select using (is_admin());

-- Le visiteur ne peut qu'annuler, et seulement depuis en_attente.
create policy "Visiteur annule sa reservation" on public.reservations
  for update
  using (visiteur_id = auth.uid() and statut = 'en_attente')
  with check (visiteur_id = auth.uid() and statut = 'annulee');

-- Le propriétaire ne peut que confirmer/refuser, et seulement depuis
-- en_attente — jamais trancher en_attente -> en_attente à répétition ni
-- revenir sur une décision déjà prise.
create policy "Proprietaire repond a une reservation" on public.reservations
  for update
  using (proprietaire_id = auth.uid() and statut = 'en_attente')
  with check (proprietaire_id = auth.uid() and statut = any (array['confirmee'::text,'refusee'::text]));

create policy "Admin gere les reservations" on public.reservations
  for all using (is_admin()) with check (is_admin());

create or replace function public.horodater_reponse_reservation()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.statut in ('confirmee','refusee') and old.statut is distinct from new.statut then
    new.date_reponse := now();
  end if;
  return new;
end;
$function$;

create trigger trg_horodater_reponse_reservation
  before update of statut on public.reservations
  for each row execute function public.horodater_reponse_reservation();
