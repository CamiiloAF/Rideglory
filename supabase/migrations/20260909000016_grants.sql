-- Con auto_expose_new_tables desactivado (comportamiento nuevo por defecto), una tabla con RLS
-- pero sin GRANT no es alcanzable por ningún rol de la API: el permiso a nivel de tabla se
-- evalúa antes que las políticas de RLS. Se otorgan los privilegios mínimos por operación a
-- `authenticated`; RLS sigue siendo la que decide qué filas ve cada quien. `anon` no recibe
-- privilegios: toda la app opera autenticada.

grant usage on schema public to authenticated;

-- service_role ya tiene BYPASSRLS (lo asigna Supabase), pero sin GRANT de tabla el permiso se
-- deniega antes de siquiera evaluar RLS. Las Edge Functions son las únicas que usan esta llave.
grant usage on schema public to service_role;
grant all on all tables in schema public to service_role;
alter default privileges in schema public grant all on tables to service_role;

grant select, insert, update on public.profiles to authenticated;

grant select, insert, update, delete on public.vehicles to authenticated;
grant select, insert, update, delete on public.maintenances to authenticated;
grant select, insert, update, delete on public.vehicle_documents to authenticated;

grant select, insert, update, delete on public.events to authenticated;

grant select, insert, update on public.event_registrations to authenticated;

grant select, insert on public.event_route_changes to authenticated;

grant select, insert, update, delete on public.device_tokens to authenticated;

grant select, insert on public.consent_log to authenticated;
