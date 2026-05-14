# Backend handoff (rideglory-api) — Iteration 2

**Date:** 2026-05-14
**Status:** done

## Endpoints delivered

| Endpoint | Method | Service | Status | Notes |
|----------|--------|---------|--------|-------|
| `/api/vehicles/:vehicleId/soat` | POST | api-gateway → vehicles-ms | done | Upsert (create or update SOAT for vehicle) |
| `/api/vehicles/:vehicleId/soat` | GET | api-gateway → vehicles-ms | done | Returns SOAT or null |
| `/api/notifications/fcm-token` | POST | api-gateway → users-ms | done | Registers FCM token; returns 204 |
| `/api/notifications` | GET | api-gateway (Prisma) | done | Cursor-paginated; `?cursor=<lastId>&limit=20` |
| `/api/notifications/:id/read` | PATCH | api-gateway (Prisma) | done | Sets isRead=true; 403 if not owner |
| `/api/notifications/read-all` | PATCH | api-gateway (Prisma) | done | Marks all unread for user |

## FCM triggers (no new HTTP endpoint)

| Trigger | Location | Notification Type |
|---------|----------|-------------------|
| New registration created | RegistrationsController.create | `NEW_REGISTRATION` to organizer |
| Registration approved | RegistrationsController.approve | `REGISTRATION_APPROVED` to registrant |
| Registration rejected | RegistrationsController.reject | `REGISTRATION_REJECTED` to registrant |

## SOAT cron reminders

| Cron | Timezone | Type |
|------|----------|------|
| Daily 09:00 (Bogota) | America/Bogota | `SOAT_30D` |
| Daily 09:00 (Bogota) | America/Bogota | `SOAT_7D` |
| Daily 09:00 (Bogota) | America/Bogota | `SOAT_DAY_OF` |

Each cron: (1) fetches SOATs expiring in N days from vehicles-ms, (2) inserts a Notification row, (3) sends FCM if token exists.

## Validation and security

- Firebase ID token verified: confirmed (all endpoints via APP_GUARD FirebaseAuthGuard)
- Input validation: class-validator DTOs (`CreateSoatDto`, `RegisterFcmTokenDto`)
- Sensitive fields excluded: `fcmToken` never returned in notification responses
- FCM payloads: scalar IDs only (`eventId`, `registrationId`, `vehicleId`, `vehicleName`) per ADR-5

## Database changes

### users-ms
- Migration: `20260514221319_add_fcm_token_to_user`
- Added: `fcmToken String?` on `User`

### vehicles-ms
- Migration: `20260514221620_add_soat_model`
- New model: `Soat` (id, vehicleId unique, policyNumber, startDate, expiryDate, insurer, documentUrl?, createdAt, updatedAt)

### api-gateway (first-time Prisma)
- Migration: `20260514221506_init_notifications`
- New model: `Notification` (id, userId, type, payload JSON, isRead, createdAt); index on `[userId, createdAt]`
- Docker: `api-gateway/docker-compose.yml` — `gateway-db` on port 5434

## Test results

- Unit (api-gateway): 19 pass / 19 total
- Unit (vehicles-ms): 9 pass / 9 total
- How to run:
  ```
  cd rideglory-api/api-gateway && npx jest
  cd rideglory-api/vehicles-ms && npx jest
  ```

## Environment variables (see .env.example in rideglory-api/api-gateway)

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection for api-gateway Notifications table. Port 5434. |

## Seed files

| Location | Purpose |
|----------|---------|
| `vehicles-ms/prisma/seed.ts` | Creates 2 test vehicles for a seed user |
| `events-ms/prisma/seed.ts` | Creates 1 scheduled event + 1 pending registration |

Run: `SEED_USER_ID=<real-user-uuid> npx ts-node prisma/seed.ts` inside each microservice.

## Known gaps

- **Cron deduplication**: Fire-and-forget; duplicate notifications possible if cron overlaps. Acceptable for MVP.
- **FCM failure**: Sends are fire-and-forget with `catch` logging. No retry. Production should use Admin SDK batch retries.
- **findSoatsExpiringIn window**: UTC-day-aligned. Colombia UTC-5 offset means 09:00 Bogota = 14:00 UTC. No adjustment needed for same-day comparisons.

## Next agent needs to know

- **Flutter dev (frontend)**: All 6 endpoints live. Response shapes:
  - SOAT: `{ id, vehicleId, policyNumber, startDate, expiryDate, insurer, documentUrl?, createdAt, updatedAt }`
  - Notifications list: `{ data: Notification[], nextCursor: string | null }`
  - Notification row: `{ id, userId, type, payload: object, isRead, createdAt }`
  - POST /fcm-token and PATCH endpoints: 204 No Content
- **QA**: Start all 5 DBs + 5 services locally. FCM testing requires a real device with the app installed and Firebase credentials configured.
- **DevOps**: New: `DATABASE_URL` in api-gateway only. Add to CI/CD secrets if running integration tests.
- **Tech lead**: RegistrationsController.approve/reject now return the full registration object. FCM triggers are async with `.catch()` — cannot cause HTTP 5xx.

## Change log

- 2026-05-14: Iteration 2 backend complete. SOAT, FCM notifications, cron scheduler, first-time api-gateway Prisma.
