-- Pruebas de RLS con pgTAP. Corren con: supabase test db supabase/tests/rls.sql
-- Cada escenario autentica una sesión real (set role authenticated + request.jwt.claim.sub) y
-- comprueba que la consulta del intruso devuelve cero filas o un error, no que "la política se
-- ve bien" leída.

begin;
create extension if not exists pgtap with schema extensions;

select plan(9);

-- Datos de prueba, insertados con privilegios de superusuario (bypassa RLS por diseño: es setup).
set local role postgres;

insert into auth.users (
  id, email, instance_id, aud, role, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) values
  ('a0000000-0000-0000-0000-00000000000a', 'rider.a@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', crypt('Test123.', gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-00000000000b', 'rider.b@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', crypt('Test123.', gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', ''),
  ('c0000000-0000-0000-0000-00000000000c', 'organizer.c@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', crypt('Test123.', gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', ''),
  ('d0000000-0000-0000-0000-00000000000d', 'minor.d@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', crypt('Test123.', gen_salt('bf')), now(), '{}', '{}', now(), now(), '', '', '', '');

update public.profiles set birth_date = date '1990-01-01' where id in (
  'a0000000-0000-0000-0000-00000000000a',
  'b0000000-0000-0000-0000-00000000000b',
  'c0000000-0000-0000-0000-00000000000c'
);
update public.profiles set birth_date = current_date - interval '10 years' where id = 'd0000000-0000-0000-0000-00000000000d';

insert into public.vehicles (id, owner_id, name, brand)
values ('a1000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-00000000000a', 'Moto de A', 'Yamaha');
insert into public.vehicles (id, owner_id, name, brand)
values ('b1000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000b', 'Moto de B', 'Honda');

insert into public.events (id, owner_id, name, start_at, difficulty, state)
values ('c1000000-0000-0000-0000-00000000000c', 'c0000000-0000-0000-0000-00000000000c', 'Evento de prueba', now() + interval '1 day', 2, 'draft');
update public.events set state = 'published' where id = 'c1000000-0000-0000-0000-00000000000c';

insert into public.event_registrations (
  event_id, user_id, full_name, phone, blood_type, emergency_contact_name,
  emergency_contact_phone, share_medical_info, allow_organizer_contact
) values (
  'c1000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-00000000000a',
  'Rider A', '3000000001', 'o_positive', 'Contacto de A', '3000000002', false, true
);

-- 1) Rider A no ve el vehículo de Rider B.
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-00000000000a';

select is(
  (select count(*) from public.vehicles where id = 'b1000000-0000-0000-0000-00000000000b'),
  0::bigint,
  'Rider A no puede leer el vehículo de Rider B'
);

select is(
  (select count(*) from public.vehicles where owner_id = 'a0000000-0000-0000-0000-00000000000a'),
  1::bigint,
  'Rider A sí ve su propio vehículo'
);

-- 2) El organizador NO ve blood_type cuando share_medical_info=false, pero sí ve el teléfono
--    porque allow_organizer_contact=true.
set local role authenticated;
set local request.jwt.claim.sub = 'c0000000-0000-0000-0000-00000000000c';

select is(
  (select blood_type from public.event_registrations_for_organizer
   where user_id = 'a0000000-0000-0000-0000-00000000000a'),
  null,
  'El organizador no ve blood_type sin consentimiento médico'
);

select is(
  (select phone from public.event_registrations_for_organizer
   where user_id = 'a0000000-0000-0000-0000-00000000000a'),
  '3000000001',
  'El organizador sí ve el teléfono porque allow_organizer_contact=true'
);

-- El organizador tampoco puede sortear la vista leyendo la tabla base directamente: no tiene
-- fila propia ahí (solo ve las suyas), así que la fila de Rider A no le aparece.
select is(
  (select count(*) from public.event_registrations where user_id = 'a0000000-0000-0000-0000-00000000000a'),
  0::bigint,
  'El organizador no puede leer la fila cruda de event_registrations de otro usuario'
);

-- 3) Un menor de 18 no puede inscribirse a un evento.
set local role authenticated;
set local request.jwt.claim.sub = 'd0000000-0000-0000-0000-00000000000d';

select throws_like(
  $$insert into public.event_registrations (
      event_id, user_id, full_name, phone, emergency_contact_name, emergency_contact_phone
    ) values (
      'c1000000-0000-0000-0000-00000000000c', 'd0000000-0000-0000-0000-00000000000d',
      'Menor de edad', '3000000003', 'Contacto', '3000000004'
    )$$,
  '%registration_requires_18_years_or_older%',
  'Un menor de 18 años no puede inscribirse a un evento'
);

-- 4) consent_log es inmutable: ni el propio autor puede actualizarlo ni borrarlo.
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-00000000000a';

insert into public.consent_log (user_id, kind, version)
values ('a0000000-0000-0000-0000-00000000000a', 'terms', 'v1');

-- No hay GRANT de UPDATE/DELETE a authenticated sobre consent_log (a propósito: "sin política
-- de update ni delete para el usuario"), así que el intento falla antes de llegar al trigger.
-- El trigger reject_consent_log_mutation() queda como defensa en profundidad si algún día se
-- otorgara el privilegio por error.
select throws_like(
  $$update public.consent_log set version = 'v2'
    where user_id = 'a0000000-0000-0000-0000-00000000000a' and kind = 'terms'$$,
  '%permission denied for table consent_log%',
  'consent_log no admite UPDATE, ni siquiera del propio autor'
);

select throws_like(
  $$delete from public.consent_log
    where user_id = 'a0000000-0000-0000-0000-00000000000a' and kind = 'terms'$$,
  '%permission denied for table consent_log%',
  'consent_log no admite DELETE, ni siquiera del propio autor'
);

-- 5) Rider A (no organizador) no puede pasar el evento de otro a 'started'.
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-00000000000a';

update public.events set state = 'started'
where id = 'c1000000-0000-0000-0000-00000000000c';

set local role postgres;
select is(
  (select state from public.events where id = 'c1000000-0000-0000-0000-00000000000c'),
  'published'::public.event_state,
  'El evento ajeno sigue en published: el intento de otro usuario no tuvo efecto'
);

select * from finish();
rollback;
