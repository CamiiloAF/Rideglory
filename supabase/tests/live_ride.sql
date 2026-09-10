-- Pruebas de RLS y RPCs del Bloque 3 (live_positions, sos_alerts). Corren con:
-- supabase test db supabase/tests/live_ride.sql
-- Reutiliza los usuarios y la rodada "Rodada en curso" del seed (qa2 organiza, qa1 aprobado) y
-- suma un tercer usuario no inscrito para probar el caso negativo.

begin;
create extension if not exists pgtap with schema extensions;

select plan(11);

set local role postgres;

-- Tercer usuario, no inscrito a ninguna rodada.
insert into auth.users (
  id, email, instance_id, aud, role, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) values (
  'e0000000-0000-0000-0000-00000000000e', 'outsider.e@test.local',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  crypt('Test123.', gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', ''
);
update public.profiles set birth_date = date '1990-01-01'
where id = 'e0000000-0000-0000-0000-00000000000e';

-- IDs del seed.
-- qa1: 11111111-1111-1111-1111-111111111111 (aprobado en "Rodada en curso")
-- qa2: 22222222-2222-2222-2222-222222222222 (organizador de "Rodada en curso" y de "Mi Evento")
-- Rodada en curso: 55555555-5555-5555-5555-555555555555 (started)
-- Mi Evento: 44444444-4444-4444-4444-444444444444 (published, nunca started)

-- 1) qa1 (aprobado) ve live_riders de la rodada en curso, y NO ve teléfono (la vista no expone
--    esa columna en absoluto: comprobamos que la fila del organizador aparece sin ese dato).
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select is(
  (select count(*) from public.live_riders
   where event_id = '55555555-5555-5555-5555-555555555555'
     and user_id = '22222222-2222-2222-2222-222222222222'),
  1::bigint,
  'qa1 (aprobado) ve la posición en vivo del organizador de la rodada en curso'
);

select is(
  (select count(*) from information_schema.columns
   where table_schema = 'public' and table_name = 'live_riders'
     and column_name in ('phone', 'email')),
  0::bigint,
  'live_riders no expone columnas de teléfono ni correo'
);

-- 2) Un tercero no inscrito no ve ninguna fila de esa rodada.
set local role authenticated;
set local request.jwt.claim.sub = 'e0000000-0000-0000-0000-00000000000e';

select is(
  (select count(*) from public.live_riders
   where event_id = '55555555-5555-5555-5555-555555555555'),
  0::bigint,
  'Un usuario no aprobado no ve filas de live_riders de la rodada en curso'
);

select is(
  (select count(*) from public.live_positions
   where event_id = '55555555-5555-5555-5555-555555555555'),
  0::bigint,
  'Un usuario no aprobado tampoco ve filas de la tabla base live_positions (RLS, no solo la vista)'
);

-- 3) upsert_live_position falla con event_not_started sobre "Mi Evento" (published, no started),
--    incluso para su propio organizador.
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

select throws_like(
  $$select public.upsert_live_position(
      '44444444-4444-4444-4444-444444444444'::uuid, 4.7186, -73.9683,
      30::real, 90::real, 80::smallint, 10::real, now()
    )$$,
  '%event_not_started%',
  'upsert_live_position falla con event_not_started sobre un evento publicado que no ha iniciado'
);

-- 4) raise_sos es idempotente por client_id: dos llamadas con el mismo client_id devuelven la
--    misma fila y no crean una segunda.
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select public.raise_sos(
  'f0000000-0000-0000-0000-00000000000f'::uuid,
  '55555555-5555-5555-5555-555555555555'::uuid,
  6.2442, -75.5812, 8::real, 'Se me cayó la moto'
);

select is(
  (
    select (public.raise_sos(
      'f0000000-0000-0000-0000-00000000000f'::uuid,
      '55555555-5555-5555-5555-555555555555'::uuid,
      6.2500, -75.5900, 5::real, 'mensaje distinto, no debería aplicar'
    )).id
  ),
  (select id from public.sos_alerts where client_id = 'f0000000-0000-0000-0000-00000000000f'::uuid),
  'raise_sos con el mismo client_id devuelve la fila existente, no crea una segunda'
);

select is(
  (select count(*) from public.sos_alerts where client_id = 'f0000000-0000-0000-0000-00000000000f'::uuid),
  1::bigint,
  'Solo existe una fila de sos_alerts para ese client_id tras dos llamadas a raise_sos'
);

-- El outsider no puede resolver el id del SOS con una consulta propia (RLS se lo impide), así
-- que se lo dejamos en una tabla temporal de la sesión, resuelta con privilegios de postgres,
-- para poder ejercitar close_sos como intruso sin que el fallo sea "no pude ni encontrar el id".
set local role postgres;
create temporary table _test_sos_ids (label text primary key, id uuid not null);
insert into _test_sos_ids values (
  'f', (select id from public.sos_alerts where client_id = 'f0000000-0000-0000-0000-00000000000f'::uuid)
);
grant select on _test_sos_ids to authenticated;

-- 5) close_sos: un tercero no puede cerrarlo; el organizador sí.
set local role authenticated;
set local request.jwt.claim.sub = 'e0000000-0000-0000-0000-00000000000e';

select throws_like(
  $$select public.close_sos((select id from _test_sos_ids where label = 'f'))$$,
  '%not_allowed_to_close%',
  'Un tercero ajeno al SOS y al evento no puede cerrarlo'
);

set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

select is(
  (select (public.close_sos((select id from _test_sos_ids where label = 'f'))).status),
  'closed',
  'El organizador del evento sí puede cerrar el SOS'
);

-- 6) Un UPDATE directo a sos_alerts (sin pasar por close_sos) es rechazado por RLS: no hay
--    política ni GRANT de UPDATE para `authenticated`.
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select throws_like(
  $$update public.sos_alerts set message = 'edición directa'
    where client_id = 'f0000000-0000-0000-0000-00000000000f'::uuid$$,
  '%permission denied for table sos_alerts%',
  'Un UPDATE directo a sos_alerts es rechazado por falta de GRANT/RLS de escritura'
);

-- 7) sos_alerts.created_at ignora cualquier valor enviado por el cliente: se prueba insertando
--    directamente como postgres (bypassa RLS, simula un intento de forjar la fecha) y
--    comprobando que el trigger igual la sobreescribe con now().
set local role postgres;

insert into public.sos_alerts (client_id, event_id, user_id, lat, lng, accuracy_m, message, created_at)
values (
  'a1000000-1111-1111-1111-1111111111a1'::uuid,
  '55555555-5555-5555-5555-555555555555'::uuid,
  '11111111-1111-1111-1111-111111111111'::uuid,
  6.2, -75.5, 10, 'intento de forjar la fecha',
  '2000-01-01T00:00:00Z'::timestamptz
);

select ok(
  (select created_at from public.sos_alerts where client_id = 'a1000000-1111-1111-1111-1111111111a1'::uuid)
    > now() - interval '1 minute',
  'sos_alerts.created_at se sella con now() del servidor, ignorando el valor enviado en el INSERT'
);

select * from finish();
rollback;
