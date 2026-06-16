# REVIEW CHECKLIST — Phase 01: Backend soft-delete e integridad de datos

_Generated: 2026-06-16T21:50:10Z_

Pasos manuales a completar antes de commitear. Todos deben pasar.

---

## Pre-commit (automatizado)

- [ ] `cd rideglory-api/vehicles-ms && npx jest src/vehicles/vehicles.service.spec.ts --no-coverage` — 17/17 pasan
- [ ] `cd rideglory-api/vehicles-ms && npx tsc --noEmit` — 0 errores
- [ ] `cd rideglory-api/api-gateway && npx tsc --noEmit` — 0 errores
- [ ] `dart analyze` — no issues found
- [ ] `flutter test` — exit 0

## Migración SQL

- [ ] Abrir `rideglory-api/vehicles-ms/prisma/migrations/20260616183358_add_soft_delete_to_vehicle/migration.sql` y verificar que contiene ÚNICAMENTE:
  ```sql
  ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false;
  ```
  Sin DROP, RENAME, ALTER COLUMN ni CREATE INDEX adicionales.

## Aplicar migración localmente

- [ ] `cd rideglory-api/vehicles-ms && npx prisma migrate dev` (o `prisma migrate deploy`) contra una DB local.
- [ ] Confirmar en Prisma Studio o psql que la columna `isDeleted` existe con valor `false` en todas las filas existentes.

## Pruebas de integración manual (requieren backend corriendo + DB local migrada)

| # | Pasos | Esperado |
|---|-------|---------|
| M-01 | `DELETE /api/vehicles/my/:vehicleId` con token del owner | 200 `{ message: "Vehicle deleted successfully", status: 200 }` |
| M-02 | `GET /api/vehicles/my` tras el soft-delete | El vehículo eliminado NO aparece en la lista |
| M-03 | Consulta directa `SELECT * FROM "Vehicle" WHERE id='<uuid>'` en psql o Prisma Studio | Fila existe con `isDeleted = true` |
| M-04 | `DELETE /api/vehicles/my/:vehicleId` con token de un usuario distinto al owner | 403 |
| M-05 | `DELETE /api/vehicles/my/<uuid-inexistente>` | 404 |
| M-06 | Soft-delete de vehículo main cuando existe otro activo | Siguiente activo (más reciente por `createdAt`) pasa a `isMainVehicle: true` |
| M-07 | Soft-delete del único vehículo activo | Ningún vehículo queda con `isMainVehicle: true` |
| M-08 | `DELETE /api/vehicles/hard-delete/:id` (endpoint antiguo) | 200; fila eliminada físicamente de la tabla |
| M-09 | Crear un vehículo nuevo cuando el único vehículo previo está archivado o eliminado | Nuevo vehículo se crea con `isMainVehicle: true` |

## Guardrails de regresión a verificar en code review

- [ ] `findByIdOrNull` en `vehicles.service.ts` tiene `where: { id }` únicamente — sin `isDeleted` en el where.
- [ ] `@Delete('my/:vehicleId')` en api-gateway aparece ANTES de `@Get(':id')` y `@Delete('hard-delete/:id')`.
- [ ] `hard-delete/:id` handler en api-gateway no fue modificado.
- [ ] Campo `isDeleted` no aparece en la respuesta JSON de `GET /api/vehicles/my` (verificar con M-02 + inspección de response body).

## Watchlist para fases futuras

- Cuando Fase 4 (Flutter) entre en producción, eliminar el endpoint `DELETE /api/vehicles/hard-delete/:id`.
- Si en el futuro se añaden selects explícitos o DTOs de respuesta en `findByOwnerId`, verificar que `isDeleted` no reaparezca.
