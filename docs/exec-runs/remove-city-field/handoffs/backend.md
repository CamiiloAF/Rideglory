# Backend handoff — remove-city-field

**Date:** 2026-06-11T22:06:53Z  
**Agent:** Backend (rideglory-api)

---

## Baseline

**Before changes:**
- `events-ms` tests: 5 failed / 26 total — pre-existing failures in TC-1 through TC-5 of `events.service.spec.ts`. TC-1 through TC-3 failed because the service had evolved (state filter changed from `NOT 'DRAFT'` to `notIn ['DRAFT','IN_PROGRESS']`, order changed to `desc`) but tests hadn't been updated. TC-4 and TC-5 were city-specific tests slated for deletion.
- `api-gateway` tests: 98 passed / 98 total — green.

---

## Archivos cambiados

### rideglory-contracts

| File | Change |
|------|--------|
| `rideglory-contracts/src/events/dto/create-event.dto.ts` | Removed `city!: string` field with `@IsString()` decorator |
| `rideglory-contracts/src/events/dto/event-filter.dto.ts` | Removed `city?: string` field with `@IsOptional()` / `@IsString()` decorators from `EventFilterDto` |
| `rideglory-contracts/src/ai/dto/ai-description-event-context.dto.ts` | Removed `city!: string` field with `@IsString()` decorator |

Contracts rebuilt with `npm run build` and reinstalled in `events-ms` and `api-gateway` via `pnpm install`.

### events-ms

| File | Change |
|------|--------|
| `events-ms/prisma/schema.prisma` | Removed `city String` from `Event` model |
| `events-ms/prisma/seed.ts` | Removed `city: 'Bogotá'` from seed create payload |
| `events-ms/prisma/migrations/20260611000000_remove_event_city/migration.sql` | New migration: `ALTER TABLE "Event" DROP COLUMN "city"` |
| `events-ms/src/events/events.service.ts` | Removed `city` from destructuring in `findAll()` and `findUpcoming()`; removed `city` from Prisma `where` clauses in both methods |
| `events-ms/src/events/events.service.spec.ts` | Removed TC-4 (city-only) and TC-5 (combined+city); updated TC-1/TC-2/TC-3 assertions to match actual service behavior (state: `notIn ['DRAFT','IN_PROGRESS']`, orderBy: `desc`, objectContaining for partial matching) |

Migration applied: column dropped directly via `psql` then marked as applied with `npx prisma migrate resolve --applied`. Prisma client regenerated with `npx prisma generate`.

### api-gateway

| File | Change |
|------|--------|
| `api-gateway/src/ai/gemini.service.ts` | Removed `- Ciudad: ${eventContext.city}` line from prompt template; updated system prompt comment removing "ciudad" from the listed context fields |
| `api-gateway/src/ai/gemini.service.spec.ts` | Removed `city: 'Bogotá'` from `validReq.eventContext` mock |
| `api-gateway/src/ai/ai.controller.spec.ts` | Removed `city: 'Medellín'` from `validDto.eventContext` and from validation test DTO |
| `api-gateway/src/ai/ai-description.spec.ts` | Removed all `city: 'Bogotá'` occurrences from `eventContext` objects in Suite A and Suite B mocks |

---

## Pruebas nuevas

No new tests were written — the change is a pure removal. TC-1/TC-2/TC-3 were updated to reflect the current (correct) service behavior that already existed but hadn't been captured. TC-4 and TC-5 were deleted since the feature no longer exists.

---

## Resultado final

| Service | Before | After |
|---------|--------|-------|
| `events-ms` | 5 fail / 26 total | **24 pass / 24 total** |
| `api-gateway` | 98 pass / 98 total | **98 pass / 98 total** |

Guardrails:
- `grep -rn "city" rideglory-contracts/src/events/ rideglory-contracts/src/ai/` → empty ✓
- `grep -rn "city" events-ms/prisma/schema.prisma` → empty ✓
- `npx tsc --noEmit` in both `events-ms` and `api-gateway` → no errors ✓

---

## Verificacion manual

1. `psql events -c '\d "Event"'` — confirm `city` column is absent from the table.
2. `POST /events` without a `city` field — should succeed.
3. `GET /events?city=Medellín` — query param is now silently ignored (no filter applied); no 400 error.
4. `POST /ai/description` with no `city` in `eventContext` — should generate a description without "Ciudad:" line in the Gemini prompt.

---

## Notas Frontend/QA

- The database column has been dropped. Any request body that still sends `city` will not cause a DB error — the field will simply be ignored by Prisma (it's no longer in the model). However, once the Flutter DTO is updated (Frontend phase), `city` will not be sent at all.
- The `EventFilterDto.city` field has been removed from contracts. The api-gateway route that forwards filters to events-ms no longer passes city.
- The Gemini prompt no longer contains "Ciudad:" — the AI will generate descriptions without city context. This is intentional per the PRD.
- Tests rely on the Prisma generated client that was regenerated without the `city` field. If another developer clones and runs without running `prisma generate`, they'll get type errors — they should run `npx prisma generate` in `events-ms`.
