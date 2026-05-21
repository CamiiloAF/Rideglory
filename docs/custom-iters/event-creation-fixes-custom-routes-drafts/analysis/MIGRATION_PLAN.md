# Prisma Migration Plan — Draft state + Waypoints

Service: `events-ms` (`/Users/cami/Developer/Personal/rideglory-api/events-ms`)
Database: PostgreSQL (via `@prisma/adapter-pg`).

## Scope
Two additive changes to the `Event` model / `EventState` enum:
1. New `DRAFT` value on the `EventState` Postgres enum.
2. New `waypoints` column — `String[]` (Postgres `TEXT[]`), default empty array.

Both are backward-safe: existing rows are unaffected, no backfill, no destructive operations.

## Current state (baseline)
- Only one migration exists: `events-ms/prisma/migrations/0_init/`.
- `0_init/migration.sql` line 11: `CREATE TYPE "EventState" AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'CANCELLED', 'FINISHED');`
- `Event` table has no `waypoints` column.

## Schema delta (`events-ms/prisma/schema.prisma`)

`enum EventState`:
```prisma
enum EventState {
  DRAFT
  SCHEDULED
  IN_PROGRESS
  CANCELLED
  FINISHED
}
```

`model Event` — add one line (suggested position: after `allowedBrands`):
```prisma
  waypoints        String[]            @default([])
```

## Migration file

Create folder: `events-ms/prisma/migrations/<YYYYMMDDHHMMSS>_draft_state_and_waypoints/`
File: `migration.sql`

```sql
-- AlterEnum: add DRAFT to EventState
ALTER TYPE "EventState" ADD VALUE IF NOT EXISTS 'DRAFT';

-- AlterTable: add ordered waypoints array to Event
ALTER TABLE "Event"
  ADD COLUMN "waypoints" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
```

## Why a single migration file is safe

PostgreSQL restriction: a value added to an enum via `ALTER TYPE ... ADD VALUE`
cannot be *used* in the same transaction that added it. Here the second
statement (`ALTER TABLE ... ADD COLUMN`) does **not** reference the `DRAFT`
literal at all — it only adds a `TEXT[]` column. Therefore the two statements
can live in the same migration file without violating that rule.

`IF NOT EXISTS` on the enum value makes the statement idempotent and safe to
re-run. `NOT NULL DEFAULT ARRAY[]::TEXT[]` means existing `Event` rows
immediately get an empty array — no separate backfill step.

Postgres 12+ also allows `ALTER TYPE ... ADD VALUE` inside a transaction
block, so Prisma's transactional migration runner handles this fine.

## Apply procedure

Local / dev:
```bash
cd events-ms
# Author the migration.sql by hand as above (do NOT use `migrate dev` to
# autogenerate — hand-author so the enum/column SQL is explicit and reviewed).
npx prisma migrate deploy        # applies pending migrations
npx prisma generate              # regenerates the client in src/generated/prisma
```

CI / production: `prisma migrate deploy` runs the new migration. No downtime —
both changes are additive (new enum label, new column with default).

## Rollback considerations

- The new column can be dropped (`ALTER TABLE "Event" DROP COLUMN "waypoints";`)
  with no data loss to other columns.
- A Postgres enum value **cannot be removed** once added. This is acceptable —
  leaving an unused `DRAFT` label is harmless if a rollback were ever needed.
  Do not attempt to remove it.

## Verification after apply
```sql
-- enum has DRAFT
SELECT enumlabel FROM pg_enum
  JOIN pg_type ON pg_type.oid = pg_enum.enumtypid
  WHERE pg_type.typname = 'EventState';
-- column exists with array default
SELECT column_name, data_type, column_default
  FROM information_schema.columns
  WHERE table_name = 'Event' AND column_name = 'waypoints';
```
Expected: `EventState` includes `DRAFT`; `waypoints` is `ARRAY` with default `ARRAY[]::text[]`.

## Out of scope
No `Waypoint` table, no indexes on `waypoints`, no FK. A `String[]` column is
sufficient for the MVP (ordered place names, no per-waypoint metadata).
