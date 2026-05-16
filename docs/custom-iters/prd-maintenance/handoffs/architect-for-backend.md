> Slim handoff for /custom-iter prd-maintenance. Full detail in docs/custom-iters/prd-maintenance/handoffs/architect.md (read only if ambiguous).

## Scope

Update `rideglory-api` maintenances-ms and rideglory-contracts to support new `MaintenanceMode` enum, `workshop` field, `serviceDate`/`odometerAtService` fields, `nextKmInterval` input → `nextOdometer` computed output, and auto-creation of a second `SCHEDULED` record when `mode=COMPLETED` + next fields provided.

## Files to modify

| File | What changes |
|------|-------------|
| `rideglory-contracts/src/maintenances/enums/maintenance.enums.ts` | Add `MaintenanceMode` enum: `COMPLETED = 'COMPLETED'`, `SCHEDULED = 'SCHEDULED'` |
| `rideglory-contracts/src/maintenances/dto/create-maintenance.dto.ts` | Replace `isScheduled/date/maintanceMileage` → `mode:MaintenanceMode`, `serviceDate:Date?`, `odometerAtService:number?`, `workshop:string?`, `nextKmInterval:number?`, `nextDate:Date?` (and keep `type`, `notes`, `cost`, `userId`, `vehicleId`) |
| `maintenances-ms/prisma/schema.prisma` | Add `MaintenanceMode` Prisma enum; add `mode`, `serviceDate`, `workshop`, `nextOdometer` columns to `Maintenance` model |
| `maintenances-ms/prisma/migrations/<new>` | Create migration SQL (see below) |
| `maintenances-ms/src/maintenances/maintenances.service.ts` | Update `create()`: compute `nextOdometer = odometerAtService + nextKmInterval`; auto-create second SCHEDULED record; return `{created:[...]}` |
| `maintenances-ms/src/maintenances/maintenances.service.ts` | Update `findByVehicleId()`: filter on `mode` column when provided |
| `api-gateway/src/maintenances/maintenances.controller.ts` | Update `CreateAuthenticatedMaintenanceDto` shape; `POST` return type is passthrough `{created:[...]}` |

## Migration SQL (write as new Prisma migration)

```sql
-- 1. Create enum
CREATE TYPE "MaintenanceMode" AS ENUM ('COMPLETED', 'SCHEDULED');

-- 2. Add new columns
ALTER TABLE "Maintenance"
  ADD COLUMN "mode"          "MaintenanceMode" NOT NULL DEFAULT 'COMPLETED',
  ADD COLUMN "serviceDate"   TIMESTAMP,
  ADD COLUMN "workshop"      TEXT,
  ADD COLUMN "nextOdometer"  INTEGER;

-- 3. Backfill mode from isScheduled
UPDATE "Maintenance"
  SET "mode" = CASE WHEN "isScheduled" = true THEN 'SCHEDULED'::"MaintenanceMode"
                    ELSE 'COMPLETED'::"MaintenanceMode" END;

-- 4. Backfill serviceDate from date for completed records
UPDATE "Maintenance"
  SET "serviceDate" = "date"
  WHERE "mode" = 'COMPLETED';

-- 5. Backfill nextOdometer from nextMaintenanceMileage (already absolute)
UPDATE "Maintenance"
  SET "nextOdometer" = "nextMaintenanceMileage"
  WHERE "nextMaintenanceMileage" IS NOT NULL;
```

## API contract — POST response shape

```typescript
// Return from maintenances.service.create():
{
  created: Maintenance[]  // 1 or 2 records
}
```

Auto-create logic in `create()`:
1. Always create the primary record.
2. If `mode == COMPLETED` AND (`nextKmInterval` OR `nextDate` present):
   - Compute `nextOdometer = odometerAtService + nextKmInterval` (when nextKmInterval present).
   - Create second record: `{ mode: SCHEDULED, vehicleId, userId, type, nextOdometer, nextDate, notes: null }`.
   - Return `{created: [primary, scheduled]}`.
3. Else return `{created: [primary]}`.

## FindMaintenancesFilter update

Add optional `mode?: MaintenanceMode` to `FindMaintenancesFilterDto`. When set, filter by `mode` in `findByVehicleId`.

## Constraints

- Do NOT run migrations on production — write the file only, migration runs via CI/deploy process.
- Use `.toJson()` / class-validator DTOs — no raw `object` spreads with unvalidated fields.
- Keep `isScheduled`, `date`, `maintanceMileage` columns — do NOT drop them (backward compat).

> Full detail: docs/custom-iters/prd-maintenance/handoffs/architect.md
