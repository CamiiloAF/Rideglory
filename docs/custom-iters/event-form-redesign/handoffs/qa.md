# QA Handoff — event-form-redesign

> Slim handoff for /custom-iter event-form-redesign.

## Goal

Verify that the event form redesign (Pencil frame zbCa0), EventType enum expansion (4→6), and maxParticipants optional field are correctly implemented with no regressions.

## Static Analysis

| Area | Command | Result |
|------|---------|--------|
| Events feature | `dart analyze lib/features/events/` | No issues found |
| Design system | `dart analyze lib/design_system/` | No issues found |
| l10n | `dart analyze lib/l10n/` | No issues found |

## Test Baseline

| Suite | Pass | Fail | Notes |
|-------|------|------|-------|
| All tests | 18 | 6 | 6 failures pre-existing in `features/maintenance/` — caused by in-progress `maintenances-logic` custom-iter; unrelated to this change |

All failures trace to `vehicle_maintenances_cubit.dart` referencing `MaintenanceModel.date` which was renamed by the maintenance custom-iter. This is a known pre-existing issue.

## Regression Test Surface

### Changed areas and coverage

| Area | Files Changed | Existing Tests | Gap |
|------|--------------|----------------|-----|
| EventModel / EventType enum | `event_model.dart` | None (domain model untested) | Manual — verify all 6 enum values serialize/deserialize |
| EventDto / converters | `event_dto.dart`, `event_dto.g.dart`, `event_dto_converters.dart` | None | Manual — verify API round-trip for all 6 EventType values + maxParticipants |
| event_form_view | `event_form_view.dart` | None | Manual — verify AppBar layout, Cancelar/Publicar buttons |
| EventFormContent | `event_form_content.dart` | None | Manual — verify section order, default values |
| EventFormMaxParticipantsSection | New file | None | Manual — verify stepper behavior |
| EventFormPriceSection | New file | None | Manual — verify checkbox toggle + AnimatedSize |
| EventFormEventTypeSection | `event_form_event_type_section.dart` | None | Manual — verify 2×3 chip grid |
| AppColors / AppColorsExtension | `app_colors.dart`, `app_colors_extension.dart` | None | Manual — verify chips display correct colors |
| event_card_type_chip / event_type_chip | Both files | None | Manual — verify event list/detail shows correct chip |

## Manual Verification Test Cases

### TC-01: Event Form — Create mode
1. Navigate to create event form
2. Verify section order: Cover → Información Básica → Fecha y Hora → Dificultad → Ruta → Tipo de Evento → Marcas Permitidas → Cupos disponibles → Precio de Inscripción
3. Verify AppBar: "Cancelar" (gray) left, title center, "Publicar" (orange) right
4. Verify bottom bar also shows "Guardar borrador" and "Publicar" buttons

### TC-02: EventType chip grid
1. Scroll to "TIPO DE EVENTO" section
2. Verify 6 chips in 2 rows: Row 1 = Turismo, Urbana, Off-road; Row 2 = Competición, Solidaria, Corta distancia
3. Tap each chip — verify orange fill + white bold text when selected; unselected shows dark card + border
4. Verify only one chip selected at a time

### TC-03: MaxParticipants stepper
1. Scroll to "CUPOS DISPONIBLES" section
2. Verify initial state shows "—" (no limit) with "–" button disabled
3. Tap "+" — verify display changes to "5"
4. Tap "+" repeatedly to 500 — verify "+" button becomes disabled at 500
5. Tap "–" at 5 — verify returns to "—"
6. Tap "–" past 5 — verify does not go below "—"
7. Set to 50 — verify value is submitted with form

### TC-04: Price section
1. Scroll to "PRECIO DE INSCRIPCIÓN" section
2. Verify "Opcional" badge in header
3. Verify "$" symbol + divider + text input visible
4. Tap "Evento gratuito" checkbox — verify price input animates out (AnimatedSize)
5. Tap again — verify price input animates back in
6. When free is checked and form submitted — verify price is null
7. Enter a price — verify only digits accepted (FilteringTextInputFormatter.digitsOnly)

### TC-05: Event form — Edit mode
1. Open an existing event for editing
2. Verify all fields populate including price and maxParticipants
3. Verify EventType chip matches stored value
4. Verify isFreeEvent checkbox state matches event.isFree

### TC-06: Event list chips
1. Navigate to event list
2. Verify each EventType displays correct chip with correct color:
   - Turismo → purple (#9333EA)
   - Urbana → primary orange (#f98c1f)
   - Off-road → brown (#8B4513)
   - Competición → red (#EF4444)
   - Solidaria → teal (#14B8A6)
   - Corta distancia → violet (#8B5CF6)

### TC-07: Cancel navigation
1. Open event form
2. Tap "Cancelar" in AppBar
3. Verify navigates back (context.pop())

### TC-08: l10n completeness
1. Verify all labels render in Spanish (no key placeholders visible)
2. Spot-check: "CUPOS DISPONIBLES", "PRECIO DE INSCRIPCIÓN", "Opcional", "Evento gratuito"

## Pending Prerequisites Before Full QA

These must be completed by the human before integration testing:

1. Run `dart run build_runner build --delete-conflicting-outputs` — the `event_dto.g.dart` was manually patched; proper generation may produce minor differences
2. Run `npx prisma migrate dev` in the backend repo — without this, API will reject new EventType values and maxParticipants field

## Known Issues / Out of Scope

- 6 failing tests in `features/maintenance/` — pre-existing, tracked separately under `maintenances-logic` custom-iter
- Backend API not yet migrated — the Prisma schema was updated in `/Users/cami/Developer/Personal/rideglory-api/events-ms/prisma/schema.prisma` but migration not run
- `event_dto.g.dart` manually edited — should be regenerated via build_runner for production safety
