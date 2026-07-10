# SUMMARY — eliminacion-cuenta-phase-02

**Fecha:** 2026-07-10T19:22:08Z
**Nivel:** normal
**Tech Lead:** revisión sobre working tree (sin PR, sin commits)

## Objetivo

Que `DELETE /users/me` (fase 1: identidad/PII + Firebase Auth) también borre en cascada, en el
backend, los datos de dominio del owner que ya prometía el copy de confirmación de fase 1:
vehículos, SOAT, RTM (con sus imágenes en Firebase Storage) y el historial de mantenimientos.
100% backend (`rideglory-api`); en Rideglory (Flutter) solo se tocó documentación.

## Qué cambió por área

**`vehicles-ms`**
- Nuevo `VehiclesService.hardDeleteAllByOwner(ownerId)`: busca los vehículos del owner, recolecta
  `imageUrl`/`documentUrl` (vehículo + SOAT + RTM asociados), filtra nulls/vacíos y dedupea, y borra
  `Soat` → `Tecnomecanica` → `Vehicle` en una única `$transaction` Prisma (hard-delete, sin
  `onDelete: Cascade`, tal como fija el PRD). Garage vacío retorna `{deletedVehicleCount:0,
  imageUrls:[]}` sin abrir transacción.
- Nuevo `@MessagePattern('hardDeleteAllByOwner')` en el controller, con `ParseUUIDPipe` sobre
  `ownerId`.

**`maintenances-ms`**
- Nuevo `MaintenancesService.softDeleteAllByUserId(userId)`: `updateMany({ where: { userId,
  isDeleted: false }, data: { isDeleted: true } })` — un solo query, sin loopear por `vehicleId`.
  Idempotente (segunda corrida actualiza 0 filas).
- Nuevo `@MessagePattern('softDeleteMaintenancesByUserId')`, con la misma convención de payload
  bare (`@Payload('userId')`) que ya usa `softDeleteMaintenancesByVehicleId` en este controller.

**`api-gateway`**
- `AccountDeletionService.deleteAccount` pasa de 5 a 6 pasos: `findUserByEmail` →
  `hardDeleteAllByOwner` (vehicles-ms) → `deleteFilesByUrls` (Storage, best-effort) →
  `softDeleteMaintenancesByUserId` (maintenances-ms) → `hardDeleteUser` (users-ms) →
  `firebaseAuthService.deleteUser` (siempre último). Los pasos 2, 4 y 5 usan `timeout(15s)` +
  `catchError` → `RpcException(502, retryable)`, igual patrón que el resto del repo. El fallo del
  paso 3 (Storage) se loguea y NO aborta el flujo (`try/catch` local).
- `StorageCleanupService.deleteFilesByUrls(urls)`: nuevo método best-effort que parsea el path de
  Storage desde cada download URL (formato Firebase SDK `/o/{encodedPath}` y formato público
  `storage.googleapis.com/{bucket}/{path}`), borra cada archivo en su propio `try/catch` (URL no
  parseable o archivo inexistente → warning + continúa, nunca aborta el batch).
- `AiModule` exporta `StorageCleanupService`; `UsersModule` importa `AiModule` y registra
  `VEHICLES_SERVICE`/`MAINTENANCES_SERVICE` como `ClientsModule` TCP adicionales (mismo patrón de
  `TracingSerializer` que `USERS_SERVICE`).

**Rideglory (Flutter) — solo docs, sin código**
- `docs/features/vehicles.md`, `soat.md`, `tecnomecanica.md`, `maintenance.md`: nota de
  comportamiento sobre el borrado en cascada al eliminar cuenta. Sin cambios de UI/UX/copy en la
  app — consistente con el alcance ("no entra") del PRD.

## Archivos

`rideglory-api` (repo separado, working tree sucio, NO commiteado):
- `vehicles-ms/src/vehicles/vehicles.service.ts`, `vehicles.controller.ts`,
  `vehicles.service.spec.ts`
- `maintenances-ms/src/maintenances/maintenances.service.ts`, `maintenances.controller.ts`,
  `maintenances.service.spec.ts` (nuevo)
- `api-gateway/src/users/account-deletion.service.ts`, `account-deletion.service.spec.ts`,
  `users.module.ts`
- `api-gateway/src/ai/storage-cleanup.service.ts`, `storage-cleanup.service.spec.ts`,
  `ai.module.ts`

Rideglory (este repo, working tree sucio, NO commiteado):
- `docs/features/vehicles.md`, `docs/features/soat.md`, `docs/features/tecnomecanica.md`,
  `docs/features/maintenance.md`

## Pruebas

| Suite | Comando | Resultado |
|---|---|---|
| `vehicles-ms` (`src/vehicles`) | `npx jest src/vehicles/vehicles.service.spec.ts` | 23 passed (reproducido por Tech Lead) |
| `maintenances-ms` (`src/maintenances`) | `npx jest src/maintenances/maintenances.service.spec.ts` | 3 passed (reproducido) |
| `api-gateway` (`src/ai` + `src/users`, specs tocados) | `npx jest src/users/account-deletion.service.spec.ts src/ai/storage-cleanup.service.spec.ts` | 19 passed (reproducido) |
| Rideglory `dart analyze` | `dart analyze` | 0 errores; 15 `info` preexistentes no relacionados a esta fase (reproducido) |

QA (`handoffs/qa.md`) reporta además la corrida completa: `vehicles-ms` 50/50, `maintenances-ms`
3/3, `api-gateway` (`src/ai`+`src/users`) 54/54, Flutter `flutter test` 1386/1386. No se corrió
contra Postgres/Firebase Storage reales — toda la cobertura nueva es unitaria con mocks; ver Gaps
en `handoffs/qa.md` y la sección de pruebas manuales abajo.

## Riesgos / watchlist

- **Sin `onDelete: Cascade`**: el borrado depende de que `hardDeleteAllByOwner` mantenga el orden
  `Soat → Tecnomecanica → Vehicle` dentro de la misma transacción. Si en el futuro se agrega una
  nueva tabla con FK a `Vehicle` sin actualizar este método, quedarán filas huérfanas silenciosas
  (no hay constraint de BD que lo impida).
- **Storage cleanup es best-effort sin retry**: un fallo transitorio de red hacia Firebase Storage
  en el momento del borrado deja imágenes huérfanas en el bucket permanentemente (no hay job de
  reconciliación). Aceptado explícitamente por el PRD/Architect para esta fase; señalado también
  por QA como gap, no como bug.
- **Cobertura 100% mockeada**: ningún test corre contra Postgres o el bucket real de Firebase
  Storage. El comportamiento real de `bucket.file(path).delete()` ante permisos/latencia de red no
  está probado. Ver "Pruebas manuales" en `handoffs/tech_lead.md` antes de considerar la fase
  cerrada para producción.
- **Test-only touch fuera del change map**: `vehicles-ms/src/vehicles/vehicles.service.spec.ts`
  también corrige el test `findByOwnerId (AC-1)` que afirmaba (incorrectamente) que el método
  filtraba `isArchived:false` — verificado que `findByOwnerId` en `vehicles.service.ts` YA no tenía
  ese filtro antes de esta fase (no es un cambio de comportamiento de esta fase, es una corrección
  de un test que estaba desalineado con el código real). No bloquea, pero no estaba en el change
  map del PRD — dejar constancia para que no sorprenda en un review posterior.

## Mensaje de commit sugerido

Para `rideglory-api` (probablemente 3 commits, uno por submódulo/PR, o uno solo si el flujo del
equipo lo permite):

```
feat(vehicles): hard-delete en cascada de vehiculos/SOAT/RTM del owner

Nuevo hardDeleteAllByOwner(ownerId): borra Soat, Tecnomecanica y Vehicle
del owner en una unica transaccion Prisma y devuelve las imageUrls/
documentUrls asociadas para limpieza posterior en Storage. Paso nuevo de
la orquestacion de DELETE /users/me (fase 2 de eliminacion de cuenta).
```

```
feat(maintenances): soft-delete de mantenimientos por userId sin loop de vehiculos

Nuevo softDeleteMaintenancesByUserId: un updateMany por userId en vez de
loopear softDeleteMaintenancesByVehicleId por cada vehiculo del owner.
Paso nuevo de la orquestacion de DELETE /users/me (fase 2).
```

```
feat(users): orquestar borrado en cascada de vehiculos/mantenimientos/storage en DELETE /users/me

AccountDeletionService pasa de 5 a 6 pasos: hardDeleteAllByOwner (vehicles-ms)
-> limpieza best-effort de Storage (nuevo StorageCleanupService.deleteFilesByUrls)
-> softDeleteMaintenancesByUserId (maintenances-ms) -> hardDeleteUser -> Firebase
Auth. Cierra la fase 2 de eliminacion de cuenta: hace cierta la promesa que la
pantalla de confirmacion de fase 1 ya le muestra al usuario.
```

Para Rideglory (solo docs):

```
docs(vehicles,soat,tecnomecanica,maintenance): documentar borrado en cascada al eliminar cuenta
```
