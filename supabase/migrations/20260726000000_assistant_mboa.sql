-- Assistant Mboa : chaque compte non-admin reçoit une conversation support
-- (participants = [user_id] uniquement — pas d'admin fixe, l'identité
-- "Assistant Mboa" est virtuelle côté UI). Elle est visible dans la liste de
-- TOUS les admins tant qu'aucun n'a répondu ; dès qu'un admin répond, on
-- fige assigned_admin_id sur cette conversation et elle disparaît de la
-- liste des autres admins (même conversation, mêmes messages, pas de
-- duplication).

alter table public.conversations
  add column is_support boolean not null default false,
  add column assigned_admin_id uuid references public.users(id);

-- RLS : les policies existantes (auth.uid() = any(participants)) ne
-- couvrent pas les admins, qui ne sont jamais dans participants pour une
-- conversation support. Policies dédiées, restreintes aux lignes support.
create policy "Admins voient les conversations assistant"
  on public.conversations for select
  using (is_support and exists (select 1 from public.users where id = auth.uid() and role = 'admin'));

create policy "Admins mettent à jour les conversations assistant"
  on public.conversations for update
  using (is_support and exists (select 1 from public.users where id = auth.uid() and role = 'admin'));

create policy "Admins voient les messages assistant"
  on public.messages for select
  using (exists (
    select 1 from public.conversations c
    join public.users u on u.id = auth.uid()
    where c.id = messages.conversation_id and c.is_support and u.role = 'admin'
  ));

create policy "Admins marquent lus les messages assistant"
  on public.messages for update
  using (exists (
    select 1 from public.conversations c
    join public.users u on u.id = auth.uid()
    where c.id = messages.conversation_id and c.is_support and u.role = 'admin'
  ));

-- Nouveau compte (hors admin) -> conversation Assistant Mboa automatique.
create or replace function public.creer_conversation_assistant_mboa()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.role <> 'admin' then
    insert into public.conversations (participants, is_support, non_lu)
    values (array[new.id], true, '{}'::jsonb);
  end if;
  return new;
end;
$$;

create trigger trg_creer_conversation_assistant_mboa
after insert on public.users
for each row execute function public.creer_conversation_assistant_mboa();

-- Backfill : comptes déjà existants sans conversation Assistant Mboa.
insert into public.conversations (participants, is_support, non_lu)
select array[u.id], true, '{}'::jsonb
from public.users u
where u.role <> 'admin'
and not exists (
  select 1 from public.conversations c
  where c.is_support and c.participants = array[u.id]
);

-- Compteur de non-lus : pour une conversation support, participants ne
-- contient que l'étudiant (pas d'admin fixe). Message de l'étudiant ->
-- incrémente le compteur de l'admin assigné, ou une clé collective
-- 'non_assigne' tant que personne n'a répondu (portée par tous les admins
-- dans la liste, jusqu'à ce que l'un d'eux réponde). Message d'un admin ->
-- incrémente le compteur de l'étudiant, comme une conversation normale.
create or replace function public.incrementer_non_lu_message()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  conv record;
  destinataire uuid;
  nouveau_non_lu jsonb;
  cle text;
begin
  select participants, non_lu, is_support, assigned_admin_id into conv
  from public.conversations
  where id = new.conversation_id;

  nouveau_non_lu := coalesce(conv.non_lu, '{}'::jsonb);

  if conv.is_support then
    if new.expediteur_id = conv.participants[1] then
      cle := coalesce(conv.assigned_admin_id::text, 'non_assigne');
      nouveau_non_lu := jsonb_set(
        nouveau_non_lu, array[cle],
        to_jsonb(coalesce((nouveau_non_lu ->> cle)::int, 0) + 1)
      );
    else
      nouveau_non_lu := jsonb_set(
        nouveau_non_lu, array[conv.participants[1]::text],
        to_jsonb(coalesce((nouveau_non_lu ->> conv.participants[1]::text)::int, 0) + 1)
      );
    end if;
  else
    foreach destinataire in array conv.participants loop
      if destinataire <> new.expediteur_id then
        nouveau_non_lu := jsonb_set(
          nouveau_non_lu, array[destinataire::text],
          to_jsonb(coalesce((nouveau_non_lu ->> destinataire::text)::int, 0) + 1)
        );
      end if;
    end loop;
  end if;

  update public.conversations set non_lu = nouveau_non_lu where id = new.conversation_id;
  return new;
end;
$function$;
