-- Funciones auxiliares compartidas por triggers de todo el esquema.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function public.set_updated_at() is
  'Sella updated_at con la hora del servidor en cada UPDATE. Nunca confiar en un valor enviado por el cliente.';
