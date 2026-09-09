-- maintenances: historial y agenda de servicio de cada moto.

create table public.maintenances (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  type text not null,
  service_date date,
  odometer integer,
  cost numeric(12, 2),
  workshop text,
  notes text,
  next_date date,
  next_odometer integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index maintenances_vehicle_id_idx on public.maintenances (vehicle_id);

alter table public.maintenances enable row level security;

create trigger set_maintenances_updated_at
  before update on public.maintenances
  for each row execute function public.set_updated_at();

-- El dueño de la moto es el dueño de sus mantenimientos: no hay columna owner_id propia,
-- se resuelve contra vehicles.owner_id en cada política.
create policy maintenances_select_own
  on public.maintenances for select
  to authenticated
  using (
    exists (
      select 1 from public.vehicles
      where vehicles.id = maintenances.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  );

create policy maintenances_insert_own
  on public.maintenances for insert
  to authenticated
  with check (
    exists (
      select 1 from public.vehicles
      where vehicles.id = maintenances.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  );

create policy maintenances_update_own
  on public.maintenances for update
  to authenticated
  using (
    exists (
      select 1 from public.vehicles
      where vehicles.id = maintenances.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.vehicles
      where vehicles.id = maintenances.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  );

create policy maintenances_delete_own
  on public.maintenances for delete
  to authenticated
  using (
    exists (
      select 1 from public.vehicles
      where vehicles.id = maintenances.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  );
