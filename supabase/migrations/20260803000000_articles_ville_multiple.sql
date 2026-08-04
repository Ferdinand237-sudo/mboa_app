-- Un article peut désormais cibler plusieurs villes à la fois : un vendeur
-- en déplacement (le cas fréquent qui a motivé ce changement) peut publier
-- le même article visible à la fois à Sangmelima et à Kribi, plutôt que de
-- dépendre d'une ville déduite implicitement (ville de profil ou ville
-- actuellement parcourue dans l'app au moment de la publication — c'était
-- la cause du bug signalé : un article d'une vendeuse basée à Sangmelima
-- publié par erreur sous Kribi parce qu'elle y avait été géolocalisée ou
-- y avait navigué juste avant de publier). `ville` passe de text à
-- text[], choisi explicitement par le vendeur à la publication et à
-- l'édition.
update public.articles set ville = 'Sangmelima' where ville is null or ville = '';

alter table public.articles
  alter column ville type text[] using array[ville];

alter table public.articles alter column ville set default '{}'::text[];
alter table public.articles alter column ville set not null;

create index if not exists idx_articles_ville on public.articles using gin (ville);
