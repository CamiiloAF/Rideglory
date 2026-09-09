-- register_maintenance: inserta un mantenimiento y, si el kilometraje reportado
-- supera el odómetro actual de la moto, lo actualiza en la misma operación
-- (decisión D5: odómetro derivado). Atómico y con RLS del dueño: la moto debe
-- pertenecer a auth.uid(), igual que ya exige maintenances_insert_own.

create or replace function public.register_maintenance(
  p_vehicle_id uuid,
  p_type text,
  p_service_date date,
  p_odometer integer,
  p_cost numeric default null,
  p_workshop text default null,
  p_notes text default null,
  p_next_date date default null,
  p_next_odometer integer default null
)
returns public.maintenances
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_maintenance public.maintenances;
begin
  if not exists (
    select 1 from public.vehicles
    where vehicles.id = p_vehicle_id
      and vehicles.owner_id = auth.uid()
  ) then
    raise exception 'vehicle_not_found_or_not_owned';
  end if;

  insert into public.maintenances (
    vehicle_id, type, service_date, odometer, cost, workshop, notes,
    next_date, next_odometer
  ) values (
    p_vehicle_id, p_type, p_service_date, p_odometer, p_cost, p_workshop, p_notes,
    p_next_date, p_next_odometer
  )
  returning * into v_maintenance;

  update public.vehicles
  set current_mileage = p_odometer
  where id = p_vehicle_id
    and p_odometer > current_mileage;

  return v_maintenance;
end;
$$;

grant execute on function public.register_maintenance(
  uuid, text, date, integer, numeric, text, text, date, integer
) to authenticated;
