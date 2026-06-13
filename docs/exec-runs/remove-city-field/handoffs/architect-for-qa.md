> Slim handoff — read this before docs/exec-runs/remove-city-field/handoffs/architect.md

# QA handoff — remove-city-field

**Date:** 2026-06-11T21:55:31Z
**Version:** v2 (corrección post-auditor Opus)

## Test files to update (Flutter)

| File | Change |
|------|--------|
| `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart` | Remove `city:` from all `AiDescriptionRequest(...)` constructors |
| `test/features/events/data/repository/ai_description_repository_impl_test.dart` | Remove `city: 'Bogotá'` from mock `AiDescriptionRequest` |
| `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` | Remove `city: 'Medellín'` from mock `EventModel` factory |
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | Remove TC-2-3 (city filter forwards to backend) and TC-2-10 (hasFilters with city); remove all `city:` named args from `EventFilters(...)` and `EventModel(...)` mocks |
| `test/features/home/presentation/cubit/home_cubit_test.dart` | Remove `city: 'Medellín'` from mock `EventModel` |
| `test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart` | Remove `city: 'Medellín'` from mock `EventModel` |
| `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` | Remove city-related test cases; remove `city: any(named: 'city')` verifications; update AC18 |
| `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart` | Remove `city: 'Medellín'` from mock `EventModel` (line 22) |
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | Remove `city:` from all mock `AiDescriptionRequest` / `EventModel` instances (lines 115, 143, 190, 220, 256, 292) |
| `test/features/events/presentation/detail/cubit/event_detail_cubit_test.dart` | Remove `city: 'Medellín'` from mock `EventModel` (line 69) |
| `test/features/events/presentation/list/events_cubit_analytics_test.dart` | Remove `city:` from all mock `EventModel` and `EventFilters` instances (lines 35, 63, 130, 144, 183) |
| `test/features/events/presentation/list/widgets/events_page_view_test.dart` | Remove `city: 'Medellín'` from all `EventFilters(...)` instances (lines 86, 132, 157) |
| `test/features/events/presentation/form/cubit/event_form_auditor_tests_test.dart` | **Delete the entire `group('AC-6: city == "" ...')` block** (lines ~113-187). See note below. |

**Note on `event_form_auditor_tests_test.dart` AC-6:**  
The AC-6 group tests that `buildEventToSave()` / `buildDraftToSave()` produce `city == ''`. Once `city` is removed from `EventModel`, the assertions `event.city` and `draft!.city` do not compile. The invariant they protected (don't read city from the form) is also gone. **Delete the group entirely.** The rest of the file (other AC groups) is unaffected.

## Run commands after changes

```bash
# Flutter
flutter test
dart analyze lib/
# Both must pass with zero issues

# Backend (in each MS)
cd /Users/cami/Developer/Personal/rideglory-api/events-ms && npm test
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway && npm test
```

## Acceptance criteria traceability

| AC | Check |
|----|-------|
| AC1 — no `.city` in events lib | `grep -rn "\.city" lib/features/events/ --include="*.dart" \| grep -v ".g.dart\|.freezed.dart"` → empty |
| AC1b — no `.city` in event_registration | `grep -rn "\.city" lib/features/event_registration/ --include="*.dart"` → empty |
| AC2 — no city in Prisma schema | `grep -rn "city" rideglory-api/events-ms/prisma/schema.prisma` → empty |
| AC3 — no city in contracts | `grep -rn "city" rideglory-api/rideglory-contracts/src/events/ rideglory-api/rideglory-contracts/src/ai/` → empty |
| AC4 — backend compiles | `tsc --noEmit` or `nest build` passes in events-ms and api-gateway |
| AC5 — dart analyze clean | `dart analyze lib/` → "No issues found" |
| AC6 — flutter test green | `flutter test` → all tests pass |
| AC7 — no AppCityAutocomplete in events form | `grep -rn "AppCityAutocomplete" lib/features/events/presentation/` → empty |
| AC8 — no EventFormFields.city | `grep -rn "EventFormFields.city\|EventFilterFormFields.city" lib/` → empty |
| AC9 — no broken references | App loads event form and events list without runtime errors |
| AC10 — gemini service clean | `grep -rn "city" rideglory-api/api-gateway/src/ai/gemini.service.ts` → empty |
| AC11 — dead widget deleted | `grep -rn "EventCardDateAndCity" lib/ --include="*.dart"` → empty |

## Non-regression checks

- Event registration wizard still shows city autocomplete (different feature, `AppCityAutocomplete` in shared/widgets must NOT be deleted)
- `meetingPoint` field still present in EventModel and rendered in event cards
- Event form create/edit/draft flows complete without errors
- `inscription_card.dart` compiles and renders without city block (location row simply absent)

> Full detail: docs/exec-runs/remove-city-field/handoffs/architect.md
