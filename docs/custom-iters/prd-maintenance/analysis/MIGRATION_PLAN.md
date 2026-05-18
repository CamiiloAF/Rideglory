# Migration Plan — prd-maintenance

**Target:** `maintenances-ms` Prisma schema and PostgreSQL DB

## New migration file

Path: `maintenances-ms/prisma/migrations/<timestamp>_maintenance_mode_workshop_fields/migration.sql`

## SQL

```sql
-- Step 1: Create MaintenanceMode enum type
CREATE TYPE "MaintenanceMode" AS ENUM ('COMPLETED', 'SCHEDULED');

-- Step 2: Add new columns
ALTER TABLE "Maintenance"
  ADD COLUMN IF NOT EXISTS "mode"          "MaintenanceMode" NOT NULL DEFAULT 'COMPLETED',
  ADD COLUMN IF NOT EXISTS "serviceDate"   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "workshop"      TEXT,
  ADD COLUMN IF NOT EXISTS "nextOdometer"  INTEGER;

-- Step 3: Backfill mode from isScheduled
UPDATE "Maintenance"
  SET "mode" = CASE
    WHEN "isScheduled" = true THEN 'SCHEDULED'::"MaintenanceMode"
    ELSE 'COMPLETED'::"MaintenanceMode"
  END;

-- Step 4: Backfill serviceDate from date for completed records
UPDATE "Maintenance"
  SET "serviceDate" = "date"
  WHERE "mode" = 'COMPLETED';

-- Step 5: Backfill nextOdometer from nextMaintenanceMileage
UPDATE "Maintenance"
  SET "nextOdometer" = "nextMaintenanceMileage"
  WHERE "nextMaintenanceMileage" IS NOT NULL;
```

## Prisma schema additions

```prisma
enum MaintenanceMode {
  COMPLETED
  SCHEDULED
}

model Maintenance {
  // ... all existing fields unchanged ...
  mode         MaintenanceMode @default(COMPLETED)
  serviceDate  DateTime?
  workshop     String?
  nextOdometer Int?
}
```

## Columns deliberately NOT dropped

- `isScheduled` — keep for backward compat; remove in future cleanup migration
- `date` — keep; maps to `serviceDate` for new records; old records rely on it
- `maintanceMileage` — keep (typo preserved); maps to `odometerAtService` in TS/Dart layer

## Running the migration

```bash
cd /Users/cami/Developer/Personal/rideglory-api/maintenances-ms
npx prisma migrate dev --name maintenance_mode_workshop_fields
npx prisma generate
```

> Do NOT run against production directly. Use the standard deploy pipeline.
