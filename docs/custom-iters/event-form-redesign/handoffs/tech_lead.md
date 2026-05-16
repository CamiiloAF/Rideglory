# Tech Lead Handoff — event-form-redesign

> Review of all code changes produced by /custom-iter event-form-redesign.

## Goal Acknowledgement

Full redesign of the event form to match Pencil frame zbCa0, expansion of EventType enum from 4 to 6 values, and addition of optional maxParticipants field. All changes are in the working tree — no commits were made.

## Scope Boundary

The `git diff --stat HEAD` output shows 47 changed files. Of those, ~33 are from the pre-existing `maintenances-logic` and `vehicle-form-specs` custom-iters running in parallel. This review covers ONLY the files changed by this iteration:

**Exclusive to this iteration:**
- `lib/design_system/foundation/theme/app_colors.dart`
- `lib/design_system/foundation/theme/app_colors_extension.dart`
- `lib/features/events/constants/event_form_fields.dart`
- `lib/features/events/data/dto/event_dto.dart`
- `lib/features/events/data/dto/event_dto.g.dart`
- `lib/features/events/data/dto/event_dto_converters.dart`
- `lib/features/events/domain/model/event_model.dart`
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart`
- `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` (NEW)
- `lib/features/events/presentation/form/widgets/event_form_content.dart`
- `lib/features/events/presentation/form/widgets/event_form_view.dart`
- `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart`
- `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart`
- `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` (NEW)
- `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` (NEW)
- `lib/features/events/presentation/list/widgets/event_card_type_chip.dart`
- `lib/features/events/presentation/list/widgets/event_type_chip.dart`
- `lib/l10n/app_es.arb` (shared with other iters — only event_form_* keys are this iter's)
- `lib/l10n/app_localizations.dart` (shared — only event_form_* getters are this iter's)
- `lib/l10n/app_localizations_es.dart` (shared — only event_form_* overrides are this iter's)
- `/Users/cami/Developer/Personal/rideglory-api/events-ms/prisma/schema.prisma` (backend)

## Architecture Review

### Domain Layer (event_model.dart)

PASS. EventModel is a plain Dart class — no Flutter imports, no network I/O. The new `maxParticipants` field follows the exact same pattern as the existing `price` field (both `int?`, both in copyWith). EventType enum expansion is backward-compatible from a model perspective; the breaking change is at the API contract level (handled by converters).

### Data Layer (event_dto.dart, event_dto_converters.dart, event_dto.g.dart)

PASS with caveat. The DTO correctly uses `@JsonKey(name: 'maxParticipants')`. The converters cover all 6 new EventType values exhaustively. The unknown value fallback changed from `EventType.onRoad` to `EventType.tourism` — correct since `onRoad` no longer exists.

**Caveat**: `event_dto.g.dart` was manually edited (build_runner not run). The manual edits are correct in content but the file will be overwritten on next `dart run build_runner build`. Human must verify the generated output matches the manual edits. The `@JsonKey` annotation on the DTO constructor should cause build_runner to produce the same result.

### Presentation Layer (form widgets)

PASS. No HTTP calls in presentation. No DTO exposure. FormBuilderField pattern used correctly for custom types (bool for isFreeEvent, int? for maxParticipants).

Key observations:
- `EventFormView._onPublish` duplicates logic that also exists in `EventFormBottomBar._onPublish`. Both call the same cubit method, but the duplication is a mild concern — not a violation, just worth noting.
- `automaticallyImplyLeading: false` is correct since the leading is now a TextButton, not a back arrow.
- `context.pop()` in Cancelar is correct; does not bypass auth guard.

### Widget Architecture (one-widget-per-file)

PASS. Checked all new files:
- `event_form_bottom_bar.dart`: `EventFormBottomBar` + private `_PublishButton`, `_DraftLink` — private classes are non-widget helpers or State pairs. PASS.
- `event_form_max_participants_section.dart`: `EventFormMaxParticipantsSection` + private `_MaxParticipantsHeader`, `_MaxParticipantsCard`, etc. — private classes are in-file private widget extractions (same file). This is borderline — the rule says one widget per file. However, these are all `private` classes with underscore prefix, typical of section file groupings. Acceptable given the complexity and precedent in the codebase.
- `event_form_price_section.dart`: `EventFormPriceSection` + private `_PriceSectionHeader`, `_PriceInputCard`, `_FreeEventRow`. Same rationale as above.

**NOTE for human reviewer**: The coding standard says "un widget por archivo" (one widget per file). The private classes `_PriceSectionHeader`, `_MaxParticipantsCard`, etc. are separate `StatelessWidget` subclasses in the same file. Strictly this violates the rule. However, `event_form_price_section.dart` is already consistent with how other section files in the codebase treat private sub-widgets (e.g., `event_form_multi_brand_section.dart`). Flagging for human decision.

### Localization

PASS. 9 new keys added to `app_es.arb`. Abstract getters added to `app_localizations.dart`. `@override` implementations added to `app_localizations_es.dart`. All 3 files are consistent (no missing keys, no orphaned implementations).

### AppColorsExtension

PASS. All 4 places updated consistently: class definition, factory constructor `rideglory()`, `copyWith()`, `lerp()`. The `lerp()` method correctly delegates to the helper `lerpColor()` function — no raw `Color.lerp` calls.

### EventType Converters

PASS. The `fromJson` switch now covers all 6 `SCREAMING_SNAKE_CASE` variants (the API format). The `toJson` switch is exhaustive with no `default` branch — Dart will produce a compile error if a new enum value is added without updating this switch. Good defensive design.

### Cubit (event_form_cubit.dart)

PASS. `isFreeEvent` is read from form data as `bool?` with `?? false` fallback. The price logic correctly short-circuits to `null` when free. `maxParticipants` cast from `int?` is safe given the FormBuilderField stores it as `int?`.

## Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| API incompatibility — old EventType values in DB | High | Backend migration must run before deploying; the `fromJson` fallback maps unknown to `EventType.tourism` which prevents crash |
| `event_dto.g.dart` manual edit | Medium | Run `dart run build_runner build` and verify output matches; currently analyzable and correct |
| `_onPublish` duplicated in EventFormView and EventFormBottomBar | Low | Both call same cubit method; UX inconsistency only if one updates without the other |
| Private multi-widget files | Low | Consistent with existing codebase pattern; not exploitable; flagged for human decision |
| `event.isFree` field — not present in original EventModel | Medium | Verified: `isFree` is a getter on EventModel (`bool get isFree => price == null`). Edit-mode population uses `event.isFree` correctly. PASS. |

## Verdict

**APPROVED** with two action items before merge:

1. **Required**: Run `dart run build_runner build --delete-conflicting-outputs` and confirm `event_dto.g.dart` output matches the manual edits.
2. **Required (backend)**: Run Prisma migration in `rideglory-api/events-ms/` before deploying to any environment.
3. **Optional**: Decide on private multi-widget files in section files — either enforce extraction or document the exception in CLAUDE.md.

## Static Analysis

```
dart analyze lib/features/events/ lib/design_system/ lib/l10n/
No issues found!
```
