-- profiles.emergency_contact_relationship: parentesco del contacto de emergencia (ej. "Hermana"),
-- que el diseño de F4 pide junto al nombre y el teléfono. Se anonimiza igual que el resto de datos
-- del contacto en delete-account.

alter table public.profiles
  add column emergency_contact_relationship text;
