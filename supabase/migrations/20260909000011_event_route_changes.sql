-- event_route_changes: avisos de cambio de ruta/contingencia. Cada fila dispara un push
-- (notify-route-change) a los inscritos aprobados. Es un log, no se edita ni se borra.

create table public.event_route_changes (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  message text not null,
  created_at timestamptz not null default now()
);

create index event_route_changes_event_id_idx on public.event_route_changes (event_id);

alter table public.event_route_changes enable row level security;

create policy event_route_changes_select_participant
  on public.event_route_changes for select
  to authenticated
  using (
    exists (
      select 1 from public.events e
      where e.id = event_route_changes.event_id and e.owner_id = auth.uid()
    )
    or exists (
      select 1 from public.event_registrations r
      where r.event_id = event_route_changes.event_id
        and r.user_id = auth.uid()
        and r.status = 'approved'
    )
  );

create policy event_route_changes_insert_organizer
  on public.event_route_changes for insert
  to authenticated
  with check (
    exists (
      select 1 from public.events e
      where e.id = event_route_changes.event_id
        and e.owner_id = auth.uid()
        and e.state in ('published', 'started')
    )
  );
