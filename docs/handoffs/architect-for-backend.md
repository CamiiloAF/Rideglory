> Slim handoff — read this before docs/handoffs/architect.md

# Architect → Backend (NestJS) — Iteration 2

Backend at `/Users/cami/Developer/Personal/rideglory-api`. All endpoints require Firebase Auth Bearer token (existing guard). Error shape `{ message, statusCode, error }`.

## Pre-flight first (T-2-2 — blocks everything)

- `prisma migrate reset` on the 4 existing microservices: vehicles-ms, events-ms, users-ms, maintenances-ms.
- `seed.ts` in vehicles-ms (2+ vehicles) and events-ms (1 scheduled event + 1 registration).
- **api-gateway: FIRST-TIME Prisma.** No `prisma/` dir exists (confirmed). `npx prisma init`, configure `DATABASE_URL` in `.env` (match Docker Compose Postgres), write `schema.prisma` with the `Notification` model, then `npx prisma migrate dev --name init_notifications`. This is NOT `migrate reset`.
- Verify `GET /api/vehicles` → 200 and `GET /api/notifications` → 200 empty `{ data: [], nextCursor: null }` before feature code.

## Implementation order

T-2-4 (fcm-token) → T-2-5 (notifications table + endpoints) → T-2-3 (SOAT) → T-2-6 (FCM triggers) → T-2-7 (cron).

## Prisma models

**users-ms `User`** — add `fcmToken String?`. Migration.

**vehicles-ms `Soat`** (new) — one-to-one with `Vehicle`:
```
model Soat {
  id           String   @id @default(uuid())
  vehicleId    String   @unique
  policyNumber String
  startDate    DateTime
  expiryDate   DateTime
  insurer      String
  documentUrl  String?
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
}
```
Do NOT add a computed `status` — the 4-state badge is client-side.

**api-gateway `Notification`** (new schema):
```
model Notification {
  id        String   @id @default(uuid())
  userId    String
  type      String
  payload   Json
  isRead    Boolean  @default(false)
  createdAt DateTime @default(now())
  @@index([userId, createdAt])
}
```

## Endpoints

| Method | Path | Body | Success | Notes |
|--------|------|------|---------|-------|
| POST | `/api/vehicles/:vehicleId/soat` | `{ policyNumber, startDate, expiryDate, insurer, documentUrl? }` | `SoatResponse` 201 | 400 invalid dates, 403 not owner, 404 vehicle |
| GET | `/api/vehicles/:vehicleId/soat` | — | `SoatResponse` or 204 | api-gateway proxies to vehicles-ms |
| POST | `/api/notifications/fcm-token` | `{ fcmToken: string }` | 204 | updates `fcmToken` on users-ms `User`; called post-login |
| GET | `/api/notifications?cursor=<lastId>&limit=20` | — | `{ data: Notification[], nextCursor: string\|null }` | ordered `createdAt desc`; **cursor pagination only — no offset/limit** |
| PATCH | `/api/notifications/:id/read` | — | 204 | sets `isRead=true`; 403 if not owner |
| PATCH | `/api/notifications/read-all` | — | 204 | all unread for the user |

`SoatResponse`: `{ id, vehicleId, policyNumber, startDate, expiryDate, insurer, documentUrl?, createdAt, updatedAt }`.

## New module: `api-gateway/src/notifications/`

`NotificationsModule` (controller + service) — owns the `notifications` table, the 4 endpoints, FCM dispatch via `firebase-admin` (already installed, no new package). Register in `api-gateway/src/app.module.ts`. SOAT routes added to the existing `api-gateway/src/vehicles/` controller (proxy) + `vehicles-ms/src/vehicles/`.

## FCM push triggers (T-2-6) — no new HTTP endpoint

In the events-ms registration approve / reject / create flow, at the api-gateway proxy layer: after the action succeeds, (1) insert a `Notification` row, (2) send FCM multicast to the target user's `fcmToken`. Payload carries scalar IDs only: `{ eventId, registrationId }` — never nested objects (ADR-5). `type`: `NEW_REGISTRATION` (to organizer), `REGISTRATION_APPROVED`, `REGISTRATION_REJECTED`.

## Cron scheduler (T-2-7)

`npm install @nestjs/schedule`. Add `ScheduleModule.forRoot()` to api-gateway `AppModule`. `NotificationSchedulerService` with `@Cron` jobs for SOAT expiry at 30d / 7d / day-of. **All cron expressions use `America/Bogota` timezone.** Each fired reminder inserts a `Notification` row (`type`: `SOAT_30D` / `SOAT_7D` / `SOAT_DAY_OF`, payload `{ vehicleId, vehicleName }`) and sends FCM.

## Env vars

`DATABASE_URL` in api-gateway `.env` — must match Docker Compose Postgres.

> Full detail: docs/handoffs/architect.md
