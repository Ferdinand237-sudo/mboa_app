-- Le statut officiel d'une réservation reste toujours porté par
-- reservations.statut (jamais déduit d'un message chat, voir migration
-- reservations) — mais le bouton "Contacter l'établissement" sur l'écran
-- détail réutilise le chat classique pour la discussion libre, comme pour
-- logements/articles. annonce_type doit donc accepter 'hebergement'.
alter table public.conversations drop constraint conversations_annonce_type_check;
alter table public.conversations add constraint conversations_annonce_type_check
  check (annonce_type = any (array['logement'::text,'article'::text,'hebergement'::text]));
