# Architect Handoff — event-form-redesign

**Date:** 2026-05-16
**Status:** in progress

---

## Goal Acknowledgement

Redesign the event form to match Pencil frame `zbCa0`, expand `EventType` from 4 to 6 values (breaking rename in both Flutter and Prisma), add optional `maxParticipants` field, and deliver new `EventFormMaxParticipantsSection` and `EventFormPriceSection` widgets. Changes span Flutter app and `rideglory-api/events-ms`.

---

## Change Map

| File | Action | Reason | Risk |
|---|---|---|---|
| `lib/features/events/domain/model/event_model.dart` | modify | Replace 4-value EventType with 6-value enum; add `int? maxParticipants` + copyWith | high — cascades to all EventType switch statements |
| `lib/features/events/data/dto/event_dto_converters.dart` | modify | Update EventTypeConverter to map 6 new values (TOURISM/URBAN/OFF_ROAD/COMPETITION/SOLIDARITY/SHORT_DISTANCE) | high — wrong mapping = silent data corruption |
| `lib/features/events/data/dto/event_dto.dart` | modify | Add `@JsonKey(name: 'maxParticipants') super.maxParticipants;` param | low |
| `lib/features/events/data/dto/event_dto.g.dart` | regenerate | Must re-run build_runner after EventDto change | low |
| `lib/features/events/constants/event_form_fields.dart` | modify | Add `maxParticipants` constant | low |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | modify | Map maxParticipants in `_getInitialValues` (edit mode) and `buildEventToSave()` | med — missing mapping = null on edit submit |
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | modify | Redesign AppBar: "Cancelar" TextButton (left) \| title (center) \| "Publicar" accent TextButton (right); extract `_FormBottomBar` to own file | med — AppBar refactor |
| `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` | create | Extracted from `event_form_view.dart` (one-widget-per-file rule) | low |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | modify | Add `EventFormMaxParticipantsSection` + `EventFormPriceSection`; remove inline AppTextField price; reorder sections per Pencil frame | med — content restructure |
| `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart` | modify | Pill chips (borderRadius 20); 6 values; correct selected/unselected colors | low |
| `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | create | New stepper section: "MÁXIMO DE PARTICIPANTES" header + "Opcional" badge + stepper (min=5, max=500, step=5) + hint row | low |
| `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` | create | Price card ("$" symbol + divider + text input) + "Evento gratuito" checkbox + AnimatedSize collapse | low |
| `lib/features/events/presentation/list/widgets/event_card_type_chip.dart` | modify | Switch on EventType must cover all 6 new cases (exhaustiveness compile error otherwise) | high — compile error if missed |
| `lib/features/events/presentation/list/widgets/event_type_chip.dart` | modify | Same — switch must cover 6 cases | high — compile error if missed |
| `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart` | modify | `_selectedEventType` default was `EventType.onRoad` (no longer exists) → change to `EventType.urban` | high — compile error |
| `lib/design_system/foundation/theme/app_colors.dart` | modify | Add 2 new event color constants: `eventSolidarity`, `eventShortDistance` | low |
| `lib/design_system/foundation/theme/app_colors_extension.dart` | modify | Rename old fields OR add 2 new fields for solidarity/shortDistance colors. Strategy: rename `eventOnRoad`→`eventUrban`, `eventExhibition`→`eventOffRoadNew`(or just reuse existing `eventOffRoad` for new OFF_ROAD), `eventCharitable`→`eventCompetition`; add `eventSolidarity`, `eventShortDistance`. See note below. | high — must coordinate with chip widgets |
| `lib/l10n/app_es.arb` | modify | Add missing l10n keys for new sections and redesigned AppBar | low |
| `rideglory-api/events-ms/prisma/schema.prisma` | modify | Replace EventType enum (6 values); add `maxParticipants Int?` to Event model | high — breaking DB change |

### Color Strategy for EventType expansion

The old 4 `appColors` fields (`eventOffRoad`, `eventOnRoad`, `eventExhibition`, `eventCharitable`) are used in switch statements. The safest approach is:

- **Rename fields** in `AppColorsExtension` to match new enum names:
  - `eventOffRoad` → **keep** (reused: old name, new value `OFF_ROAD` = "Off-road")
  - `eventOnRoad` → rename to **`eventUrban`** (new `URBAN` type)
  - `eventExhibition` → rename to **`eventTourism`** (new `TOURISM` type)  
  - `eventCharitable` → rename to **`eventCompetition`** (new `COMPETITION` type)
  - Add **`eventSolidarity`** (new)
  - Add **`eventShortDistance`** (new)
- This requires updating `AppColors` static constants with the same renames, plus updating `AppColorsExtension.rideglory()`, `copyWith()`, and `lerp()`.
- The switch statements in chip files must be updated to use the new field names.

---

## Data Model Impact

### EventModel

```dart
// New field added:
final int? maxParticipants;
// In constructor: this.maxParticipants,
// In copyWith: int? maxParticipants, ... maxParticipants: maxParticipants ?? this.maxParticipants,
```

### EventDto

```dart
// Add to constructor:
@JsonKey(name: 'maxParticipants') super.maxParticipants,
```

The `.g.dart` regeneration will add `maxParticipants` to `_$EventDtoFromJson` and `_$EventDtoToJson` automatically.

### Prisma Schema (events-ms)

```prisma
enum EventType {
  TOURISM
  URBAN
  OFF_ROAD
  COMPETITION
  SOLIDARITY
  SHORT_DISTANCE
}

model Event {
  // ... existing fields ...
  maxParticipants  Int?   // add after price
}
```

Migration: `npx prisma migrate reset --force` (dev DB wipe) then `npx prisma migrate dev --name expand_event_type_and_add_max_participants`

---

## Contract Impact

The backend `EventType` enum changes affect:
- `POST /api/events` — `eventType` body field now accepts 6 new string values
- `GET /api/events` — `eventType` in response now returns new string values
- `GET /api/events/:id` — same
- `PATCH /api/events/:id` — same
- `maxParticipants` field is additive (optional `Int?`) — no breaking change on API consumers that don't use it

**Flutter `EventTypeConverter.fromJson`** must handle the 6 new SCREAMING_SNAKE values. Old camelCase aliases can be dropped (they were for backward compat with old data that no longer exists after reset).

---

## Env / Config Delta

None. No new env vars required.

---

## Risk Register

1. **Enum exhaustiveness compile errors** (high): `event_card_type_chip.dart`, `event_type_chip.dart`, `event_form_details_section.dart` all use `switch(eventType)` without `default`. After enum expansion, Dart will refuse to compile until all 6 cases are covered. Mitigation: Frontend agent must update all switch statements as part of this change.

2. **`AppColorsExtension` field rename** (high): Renaming `eventOnRoad`→`eventUrban` etc. requires grep-replacing all call sites. Mitigation: Frontend agent uses `replace_all` edits to be safe; `dart analyze` catches missed references.

3. **`event_form_details_section.dart` default value** (high): `EventType _selectedEventType = EventType.onRoad` — `onRoad` will not exist after enum change. Must change to `EventType.urban`. This file is NOT in the PRD's § 6 affected list — it's an additional file discovered during architecture review.

4. **`event_form_content.dart` uses `EventType.offRoad` as default** (med): Line `EventFormFields.eventType: EventType.offRoad` in `_getInitialValues`. After rename, `offRoad` still exists (it's the new OFF_ROAD value) — but verify the default makes sense. PRD design shows "Turismo" selected by default visually. Change default to `EventType.tourism`.

5. **`EventDto.toJson()` manual override** (low): The `toJson()` in `event_dto.dart` manually sets `startDate` and `meetingTime`. The `maxParticipants` field will be automatically handled by the generated `_$EventDtoToJson` — no manual addition needed. Verify regenerated `.g.dart` includes it.

6. **`_FormBottomBar` private class** (med): Violates one-widget-per-file. Must be extracted to `event_form_bottom_bar.dart`.

7. **Backend migration irreversibility** (high-dev-only): `prisma migrate reset --force` wipes the dev DB. This is acceptable per PRD; no prod impact. Dev must restart their local API after migration.

---

## Regression Test Surface

| Test Area | Existing Coverage | Gap |
|---|---|---|
| EventType serialization | None | Need: unit test for all 6 new EventTypeConverter mappings |
| EventModel construction | None | Need: verify maxParticipants is nullable, copyWith works |
| EventFormContent build | No widget tests | Need: smoke widget test that form builds without error |
| Price section | None | Need: widget test for "Evento gratuito" checkbox collapsing price |
| EventType chips display | None | Need: verify 6 chips render |

---

## Implementation Order

1. **Backend** (`rideglory-api/events-ms`):
   - Update `prisma/schema.prisma`: replace EventType enum + add `maxParticipants Int?`
   - Run `npx prisma migrate reset --force && npx prisma migrate dev --name expand_event_type_and_add_max_participants`

2. **Flutter — domain + data** (no compile errors in this layer yet):
   - Update `event_model.dart`: replace EventType enum + add `maxParticipants` to EventModel
   - Update `event_dto_converters.dart`: new EventTypeConverter
   - Update `event_dto.dart`: add maxParticipants param
   - Update `event_form_fields.dart`: add maxParticipants constant
   - Run `dart run build_runner build --delete-conflicting-outputs` → regenerate `event_dto.g.dart`

3. **Flutter — design system** (must fix before presentation layer):
   - Update `app_colors.dart`: rename + add color constants
   - Update `app_colors_extension.dart`: rename + add fields in all 4 places (class def, factory, copyWith, lerp)

4. **Flutter — presentation switches** (fix compile errors):
   - Update `event_card_type_chip.dart`: switch for 6 new enum values
   - Update `event_type_chip.dart`: same
   - Update `event_form_details_section.dart`: fix default `EventType.onRoad` → `EventType.urban`

5. **Flutter — cubit**:
   - Update `event_form_cubit.dart`: `_getInitialValues` + `buildEventToSave()` for maxParticipants; fix default `EventType.offRoad` → `EventType.tourism`

6. **Flutter — new widgets**:
   - Create `event_form_max_participants_section.dart`
   - Create `event_form_price_section.dart`
   - Create `event_form_bottom_bar.dart` (extracted from view)

7. **Flutter — modified widgets**:
   - Update `event_form_view.dart`: redesign AppBar, reference new `EventFormBottomBar`
   - Update `event_form_content.dart`: add new sections, remove inline price, fix default eventType
   - Update `event_form_event_type_section.dart`: pill radius + colors

8. **L10n**:
   - Update `app_es.arb`: add missing keys
   - Run `flutter gen-l10n` (or build_runner)

9. **Run `dart analyze`** — 0 errors required

---

## Out of Scope

- `event_form_details_section.dart` beyond the default value fix — this appears to be an older/alternate form section; the current form content uses `EventFormDifficultySection` and `EventFormEventTypeSection` separately. The details section still exists but is NOT rendered in the current `event_form_content.dart`. We still update the default value and switch cases to prevent compile errors, but we don't redesign this file.
- `AppColors.eventOffRoad` static on the class → keep the name since it now correctly maps to the new `OFF_ROAD` type ("Off-road" label). Only the color fields that need semantic rename get changed.
- Color values themselves — we're only renaming and adding; Architect defers the actual color palette values for new types to the Frontend agent's judgment based on Pencil frame.

---

## Notes for Orchestrator

- `decisions.uiChanges = true` ✓
- `decisions.backendChanges = true` ✓
- `decisions.frontendChanges = true` ✓
- `decisions.dbChanges = true` ✓
- `decisions.needsDesign = true` ✓ — Pencil frame `zbCa0` must be inspected before implementing the new section widgets
- **Additional files discovered not in PRD § 6**: `event_card_type_chip.dart`, `event_type_chip.dart`, `event_form_details_section.dart`, `app_colors.dart`, `app_colors_extension.dart`, `event_form_bottom_bar.dart` (new). These are mandatory to avoid compile errors.
- PO decisions field already set correctly — no flips needed.
