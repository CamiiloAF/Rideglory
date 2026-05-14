> Slim handoff — read this before docs/handoffs/architect.md

# Architect → Backend (NestJS) — Iteration 1

**Status: NO rideglory-api changes required this iteration.**

## Why

Iteration 1 is a pure UI/UX redesign pass on 15 existing Flutter screens. Per PO scope and the existing-system scan:

- No new endpoints requested by any of the 11 user stories (US-1-1 … US-1-11).
- No DTO contract evolves — the redesign uses existing models as-is.
- No Prisma schema changes, no migrations, no seed data updates.
- No new env vars on the backend.
- No new microservice; no api-gateway proxy edits.

All API contracts already documented in `docs/handoffs/planning/00-existing-system-scan.md` §3 remain frozen for iter-1.

## What backend agent does this iteration

**Nothing.** Stand down. Resume in iteration 2 (SOAT + Notifications):
- New endpoints in vehicles-ms (`POST /api/vehicles/:vehicleId/soat`, `GET /api/vehicles/:vehicleId/soat`)
- New endpoints in api-gateway (`POST /api/notifications/fcm-token`, `GET /api/notifications`, `PATCH /api/notifications/:id/read`, `PATCH /api/notifications/read-all`)
- First-time Prisma setup in api-gateway (`prisma init` + `prisma migrate dev`, NOT reset)
- `notifications` table in api-gateway
- `fcmToken String?` field added to `User` in users-ms
- `@nestjs/schedule` SOAT cron jobs (America/Bogota timezone)
- Pre-flight: `seed.ts` in vehicles-ms and events-ms; `prisma migrate reset` on the 4 existing microservices

## What backend agent must NOT do this iteration

- Pre-implement iter-2 SOAT endpoints "to get a head start" → would invalidate the iter-1 frozen-contract guarantee that the frontend redesign relies on.
- Touch any DTO referenced by Flutter (`EventDto`, `VehicleDto`, `UserDto`, `RegistrationDto`, etc.) — even a non-functional rename breaks the frontend redesign PRs.
- Run any `prisma migrate` command in any microservice (data state must not drift while frontend smoke tests run).

## Coordination signal

If frontend hits a redesign blocker that surfaces a missing field in an existing DTO (e.g., a card needs a value the API never returned), STOP and escalate to PO. The iter-1 plan explicitly states "no new domain models" — a workaround is not a pre-iter-2 ticket.

> Full detail: docs/handoffs/architect.md
