-- Seed de QA local. Password 'Test123.' para ambos usuarios (bcrypt precomputado con costo 10).
-- qa1@gmail.com: rider con moto, mantenimiento y SOAT.
-- qa2@gmail.com: organizador de "Mi Evento" (publicado) y de "Rodada en curso" (started).

do $$
declare
  v_qa1_id uuid := '11111111-1111-1111-1111-111111111111';
  v_qa2_id uuid := '22222222-2222-2222-2222-222222222222';
  v_vehicle_id uuid := '33333333-3333-3333-3333-333333333333';
  v_event_id uuid := '44444444-4444-4444-4444-444444444444';
  v_live_event_id uuid := '55555555-5555-5555-5555-555555555555';
  v_encrypted_password text := crypt('Test123.', gen_salt('bf'));
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token,
    email_change_token_new, email_change
  ) values
  (
    '00000000-0000-0000-0000-000000000000', v_qa1_id, 'authenticated', 'authenticated',
    'qa1@gmail.com', v_encrypted_password, now(),
    '{"provider":"email","providers":["email"]}', '{"full_name":"QA Rider Uno"}',
    now(), now(), '', '', '', ''
  ),
  (
    '00000000-0000-0000-0000-000000000000', v_qa2_id, 'authenticated', 'authenticated',
    'qa2@gmail.com', v_encrypted_password, now(),
    '{"provider":"email","providers":["email"]}', '{"full_name":"QA Organizador Dos"}',
    now(), now(), '', '', '', ''
  )
  on conflict (id) do nothing;

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) values
  (
    gen_random_uuid(), v_qa1_id::text, v_qa1_id,
    jsonb_build_object('sub', v_qa1_id::text, 'email', 'qa1@gmail.com'),
    'email', now(), now(), now()
  ),
  (
    gen_random_uuid(), v_qa2_id::text, v_qa2_id,
    jsonb_build_object('sub', v_qa2_id::text, 'email', 'qa2@gmail.com'),
    'email', now(), now(), now()
  )
  on conflict (provider_id, provider) do nothing;

  -- profiles ya existen por el trigger on_auth_user_created; se completan con datos de QA.
  update public.profiles set
    full_name = 'QA Rider Uno',
    phone = '3001112233',
    birth_date = date '1995-04-12',
    residence_city = 'Medellín',
    eps = 'Sura EPS',
    medical_insurance = 'Sura',
    blood_type = 'o_positive',
    emergency_contact_name = 'Contacto QA Uno',
    emergency_contact_phone = '3009998877'
  where id = v_qa1_id;

  update public.profiles set
    full_name = 'QA Organizador Dos',
    phone = '3004445566',
    birth_date = date '1990-01-20',
    residence_city = 'Bogotá',
    eps = 'Sanitas EPS',
    medical_insurance = 'Sanitas',
    blood_type = 'a_positive',
    emergency_contact_name = 'Contacto QA Dos',
    emergency_contact_phone = '3006667788'
  where id = v_qa2_id;

  insert into public.vehicles (
    id, owner_id, name, brand, model, year, license_plate, current_mileage, is_main
  ) values (
    v_vehicle_id, v_qa1_id, 'La Negra', 'Yamaha', 'MT-03', 2022, 'ABC12D', 8500, true
  ) on conflict (id) do nothing;

  insert into public.maintenances (
    vehicle_id, type, service_date, odometer, cost, workshop, notes
  ) values (
    v_vehicle_id, 'Cambio de aceite', current_date - interval '20 days', 8500, 120000,
    'Taller Central', 'Aceite 10W40 + filtro'
  ) on conflict do nothing;

  insert into public.vehicle_documents (
    vehicle_id, kind, number, issuer, start_date, expiry_date, reminder_enabled
  ) values (
    v_vehicle_id, 'soat', 'SOAT-QA-0001', 'Seguros Bolívar',
    current_date - interval '2 months', current_date + interval '10 months', true
  ) on conflict (vehicle_id, kind) do nothing;

  insert into public.events (
    id, owner_id, name, description, route_text, start_at, difficulty,
    destination_name, destination_lat, destination_lng, price, max_participants, state
  ) values (
    v_event_id, v_qa2_id, 'Mi Evento',
    'Rodada de prueba para QA.', 'Salida desde el Parque de la 93 hacia La Calera',
    now() + interval '3 days', 2, 'La Calera', 4.7186, -73.9683, 0, 30, 'draft'
  ) on conflict (id) do nothing;

  update public.events set state = 'published' where id = v_event_id;

  -- Rodada en curso: qa2 organiza, qa1 inscrito y aprobado, tracking activo (Bloque 3).
  insert into public.events (
    id, owner_id, name, description, route_text, start_at, difficulty,
    destination_name, destination_lat, destination_lng, price, max_participants, state
  ) values (
    v_live_event_id, v_qa2_id, 'Rodada en curso',
    'Rodada de prueba con tracking en vivo para QA.', 'Salida desde El Poblado hacia Santa Elena',
    now() - interval '30 minutes', 2, 'Santa Elena', 6.2000, -75.5000, 0, 20, 'draft'
  ) on conflict (id) do nothing;

  update public.events set state = 'published' where id = v_live_event_id;
  update public.events set state = 'started' where id = v_live_event_id;

  insert into public.event_registrations (
    event_id, user_id, vehicle_id, status, full_name, phone, blood_type, eps,
    emergency_contact_name, emergency_contact_phone, share_medical_info, allow_organizer_contact,
    risk_accepted_at, medical_consent_at, consent_version
  ) values (
    v_live_event_id, v_qa1_id, v_vehicle_id, 'approved', 'QA Rider Uno', '3001112233',
    'o_positive', 'Sura EPS', 'Contacto QA Uno', '3009998877', true, true,
    now(), now(), 'v1'
  ) on conflict (event_id, user_id) do nothing;

  insert into public.live_positions (
    event_id, user_id, lat, lng, speed_kmh, heading, battery_pct, accuracy_m, recorded_at, updated_at
  ) values (
    v_live_event_id, v_qa2_id, 6.2442, -75.5812, 35, 90, 80, 10, now(), now()
  ) on conflict (event_id, user_id) do nothing;
end $$;
