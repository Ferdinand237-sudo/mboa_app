-- Lieux publics ajoutés par l'administrateur (écoles, églises, hôpitaux, marchés...)
create table if not exists public.lieux_publics (
  id uuid default uuid_generate_v4() primary key,
  nom text not null,
  categorie text not null check (categorie = any (array['ecole','eglise','hopital','marche','pharmacie','commissariat','autre'])),
  lat double precision not null,
  lng double precision not null,
  cree_par uuid references public.users(id) on delete set null,
  created_at timestamp with time zone default now()
);

alter table public.lieux_publics enable row level security;

create policy "Tout le monde peut voir les lieux publics" on public.lieux_publics
  for select using (true);

create policy "Seul un admin peut ajouter des lieux" on public.lieux_publics
  for insert with check (
    exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );

create policy "Seul un admin peut modifier des lieux" on public.lieux_publics
  for update using (
    exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );

create policy "Seul un admin peut supprimer des lieux" on public.lieux_publics
  for delete using (
    exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );
