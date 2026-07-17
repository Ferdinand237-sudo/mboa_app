-- Sans cet ajout à la publication supabase_realtime, les abonnements
-- onPostgresChanges de admin_verifications_screen, admin_signalements_screen
-- et ambassadeur_liste_screen ne recevraient jamais aucun événement.
alter publication supabase_realtime add table public.verifications_terrain;
alter publication supabase_realtime add table public.signalements;
