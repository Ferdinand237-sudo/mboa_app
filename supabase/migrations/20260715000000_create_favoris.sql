-- Table des favoris (logements enregistrés par un utilisateur)
create table if not exists public.favoris (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade,
  logement_id uuid references public.logements(id) on delete cascade,
  created_at timestamp with time zone default now(),
  unique(user_id, logement_id)
);

alter table public.favoris enable row level security;

create policy "User gère ses favoris" on public.favoris
  for all using (auth.uid() = user_id);
