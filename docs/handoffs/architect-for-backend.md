# Architect → Backend Handoff — Iteration 2

**Iteration:** 2 | **Agent:** backend | **Status:** READY

---

## Changes Required

### 1. GET /events — Add Filter Query Params

File: `events-ms/src/events/events.controller.ts` and api-gateway equivalent

Add optional query params: `type`, `dateFrom`, `dateTo`, `city` (all strings, all optional).
Api-gateway passes them through unchanged to events-ms.

### 2. GET /events/upcoming — Same Params

Same query params as above. Pass through to events-ms.

### 3. Prisma WHERE Logic in `findAllEvents`

Apply conditions only when param is present:

```typescript
where: {
  ...(type    && { eventType: type }),
  ...(city    && { city: { contains: city, mode: 'insensitive' } }),
  ...(dateFrom && { startDate: { gte: new Date(dateFrom) } }),
  ...(dateTo   && { startDate: { lte: new Date(dateTo)   } }),
}
```

All conditions are ANDed (Prisma default).

### 4. GET /users/:id — New Endpoint

Add `@Get(':id')` to `UsersController`. Returns same shape as `GET /users/me`.
Protected by Firebase ID token guard (same as existing endpoints).

```typescript
@Get(':id')
@UseGuards(FirebaseAuthGuard)
async getUserById(@Param('id') id: string): Promise<UserDto> {
  return this.usersService.findById(id);
}
```

`UsersService.findById(id)`: `prisma.user.findUniqueOrThrow({ where: { id } })`.

---

## Unit Tests Required (≥5 for filters)

1. Type-only filter returns only matching event types
2. Date-range-only filter returns events within range
3. City-only filter (case-insensitive)
4. Combined filter (type + dateFrom + city)
5. No filters — returns all events (backward compat)

---

## No Schema Changes

No Prisma migration needed. All new logic is query-level only.
