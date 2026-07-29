-- Complète le système de notifications admin (§7bis, voir
-- HISTORIQUE_PROJET_MBOA.md) : Ferdinand a demandé qu'un admin soit
-- notifié (in-app + push, même app fermée) pour tout message, demande de
-- compte ou signalement, avec ouverture directe du bon écran au clic et
-- compteur qui se vide pour cette notification précise.
--
-- Deux manques trouvés en creusant :
-- 1. Même bug que lieux_publics/assistant_mboa (voir §5bis, §5quinquies) :
--    notifier_admin_demande_compte_inapp() et
--    notifier_admin_signalement_inapp() (20260725000000) diffusent encore
--    à `role = 'admin'` en dur, jamais migré vers le modèle de privilège
--    superposé (`est_admin`). Un admin est_admin-only ne recevait donc
--    aucune notification in-app pour ces deux évènements.
-- 2. Aucun trigger SQL n'appelle send-notification sur insert dans
--    messages (contrairement à demandes_compte/signalements, qui ont
--    chacun leur trigger `_push` explicite depuis le 25/07) alors que
--    l'Edge Function (gererNouveauMessage) sait déjà gérer ce cas,
--    Assistant Mboa compris — code mort faute de déclencheur. Ajouté ici,
--    même mécanique que les deux autres.
--
-- ⚠️ Si un Database Webhook (Dashboard > Database > Webhooks) existe déjà
-- sur `messages` vers send-notification, le supprimer après cette
-- migration pour éviter un double envoi du push.

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
  from public.users where role = 'admin' or est_admin = true;
  return new;
end;
$$;

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
  from public.users where role = 'admin' or est_admin = true;
  return new;
end;
$$;

-- Push FCM (mobile) : nouveau message -> l'autre participant, ou (Assistant
-- Mboa) l'admin assigné / tous les admins avec jeton tant que personne n'a
-- répondu. Toute la logique de routage vit déjà côté Edge Function
-- (gererNouveauMessage, send-notification/index.ts) ; ce trigger se
-- contente de la déclencher, comme pour demandes_compte/signalements.
create or replace function public.notifier_nouveau_message_push()
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

drop trigger if exists trg_notifier_nouveau_message_push on public.messages;
create trigger trg_notifier_nouveau_message_push
after insert on public.messages
for each row execute function public.notifier_nouveau_message_push();
