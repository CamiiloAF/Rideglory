# PRD_NORMALIZED — Event Form Redesign

**Slug:** event-form-redesign
**Type:** feature + redesign
**Severity:** high (EventType enum change is a breaking change)
**Normalized by PO on:** 2026-05-16

---

## § 1 Title

Event Form — Full Redesign to Pencil Frame `zbCa0` + EventType Enum Expansion (4→6) + maxParticipants Field

---

## § 2 Goal

Redesign `event_form_page.dart` and all its section widgets to be visually identical to Pencil frame `zbCa0` ("Crear Evento"), expand the `EventType` enum from 4 to 6 values with updated labels, and add the new optional `maxParticipants` field.

---

## § 3 Type and Severity

- **Type:** feature + redesign
- **Severity:** high
- **Breaking change:** `EventType` enum rename requires backend Prisma migration (`npx prisma migrate reset --force` on dev — dev DB is wiped clean, no SQL data migration needed)

---

## § 4 Affected Areas

| Area | File | Change | Status Today |
|---|---|---|---|
| Domain model | `lib/features/events/domain/model/event_model.dart` | Replace EventType enum (4→6), add `maxParticipants` field | 4 enum values: offRoad/onRoad/exhibition/charitable |
| DTO + converters | `lib/features/events/data/dto/event_dto.dart` | Add `maxParticipants` field | Missing field |
| DTO converters | `lib/features/events/data/dto/event_dto_converters.dart` | Update EventTypeConverter for 6 new values | Old 4 mappings |
| Form constants | `lib/features/events/constants/event_form_fields.dart` | Add `maxParticipants` constant | Missing constant |
| Form cubit | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | Map `maxParticipants` on load + submit | Missing field handling |
| Form view | `lib/features/events/presentation/form/widgets/event_form_view.dart` | Redesign AppBar: "Cancelar" (left) \| title center \| "Publicar" accent (right); move CTA into bottom bar per Pencil | Current: back-arrow left, "Cancelar" right |
| Form content | `lib/features/events/presentation/form/widgets/event_form_content.dart` | Add maxParticipants section, add price section redesign, reorder sections per Pencil | Missing sections |
| Event type section | `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart` | Pill chips (cornerRadius 20), 6 types, 2 rows of 3 | Currently radius=8, 4 values |
| New file | `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | Stepper widget for maxParticipants (min=5, max=500, step=5) | Does not exist |
| New file | `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` | Price card ("$" symbol + amount input) + "Evento gratuito" checkbox (AnimatedSize collapse) | Currently a plain AppTextField inline in content |
| L10n | `lib/l10n/app_es.arb` | Add new l10n keys for maxParticipants section, price redesign, CTA labels | Missing keys |
| Backend schema | `/Users/cami/Developer/Personal/rideglory-api/events-ms/prisma/schema.prisma` | Replace EventType enum (6 values), add `maxParticipants Int?` to Event model | Old 4-value enum |

---

## § 5 Enum & Field Changes

### EventType (breaking rename)

| Old Flutter enum | New Flutter enum | Backend value | Display label |
|---|---|---|---|
| `offRoad` | `tourism` | `TOURISM` | Turismo |
| `onRoad` | `urban` | `URBAN` | Urbana |
| `exhibition` | `offRoad` | `OFF_ROAD` | Off-road |
| `charitable` | `competition` | `COMPETITION` | Competición |
| — | `solidarity` | `SOLIDARITY` | Solidaria |
| — | `shortDistance` | `SHORT_DISTANCE` | Corta distancia |

### maxParticipants

- Optional `int?` on `EventModel` and `EventDto`
- Stepper: min=5, max=500, step=5; direct text input also allowed
- Sent as `null` when not set; no backend capacity enforcement this iteration

---

## § 6 Acceptance Criteria

1. `event_form_view.dart` AppBar: "Cancelar" text button (text-secondary, left) | "Nuevo Evento"/"Editar Evento" title (center, w600) | "Publicar" accent text button (right).
2. EventType chips are pill-shaped (borderRadius 20), 6 values, in 2 rows of 3 (Wrap with spacing 8).
3. Selected chip: `AppColors.primary` fill, white bold text. Unselected: `AppColors.darkCard` fill, `AppColors.darkBorderPrimary` border, text-secondary.
4. New `EventFormMaxParticipantsSection` widget: stepper (min=5, max=500, step=5), optional field.
5. New `EventFormPriceSection` widget: "$" symbol card + amount input + "Evento gratuito" checkbox; checking box AnimatedSize-collapses the price input and clears the value.
6. `maxParticipants` is sent as `null` when not set; correctly loaded in edit mode.
7. The 6 new EventType values are correctly serialized/deserialized via `EventTypeConverter`.
8. `dart analyze` passes with 0 errors after all changes.
9. `dart run build_runner build --delete-conflicting-outputs` runs cleanly.
10. Existing event create + edit flow continues to work end-to-end.
11. All new user-visible strings are in `lib/l10n/app_es.arb` (no hardcoded Spanish).

---

## § 7 Regression Guardrails

| Area | Guardrail | Verification |
|---|---|---|
| Event create flow | Form submits in create mode without error | Manual: create event, verify success SnackBar |
| Event edit flow | Form loads existing event data, submits update | Manual: edit event, verify update SnackBar |
| EventType serialization | All 6 new types round-trip to/from backend | Unit test: `EventTypeConverter` encode + decode all 6 |
| maxParticipants optional | Null when stepper not activated | Manual + cubit unit test |
| AI cover generation | `generateCover()` still triggers correctly | Manual: tap "Generar con IA" |
| Difficulty selector | Flame selector still sets difficulty on submit | Manual: change difficulty, submit |
| Multi-brand toggle | allowedBrands correctly populated on submit | Manual: toggle brands, submit |
| Price free event | Checking "Evento gratuito" nulls price | Manual + widget test |

---

## § 8 Out of Scope

- "Guardar como borrador" actual draft persistence — UI placeholder only
- Capacity enforcement ("Completo" badge)
- Route map preview rendering changes
- AI cover generation logic changes
- Event list / detail / registration screens
- "Cancelar" discard-confirmation dialog in edit mode (deferred)

---

## § 9 Open Questions

1. **MaxParticipants stepper range**: PRD recommends min=5, max=500, step=5 — proceeding with this.
2. **"Evento gratuito" checkbox**: PRD recommends AnimatedSize collapse — proceeding with this.
3. **"Cancelar" in edit mode**: PRD recommends discard confirmation dialog — deferred to follow-up; current implementation just pops.

---

## § 10 Notes

- Backend change (Prisma schema) is in a separate repo: `/Users/cami/Developer/Personal/rideglory-api/events-ms`
- Dev database reset required after enum change: `npx prisma migrate reset --force && npx prisma migrate dev --name expand_event_type_and_add_max_participants`
- `EventDto` extends `EventModel` directly — adding `maxParticipants` to `EventModel` automatically propagates to `EventDto` constructor (only the `@JsonKey` annotation needed in DTO)
