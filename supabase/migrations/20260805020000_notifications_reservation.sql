-- Notifications in-app pour le cycle de vie d'une réservation, sur le
-- modèle de notifier_nouvel_avis_inapp.
alter table public.notifications drop constraint notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array['message'::text,'avis'::text,'annonce'::text,'demande'::text,'signalement'::text,'parrainage'::text,'reservation'::text]));

create or replace function public.notifier_nouvelle_reservation_inapp()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_visiteur_nom text;
  v_titre_hebergement text;
begin
  select nom into v_visiteur_nom from public.users where id = new.visiteur_id;
  select titre into v_titre_hebergement from public.hebergements where id = new.hebergement_id;
  insert into public.notifications (user_id, type, titre, corps, lien)
  values (
    new.proprietaire_id,
    'reservation',
    '📅 Nouvelle demande de réservation',
    coalesce(v_visiteur_nom, 'Un visiteur') || ' souhaite réserver « ' || coalesce(v_titre_hebergement, 'votre hébergement') || ' »',
    '/vendeur/reservations'
  );
  return new;
end;
$function$;

create trigger trg_notifier_nouvelle_reservation_inapp
  after insert on public.reservations
  for each row execute function public.notifier_nouvelle_reservation_inapp();

create or replace function public.notifier_reponse_reservation_inapp()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_titre_hebergement text;
begin
  if new.statut in ('confirmee','refusee') and old.statut is distinct from new.statut then
    select titre into v_titre_hebergement from public.hebergements where id = new.hebergement_id;
    insert into public.notifications (user_id, type, titre, corps, lien)
    values (
      new.visiteur_id,
      'reservation',
      case when new.statut = 'confirmee' then '✅ Réservation confirmée' else '❌ Réservation refusée' end,
      '« ' || coalesce(v_titre_hebergement, 'Votre demande') || ' »',
      '/profil/reservations'
    );
  end if;
  return new;
end;
$function$;

create trigger trg_notifier_reponse_reservation_inapp
  after update of statut on public.reservations
  for each row execute function public.notifier_reponse_reservation_inapp();
