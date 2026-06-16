# Backend Handoff — Phase 01: soft-delete de vehículos

**Date:** 2026-06-16T18:35:37Z
**Agent:** Backend

---

## Baseline

Before changes: `vehicles-ms` had 2 test suites, 27 tests — all passing. No pre-existing failures.

---

## Archivos cambiados

### vehicles-ms

| File | Change |
|---|---|
| `prisma/schema.prisma` | Added `isDeleted Boolean @default(false)` after `isArchived` in model `Vehicle` |
| `prisma/migrations/20260616183358_add_soft_delete_to_vehicle/migration.sql` | Created — strictly additive `ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false` |
| `src/vehicles/vehicles.service.ts` | Added `softDeleteVehicle()` method; added `isDeleted: false, isArchived: false` filters to `findByOwnerId`, `findMainVehicleByOwnerId`; fixed `create()` count query bug; `findByIdOrNull` left unfiltered (historical access) |
| `src/vehicles/vehicles.controller.ts` | Added `@MessagePattern('softDeleteVehicle')` handler |
| `src/vehicles/vehicles.service.spec.ts` | **CREATED** — 16 new unit tests covering all guardrails |
| `src/generated/prisma/` | Regenerated Prisma client (`npx prisma generate`) to pick up new `isDeleted` field |

### api-gateway

| File | Change |
|---|---|
| `src/vehicles/vehicles.controller.ts` | Added `@Delete('my/:vehicleId')` endpoint before `@Get(':id')`; orchestrates `softDeleteMaintenancesByVehicleId` (timeout 15s) then `softDeleteVehicle`; ownership from Firebase token via `getAuthenticatedUser` |

---

## Pruebas nuevas

`vehicles-ms/src/vehicles/vehicles.service.spec.ts` — 16 tests:

**softDeleteVehicle:**
- Returns 403 when ownerId does not match
- Returns 404 when vehicleId is not found
- Promotes next active vehicle as main when deleted vehicle was main
- Does NOT promote a new main when deleted vehicle was not main
- Does not set any main vehicle when no active vehicles remain after deletion

**findByOwnerId:**
- Excludes vehicles where isDeleted is true
- Excludes vehicles where isArchived is true
- Returns empty array when all vehicles are deleted or archived

**findMainVehicleByOwnerId:**
- Returns the main vehicle when it is active
- Returns undefined when main vehicle is deleted
- Returns undefined when main vehicle is archived

**findByIdOrNull:**
- Returns a vehicle even when isDeleted is true (historical access)
- Returns undefined when vehicle id does not exist

**create() isMainVehicle logic:**
- Marks new vehicle as isMainVehicle: true when owner has no active vehicles
- Marks new vehicle as isMainVehicle: true when prior vehicles are all archived/deleted
- Marks new vehicle as isMainVehicle: false when owner already has active vehicles

---

## Resultado final

```
Test Suites: 3 passed, 3 total
Tests:       43 passed, 43 total (27 baseline + 16 new)
TypeScript:  0 errors (vehicles-ms, api-gateway)
```

---

## Verificacion manual

1. Run `prisma migrate deploy` (or `prisma migrate dev`) against a local DB to apply the `isDeleted` column.
2. `DELETE /api/vehicles/my/:vehicleId` — expects 200 `{ message: 'Vehicle deleted successfully' }`.
3. After delete, `GET /api/vehicles/my` must NOT return the deleted vehicle.
4. If deleted vehicle was main, another active vehicle should be promoted to main.
5. Hard-delete endpoint (`DELETE /api/vehicles/hard-delete/:id`) is unchanged.

---

## Notas Frontend/QA

- Flutter: call `DELETE /api/vehicles/my/{vehicleId}` (not the old hard-delete endpoint).
- No new JWT claims or headers needed — ownership derived from Firebase token.
- `maintenances-ms` `softDeleteMaintenancesByVehicleId` already existed and is called transparently before the vehicle soft-delete.
- The deleted vehicle will still be accessible via internal `getVehicleById` (MessagePattern) for events-ms historical snapshots — `findByIdOrNull` is intentionally unfiltered.
- `isDeleted` column has `DEFAULT false`, so migration is non-breaking for existing rows.
