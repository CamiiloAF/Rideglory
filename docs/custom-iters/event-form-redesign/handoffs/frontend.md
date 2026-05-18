# Frontend Handoff — event-form-redesign

> Slim handoff for /custom-iter event-form-redesign. Full detail in architect-for-frontend.md.

## Goal

Full redesign of event form page and section widgets to match Pencil frame zbCa0, expand EventType enum from 4 to 6 values, and add maxParticipants optional field.

## Implementation Summary

All Flutter source code changes have been applied. The working tree contains a complete, analyzable implementation ready for human review.

## Files Modified / Created

### New files
- `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` — Stepper widget for optional maxParticipants (null=no limit, 5–500 step 5)
- `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` — Price section with "Evento gratuito" checkbox and AnimatedSize collapse
- `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` — Extracted from private _FormBottomBar; public EventFormBottomBar widget

### Modified files
- `lib/features/events/domain/model/event_model.dart` — EventType enum expanded to 6 values; maxParticipants added to EventModel
- `lib/features/events/data/dto/event_dto_converters.dart` — EventTypeConverter updated for all 6 values
- `lib/features/events/data/dto/event_dto.dart` — maxParticipants added to constructor and toJson
- `lib/features/events/data/dto/event_dto.g.dart` — Manually updated: maxParticipants in fromJson/toJson
- `lib/features/events/constants/event_form_fields.dart` — Added maxParticipants and isFreeEvent constants
- `lib/design_system/foundation/theme/app_colors.dart` — 4 old event colors replaced with 6 new ones
- `lib/design_system/foundation/theme/app_colors_extension.dart` — Full rewrite with 6 event color fields
- `lib/features/events/presentation/list/widgets/event_card_type_chip.dart` — Switch updated to 6 EventType cases
- `lib/features/events/presentation/list/widgets/event_type_chip.dart` — Switch updated to 6 EventType cases
- `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart` — Default EventType changed to urban
- `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart` — Rewritten with 2 rows of 3 chips each
- `lib/features/events/presentation/form/widgets/event_form_content.dart` — New section order; new sections wired in
- `lib/features/events/presentation/form/widgets/event_form_view.dart` — AppBar with Cancelar/Publicar; bottomNavigationBar uses EventFormBottomBar
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart` — buildEventToSave handles isFreeEvent + maxParticipants
- `lib/l10n/app_es.arb` — New l10n keys added
- `lib/l10n/app_localizations.dart` — Abstract getters added for new keys
- `lib/l10n/app_localizations_es.dart` — Override implementations added for new keys

## Lint Result

```
dart analyze lib/features/events/ lib/design_system/ lib/l10n/
Analyzing lib/features/events/, lib/design_system/, lib/l10n/...
No issues found!
```

## Test Result

```
flutter test
00:06 +18 -6: Some tests failed.
```

- 18 tests passing
- 6 tests failing — all in `lib/features/maintenance/` (pre-existing, unrelated to this change; caused by the in-progress `maintenances-logic` custom-iter in the untracked tree)
- 0 failures in events, design_system, or l10n

## Compliance

- One widget per file: verified (EventFormBottomBar extracted, all private classes are non-widget or same-widget state)
- No hardcoded strings: all user-visible text uses context.l10n keys
- No direct HTTP calls in presentation layer: confirmed
- FormBuilderField pattern: used for isFreeEvent (bool) and maxParticipants (int?) custom fields
- AnimatedSize for collapsible price card: implemented
- All exhaustive switches on EventType updated to 6 cases: verified

## Manual Verification Checklist

- [ ] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate freezed/json (event_dto.g.dart was manually edited as a workaround)
- [ ] Run `flutter gen-l10n` to confirm ARB generates correctly
- [ ] Open event form create mode — verify section order matches Pencil frame zbCa0
- [ ] Verify EventType chip grid shows 2 rows × 3 chips (Turismo/Urbana/Off-road, Competición/Solidaria/Corta distancia)
- [ ] Tap "Turismo" chip — verify orange fill + white text
- [ ] Toggle "Evento gratuito" — verify price input animates out; toggle off — verify it animates back
- [ ] Tap "+" on maxParticipants from null state — verify display jumps to 5
- [ ] Tap "–" at 5 — verify returns to "—" (no limit)
- [ ] Tap "+" at 500 — verify disabled (no change)
- [ ] Open event form edit mode — verify existing values populate correctly including price and maxParticipants

## Pending Human Actions

1. Backend repo: run `npx prisma migrate reset --force && npx prisma migrate dev --name expand_event_type_and_add_max_participants` in `rideglory-api/events-ms/`
2. Frontend: run `dart run build_runner build --delete-conflicting-outputs` to regenerate all `.g.dart` and `.freezed.dart` files
3. Review `git diff` output for all changed files before committing
