-- Portage mobile de l'Assistant Mboa (chat_screen.dart) : en l'implémentant
-- côté client, on a vérifié que 20260726000000_assistant_mboa.sql (écrite
-- la veille de la refonte des rôles superposables, PR #28 du 27/07) a le
-- même oubli déjà rencontré sur lieux_publics (voir HISTORIQUE_PROJET_MBOA.md
-- §4.9 et §5bis) : ses 4 policies RLS et le fallback de notification
-- utilisent encore `role = 'admin'` en dur au lieu de `is_admin()`. Un
-- compte admin par privilège superposé (`est_admin = true`, role toujours
-- 'visiteur'/'vendeur') ne voyait donc aucune conversation Assistant Mboa,
-- ni en RLS ni dans la notification de repli tant qu'aucun admin n'a
-- répondu — probablement la cause du "l'assistant ne s'affiche pas".

drop policy if exists "Admins voient les conversations assistant" on public.conversations;
create policy "Admins voient les conversations assistant"
  on public.conversations for select
  using (is_support and public.is_admin());

drop policy if exists "Admins mettent à jour les conversations assistant" on public.conversations;
create policy "Admins mettent à jour les conversations assistant"
  on public.conversations for update
  using (is_support and public.is_admin());

drop policy if exists "Admins voient les messages assistant" on public.messages;
create policy "Admins voient les messages assistant"
  on public.messages for select
  using (exists (
    select 1 from public.conversations c
    where c.id = messages.conversation_id and c.is_support and public.is_admin()
  ));

drop policy if exists "Admins marquent lus les messages assistant" on public.messages;
create policy "Admins marquent lus les messages assistant"
  on public.messages for update
  using (exists (
    select 1 from public.conversations c
    where c.id = messages.conversation_id and c.is_support and public.is_admin()
  ));

-- Même correctif pour le repli "personne assigné -> notifier tous les
-- admins" (voir 20260726010000_fix_notif_message_support.sql).
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
      from public.users where role = 'admin' or est_admin = true;
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

-- `marquer_conversation_lue` (20260722120000_non_lu_messages.sql) exige
-- `auth.uid() = any(participants)` : jamais vrai pour un admin sur une
-- conversation Assistant Mboa (participants ne contient que l'étudiant),
-- donc l'appel mobile existant échouait silencieusement (UPDATE sans
-- ligne trouvée) pour tout admin ouvrant le chat support.
create or replace function public.marquer_conversation_lue(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
  set non_lu = jsonb_set(coalesce(non_lu, '{}'::jsonb), array[auth.uid()::text], '0'::jsonb)
  where id = p_conversation_id
    and (auth.uid() = any(participants) or (is_support and public.is_admin()));
end;
$$;
