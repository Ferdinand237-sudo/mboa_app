-- Granularité par photo pour moderation_ia : jusqu'ici seul un verdict
-- global était enregistré (fraud_match/categories au niveau de l'annonce
-- entière), donc l'admin ne pouvait jamais savoir QUELLE photo précise
-- posait problème dans l'écran Signalements — seulement "à vérifier",
-- sans indice. Ce correctif ajoute trois colonnes que moderate-annonce
-- (Edge Function) remplit désormais en plus du verdict global existant
-- (conservé pour compatibilité avec le calcul du risk_score) :
--   - photos_fraude : photos de CETTE annonce dont le hash correspond à
--     une photo déjà publiée par un autre vendeur (réutilisation).
--   - photos_categories : verdict Gemini par photo (pornographie/
--     violence/stupefiants — arnaque_suspectee reste global, elle dépend
--     de la cohérence texte/photo, pas d'une photo isolée).
--   - photos_ignorees : photos jamais réellement analysées (trop lourdes
--     pour le hash et/ou pour l'appel Gemini, voir 449741f), pour que
--     l'admin sache qu'une absence de signal ne veut pas dire "vérifiée
--     et propre".

alter table public.moderation_ia
  add column if not exists photos_fraude jsonb not null default '[]',
  add column if not exists photos_categories jsonb not null default '[]',
  add column if not exists photos_ignorees jsonb not null default '[]';
