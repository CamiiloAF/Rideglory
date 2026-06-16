# Migration Plan — Phase 01: Backend soft-delete e integridad de datos

_Generated: 2026-06-16T18:29:16Z_

---

## Scope

Single additive migration to `vehicles-ms` Prisma schema.

## Migration name

```
<timestamp>_add_soft_delete_to_vehicle
```

(Run `prisma migrate dev --name add_soft_delete_to_vehicle` locally to generate the timestamp.)

## Expected SQL (strictly additive)

```sql
-- AlterTable
ALTER TABLE "Vehicle" ADD COLUMN "isDeleted" BOOLEAN NOT NULL DEFAULT false;
```

**Guardrail:** The generated SQL MUST contain only this `ALTER TABLE ... ADD COLUMN` statement.
Reject any migration that contains `DROP`, `RENAME`, `ALTER COLUMN`, or `CREATE INDEX` beyond this.

## Schema delta

Add to `model Vehicle` in `vehicles-ms/prisma/schema.prisma`:

```prisma
isDeleted  Boolean  @default(false)
```

Placement: directly after the existing `isArchived` field for readability.

## Execution protocol

1. Run locally: `prisma migrate dev --name add_soft_delete_to_vehicle` inside `vehicles-ms/`.
2. Inspect the generated `migration.sql` — verify it contains only the `ADD COLUMN` line above.
3. Confirm with human before any remote deployment.
4. No `prisma migrate reset` required — this is an additive change on an existing migration history.

## Impact on existing data

All existing `Vehicle` rows will have `isDeleted = false` (via `DEFAULT false`). No data migration needed.

## No migration needed in other microservices

- `maintenances-ms`: `isDeleted` column already exists on `Maintenance` table (confirmed in service code).
- `api-gateway`: no `Vehicle` table here.
