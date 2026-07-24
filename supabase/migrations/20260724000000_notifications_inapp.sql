-- Notifications in-app : miroir web du système de push FCM mobile
-- (lib/core/services/notification_service.dart, edge functions
-- send-notification / notifier-nouvelle-annonce). Les edge functions
-- envoient déjà le push FCM ; cette table alimente en plus un centre de
-- notifications consultable et temps réel côté web (et mobile plus tard si
-- besoin), pour les utilisateurs sans push actif ou en session navigateur.
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null check (type in ('message', 'avis', 'annonce')),
  titre text not null,
  corps text,
  lien text,
  lu boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_user_id_created_at_idx on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

create policy "User lit ses notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "User met à jour ses notifications"
  on public.notifications for update
  using (auth.uid() = user_id);

alter publication supabase_realtime add table public.notifications;

-- Nouveau message -> notification pour l'autre participant de la conversation.
create or replace function public.notifier_nouveau_message_inapp()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_participants uuid[];
  v_destinataire uuid;
  v_expediteur_nom text;
begin
  select participants into v_participants from public.conversations where id = new.conversation_id;
  select nom into v_expediteur_nom from public.users where id = new.expediteur_id;

  foreach v_destinataire in array coalesce(v_participants, array[]::uuid[]) loop
    if v_destinataire <> new.expediteur_id then
      insert into public.notifications (user_id, type, titre, corps, lien)
      values (v_destinataire, 'message', coalesce(v_expediteur_nom, 'Nouveau message'), new.texte, '/chat/' || new.conversation_id);
    end if;
  end loop;
  return new;
end;
$$;

create trigger trg_notifier_nouveau_message_inapp
after insert on public.messages
for each row execute function public.notifier_nouveau_message_inapp();

-- Nouvel avis reçu -> notification pour la cible.
create or replace function public.notifier_nouvel_avis_inapp()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_auteur_nom text;
begin
  select nom into v_auteur_nom from public.users where id = new.auteur_id;
  insert into public.notifications (user_id, type, titre, corps, lien)
  values (
    new.cible_id,
    'avis',
    coalesce(v_auteur_nom, 'Nouvel avis') || ' vous a donné ' || new.note || ' étoiles',
    nullif(new.commentaire, ''),
    '/vendeur/' || new.cible_id
  );
  return new;
end;
$$;

create trigger trg_notifier_nouvel_avis_inapp
after insert on public.avis
for each row execute function public.notifier_nouvel_avis_inapp();

-- Nouvelle annonce correspondant à une alerte de recherche enregistrée ->
-- notification. Reproduit la logique de correspondance déjà écrite en
-- TypeScript dans l'edge function notifier-nouvelle-annonce (mêmes critères :
-- type/prixMax pour un logement, categorie/etat pour un article).
create or replace function public.notifier_alerte_inapp()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_alerte record;
  v_type text := case TG_TABLE_NAME when 'articles' then 'article' else 'logement' end;
  v_lien text := (case TG_TABLE_NAME when 'articles' then '/marketplace/' else '/logements/' end) || new.id;
begin
  for v_alerte in select user_id, libelle, criteres from public.alertes_recherche where type = v_type loop
    if v_type = 'logement' then
      if v_alerte.criteres->>'type' is not null and v_alerte.criteres->>'type' <> 'Tous'
        and v_alerte.criteres->>'type' <> new.type then
        continue;
      end if;
      if v_alerte.criteres->>'prixMax' is not null
        and new.prix > (v_alerte.criteres->>'prixMax')::numeric then
        continue;
      end if;
    else
      if v_alerte.criteres->>'categorie' is not null and v_alerte.criteres->>'categorie' <> 'Tous'
        and v_alerte.criteres->>'categorie' <> new.categorie then
        continue;
      end if;
      if v_alerte.criteres->>'etat' is not null and v_alerte.criteres->>'etat' <> 'Tous'
        and v_alerte.criteres->>'etat' <> new.etat then
        continue;
      end if;
    end if;

    insert into public.notifications (user_id, type, titre, corps, lien)
    values (v_alerte.user_id, 'annonce', coalesce('Alerte "' || v_alerte.libelle || '"', 'Nouvelle annonce'), new.titre, v_lien);
  end loop;
  return new;
end;
$$;

create trigger trg_notifier_alerte_logement_inapp
after insert on public.logements
for each row execute function public.notifier_alerte_inapp();

create trigger trg_notifier_alerte_article_inapp
after insert on public.articles
for each row execute function public.notifier_alerte_inapp();
