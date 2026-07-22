-- conversations.non_lu n'est initialisé qu'à la création de la conversation
-- ({participant: 0, ...}) et n'était ensuite jamais mis à jour nulle part :
-- ni trigger serveur, ni écriture côté client dans _envoyerMessage(). Le
-- compteur reste donc à 0 pour toujours, quel que soit le nombre réel de
-- messages non lus — bug silencieux (aucune erreur, juste un badge qui
-- n'apparaît jamais) qui touche tous les écrans qui affichent ce compteur
-- (chat_screen, profil_screen, et les badges nav/cloche ajoutés le 22/07).
--
-- Incrémente non_lu[destinataire] pour chaque participant autre que
-- l'expéditeur à chaque nouveau message. SECURITY DEFINER : le trigger
-- doit pouvoir modifier la ligne conversations quel que soit l'appelant,
-- même si RLS restreint normalement les UPDATE inter-utilisateurs (voir
-- GUIDE_SESSIONS.md, piège n°3 — ici c'est le cas légitime où le serveur,
-- pas le client, doit faire cette écriture).
create or replace function public.incrementer_non_lu_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  conv record;
  destinataire uuid;
  nouveau_non_lu jsonb;
begin
  select participants, non_lu into conv
  from public.conversations
  where id = new.conversation_id;

  nouveau_non_lu := coalesce(conv.non_lu, '{}'::jsonb);

  foreach destinataire in array conv.participants loop
    if destinataire <> new.expediteur_id then
      nouveau_non_lu := jsonb_set(
        nouveau_non_lu,
        array[destinataire::text],
        to_jsonb(coalesce((nouveau_non_lu ->> destinataire::text)::int, 0) + 1)
      );
    end if;
  end loop;

  update public.conversations
  set non_lu = nouveau_non_lu
  where id = new.conversation_id;

  return new;
end;
$$;

drop trigger if exists trg_incrementer_non_lu on public.messages;
create trigger trg_incrementer_non_lu
after insert on public.messages
for each row execute function public.incrementer_non_lu_message();

-- Remet non_lu[utilisateur_courant] à 0 quand il ouvre/lit une
-- conversation. RPC plutôt qu'un UPDATE direct du JSON côté client : évite
-- de lire-modifier-écrire toute la map (risque d'écraser un incrément
-- concurrent d'un message qui vient d'arriver), et vérifie que l'appelant
-- est bien participant avant d'écrire.
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
    and auth.uid() = any(participants);
end;
$$;

grant execute on function public.marquer_conversation_lue(uuid) to authenticated;
