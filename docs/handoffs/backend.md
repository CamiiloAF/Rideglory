# Backend Handoff — Iteration 2

**Phase:** backend | **Iteration:** 2 | **Status:** DONE  
**Completed:** 2026-05-12T15:25:00Z

---

## Changes Implemented

### 1. Event filter DTO — `rideglory-contracts`

**File:** `rideglory-contracts/src/events/dto/event-filter.dto.ts` (new)

Added three DTOs:
- `EventFilterDto` — optional `type` (EventType enum), `dateFrom` (ISO 8601 string), `dateTo` (ISO 8601 string), `city` (string)
- `FindAllEventsPayloadDto extends EventFilterDto` — payload for `findAllEvents` message pattern
- `FindUpcomingEventsPayloadDto extends EventFilterDto` — payload for `findUpcomingEvents`, with optional `limit`

Exported from `rideglory-contracts/src/events/dto/index.ts`.

### 2. API Gateway — `GET /events` and `GET /events/upcoming` filter passthrough

**File:** `api-gateway/src/events/events.controller.ts`

- Added `@Query()` decorator to `findAll()`: accepts `EventFilterDto`, forwards to events-ms via `send('findAllEvents', filters)`
- Added `@Query()` decorator to `findUpcoming()`: accepts `EventFilterDto`, forwards merged with `{ limit: 5 }` to events-ms via `send('findUpcomingEvents', { ...filters, limit: 5 })`
- All params are optional; missing params pass empty object (backward compatible)

### 3. Events Microservice controller

**File:** `events-ms/src/events/events.controller.ts`

- `findAllEvents` message handler now accepts `@Payload() filters: FindAllEventsPayloadDto` and passes to service
- `findUpcomingEvents` message handler now accepts `@Payload() payload: FindUpcomingEventsPayloadDto`, destructures `{ limit, ...filters }`, passes both to service

### 4. Events Microservice service — Prisma WHERE logic

**File:** `events-ms/src/events/events.service.ts`

`findAll(filters: EventFilterDto = {})`:
- Constructs `startDate` filter combining `gte` (dateFrom) and `lte` (dateTo) in a single object to avoid key collision
- Conditionally spreads `eventType`, `city` (ILIKE via Prisma `contains + insensitive`), and `startDate` filters
- Empty `filters` object produces empty `where: {}` — returns all events (backward compatible)

`findUpcoming(filters: EventFilterDto = {}, limit = 5)`:
- `startDate.gte` uses `dateFrom` if provided, otherwise `new Date()` (current behavior preserved)
- `startDate.lte` conditionally added if `dateTo` is present
- `eventType` and `city` filters applied the same as `findAll`

### 5. `GET /users/:id` — Already Implemented

**File:** `api-gateway/src/users/users.controller.ts`

The endpoint was already present:
```typescript
@Get(':id')
findOne(@Param('id', ParseUUIDPipe) id: string) {
  return this.usersService.send('findOneUser', { id });
}
```
Protected by global `FirebaseAuthGuard` (registered via `APP_GUARD` in `AuthModule`). No changes required.

---

## Unit Tests

**File:** `events-ms/src/events/events.service.spec.ts` (new — 8 tests)

| Test | Description |
|------|-------------|
| TC-1 | No filters — WHERE `{}`, returns all events (backward compat) |
| TC-2 | Type-only filter — WHERE `{ eventType: 'OFF_ROAD' }` |
| TC-3 | Date-range filter — WHERE `{ startDate: { gte, lte } }` combined correctly |
| TC-4 | City-only filter — WHERE `{ city: { contains, mode: 'insensitive' } }` |
| TC-5 | Combined (type + dateFrom + city) — all conditions ANDed |
| TC-6 | `findUpcoming` no filters — `gte` uses current date, `take: 5` |
| TC-7 | `findUpcoming` with type filter — `eventType` in WHERE |
| TC-8 | `findUpcoming` with dateFrom — overrides default `now` as `gte` |

All 8 tests pass.

---

## No ENV Changes

No new environment variables. No Prisma migration required (query-level changes only).

---

## Security

- All event filter endpoints protected by global `FirebaseAuthGuard` (Firebase ID token via `Authorization: Bearer`)
- `GET /users/:id` was already protected by the same global guard
- Filter params validated via class-validator decorators on `EventFilterDto`
- `ParseUUIDPipe` on `/users/:id` prevents injection via malformed IDs

---

## Files Changed

**rideglory-api:**
- `rideglory-contracts/src/events/dto/event-filter.dto.ts` — NEW
- `rideglory-contracts/src/events/dto/index.ts` — export added
- `api-gateway/src/events/events.controller.ts` — Query params on findAll + findUpcoming
- `events-ms/src/events/events.controller.ts` — Payload types on message handlers
- `events-ms/src/events/events.service.ts` — Prisma WHERE filter logic
- `events-ms/src/events/events.service.spec.ts` — NEW (8 unit tests)

---

## Next Phase

Frontend — implement `EventService` Retrofit `@Query` params, `GetUserByIdUseCase`, `RiderProfilePage`, attendee list tap navigation, filter bottom sheet wiring.
