# Tech Lead handoff — eliminacion-cuenta-phase-02

**Fecha:** 2026-07-10T19:22:08Z
**Nivel:** normal
**Modo:** revisión de working tree (sin PR), artefactos escritos, NO se commiteó nada.

## Veredicto

**ready** (aprobado) — sin blockers. Working tree queda sucio a propósito para que el humano
revise y commitee siguiendo `REVIEW_CHECKLIST.md`.

## Hallazgos

Ninguno bloqueante. Un hallazgo menor no bloqueante, documentado también en `SUMMARY.md`:

- **Test-only fuera de change map**: `vehicles-ms/src/vehicles/vehicles.service.spec.ts` corrige
  el test `findByOwnerId (AC-1)` que aseveraba (incorrectamente) que el método filtraba
  `isArchived:false`. Verifiqué leyendo `vehicles.service.ts` que `findByOwnerId` YA no tenía ese
  filtro antes de esta fase — es una corrección de un test desalineado con el código real, no un
  cambio de comportamiento introducido por esta fase. No estaba en el change map del PRD
  (§4 Áreas afectadas). Sugiero decidir si va en el mismo commit o en uno de "test fix" separado
  (ver `REVIEW_CHECKLIST.md`).

## Seguridad

- No se agregaron endpoints HTTP nuevos en `api-gateway` (confirmado: solo 2 `@MessagePattern`
  RPC internos nuevos, `DELETE /users/me` no cambia firma) — cumple el guardrail del PRD.
- Sin secretos ni credenciales en el diff.
- Sin SQL concatenado — todo el acceso a datos usa Prisma con `where`/`findMany`/`deleteMany`
  tipados.
- Sin XSS (no hay superficie de renderizado nuevo, es 100% backend/RPC).
- Sin PII en logs: `deleteFilesByUrls` loguea la URL de Storage en caso de fallo (no email/nombre/
  documento de identidad); `account-deletion.service.ts` loguea el mensaje de error de storage
  cleanup, no el payload del usuario. Aceptable — las URLs de Storage no son PII per se (son paths
  de objetos, ya conocidos por quien tiene acceso al bucket).
- `ParseUUIDPipe` en `hardDeleteAllByOwner` (vehicles-ms) valida que `ownerId` sea un UUID antes de
  tocar la BD; `softDeleteMaintenancesByUserId` (maintenances-ms) usa `@Payload('userId')` sin
  pipe, pero es exactamente el mismo patrón que el `@MessagePattern` vecino
  `softDeleteMaintenancesByVehicleId` ya en producción — consistencia interna del microservicio,
  no una regresión introducida por esta fase.
- Autenticación/autorización: el `ownerId`/`userId` usado en ambos MS proviene de
  `findUserByEmail` resuelto desde el email del token Firebase ya autenticado en `api-gateway`
  (paso 1 de la orquestación, sin cambios en esta fase) — no hay superficie nueva de bypass de
  auth.

## Arquitectura

- **Clean Architecture / capas**: cambios 100% en `rideglory-api` (servicios NestJS +
  microservicios), sin tocar Flutter salvo docs. No aplica el chequeo de domain/data/presentation
  de Rideglory a este diff.
- **Sin `onDelete: Cascade`**: confirmado — no se tocó ningún `schema.prisma`. El borrado es
  explícito y transaccional (`$transaction([soat.deleteMany, tecnomecanica.deleteMany,
  vehicle.deleteMany])`), en el orden fijado por el Architect. Cumple el guardrail.
- **Orden de orquestación**: `AccountDeletionService.deleteAccount` sigue el orden documentado en
  el PRD (dominio → PII de usuario → Firebase Auth al final), insertando los 2 pasos nuevos (2 y 4)
  antes del hard-delete de usuario (5) y Firebase Auth (6). Verificado con test explícito de orden
  (`callOrder` array) en `account-deletion.service.spec.ts`.
- **Shape de API/contrato**: no se agregó ningún DTO a `rideglory-contracts` — el resultado de
  `hardDeleteAllByOwner` se tipa localmente en `api-gateway` con una interfaz
  `HardDeleteAllByOwnerResult` inline, consistente con la decisión "opcional" del PRD. No hay
  riesgo de `MODULE_NOT_FOUND` porque no se tocó el paquete compartido.
- **Best-effort de Storage**: `deleteFilesByUrls` no lanza excepción por archivo individual
  (`try/catch` por archivo) y el llamador (`account-deletion.service.ts`) también envuelve la
  llamada completa en `try/catch` — doble capa de contención, cumple el guardrail "nunca abortar
  el batch por un archivo".
- **DI/wiring**: `VEHICLES_SERVICE`/`MAINTENANCES_SERVICE` registrados como `ClientsModule.
  registerAsync` en `users.module.ts`, mismo patrón TCP + `TracingSerializer` que `USERS_SERVICE`
  existente. `AiModule` exporta `StorageCleanupService` y `UsersModule` lo importa — sin ciclos de
  módulos detectados en el diff.
- **rideglory-coding-standards.mdc**: aplica solo a la parte Flutter tocada (4 archivos de
  `docs/features/`) — son notas de documentación en prosa, no código; no aplica lint de widgets/
  cubits/DTOs.

## Tests

Cada AC del PRD_NORMALIZED.md (§5) tiene cobertura:

| AC | Test |
|---|---|
| 1 (hard-delete Vehicle/Soat/Tecnomecanica) | `vehicles.service.spec.ts` — "deletes Soat, Tecnomecanica and Vehicle for every vehicle of the owner and collects urls" + test de orden de `$transaction` |
| 2 (soft-delete Maintenance sin loop) | `maintenances.service.spec.ts` — "soft-deletes every non-deleted maintenance record for the user, across vehicles" (un solo `updateMany`) |
| 3 (imágenes ya no existen en Storage) | `storage-cleanup.service.spec.ts` — parseo de ambos formatos de URL + `file.delete()` invocado |
| 4 (SOAT/RTM sin foto no bloquea) | `vehicles.service.spec.ts` — "filters out null imageUrls/documentUrls" + `storage-cleanup.service.spec.ts` — "filters out null/undefined/empty entries" |
| 5 (fallo individual no aborta batch/no 500) | `storage-cleanup.service.spec.ts` — "continues the batch when one file fails to delete" + `account-deletion.service.spec.ts` — "storage cleanup failure does NOT abort the flow" |
| 6 (garage vacío sin error) | `vehicles.service.spec.ts` — "returns zero counts and empty urls without opening a transaction" + `account-deletion.service.spec.ts` — "empty garage" |
| 7 (`dart analyze`/`flutter test` en verde) | Reproducido por Tech Lead: `dart analyze` 0 errores; QA reporta `flutter test` 1386/1386 |
| 8 (tests unitarios nuevos pasan) | Reproducido por Tech Lead localmente (ver abajo); QA reporta corrida completa de las 3 suites en verde |

Reproducción local de Tech Lead (subconjunto de specs tocados):

```
vehicles-ms:      npx jest src/vehicles/vehicles.service.spec.ts       → 23 passed
maintenances-ms:  npx jest src/maintenances/maintenances.service.spec.ts → 3 passed
api-gateway:      npx jest src/users/account-deletion.service.spec.ts
                            src/ai/storage-cleanup.service.spec.ts      → 19 passed
Rideglory:        dart analyze                                          → 0 errores (15 info preexistentes)
```

Cada test nuevo falla sin el cambio correspondiente: los tests de `hardDeleteAllByOwner`,
`softDeleteAllByUserId` y `deleteFilesByUrls` invocan directamente métodos que no existían antes de
este diff (fallarían con `TypeError: ... is not a function` en HEAD~1); los tests de orquestación
en `account-deletion.service.spec.ts` verifican un `callOrder` de 6 pasos que no existía en la
versión de 5 pasos (fallarían por longitud de array distinta).

## Pruebas manuales

Pendientes, documentadas en detalle en `../REVIEW_CHECKLIST.md` §5 y en `handoffs/qa.md`. Resumen:
verificar contra Postgres/Firebase Storage reales (no solo mocks) con una cuenta QA desechable —
borrado de cascada de vehículos/SOAT/RTM/mantenimientos, limpieza de imágenes, y los 3 casos borde
(documento sin foto, imagen ya borrada del bucket, garage vacío). No ejecutadas en esta corrida por
requerir infraestructura real y una cuenta desechable — riesgo aceptado explícitamente dado que es
una fase 100% backend con cobertura unitaria completa y correcta.
