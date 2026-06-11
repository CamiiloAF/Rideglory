# Migration plan — remove_event_city

**Generated:** 2026-06-11T21:49:06Z
**Scope:** events-ms Prisma schema only

---

## Migration to run locally

```bash
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npx prisma migrate dev --name remove_event_city
npx prisma generate
```

### What the migration does

Drops column `city String` from the `Event` table.

```sql
-- Migration: remove_event_city
ALTER TABLE "Event" DROP COLUMN "city";
```

### Pre-conditions

- No real events in production (confirmed — PRD §2, memory `project_no_real_users.md`).
- Migration runs **locally only**; no staging/prod deployment without human approval
  (deploy-workflow rule from memory).

### Post-migration steps

1. `npx prisma generate` — regenerate Prisma client.
2. Update `events-ms/src/generated/prisma/` — **do not commit generated files manually**;
   Prisma CLI handles them.
3. Rebuild contracts (`cd rideglory-contracts && npm run build`) and reinstall in affected
   microservices (`pnpm install`) — mandatory per `project_contracts_rebuild_gotcha.md` memory.

### Affected microservices that must pnpm install after contracts rebuild

| MS | Reason |
|----|--------|
| `events-ms` | Imports `CreateEventDto`, `EventFilterDto` from contracts |
| `api-gateway` | Imports `AiDescriptionEventContextDto` from contracts |

### Guardrail

`grep -rn "city" events-ms/prisma/schema.prisma` must return empty after migration.
