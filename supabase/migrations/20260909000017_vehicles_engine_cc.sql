-- El diseño de "Agregar moto"/"Editar moto" (rideglory.pen: KIdCH, e0fmR, tbZKM)
-- pide el cilindraje de la moto junto a marca/línea/año. No estaba en el
-- modelo de datos original del plan v2; se agrega aquí porque el .pen manda
-- sobre la descripción escrita cuando difieren (CLAUDE.md, orden de
-- precedencia de diseño).

alter table public.vehicles
  add column engine_cc integer;

comment on column public.vehicles.engine_cc is
  'Cilindraje en cc, mostrado en la ficha técnica de la moto (opcional).';
