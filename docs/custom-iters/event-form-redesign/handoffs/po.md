# PO Handoff — event-form-redesign

**Date:** 2026-05-16
**Status:** in progress

---

## Goal

Redesign the event creation/edit form to match Pencil frame `zbCa0`, expand `EventType` from 4 to 6 values, and add optional `maxParticipants` field — both in Flutter and in the backend Prisma schema.

---

## Source Quote

> PRD path: docs/custom-iters/event-form-redesign/PRD.md — Full redesign of event_form_page.dart to match Pencil frame zbCa0 ("Crear Evento"), EventType enum expansion from 4 to 6 values, and new maxParticipants field.

---

## Interpretation

This is a high-severity improvement combining:
1. A **visual redesign** — the form must match Pencil frame `zbCa0` exactly, including AppBar style, chip pills, section headers, new price section widget, and new maxParticipants stepper section.
2. A **breaking enum rename** — 4 EventType values become 6 with completely different Dart names and backend string values. All existing events in dev DB will be wiped (dev reset — no data migration needed per PRD).
3. A **new optional field** — `maxParticipants` added to domain model, DTO, cubit, and backend schema.

The changes span two repositories: this Flutter repo AND `rideglory-api/events-ms`.

---

## Affected Areas — Current State

| File | Current State | Required Change |
|---|---|---|
| `lib/features/events/domain/model/event_model.dart` (line 1-8) | `EventType` enum has 4 values: `offRoad`, `onRoad`, `exhibition`, `charitable`. No `maxParticipants` field on `EventModel`. | Replace enum with 6 values; add `int? maxParticipants` field + copyWith |
| `lib/features/events/data/dto/event_dto_converters.dart` (line 32-57) | `EventTypeConverter` maps 4 old values. `fromJson` handles both camelCase and SCREAMING_SNAKE strings. | Replace with 6-value mapping per new enum |
| `lib/features/events/data/dto/event_dto.dart` | Extends `EventModel`; no `maxParticipants`. Generated `.g.dart` file exists. | Add `@JsonKey(name: 'maxParticipants') super.maxParticipants;` and regenerate |
| `lib/features/events/constants/event_form_fields.dart` | Missing `maxParticipants` constant | Add `static const maxParticipants = 'maxParticipants';` |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | `buildEventToSave()` maps price but not maxParticipants. `initialize()` does not load maxParticipants from editing event. | Add maxParticipants mapping in both |
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | AppBar: back-arrow (left) \| title (center) \| "Cancelar" text button (right). Bottom bar has CTA. | AppBar: "Cancelar" text (left) \| title (center) \| "Publicar" accent text (right). Remove bottom bar CTA or keep as secondary? — PRD says header "Publicar" IS the CTA; keep bottom "Publicar evento" primary button per Pencil section 11 |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | Missing price section widget, missing maxParticipants section. Price is an inline `AppTextField`. | Add `EventFormMaxParticipantsSection` and `EventFormPriceSection` |
| `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart` | Chips have `borderRadius: 8`. 4 EventType values. | Change to `borderRadius: 20` (pill). 6 values. Unselected: `AppColors.darkCard` fill + `AppColors.darkBorderPrimary` border. Selected: `AppColors.primary` fill + white bold text |
| `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | Does not exist | Create: stepper (min=5, max=500, step=5), optional, with section header "MÁXIMO DE PARTICIPANTES" + "Opcional" badge |
| `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` | Does not exist | Create: price card with "$" symbol + divider + text input + "Evento gratuito" checkbox (AnimatedSize collapse) |
| `lib/l10n/app_es.arb` | `event_form_max_participants_label` key exists but no stepper/section-specific keys; some price keys exist | Add missing keys for redesigned sections |
| `rideglory-api/events-ms/prisma/schema.prisma` | `EventType` enum: OFF_ROAD, ON_ROAD, EXHIBITION, CHARITABLE. No `maxParticipants` on Event model | Replace enum + add field |

---

## Acceptance Criteria

1. AppBar: "Cancelar" (text-secondary, left) | "Nuevo Evento"/"Editar Evento" (center, w600) | "Publicar" (accent, right).
2. EventType chips: borderRadius 20, 6 values, Wrap with spacing 8 in 2 rows of 3.
3. Selected chip: `AppColors.primary` fill, white bold text. Unselected: `AppColors.darkCard` fill, `AppColors.darkBorderPrimary` border, text-secondary.
4. `EventFormMaxParticipantsSection` exists: stepper (min=5, max=500, step=5), optional.
5. `EventFormPriceSection` exists: "$" symbol card + amount input + "Evento gratuito" checkbox; checking box collapses price input via AnimatedSize and clears the value.
6. `maxParticipants` sent as `null` when not set; loaded correctly in edit mode.
7. All 6 new EventType values serialize/deserialize correctly via `EventTypeConverter`.
8. `dart analyze` 0 errors. `build_runner build` clean.
9. Existing create + edit flow works end-to-end.
10. All new user-visible strings in `app_es.arb`.

---

## Regression Guardrails

| Area | Guardrail | Verification steps |
|---|---|---|
| Event create flow | Form submits without error | `flutter run`, create event, see success SnackBar |
| Event edit flow | Existing event data loads, submits update | Open edit form for existing event, verify fields populated |
| EventType serialization | All 6 types round-trip | Unit test: `EventTypeConverter` encode + decode all 6 values |
| maxParticipants optional | Null when stepper not touched | Check cubit `buildEventToSave()` returns null for unset |
| AI cover generation | `generateCover()` triggers | Manual: tap "Generar con IA" on form |
| Difficulty | Flame selector sets difficulty | Manual: change to level 3, submit |
| Multi-brand toggle | allowedBrands correct | Manual: select 2 brands, submit |
| "Evento gratuito" checkbox | Nulls price | Widget test: check box → verify price field collapses + value null |

---

## Decisions Needed from Downstream Agents

- **Architect**: Confirm whether `EventDto` needs explicit constructor parameter for `maxParticipants` or if the `super.maxParticipants` approach suffices given that `EventDto extends EventModel`.
- **Frontend**: Note that `_FormBottomBar` is a private class in `event_form_view.dart` — it must be extracted to its own file per "one widget per file" rule if it stays.
- **Backend**: Confirm `npx prisma migrate reset --force` is safe for dev (wipes DB).

---

## Open Questions for Human

1. MaxParticipants stepper range: proceeding with min=5, max=500, step=5 per PRD recommendation.
2. "Evento gratuito" behavior: proceeding with AnimatedSize collapse per PRD recommendation.
3. "Cancelar" discard dialog in edit mode: deferred (out of scope this run per PRD § 7).

---

## Suggested Phase Plan

- `needsDesign: true` — Pencil frame `zbCa0` must be read before any widget is touched
- `needsBackend: true` — Prisma schema change in rideglory-api
- `needsFrontend: true` — all Flutter file changes
- `needsDb: true` — Prisma migration (dev reset)

---

## Notes for Orchestrator

- `decisions.uiChanges = true`
- `decisions.backendChanges = true`
- `decisions.frontendChanges = true`
- `decisions.dbChanges = true`
- `decisions.needsDesign = true`
- The `_FormBottomBar` private class in `event_form_view.dart` (lines ~140-230) violates the one-widget-per-file rule. Frontend agent must extract it.
- No `improvement-prd.md` template found in `scripts/templates/` — PRD_NORMALIZED was written from scratch following the structure in the custom-iter prompt.
- No `custom-iter-review-checklist.md` template found — PO close-out agent must also work from scratch.
