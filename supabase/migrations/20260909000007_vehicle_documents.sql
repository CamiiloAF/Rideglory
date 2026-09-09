-- vehicle_documents: SOAT y RTM de cada moto, con recordatorio local controlado por el usuario.

create table public.vehicle_documents (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  kind public.document_kind not null,
  number text,
  issuer text,
  start_date date,
  expiry_date date not null,
  file_path text,
  reminder_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (vehicle_id, kind)
);

comment on column public.vehicle_documents.file_path is
  'Ruta dentro del bucket privado documents, prefijo <owner_id>/. Nunca pública: contiene la placa y datos de terceros.';

create index vehicle_documents_vehicle_id_idx on public.vehicle_documents (vehicle_id);

alter table public.vehicle_documents enable row level security;

create trigger set_vehicle_documents_updated_at
  before update on public.vehicle_documents
  for each row execute function public.set_updated_at();

create policy vehicle_documents_select_own
  on public.vehicle_documents for select
  to authenticated
  using (
    exists (
      select 1 from public.vehicles
      where vehicles.id = vehicle_documents.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  );

create policy vehicle_documents_insert_own
  on public.vehicle_documents for insert
  to authenticated
  with check (
    exists (
      select 1 from public.vehicles
      where vehicles.id = vehicle_documents.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  );

create policy vehicle_documents_update_own
  on public.vehicle_documents for update
  to authenticated
  using (
    exists (
      select 1 from public.vehicles
      where vehicles.id = vehicle_documents.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.vehicles
      where vehicles.id = vehicle_documents.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  );

create policy vehicle_documents_delete_own
  on public.vehicle_documents for delete
  to authenticated
  using (
    exists (
      select 1 from public.vehicles
      where vehicles.id = vehicle_documents.vehicle_id
        and vehicles.owner_id = auth.uid()
    )
  );
