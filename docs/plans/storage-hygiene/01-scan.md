# 01 — System Scan: storage-hygiene

**Timestamp:** 2026-06-19T20:10:14Z
**Slug:** `storage-hygiene`

---

## Inventario Flutter

### `lib/core/services/image_storage_service.dart`

Servicio central de Storage. Tiene:
- `pickImageFromGallery()` / `pickImageFromCamera()` — picker de galería/cámara.
- `uploadImage({XFile, storagePath})` — sube archivo, lanza `DomainException` en error.
- `deleteImage(String imageUrl)` — llama `_storage.refFromURL(url).delete()` con catch silencioso. **Ya existe un método de borrado**, pero tiene dos problemas: (1) no valida que la URL pertenezca al bucket propio antes de borrar; (2) silencia todos los errores sin logging.

### Feature: `vehicles`

- **Domain:** `VehicleModel` (campo `imageUrl: String?`), `VehicleRepository` (interface), use cases: `AddVehicleUseCase`, `UpdateVehicleUseCase`, `PermanentlyDeleteVehicleUseCase`, `ArchiveVehicleUseCase`, `UnarchiveVehicleUseCase`.
- **Data:** `VehicleRepositoryImpl` — inyecta `FirebaseStorage` directamente (no usa `ImageStorageService`). `uploadVehicleImage` hace upload con `_storage.ref().child(...)`. `updateVehicle` y `permanentlyDeleteVehicle` **no borran** la imagen anterior en Storage.
- **Distinción archive vs. delete:** `ArchiveVehicleUseCase` llama a `updateVehicle` con `isArchived=true` (no debe borrar imagen); `PermanentlyDeleteVehicleUseCase` llama a `permanentlyDeleteVehicle` (aquí sí debe borrar). Distinción ya modelada en dominio.
- **Presentation:** `VehicleActionCubit` orquesta archive/unarchive/permanentlyDelete desde UI; `VehicleFormCubit` orquesta creación/edición + upload de imagen.

### Feature: `events`

- **Domain:** `EventModel` (campo `imageUrl: String?`), `EventRepository`.
- **Data:** `EventRepositoryImpl` — inyecta `FirebaseStorage` directamente. `uploadEventImage` sube a `events/$folder/cover.jpg`. `updateEvent` y `deleteEvent` **no borran** la imagen anterior.
- **Patrones de Storage path:** `events/{eventId|anonymous-timestamp}/cover.jpg`. El `eventId` puede ser null antes de crear el evento (upload pre-creación), lo que dificulta derivar la referencia desde la URL en borrado.
- **Presentation:** no hay `EventDeleteCubit` dedicado; el borrado se dispara desde el cubit de detalle de evento.

### Feature: `soat`

- **Domain:** `SoatModel` (campo `documentUrl: String?`), `SoatRepository`, use cases: `SaveSoatUseCase`, `DeleteSoatUseCase`, `GetSoatUseCase`, `ScanSoatUseCase`.
- **Data:** `SoatRepositoryImpl` — **no inyecta FirebaseStorage ni `ImageStorageService`**. `saveSoat` hace POST con `soat.toRequestJson()` (que incluye `documentUrl` ya como URL). `deleteSoat` llama DELETE al API. **Ningún método borra el archivo de Storage**.
- **Patrón UPSERT:** el endpoint es `POST /vehicles/{vehicleId}/soat` (upsert server-side). La app no tiene la URL anterior al momento de guardar — necesitaría un GET previo para comparar si la URL cambió, o recibir la URL vieja como parámetro.
- **Upload de documento:** ocurre en `SoatUploadCubit` usando `ImageStorageService.uploadImage`. La URL resultante se pasa al modelo y luego a `saveSoat`. El repositorio no tiene acceso a la URL anterior.

### Feature: `tecnomecanica`

- **Domain:** `TecnomecanicaModel` (campo `documentUrl: String?`), `TecnomecanicaRepository`, use cases: `SaveTecnomecanicaUseCase`, `DeleteTecnomecanicaUseCase`, `GetTecnomecanicaUseCase`.
- **Data:** `TecnomecanicaRepositoryImpl` — **no inyecta FirebaseStorage ni `ImageStorageService`**. `saveTecnomecanica` crea `CreateTecnomecanicaRequestDto` con `documentUrl`. `deleteTecnomecanica` llama DELETE al API. **Ningún método borra el archivo de Storage**.
- **Mismo problema de URL anterior** que SOAT: no hay parámetro `oldDocumentUrl` en save; el repositorio no conoce la URL previa sin un GET previo.

---

## Dependencias

Dependencias relevantes de `pubspec.yaml`:

| Paquete | Versión | Rol en este plan |
|---|---|---|
| `firebase_storage` | `^13.1.0` | SDK para upload/delete de archivos |
| `firebase_core` | — | Base Firebase |
| `injectable` / `get_it` | — | DI para inyectar servicios en repositorios |
| `dartz` | — | `Either` para manejo de errores en data layer |
| `mocktail` | `^1.0.4` | Mocking en tests (ya disponible) |
| `bloc_test` | `^10.0.0` | Tests de cubits |

**No hay** `firebase_storage_mocks` ni `fake_firebase_storage` en dev_dependencies. Los tests de Storage deberán crear fakes/mocks con `mocktail` (mockear `FirebaseStorage`, `Reference`, `TaskSnapshot`).

---

## Superficie rideglory-api

### `vehicles-ms`

Endpoints relevantes (vía API Gateway, message patterns NestJS microservicio):

| Pattern | Método HTTP (gateway) | Propósito |
|---|---|---|
| `upsertSoat` | `POST /vehicles/{vehicleId}/soat` | Crear o reemplazar SOAT |
| `findSoatByVehicle` | `GET /vehicles/{vehicleId}/soat` | Leer SOAT actual (incluye `documentUrl`) |
| `deleteSoat` | `DELETE /vehicles/{vehicleId}/soat` | Eliminar SOAT |
| `upsertTecnomecanica` | `POST /vehicles/{vehicleId}/tecnomecanica` | Crear o reemplazar RTM |
| `findTecnomecanicaByVehicle` | `GET /vehicles/{vehicleId}/tecnomecanica` | Leer RTM actual (incluye `documentUrl`) |
| `deleteTecnomecanica` | `DELETE /vehicles/{vehicleId}/tecnomecanica` | Eliminar RTM |
| `softDeleteVehicle` | `PATCH /vehicles/{id}` (isArchived=true) | Archivar vehículo |
| `hardDeleteVehicle` | `DELETE /my-vehicles/{id}` | Eliminar permanente |
| `updateVehicle` | `PATCH /vehicles/{id}` | Actualizar campos (incluye imageUrl) |

El backend **no toca Firebase Storage** en ningún endpoint — toda la gestión de archivos es responsabilidad del cliente.

### `events-ms`

| Pattern | Método HTTP (gateway) | Propósito |
|---|---|---|
| `createEvent` | `POST /events` | Crear evento (incluye `imageUrl`) |
| `updateEvent` | `PATCH /events/{id}` | Actualizar evento (puede cambiar `imageUrl`) |
| `removeEvent` | `DELETE /events/{id}` | Eliminar evento |

El backend persiste la URL pero no gestiona el archivo en Storage.

---

## Gap analysis

| Componente | Estado | Detalle del gap |
|---|---|---|
| `ImageStorageService.deleteImage` | **partial** | Método existe pero (1) no valida pertenencia al bucket propio; (2) silencia errores sin logging; no es idempotente de forma explícita (un 404 de Storage no debería ser error). Renombrar/refactorizar a `deleteByUrl` según PRD. |
| Borrado imagen al actualizar vehículo | **not started** | `VehicleRepositoryImpl.updateVehicle` no borra `oldImageUrl`. El llamador (`VehicleFormCubit`) conoce la URL anterior (modelo antes del update). |
| Borrado imagen al eliminar vehículo | **not started** | `VehicleRepositoryImpl.permanentlyDeleteVehicle` no borra imagen. El llamador (`VehicleActionCubit`) tiene el `VehicleModel` con `imageUrl`. |
| Archivar vehículo NO borra imagen | **implemented** | `ArchiveVehicleUseCase` llama `updateVehicle` con `isArchived=true`. No hay lógica de borrado de imagen aquí — correcto por diseño. Solo hay que asegurarse de que el update con imagen nueva no borre en caso de archivado. |
| Borrado imagen al actualizar evento | **not started** | `EventRepositoryImpl.updateEvent` no borra la imagen anterior. El llamador tiene el modelo previo. |
| Borrado imagen al eliminar evento | **not started** | `EventRepositoryImpl.deleteEvent` no borra imagen. El llamador tiene el modelo con `imageUrl`. |
| Borrado documento al guardar SOAT (replace) | **not started** | `SoatRepositoryImpl.saveSoat` no borra `oldDocumentUrl`. **El repositorio no recibe la URL anterior.** Estrategia: leer el SOAT actual antes del save con `getSoat` para comparar `documentUrl`, o añadir `oldDocumentUrl` como parámetro opcional a `saveSoat`. |
| Borrado documento al eliminar SOAT | **not started** | `SoatRepositoryImpl.deleteSoat` no borra el archivo. El repositorio necesita leer el SOAT antes de borrarlo para conocer la URL, o el llamador debe pasar la URL. |
| Borrado documento al guardar RTM (replace) | **not started** | Mismo problema que SOAT: `TecnomecanicaRepositoryImpl.saveTecnomecanica` no borra `oldDocumentUrl`. |
| Borrado documento al eliminar RTM | **not started** | `TecnomecanicaRepositoryImpl.deleteTecnomecanica` no borra el archivo. |
| Tests de borrado Storage | **not started** | No hay mocks de `FirebaseStorage` en el proyecto de tests. Hay que crearlos con `mocktail` (mockear `FirebaseStorage` y `Reference`). |
| Docs de features afectados | **exists, not updated** | `docs/features/vehicles.md`, `docs/features/events.md`, `docs/features/soat.md`, `docs/features/tecnomecanica.md` — deben actualizarse en la fase QA. |

---

## Patrones

### Patrón de upload actual (inconsistente entre features)

- **Vehículos:** upload en `VehicleRepositoryImpl` directamente con `FirebaseStorage` (no usa `ImageStorageService`).
- **Eventos:** upload en `EventRepositoryImpl` directamente con `FirebaseStorage` (no usa `ImageStorageService`).
- **SOAT / RTM:** upload en cubit de presentación (`SoatUploadCubit`) usando `ImageStorageService.uploadImage`. El repositorio solo recibe la URL ya resuelta.

Este patrón mixto implica que `deleteByUrl` necesita ser usado desde los repositorios (datos layer), pero los repositorios de vehículos y eventos ya tienen `FirebaseStorage` inyectado, mientras que SOAT y RTM necesitarán inyectar `ImageStorageService` (o `FirebaseStorage`).

### Patrón de URL conocida en el punto de borrado

- **Vehículos update/delete:** el llamador (cubit o use case) tiene el `VehicleModel` con `imageUrl`. Se puede pasar como parámetro al repositorio o manejarse internamente si el update devuelve el modelo previo.
- **Eventos update/delete:** mismo patrón — el cubit tiene el `EventModel` previo.
- **SOAT/RTM delete:** el llamador (use case o cubit) puede tener el modelo en memoria si lo cargó antes. En `SoatCubit` el modelo actual está en el estado del cubit.
- **SOAT/RTM save (replace):** el llamador puede pasar `oldDocumentUrl` como parámetro opcional, evitando un GET extra de red. **Recomendado**: añadir `oldDocumentUrl` como parámetro opcional a `saveSoat` / `saveTecnomecanica` en la interface del repositorio y en el use case.

### Idempotencia del borrado

`deleteImage` actual hace `delete()` y silencia todo. Para `deleteByUrl` el PRD requiere: (1) validar que la URL sea del bucket propio (prefijo `https://firebasestorage.googleapis.com/.../<bucket-name>/`); (2) si el archivo no existe (`object-not-found`), log y continuar sin error (idempotente); (3) si es URL externa o vacía, skip silencioso.

`AppEnv.firebaseStorageBucket` está disponible y puede usarse para la validación de pertenencia al bucket.

---

## Implicaciones para el plan

1. **Fase 1 (Utilidad):** refactorizar `deleteImage` a `deleteByUrl` en `ImageStorageService` con validación de bucket (`AppEnv.firebaseStorageBucket`), log en catch y 404-idempotente. Añadir tests con mocks mocktail de `FirebaseStorage`/`Reference`. No hay paquete `firebase_storage_mocks` disponible — se crea un mock manual con mocktail.

2. **Fase 2 (Vehículos):** `VehicleRepositoryImpl` ya tiene `FirebaseStorage` inyectado; se puede inyectar `ImageStorageService` en su lugar para reutilizar `deleteByUrl`. El repositorio debe recibir `oldImageUrl` como parámetro en `updateVehicle`/`permanentlyDeleteVehicle`, o alternativamente el borrado ocurre en el use case si el modelo previo está disponible. Respetar la regla: `archiveVehicle` (que llama `updateVehicle` con `isArchived=true`) **no** debe disparar borrado de imagen.

3. **Fases 3–5 (Eventos, SOAT, RTM):** para SOAT y RTM hay que definir la estrategia de URL anterior: **opción A** — añadir `oldDocumentUrl` como parámetro opcional en las interfaces de repositorio y use cases (sin GET extra); **opción B** — el repositorio hace un GET previo. Opción A es preferida (sin overhead de red). El plan de cada fase debe especificar la firma actualizada.

4. **Fase 6 (QA):** crear mocks reutilizables para `FirebaseStorage` en `test/helpers/` para compartir entre todos los tests de repositorios afectados; actualizar los 4 docs de features; correr `flutter test` y `dart analyze`.

5. **Advertencia de deuda:** `VehicleRepositoryImpl` construye el body de update con un `Map<String, dynamic>` manual (viola el DTO `.toJson()` estándar del proyecto). Está fuera del alcance de storage-hygiene pero debe anotarse para un cleanup posterior.
