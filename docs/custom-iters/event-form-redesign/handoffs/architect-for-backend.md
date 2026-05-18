> Slim handoff for /custom-iter event-form-redesign. Full detail in architect.md (read only if ambiguous).

# Architect → Backend

## Repo
`/Users/cami/Developer/Personal/rideglory-api/events-ms`

## Files to modify

### 1. `prisma/schema.prisma`

Replace the `EventType` enum block:

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

Add to `model Event` after the `price` field:

```prisma
  maxParticipants  Int?
```

### 2. Run migration (dev only — wipes DB)

```bash
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npx prisma migrate reset --force
npx prisma migrate dev --name expand_event_type_and_add_max_participants
```

## Contract changes

- `eventType` field in all Event endpoints now accepts/returns: `TOURISM`, `URBAN`, `OFF_ROAD`, `COMPETITION`, `SOLIDARITY`, `SHORT_DISTANCE`
- `maxParticipants` is an optional `Int?` — passes through automatically (no service logic change needed)

## No other backend changes

No controller, service, or DTO changes needed in the NestJS layer — Prisma handles enum and field pass-through automatically.
