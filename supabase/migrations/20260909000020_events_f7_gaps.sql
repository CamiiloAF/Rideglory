-- F7 (eventos e inscripción): completa lo que faltaba del esquema base de events.
--
-- 1) meeting_point: el punto de encuentro (texto libre) es distinto del destino
--    (destination_name/lat/lng), y EV2/EV3 lo muestran por separado.
-- 2) bucket event-images: portada de la rodada. A diferencia de vehicle-images/documents,
--    la portada de un evento público (published/started/finished) es visible para cualquier
--    autenticado -- por eso la política de lectura no exige el prefijo <owner_id>/, solo la de
--    escritura. Nunca pública sin sesión: sigue siendo un bucket privado.
-- 3) event_capacity: cuántos cupos aprobados tiene un evento. Sin esta vista, un rider que
--    todavía no se inscribió no podría ver "12 de 20 cupos ocupados" en el detalle, porque RLS
--    de event_registrations solo expone la fila propia. La vista no filtra por autorización
--    (el conteo no es un dato sensible) y no expone ninguna fila cruda de event_registrations.

alter table public.events
  add column if not exists meeting_point text;

insert into storage.buckets (id, name, public, file_size_limit)
values ('event-images', 'event-images', false, 10485760)
on conflict (id) do nothing;

create policy event_images_select_authenticated
  on storage.objects for select
  to authenticated
  using (bucket_id = 'event-images');

create policy event_images_insert_own
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'event-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy event_images_update_own
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'event-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'event-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy event_images_delete_own
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'event-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create view public.event_capacity
  with (security_invoker = false)
  as
select
  event_id,
  count(*) filter (where status = 'approved') as approved_count
from public.event_registrations
group by event_id;

comment on view public.event_capacity is
  'Conteo de inscritos aprobados por evento. No expone filas de event_registrations, solo un
  agregado -- por eso puede ser visible para cualquier autenticado, inscrito o no.';

grant select on public.event_capacity to authenticated;

-- 4) events_public: la lista y el detalle necesitan el nombre del organizador y el conteo de
--    cupos en el mismo llamado, pero `profiles` solo es legible por su propio dueño (RLS) y no
--    hay FK de events.owner_id a profiles para que PostgREST lo embeba. Esta vista expone
--    ÚNICAMENTE el nombre del organizador (nunca su teléfono ni ningún otro dato de profiles) y
--    replica exactamente el `using` de events_select_visible, para no ampliar quién ve qué
--    evento -- solo qué tan cómodo es leerlo.
create view public.events_public
  with (security_invoker = false)
  as
select
  e.id,
  e.owner_id,
  coalesce(p.full_name, 'Organizador') as owner_name,
  e.name,
  e.description,
  e.route_text,
  e.meeting_point,
  e.start_at,
  e.difficulty,
  e.destination_name,
  e.destination_lat,
  e.destination_lng,
  e.image_path,
  e.price,
  e.max_participants,
  e.state,
  e.started_at,
  e.created_at,
  coalesce(c.approved_count, 0) as approved_count
from public.events e
left join public.profiles p on p.id = e.owner_id
left join public.event_capacity c on c.event_id = e.id
where e.owner_id = auth.uid() or e.state <> 'draft';

-- 5) event_registrations_for_organizer necesita la moto del inscrito (EV5: "nombre, moto, tipo
--    de sangre"), pero vehicles solo es legible por su propio dueño (RLS): el organizador no
--    puede hacer un segundo select a `vehicles` para resolver vehicle_id. Se agrega aquí en vez
--    de tocar la vista original de la migración 010.
create or replace view public.event_registrations_for_organizer
  with (security_invoker = false)
  as
select
  r.id,
  r.event_id,
  r.user_id,
  r.vehicle_id,
  r.status,
  r.full_name,
  case when r.allow_organizer_contact then r.phone else null end as phone,
  case when r.share_medical_info then r.blood_type else null end as blood_type,
  case when r.share_medical_info then r.eps else null end as eps,
  case when r.share_medical_info then r.emergency_contact_name else null end as emergency_contact_name,
  case when r.share_medical_info then r.emergency_contact_phone else null end as emergency_contact_phone,
  r.share_medical_info,
  r.allow_organizer_contact,
  r.risk_accepted_at,
  r.medical_consent_at,
  r.consent_version,
  r.created_at,
  r.updated_at,
  v.name as vehicle_name,
  v.brand as vehicle_brand,
  v.model as vehicle_model
from public.event_registrations r
join public.events e on e.id = r.event_id
left join public.vehicles v on v.id = r.vehicle_id
where e.owner_id = auth.uid();

comment on view public.event_registrations_for_organizer is
  'Única vía por la que un organizador ve inscripciones de su evento. Enmascara blood_type/eps/contacto de emergencia según share_medical_info, y el teléfono según allow_organizer_contact. Incluye la moto (vehicle_name/brand/model) porque vehicles no le concede fila al organizador.';

grant select on public.event_registrations_for_organizer to authenticated;

comment on view public.events_public is
  'Único lugar donde un rider ve el nombre del organizador de un evento ajeno. Replica la
  visibilidad de events_select_visible; nunca expone más columnas de profiles que full_name.';

grant select on public.events_public to authenticated;
