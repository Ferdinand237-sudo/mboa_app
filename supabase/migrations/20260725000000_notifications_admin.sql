-- Étend le centre de notifications in-app (20260724000000) et le push FCM
-- mobile (send-notification, v5) aux évènements que l'admin doit voir :
-- nouvelle demande de compte, nouveau signalement (utilisateur ou détection
-- IA). Diffusion à tous les comptes role='admin', même mécanisme que les
-- notifications existantes (message/avis/annonce).

alter table public.notifications drop constraint notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type in ('message', 'avis', 'annonce', 'demande', 'signalement'));

-- In-app : nouvelle demande de compte -> tous les admins.
create or replace function public.notifier_admin_demande_compte_inapp()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.notifications (user_id, type, titre, corps, lien)
  select id, 'demande', '📨 Nouvelle demande de compte',
    new.nom || ' souhaite devenir ' || coalesce(new.type_activite, 'vendeur'),
    '/admin/demandes'
  from public.users where role = 'admin';
  return new;
end;
$$;

create trigger trg_notifier_admin_demande_compte_inapp
after insert on public.demandes_compte
for each row execute function public.notifier_admin_demande_compte_inapp();

-- Push FCM (mobile) : nouvelle demande de compte -> tous les admins.
create or replace function public.notifier_admin_demande_compte_push()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform net.http_post(
    url := 'https://vodmsndqahmxdsqpayrd.supabase.co/functions/v1/send-notification',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object('table', TG_TABLE_NAME, 'record', to_jsonb(new))
  );
  return new;
end;
$$;

create trigger trg_notifier_admin_demande_compte_push
after insert on public.demandes_compte
for each row execute function public.notifier_admin_demande_compte_push();

-- In-app : nouveau signalement (utilisateur ou détection IA) -> tous les
-- admins.
create or replace function public.notifier_admin_signalement_inapp()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_est_ia boolean := new.raison = 'detection_ia';
begin
  insert into public.notifications (user_id, type, titre, corps, lien)
  select id, 'signalement',
    case when v_est_ia then '🤖 Détection IA — annonce à vérifier' else '🚩 Nouveau signalement' end,
    coalesce(new.description, new.raison, 'À vérifier'),
    '/admin/signalements'
  from public.users where role = 'admin';
  return new;
end;
$$;

create trigger trg_notifier_admin_signalement_inapp
after insert on public.signalements
for each row execute function public.notifier_admin_signalement_inapp();

-- Push FCM (mobile) : nouveau signalement -> tous les admins.
create or replace function public.notifier_admin_signalement_push()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform net.http_post(
    url := 'https://vodmsndqahmxdsqpayrd.supabase.co/functions/v1/send-notification',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object('table', TG_TABLE_NAME, 'record', to_jsonb(new))
  );
  return new;
end;
$$;

create trigger trg_notifier_admin_signalement_push
after insert on public.signalements
for each row execute function public.notifier_admin_signalement_push();
