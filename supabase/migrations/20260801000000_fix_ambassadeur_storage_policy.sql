-- Corrige la policy Storage du bucket attestations-proprietaires, qui
-- bloquait l'envoi du formulaire de vérification terrain avec
-- "new row violates row-level security policy for table objects".
--
-- Root cause : même famille de bug que les policies déjà corrigées côté
-- notifications (20260729000000) et l'assignation d'ambassadeur côté
-- application (voir HISTORIQUE_PROJET_MBOA.md §5undecies) — écrite avant
-- la refonte des rôles superposables (§4.9), elle ne vérifiait que
-- role = 'ambassadeur', jamais est_ambassadeur = true. Un ambassadeur
-- nommé via "Nommer ambassadeur" garde son rôle de base (souvent
-- "visiteur"), donc ne passait jamais cette condition et ne pouvait pas
-- téléverser sa pièce justificative.

drop policy if exists "Ambassadeur televerse et consulte ses attestations" on storage.objects;

create policy "Ambassadeur televerse et consulte ses attestations"
on storage.objects for all
using (
  bucket_id = 'attestations-proprietaires'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1 from public.users
    where id = auth.uid() and (role = 'ambassadeur' or est_ambassadeur = true)
  )
)
with check (
  bucket_id = 'attestations-proprietaires'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (
    select 1 from public.users
    where id = auth.uid() and (role = 'ambassadeur' or est_ambassadeur = true)
  )
);
