# 03 — Architect Review: storage-hygiene

**Timestamp:** 2026-06-19T20:14:17Z
**Slug:** `storage-hygiene`
**Verdict:** `ok_con_ajustes`

---

## Validacion por fase

### Fase 1 — Storage Delete Utility

**Complejidad:** baja

**Viabilidad:** Alta. `ImageStorageService` ya existe en `lib/core/services/image_storage_service.dart` y tiene un `deleteImage` que solo necesita refactorizacion, no reemplazo. Los tres problemas a resolver son acotados: (1) validacion de pertenencia al bucket via `AppEnv.firebaseStorageBucket` (disponible), (2) idempotencia ante `object-not-found` en lugar del catch silencioso actual, (3) logging explicito del error (no propagacion — el borrado nunca falla el flujo de negocio).

**Punto critico:** el metodo renombrado `deleteByUrl` debe distinguir cuatro casos:
- URL `null` o vacia → skip silencioso, no loguear.
- URL externa (no comienza con `https://firebasestorage.googleapis.com`) → skip silencioso.
- URL del bucket propio + archivo inexistente (`object-not-found`) → log debug, retornar sin error (idempotente).
- URL del bucket propio + error de red/permisos → log warning, absorber (no propagas a negocio).

**Firma recomendada:**
```dart
Future<void> deleteByUrl(String? imageUrl) async
```

No requiere cambios de DI ni code-gen. `ImageStorageService` ya es `@injectable`.

**Dependencias backend / API:** ninguna. Puramente cliente.

**Tests:** usar mocktail para mockear `FirebaseStorage` y `Reference`. No hay `firebase_storage_mocks` en el proyecto — crear `test/helpers/storage_mocks.dart` con las clases mock reutilizables. El implementador debe cubrir los cuatro casos del punto critico con tests unitarios.

---

### Fase 2 — Vehicle Image Cleanup

**Complejidad:** media

**Viabilidad:** Alta, con un ajuste de diseno que se detalla abajo.

**Analisis de capas:**

`VehicleRepositoryImpl` actualmente inyecta `FirebaseStorage` directamente para el upload (`uploadVehicleImage`). Este plan propone reemplazarlo por `ImageStorageService`, lo cual es correcto y consolida el patron de Storage en un unico servicio. El DI change es trivial — sustituir `FirebaseStorage` por `ImageStorageService` en el constructor.

**Flujo de borrado en update (imagen reemplazada):**

El `VehicleFormCubit._buildVehicleWithImage` tiene acceso a `state.vehicle?.imageUrl` (URL anterior) cuando `state.isEditing == true`. El upload de la nueva imagen ocurre en el cubit (via `ImageStorageService.uploadImage`) antes de llamar al use case. El borrado de la imagen anterior debe ocurrir tambien en el cubit, despues de confirmar que el update al backend fue exitoso:

```
cubit: upload new image → get newUrl
cubit: call UpdateVehicleUseCase(vehicle.copyWith(imageUrl: newUrl))
cubit: on success → call ImageStorageService.deleteByUrl(oldImageUrl)
```

Esta estrategia evita tocar las firmas del repositorio y del use case, manteniendo la responsabilidad del borrado en la capa mas alta que tiene contexto de "imagen previa".

**Flujo de borrado en permanentlyDelete:**

`VehicleActionCubit.permanentlyDeleteVehicle(String vehicleId)` recibe solo el ID, no el modelo completo. Esto es un gap: el cubit no tiene la URL de la imagen para borrarla. Soluciones posibles:

- **Opcion A (recomendada):** cambiar la firma del metodo a `permanentlyDeleteVehicle(VehicleModel vehicle)` — el llamador ya tiene el modelo en memoria (viene del estado del `VehicleCubit`). Despues del delete exitoso, llamar `ImageStorageService.deleteByUrl(vehicle.imageUrl)`.
- **Opcion B:** pasar `imageUrl` como parametro opcional junto al `vehicleId`.

La Opcion A es preferida por consistencia con el patron existente (`archiveVehicle(VehicleModel vehicle)` ya recibe el modelo completo).

**Regla de archivo (archive):** `ArchiveVehicleUseCase` llama `updateVehicle` con `isArchived=true` via `VehicleActionCubit.archiveVehicle(VehicleModel vehicle)`. Este flujo no toca imagenes — la imagen NO debe borrarse al archivar. Esta distincion ya esta modelada correctamente en el dominio y no requiere cambios. Solo hay que documentarla explicitamente en el codigo.

**Deuda existente (fuera de alcance):** `VehicleRepositoryImpl._vehicleRequest` construye el body con `Map<String, dynamic>` manual, violando el estandar DTO `.toJson()`. Se anota como deuda conocida para un cleanup posterior (no es parte de este plan).

---

### Fase 3 — Event Cover Cleanup

**Complejidad:** media

**Viabilidad:** Alta. `EventRepositoryImpl` tiene el mismo patron que `VehicleRepositoryImpl`: inyecta `FirebaseStorage` directamente para upload. Se migra a `ImageStorageService`.

**Analisis de borrado:**

`updateEvent(EventModel event)` recibe el modelo nuevo pero no el modelo previo. El llamador (cubit de detalle de evento o form) debe tener el modelo anterior en estado y pasar la old URL para el borrado. El patron es identico al de vehiculos:

```
cubit: get oldImageUrl from current state
cubit: call UpdateEventUseCase(newEvent)
cubit: on success → call ImageStorageService.deleteByUrl(oldImageUrl)
```

`deleteEvent(String id)`: el cubit debe tener el `EventModel` con `imageUrl` en estado antes de disparar el delete. Verificar que el cubit de detalle de evento retiene el modelo en estado durante el flujo de eliminacion.

**Caso edge — upload anonimo pre-creacion:** el path `events/{ownerId}-{timestamp}/cover.jpg` se genera cuando el evento no tiene ID aun. Si el evento se abandona, la imagen queda huerfana. Este barrido retroactivo esta **fuera de alcance** y se registra como deuda tecnica conocida. Solo aplica a imagenes de eventos creados pero luego cancelados por el usuario.

**Caso edge — portada generada por IA (Iter 4):** si `imageUrl` proviene de Unsplash (URL externa), `deleteByUrl` la rechaza silenciosamente por no pertenecer al bucket propio. Esto es el comportamiento correcto — no hay nada que borrar en Storage para portadas de Unsplash.

---

### Fase 4 — SOAT Document Cleanup

**Complejidad:** media

**Viabilidad:** Alta con la estrategia de parametro opcional (Opcion A del scan).

**Analisis de flujos:**

`SoatCubit` tiene estado `ResultState<SoatModel>`. Cuando el usuario guarda un SOAT (reemplazo), el cubit tiene el modelo anterior en `state` cuando `state is Data`. La URL anterior esta disponible como `(state as Data<SoatModel>).data.documentUrl`.

**Cambios de firma requeridos:**

1. `SoatRepository.saveSoat` → añadir `String? oldDocumentUrl` como parametro opcional:
```dart
Future<Either<DomainException, SoatModel>> saveSoat({
  required String vehicleId,
  required SoatModel soat,
  String? oldDocumentUrl,
});
```

2. `SaveSoatUseCase.call` → propagar el mismo parametro opcional.

3. `SoatRepositoryImpl.saveSoat` → inyectar `ImageStorageService`; despues del save exitoso, llamar `deleteByUrl(oldDocumentUrl)`.

4. `SoatRepository.deleteSoat` / `SoatRepositoryImpl.deleteSoat` → mismo patron: el cubit pasa `documentUrl` como parametro opcional para el borrado. Alternativa: el repositorio hace un GET previo — **rechazado** por overhead de red innecesario (Opcion B del scan).

**Firma alternativa para deleteSoat:**
```dart
Future<Either<DomainException, Unit>> deleteSoat(
  String vehicleId, {
  String? documentUrl,
});
```

`SoatCubit.delete(vehicleId)` tendra acceso a la URL via `state` antes de llamar al use case.

**Precondicion documentada:** el cubit DEBE tener el modelo cargado (`state is Data`) antes de disparar save o delete. Si el estado es `Empty` o `Error`, `oldDocumentUrl` llegara como `null` — el borrado se omite silenciosamente (el archivo eventualmente quedara huerfano). Esto es aceptable como degradacion controlada.

**Inyeccion de `ImageStorageService` en `SoatRepositoryImpl`:** actualmente no tiene acceso a Storage. Se agrega `ImageStorageService` al constructor via DI. No requiere code-gen extra — `ImageStorageService` ya es `@injectable` y `SoatRepositoryImpl` ya usa `@Injectable(as: SoatRepository)`.

---

### Fase 5 — RTM Document Cleanup

**Complejidad:** media

**Viabilidad:** Alta. Identica en estructura a Fase 4 (SOAT). `TecnomecanicaRepositoryImpl` tiene el mismo gap: no inyecta Storage, no borra documentos.

**Cambios de firma requeridos (espejo de SOAT):**

1. `TecnomecanicaRepository.saveTecnomecanica` → `String? oldDocumentUrl` opcional.
2. `SaveTecnomecanicaUseCase.call` → propagar parametro.
3. `TecnomecanicaRepository.deleteTecnomecanica` → `String? documentUrl` opcional.
4. `TecnomecanicaRepositoryImpl` → inyectar `ImageStorageService`.
5. `TecnomecanicaCubit.save / delete` → extraer URL del estado antes de llamar al use case.

**Nota sobre `CreateTecnomecanicaRequestDto`:** este DTO se construye inline en `TecnomecanicaRepositoryImpl.saveTecnomecanica`. El borrado de Storage ocurre despues del save exitoso, por lo que el DTO no necesita cambios.

---

### Fase 6 — QA & Docs

**Complejidad:** baja

**Viabilidad:** Alta. Sin cambios de produccion — solo consolidacion de helpers de test y actualizacion de docs.

**Mocks a centralizar en `test/helpers/storage_mocks.dart`:**
- `MockFirebaseStorage` (mocktail)
- `MockReference` (mocktail)
- Funciones helper `setupStorageDeleteSuccess()`, `setupStorageDeleteNotFound()`, `setupStorageDeleteError()`

Esto evita duplicacion entre los tests de Fases 1–5.

**Docs a actualizar:**
- `docs/features/vehicles.md` — ciclo de vida de imagen (update + permanentDelete borra Storage; archive no).
- `docs/features/events.md` — ciclo de vida de portada (update + delete borra Storage; portadas Unsplash exentas).
- `docs/features/soat.md` — ciclo de vida de documento (save con reemplazo + delete borra Storage).
- `docs/features/tecnomecanica.md` — ciclo de vida de documento (identico a SOAT).

**Gate de calidad:** `dart analyze` sin errores nuevos, `flutter test` sin regresiones.

---

## Contratos

### rideglory-api

**Sin cambios.** El backend no gestiona Firebase Storage en ningun endpoint. Las URLs persisten como strings en la BD (`imageUrl`, `documentUrl`) pero el ciclo de vida del archivo en Storage es 100% responsabilidad del cliente Flutter. Este plan no requiere modificaciones a `vehicles-ms`, `events-ms` ni ninguna migracion de datos.

### Firebase Storage

No hay cambios de reglas de seguridad necesarios. El SDK cliente (`firebase_storage ^13.1.0`) ya tiene permisos para leer y borrar archivos del usuario autenticado bajo los paths existentes. `deleteByUrl` usa `_storage.refFromURL(url).delete()` — el mismo patron que `deleteImage` actual.

### Code generation

No hay nuevas clases `@freezed` ni nuevos Retrofit clients en este plan. DI (`injectable`) se actualiza en:
- `VehicleRepositoryImpl` — sustituir `FirebaseStorage` por `ImageStorageService`
- `EventRepositoryImpl` — idem
- `SoatRepositoryImpl` — agregar `ImageStorageService`
- `TecnomecanicaRepositoryImpl` — idem

Esto requiere correr `dart run build_runner build --delete-conflicting-outputs` una vez al final o por fase. No hay riesgo de conflicto de codigo generado porque ninguna de estas clases tiene `@freezed`.

### WebSocket / Tracking

Sin impacto. `TrackingWsClient` no gestiona Storage.

### Plataforma (Android / iOS)

Sin impacto. No hay cambios de permisos, entitlements, ni native code.

---

## Riesgos

| # | Riesgo | Severidad | Mitigacion |
|---|--------|-----------|------------|
| R1 | **Borrado prematuro:** `deleteByUrl` llamado antes de confirmar persistencia backend → archivo borrado con modelo inconsistente | Alta | Orden estricto: write al API primero, borrado de Storage solo en el bloque de exito del `fold`. Documentar en cada fase como regla explicita. |
| R2 | **`permanentlyDeleteVehicle` recibe solo `vehicleId`:** el cubit no tiene imageUrl disponible con la firma actual | Media | Cambio de firma a `permanentlyDeleteVehicle(VehicleModel vehicle)` — Opcion A. Cubierto en ajuste A2. |
| R3 | **URL anterior no disponible en cubit:** si el usuario llega a un flujo de save/delete sin haber cargado el modelo (estado no es `Data`), `oldDocumentUrl` es null y el archivo queda huerfano | Media | Documentar como precondicion. El cubit debe garantizar que `load()` se complete antes de exponer acciones de save/delete en la UI. Degradacion controlada aceptable. |
| R4 | **Portadas de Unsplash (eventos, Iter 4):** si `deleteByUrl` se llama sobre una URL de Unsplash, debe rechazarla silenciosamente | Baja | La validacion de pertenencia al bucket (Fase 1) cubre este caso — URL externa = skip silencioso. |
| R5 | **Huerfanos preexistentes (upload anonimo de evento):** imagenes en `events/{timestamp}/cover.jpg` de eventos abandonados antes de persistir | Baja | Explicito fuera de alcance. Registrado como deuda tecnica. |
| R6 | **Mocks mocktail fragiles ante cambios del SDK:** `FirebaseStorage`/`Reference` son clases del SDK externo; un cambio de version puede romper mocks manuales | Baja | Centralizar mocks en `test/helpers/storage_mocks.dart`. Cuando el SDK cambie, un solo archivo a actualizar. |
| R7 | **DI regeneration gotcha:** build_runner puede fallar en entornos frescos por build hooks de `objective_c` (documentado en MEMORY.md) | Baja | Usar `--force-jit` o copiar `pubspec.lock` de main. Documentar en la fase QA. |

---

## Ajustes

### A1 — `deleteByUrl` maneja explicitamente cuatro casos (Fase 1)

La PO propone "validacion de pertenencia al bucket + idempotencia 404 + logging". El Architect especifica los cuatro casos exactos que el implementador debe cubrir (URL null/vacia, URL externa, 404, error de red) para evitar ambiguedades. El implementador debe tener un test por caso.

### A2 — `permanentlyDeleteVehicle` cambia firma de `String vehicleId` a `VehicleModel vehicle` (Fase 2)

La PO no especifica como el cubit obtiene la `imageUrl` para el delete. El Architect prescribe cambiar la firma del metodo en `VehicleActionCubit` (y cascada al use case si corresponde) para que reciba el `VehicleModel` completo. El llamador — que ya tiene el modelo en estado — pasa el objeto entero. El borrado de Storage ocurre en el cubit tras el delete exitoso.

### A3 — Borrado en `updateVehicle` ocurre en el cubit, no en el repositorio (Fase 2)

El cubit ya tiene `state.vehicle?.imageUrl` cuando edita. El borrado de la imagen anterior se hace en `VehicleFormCubit._saveExistingVehicle` despues del update exitoso, sin tocar las firmas del repositorio ni del use case. Esto minimiza el impacto en capas inferiores.

### A4 — El borrado de Storage en Fases 4 y 5 ocurre en el repositorio, no en el cubit (SOAT / RTM)

Para vehiculos y eventos el cubit tiene la URL previa en estado. Para SOAT y RTM el patron es diferente: el repositorio recibe `oldDocumentUrl` como parametro opcional. Esto es necesario porque el upload de documentos ocurre en la capa de presentacion (`SoatUploadCubit`) y la URL anterior ya esta disponible en el cubit antes de llamar al save — se pasa hacia abajo. El borrado lo hace el repositorio despues del write al API, manteniendo la misma regla de orden (backend primero, Storage despues).

### A5 — `test/helpers/storage_mocks.dart` se crea en Fase 1 y se reutiliza en Fases 2–6 (no solo en Fase 6)

La PO propone consolidar helpers en la Fase QA. El Architect mueve la creacion de los mocks a la Fase 1 — son necesarios desde el primer test. Las Fases 2–5 los importan directamente. La Fase 6 solo verifica que esten completos y actualizados.

### A6 — Anotacion de deuda de `VehicleRepositoryImpl._vehicleRequest` en comentario de codigo (Fase 2)

El body de update construido como `Map<String, dynamic>` manual viola el estandar DTO `.toJson()` del proyecto. Este plan no lo corrige, pero el implementador debe agregar un comentario `// TODO(debt): migrar a DTO.toJson() — ver storage-hygiene plan` para que sea rastreable. No se abre una fase adicional.
