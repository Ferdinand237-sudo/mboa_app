-- Complète 20260726000000_assistant_mboa.sql : le trigger in-app
-- (notifications, cloche du header) avait le même trou que l'edge function
-- send-notification pour les messages envoyés par l'étudiant vers Assistant
-- Mboa (participants ne contient que lui, donc la boucle "quelqu'un d'autre
-- que l'expéditeur" ne trouvait jamais personne à notifier).
create or replace function public.notifier_nouveau_message_inapp()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_participants uuid[];
  v_destinataire uuid;
  v_expediteur_nom text;
  v_is_support boolean;
  v_assigned_admin_id uuid;
begin
  select participants, is_support, assigned_admin_id
    into v_participants, v_is_support, v_assigned_admin_id
  from public.conversations where id = new.conversation_id;
  select nom into v_expediteur_nom from public.users where id = new.expediteur_id;

  if v_is_support and new.expediteur_id = v_participants[1] then
    if v_assigned_admin_id is not null then
      insert into public.notifications (user_id, type, titre, corps, lien)
      values (v_assigned_admin_id, 'message', coalesce(v_expediteur_nom, 'Nouveau message') || ' (Assistant Mboa)', new.texte, '/chat/' || new.conversation_id);
    else
      insert into public.notifications (user_id, type, titre, corps, lien)
      select id, 'message', coalesce(v_expediteur_nom, 'Nouveau message') || ' (Assistant Mboa)', new.texte, '/chat/' || new.conversation_id
      from public.users where role = 'admin';
    end if;
    return new;
  end if;

  foreach v_destinataire in array coalesce(v_participants, array[]::uuid[]) loop
    if v_destinataire <> new.expediteur_id then
      insert into public.notifications (user_id, type, titre, corps, lien)
      values (v_destinataire, 'message', coalesce(v_expediteur_nom, 'Nouveau message'), new.texte, '/chat/' || new.conversation_id);
    end if;
  end loop;
  return new;
end;
$function$;
