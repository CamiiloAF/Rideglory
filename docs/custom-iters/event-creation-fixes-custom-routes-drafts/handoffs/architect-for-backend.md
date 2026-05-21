# Architect → Backend

Repo: `/Users/cami/Developer/Personal/rideglory-api`. Touch ONLY the files below.

## 1. Contracts (`rideglory-contracts` — git submodule)

`src/events/enums/event.enums.ts` — add `DRAFT` to `EventState`:
```ts
export enum EventState {
  DRAFT = 'DRAFT',
  SCHEDULED = 'SCHEDULED',
  IN_PROGRESS = 'IN_PROGRESS',
  CANCELLED = 'CANCELLED',
  FINISHED = 'FINISHED',
}
```

`src/events/dto/create-event.dto.ts` — add optional `waypoints` after `allowedBrands`:
```ts
@IsOptional()
@IsArray()
@IsString({ each: true })
waypoints?: string[];
```
`UpdateEventDto` inherits via `PartialType` — no change. `state` stays as-is (already `@IsOptional @IsEnum`, default `SCHEDULED`).

After editing: run `npm run build` inside `rideglory-contracts` so `dist/` is regenerated.

## 2. Prisma (`events-ms/prisma/schema.prisma`)

In `enum EventState` add `DRAFT`. In `model Event` add:
```prisma
waypoints        String[]            @default([])
```
Then hand-author the migration — see `analysis/MIGRATION_PLAN.md` for the exact SQL and folder layout. Regenerate the Prisma client (`prisma generate`).

## 3. `events-ms/src/events/events.service.ts`

**`findAll`** — add draft exclusion to the `where`:
```ts
where: {
  state: { not: EventState.DRAFT },
  ...(type && { eventType: type }),
  ...(city && { city: { contains: city, mode: 'insensitive' } }),
  ...(startDateFilter && { startDate: startDateFilter }),
},
```

**`findUpcoming`** — same: add `state: { not: EventState.DRAFT }` to the `where`.

**`findByOwnerId`** — leave unchanged (owner must see own drafts).

**New `findOneEventForViewer(id, authUserId)`** — do NOT modify the existing `findOne`:
```ts
async findOneEventForViewer(id: string, authUserId: string) {
  const event = await this.findOne(id); // reuses 404
  if (event.state === EventState.DRAFT && event.ownerId !== authUserId) {
    throw new RpcException({
      status: HttpStatus.NOT_FOUND,
      message: `Event with id ${id} not found`,
    });
  }
  return event;
}
```
(404, not 403 — does not leak draft existence.)

**New `publishEvent(id, ownerId)`:**
```ts
async publishEvent(id: string, ownerId: string) {
  const event = await this.findOne(id);
  if (event.ownerId !== ownerId) {
    throw new RpcException({ status: HttpStatus.FORBIDDEN,
      message: 'Only the event organizer can publish this event' });
  }
  if (event.state !== EventState.DRAFT) {
    throw new RpcException({ status: HttpStatus.CONFLICT,
      message: `Cannot publish: event state is ${event.state}, expected DRAFT` });
  }
  return this.event.update({
    where: { id },
    data: { state: EventState.SCHEDULED },
  });
}
```

## 4. `events-ms/src/events/events.controller.ts`

Add two message patterns:
```ts
@MessagePattern('publishEvent')
publishEvent(@Payload() payload: { id: string; ownerId: string }) {
  return this.eventsService.publishEvent(payload.id, payload.ownerId);
}

@MessagePattern('findOneEventForViewer')
findOneForViewer(@Payload() payload: { id: string; authUserId: string }) {
  return this.eventsService.findOneEventForViewer(payload.id, payload.authUserId);
}
```

## 5. `api-gateway/src/events/events.controller.ts`

Add the publish route and switch `GET :id` to the viewer-aware RPC. Resolve the user with the existing `getAuthenticatedUser` helper (the one `findMyEvents` uses):
```ts
@Patch(':id/publish')
async publish(
  @Param('id', ParseUUIDPipe) id: string,
  @Req() request: AuthenticatedRequest,
) {
  const user = await this.getAuthenticatedUser(request);
  return this.eventsService.send('publishEvent', { id, ownerId: user.id });
}

@Get(':id')
async findOne(
  @Param('id', ParseUUIDPipe) id: string,
  @Req() request: AuthenticatedRequest,
) {
  const user = await this.getAuthenticatedUser(request);
  return this.eventsService.send('findOneEventForViewer', { id, authUserId: user.id });
}
```
Note: `AuthenticatedRequest` in this controller currently only types `user.email`. `getAuthenticatedUser` already returns the DB user with `.id`. Keep using `.id` from that resolved user — do not rely on `request.user.uid` here (this controller uses the email path; the tracking controller uses `uid` — keep them separate).

Route ordering: `PATCH :id/publish` must be declared — Nest matches `:id/publish` distinctly from `:id`; no conflict, but keep `:id/publish` above bare `:id` for clarity.

## Constraints
- Do NOT modify `findOneEvent` — tracking / registrations / reminder cron depend on its id-only payload.
- Do NOT change `EventsService.create()` — drafts go through the normal create with `state: 'DRAFT'`; owner auto-registration on a draft is acceptable.
- `waypoints` needs no service logic — Prisma persists the array directly from `createEventDto`/`updateEventDto`.
- No new env vars.

## Verify
- `GET /api/events` → no `DRAFT` rows. `GET /api/events/my` → includes owner drafts.
- `GET /api/events/:id` non-owner draft → 404; owner draft → 200.
- `PATCH /api/events/:id/publish`: non-owner → 403; non-draft → 409; owner draft → 200 with `state: SCHEDULED`.
- Tracking start/end and registrations still work.
