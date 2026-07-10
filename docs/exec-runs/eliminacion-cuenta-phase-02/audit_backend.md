# Auditoría backend — eliminacion-cuenta-phase-02

_Auditor (Opus). Fecha: 2026-07-10T19:15Z_

## Veredicto: APROBADO (score 92)

Verificado contra AC §5 y guardrails §6 del PRD normalizado. Tests corridos localmente
en verde; tsc limpio en api-gateway.

### AC cumplidos
- AC1: `hardDeleteAllByOwner` borra Vehicle+Soat+Tecnomecanica en un único `$transaction`
  ([Soat, Tecnomecanica, Vehicle], orden correcto). Tests verifican las 3 ops y el `in`.
- AC2: `softDeleteAllByUserId` → `updateMany({userId, isDeleted:false}, {isDeleted:true})`,
  sin loop por vehículo. Idempotente. 3 tests.
- AC3: `deleteFilesByUrls` borra por download URL (2 formatos: Firebase SDK y público). 6 tests.
- AC4: URLs null/'' filtradas antes de procesar. Test explícito.
- AC5: cada archivo en su try/catch; fallo individual loguea y continúa. Test explícito.
- AC6: garage vacío → `{deletedVehicleCount:0, imageUrls:[]}` sin abrir transacción. Test.
- AC7: Flutter solo docs; sin cambios de código.
- AC8: vehicles-ms 50/50, maintenances-ms 3/3, api-gateway src/ai+src/users 54/54 → verde.

### Guardrails respetados
- Sin `onDelete: Cascade`; borrado explícito por `vehicleId IN (...)`.
- Sin cambio de `storagePath`; path derivado de la URL guardada.
- Sin UI/copy Flutter. Sin EventRegistration. Sin endpoints HTTP nuevos (2 RPC + 1 storage).
- Transacción única Soat→Tecno→Vehicle. `deleteFilesByUrls` best-effort no aborta batch.
- Solo archivos del change map (users-ms clean; su pointer es trabajo commiteado de fase 1).

### Contrato de error
`RpcException({message, status: BAD_GATEWAY})` + `timeout(15_000)` en las 2 RPC nuevas;
mapea a HTTP 502 vía `RpcCustomExceptionFilter` global. Shape idéntico al patrón existente
en `vehicles.controller.ts`. El `retryable:true` que menciona el PRD §7 no existe en ningún
punto del codebase real; su omisión es consistente con la convención vigente, no un defecto.

### Observaciones menores (no bloqueantes)
1. Fallo parcial: si `softDeleteMaintenancesByUserId` o `hardDeleteUser` fallan tras haber
   borrado ya vehículos + imágenes, queda estado parcial (identidad viva, dominio borrado).
   Explícitamente diferido a fase 4 (idempotencia/reintentos del endpoint completo). OK.
2. `getStorage(getApps()[0])` asume app Firebase inicializada; reusa patrón preexistente del
   mismo archivo (`cleanupStalePendingCovers`). No es regresión.
3. `deleteFilesByUrls` ya nunca lanza (swallow interno); el try/catch envolvente en
   `account-deletion.service` es redundante pero inofensivo (defensa en profundidad).
4. Preexistente fuera de scope: `places.service.iter3.spec.ts` (8 rojos) — no tocado, correcto.
   Corrección del spec `findByOwnerId` (incluir archivados) bien razonada y respaldada por el
   consumidor Flutter real; corrige test, no comportamiento.

### Sin hallazgos de seguridad
SQL parametrizado (Prisma), sin URLs/secretos hardcodeados (bucket derivado de `bucket.name`),
sin PII expuesta en logs (solo paths/URLs de Storage, ya no-PII tras el borrado).
