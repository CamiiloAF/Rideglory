-- Bloque 3 (D13-D23): tracking en vivo y SOS.
-- Transporte de posiciones: live_positions (D15, una fila por rider+evento, sin historial).
-- SOS: escritura durable en sos_alerts + Realtime + push (notify-sos), nunca solo broadcast.

create table public.live_positions (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  speed_kmh real,
  heading real,
  battery_pct smallint,
  accuracy_m real,
  recorded_at timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

comment on table public.live_positions is
  'Última posición conocida de cada rider en una rodada en curso. Una fila por rider+evento, sin historial: a 1 Hz por rider eso serían cientos de miles de filas que nadie consulta después. Si hace falta la ruta a posteriori, se persiste un resumen al cerrar el evento, no cada punto.';
comment on column public.live_positions.recorded_at is
  'Hora en el dispositivo del rider al capturar la posición (para descartar lecturas viejas en la UI). No es evidencia legal: updated_at es la hora del servidor.';

create index live_positions_event_id_idx on public.live_positions (event_id);

alter table public.live_positions enable row level security;
alter table public.live_positions replica identity full;

create table public.sos_alerts (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null unique,
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  accuracy_m real,
  message text,
  status text not null default 'active' check (status in ('active', 'closed')),
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  closed_by uuid,
  constraint sos_alerts_closed_fields_together check (
    (status = 'active' and closed_at is null and closed_by is null)
    or (status = 'closed' and closed_at is not null and closed_by is not null)
  )
);

comment on table public.sos_alerts is
  'Emergencia de rescate entre pares (no médica: no llama a servicios de emergencia por su cuenta). Escritura durable en Postgres, más broadcast por Realtime, más push vía notify-sos. Nunca cerrado por una desconexión ni por el fin del evento: solo por el rider que lo emitió o el organizador, vía close_sos.';
comment on column public.sos_alerts.client_id is
  'Id generado en el cliente antes de intentar la red: permite reintentar raise_sos sin duplicar la alerta si el primer intento sí llegó pero la respuesta se perdió.';
comment on column public.sos_alerts.created_at is
  'Sellado por el servidor (trigger seal_sos_alert_created_at), nunca por el reloj del teléfono.';
comment on column public.sos_alerts.closed_by is
  'Solo lo escribe la RPC close_sos. Un UPDATE que ponga status=closed sin closed_by es rechazado por el trigger protect_sos_alerts_mutation.';

create index sos_alerts_event_id_idx on public.sos_alerts (event_id);
create index sos_alerts_status_idx on public.sos_alerts (status);

alter table public.sos_alerts enable row level security;
alter table public.sos_alerts replica identity full;

-- Sella created_at con la hora del servidor en cada INSERT, ignorando cualquier valor enviado
-- por el cliente (el reloj del teléfono es manipulable).
create or replace function public.seal_sos_alert_created_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.created_at := now();
  new.closed_at := null;
  new.closed_by := null;
  new.status := 'active';
  return new;
end;
$$;

create trigger sos_alerts_seal_created_at
  before insert on public.sos_alerts
  for each row execute function public.seal_sos_alert_created_at();

-- Defensa en profundidad (igual que consent_log/event_registrations): aunque las únicas
-- escritoras sean las RPC security definer (que corren como el dueño de la función y por lo
-- tanto no pasan por GRANT ni por esta lógica salvo que ellas mismas hagan el UPDATE, momento en
-- el que el trigger sigue disparando), un UPDATE que intente reabrir un SOS cerrado, que cambie
-- created_at, o que ponga status='closed' sin closed_by/closed_at, se rechaza aquí. Nada del fin
-- del evento cierra un SOS: no hay trigger ni job que toque sos_alerts al terminar un evento.
create or replace function public.protect_sos_alerts_mutation()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.created_at is distinct from old.created_at then
    raise exception 'sos_alert_created_at_is_immutable';
  end if;

  if old.status = 'closed' then
    raise exception 'sos_alert_already_closed';
  end if;

  if new.status = 'closed' and (new.closed_by is null or new.closed_at is null) then
    raise exception 'sos_close_requires_closed_by_and_closed_at';
  end if;

  if new.status = 'active' and (new.closed_by is not null or new.closed_at is not null) then
    raise exception 'sos_active_cannot_have_closed_fields';
  end if;

  return new;
end;
$$;

create trigger sos_alerts_protect_mutation
  before update on public.sos_alerts
  for each row execute function public.protect_sos_alerts_mutation();

-- Helper de pertenencia a un evento: owner o inscrito aprobado. security definer para que las
-- políticas de RLS y las vistas de enmascarado compartan una sola definición de "quién puede ver
-- el tracking de esta rodada", sin duplicar la lógica.
create or replace function public.is_event_staff_or_approved(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.events e
    where e.id = p_event_id and e.owner_id = auth.uid()
  ) or exists (
    select 1 from public.event_registrations r
    where r.event_id = p_event_id and r.user_id = auth.uid() and r.status = 'approved'
  );
$$;

comment on function public.is_event_staff_or_approved(uuid) is
  'true si auth.uid() es el organizador del evento o un inscrito aprobado. Usado por RLS de live_positions/sos_alerts y por las vistas live_riders/sos_alerts_visible.';

-- RLS: solo select, filtrado por pertenencia al evento (para que postgres_changes de Realtime
-- respete el mismo filtro). Sin políticas de insert/update/delete para `authenticated`: toda
-- escritura pasa por las RPC de abajo, que corren security definer como dueño de la función.
create policy live_positions_select_participant
  on public.live_positions for select
  to authenticated
  using (public.is_event_staff_or_approved(event_id));

create policy sos_alerts_select_participant
  on public.sos_alerts for select
  to authenticated
  using (public.is_event_staff_or_approved(event_id));

grant select on public.live_positions to authenticated;
grant select on public.sos_alerts to authenticated;

alter publication supabase_realtime add table public.live_positions, public.sos_alerts;

-- RPC: upsert_live_position. Solo mientras el evento está 'started' y el caller es owner o
-- inscrito aprobado. Una fila por rider+evento (D15): sobreescribe la última posición.
create or replace function public.upsert_live_position(
  p_event_id uuid,
  p_lat double precision,
  p_lng double precision,
  p_speed_kmh real,
  p_heading real,
  p_battery_pct smallint,
  p_accuracy_m real,
  p_recorded_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_event_state public.event_state;
begin
  select state into v_event_state from public.events where id = p_event_id;

  if v_event_state is null then
    raise exception 'event_not_found';
  end if;

  if v_event_state <> 'started' then
    raise exception 'event_not_started';
  end if;

  if not public.is_event_staff_or_approved(p_event_id) then
    raise exception 'not_a_participant';
  end if;

  insert into public.live_positions (
    event_id, user_id, lat, lng, speed_kmh, heading, battery_pct, accuracy_m, recorded_at, updated_at
  ) values (
    p_event_id, auth.uid(), p_lat, p_lng, p_speed_kmh, p_heading, p_battery_pct, p_accuracy_m,
    p_recorded_at, now()
  )
  on conflict (event_id, user_id) do update set
    lat = excluded.lat,
    lng = excluded.lng,
    speed_kmh = excluded.speed_kmh,
    heading = excluded.heading,
    battery_pct = excluded.battery_pct,
    accuracy_m = excluded.accuracy_m,
    recorded_at = excluded.recorded_at,
    updated_at = now();
end;
$$;

grant execute on function public.upsert_live_position(
  uuid, double precision, double precision, real, real, smallint, real, timestamptz
) to authenticated;

-- RPC: raise_sos. Idempotente por client_id (un reintento del cliente nunca duplica la alerta).
-- Permite emitir SOS aunque el evento ya esté 'finished', mientras el caller haya sido owner o
-- inscrito aprobado. Si el evento sigue 'started', también deja esa posición en live_positions.
create or replace function public.raise_sos(
  p_client_id uuid,
  p_event_id uuid,
  p_lat double precision,
  p_lng double precision,
  p_accuracy_m real,
  p_message text
)
returns public.sos_alerts
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_existing public.sos_alerts;
  v_event_state public.event_state;
  v_row public.sos_alerts;
begin
  select * into v_existing from public.sos_alerts where client_id = p_client_id;
  if found then
    return v_existing;
  end if;

  select state into v_event_state from public.events where id = p_event_id;
  if v_event_state is null then
    raise exception 'event_not_found';
  end if;

  if not public.is_event_staff_or_approved(p_event_id) then
    raise exception 'not_a_participant';
  end if;

  insert into public.sos_alerts (client_id, event_id, user_id, lat, lng, accuracy_m, message)
  values (p_client_id, p_event_id, auth.uid(), p_lat, p_lng, p_accuracy_m, p_message)
  returning * into v_row;

  if v_event_state = 'started' then
    insert into public.live_positions (event_id, user_id, lat, lng, accuracy_m, recorded_at, updated_at)
    values (p_event_id, auth.uid(), p_lat, p_lng, p_accuracy_m, now(), now())
    on conflict (event_id, user_id) do update set
      lat = excluded.lat,
      lng = excluded.lng,
      accuracy_m = excluded.accuracy_m,
      recorded_at = excluded.recorded_at,
      updated_at = now();
  end if;

  return v_row;
end;
$$;

grant execute on function public.raise_sos(
  uuid, uuid, double precision, double precision, real, text
) to authenticated;

-- RPC: close_sos. Solo el rider que lo emitió o el organizador del evento. Idempotente: cerrar
-- un SOS ya cerrado devuelve la fila tal cual, sin error, para no romper un doble tap en la UI.
create or replace function public.close_sos(p_sos_id uuid)
returns public.sos_alerts
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sos public.sos_alerts;
  v_event_owner uuid;
begin
  select * into v_sos from public.sos_alerts where id = p_sos_id;
  if not found then
    raise exception 'sos_not_found';
  end if;

  select owner_id into v_event_owner from public.events where id = v_sos.event_id;

  if auth.uid() <> v_sos.user_id and auth.uid() <> v_event_owner then
    raise exception 'not_allowed_to_close';
  end if;

  if v_sos.status = 'closed' then
    return v_sos;
  end if;

  update public.sos_alerts
  set status = 'closed', closed_at = now(), closed_by = auth.uid()
  where id = p_sos_id
  returning * into v_sos;

  return v_sos;
end;
$$;

grant execute on function public.close_sos(uuid) to authenticated;

-- RPC: end_live_ride. Borra la última posición del caller para ese evento. Ninguna de las tres
-- razones de fin de tracking (Detener, evento finished, cierre de sesión) cierra un SOS.
create or replace function public.end_live_ride(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  delete from public.live_positions
  where event_id = p_event_id and user_id = auth.uid();
end;
$$;

grant execute on function public.end_live_ride(uuid) to authenticated;

-- RPC: get_live_ride_contacts. Para cachear al iniciar el tracking (D17): el teléfono del
-- organizador solo si el caller es inscrito aprobado (no filtra por allow_organizer_contact: es
-- el organizador exponiendo su propio contacto de rescate a sus inscritos, no al revés); el
-- contacto de emergencia es siempre el del propio caller, nunca el de otro rider.
create or replace function public.get_live_ride_contacts(p_event_id uuid)
returns table (
  organizer_name text,
  organizer_phone text,
  emergency_contact_name text,
  emergency_contact_phone text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner_id uuid;
  v_is_approved_participant boolean;
begin
  select owner_id into v_owner_id from public.events where id = p_event_id;
  if v_owner_id is null then
    raise exception 'event_not_found';
  end if;

  if not public.is_event_staff_or_approved(p_event_id) then
    raise exception 'not_a_participant';
  end if;

  select exists (
    select 1 from public.event_registrations r
    where r.event_id = p_event_id and r.user_id = auth.uid() and r.status = 'approved'
  ) into v_is_approved_participant;

  return query
  select
    organizer.full_name as organizer_name,
    case when v_is_approved_participant then organizer.phone else null end as organizer_phone,
    caller.emergency_contact_name,
    caller.emergency_contact_phone
  from public.profiles organizer
  left join public.profiles caller on caller.id = auth.uid()
  where organizer.id = v_owner_id;
end;
$$;

grant execute on function public.get_live_ride_contacts(uuid) to authenticated;

-- Vista de enmascarado: quién está dónde en la rodada. Solo owner/inscritos aprobados. Sin
-- teléfono ni correo (eso lo resuelve get_live_ride_contacts, con su propia regla de consentimiento).
create view public.live_riders
  with (security_invoker = false, security_barrier = true)
  as
select
  lp.event_id,
  lp.user_id,
  coalesce(p.full_name, '') as full_name,
  (e.owner_id = lp.user_id) as is_organizer,
  lp.lat,
  lp.lng,
  lp.speed_kmh,
  lp.heading,
  lp.battery_pct,
  lp.accuracy_m,
  lp.recorded_at,
  lp.updated_at
from public.live_positions lp
join public.events e on e.id = lp.event_id
left join public.profiles p on p.id = lp.user_id
where public.is_event_staff_or_approved(lp.event_id);

comment on view public.live_riders is
  'Quién está dónde en una rodada en curso, visible solo para el organizador y los inscritos aprobados del mismo evento. Nunca expone teléfono ni correo.';

grant select on public.live_riders to authenticated;

-- Vista de enmascarado del SOS. rider_phone SÍ se incluye a propósito: el SOS es rescate entre
-- pares (CLAUDE.md, regla 6 de seguridad del rider) y que los compañeros puedan llamar al rider
-- es parte del rescate mismo, no una fuga de datos de contacto -- a diferencia de
-- event_registrations_for_organizer, aquí no aplica allow_organizer_contact: la emergencia no
-- espera el consentimiento de contacto ordinario.
create view public.sos_alerts_visible
  with (security_invoker = false, security_barrier = true)
  as
select
  s.id,
  s.event_id,
  s.user_id,
  coalesce(p.full_name, '') as rider_name,
  p.phone as rider_phone,
  s.lat,
  s.lng,
  s.accuracy_m,
  s.message,
  s.status,
  s.created_at,
  s.closed_at,
  s.closed_by
from public.sos_alerts s
left join public.profiles p on p.id = s.user_id
where public.is_event_staff_or_approved(s.event_id);

comment on view public.sos_alerts_visible is
  'SOS visibles para el organizador y los inscritos aprobados del evento. rider_phone incluido a propósito: el SOS es rescate entre pares.';

grant select on public.sos_alerts_visible to authenticated;
