# Garage

> Reescrito para v2 (F5). Reemplaza `vehicles.md` de la v1.

## Problema que resuelve

Bloque 1 de `docs/product/ALCANCE-V2.md`: "Es lo único con uso voluntario y recurrente, y el motivo declarado de existencia del producto. Va primero." Garaje resuelve P-02 junto con mantenimiento: motos, odómetro, placa, foto, moto principal, archivar.

## Flujos

- **Galería en dos columnas** (arquetipo D, decisión de diseño del 2026-08-19): escala a 6-8 motos, no compite con el hero del detalle, se degrada bien con o sin foto.
- **Alta por placa en dos pasos**: `VehicleFormPage` primero valida la placa (`VehiclePlateValidator`, formato colombiano `[A-Z]{3}[0-9]{2}[A-Z]`, puro Dart) y luego pide marca/modelo/año/cilindraje/kilometraje/foto/principal.
- **Buscador de marca**: `BrandPickerPage` sobre un catálogo estático (portado de `main`), búsqueda síncrona sin red.
- **Editar / archivar / restaurar / eliminar**: `VehicleEditPage`. El frame aprobado del `.pen` (`tbZKM`) no incluía la fila de documentos ni archivar/restaurar — es una **desviación documentada** en el commit de F5, no un olvido.
- **Alerta de documento por vencer en la celda de galería**: cada `Vehicle` trae un `VehicleDocumentAlert?` (`kind: soat|rtm`, `severity: warning|critical`, `daysUntilExpiry`), calculado por `VehicleDocumentAlert.mostUrgent()` sobre SOAT y RTM del vehículo.
- **Moto principal**: `setMainVehicle` hace un update en dos pasos (desmarcar las demás, marcar la elegida) — no hay trigger de base que lo garantice atómico.

## Pantallas (Pencil)

| Pantalla | Archivo | Pencil |
|---|---|---|
| Galería | `presentation/pages/garage_page.dart` | `V02g9` (galería), `rgLwm` (vacío), `pBdbp` (carga), `ZSUKH` (sin conexión) |
| Alta de moto | `presentation/pages/vehicle_form_page.dart` | `KIdCH`, `ruRle`, `e0fmR`, `M2i66X`, `sH7QQ` |
| Editar moto | `presentation/pages/vehicle_edit_page.dart` | `tbZKM` (con desviación documentada) |
| Buscador de marca | `presentation/pages/brand_picker_page.dart` | `LHKHl` |

## Datos

- Tabla `vehicles`: `owner_id, name, brand, model, year, engine_cc, license_plate, current_mileage, image_path, is_main, archived_at`. `engine_cc` se agregó en la migración `20260909000017_vehicles_engine_cc.sql` porque el `.pen` lo pedía en alta/edición y no estaba en el modelo de datos original de v2.
- Storage: bucket privado `vehicle-images`, URL firmada con TTL de 1 hora.
- Lee `vehicle_documents` (`vehicle_id, kind, expiry_date`) solo para calcular las alertas de vencimiento de la galería — no es dueño de esa tabla (ver `documents.md`).
- Sin RPCs ni Edge Functions propias.

## Estados

`GarageGalleryCubit` es `Cubit<ResultState<List<Vehicle>>>` (`load/archive/unarchive/setMain/delete`). `VehicleFormCubit` tiene un estado freezed propio (`VehicleFormState`) con el paso del formulario (`plate|details`), los campos y una `submission: ResultState<Vehicle>` embebida — no es un `ResultState` de tope porque el formulario en sí no es un resultado de red. `BrandPickerCubit` es puramente síncrono (catálogo local), sin `ResultState`.

Obligatorios: skeleton (`GarageSkeletonGrid`, `SkeletonBox` en la sección de documentos), vacío (`GarageEmptyView`), error con reintentar (`ErrorStateView`), sin conexión (`OfflineStateView`, gateado por `ConnectivityCubit`). Sin permiso de ubicación / sin GPS no aplican: garaje no depende de ubicación.

## Pendientes

- Ninguna nota `TODO`/`FIXME`/pendiente encontrada en el código de esta feature.
- La desviación de `tbZKM` (documentos y archivar/restaurar fuera del frame aprobado) queda pendiente de reconciliar con Pencil: o se actualiza el frame, o se retira la funcionalidad de `VehicleEditPage`.
