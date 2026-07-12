# QA-auto — Auditoría Opus — eliminacion-cuenta-phase-02

**Fecha:** 2026-07-11T15:12:57Z
**Rol:** Auditor de calidad (caza-falso-verde)
**Veredicto:** `solid` — ningún test vacío; la re-corrida reproduce el verde.

## Re-corrida (verde reproducible)

| Suite | Resultado |
|-------|-----------|
| Flutter `delete_account_confirmation_page_test.dart` + `delete_account_cubit_test.dart` | 7/7 pasan |
| `vehicles-ms` `npx jest src/vehicles` | 50/50 (3 suites) |
| `maintenances-ms` `npx jest src/maintenances` | 3/3 (1 suite) |
| `api-gateway` `npx jest src/ai src/users` | 58/58 (8 suites) |

## Verificación por caso

- **1.1 / 5.1** — Los 4 widget tests assertan copy y estructura reales de la pantalla (switch → habilita botón, string exacto "Entiendo que esta acción es irreversible", banner de error con texto literal, botón "Reintentar"). Fallarían si el copy o los botones cambiaran. No vacío.
- **5.2** — `deleteAccount` guard de doble-tap: `verify(mockUseCase).called(1)` con dos invocaciones concurrentes; y el widget test verifica `onPressed == null` sin switch activo. Ambos ligan el assert a "sin confirmación no se dispara borrado → cuenta intacta". No vacío.
- **6A.1** — Estado `ResultState.error(DomainException)` → assert de banner con mensaje literal + botón "Reintentar". Ejerce el render de error real, no tautológico. No vacío.
- **6B.1** — `hardDeleteAllByOwner` filtra nulls y dedupea: assert `imageUrls === ['https://img/shared.jpg']` (una URL compartida entre vehicle y soat, tecno null). `deleteFilesByUrls` filtra `[null, undefined, '']`: assert `file()` llamado 1 vez. No vacío.
- **7.1** — `hardDeleteAllByOwner`: asserts explícitos de `soat.deleteMany`, `tecnomecanica.deleteMany`, `vehicle.deleteMany` con el where correcto, dentro de un único `$transaction` con array de 3 ops. Solo Prisma mockeado (frontera correcta). No vacío.
- **7.2** — `softDeleteAllByUserId`: assert `updateMany({ where:{userId,isDeleted:false}, data:{isDeleted:true} })` + idempotencia (segunda corrida count:0). Soft delete real. No vacío.
- **7.4** — Fallo individual no aborta batch: `delete` que rechaza + `delete` que resuelve; assert de que ambos se llamaron y `resolves.toBeUndefined()` (sin excepción propagada). El log WARN "failed to delete file ... object not found" aparece en stdout de la corrida, confirmando el warn esperado. No vacío.
- **7.5** — Garage vacío: assert `{ deletedVehicleCount:0, imageUrls:[] }` + `$transaction` NO llamado + `soat/tecnomecanica.findMany` NO llamados. No vacío.
- **7.6** — n/a (verificación por comando: diff de schema.prisma + grep onDelete). No es test; fuera del alcance de vacuidad.
- **7.7** — Contrato `DELETE /users/me`: `users.controller.ts` confirma `@Delete('me')` + `@HttpCode(HttpStatus.NO_CONTENT)`, sin `@MessagePattern` ni endpoints HTTP nuevos en el controller; la suite `src/users` (incluye `account-deletion.service.spec.ts`) pasa. Contrato público intacto. No vacío.

## Observaciones no bloqueantes

- 7.4: el test no assertea el texto del WARN de forma programática (solo verifica que el batch continúa y no lanza). El comportamiento esperado central — "sin error 500 propagado ni excepción sin capturar" — sí está assertado. Cobertura suficiente; el log es evidencia adicional en stdout.
- 6B.1: no existe un test de integración que encadene ambos módulos (vehicles-ms → storage-cleanup) en un mismo spec; ambos casos se cubren por separado. Gap ya documentado por Backend/QA, riesgo bajo (el dato que cruza es un array pasado tal cual). No bloqueante.
