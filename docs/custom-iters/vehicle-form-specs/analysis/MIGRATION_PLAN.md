# Migration Plan — vehicle-form-specs

## Database: PostgreSQL via Prisma (vehicles-ms)

### Schema changes
File: `rideglory-api/vehicles-ms/prisma/schema.prisma`

Add 4 nullable String? columns to the Vehicle model:
```prisma
engine       String?
horsepower   String?
torque       String?
weight       String?
```

### Migration generation
```bash
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
npx prisma migrate dev --name add_vehicle_specs
```

This generates: `prisma/migrations/<timestamp>_add_vehicle_specs/migration.sql`

### Expected SQL
```sql
-- AlterTable
ALTER TABLE "Vehicle" ADD COLUMN "engine" TEXT;
ALTER TABLE "Vehicle" ADD COLUMN "horsepower" TEXT;
ALTER TABLE "Vehicle" ADD COLUMN "torque" TEXT;
ALTER TABLE "Vehicle" ADD COLUMN "weight" TEXT;
```

### Safety
- All 4 columns are nullable with no default → zero-impact on existing rows
- No backfill needed
- No destructive operations (no DROP, no ALTER TYPE)
- Fully reversible: `ALTER TABLE "Vehicle" DROP COLUMN "engine"` etc.

### Post-migration
Regenerate the Prisma client:
```bash
npx prisma generate
```
(This is usually done automatically by `migrate dev`, but confirm by checking `src/generated/prisma/index.d.ts` includes the new fields.)
