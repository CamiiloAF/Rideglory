> Slim handoff for /custom-iter event-form-redesign. Full detail in architect.md (read only if ambiguous).

# Architect → QA

## Test Commands

```bash
# Flutter analyze
cd /Users/cami/Developer/Personal/Rideglory
dart analyze

# Flutter tests
flutter test

# Build runner (check no codegen errors)
dart run build_runner build --delete-conflicting-outputs
```

## Key Test Areas

### 1. EventTypeConverter (unit test priority HIGH)
All 6 new enum values must round-trip:
- `fromJson('TOURISM')` → `EventType.tourism`
- `fromJson('URBAN')` → `EventType.urban`
- `fromJson('OFF_ROAD')` → `EventType.offRoad`
- `fromJson('COMPETITION')` → `EventType.competition`
- `fromJson('SOLIDARITY')` → `EventType.solidarity`
- `fromJson('SHORT_DISTANCE')` → `EventType.shortDistance`
- `toJson(EventType.tourism)` → `'TOURISM'` (and all 6)
- Old camelCase aliases (`offRoad`, `onRoad`, etc.) can be tested for graceful handling

### 2. maxParticipants (unit test)
- `EventModel` with `maxParticipants: null` serializes without error
- `EventModel` with `maxParticipants: 50` includes field in toJson
- Edit-mode cubit initialization: `maxParticipants` loaded from event model

### 3. Price section widget test
- "Evento gratuito" checkbox checked → price input collapsed and null

### 4. EventFormContent widget smoke test
- Form builds without error with default values
- All 6 EventType chips render

### 5. Regression: dart analyze
- Must be 0 errors (switch exhaustiveness, renamed fields)

## Regression Matrix to Verify

| Guardrail | Mechanism | Acceptable result |
|---|---|---|
| Event create | Manual | Success SnackBar shown |
| Event edit | Manual | Existing data loads; update SnackBar shown |
| EventType serialization | Unit test | All 6 values pass |
| maxParticipants null | Unit/cubit test | `null` in built model |
| AI cover generation | Manual | Triggers correctly |
| Difficulty selector | Manual | Submits correct value |
| Multi-brand toggle | Manual | allowedBrands correct |
| "Evento gratuito" | Widget test | Price collapses |
| dart analyze | CI | 0 errors |

## Pre-Existing Failures

Check Backend and Frontend handoffs for any pre-existing test failures before flagging new ones.
