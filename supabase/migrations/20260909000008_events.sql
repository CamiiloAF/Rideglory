-- events: rodadas. Sin mapa interactivo en v2 (D10): destino como punto exacto + texto de ruta.

create table public.events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  description text,
  route_text text,
  start_at timestamptz not null,
  difficulty smallint not null check (difficulty between 1 and 5),
  destination_name text,
  destination_lat double precision,
  destination_lng double precision,
  image_path text,
  price integer not null default 0 check (price >= 0),
  max_participants integer check (max_participants is null or max_participants > 0),
  state public.event_state not null default 'draft',
  started_at timestamptz,
  start_reminder_sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.events.started_at is
  'Sellado por el servidor (trigger) al pasar a started. Nunca confiar en un valor del cliente.';
comment on column public.events.start_reminder_sent_at is
  'Marca que event-start-watchdog ya avisó de este evento. Garantiza que el push no se duplica.';

create index events_owner_id_idx on public.events (owner_id);
create index events_state_idx on public.events (state);

alter table public.events enable row level security;

create trigger set_events_updated_at
  before update on public.events
  for each row execute function public.set_updated_at();

-- Transiciones válidas: draft->published|cancelled, published->started|cancelled, started->finished.
-- started_at se sella con now() del servidor al entrar a 'started', ignorando cualquier valor
-- que venga en la fila del cliente.
create or replace function public.enforce_event_state_transition()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.state = old.state then
    -- Otros campos pueden cambiar sin que el estado se mueva; no se toca started_at aquí.
    new.started_at := old.started_at;
    return new;
  end if;

  if not (
    (old.state = 'draft' and new.state in ('published', 'cancelled'))
    or (old.state = 'published' and new.state in ('started', 'cancelled'))
    or (old.state = 'started' and new.state = 'finished')
  ) then
    raise exception 'invalid_event_state_transition: % -> %', old.state, new.state;
  end if;

  if new.state = 'started' then
    new.started_at := now();
  end if;

  return new;
end;
$$;

create trigger events_state_transition
  before update on public.events
  for each row execute function public.enforce_event_state_transition();

-- RLS: el organizador ve y administra su propio evento en cualquier estado; cualquier
-- autenticado ve eventos que ya salieron de borrador.
create policy events_select_visible
  on public.events for select
  to authenticated
  using (owner_id = auth.uid() or state <> 'draft');

create policy events_insert_own
  on public.events for insert
  to authenticated
  with check (owner_id = auth.uid() and state = 'draft');

create policy events_update_own
  on public.events for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy events_delete_own_draft
  on public.events for delete
  to authenticated
  using (owner_id = auth.uid() and state = 'draft');
