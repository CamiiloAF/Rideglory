# Fase 3 — Event Cover Cleanup

**Timestamp:** 2026-06-19T20:21:54Z
**Slug:** `storage-hygiene`
**Fase:** 3 de 6
**Depende de:** Fase 1 (Storage Delete Utility)

---

## Objetivo

Al editar o eliminar un evento, la foto de portada anterior se borra de Firebase Storage sin afectar el flujo de creacion del organizador. Las portadas generadas por IA (URLs de Unsplash u otros dominios externos) son ignoradas silenciosamente por la validacion de bucket introducida en Fase 1 — este es el comportamiento correcto documentado.

---

## Alcance (entra / no entra)

### Entra

- Migrar `EventRepositoryImpl` de `FirebaseStorage` directo a `ImageStorageService` para el upload de portadas (Sub-tarea A).
- Integrar `ImageStorageService.deleteByUrl` en el flujo de **actualizacion de evento** cuando la portada cambia (Sub-tarea B).
- Integrar `ImageStorageService.deleteByUrl` en el flujo de **eliminacion de evento** cuando el evento tiene `imageUrl` en Storage (Sub-tarea B).
- El borrado ocurre en el cubit (capa de presentacion), despues de confirmar exito del backend, con `emit(data)` antes del `deleteByUrl` (fire-and-forget para la UI).
- Inyectar `ImageStorageService` en `EventRepositoryImpl` (reemplaza `FirebaseStorage`).
- Tests unitarios de los cubits afectados con `verifyInOrder` (backend primero, Storage despues) importando `test/helpers/storage_mocks.dart` de Fase 1.
- Documentar como deuda tecnica el upload anonimo pre-creacion (path `events/{ownerId}-{timestamp}/cover.jpg`).

### No entra

- Barrido retroactivo de portadas huerfanas de eventos abandonados antes de persistir (deuda tecnica conocida).
- Modificacion de contratos de `rideglory-api` (ningun endpoint toca Firebase Storage).
- Modificacion de la logica de upload propiamente dicha mas alla de reutilizar `ImageStorageService.uploadImage`.
- Cambio en el flujo de creacion de evento (no hay imagen previa que borrar).
- Cambio en `EventDetailCubit` mas alla de inyectar `ImageStorageService` para el deleteByUrl en delete (ver paso 5 abajo).
- Cambio en pantallas o widgets.

---

## Que se debe hacer (pasos concretos y ordenados)

### Sub-tarea A — Migrar upload a `ImageStorageService` en `EventRepositoryImpl`

**1. Sustituir `FirebaseStorage` por `ImageStorageService` en `EventRepositoryImpl`**

Cambiar la dependencia inyectada de `FirebaseStorage _storage` a `ImageStorageService _imageStorageService`. Reescribir `uploadEventImage` para delegar en `ImageStorageService.uploadImage(image: xFile, storagePath: 'events/$folder/cover.jpg')`. El metodo recibe `UploadEventImageRequest` que contiene el `localImagePath` como `String`; convertirlo a `XFile` antes de pasar al servicio.

> Nota: `ImageStorageService.uploadImage` acepta `XFile`, no `File`. El `localImagePath` de `UploadEventImageRequest` debe envolverse con `XFile(request.localImagePath)`.

**2. Agregar anotacion de deuda tecnica**

En el metodo `uploadEventImage`, agregar un comentario:
```dart
// TODO(debt): upload pre-creacion usa path anonimo events/{ownerId}-{timestamp}/cover.jpg.
// Si el evento se abandona, la imagen queda huerfana. Barrido retroactivo fuera del
// alcance de storage-hygiene — ver docs/plans/storage-hygiene/05-sintesis.md R5.
```

### Sub-tarea B — Integrar `deleteByUrl` en flujos de update y delete

**3. Inyectar `ImageStorageService` en `EventFormCubit`**

`EventFormCubit` ya inyecta `UploadEventImageUseCase` y otros casos de uso. Agregar `ImageStorageService` como parametro del constructor para poder llamar `deleteByUrl` post-update.

**4. Capturar `oldImageUrl` y borrar en `_saveExistingEvent` de `EventFormCubit`**

Antes de `emit(loading)` (que ocurre en `saveEvent` y `saveDraft` antes de llamar `_saveExistingEvent`), la URL anterior ya es conocida via `_editingEvent?.imageUrl`. Dentro de `_saveExistingEvent`, capturar `final oldImageUrl = _editingEvent?.imageUrl` al inicio del metodo — antes de cualquier `await`. Despues del update exitoso, el resultado se devuelve al llamador (`saveEvent`/`saveDraft`) que emite `ResultState.data`. El borrado debe ocurrir inmediatamente despues del `emit(data)`, como fire-and-forget:

```dart
// En saveEvent / saveDraft, bloque de exito del fold:
(event) {
  _terminalEventEmitted = true;
  emit(state.copyWith(saveResult: ResultState.data(data: event)));
  // Borrar portada anterior solo si la URL cambio
  if (oldImageUrl != null && oldImageUrl != event.imageUrl) {
    _imageStorageService.deleteByUrl(oldImageUrl).ignore();
  }
}
```

La `oldImageUrl` debe propagarse desde `_saveExistingEvent` al llamador. Opciones:

- Retornar un `record` o usar un campo privado temporal `_pendingOldImageUrl` en el cubit (preferido para no cambiar la firma del metodo privado `_saveExistingEvent`).
- Implementacion recomendada: campo privado `String? _oldCoverImageUrl` asignado al inicio de `_saveExistingEvent` antes de cualquier await, consultado en el bloque `fold` de exito de `saveEvent` y `saveDraft`.

**Regla critica de orden de operaciones:**
```
1. Capturar oldImageUrl (antes de emit(loading))
2. emit(loading)
3. Upload nueva imagen (si aplica)
4. PATCH /events/{id} al backend
5. emit(data) con nuevo EventModel
6. deleteByUrl(oldImageUrl) — fire-and-forget, solo si URL cambio
```

**5. Integrar `deleteByUrl` en `EventDeleteCubit`**

`EventDeleteCubit.deleteEvent(String eventId)` recibe solo el ID, no el `EventModel`. El borrado de Storage requiere la `imageUrl`. Cambiar la firma del metodo publico a:

```dart
Future<void> deleteEvent(String eventId, {String? coverImageUrl}) async
```

El llamador (widget de UI que muestra la pantalla de detalle del evento) ya tiene el `EventModel` en estado del `EventDetailCubit` y puede extraer `event.imageUrl` antes de llamar a `deleteEvent`. En el bloque de exito del fold:

```dart
(_) {
  emit(ResultState.data(data: eventId));
  if (coverImageUrl != null) {
    _imageStorageService.deleteByUrl(coverImageUrl).ignore();
  }
}
```

Inyectar `ImageStorageService` en `EventDeleteCubit`.

**Regla critica de orden de operaciones para delete:**
```
1. Llamador extrae coverImageUrl del estado del EventDetailCubit
2. emit(loading)
3. DELETE /events/{id} al backend
4. emit(data)
5. deleteByUrl(coverImageUrl) — fire-and-forget
```

**6. Ejecutar `dart run build_runner build --delete-conflicting-outputs`**

El cambio de dependencias en `EventRepositoryImpl` y los dos cubits requiere regenerar el codigo de DI (`injection.dart` generado por `injectable`). Verificar que no haya conflictos.

**7. Ejecutar `dart analyze` y `flutter test`**

Sin errores nuevos ni regresiones.

---

## Archivos a crear/modificar (rutas reales, una linea de que cambia)

| Archivo | Accion | Que cambia |
|---------|--------|------------|
| `lib/features/events/data/repository/event_repository_impl.dart` | Modificar | Sustituir `FirebaseStorage` por `ImageStorageService`; reescribir `uploadEventImage` delegando en `_imageStorageService.uploadImage`; agregar comentario de deuda en upload anonimo |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | Modificar | Inyectar `ImageStorageService`; capturar `oldImageUrl` en `_saveExistingEvent`; llamar `deleteByUrl` post-exito en `saveEvent` y `saveDraft` |
| `lib/features/events/presentation/delete/cubit/event_delete_cubit.dart` | Modificar | Inyectar `ImageStorageService`; cambiar firma de `deleteEvent` a `deleteEvent(String eventId, {String? coverImageUrl})`; llamar `deleteByUrl` post-exito |
| `test/features/events/data/repository/event_repository_impl_test.dart` | Crear | Tests de `uploadEventImage` con mock de `ImageStorageService` |
| `test/features/events/presentation/form/cubit/event_form_cover_cleanup_test.dart` | Crear | Tests de borrado de portada anterior en update (con `verifyInOrder`) |
| `test/features/events/presentation/delete/cubit/event_delete_cubit_test.dart` | Modificar | Agregar tests de borrado de portada en delete (con `verifyInOrder`); actualizar setup para `ImageStorageService` mock |

> `test/helpers/storage_mocks.dart` es creado en Fase 1. Esta fase solo lo importa.

---

## Contratos / API rideglory-api

Ninguno. El backend (`events-ms`) persiste `imageUrl` como string en la BD pero no gestiona Firebase Storage. Los endpoints `PATCH /events/{id}` y `DELETE /events/{id}` no cambian. Este plan no requiere modificaciones a `rideglory-api`.

---

## Cambios de datos / migraciones

Ninguno. No hay cambios en modelos de dominio, DTOs, ni en el esquema de BD. Las URLs existentes en la BD no se tocan — se seguiran almacenando y sirviendo normalmente. Solo el comportamiento del cliente Flutter al borrar/reemplazar cambia.

---

## Criterios de aceptacion (numerados, observables, testeables)

**CA-1 — Upload delegado a `ImageStorageService`**
`EventRepositoryImpl` no importa ni inyecta `FirebaseStorage` directamente. El metodo `uploadEventImage` invoca `_imageStorageService.uploadImage(image: XFile(request.localImagePath), storagePath: 'events/$folder/cover.jpg')`. Verificable con `dart analyze` (sin importacion de `firebase_storage` en `event_repository_impl.dart`) y con test unitario de repositorio usando `MockImageStorageService`.

**CA-2 — Borrado de portada anterior al editar evento (imagen local nueva)**
Cuando el organizador edita un evento que ya tiene portada en Storage y selecciona una imagen local nueva, despues de un update exitoso al backend, `ImageStorageService.deleteByUrl` es llamado con la URL anterior. La UI no queda bloqueada esperando el borrado (fire-and-forget). Verificable con test `verifyInOrder([mockUpdateEventUseCase.call(any()), mockImageStorageService.deleteByUrl(oldUrl)])`.

**CA-3 — Borrado de portada anterior al editar evento (URL remota nueva de Unsplash)**
Cuando el organizador reemplaza la portada con una URL de Unsplash (portada generada por IA), `deleteByUrl` es llamado con la URL anterior de Storage. La validacion de bucket en `deleteByUrl` (Fase 1) rechaza silenciosamente la URL de Unsplash si era la anterior — sin error, sin bloqueo. Verificable con test unitario del cubit.

**CA-4 — Portada Unsplash existente no genera borrado en Storage**
Cuando `_editingEvent?.imageUrl` es una URL de Unsplash (no del bucket propio), y el organizador guarda el evento sin cambiar la portada, `deleteByUrl` NO es llamado (o si es llamado, la implementacion de Fase 1 lo ignora silenciosamente). Verificable con test unitario: `verifyNever(() => mockImageStorageService.deleteByUrl(any()))` cuando `oldImageUrl == newImageUrl`.

**CA-5 — Borrado de portada al eliminar evento**
Cuando `EventDeleteCubit.deleteEvent(eventId, coverImageUrl: url)` se llama con una URL de portada, despues del delete exitoso al backend, `deleteByUrl(url)` es invocado. Verificable con test `verifyInOrder([mockDeleteEventUseCase.call(eventId), mockImageStorageService.deleteByUrl(url)])`.

**CA-6 — Delete sin portada no falla**
Cuando `EventDeleteCubit.deleteEvent(eventId)` se llama sin `coverImageUrl` (evento sin portada), el flujo es identico al actual: el evento se elimina del backend y se emite `ResultState.data`. `deleteByUrl` NO es llamado. Verificable con test unitario: `verifyNever(() => mockImageStorageService.deleteByUrl(any()))`.

**CA-7 — Orden de operaciones verificado**
Los tests de cubits afectados incluyen `verifyInOrder` que confirma: (1) llamada al backend (use case), (2) `emit(data)`, (3) `deleteByUrl`. El borrado de Storage nunca precede a la confirmacion del backend.

**CA-8 — Sin regresiones**
`flutter test` pasa sin errores nuevos. `dart analyze` no reporta warnings ni errores nuevos. Los tests existentes de `EventDeleteCubit`, `EventFormCubit` y `EventDetailCubit` siguen pasando (actualizar los mocks del constructor donde sea necesario).

**CA-9 — DI regenerado correctamente**
`dart run build_runner build --delete-conflicting-outputs` completa sin errores. El contenedor de DI generado resuelve `EventRepositoryImpl` con `ImageStorageService` y los cubits con sus nuevas dependencias.

---

## Pruebas (unitarias/widget/integracion)

### Tests unitarios — `EventFormCubit` (cover cleanup)

**Archivo:** `test/features/events/presentation/form/cubit/event_form_cover_cleanup_test.dart`

**Imports:** `test/helpers/storage_mocks.dart` (de Fase 1), `bloc_test`, `mocktail`.

| ID | Descripcion | Verificacion |
|----|-------------|-------------|
| TC-form-c1 | `saveEvent` editing con imagen local nueva: deleteByUrl llamado con oldUrl post-exito | `verifyInOrder([updateUseCase, imageStorageService.deleteByUrl(oldUrl)])` |
| TC-form-c2 | `saveEvent` editing con URL remota nueva: deleteByUrl llamado con oldUrl post-exito | Idem con URL nueva distinta a oldUrl |
| TC-form-c3 | `saveEvent` editing sin cambio de imagen: deleteByUrl NO llamado | `verifyNever(() => imageStorageService.deleteByUrl(any()))` |
| TC-form-c4 | `saveEvent` editing con portada Unsplash como oldUrl: deleteByUrl llamado (Fase 1 lo ignora) | Solo verifica que se llama; el comportamiento de ignorar es responsabilidad de Fase 1 |
| TC-form-c5 | `saveEvent` error de backend: deleteByUrl NO llamado | `verifyNever(() => imageStorageService.deleteByUrl(any()))` |
| TC-form-c6 | `saveDraft` editing con imagen local nueva: mismo patron que TC-form-c1 | `verifyInOrder` |

### Tests unitarios — `EventDeleteCubit` (storage cleanup)

**Archivo:** `test/features/events/presentation/delete/cubit/event_delete_cubit_test.dart` (grupo nuevo)

| ID | Descripcion | Verificacion |
|----|-------------|-------------|
| TC-del-c1 | `deleteEvent(id, coverImageUrl: url)` exito: deleteByUrl llamado con url post-delete | `verifyInOrder([deleteUseCase(id), imageStorageService.deleteByUrl(url)])` |
| TC-del-c2 | `deleteEvent(id)` sin coverImageUrl: deleteByUrl NO llamado | `verifyNever(() => imageStorageService.deleteByUrl(any()))` |
| TC-del-c3 | `deleteEvent(id, coverImageUrl: url)` backend falla: deleteByUrl NO llamado | `verifyNever(() => imageStorageService.deleteByUrl(any()))` |
| TC-del-c4 | Estado emitido es `data` antes de que deleteByUrl sea awaited | Verificado con `blocTest` y `expect` de estados |

### Tests unitarios — `EventRepositoryImpl`

**Archivo:** `test/features/events/data/repository/event_repository_impl_test.dart`

| ID | Descripcion | Verificacion |
|----|-------------|-------------|
| TC-repo-e1 | `uploadEventImage` delega en `ImageStorageService.uploadImage` con path correcto | `verify(() => mockImageStorageService.uploadImage(image: any(named:'image'), storagePath: 'events/$eventId/cover.jpg'))` |
| TC-repo-e2 | `uploadEventImage` con `eventId` null usa path anonimo | `storagePath` contiene `ownerId` y timestamp |

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigacion |
|---|--------|-----------|------------|
| R1 | **Borrado prematuro:** `deleteByUrl` llamado antes de confirmar respuesta del backend | Alta | Patron estricto: `deleteByUrl` solo en bloque de exito del `fold`, despues de `emit(data)`. Verificado con `verifyInOrder` en tests. |
| R2 | **`_editingEvent` es null en `EventFormCubit`:** si `initialize()` no fue llamado, `_editingEvent?.imageUrl` es null y no hay borrado | Media | Comportamiento correcto: si no hay evento previo (creacion), no hay imagen anterior que borrar. Documentado como precondicion. |
| R3 | **Portadas Unsplash como `oldImageUrl`:** `deleteByUrl` se llama con URL de Unsplash; debe rechazarla silenciosamente | Baja | La validacion de bucket en `deleteByUrl` (Fase 1) cubre este caso. Si Fase 1 no esta completa, esta fase no puede ejecutarse. |
| R4 | **Upload anonimo pre-creacion queda como huerfano:** `events/{ownerId}-{timestamp}/cover.jpg` de eventos abandonados | Baja | Explicito fuera de alcance. Comentario `TODO(debt)` en el codigo. Registrado en `05-sintesis.md` como R5. |
| R5 | **`EventDeleteCubit` firma cambiada:** callers del cubit deben actualizarse para pasar `coverImageUrl` | Media | Buscar todos los call sites de `deleteEvent` en el arbol de widgets (probablemente un solo lugar: el bottom sheet/dialog de confirmacion de borrado del evento). Actualizar para extraer `imageUrl` del estado del `EventDetailCubit`. |
| R6 | **DI regeneration gotcha:** `build_runner` puede fallar en entornos frescos por build hooks de `objective_c` | Baja | Usar `--force-jit` o copiar `pubspec.lock` de main (documentado en MEMORY.md). |

---

## Dependencias (fases prerequisito y por que)

**Fase 1 — Storage Delete Utility (obligatoria)**

Esta fase requiere que `ImageStorageService.deleteByUrl` exista con la firma y comportamiento exactos definidos en Fase 1:
- Validacion de pertenencia al bucket (`AppEnv.firebaseStorageBucket`) para ignorar silenciosamente URLs de Unsplash.
- Idempotencia ante `object-not-found` (404 no es error).
- Log de warning ante errores de red/permisos sin propagar excepcion.
- `test/helpers/storage_mocks.dart` disponible con las clases mock y helpers reutilizables.

Sin Fase 1, los tests de esta fase no pueden importar los helpers de mocks, y `deleteByUrl` no existe en `ImageStorageService`. No ejecutar esta fase hasta que Fase 1 este completa y con tests pasando.

**Fases 4 y 5 (sin dependencia de esta fase)**

SOAT y RTM son independientes de eventos. Pueden ejecutarse en cualquier orden despues de Fase 1.

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Por que normal y no lite:**

- Toca tres archivos de produccion en dos capas distintas (`EventRepositoryImpl` en data, `EventFormCubit` y `EventDeleteCubit` en presentacion) con logica de coordinacion inter-cubit (el llamador del delete necesita extraer la URL del `EventDetailCubit`).
- El patron de orden de operaciones es critico: `emit(data)` antes de `deleteByUrl`, nunca antes de la respuesta del backend. Un error en el orden rompe la consistencia de datos.
- El edge case de portadas de Unsplash (generadas por IA en iteracion anterior) requiere que el implementador entienda la validacion de bucket de Fase 1 y verifique que el flujo pasa por ella correctamente.
- `EventFormCubit` tiene dos paths de exito (`saveEvent` y `saveDraft`), ambos llaman a `_saveExistingEvent` en modo edicion — el borrado debe ocurrir en ambos.
- El cambio de firma de `EventDeleteCubit.deleteEvent` puede tener call sites en la UI que deben actualizarse.
- Los tests de `verifyInOrder` requieren mocks bien configurados de `ImageStorageService`, `UpdateEventUseCase` y `DeleteEventUseCase` simultaneamente.

**Nivel lite no es suficiente** porque hay logica de ramificacion (imagen local vs. URL remota vs. sin cambio de imagen), un cambio de firma publica de cubit, y tests de orden de operaciones que van mas alla de un simple mock-and-verify.
