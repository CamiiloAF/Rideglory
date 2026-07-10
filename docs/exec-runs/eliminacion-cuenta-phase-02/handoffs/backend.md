# Backend handoff (rideglory-api) — eliminacion-cuenta-phase-02

**Date:** 2026-07-10T19:10:44Z
**Status:** done (corrección aplicada tras auditor Opus)

## Baseline

Esta corrida re-ejecuta la fase después de que la corrida previa se detuvo con `status: fail` por
un rojo preexistente fuera de esta fase (ver historial de esta sesión, mismo archivo, versión
anterior con timestamp `2026-07-10T18:56:40Z`).

1. **Fix del rojo preexistente** (mandato explícito del auditor, con alternativa dejada a mi
   criterio): `vehicles-ms/src/vehicles/vehicles.service.spec.ts` esperaba `isArchived: false` en
   el `where` de `findByOwnerId()`, pero el código no lo aplicaba (desface introducido en el commit
   `1ec13922`, 2026-06-17). Antes de aplicar el fix sugerido por el auditor (agregar
   `isArchived: false` al `where`), verifiqué el consumidor real en Flutter:
   `garage_vehicles_content.dart` hace `context.watch<VehicleCubit>().state` → `allVehicles` →
   `.where((v) => !v.isArchived)` / `.where((v) => v.isArchived)` para poblar
   `GarageVehiclesContent` (sección activa) y `GarageArchivedSection` (sección archivada) **a
   partir de una sola llamada** a `getMyVehicles()` → `findVehiclesByOwnerId` → `findByOwnerId()`.
   Si `findByOwnerId()` excluyera los archivados en el servidor, la sección "Archivados" del garage
   quedaría vacía siempre en producción — una regresión real, no cosmética.
   **Decisión:** corregí el spec (no el código) para reflejar el comportamiento correcto —
   `findByOwnerId` incluye archivados, solo excluye `isDeleted`. Documenté la razón en el comentario
   `AC-1` del spec y agregué un test explícito que verifica que un vehículo archivado sí aparece en
   el resultado.
2. Con ese fix, `vehicles-ms` completo quedó verde antes de aplicar el change map de esta fase
   (46/46), y terminó en 50/50 tras agregar los tests nuevos.
3. `maintenances-ms`: sin tests (`no matches found`), consistente con el change map (crear el spec
   desde cero) — no cuenta como rojo preexistente.
4. `api-gateway` (`src/ai` + `src/users`): 9/9 verde antes de tocar nada de esta fase.
5. **Nota aparte, fuera del scope de esta fase**: `api-gateway/src/places/places.service.iter3.spec.ts`
   tiene 8 tests rojos preexistentes (verificado con `git stash` — el rojo persiste sin ninguno de
   mis cambios). No toca ningún archivo del change map de `eliminacion-cuenta-phase-02`; no lo
   toqué. Lo dejo anotado para que quede registrado, no lo arreglé (no está en el change map y
   arreglarlo requeriría entender un feature no relacionado).

## Archivos cambiados

**vehicles-ms**
- `src/vehicles/vehicles.service.ts` — nuevo `hardDeleteAllByOwner(ownerId)`: captura
  `imageUrl`/`documentUrl` de `Vehicle`/`Soat`/`Tecnomecanica` del owner, deduplica y filtra nulls,
  y borra los 3 en una única `$transaction` (array form), orden `Soat → Tecnomecanica → Vehicle`.
  Garage vacío devuelve `{ deletedVehicleCount: 0, imageUrls: [] }` sin abrir transacción.
- `src/vehicles/vehicles.controller.ts` — nuevo `@MessagePattern('hardDeleteAllByOwner')`.
- `src/vehicles/vehicles.service.spec.ts` — 4 tests nuevos de `hardDeleteAllByOwner` (garage vacío,
  N vehículos con SOAT/RTM + dedupe de URLs, filtrado de nulls + dedupe, transacción con 3
  operaciones); ajuste del mock de Prisma para incluir `soat`/`tecnomecanica`/`vehicle.deleteMany`;
  **corrección del rojo preexistente** en `describe('findByOwnerId (AC-1)')` (ver Baseline);
  tipado explícito (`as string | null` / `as Date | null`) en `BASE_VEHICLE` para permitir
  overrides con valores no-null en los tests nuevos (error de TS preexistente que solo se
  manifestaba al usar `imageUrl` con un string).

**maintenances-ms**
- `src/maintenances/maintenances.service.ts` — nuevo `softDeleteAllByUserId(userId)`, análogo a
  `softDeleteAllByVehicleId` ya existente.
- `src/maintenances/maintenances.controller.ts` — nuevo
  `@MessagePattern('softDeleteMaintenancesByUserId')`.
- `src/maintenances/maintenances.service.spec.ts` — **archivo nuevo** (no existía). 3 tests:
  M registros soft-deleted, 0 registros, idempotencia (segunda corrida devuelve `count: 0`).

**api-gateway**
- `src/ai/storage-cleanup.service.ts` — nuevo `deleteFilesByUrls(urls)`: filtra
  null/undefined/`''`, parsea el path desde ambos formatos de URL observados en el codebase
  Flutter (`firebasestorage.googleapis.com/v0/b/{bucket}/o/{encodedPath}?...` — usado por
  `ImageStorageService.getDownloadURL()` para fotos de vehículo, SOAT y RTM — y
  `storage.googleapis.com/{bucket}/{path}` — usado por `StorageService.uploadCover` en este mismo
  repo), y borra cada archivo en su propio `try/catch` (loguea `warn` y continúa, nunca relanza).
  URL no parseable se loguea y se salta sin abortar el batch.
- `src/ai/ai.module.ts` — registré `StorageCleanupService` en `providers` (antes era código huérfano,
  no estaba en ningún módulo) y agregué `exports: [StorageCleanupService]`.
- `src/ai/storage-cleanup.service.spec.ts` — 6 tests nuevos de `deleteFilesByUrls`: URL formato
  Firebase SDK, URL formato público, lista vacía, filtrado de null/undefined/`''`, fallo individual
  no aborta el batch (objeto inexistente), URL no parseable no lanza.
- `src/users/users.module.ts` — agregué `VEHICLES_SERVICE` y `MAINTENANCES_SERVICE` a
  `ClientsModule.registerAsync` (copiado del patrón de `vehicles.module.ts`) e importé `AiModule`.
- `src/users/account-deletion.service.ts` — constructor pasa de 2 a 5 dependencias
  (`usersService`, `vehiclesService`, `maintenancesService`, `storageCleanupService`,
  `firebaseAuthService`). Reemplacé los 2 `// TODO fase 2/3` por la orquestación de 6 pasos:
  `findUserByEmail → hardDeleteAllByOwner (timeout 15s + catchError→502) → deleteFilesByUrls
  (try/catch, no relanza) → softDeleteMaintenancesByUserId (timeout 15s + catchError→502) →
  hardDeleteUser → firebaseAuthService.deleteUser`.
- `src/users/account-deletion.service.spec.ts` — reescrito: mocks del constructor actualizados a 5
  deps; 7 tests: orden de 6 pasos, garage vacío (`imageUrls: []`, `deleteFilesByUrls` se llama
  igual con array vacío), fallo de storage no aborta el flujo, propagación del 404 de
  `findUserByEmail`, fallo de `hardDeleteAllByOwner` aborta antes de storage/maintenances/hardDelete/
  Firebase, fallo de `softDeleteMaintenancesByUserId` aborta antes de hardDeleteUser/Firebase, fallo
  de `hardDeleteUser` aborta antes de Firebase.

**Rideglory (Flutter, solo docs)**
- `docs/features/vehicles.md` — nota de cascada en §8 (Archivado y borrado).
- `docs/features/soat.md` — nota de cascada al final de §11 (Patrones y trampas conocidas).
- `docs/features/tecnomecanica.md` — nota de cascada al final de §9 (Modelo de datos).
- `docs/features/maintenance.md` — nota de cascada (soft-delete por `userId`, sin loop por
  vehículo) al final de §12 (Patrones y trampas conocidas).

## Pruebas nuevas

| Suite | Archivo | Casos nuevos |
|---|---|---|
| vehicles-ms | `vehicles.service.spec.ts` | 4 (`hardDeleteAllByOwner`: garage vacío, N vehículos + dedupe, filtrado nulls + dedupe, transacción de 3 ops) + 1 (`findByOwnerId` incluye archivados) reemplazando el caso roto |
| maintenances-ms | `maintenances.service.spec.ts` (nuevo) | 3 (M registros, 0 registros, idempotencia) |
| api-gateway | `storage-cleanup.service.spec.ts` | 6 (`deleteFilesByUrls`: URL Firebase SDK, URL pública, lista vacía, filtrado nulls, fallo individual no aborta, URL no parseable) |
| api-gateway | `account-deletion.service.spec.ts` | 7 (reescritos: orden 6 pasos, garage vacío, fallo storage no aborta, 404 findUserByEmail, fallo hardDeleteAllByOwner aborta, fallo softDeleteMaintenancesByUserId aborta, fallo hardDeleteUser aborta) |

## Resultado final

`status: pass`.

| Suite | Comando | Resultado |
|---|---|---|
| `vehicles-ms` | `npx jest` | **50 passed, 50 total** (3 suites) |
| `maintenances-ms` | `npx jest` | **3 passed, 3 total** (1 suite) |
| `api-gateway` (`src/ai` + `src/users`) | `npx jest src/ai src/users` | **54 passed, 54 total** (8 suites) |
| `tsc --noEmit` en los 3 proyectos | — | sin errores |
| `dart analyze` (Rideglory Flutter) | — | 15 info preexistentes, 0 errores (solo cambié docs) |

No corrí `npx jest` completo de `api-gateway` como gate de esta fase porque incluye
`src/places/places.service.iter3.spec.ts`, rojo preexistente y no relacionado (ver Baseline).

## Verificación manual

No se ejecutó contra base de datos real ni Firebase Storage real — toda la cobertura es unitaria
con Prisma/Firebase Admin mockeados, siguiendo el patrón ya usado por los specs vecinos del repo.
Recomendado para QA: con un usuario de prueba con N vehículos (con SOAT/RTM y fotos) y M
mantenimientos, ejecutar `DELETE /users/me` end-to-end contra un entorno real y verificar por
query directa a la BD (no solo por la respuesta HTTP) que `Vehicle`/`Soat`/`Tecnomecanica` no
tienen filas de ese owner, que `Maintenance` quedó con `isDeleted: true`, y que los objetos en
Firebase Storage referenciados por esas filas ya no existen.

## Notas Frontend/QA

- No hay cambios de contrato HTTP nuevo — todo vía `MessagePattern` interno
  (`hardDeleteAllByOwner`, `softDeleteMaintenancesByUserId`), sin DTOs nuevos en
  `rideglory-contracts`.
- El endpoint público `DELETE /users/me` (fase 1) no cambió su firma ni su respuesta; solo se
  ampliaron los pasos internos de la orquestación de 5 a 6.
- **Hallazgo relevante para QA**: durante esta fase se corrigió un desface preexistente en
  `findByOwnerId()` de `vehicles-ms` — el garage de un usuario (`GET /vehicles/my`) siempre debe
  incluir vehículos archivados en la respuesta (la app los filtra client-side en dos secciones:
  activos y archivados). Si en algún QA anterior se observó la sección "Archivados" vacía cuando sí
  había vehículos archivados, ese sería el bug que este fix cierra (era un desface código/test, no
  llegó a producción porque el código nunca aplicó el filtro que el test rojo exigía).
- Casos de QA manual sugeridos para esta fase específicamente: usuario con SOAT/RTM sin foto
  (`documentUrl: null`) completa borrado de cuenta sin error; usuario con imagen de vehículo ya
  borrada manualmente de Storage (URL "colgada") completa borrado sin error 500; usuario sin
  vehículos (garage vacío) completa borrado sin error.
- `places.service.iter3.spec.ts` sigue rojo (8 tests) — no relacionado a esta fase, dejar
  registrado para que otra fase/persona lo levante.
