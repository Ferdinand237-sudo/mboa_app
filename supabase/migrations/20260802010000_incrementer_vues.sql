-- Compteur de vues par annonce : les policies UPDATE de logements/articles
-- sont restreintes au propriétaire/vendeur (auth.uid() = proprietaire_id/
-- vendeur_id) ou à is_admin(), donc un visiteur (même connecté) ne peut pas
-- faire un update({vues: ...}) direct. Deux fonctions security definer,
-- limitées à ce seul incrément atomique (vues = vues + 1), exposées via RPC.

create or replace function public.increment_vues_logement(p_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.logements set vues = coalesce(vues, 0) + 1 where id = p_id;
$$;

create or replace function public.increment_vues_article(p_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.articles set vues = coalesce(vues, 0) + 1 where id = p_id;
$$;

grant execute on function public.increment_vues_logement(uuid) to anon, authenticated;
grant execute on function public.increment_vues_article(uuid) to anon, authenticated;
