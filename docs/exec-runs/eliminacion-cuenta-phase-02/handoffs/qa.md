# QA handoff — eliminacion-cuenta-phase-02

**Date:** 2026-07-10T19:18:23Z
**Nivel:** normal
**Status:** pass (con hallazgos menores no bloqueantes)

## Contexto

Fase 100% backend (`rideglory-api`): el borrado de cuenta (`DELETE /users/me`, endpoint de fase 1)
ahora también hace hard-delete en cascada de `Vehicle`/`Soat`/`Tecnomecanica` del owner, soft-delete
de `Maintenance` por `userId`, y limpieza best-effort de imágenes en Firebase Storage. En Rideglory
(Flutter) solo cambiaron 4 archivos de documentación (`docs/features/{vehicles,soat,tecnomecanica,
maintenance}.md`) — sin código de app.

## Catálogo — AC (§5 PRD_NORMALIZED.md) → cobertura

| # | AC | Cobertura | Test |
|---|----|-----------|------|
| 1 | `hardDeleteAllByOwner` borra `Vehicle`/`Soat`/`Tecnomecanica` del owner (verificable por query directa a BD) | nuevo (unit, mockeado) | `vehicles-ms/src/vehicles/vehicles.service.spec.ts` — "N vehículos con SOAT/RTM + dedupe de URLs"; **no verificado contra BD real** (ver Gap 1) |
| 2 | `Maintenance` del usuario queda `isDeleted: true` sin loop por `vehicleId` | nuevo (unit) | `maintenances-ms/src/maintenances/maintenances.service.spec.ts` — "M registros soft-deleted" |
| 3 | Imágenes de Storage referenciadas por `Vehicle.imageUrl`/`Soat.documentUrl`/`Tecnomecanica.documentUrl` ya no existen tras el borrado | nuevo (unit, Firebase Admin mockeado) | `api-gateway/src/ai/storage-cleanup.service.spec.ts` — URL formato Firebase SDK, URL formato público; **no verificado contra bucket real** (ver Gap 2) |
| 4 | SOAT/RTM sin foto (`documentUrl: null`) no bloquea el borrado | nuevo (unit) | `storage-cleanup.service.spec.ts` — "filtrado de null/undefined/''" + `vehicles.service.spec.ts` — "filtrado de nulls + dedupe" |
| 5 | Imagen ya borrada/URL corrupta en Storage no produce error 500, no aborta el batch | nuevo (unit) | `storage-cleanup.service.spec.ts` — "fallo individual no aborta el batch (objeto inexistente)", "URL no parseable no lanza" + `account-deletion.service.spec.ts` — "storage cleanup failure does NOT abort the flow" |
| 6 | Garage vacío completa el borrado sin error, arrays vacíos | nuevo (unit) | `vehicles.service.spec.ts` — "garage vacío" (`{deletedVehicleCount:0, imageUrls:[]}` sin abrir `$transaction`) + `account-deletion.service.spec.ts` — "empty garage" |
| 7 | `dart analyze` y `flutter test` en verde (solo docs tocadas) | verificado en esta corrida | ver §Ejecución |
| 8 | Tests unitarios nuevos de `vehicles-ms`, `maintenances-ms`, storage-cleanup pasan en CI de `rideglory-api` | verificado en esta corrida (local, no CI remoto) | ver §Ejecución |

## Matriz de regresión — guardrails (§6 PRD_NORMALIZED.md) → mecanismo

| Guardrail | Mecanismo verificado |
|---|---|
| No `onDelete: Cascade` en Prisma | `git diff` de `rideglory-api` no toca `schema.prisma` en `vehicles-ms` ni `maintenances-ms` (confirmado leyendo `vehicles.service.ts`: borrado explícito `soat.deleteMany` → `tecnomecanica.deleteMany` → `vehicle.deleteMany`) |
| No cambiar convención `storagePath` de subida | Código de `storage-cleanup.service.ts` solo *lee* URLs existentes (`extractStoragePath`), no toca lógica de subida (`ImageStorageService`/`StorageService` intactos) |
| Sin cambios de UI/UX/copy en Flutter | `git diff --stat` (Rideglory) muestra únicamente 4 `docs/features/*.md`; `dart analyze`/`flutter test` no detectan cambios de código de producción |
| Sin anonimización de `EventRegistration` (fase 3) | No aparece en el change map ni en el diff de `account-deletion.service.ts` |
| Sin manejo de reintentos/idempotencia del flujo completo de 5(6) pasos (fase 4) | Confirmado: `account-deletion.service.ts` no tiene retry wrapper; cada paso 2/4 usa `timeout(15s)+catchError→502` puntual, no hay reintento automático |
| Soat→Tecnomecanica→Vehicle en una única transacción Prisma | Leído directo en `vehicles.service.ts:308-312`: `this.$transaction([soat.deleteMany, tecnomecanica.deleteMany, vehicle.deleteMany])`, orden correcto |
| `deleteFilesByUrls` con try/catch individual por archivo, nunca aborta batch | Leído directo en `storage-cleanup.service.ts`: loop `for...of` con `try/catch` dentro, `continue` en URL no parseable, sin `throw` que escape del método |
| Sin endpoints HTTP nuevos en api-gateway | Confirmado: solo `@MessagePattern` (`hardDeleteAllByOwner`, `softDeleteMaintenancesByUserId`); `DELETE /users/me` no cambia firma |
| Suite Flutter existente en verde sin cambios de código | `flutter test` completo: 1386 tests, `All tests passed!` (ver §Ejecución) |

## Ejecución

| Suite | Comando | Resultado |
|---|---|---|
| `vehicles-ms` (`src/vehicles`) | `npx jest src/vehicles` | **50 passed, 50 total** (3 suites) — reproducido en esta corrida |
| `maintenances-ms` (`src/maintenances`) | `npx jest src/maintenances` | **3 passed, 3 total** (1 suite) — reproducido |
| `api-gateway` (`src/ai` + `src/users`) | `npx jest src/ai src/users` | **54 passed, 54 total** (8 suites) — reproducido |
| Rideglory `dart analyze` | `dart analyze` | 0 errores, 15 `info` preexistentes (curly_braces_in_flow_control_structures, no relacionados a esta fase) |
| Rideglory `flutter test` | `flutter test` | **1386/1386 passed**, `All tests passed!` — sin regresiones |

No se corrió `npx jest` completo de `api-gateway` (incluye `src/places/places.service.iter3.spec.ts`,
8 tests rojos preexistentes documentados por Backend, no relacionados a esta fase — confirmado que no
toca ningún archivo del change map).

No se corrió contra base de datos real (Postgres de `vehicles-ms`/`maintenances-ms`) ni bucket real de
Firebase Storage — toda la cobertura nueva es unitaria con Prisma/Firebase Admin mockeados. Esto es
consistente con el resto del repo (mismo patrón que specs vecinos) pero deja un gap real de
verificación end-to-end (ver Gaps).

## Bugs

Ninguno encontrado. Revisión de código línea a línea de `vehicles.service.ts:hardDeleteAllByOwner`,
`maintenances.service.ts:softDeleteAllByUserId`, `storage-cleanup.service.ts:deleteFilesByUrls` y
`account-deletion.service.ts:deleteAccount` confirma que la implementación coincide exactamente con
las decisiones documentadas por el Architect (orden de transacción, try/catch individual, orquestación
de 6 pasos, manejo de garage vacío y URLs nulas).

## Gaps (no bloqueantes para sign-off de esta fase, recomendados para QA manual antes de release)

1. **AC 1, 3, 5, 6 no verificados contra infraestructura real** (Postgres/Firebase Storage reales).
   Toda la cobertura nueva es unitaria con mocks. El propio handoff de Backend lo señala explícitamente
   y recomienda la verificación manual descrita abajo — no se ejecutó en esta corrida porque requiere
   una cuenta QA desechable y acceso a la consola de Firebase Storage/BD de producción, fuera del
   alcance de una corrida de QA automatizada de código.
2. **`account-deletion.service.spec.ts` no cubre explícitamente el caso "SOAT/RTM sin foto
   (`documentUrl: null`) end-to-end junto con vehículos con foto"** en el mismo test — la cobertura de
   nulls vive en `vehicles.service.spec.ts` (filtrado antes de retornar `imageUrls`) y en
   `storage-cleanup.service.spec.ts` (filtrado de la lista recibida), pero no hay un test de integración
   unitaria que encadene ambos. Riesgo bajo: cada pieza está cubierta por separado y el flujo de datos
   entre ellas es trivial (un array pasado tal cual).

## Pruebas manuales (pendientes, requieren entorno real — no ejecutadas en esta corrida)

Usar **solo** cuentas QA dedicadas (`qa1@gmail.com` / `qa2@gmail.com`, password `Test123.`) o una
cuenta QA desechable adicional — hay usuarios reales en producción desde 2026-07-10. El borrado de
cuenta es irreversible.

1. Usuario con N vehículos, cada uno con SOAT y RTM (con foto) y M mantenimientos → `DELETE /users/me`
   → verificar por query directa a Postgres de `vehicles-ms` que no quedan filas de `Vehicle`/`Soat`/
   `Tecnomecanica` con ese `ownerId`/`vehicleId`, y que `Maintenance` en `maintenances-ms` tiene
   `isDeleted: true` para ese `userId`.
2. Verificar en consola de Firebase Storage (o `bucket.file(path).exists()`) que las imágenes de esos
   vehículos y los documentos SOAT/RTM ya no existen.
3. Usuario con SOAT o RTM sin foto (`documentUrl: null`) completa el borrado sin error.
4. Usuario con imagen de vehículo borrada manualmente del bucket antes de eliminar la cuenta (URL
   colgada) completa el borrado sin error 500.
5. Usuario sin ningún vehículo (garage vacío) completa el borrado sin error.
6. Confirmar que la pantalla y el copy de confirmación de eliminación de cuenta no cambiaron
   visualmente respecto a fase 1 (fuera de alcance de código de esta fase, pero es la superficie de
   regresión visible para el usuario).

## Sign-off

**green** — cobertura unitaria completa y correcta para los 8 AC del PRD, guardrails respetados
(verificados por lectura directa de código, no solo por handoff), 0 regresiones en las 4 suites de
`rideglory-api` (107/107 tests) ni en Flutter (1386/1386 tests, `dart analyze` limpio). Los gaps
listados son de verificación end-to-end contra infraestructura real (esperable en una fase 100%
backend con mocks) y quedan como pruebas manuales recomendadas antes de considerar esta fase
completamente cerrada para producción — no son bugs de código y no bloquean el sign-off de esta
corrida de QA.
