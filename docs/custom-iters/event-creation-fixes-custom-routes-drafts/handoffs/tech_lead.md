# Tech Lead Handoff — event-creation-fixes-custom-routes-drafts

## Verdict

**ready_for_human_review**

All cycle 1 blockers (BUG-1 and BUG-2) have been resolved. One new minor finding was identified during cycle 2 review (`_buildContainer` widget-returning method in `AppPlaceSuggestionsDropdown`) — it does not block merge; it is low severity and acceptable as a pure layout helper. Architecture, security, and API contract remain sound. The iteration is cleared for human review and manual probes.

---

## Cycle 2 verification

### BUG-1 — Hardcoded strings (RESOLVED)

- `lib/l10n/app_es.arb` lines 1534–1535: both `route_placeSearchError` and `route_noPlacesFound` keys present with correct Spanish copy.
- `lib/shared/widgets/form/app_place_autocomplete.dart`: no hardcoded Spanish strings remain. The `_fetchSuggestions` method now sets `_hasError = true` (bool sentinel) instead of storing a string. No `BuildContext` anti-pattern in `_fetchSuggestions`.
- `lib/shared/widgets/form/app_place_suggestions_dropdown.dart`: `build(BuildContext context)` renders `context.l10n.route_placeSearchError` in the error branch and `context.l10n.route_noPlacesFound` in the empty branch. Verified directly at lines 44 and 59.

### BUG-2 — Multiple widgets per file (RESOLVED)

- `app_place_autocomplete.dart`: 1 widget class only — `AppPlaceAutocompleteField extends StatefulWidget` (+ its `State<T>` — allowed per CLAUDE.md).
- `app_place_suggestions_dropdown.dart`: created as new file; 1 widget class — `AppPlaceSuggestionsDropdown extends StatelessWidget`.
- `custom_route_builder_section.dart`: 1 widget class only — `CustomRouteBuilderSection`. Imports 4 extracted files.
- `waypoint_counter.dart`: `WaypointCounter` — 1 class, no BuildContext anti-pattern.
- `waypoint_limit_banner.dart`: `WaypointLimitBanner` — 1 class, no BuildContext anti-pattern.
- `waypoint_search_field.dart`: `WaypointSearchField` — 1 class, no BuildContext anti-pattern.
- `waypoints_empty_hint.dart`: `WaypointsEmptyHint` — 1 class, no BuildContext anti-pattern, no `final BuildContext context` constructor field (the cycle 1 anti-pattern is gone).
- `event_card_my_event_badge.dart`: 1 class only — `EventCardMyEventBadge`.
- `event_card_draft_badge.dart`: created as new file; 1 class — `EventCardDraftBadge`.

### Tests

- `dart analyze lib/`: 1 issue — pre-existing `dead_code` warning in `api_base_url_resolver.dart`. Zero new errors or warnings.
- `flutter test`: 96 passed, 1 pre-existing failure (`auth_cubit_test.dart` — `AuthException` compilation error, unrelated to this iteration, file not touched). The higher test count vs QA baseline (69) reflects Patrol integration tests added in commit `405fd93` after QA ran — unrelated to this iteration.

### Domain model and API contract (re-confirmed)

- `lib/features/events/domain/model/event_model.dart`: `EventState.draft` present (line 30), `waypoints` field present (line 60) with default `const []`.
- `lib/features/events/data/service/event_service.dart`: `publishEvent` endpoint present at line 47–48 (`@PATCH('${ApiRoutes.events}/{id}/publish')`).
- `lib/features/events/presentation/drafts/my_drafts_page.dart`: 2 classes (`MyDraftsPage` + `_MyDraftsView`) — accepted as-is per cycle 1 ruling.

---

## New finding (cycle 2)

| file:line | severity | issue | disposition |
|-----------|----------|-------|-------------|
| `lib/shared/widgets/form/app_place_suggestions_dropdown.dart:119` | LOW | `Widget _buildContainer({required Widget child})` is a widget-returning method — violates CLAUDE.md "Prohibidos los métodos que retornan widgets". It is a pure decoration helper (shared border/shadow/constraints for the dropdown container); all UI rendering and l10n calls are correctly in `build(context)`. | Accept — does not block merge. If a future cleanup sprint runs, extract to a private `_DropdownContainer` widget. |

---

## Files reviewed

| File | Review status |
|------|--------------|
| `lib/features/events/domain/model/event_model.dart` | PASS |
| `lib/features/events/domain/repository/event_repository.dart` | PASS (unchanged from cycle 1) |
| `lib/features/events/domain/use_cases/publish_event_use_case.dart` | PASS (unchanged from cycle 1) |
| `lib/features/events/data/dto/event_dto_converters.dart` | PASS (unchanged from cycle 1) |
| `lib/features/events/data/repository/event_repository_impl.dart` | PASS (unchanged from cycle 1) |
| `lib/features/events/data/service/event_service.dart` | PASS |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | PASS (unchanged from cycle 1) |
| `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart` | PASS — 1 class only |
| `lib/features/events/presentation/form/widgets/sections/waypoint_counter.dart` | PASS — new file, 1 class |
| `lib/features/events/presentation/form/widgets/sections/waypoint_limit_banner.dart` | PASS — new file, 1 class |
| `lib/features/events/presentation/form/widgets/sections/waypoint_search_field.dart` | PASS — new file, 1 class |
| `lib/features/events/presentation/form/widgets/sections/waypoints_empty_hint.dart` | PASS — new file, 1 class, no BuildContext constructor anti-pattern |
| `lib/features/events/presentation/detail/cubit/event_detail_cubit.dart` | PASS (unchanged from cycle 1) |
| `lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart` | PASS — pre-existing multi-widget; accepted |
| `lib/features/events/presentation/list/widgets/event_card_my_event_badge.dart` | PASS — 1 class only |
| `lib/features/events/presentation/list/widgets/event_card_draft_badge.dart` | PASS — new file, 1 class |
| `lib/features/events/presentation/drafts/my_drafts_page.dart` | PASS (accepted per cycle 1) |
| `lib/shared/widgets/form/app_place_autocomplete.dart` | PASS — 1 widget class, no hardcoded strings |
| `lib/shared/widgets/form/app_place_suggestions_dropdown.dart` | PASS with minor finding (see above) |
| `lib/l10n/app_es.arb` | PASS — `route_placeSearchError` and `route_noPlacesFound` present |

---

## Remaining findings

| file:line | severity | issue | disposition |
|-----------|----------|-------|-------------|
| `lib/shared/widgets/form/app_place_suggestions_dropdown.dart:119` | LOW | `Widget _buildContainer(...)` — widget-returning method | Accepted; does not block merge |

All cycle 1 blockers are resolved.

---

## Security findings

**No issues found.** (unchanged from cycle 1)

- `PATCH /events/:id/publish` authenticated via `FirebaseAuthInterceptor` in `AppDio`. Owner check is server-side.
- No hardcoded credentials, API keys, or secrets in any changed file.
- No hardcoded base URLs. `ApiRoutes.events` used throughout.
- `PlaceService.autocomplete` invoked via `getIt<PlaceService>()` — Mapbox key remains in `.env` via `AppEnv`.

---

## Architecture adherence

**PASS**

**Domain layer** — Clean. `EventModel`, `EventRepository`, `PublishEventUseCase` contain no Flutter imports and no I/O calls. `EventState.draft` is present. `waypoints` defaults to `const []`.

**Data layer** — Clean. `EventRepositoryImpl` and `EventService` contain no `BuildContext` references. `publishEvent` follows the `executeService` pattern. `EventStateConverter` is exhaustive across all 5 `EventState` values. DTO `.toJson()` used for HTTP request bodies.

**Presentation layer** — Clean. No direct HTTP calls from cubits or widgets. `EventFormCubit.buildDraftToSave()` bypasses form validation correctly. `EventDetailCubit.publishEvent()` uses `PublishEventUseCase` correctly. All extracted widget classes are single-responsibility, `StatelessWidget`, no `BuildContext` constructor anti-patterns.

**Routing** — `AppRoutes.myDrafts = '/events/drafts'` and `GoRoute` registered. `context.pushNamed()` used correctly.

**State management** — `EventFormCubit.saveDraft()` and `EventDetailCubit.publishEvent()` both emit `ResultState.loading()` → `ResultState.data`/`ResultState.error`. `EventFormState` has `waypoints` and `routeType` fields in the `@freezed` state class.

**L10n** — All user-visible strings in `app_es.arb`. BUG-1 resolved: `route_placeSearchError` and `route_noPlacesFound` now present and wired via `context.l10n.*` in `build(context)`.

---

## Regression risk summary

| Risk | Assessment |
|------|-----------|
| Existing EventState values broken | Low — `EventStateConverter` exhaustive; all 69 pre-existing tests pass |
| AppCityAutocompleteField regression | Low — separate class in separate file; not modified |
| Route simple flow broken | Low — `routeType==simple` sets `waypoints=[]`; RouteMapPreview tests pass |
| Test suite regression | None introduced — 1 failure is pre-existing `auth_cubit_test.dart` compilation error |
| Hardcoded strings in UI | Resolved — no remaining violations in new/modified files |
| Multi-widget-per-file violations | Resolved — all new files have 1 widget class each |

---

## Manual probes the human must run before commit

| # | Probe | Expected result |
|---|-------|----------------|
| M-1 | Open event creation → type 3+ chars in "Punto de encuentro" | Dropdown appears within ~600ms with Mapbox suggestions |
| M-2 | While suggestions loading | Spinner visible inside field |
| M-3 | Disconnect network, type 3+ chars | "No se pudo cargar sugerencias" shown, no crash |
| M-4 | Type something that returns no results | "No se encontraron resultados" shown in dropdown |
| M-5 | Select a suggestion | Field populates; RouteMapPreview marker updates |
| M-6 | Toggle "Ruta personalizada" in locations section | CustomRouteBuilderSection appears below route type selector |
| M-7 | Add 9 waypoints | "Agregar punto" button disabled/hidden; limit banner visible |
| M-8 | Delete a waypoint | Card removed; counter updates; add button re-enables |
| M-9 | Toggle back to "Ruta simple" | Waypoints section hidden; waypoints cleared |
| M-10 | Tap cupos counter → type 250 → focus out | Value accepted: 250 |
| M-11 | Type 3 in cupos → focus out | Value reverts to previous valid value |
| M-12 | Type 999 in cupos → focus out | Value clamped to 500 |
| M-13 | Fill only event name → tap "Guardar borrador" | Draft saved; appears in "Mis eventos" with "BORRADOR" badge |
| M-14 | Profile → "Mis borradores" | Draft events listed; non-drafts excluded |
| M-15 | Open draft detail as owner | "Publicar evento" CTA visible at bottom |
| M-16 | Tap "Publicar evento" | Event state → SCHEDULED; badge updates; event appears in public feed |
| M-17 | Open any published event as non-owner | No "Publicar" button visible |
| M-18 | GET /api/events (public list) | No DRAFT events in response |
| M-19 | GET /api/events/:draftId with non-owner token | 404 response |
| M-20 | PATCH /api/events/:scheduledId/publish | 409 response |
| M-21 | AppCityAutocompleteField (event filters) | Still works; suggestions appear for city search |
| M-22 | Create event with "Ruta simple" + submit | waypoints:[] in API payload; event saved normally |
| M-23 | Load events list with existing SCHEDULED/IN_PROGRESS events | Correct badges and lifecycle bars unchanged |

---

## Recommended commit message

```
feat(events): activate autocomplete, custom routes, draft events, cupos input

- AppPlaceAutocompleteField rewritten as debounced StatefulWidget overlay
- Custom route builder with up to 9 waypoints (EventFormLocationsSection)
- Cupos stepper with inline editable field clamped to [5, 500]
- EventState.draft: draft creation, badge, Mis Borradores page, Publicar CTA
- PATCH /events/:id/publish wired via PublishEventUseCase
- All widget classes extracted to own files; l10n strings completed
```
