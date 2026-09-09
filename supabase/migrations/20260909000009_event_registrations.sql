-- event_registrations: inscripción de un rider a un evento, con snapshot legal de sus datos
-- al momento de inscribirse (no se relee el perfil después: es evidencia de lo que aceptó).

create table public.event_registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  vehicle_id uuid references public.vehicles (id) on delete set null,
  status public.registration_status not null default 'pending',

  full_name text not null,
  phone text not null,
  blood_type public.blood_type,
  eps text,
  emergency_contact_name text not null,
  emergency_contact_phone text not null,

  share_medical_info boolean not null default false,
  allow_organizer_contact boolean not null default false,

  risk_accepted_at timestamptz,
  medical_consent_at timestamptz,
  consent_version text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (event_id, user_id)
);

comment on column public.event_registrations.risk_accepted_at is
  'Sellado con now() del servidor al insertar. Inmutable: ver trigger prevent_consent_mutation.';
comment on column public.event_registrations.blood_type is
  'Solo visible para el organizador si share_medical_info=true, vía event_registrations_for_organizer.';

create index event_registrations_event_id_idx on public.event_registrations (event_id);
create index event_registrations_user_id_idx on public.event_registrations (user_id);

alter table public.event_registrations enable row level security;

create trigger set_event_registrations_updated_at
  before update on public.event_registrations
  for each row execute function public.set_updated_at();

-- Edad mínima 18 años, validada en el servidor contra profiles.birth_date (D12, requisito legal).
create or replace function public.check_registration_age()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_birth_date date;
begin
  select birth_date into v_birth_date
  from public.profiles
  where id = new.user_id;

  if v_birth_date is null then
    raise exception 'birth_date_required_for_registration';
  end if;

  if age(current_date, v_birth_date) < interval '18 years' then
    raise exception 'registration_requires_18_years_or_older';
  end if;

  return new;
end;
$$;

create trigger event_registrations_check_age
  before insert on public.event_registrations
  for each row execute function public.check_registration_age();

-- Los sellos de consentimiento nunca viajan desde el cliente: si la fila trae un valor no nulo
-- en risk_accepted_at / medical_consent_at (es decir, el rider marcó que acepta), se sobreescribe
-- siempre con now() del servidor. Si viene nulo (no aceptó ese consentimiento), se respeta el nulo.
create or replace function public.seal_registration_consent_timestamps()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.risk_accepted_at is not null then
    new.risk_accepted_at := now();
  end if;
  if new.medical_consent_at is not null then
    new.medical_consent_at := now();
  end if;
  return new;
end;
$$;

create trigger event_registrations_seal_consent
  before insert on public.event_registrations
  for each row execute function public.seal_registration_consent_timestamps();

-- Los sellos de consentimiento y su versión son evidencia legal: una vez escritos, ninguna
-- UPDATE puede tocarlos. Un cambio de decisión se modela como fila nueva (cancelar + reinscribir).
create or replace function public.prevent_consent_mutation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.risk_accepted_at is distinct from old.risk_accepted_at
     or new.medical_consent_at is distinct from old.medical_consent_at
     or new.consent_version is distinct from old.consent_version then
    raise exception 'consent_fields_are_immutable';
  end if;
  return new;
end;
$$;

create trigger event_registrations_protect_consent
  before update on public.event_registrations
  for each row execute function public.prevent_consent_mutation();

-- RLS: cada rider ve y crea solo su propia inscripción, y solo puede cambiar su propio estado
-- a 'cancelled' (aprobar/rechazar es del organizador, vía la función organizer_set_registration_status
-- para no darle acceso de columna directo a la fila cruda).
create policy event_registrations_select_own
  on public.event_registrations for select
  to authenticated
  using (user_id = auth.uid());

create policy event_registrations_insert_own
  on public.event_registrations for insert
  to authenticated
  with check (user_id = auth.uid());

create policy event_registrations_update_own_cancel
  on public.event_registrations for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and status = 'cancelled');
