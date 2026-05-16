# Migration Plan — event-form-redesign

## Repo
`/Users/cami/Developer/Personal/rideglory-api/events-ms`

## Strategy
Dev database reset — no data migration SQL needed.

## Commands

```bash
cd /Users/cami/Developer/Personal/rideglory-api/events-ms

# Wipe dev DB and apply fresh schema
npx prisma migrate reset --force

# Create new migration with expanded enum + maxParticipants
npx prisma migrate dev --name expand_event_type_and_add_max_participants
```

## Schema Changes

### EventType enum (replace block)

```prisma
enum EventType {
  TOURISM
  URBAN
  OFF_ROAD
  COMPETITION
  SOLIDARITY
  SHORT_DISTANCE
}
```

### Event model (add field after `price`)

```prisma
  maxParticipants  Int?
```

## Post-migration Verification

```bash
# Verify Prisma client regenerated
npx prisma generate

# Verify migration applied cleanly
npx prisma migrate status
```

## Risk

- Dev-only: wipes all local event data. Acceptable per PRD.
- No prod impact: this migration should only run after backend deployment coordination.
