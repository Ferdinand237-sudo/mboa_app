-- Les annonces non encore "publie" (en_attente / a_verifier / bloque) ne
-- doivent pas apparaître dans les résultats de recherche par proximité.
create or replace function public.logements_proches(
  p_lat double precision,
  p_lng double precision,
  p_rayon_km double precision
)
returns table (
  id uuid,
  titre text,
  description text,
  type text,
  prix integer,
  surface double precision,
  photos text[],
  quartier text,
  ville text,
  lat double precision,
  lng double precision,
  boosted boolean,
  note_globale double precision,
  nb_avis integer,
  proprietaire_id uuid,
  distance_km double precision
)
language sql stable as $$
  select sub.id, sub.titre, sub.description, sub.type, sub.prix, sub.surface, sub.photos,
    sub.quartier, sub.ville, sub.lat, sub.lng, sub.boosted, sub.note_globale, sub.nb_avis,
    sub.proprietaire_id, sub.distance_km
  from (
    select l.*,
      6371 * acos(least(1, greatest(-1,
        cos(radians(p_lat)) * cos(radians(l.lat)) * cos(radians(l.lng) - radians(p_lng)) +
        sin(radians(p_lat)) * sin(radians(l.lat))
      ))) as distance_km
    from public.logements l
    where l.statut = 'disponible' and l.statut_moderation = 'publie' and l.lat is not null and l.lng is not null
  ) sub
  where sub.distance_km <= p_rayon_km
  order by sub.distance_km asc;
$$;

create or replace function public.articles_proches(
  p_lat double precision,
  p_lng double precision,
  p_rayon_km double precision
)
returns table (
  id uuid,
  titre text,
  description text,
  categorie text,
  etat text,
  prix integer,
  negociable boolean,
  photos text[],
  lat double precision,
  lng double precision,
  boosted boolean,
  vendeur_id uuid,
  distance_km double precision
)
language sql stable as $$
  select sub.id, sub.titre, sub.description, sub.categorie, sub.etat, sub.prix, sub.negociable,
    sub.photos, sub.lat, sub.lng, sub.boosted, sub.vendeur_id, sub.distance_km
  from (
    select a.*,
      6371 * acos(least(1, greatest(-1,
        cos(radians(p_lat)) * cos(radians(a.lat)) * cos(radians(a.lng) - radians(p_lng)) +
        sin(radians(p_lat)) * sin(radians(a.lat))
      ))) as distance_km
    from public.articles a
    where a.statut = 'disponible' and a.statut_moderation = 'publie' and a.lat is not null and a.lng is not null
  ) sub
  where sub.distance_km <= p_rayon_km
  order by sub.distance_km asc;
$$;
