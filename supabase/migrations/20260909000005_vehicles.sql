-- vehicles: el garaje de cada rider.

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  brand text not null,
  model text,
  year integer,
  license_plate text,
  current_mileage integer not null default 0,
  image_path text,
  is_main boolean not null default false,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.vehicles.image_path is
  'Ruta dentro del bucket privado vehicle-images, prefijo <owner_id>/. Nunca una URL pública.';

create index vehicles_owner_id_idx on public.vehicles (owner_id);

alter table public.vehicles enable row level security;

create trigger set_vehicles_updated_at
  before update on public.vehicles
  for each row execute function public.set_updated_at();

create policy vehicles_select_own
  on public.vehicles for select
  to authenticated
  using (owner_id = auth.uid());

create policy vehicles_insert_own
  on public.vehicles for insert
  to authenticated
  with check (owner_id = auth.uid());

create policy vehicles_update_own
  on public.vehicles for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy vehicles_delete_own
  on public.vehicles for delete
  to authenticated
  using (owner_id = auth.uid());
