# Human Review Checklist — event-form-redesign

Use this checklist before approving and committing the changes.

## Pre-Merge Required Actions

- [ ] Run `dart run build_runner build --delete-conflicting-outputs` in the Flutter project root
  - Verify `event_dto.g.dart` output includes `maxParticipants` in both `_$EventDtoFromJson` and `_$EventDtoToJson`
- [ ] In `rideglory-api/events-ms/`: run `npx prisma migrate dev --name expand_event_type_and_add_max_participants`
  - If a destructive migration is needed: `npx prisma migrate reset --force && npx prisma migrate dev --name expand_event_type_and_add_max_participants`
- [ ] After build_runner: re-run `dart analyze lib/features/events/ lib/design_system/ lib/l10n/` — verify still 0 issues

## Code Review (git diff)

Files changed exclusively by this iteration (filter out maintenance/ and vehicles/ lines — those belong to other custom-iters):

- [ ] `lib/features/events/domain/model/event_model.dart` — EventType has 6 values; maxParticipants added
- [ ] `lib/features/events/data/dto/event_dto_converters.dart` — 6 values in fromJson/toJson; no default branch in toJson
- [ ] `lib/features/events/data/dto/event_dto.dart` — maxParticipants in constructor + toJson
- [ ] `lib/features/events/data/dto/event_dto.g.dart` — maxParticipants in generated fromJson/toJson
- [ ] `lib/design_system/foundation/theme/app_colors.dart` — 6 event colors (old 4 removed)
- [ ] `lib/design_system/foundation/theme/app_colors_extension.dart` — 6 fields consistent across all 4 locations
- [ ] `lib/features/events/presentation/list/widgets/event_card_type_chip.dart` — 6-case switch
- [ ] `lib/features/events/presentation/list/widgets/event_type_chip.dart` — 6-case switch
- [ ] `lib/features/events/presentation/form/widgets/event_form_view.dart` — AppBar: Cancelar/title/Publicar; EventFormBottomBar
- [ ] `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` (NEW) — extracted bottom bar
- [ ] `lib/features/events/presentation/form/widgets/event_form_content.dart` — section order; new sections wired
- [ ] `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` (NEW) — stepper logic
- [ ] `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` (NEW) — price + free checkbox
- [ ] `lib/features/events/presentation/form/cubit/event_form_cubit.dart` — isFreeEvent + maxParticipants in buildEventToSave
- [ ] `lib/l10n/app_es.arb` — 9 new event_form_* keys present
- [ ] `lib/l10n/app_localizations.dart` — abstract getters for all 9 new keys
- [ ] `lib/l10n/app_localizations_es.dart` — @override implementations for all 9 new keys

## Policy Decision (Optional)

- [ ] Decide: allow private StatelessWidget subclasses in section files (current state: multiple `_X extends StatelessWidget` in same file)?
  - If NO: extract `_PriceSectionHeader`, `_PriceInputCard`, `_FreeEventRow`, `_MaxParticipantsCard`, etc. to separate files under a `widgets/` subfolder.
  - If YES: document the exception in CLAUDE.md under "Widgets — Reglas críticas".

## Manual Smoke Test

- [ ] Launch app → create event → verify section order matches Pencil frame zbCa0
- [ ] EventType chip grid: 2 rows × 3 chips; orange fill when selected
- [ ] MaxParticipants stepper: null → 5 → ... → 500 (capped); 5 → null (not below 5)
- [ ] Price section: "Evento gratuito" checkbox collapses input (AnimatedSize)
- [ ] Cancelar → pops form; Publicar → submits (or shows loading)
- [ ] Event list chips: 6 colors render correctly for each EventType

## Acceptance Criteria Verification

From PRD_NORMALIZED.md § 6:

- [ ] AC-01: AppBar matches zbCa0 — "Cancelar" (left), title (center), "Publicar" (right)
- [ ] AC-02: EventType section shows 2×3 chip grid with all 6 types
- [ ] AC-03: Selected chip has orange fill (#f98c1f) + white bold text
- [ ] AC-04: MaxParticipants stepper — null means no limit; "+" from null → 5; "–" at 5 → null; capped at 500
- [ ] AC-05: Price section "Opcional" badge; "Evento gratuito" checkbox collapses input
- [ ] AC-06: Form submits with null price when isFree=true; submits maxParticipants as int? or null
- [ ] AC-07: EventType enum has exactly 6 values: TOURISM, URBAN, OFF_ROAD, COMPETITION, SOLIDARITY, SHORT_DISTANCE
- [ ] AC-08: Prisma schema updated with new EventType values and maxParticipants Int? field
- [ ] AC-09: dart analyze shows 0 issues in events/, design_system/, l10n/
- [ ] AC-10: All new labels use l10n keys (no hardcoded strings)

## Files NOT to Stage (belong to other custom-iters)

Do not stage any files under:
- `lib/features/maintenance/`
- `lib/features/vehicles/` (except as needed by this iter — none in scope)
- `lib/features/home/presentation/widgets/home_vehicle_info_row.dart`
