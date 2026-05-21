# Backend Handoff

## Baseline test result

`events-ms`: **19 tests passed, 0 failed** (2 suites)  
No other test commands exist at root (`npm test` → "Missing script: test").

## Files changed

### rideglory-contracts (submodule)
- `rideglory-contracts/src/events/enums/event.enums.ts` — added `DRAFT = 'DRAFT'` to `EventState` enum
- `rideglory-contracts/src/events/dto/create-event.dto.ts` — added `waypoints?: string[]` with `@IsOptional @IsArray @IsString({ each: true })` after `allowedBrands`
- `rideglory-contracts/dist/` — rebuilt via `npm run build` (tsc)

### events-ms
- `events-ms/prisma/schema.prisma` — added `DRAFT` to `EventState` enum; added `waypoints String[] @default([])` to `Event` model after `allowedBrands`
- `events-ms/prisma/migrations/20260520220000_draft_state_and_waypoints/migration.sql` — new migration: `ALTER TYPE "EventState" ADD VALUE IF NOT EXISTS 'DRAFT'` + `ALTER TABLE "Event" ADD COLUMN IF NOT EXISTS "waypoints" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[]`
- `events-ms/src/generated/prisma/` — regenerated via `npx prisma generate` (reflects new enum value and column)
- `events-ms/src/events/events.service.ts` — three changes:
  1. `findAll`: added `state: { not: EventState.DRAFT }` to `where`
  2. `findUpcoming`: added `state: { not: EventState.DRAFT }` to `where`
  3. Added `findOneEventForViewer(id, authUserId)` — returns 404 if event is DRAFT and caller is not the owner
  4. Added `publishEvent(id, ownerId)` — validates ownership (403) and DRAFT state (409), then transitions to SCHEDULED
- `events-ms/src/events/events.controller.ts` — added two `@MessagePattern` handlers: `findOneEventForViewer` and `publishEvent`
- `events-ms/src/events/events.service.spec.ts` — updated TC-1 through TC-8 to assert `state: { not: 'DRAFT' }` in all public listing `where` clauses
- `events-ms/src/events/events.service.iter3.spec.ts` — added TC-3-12 through TC-3-18 (7 new tests for `findOneEventForViewer` and `publishEvent`)

### api-gateway
- `api-gateway/src/events/events.controller.ts` — two changes:
  1. Added `PATCH :id/publish` endpoint (auth required via `getAuthenticatedUser`, sends `publishEvent` RPC)
  2. Changed `GET :id` to be auth-aware: resolves user and sends `findOneEventForViewer` RPC instead of `findOneEvent`
  - `PATCH :id/publish` is declared **above** bare `GET :id` for route clarity

## New tests added

7 new unit tests in `events-ms/src/events/events.service.iter3.spec.ts`:

| TC | Method | Scenario |
|----|--------|----------|
| TC-3-12 | `findOneEventForViewer` | SCHEDULED event visible to any viewer |
| TC-3-13 | `findOneEventForViewer` | DRAFT event visible to owner |
| TC-3-14 | `findOneEventForViewer` | DRAFT event throws 404 for non-owner |
| TC-3-15 | `publishEvent` | Owner publishes DRAFT → SCHEDULED |
| TC-3-16 | `publishEvent` | Non-owner throws 403 |
| TC-3-17 | `publishEvent` | Already SCHEDULED throws 409 |
| TC-3-18 | `publishEvent` | IN_PROGRESS throws 409 |

## Final test result

`events-ms`: **26 tests passed, 0 failed** (2 suites)

## Manual verification steps

All examples assume `TOKEN` is a valid Firebase JWT and the API gateway is running at `localhost:3000`.

### Create a draft event
```bash
curl -X POST http://localhost:3000/api/events \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "<owner-uuid>",
    "name": "Rodada Draft",
    "description": "Prueba de borrador",
    "city": "Medellín",
    "startDate": "2026-07-01T08:00:00.000Z",
    "difficulty": "EASY",
    "meetingPoint": "Parque Norte",
    "destination": "Santa Fe de Antioquia",
    "meetingTime": "2026-07-01T07:30:00.000Z",
    "eventType": "TOURISM",
    "allowedBrands": [],
    "waypoints": ["Alto de Minas", "La Pintada"],
    "state": "DRAFT"
  }'
# Expected: 201 with event object, state: "DRAFT"
```

### GET /api/events — draft excluded from public list
```bash
curl http://localhost:3000/api/events \
  -H "Authorization: Bearer $TOKEN"
# Expected: array does NOT include any event with state: "DRAFT"
```

### GET /api/events/my — owner sees own draft
```bash
curl http://localhost:3000/api/events/my \
  -H "Authorization: Bearer $TOKEN"
# Expected: array INCLUDES owner's draft events
```

### GET /api/events/:id — non-owner sees 404 for draft
```bash
curl http://localhost:3000/api/events/<draft-event-uuid> \
  -H "Authorization: Bearer $OTHER_USER_TOKEN"
# Expected: 404
```

### GET /api/events/:id — owner sees 200 for own draft
```bash
curl http://localhost:3000/api/events/<draft-event-uuid> \
  -H "Authorization: Bearer $OWNER_TOKEN"
# Expected: 200 with event object, state: "DRAFT"
```

### PATCH /api/events/:id/publish — owner publishes draft
```bash
curl -X PATCH http://localhost:3000/api/events/<draft-event-uuid>/publish \
  -H "Authorization: Bearer $OWNER_TOKEN"
# Expected: 200 with event object, state: "SCHEDULED"
```

### PATCH /api/events/:id/publish — non-owner gets 403
```bash
curl -X PATCH http://localhost:3000/api/events/<draft-event-uuid>/publish \
  -H "Authorization: Bearer $OTHER_USER_TOKEN"
# Expected: 403
```

### PATCH /api/events/:id/publish — already published gets 409
```bash
curl -X PATCH http://localhost:3000/api/events/<scheduled-event-uuid>/publish \
  -H "Authorization: Bearer $OWNER_TOKEN"
# Expected: 409 with message "Cannot publish: event state is SCHEDULED, expected DRAFT"
```

## Notes for Frontend

### New EventState values
`EventState` now includes `DRAFT` as a valid value. Flutter `EventModel` must add this to its enum (the architect flagged 4 files with non-exhaustive switches that will break compilation).

### CreateEvent with state
Send `"state": "DRAFT"` in the create request body to save as draft. Omit `state` (or send `"state": "SCHEDULED"`) for immediate publish. Both paths go through `POST /api/events`.

### waypoints field
`waypoints` is `String[]` — ordered list of place name strings (up to 9 entries). Present in both create and update DTOs. Returned in event response objects from all endpoints.

### Publish endpoint
- `PATCH /api/events/:id/publish`
- Auth required (standard Firebase JWT header)
- No request body needed
- Response: full event object with `state: "SCHEDULED"`
- Error responses:
  - `404` — event not found (or event is someone else's draft)
  - `403` — caller is not the event owner (`{ message: "Only the event organizer can publish this event" }`)
  - `409` — event is not in DRAFT state (`{ message: "Cannot publish: event state is <state>, expected DRAFT" }`)

### GET /api/events/:id now auth-aware
The single-event endpoint now requires authentication (previously public). The gateway resolves the user from the JWT to check draft visibility. **If the caller is unauthenticated the request will be rejected.** Frontend must ensure the auth token is sent for this endpoint.

### findMyEvents (GET /api/events/my)
Unchanged behaviour — always returns owner's events including drafts.

## Notes for QA

### Database migration
Before testing on any environment, the migration must be applied:
```bash
cd events-ms
npx prisma migrate deploy
npx prisma generate
```
The migration is idempotent (`IF NOT EXISTS` guards on both SQL statements).

### Regression checks
- Tracking start/end still works: `startTracking` requires SCHEDULED state, so a DRAFT event cannot have tracking started (correct — you must publish first).
- Event registrations: owner auto-registration still fires on `create` even for drafts (acceptable per architect decision).
- Reminder cron: `findEventsNeedingReminder` filters by `state: EventState.SCHEDULED` — drafts are already excluded.
- `PATCH /api/events/:id` (update) is still public (no auth guard added). This is pre-existing behaviour and out of scope.

### Key risk: exhaustive switch on EventState in Flutter
The Flutter frontend has 4 files with switch statements on `EventState`. Adding `DRAFT` will cause compilation errors until those switches are updated with a `DRAFT` case. This is a frontend task.

## Pre-existing failures

None. All 19 baseline tests passed before changes.
