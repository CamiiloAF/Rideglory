-- consent_log: evidencia legal de cada consentimiento aceptado (riesgo, médico, términos).
-- Inmutable por diseño: sin política de update/delete y, por si acaso, un trigger que las
-- rechaza sin importar el rol. Sobrevive a la anonimización de la cuenta: user_id se guarda
-- como valor, sin FK a auth.users, para que borrar el usuario (delete-account) nunca toque
-- esta tabla ni dispare un ON DELETE que la mutaría.

create table public.consent_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  kind public.consent_kind not null,
  version text not null,
  accepted_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

comment on column public.consent_log.user_id is
  'Sin FK a auth.users a propósito: esta fila debe sobrevivir intacta al borrado de cuenta (evidencia legal).';

create index consent_log_user_id_idx on public.consent_log (user_id);

alter table public.consent_log enable row level security;

create policy consent_log_select_own
  on public.consent_log for select
  to authenticated
  using (user_id = auth.uid());

create policy consent_log_insert_own
  on public.consent_log for insert
  to authenticated
  with check (user_id = auth.uid());

-- El timestamp legal nunca viaja desde el cliente: se sella siempre con now() del servidor,
-- sin importar qué valor venga en la fila del INSERT.
create or replace function public.seal_consent_log_timestamp()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.accepted_at := now();
  return new;
end;
$$;

create trigger consent_log_seal_timestamp
  before insert on public.consent_log
  for each row execute function public.seal_consent_log_timestamp();

-- Defensa en profundidad: aunque nunca se declare una política de update/delete, un trigger
-- explícito rechaza cualquier intento, venga del rol que venga.
create or replace function public.reject_consent_log_mutation()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  raise exception 'consent_log_is_immutable';
end;
$$;

create trigger consent_log_block_update
  before update on public.consent_log
  for each row execute function public.reject_consent_log_mutation();

create trigger consent_log_block_delete
  before delete on public.consent_log
  for each row execute function public.reject_consent_log_mutation();
