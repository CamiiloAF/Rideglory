-- profiles: 1:1 con auth.users. Contiene datos de contacto y médicos sensibles del rider.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  phone text,
  birth_date date,
  residence_city text,
  eps text,
  medical_insurance text,
  blood_type public.blood_type,
  emergency_contact_name text,
  emergency_contact_phone text,
  medical_consent_accepted_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is
  'Perfil del rider. Datos médicos y de contacto: nunca se exponen crudos a otros usuarios, solo a través de vistas con enmascarado.';

alter table public.profiles enable row level security;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Un perfil se crea automáticamente cuando se crea el usuario en auth.users.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- RLS: cada quien ve y edita solo su propio perfil. Sin insert/delete directos desde el
-- cliente: el perfil nace por el trigger de auth.users y se borra vía la Edge Function
-- delete-account con service_role.
create policy profiles_select_own
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

create policy profiles_update_own
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
