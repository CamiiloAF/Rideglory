-- Enmascarado de datos sensibles de la inscripción. El cliente solo llega a estos datos por
-- esta vía; la tabla base event_registrations NO concede al organizador acceso de fila a
-- inscripciones ajenas (ver migración anterior), así que un curl directo con la anon key del
-- organizador no puede leer datos crudos aunque conozca el id de la fila.
--
-- Nota de implementación: esta vista se crea SIN "security_invoker" (queda con el comportamiento
-- clásico de Postgres, ejecutándose con los privilegios de su dueño, "postgres", que tiene
-- BYPASSRLS). Es una desviación deliberada del enunciado original ("vista ... con
-- security_invoker"): con security_invoker=true, la vista se ejecuta con los privilegios del
-- invocador y por lo tanto solo podría enmascarar COLUMNAS si el organizador ya tuviera permiso
-- de RLS para leer la FILA completa -- y ese permiso, de existir en la tabla base, le permitiría
-- además leerla sin pasar por la vista, con cualquier cliente HTTP y la anon key. Eso es
-- exactamente la fuga que CLAUDE.md prohíbe ("la vista es la frontera"). Con security_invoker
-- desactivado, la fila solo es alcanzable a través de esta vista, que aplica su propia
-- autorización (organizador del evento) y su propio enmascarado (CASE WHEN según consentimiento).

create view public.event_registrations_for_organizer
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
  r.updated_at
from public.event_registrations r
join public.events e on e.id = r.event_id
where e.owner_id = auth.uid();

comment on view public.event_registrations_for_organizer is
  'Única vía por la que un organizador ve inscripciones de su evento. Enmascara blood_type/eps/contacto de emergencia según share_medical_info, y el teléfono según allow_organizer_contact.';

grant select on public.event_registrations_for_organizer to authenticated;

-- Aprobar/rechazar es la única escritura que el organizador puede hacer sobre una inscripción
-- ajena, y se hace vía función security definer: nunca UPDATE directo de la tabla base, porque
-- la tabla base no le concede fila a un tercero.
create or replace function public.organizer_set_registration_status(
  p_registration_id uuid,
  p_status public.registration_status
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_event_owner uuid;
begin
  if p_status not in ('approved', 'rejected') then
    raise exception 'organizer_can_only_approve_or_reject';
  end if;

  select e.owner_id into v_event_owner
  from public.event_registrations r
  join public.events e on e.id = r.event_id
  where r.id = p_registration_id;

  if v_event_owner is null then
    raise exception 'registration_not_found';
  end if;

  if v_event_owner <> auth.uid() then
    raise exception 'not_authorized';
  end if;

  update public.event_registrations
  set status = p_status
  where id = p_registration_id;
end;
$$;

grant execute on function public.organizer_set_registration_status(uuid, public.registration_status) to authenticated;

-- Vista de pares: un inscrito aprobado de un evento publicado/iniciado ve nombre y moto de los
-- demás inscritos aprobados, nada más (nunca datos médicos ni de contacto).
create view public.event_participants_public
  with (security_invoker = false)
  as
select
  r.event_id,
  r.user_id,
  r.full_name,
  v.name as vehicle_name,
  v.brand as vehicle_brand,
  v.model as vehicle_model
from public.event_registrations r
join public.events e on e.id = r.event_id
left join public.vehicles v on v.id = r.vehicle_id
where r.status = 'approved'
  and e.state in ('published', 'started', 'finished')
  and (
    e.owner_id = auth.uid()
    or exists (
      select 1 from public.event_registrations mine
      where mine.event_id = r.event_id
        and mine.user_id = auth.uid()
        and mine.status = 'approved'
    )
  );

comment on view public.event_participants_public is
  'Lo único que un inscrito ve de los demás inscritos de su evento: nombre y moto. Nada médico, nada de contacto.';

grant select on public.event_participants_public to authenticated;
