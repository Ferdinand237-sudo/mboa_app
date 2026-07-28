-- Jeu de données de test pour Kribi et Ébolowa : comptes vendeurs certifiés,
-- logements/articles avec de vrais quartiers et lieux publics géocodés
-- (OpenStreetMap Nominatim), pour que la couverture multi-villes ajoutée en
-- 20260727000000_multi_ville.sql soit exploitable dès l'installation de
-- l'app (sans attendre de vrais vendeurs sur ces deux villes).
--
-- Comptes créés (mots de passe consignés aussi dans HISTORIQUE_PROJET_MBOA.md) :
--   Kribi   — emilienne.mbarga@mboa-test.cm / MboaKribi2026!   (propriétaire)
--             serge.nkoulou@mboa-test.cm    / MboaKribi2026!   (commerçant/vendeur indépendant)
--   Ébolowa — odette.ayissi@mboa-test.cm    / MboaEbolowa2026! (propriétaire)
--             bruno.essomba@mboa-test.cm    / MboaEbolowa2026! (commerçant/vendeur indépendant)
--
-- Script rejouable : chaque bloc vérifie l'existence avant de créer, comme
-- les migrations précédentes de cette session.

create extension if not exists pgcrypto with schema extensions;

-- Toute la migration dans une seule transaction : si une instruction échoue
-- en cours de route (ex. colonne auth.users inattendue sur cette version de
-- GoTrue), tout est annulé plutôt que de laisser les triggers désactivés ou
-- des comptes/annonces à moitié créés.
begin;

-- Les triggers de modération IA (appel HTTP asynchrone vers l'Edge Function
-- moderate-annonce) et de protection des colonnes de confiance sur
-- logements/articles/users résistent aux écritures faites hors contexte
-- authentifié (is_admin()/auth.role() sont vides dans l'éditeur SQL du
-- dashboard) : sans les désactiver ici, statut_moderation, verified et
-- compte_actif_publication seraient silencieusement réinitialisés, et une
-- analyse IA inutile serait déclenchée sur ces annonces de test. Réactivés
-- en toute fin de script.
alter table public.users disable trigger user;
alter table public.logements disable trigger user;
alter table public.articles disable trigger user;

do $$
declare
  v_emilienne uuid;
  v_serge     uuid;
  v_odette    uuid;
  v_bruno     uuid;

  -- Photos Unsplash cohérentes par type d'annonce (vérifiées accessibles).
  chambre_1 text[] := array[
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200&q=75&auto=format&fit=crop'
  ];
  chambre_2 text[] := array[
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=75&auto=format&fit=crop'
  ];
  studio text[] := array[
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=1200&q=75&auto=format&fit=crop'
  ];
  appartement text[] := array[
    'https://images.unsplash.com/photo-1502672023488-70e25813eb80?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1200&q=75&auto=format&fit=crop'
  ];
  photo_lit text[] := array[
    'https://images.unsplash.com/photo-1505693314120-0d443867891c?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1505692952047-1a78307da8f2?w=1200&q=75&auto=format&fit=crop'
  ];
  photo_mobilier text[] := array[
    'https://images.unsplash.com/photo-1550254478-ead40cc54513?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=1200&q=75&auto=format&fit=crop'
  ];
  photo_electronique text[] := array[
    'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200&q=75&auto=format&fit=crop'
  ];
  photo_cuisine text[] := array[
    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=1200&q=75&auto=format&fit=crop'
  ];
  photo_scolaire text[] := array[
    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=1200&q=75&auto=format&fit=crop'
  ];
  photo_divers text[] := array[
    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=1200&q=75&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1200&q=75&auto=format&fit=crop'
  ];
begin
  -- ── Compte 1 : Émilienne Mbarga — propriétaire à Kribi ──────
  select id into v_emilienne from auth.users where email = 'emilienne.mbarga@mboa-test.cm';
  if v_emilienne is null then
    v_emilienne := extensions.uuid_generate_v4();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, email_change,
      email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_emilienne, 'authenticated', 'authenticated',
      'emilienne.mbarga@mboa-test.cm', extensions.crypt('MboaKribi2026!', extensions.gen_salt('bf')),
      now(), '{"provider":"email","providers":["email"]}', jsonb_build_object('nom', 'Émilienne Mbarga', 'role', 'vendeur'),
      now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (extensions.uuid_generate_v4(), v_emilienne, v_emilienne::text,
      jsonb_build_object('sub', v_emilienne::text, 'email', 'emilienne.mbarga@mboa-test.cm'),
      'email', now(), now(), now());
  end if;

  insert into public.users (id, nom, email, telephone, role, sous_roles, verified, actif, date_inscription, compte_actif_publication, nom_commerce, emplacement_commerce, lat, lng)
  values (v_emilienne, 'Émilienne Mbarga', 'emilienne.mbarga@mboa-test.cm', '+237 671 22 33 44', 'vendeur',
    array['proprietaire'], true, true, now(), true, 'Résidences Mbarga', 'Kribi', 2.9405664, 9.9139608)
  on conflict (id) do update set
    role = excluded.role, sous_roles = excluded.sous_roles, verified = excluded.verified,
    compte_actif_publication = excluded.compte_actif_publication, telephone = excluded.telephone,
    nom_commerce = excluded.nom_commerce, emplacement_commerce = excluded.emplacement_commerce;

  -- ── Compte 2 : Serge Nkoulou — commerçant / vendeur indépendant à Kribi ──
  select id into v_serge from auth.users where email = 'serge.nkoulou@mboa-test.cm';
  if v_serge is null then
    v_serge := extensions.uuid_generate_v4();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, email_change,
      email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_serge, 'authenticated', 'authenticated',
      'serge.nkoulou@mboa-test.cm', extensions.crypt('MboaKribi2026!', extensions.gen_salt('bf')),
      now(), '{"provider":"email","providers":["email"]}', jsonb_build_object('nom', 'Serge Nkoulou', 'role', 'vendeur'),
      now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (extensions.uuid_generate_v4(), v_serge, v_serge::text,
      jsonb_build_object('sub', v_serge::text, 'email', 'serge.nkoulou@mboa-test.cm'),
      'email', now(), now(), now());
  end if;

  insert into public.users (id, nom, email, telephone, role, sous_roles, verified, actif, date_inscription, compte_actif_publication, nom_commerce, emplacement_commerce, lat, lng)
  values (v_serge, 'Serge Nkoulou', 'serge.nkoulou@mboa-test.cm', '+237 675 33 44 55', 'vendeur',
    array['commercant', 'vendeur_independant'], true, true, now(), true, 'Bazar Nkoulou', 'Kribi', 2.9405664, 9.9139608)
  on conflict (id) do update set
    role = excluded.role, sous_roles = excluded.sous_roles, verified = excluded.verified,
    compte_actif_publication = excluded.compte_actif_publication, telephone = excluded.telephone,
    nom_commerce = excluded.nom_commerce, emplacement_commerce = excluded.emplacement_commerce;

  -- ── Compte 3 : Odette Ayissi — propriétaire à Ébolowa ───────
  select id into v_odette from auth.users where email = 'odette.ayissi@mboa-test.cm';
  if v_odette is null then
    v_odette := extensions.uuid_generate_v4();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, email_change,
      email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_odette, 'authenticated', 'authenticated',
      'odette.ayissi@mboa-test.cm', extensions.crypt('MboaEbolowa2026!', extensions.gen_salt('bf')),
      now(), '{"provider":"email","providers":["email"]}', jsonb_build_object('nom', 'Odette Ayissi', 'role', 'vendeur'),
      now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (extensions.uuid_generate_v4(), v_odette, v_odette::text,
      jsonb_build_object('sub', v_odette::text, 'email', 'odette.ayissi@mboa-test.cm'),
      'email', now(), now(), now());
  end if;

  insert into public.users (id, nom, email, telephone, role, sous_roles, verified, actif, date_inscription, compte_actif_publication, nom_commerce, emplacement_commerce, lat, lng)
  values (v_odette, 'Odette Ayissi', 'odette.ayissi@mboa-test.cm', '+237 677 44 55 66', 'vendeur',
    array['proprietaire'], true, true, now(), true, 'Résidences Ayissi', 'Ébolowa', 2.9206461, 11.1525020)
  on conflict (id) do update set
    role = excluded.role, sous_roles = excluded.sous_roles, verified = excluded.verified,
    compte_actif_publication = excluded.compte_actif_publication, telephone = excluded.telephone,
    nom_commerce = excluded.nom_commerce, emplacement_commerce = excluded.emplacement_commerce;

  -- ── Compte 4 : Bruno Essomba — commerçant / vendeur indépendant à Ébolowa ──
  select id into v_bruno from auth.users where email = 'bruno.essomba@mboa-test.cm';
  if v_bruno is null then
    v_bruno := extensions.uuid_generate_v4();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, email_change,
      email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_bruno, 'authenticated', 'authenticated',
      'bruno.essomba@mboa-test.cm', extensions.crypt('MboaEbolowa2026!', extensions.gen_salt('bf')),
      now(), '{"provider":"email","providers":["email"]}', jsonb_build_object('nom', 'Bruno Essomba', 'role', 'vendeur'),
      now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (extensions.uuid_generate_v4(), v_bruno, v_bruno::text,
      jsonb_build_object('sub', v_bruno::text, 'email', 'bruno.essomba@mboa-test.cm'),
      'email', now(), now(), now());
  end if;

  insert into public.users (id, nom, email, telephone, role, sous_roles, verified, actif, date_inscription, compte_actif_publication, nom_commerce, emplacement_commerce, lat, lng)
  values (v_bruno, 'Bruno Essomba', 'bruno.essomba@mboa-test.cm', '+237 679 55 66 77', 'vendeur',
    array['commercant', 'vendeur_independant'], true, true, now(), true, 'Boutique Essomba', 'Ébolowa', 2.9206461, 11.1525020)
  on conflict (id) do update set
    role = excluded.role, sous_roles = excluded.sous_roles, verified = excluded.verified,
    compte_actif_publication = excluded.compte_actif_publication, telephone = excluded.telephone,
    nom_commerce = excluded.nom_commerce, emplacement_commerce = excluded.emplacement_commerce;

  -- ── Logements Kribi (Émilienne) ──────────────────────────────
  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Chambre meublée à 5 min de la plage', 'Belle chambre meublée dans le quartier Bella, à deux pas de la plage et du centre-ville de Kribi. Idéal pour étudiant ou jeune actif.', 'Chambre', 20000, 12, chambre_1, array['Wifi','Eau courante','Électricité','Meublé'], array['Non fumeur'], 'Bella', 'Kribi', 2.9390, 9.9070, 'Quartier Bella, à deux pas de la plage', v_emilienne, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Chambre meublée à 5 min de la plage' and proprietaire_id = v_emilienne);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Studio calme proche école à Afan Mabé', 'Studio indépendant, quartier calme et sécurisé d''Afan Mabé, à proximité immédiate de l''école primaire du quartier.', 'Studio', 35000, 22, studio, array['Wifi','Eau courante','Électricité','Cuisine','Sécurité'], array['Pas de visiteurs après 22h'], 'Afan Mabé', 'Kribi', 2.9553299, 9.9154216, 'Près de l''École maternelle et primaire d''Afan Mabé', v_emilienne, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Studio calme proche école à Afan Mabé' and proprietaire_id = v_emilienne);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Appartement moderne à Ngoyé', 'Appartement moderne de standing à Ngoyé, proche de l''hôpital et des commerces. Idéal en colocation.', 'Appartement', 60000, 45, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Parking'], array['Non fumeur','Caution 1 mois'], 'Ngoyé', 'Kribi', 2.9492244, 9.9096686, 'Ngoyé, proche de l''Hôpital de District de Kribi', v_emilienne, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Appartement moderne à Ngoyé' and proprietaire_id = v_emilienne);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Chambre spacieuse à Dombé', 'Chambre spacieuse et lumineuse à Dombé, quartier résidentiel calme en périphérie de Kribi.', 'Chambre', 17000, 11, chambre_2, array['Wifi','Eau courante','Électricité'], array['Non fumeur'], 'Dombé', 'Kribi', 2.9504064, 9.9243667, 'Dombé, proche du marché et de l''école publique du quartier', v_emilienne, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Chambre spacieuse à Dombé' and proprietaire_id = v_emilienne);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Studio tout confort à Mpango', 'Studio moderne et bien agencé à Mpango, à deux pas du centre-ville et de la cathédrale.', 'Studio', 38000, 24, studio, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Sécurité'], array['Pas de visiteurs après 22h'], 'Mpango', 'Kribi', 2.9301423, 9.9119872, 'Mpango, proche de la Cathédrale Saint-Joseph', v_emilienne, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Studio tout confort à Mpango' and proprietaire_id = v_emilienne);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Appartement familial à Bella', 'Grand appartement familial dans le quartier Bella, à proximité immédiate de la plage.', 'Appartement', 70000, 55, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Sécurité','Parking'], array['Non fumeur','Caution 1 mois'], 'Bella', 'Kribi', 2.9390, 9.9070, 'Quartier Bella, à proximité immédiate de la plage', v_emilienne, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Appartement familial à Bella' and proprietaire_id = v_emilienne);

  -- ── Logements Ébolowa (Odette) ───────────────────────────────
  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Chambre étudiante à New-Bell', 'Chambre simple et propre à New-Bell, quartier animé et bien desservi d''Ébolowa.', 'Chambre', 18000, 10, chambre_2, array['Wifi','Eau courante','Électricité'], array['Non fumeur'], 'New-Bell', 'Ébolowa', 2.9314441, 11.1443331, 'New-Bell, proche du Commissariat de Newbell', v_odette, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Chambre étudiante à New-Bell' and proprietaire_id = v_odette);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Studio indépendant à Elat', 'Studio meublé avec cuisine équipée, quartier Elat, proche de l''hôpital régional et du marché.', 'Studio', 32000, 20, studio, array['Wifi','Eau courante','Électricité','Meublé','Cuisine'], array['Pas de visiteurs après 22h'], 'Elat', 'Ébolowa', 2.9093049, 11.1584503, 'Elat, à côté de l''Hôpital Régional d''Ébolowa', v_odette, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Studio indépendant à Elat' and proprietaire_id = v_odette);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Appartement 2 chambres à Ngalan', 'Spacieux appartement 2 chambres à Ngalan I, proche de la cathédrale et du lycée technique.', 'Appartement', 55000, 50, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Sécurité','Parking'], array['Non fumeur','Caution 1 mois'], 'Ngalan I', 'Ébolowa', 2.9410616, 11.1221419, 'Ngalan I, proche de la Cathédrale Sainte-Anne-et-Joachim', v_odette, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Appartement 2 chambres à Ngalan' and proprietaire_id = v_odette);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Chambre proche du complexe sportif à Mekalat', 'Chambre simple à Mekalat, quartier calme proche du complexe multisports et de l''université.', 'Chambre', 19000, 11, chambre_1, array['Wifi','Eau courante','Électricité'], array['Non fumeur'], 'Mekalat', 'Ébolowa', 2.9130441, 11.1663076, 'Mekalat, proche du complexe multisports de Nko''Ovos', v_odette, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Chambre proche du complexe sportif à Mekalat' and proprietaire_id = v_odette);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Studio calme à Biyeyem', 'Studio indépendant à Biyeyem, quartier calme en périphérie d''Ébolowa.', 'Studio', 30000, 19, studio, array['Wifi','Eau courante','Électricité','Cuisine'], array['Pas de visiteurs après 22h'], 'Biyeyem', 'Ébolowa', 2.8480820, 11.1406744, 'Biyeyem, proche du Marché Mvila', v_odette, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Studio calme à Biyeyem' and proprietaire_id = v_odette);

  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select 'Appartement spacieux à Elat', 'Appartement spacieux et bien situé à Elat, proche de l''hôpital régional et du marché central.', 'Appartement', 58000, 48, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Parking'], array['Non fumeur','Caution 1 mois'], 'Elat', 'Ébolowa', 2.9093049, 11.1584503, 'Elat, proche de l''Hôpital Régional d''Ébolowa', v_odette, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  where not exists (select 1 from public.logements where titre = 'Appartement spacieux à Elat' and proprietaire_id = v_odette);

  -- ── Articles Kribi (Serge) ────────────────────────────────────
  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Lit 1 place avec matelas en bon état', 'Lit 1 place en bois avec matelas, peu servi, à récupérer sur Kribi.', 'Literie', 'Bon état', 25000, true, true, photo_lit, v_serge, 'Kribi', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Lit 1 place avec matelas en bon état' and vendeur_id = v_serge);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Table à manger + 4 chaises en bois', 'Ensemble table et 4 chaises en bois massif, quelques traces d''usage.', 'Mobilier', 'Correct', 30000, true, true, photo_mobilier, v_serge, 'Kribi', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Table à manger + 4 chaises en bois' and vendeur_id = v_serge);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Ordinateur portable HP occasion', 'PC portable HP fonctionnel, bon état, idéal pour les cours.', 'Électronique', 'Bon état', 120000, false, true, photo_electronique, v_serge, 'Kribi', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Ordinateur portable HP occasion' and vendeur_id = v_serge);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Armoire 2 portes', 'Armoire en bois 2 portes, bon état, idéale pour une chambre d''étudiant.', 'Mobilier', 'Bon état', 28000, true, true, photo_mobilier, v_serge, 'Kribi', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Armoire 2 portes' and vendeur_id = v_serge);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Smartphone Android d''occasion', 'Smartphone Android fonctionnel, écran sans fissure, bonne autonomie.', 'Électronique', 'Correct', 45000, true, true, photo_electronique, v_serge, 'Kribi', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Smartphone Android d''occasion' and vendeur_id = v_serge);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Matelas mousse 2 places', 'Matelas mousse 2 places, jamais servi, encore sous emballage.', 'Literie', 'Neuf', 35000, true, true, photo_lit, v_serge, 'Kribi', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Matelas mousse 2 places' and vendeur_id = v_serge);

  -- ── Articles Ébolowa (Bruno) ──────────────────────────────────
  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Kit de cuisine complet', 'Casseroles, ustensiles et vaisselle de base, idéal pour une première installation.', 'Cuisine', 'Très bon état', 15000, true, true, photo_cuisine, v_bruno, 'Ébolowa', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Kit de cuisine complet' and vendeur_id = v_bruno);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Lot de livres scolaires niveau universitaire', 'Livres et supports de cours niveau universitaire, plusieurs matières.', 'Scolaire', 'Bon état', 12000, true, true, photo_scolaire, v_bruno, 'Ébolowa', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Lot de livres scolaires niveau universitaire' and vendeur_id = v_bruno);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Ventilateur + petit réfrigérateur', 'Ventilateur sur pied et petit réfrigérateur, tous deux fonctionnels.', 'Divers', 'Correct', 45000, true, true, photo_divers, v_bruno, 'Ébolowa', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Ventilateur + petit réfrigérateur' and vendeur_id = v_bruno);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Matelas mousse 1 place', 'Matelas mousse 1 place, jamais servi, encore sous emballage.', 'Literie', 'Neuf', 22000, true, true, photo_lit, v_bruno, 'Ébolowa', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Matelas mousse 1 place' and vendeur_id = v_bruno);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Chaise de bureau ergonomique', 'Chaise de bureau réglable, confortable, idéale pour les longues sessions de révision.', 'Mobilier', 'Bon état', 20000, true, true, photo_mobilier, v_bruno, 'Ébolowa', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Chaise de bureau ergonomique' and vendeur_id = v_bruno);

  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select 'Sac à dos + fournitures scolaires', 'Sac à dos solide avec quelques fournitures scolaires incluses.', 'Scolaire', 'Très bon état', 10000, true, true, photo_scolaire, v_bruno, 'Ébolowa', 'disponible', 'publie', false, 0, 0, now()
  where not exists (select 1 from public.articles where titre = 'Sac à dos + fournitures scolaires' and vendeur_id = v_bruno);

  -- ── Lot supplémentaire : 15 logements de plus à Kribi (Émilienne) ──
  -- Quartiers réutilisés (déjà géocodés ci-dessus) : normal qu'une même
  -- ville ait plusieurs annonces dans le même quartier.
  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select v.titre, v.description, v.type, v.prix, v.surface, v.photos, v.equipements, v.regles, v.quartier, 'Kribi', v.lat, v.lng, v.adresse_approx, v_emilienne, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  from (values
    ('Chambre avec balcon à Bella', 'Chambre avec balcon donnant sur une cour calme, à Bella, à deux pas de la plage.', 'Chambre', 22000, 13, chambre_1, array['Wifi','Eau courante','Électricité','Meublé'], array['Non fumeur'], 'Bella', 2.9390, 9.9070, 'Quartier Bella, proche de la plage'),
    ('Chambre climatisée à Afan Mabé', 'Chambre climatisée, quartier calme d''Afan Mabé, proche de l''école du quartier.', 'Chambre', 24000, 14, chambre_2, array['Wifi','Eau courante','Électricité','Climatisation'], array['Non fumeur'], 'Afan Mabé', 2.9553299, 9.9154216, 'Afan Mabé, proche de l''école du quartier'),
    ('Chambre proche du marché à Ngoyé', 'Chambre pratique, à quelques minutes à pied du marché et de l''hôpital de Ngoyé.', 'Chambre', 19000, 12, chambre_1, array['Wifi','Eau courante','Électricité'], array['Non fumeur'], 'Ngoyé', 2.9492244, 9.9096686, 'Ngoyé, proche de l''Hôpital de District de Kribi'),
    ('Chambre calme à Dombé', 'Chambre simple dans un quartier résidentiel calme de Dombé.', 'Chambre', 15000, 10, chambre_2, array['Eau courante','Électricité'], array['Non fumeur'], 'Dombé', 2.9504064, 9.9243667, 'Dombé, quartier résidentiel calme'),
    ('Chambre lumineuse à Mpango', 'Chambre lumineuse et bien ventilée à Mpango, proche du centre-ville.', 'Chambre', 20000, 12, chambre_1, array['Wifi','Eau courante','Électricité','Meublé'], array['Non fumeur'], 'Mpango', 2.9301423, 9.9119872, 'Mpango, proche de la Cathédrale Saint-Joseph'),
    ('Studio avec kitchenette à Bella', 'Studio avec kitchenette équipée, à Bella, proche de la plage.', 'Studio', 40000, 24, studio, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Sécurité'], array['Pas de visiteurs après 22h'], 'Bella', 2.9390, 9.9070, 'Quartier Bella, proche de la plage'),
    ('Studio sécurisé à Afan Mabé', 'Studio sécurisé avec gardiennage, quartier calme d''Afan Mabé.', 'Studio', 36000, 22, studio, array['Wifi','Eau courante','Électricité','Sécurité'], array['Pas de visiteurs après 22h'], 'Afan Mabé', 2.9553299, 9.9154216, 'Afan Mabé, proche de l''école du quartier'),
    ('Studio rénové à Ngoyé', 'Studio récemment rénové, proche des commerces de Ngoyé.', 'Studio', 38000, 23, studio, array['Wifi','Eau courante','Électricité','Meublé','Cuisine'], array['Non fumeur'], 'Ngoyé', 2.9492244, 9.9096686, 'Ngoyé, proche de l''Hôpital de District de Kribi'),
    ('Studio économique à Dombé', 'Studio simple et économique, quartier calme de Dombé.', 'Studio', 28000, 18, studio, array['Eau courante','Électricité','Cuisine'], array['Non fumeur'], 'Dombé', 2.9504064, 9.9243667, 'Dombé, quartier résidentiel calme'),
    ('Studio confortable à Mpango', 'Studio confortable et meublé, proche du centre-ville de Kribi.', 'Studio', 37000, 23, studio, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Sécurité'], array['Pas de visiteurs après 22h'], 'Mpango', 2.9301423, 9.9119872, 'Mpango, proche de la Cathédrale Saint-Joseph'),
    ('Appartement standing à Bella', 'Appartement de standing avec vue dégagée, à Bella, proche de la plage.', 'Appartement', 75000, 60, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Sécurité','Parking'], array['Non fumeur','Caution 1 mois'], 'Bella', 2.9390, 9.9070, 'Quartier Bella, proche de la plage'),
    ('Appartement 3 pièces à Afan Mabé', 'Appartement 3 pièces, quartier calme et sécurisé d''Afan Mabé.', 'Appartement', 65000, 52, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Sécurité'], array['Non fumeur'], 'Afan Mabé', 2.9553299, 9.9154216, 'Afan Mabé, proche de l''école du quartier'),
    ('Appartement vue dégagée à Ngoyé', 'Appartement spacieux avec vue dégagée, proche de l''hôpital de Ngoyé.', 'Appartement', 62000, 48, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Parking'], array['Non fumeur','Caution 1 mois'], 'Ngoyé', 2.9492244, 9.9096686, 'Ngoyé, proche de l''Hôpital de District de Kribi'),
    ('Appartement neuf à Dombé', 'Appartement neuf et bien fini, quartier résidentiel calme de Dombé.', 'Appartement', 58000, 46, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon'], array['Non fumeur'], 'Dombé', 2.9504064, 9.9243667, 'Dombé, quartier résidentiel calme'),
    ('Appartement cosy à Mpango', 'Appartement cosy et bien situé, proche du centre-ville et de la cathédrale.', 'Appartement', 55000, 42, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Sécurité'], array['Non fumeur','Caution 1 mois'], 'Mpango', 2.9301423, 9.9119872, 'Mpango, proche de la Cathédrale Saint-Joseph')
  ) as v(titre, description, type, prix, surface, photos, equipements, regles, quartier, lat, lng, adresse_approx)
  where not exists (select 1 from public.logements l where l.titre = v.titre and l.proprietaire_id = v_emilienne);

  -- ── Lot supplémentaire : 15 logements de plus à Ébolowa (Odette) ──
  insert into public.logements (titre, description, type, prix, surface, photos, equipements, regles, quartier, ville, lat, lng, adresse_approx, proprietaire_id, statut, statut_moderation, boosted, vues, signalements, note_globale, nb_avis, date_publication)
  select v.titre, v.description, v.type, v.prix, v.surface, v.photos, v.equipements, v.regles, v.quartier, 'Ébolowa', v.lat, v.lng, v.adresse_approx, v_odette, 'disponible', 'publie', false, 0, 0, 0, 0, now()
  from (values
    ('Chambre avec balcon à New-Bell', 'Chambre avec balcon, quartier animé et bien desservi de New-Bell.', 'Chambre', 20000, 12, chambre_1, array['Wifi','Eau courante','Électricité','Meublé'], array['Non fumeur'], 'New-Bell', 2.9314441, 11.1443331, 'New-Bell, proche du Commissariat de Newbell'),
    ('Chambre climatisée à Elat', 'Chambre climatisée, proche de l''hôpital régional et du marché d''Elat.', 'Chambre', 21000, 12, chambre_2, array['Wifi','Eau courante','Électricité','Climatisation'], array['Non fumeur'], 'Elat', 2.9093049, 11.1584503, 'Elat, proche de l''Hôpital Régional d''Ébolowa'),
    ('Chambre proche du lycée à Ngalan I', 'Chambre pratique, proche du lycée technique et de la cathédrale.', 'Chambre', 18000, 11, chambre_1, array['Wifi','Eau courante','Électricité'], array['Non fumeur'], 'Ngalan I', 2.9410616, 11.1221419, 'Ngalan I, proche de la Cathédrale Sainte-Anne-et-Joachim'),
    ('Chambre calme à Mekalat', 'Chambre calme, quartier proche du complexe multisports.', 'Chambre', 19000, 11, chambre_2, array['Eau courante','Électricité'], array['Non fumeur'], 'Mekalat', 2.9130441, 11.1663076, 'Mekalat, proche du complexe multisports de Nko''Ovos'),
    ('Chambre lumineuse à Biyeyem', 'Chambre lumineuse dans un quartier calme en périphérie d''Ébolowa.', 'Chambre', 16000, 10, chambre_1, array['Wifi','Eau courante','Électricité'], array['Non fumeur'], 'Biyeyem', 2.8480820, 11.1406744, 'Biyeyem, proche du Marché Mvila'),
    ('Studio avec kitchenette à New-Bell', 'Studio avec kitchenette équipée, quartier animé de New-Bell.', 'Studio', 34000, 21, studio, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Sécurité'], array['Pas de visiteurs après 22h'], 'New-Bell', 2.9314441, 11.1443331, 'New-Bell, proche du Commissariat de Newbell'),
    ('Studio sécurisé à Elat', 'Studio sécurisé, proche de l''hôpital régional d''Ébolowa.', 'Studio', 33000, 20, studio, array['Wifi','Eau courante','Électricité','Sécurité'], array['Pas de visiteurs après 22h'], 'Elat', 2.9093049, 11.1584503, 'Elat, proche de l''Hôpital Régional d''Ébolowa'),
    ('Studio rénové à Ngalan I', 'Studio récemment rénové, proche de la cathédrale et du lycée.', 'Studio', 35000, 22, studio, array['Wifi','Eau courante','Électricité','Meublé','Cuisine'], array['Non fumeur'], 'Ngalan I', 2.9410616, 11.1221419, 'Ngalan I, proche de la Cathédrale Sainte-Anne-et-Joachim'),
    ('Studio économique à Mekalat', 'Studio simple et économique à Mekalat.', 'Studio', 29000, 18, studio, array['Eau courante','Électricité','Cuisine'], array['Non fumeur'], 'Mekalat', 2.9130441, 11.1663076, 'Mekalat, proche du complexe multisports de Nko''Ovos'),
    ('Studio confortable à Biyeyem', 'Studio confortable et meublé, quartier calme de Biyeyem.', 'Studio', 28000, 17, studio, array['Wifi','Eau courante','Électricité','Meublé','Cuisine'], array['Non fumeur'], 'Biyeyem', 2.8480820, 11.1406744, 'Biyeyem, proche du Marché Mvila'),
    ('Appartement standing à New-Bell', 'Appartement de standing, quartier animé et bien desservi de New-Bell.', 'Appartement', 60000, 50, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Sécurité','Parking'], array['Non fumeur','Caution 1 mois'], 'New-Bell', 2.9314441, 11.1443331, 'New-Bell, proche du Commissariat de Newbell'),
    ('Appartement 3 pièces à Elat', 'Appartement 3 pièces, proche de l''hôpital régional et du marché.', 'Appartement', 62000, 52, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Sécurité'], array['Non fumeur'], 'Elat', 2.9093049, 11.1584503, 'Elat, proche de l''Hôpital Régional d''Ébolowa'),
    ('Appartement vue dégagée à Ngalan I', 'Appartement spacieux, proche de la cathédrale et du lycée technique.', 'Appartement', 57000, 46, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Parking'], array['Non fumeur','Caution 1 mois'], 'Ngalan I', 2.9410616, 11.1221419, 'Ngalan I, proche de la Cathédrale Sainte-Anne-et-Joachim'),
    ('Appartement neuf à Mekalat', 'Appartement neuf et bien fini, proche du complexe multisports.', 'Appartement', 54000, 44, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon'], array['Non fumeur'], 'Mekalat', 2.9130441, 11.1663076, 'Mekalat, proche du complexe multisports de Nko''Ovos'),
    ('Appartement cosy à Biyeyem', 'Appartement cosy, quartier calme en périphérie d''Ébolowa.', 'Appartement', 50000, 40, appartement, array['Wifi','Eau courante','Électricité','Meublé','Cuisine','Salon','Sécurité'], array['Non fumeur','Caution 1 mois'], 'Biyeyem', 2.8480820, 11.1406744, 'Biyeyem, proche du Marché Mvila')
  ) as v(titre, description, type, prix, surface, photos, equipements, regles, quartier, lat, lng, adresse_approx)
  where not exists (select 1 from public.logements l where l.titre = v.titre and l.proprietaire_id = v_odette);

  -- ── Lot supplémentaire : 20 articles de plus à Kribi (Serge) ──
  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select v.titre, v.description, v.categorie, v.etat, v.prix, true, true, v.photos, v_serge, 'Kribi', 'disponible', 'publie', false, 0, 0, now()
  from (values
    ('Matelas 1 place neuf', 'Matelas mousse 1 place, neuf, encore emballé.', 'Literie', 'Neuf', 20000, photo_lit),
    ('Oreillers + couette', 'Lot de 2 oreillers et une couette chaude, peu servis.', 'Literie', 'Très bon état', 8000, photo_lit),
    ('Lit superposé métallique', 'Lit superposé en métal, solide, idéal colocation.', 'Literie', 'Bon état', 45000, photo_lit),
    ('Bureau d''étude en bois', 'Bureau d''étude en bois avec tiroir, bon état.', 'Mobilier', 'Bon état', 22000, photo_mobilier),
    ('Étagère de rangement', 'Étagère 4 niveaux, pratique pour livres et affaires.', 'Mobilier', 'Correct', 12000, photo_mobilier),
    ('Canapé 2 places', 'Canapé 2 places en tissu, confortable.', 'Mobilier', 'Bon état', 40000, photo_mobilier),
    ('Petite commode', 'Petite commode 3 tiroirs, bois.', 'Mobilier', 'Correct', 15000, photo_mobilier),
    ('Réchaud à gaz 2 feux', 'Réchaud à gaz 2 feux avec régulateur, fonctionnel.', 'Cuisine', 'Bon état', 18000, photo_cuisine),
    ('Set de casseroles inox', 'Set de 4 casseroles en inox, tailles variées.', 'Cuisine', 'Très bon état', 16000, photo_cuisine),
    ('Bouilloire électrique', 'Bouilloire électrique, chauffe rapide.', 'Cuisine', 'Bon état', 9000, photo_cuisine),
    ('Ventilateur de bureau', 'Petit ventilateur de bureau, silencieux.', 'Électronique', 'Bon état', 8000, photo_electronique),
    ('Enceinte Bluetooth portable', 'Enceinte Bluetooth portable, bonne autonomie.', 'Électronique', 'Très bon état', 15000, photo_electronique),
    ('Fer à repasser', 'Fer à repasser électrique, fonctionnel.', 'Électronique', 'Correct', 6000, photo_electronique),
    ('Chargeur solaire portable', 'Chargeur solaire portable pour téléphone.', 'Électronique', 'Bon état', 10000, photo_electronique),
    ('Calculatrice scientifique', 'Calculatrice scientifique, idéale pour les études techniques.', 'Scolaire', 'Très bon état', 6000, photo_scolaire),
    ('Kit de géométrie + cahiers', 'Kit de géométrie complet avec quelques cahiers neufs.', 'Scolaire', 'Neuf', 3000, photo_scolaire),
    ('Sac de cours imperméable', 'Sac à dos imperméable, plusieurs compartiments.', 'Scolaire', 'Bon état', 9000, photo_scolaire),
    ('Vélo d''occasion', 'Vélo d''occasion, bon état général, pratique pour se déplacer.', 'Divers', 'Correct', 35000, photo_divers),
    ('Valise de voyage', 'Valise de voyage rigide, roulettes en bon état.', 'Divers', 'Bon état', 20000, photo_divers),
    ('Housse de matelas', 'Housse de matelas imperméable, taille standard.', 'Divers', 'Neuf', 5000, photo_divers)
  ) as v(titre, description, categorie, etat, prix, photos)
  where not exists (select 1 from public.articles a where a.titre = v.titre and a.vendeur_id = v_serge);

  -- ── Lot supplémentaire : 20 articles de plus à Ébolowa (Bruno) ──
  insert into public.articles (titre, description, categorie, etat, prix, negociable, accepte_avis, photos, vendeur_id, ville, statut, statut_moderation, boosted, vues, signalements, date_publication)
  select v.titre, v.description, v.categorie, v.etat, v.prix, true, true, v.photos, v_bruno, 'Ébolowa', 'disponible', 'publie', false, 0, 0, now()
  from (values
    ('Matelas 2 places d''occasion', 'Matelas 2 places, bon état, sans taches.', 'Literie', 'Bon état', 30000, photo_lit),
    ('Draps et couvertures', 'Lot de draps et couvertures, propres et bien entretenus.', 'Literie', 'Très bon état', 7000, photo_lit),
    ('Lit pliant compact', 'Lit pliant compact, pratique pour petit espace.', 'Literie', 'Bon état', 25000, photo_lit),
    ('Table de chevet', 'Table de chevet en bois, un tiroir.', 'Mobilier', 'Bon état', 8000, photo_mobilier),
    ('Bibliothèque murale', 'Bibliothèque murale, plusieurs étagères.', 'Mobilier', 'Correct', 18000, photo_mobilier),
    ('Fauteuil confortable', 'Fauteuil confortable en tissu, bon état.', 'Mobilier', 'Bon état', 25000, photo_mobilier),
    ('Portant à vêtements', 'Portant à vêtements sur roulettes, pratique.', 'Mobilier', 'Correct', 10000, photo_mobilier),
    ('Marmite en aluminium', 'Grande marmite en aluminium, idéale pour cuisiner en groupe.', 'Cuisine', 'Bon état', 12000, photo_cuisine),
    ('Service à thé complet', 'Service à thé complet avec théière et tasses.', 'Cuisine', 'Très bon état', 10000, photo_cuisine),
    ('Glacière portable', 'Glacière portable, pratique pour garder les aliments frais.', 'Cuisine', 'Bon état', 14000, photo_cuisine),
    ('Radio portable à piles', 'Radio portable à piles, fonctionne bien.', 'Électronique', 'Correct', 5000, photo_electronique),
    ('Lampe torche rechargeable', 'Lampe torche rechargeable, forte autonomie.', 'Électronique', 'Bon état', 6000, photo_electronique),
    ('Multiprise avec parasurtenseur', 'Multiprise 6 prises avec protection contre les surtensions.', 'Électronique', 'Neuf', 7000, photo_electronique),
    ('Écouteurs filaires neufs', 'Écouteurs filaires neufs, jamais utilisés.', 'Électronique', 'Neuf', 4000, photo_electronique),
    ('Rame de papier + stylos', 'Rame de papier A4 et lot de stylos neufs.', 'Scolaire', 'Neuf', 3500, photo_scolaire),
    ('Classeurs et chemises', 'Lot de classeurs et chemises pour organiser les cours.', 'Scolaire', 'Très bon état', 4000, photo_scolaire),
    ('Cahiers et manuels universitaires', 'Cahiers et quelques manuels universitaires d''occasion.', 'Scolaire', 'Bon état', 8000, photo_scolaire),
    ('Tapis de sol', 'Tapis de sol confortable, facile à entretenir.', 'Divers', 'Bon état', 10000, photo_divers),
    ('Parapluie pliable', 'Parapluie pliable, résistant au vent.', 'Divers', 'Neuf', 3000, photo_divers),
    ('Panier à linge', 'Panier à linge en plastique tressé, pratique.', 'Divers', 'Correct', 4000, photo_divers)
  ) as v(titre, description, categorie, etat, prix, photos)
  where not exists (select 1 from public.articles a where a.titre = v.titre and a.vendeur_id = v_bruno);
end $$;

alter table public.users enable trigger user;
alter table public.logements enable trigger user;
alter table public.articles enable trigger user;

-- ── Lieux publics géocodés (OpenStreetMap Nominatim) ──────────
-- cree_par laissé null : ajoutés par cette migration, pas via l'écran
-- admin, pour ne pas avoir à connaître l'id du compte admin réel.
insert into public.lieux_publics (nom, categorie, lat, lng, ville, cree_par)
select * from (values
  ('Hôpital de District de Kribi', 'hopital', 2.9431129, 9.9106951, 'Kribi', null::uuid),
  ('Marché Central de Kribi', 'marche', 2.9405664, 9.9139608, 'Kribi', null::uuid),
  ('École Maternelle Publique de Kribi', 'ecole', 2.9444675, 9.9150155, 'Kribi', null::uuid),
  ('Cathédrale Saint-Joseph de Kribi', 'eglise', 2.9374787, 9.9081518, 'Kribi', null::uuid),
  ('Pharmacie de l''Atlantique', 'pharmacie', 2.9401370, 9.9136025, 'Kribi', null::uuid),
  ('Brigade de Gendarmerie de Kribi 1', 'commissariat', 2.9421466, 9.9138047, 'Kribi', null::uuid),
  ('Aéroport de Kribi', 'autre', 2.8742843, 9.9771073, 'Kribi', null::uuid),
  ('Hôpital Régional d''Ébolowa', 'hopital', 2.9248777, 11.1561619, 'Ébolowa', null::uuid),
  ('Marché Central d''Ébolowa', 'marche', 2.9206461, 11.1525020, 'Ébolowa', null::uuid),
  ('Lycée d''Ébolowa', 'ecole', 2.9362365, 11.1671167, 'Ébolowa', null::uuid),
  ('Cathédrale Sainte-Anne-et-Joachim d''Ébolowa', 'eglise', 2.9333765, 11.1341411, 'Ébolowa', null::uuid),
  ('Pharmacie du Bercail', 'pharmacie', 2.9208588, 11.1505664, 'Ébolowa', null::uuid),
  ('Commissariat Central d''Ébolowa', 'commissariat', 2.9176329, 11.1450291, 'Ébolowa', null::uuid),
  ('Université d''Ébolowa', 'autre', 2.8671356, 11.1803980, 'Ébolowa', null::uuid)
) as v(nom, categorie, lat, lng, ville, cree_par)
where not exists (
  select 1 from public.lieux_publics lp where lp.nom = v.nom and lp.ville = v.ville
);

commit;
