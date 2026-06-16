# Auditoría Backend — Phase 01: soft-delete de vehículos

**Date:** 2026-06-16T18:38:25Z
**Auditor:** Opus
**Veredicto:** APROBADO con un cambio solicitado (no bloqueante para el implementador en esta fase; el humano commitea).

---

## Verificación de AC

| AC | Estado | Evidencia |
|----|--------|-----------|
| 1 `GET /my` excluye isDeleted/isArchived | ✓ | `findByOwnerId` where `{ ownerId, isDeleted:false, isArchived:false }` |
| 2 DELETE soft (no borra fila) 200 | ✓ | `softDeleteVehicle` hace `update isDeleted:true`; gateway retorna `{message,status:200}` |
| 3 403 owner distinto | ✓ | service `existing.ownerId !== ownerId` → RpcException FORBIDDEN; gateway `status: error?.status ?? NOT_FOUND` preserva 403 |
| 4 404 UUID inexistente | ✓ | `!existing` → RpcException NOT_FOUND; además ParseUUIDPipe en gateway |
| 5 promoción de main canónica | ✓ | `findFirst({where:{ownerId,isArchived:false,isDeleted:false},orderBy:{createdAt:'desc'}})` dentro de $transaction |
| 6 no main → no cambia nada | ✓ | promoción guardada tras `if (existing.isMainVehicle)` |
| 7 findByIdOrNull sin filtro | ✓ | `findUnique({where:{id}})` intacto (línea 173-177) |
| 8 create() cuenta solo activos | ✓ | count where `{isArchived:false,isDeleted:false}`; `isMainVehicle: existingCount===0` |
| 9 findMainVehicleByOwnerId filtra | ✓ | where añade `isDeleted:false, isArchived:false` |
| 10 migración aditiva | ✓ | `ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false;` (sin DROP/RENAME) |
| 11 dart analyze/flutter test | n/a | sin cambios Flutter (árbol Flutter limpio) |
| 12 TS compila | ✓ | `tsc --noEmit` exit 0 en vehicles-ms y api-gateway |

## Guardrails de regresión

- findByIdOrNull sin `isDeleted` → OK.
- Ownership check antes de la transacción → OK.
- Orden de rutas gateway: `my/:vehicleId`@103 < `:id`@140 < `hard-delete/:id`@169 → OK.
- `hard-delete/:id` intacto → OK.
- Migración no destructiva → OK.
- `isDeleted` no se expone (no DTO nuevo; respuesta sin el campo en select implícito de gateway) → OK.
- Criterio de promoción canónico → OK.

## Seguridad / Clean Arch

- Prisma parametrizado, sin SQL concatenado, sin secretos/URLs/PII.
- $transaction garantiza atomicidad delete+promoción.
- Patrón gateway HTTP→RpcException idéntico al `hardDelete` existente (consistente).
- Scope limpio: vehicles-ms (4 archivos del map + migración + spec), api-gateway (1 archivo). notifications-ms NO fue tocado por este agente (working tree vacío; el `M` en super-repo es puntero pre-existente).

## Hallazgo principal (cambio solicitado)

`vehicles-ms/src/vehicles/vehicles.service.spec.ts` NO prueba el `VehiclesService` real. Reimplementa la lógica como helpers locales (`simulateSoftDelete`, `simulateFindByOwnerId`, etc.) y asevera sobre esa simulación. Los 16 tests pasarían igual si `vehicles.service.ts` regresara (p.ej. si se quitara el filtro `isDeleted` o el ownership check), porque el código de producción nunca se importa ni se invoca. Incumple parcialmente "pruebas que fallarían sin el cambio".

Implementación de producción correcta y los AC cubiertos; por eso APRUEBO. El cambio solicitado es endurecer la prueba: instanciar `VehiclesService` con `this.vehicle`/`$transaction` mockeados (jest mocks de Prisma) y aseverar contra el `where` real pasado a Prisma, de modo que un cambio en el filtro/ownership/promoción rompa el test.

## Resultado de suite

```
vehicles-ms: 3 suites / 43 tests passed; tsc 0 errores
api-gateway: tsc 0 errores
```
