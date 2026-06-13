> Slim handoff — read this before docs/exec-runs/remove-city-field/handoffs/architect.md

# Backend handoff — remove-city-field

**Date:** 2026-06-11T21:49:06Z

## Files to change

| File | Change |
|------|--------|
| `rideglory-contracts/src/events/dto/create-event.dto.ts` | Remove `city!: string` |
| `rideglory-contracts/src/events/dto/event-filter.dto.ts` | Remove `city?: string` |
| `rideglory-contracts/src/ai/dto/ai-description-event-context.dto.ts` | Remove `city!: string` |
| `events-ms/prisma/schema.prisma` | Remove `city String` from Event model |
| `events-ms/src/events/events.service.ts` | Remove `city` from filter destructuring + Prisma where clause in `findAll()` and `findMine()` |
| `api-gateway/src/ai/gemini.service.ts` | Remove line `- Ciudad: ${eventContext.city}` from prompt template |

## Test files to update

| File | Change |
|------|--------|
| `events-ms/src/events/events.service.spec.ts` | Remove TC-4 (city-only) and TC-5 (combined+city) assertions; remove `city:` from mock EventCreateInput objects |
| `api-gateway/src/ai/gemini.service.spec.ts` | Remove `city:` from mock AiDescriptionEventContextDto |
| `api-gateway/src/ai/ai.controller.spec.ts` | Remove `city:` from mock eventContext objects |
| `api-gateway/src/ai/ai-description.spec.ts` | Remove `city:` from mock request DTOs |

## Required command sequence

```bash
# 1. Edit contracts first
cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
npm run build

# 2. Reinstall in affected microservices
cd ../events-ms && pnpm install
cd ../api-gateway && pnpm install

# 3. Run Prisma migration
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npx prisma migrate dev --name remove_event_city
npx prisma generate

# 4. Verify
tsc --noEmit  # or: npm run build / nest build
```

## Guardrail

`grep -rn "city" rideglory-contracts/src/events/ rideglory-contracts/src/ai/` must return empty.
`grep -rn "city" events-ms/prisma/schema.prisma` must return empty.

> Full detail: docs/exec-runs/remove-city-field/handoffs/architect.md
