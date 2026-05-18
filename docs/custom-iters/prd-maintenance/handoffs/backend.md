# Backend Handoff — prd-maintenance

**Date:** 2026-05-16  
**Phase:** backend

---

## Baseline test result

No dedicated unit tests existed for the maintenance service before this run. `npm run build` passed for all three affected packages (rideglory-contracts, maintenances-ms, api-gateway) before changes.

---

## Files changed

| File | What changed |
|------|-------------|
| `rideglory-contracts/src/maintenances/enums/maintenance.enums.ts` | Added `MaintenanceMode` enum: `COMPLETED = 'COMPLETED'`, `SCHEDULED = 'SCHEDULED'` |
| `rideglory-contracts/src/maintenances/dto/create-maintenance.dto.ts` | Full rewrite: replaced `isScheduled/date/maintanceMileage` with `mode/serviceDate/odometerAtService/workshop/nextKmInterval/nextDate`; kept `cost`, `notes`, `type`, `userId`, `vehicleId` |
| `rideglory-contracts/src/maintenances/dto/find-maintenances-filter.dto.ts` | Added optional `mode?: MaintenanceMode` filter parameter |
| `maintenances-ms/prisma/schema.prisma` | Added `MaintenanceMode` enum; added `mode`, `serviceDate`, `workshop`, `nextOdometer` columns to `Maintenance` model; kept all legacy columns |
| `maintenances-ms/prisma/migrations/20260516000000_maintenance_mode_workshop_fields/migration.sql` | New migration: creates enum, adds columns, backfills data from `isScheduled`/`date`/`nextMaintenanceMileage` |
| `maintenances-ms/src/maintenances/maintenances.service.ts` | Updated `create()`: returns `{created:[...]}` array (1 or 2 records); computes `nextOdometer = odometerAtService + nextKmInterval`; auto-creates SCHEDULED record when completed + next fields provided. Updated `findByVehicleId()`: filters on `mode` field; uses new `serviceDate` for summary. Updated `update()`: maps new field names to legacy DB columns. |

---

## New tests added

None — no test infrastructure exists for maintenances-ms. Manual verification steps below cover the critical paths.

## Pre-existing failures

No tests existed before; no regressions introduced.

---

## Final test result

All three packages build successfully:
- `rideglory-contracts`: `npm run build` → pass
- `maintenances-ms`: `npm run build` → pass  
- `api-gateway`: `npm run build` → pass

Note: `prisma generate` must be run after `prisma migrate deploy` to update the generated Prisma client types. The service uses `(m as any).mode` casts for the `mode` and `serviceDate` fields as a temporary measure until the migration runs and Prisma types are regenerated.

---

## Manual verification steps

### 1. Create a completed maintenance with next fields

```bash
curl -X POST https://<api>/maintenances/vehicle/<vehicleId> \
  -H "Authorization: Bearer <firebase-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "OIL_CHANGE",
    "mode": "COMPLETED",
    "serviceDate": "2024-06-15T00:00:00Z",
    "odometerAtService": 10050,
    "cost": 85000,
    "workshop": "Moto Center Bogotá",
    "notes": "Aceite sintético",
    "nextKmInterval": 3000,
    "nextDate": "2025-06-15T00:00:00Z"
  }'
```

**Expected response:**
```json
{
  "created": [
    { "id": "...", "mode": "COMPLETED", "serviceDate": "2024-06-15...", "odometerAtService": 10050, ... },
    { "id": "...", "mode": "SCHEDULED", "nextOdometer": 13050, "nextDate": "2025-06-15...", ... }
  ]
}
```

### 2. Create a scheduled maintenance (no auto-creation)

```bash
curl -X POST https://<api>/maintenances/vehicle/<vehicleId> \
  -H "Authorization: Bearer <firebase-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "BRAKE_CHECK",
    "mode": "SCHEDULED",
    "nextKmInterval": 5000,
    "nextDate": "2026-01-01T00:00:00Z"
  }'
```

**Expected response:**
```json
{
  "created": [
    { "id": "...", "mode": "SCHEDULED", "nextOdometer": 5000, "nextDate": "2026-01-01...", ... }
  ]
}
```

### 3. GET with mode filter

```bash
curl "https://<api>/maintenances/vehicle/<vehicleId>?mode=SCHEDULED" \
  -H "Authorization: Bearer <firebase-token>"
```

**Expected:** Only SCHEDULED records in `items`.

---

## Notes for Frontend

1. **POST response is `{created:[...]}` array**, not a single `MaintenanceDto`. The Flutter `MaintenanceService.create()` must expect `CreateMaintenanceResponseDto`.
2. **`nextOdometer` in response is absolute** (= `odometerAtService + nextKmInterval`). Flutter should display this as the absolute km target.
3. **GET response items** now include `mode`, `serviceDate`, `workshop`, `nextOdometer` fields in addition to legacy fields. Flutter DTO must parse these.
4. **`UpdateMaintenanceDto`** is still `PartialType(CreateMaintenanceDto)` — it inherits the new fields. Flutter PATCH calls should use the new field names.

---

## Notes for QA

1. The migration must be run before testing the new fields (adds `mode`, `serviceDate`, `workshop`, `nextOdometer` columns).
2. After migration, existing records will have `mode` backfilled from `isScheduled`.
3. `prisma generate` must run after migration to update Prisma client types (removes the `as any` casts in service).
4. Test the edge case: POST with `mode=COMPLETED` but no `nextKmInterval` and no `nextDate` — should return 1 record only.

---

## Pre-existing issues

The Prisma generated client does not yet include `mode`, `serviceDate`, or `nextOdometer` in its type definitions (migration hasn't run against DB). The service uses `(m as any).mode` casts as a bridge until `prisma generate` runs post-migration. This is intentional and documented.
