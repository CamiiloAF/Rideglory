> Slim handoff — read this before docs/exec-runs/remove-city-field/handoffs/architect.md

# Frontend handoff — remove-city-field

**Date:** 2026-06-11T21:55:31Z
**Version:** v2 (corrección post-auditor Opus)

## Critical constraint: AppCityAutocomplete is NOT deleted

`lib/shared/widgets/form/app_city_autocomplete.dart` stays — it's used by
`event_registration/presentation/wizard/steps/registration_personal_step.dart`.
Only its usage in **events/form** is removed.

## Domain layer

| File | Change |
|------|--------|
| `lib/features/events/domain/model/event_model.dart` | Remove `city` field + constructor param + copyWith param/body |
| `lib/features/events/domain/model/ai_description_request.dart` | Remove `required this.city` field + constructor param |
| `lib/features/events/domain/repository/event_repository.dart` | Remove `String? city` param from `getEvents()` |
| `lib/features/events/domain/use_cases/get_events_use_case.dart` | Remove `String? city` param + `city: city` call |
| `lib/features/events/domain/use_cases/generate_event_description_use_case.dart` | Remove `city: request.city` in trimmedRequest construction |

## Data layer

| File | Change |
|------|--------|
| `lib/features/events/data/dto/event_dto.dart` | Remove `required super.city` in constructor + `city: city` in `EventModelExtension.toJson()` |
| `lib/features/events/data/dto/ai_event_context_dto.dart` | Remove `city` field, constructor param, `city: request.city` in `fromDomain()` |
| `lib/features/events/data/service/event_service.dart` | Remove `@Query('city') String? city` from `getEvents()` |
| `lib/features/events/data/repository/event_repository_impl.dart` | Remove `String? city` param + `city: city` argument |

## Presentation layer — form

| File | Change |
|------|--------|
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | Remove the `city: ''` named arg in EventModel constructors in `buildEventToSave()` and `buildDraftToSave()` |
| `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` | Remove `required String city` from `sendMessage()` and `retryLastMessage()` signatures; remove `city: city` in `AiDescriptionRequest(...)` |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_description_chat_page.dart` | Remove `city: eventContext.city` from both `sendMessage` and `retryLastMessage` call-sites |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | Remove `EventFormFields.city: event.city` from `_getInitialValues()` edit branch |
| `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart` | Remove `AppCityAutocomplete(...)` widget block; remove `final city = formValues[EventFormFields.city]...` local var; remove `city: city` in `_buildEventContext()` |

## Presentation layer — list/cards

| File | Change |
|------|--------|
| `lib/features/events/presentation/list/events_cubit.dart` | Remove `String? city` from `EventFilters` class + its `hasFilters` check + `copyWith`; remove city from `_fetchFn` signature (both constructors); remove city filter block in `_applyFiltersAndEmit()`; remove city from `_searchQuery` filter block |
| `lib/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart` | Remove ciudad `FilterSectionLabel` + `AppCityAutocomplete` section; remove `city:` from `_clearAll()` and `_apply()` |
| `lib/features/events/presentation/list/widgets/event_card.dart` | Replace `event.city` → `event.meetingPoint` in location row |
| `lib/features/events/presentation/list/widgets/event_card_info_panel.dart` | Replace `event.city` → `event.meetingPoint` |
| `lib/features/events/presentation/list/widgets/event_card_date_and_city.dart` | **DELETE file** — confirmed dead code: zero call-sites in `lib/` (grep returns empty). Do not rename params; just delete. |

## event_registration — CRITICAL (compile blocker)

| File | Change |
|------|--------|
| `lib/features/event_registration/presentation/widgets/inscription_card.dart` | Remove the entire `if (event?.city != null)` block (lines ~190-212 including the Row with `event!.city`). Do NOT replace with `meetingPoint` — PRD does not request it. |

**Why critical:** `inscription_card.dart` references `event!.city` at lines ~190 and ~202. Once `EventModel.city` is removed, the file will not compile. This must be done in the same pass as the domain change.

## Constants and l10n

| File | Change |
|------|--------|
| `lib/features/events/constants/event_form_fields.dart` | Remove `static const String city = 'city'` |
| `lib/features/events/constants/event_filter_form_fields.dart` | Remove `static const String city = 'city'` |
| `lib/l10n/app_es.arb` | Remove keys: `event_eventCity`, `event_eventCityHint`, `event_cityRequired`, `event_filterByCity` |
| `docs/features/events.md` | Remove city from model, form, filters, API contracts sections |

## Code generation

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/
# Both must pass clean
```

If in a worktree/fresh environment: `dart run build_runner build --force-jit --delete-conflicting-outputs`

## Acceptance criteria (grep checks)

```bash
grep -rn "\.city" lib/features/ --include="*.dart" | grep -v ".g.dart\|.freezed.dart"
# → must return empty

grep -rn "EventFormFields.city\|EventFilterFormFields.city" lib/ --include="*.dart"
# → must return empty

grep -rn "AppCityAutocomplete" lib/features/events/ --include="*.dart"
# → must return empty

grep -rn "EventCardDateAndCity" lib/ --include="*.dart"
# → must return empty (file deleted)
```

> Full detail: docs/exec-runs/remove-city-field/handoffs/architect.md
