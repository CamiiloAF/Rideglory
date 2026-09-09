-- Buckets privados. Todo objeto vive bajo el prefijo <owner_id>/... del path, y solo su dueño
-- puede leerlo o escribirlo. Nunca públicos: las fotos de moto muestran la placa, y los
-- documentos contienen datos de terceros y del propio rider.

insert into storage.buckets (id, name, public, file_size_limit)
values
  ('vehicle-images', 'vehicle-images', false, 10485760),
  ('documents', 'documents', false, 20971520)
on conflict (id) do nothing;

create policy vehicle_images_select_own
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'vehicle-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy vehicle_images_insert_own
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'vehicle-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy vehicle_images_update_own
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'vehicle-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'vehicle-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy vehicle_images_delete_own
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'vehicle-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy documents_select_own
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy documents_insert_own
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy documents_update_own
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy documents_delete_own
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
