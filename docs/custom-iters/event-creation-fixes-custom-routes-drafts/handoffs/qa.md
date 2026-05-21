# QA Handoff — event-creation-fixes-custom-routes-drafts

## Test catalog

| AC | Description | Covering test(s) | Status |
|----|-------------|-----------------|--------|
| AC-1 | Autocomplete fires for 3+ chars, debounced 400ms, shows dropdown | **NONE** — no automated test; AppPlaceAutocompleteField rewrite has no widget test | GAP |
| AC-2 | Loading spinner, empty state, error state in autocomplete | **NONE** — no automated test | GAP |
| AC-3 | Route type selector visible, default = Ruta simple | **NONE** — no automated test for EventRouteTypeSelector | GAP |
| AC-4 | Custom route: up to 9 waypoints, add/delete, disable at 9 | **NONE** — no automated test for CustomRouteBuilderSection | GAP |
| AC-5 | Waypoints stored in EventModel, passed through buildEventToSave | **NONE** — no EventFormCubit test for waypoints flow | GAP |
| AC-6 | Cupos manual input, clamp [5,500], revert non-numeric | Existing test file does not cover the new StatefulWidget behavior | GAP |
| AC-7 | "Guardar borrador" saves event with state=draft, name-only required | **NONE** — no test for saveDraft/buildDraftToSave | GAP |
| AC-8 | Draft appears in "Mis eventos" with orange "Borrador" badge | **NONE** — no widget test for EventCardDraftBadge rendering | GAP |
| AC-9 | "Mis borradores" page exists, lists only creator's drafts | **NONE** — no test for MyDraftsPage | GAP |
| AC-10 | Drafts NOT visible to others; GET /api/events excludes drafts | Backend: TC-3-14 (findOneEventForViewer 404 for non-owner); TC-1 through TC-8 assert `state: { not: 'DRAFT' }` in findAll/findUpcoming | PASS (backend) |
| AC-11 | "Publicar" CTA on draft detail transitions to SCHEDULED | Backend: TC-3-15 (publishEvent DRAFT→SCHEDULED); Flutter: no test | PARTIAL |
| AC-12 | Owner can edit draft (all fields editable) | **NONE** — manual only | GAP |
| AC-13 | dart analyze zero new errors/warnings | `dart analyze lib/` — 2 issues, both pre-existing (`api_base_url_resolver.dart`) | PASS |
| AC-14 | All user-visible strings in app_es.arb; no hardcoded strings | **BUG**: `app_place_autocomplete.dart` has 2 hardcoded Spanish strings (see Bugs Found) | FAIL |
| AC-15 | New UI matches Pencil designs | Design phase produced frames; manual verification required | MANUAL |

---

## Regression matrix

| Guardrail | Mechanism | Result |
|-----------|-----------|--------|
| Simple A→B flow unchanged | Manual probe; code inspection: routeType==simple sets waypoints=[] | PASS (code) |
| RouteMapPreview geocoding unchanged | TC-3-6a/b/c/d in `route_map_preview_test.dart` (4 tests, all pass) | PASS |
| AI cover generation preserved | `get_generate_cover_use_case_test.dart` passes; EventFormCubit.saveEvent untouched | PASS |
| Existing EventState values (scheduled/inProgress/cancelled/finished) | EventStateConverter still maps all 4 original values; event_card.dart switch updated; `flutter test` 69/69 pass | PASS |
| flutter test 47+ passing | `flutter test`: **69 passed, 0 failed** (baseline was 47+22 pre-existing; all pass) | PASS |
| getMyEvents flow | EventsCubit unchanged; GetMyEventsUseCase unchanged; drafts included by backend | PASS (code) |
| AppCityAutocompleteField unaffected | Frontend handoff confirms widget not modified; separate class in separate file | PASS |
| Backend findAll filters | TC-1 through TC-8 assert `state: { not: 'DRAFT' }` in all public `where` clauses | PASS |
| No existing tests broken | All 69 tests pass | PASS |

---

## Test execution

### Flutter tests
```
cd /Users/cami/Developer/Personal/Rideglory && flutter test 2>&1 | tail -5
```
**Result: 69 passed, 0 failed. All tests passed.**

### Dart analyze
```
dart analyze lib/ 2>&1
```
**Result: 2 issues found.**
- `warning` — `core/http/api_base_url_resolver.dart:19:57` — `dead_code` (pre-existing dirty file, noted in frontend baseline)
- `info` — `core/http/api_base_url_resolver.dart:17:5` — `prefer_const_declarations` (pre-existing dirty file, noted in frontend baseline)

Zero new errors or warnings introduced by this iteration. Both issues are in a pre-existing dirty file (`lib/core/http/api_base_url_resolver.dart` listed in `preExistingDirtyFiles` in `_meta.json`). **AC-13: PASS.**

### Backend tests
```
cd /Users/cami/Developer/Personal/rideglory-api/events-ms && npm test 2>&1 | tail -5
```
**Result: 26 passed, 0 failed, 2 suites.** (Baseline was 19; 7 new tests added for findOneEventForViewer and publishEvent.)

---

## Bugs found

### BUG-1 (Frontend) — Hardcoded Spanish strings in AppPlaceAutocompleteField
- **File:** `lib/shared/widgets/form/app_place_autocomplete.dart`
- **Lines:** L102 (`'No se pudo cargar sugerencias'`), L363 (`'No se encontraron resultados'`)
- **AC violated:** AC-14 — all user-visible strings must be in `app_es.arb`
- **Severity:** Low (functional, but coding-standards violation)
- **Responsible agent:** Frontend
- **Fix:** Add keys (e.g., `route_noPlacesFound` and `route_placeSearchError`) to `app_es.arb` and replace hardcoded strings with `context.l10n.route_noPlacesFound` / `context.l10n.route_placeSearchError`

### BUG-2 (Frontend) — Multiple public/private widget classes in single files
- **Files and violations:**
  - `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart` — 5 widget classes (`CustomRouteBuilderSection`, `_WaypointCounter`, `_LimitBanner`, `_WaypointSearchField`, `_EmptyWaypointsHint`)
  - `lib/shared/widgets/form/app_place_autocomplete.dart` — 2 widget classes (`AppPlaceAutocompleteField`, `_SuggestionsDropdown`)
  - `lib/features/events/presentation/list/widgets/event_card_my_event_badge.dart` — 2 public widget classes (`EventCardDraftBadge`, `EventCardMyEventBadge`)
- **Note:** `event_detail_owner_lifecycle_bar.dart` (4 classes) and `event_form_max_participants_section.dart` (7 classes) are pre-existing multi-widget files; new classes were added to them rather than new violations created independently.
- **AC violated:** Coding standards ("un widget por archivo")
- **Severity:** Medium (architectural standard violation; tests and compilation unaffected)
- **Responsible agent:** Frontend
- **Fix:** Extract private widget classes into their own files, or confirm with Tech Lead that private `_` classes in the same file as their parent public widget are acceptable (common Flutter pattern)

### NOTE — SaveDraftEventUseCase not created
- PRD § 6 AC-7 and architect handoff specify `SaveDraftEventUseCase` as a new injectable use case. The implementation routes `saveDraft()` through the existing `CreateEventUseCase` with `state: EventState.draft` — functionally equivalent but diverges from the agreed domain design.
- **Not filed as BUG** because the architect handoff (§ Implementation Notes) describes calling `SaveDraftEventUseCase` but the actual implementation decision is within acceptable scope for Tech Lead review.

---

## Manual probes for human

The following AC items have no automated test coverage and require human verification against a running backend:

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

## How to verify

```bash
# Run Flutter tests
cd /Users/cami/Developer/Personal/Rideglory
flutter test

# Run dart analyze
dart analyze lib/

# Run backend tests (events-ms)
cd /Users/cami/Developer/Personal/rideglory-api/events-ms
npm test

# Run dart analyze (expected: 2 pre-existing info/warning in api_base_url_resolver.dart only)
cd /Users/cami/Developer/Personal/Rideglory
dart analyze lib/ 2>&1
```

---

## Sign-off

**conditional**

All automated tests pass (69 Flutter + 26 backend). Zero new `dart analyze` errors or warnings. AC-13 is clean.

**Conditions before merge:**
1. **BUG-1** must be fixed: replace 2 hardcoded Spanish strings in `app_place_autocomplete.dart` with `app_es.arb` keys and `context.l10n` calls (AC-14).
2. **BUG-2** is flagged for Tech Lead review: multi-widget-per-file violations in 3 files. Tech Lead must explicitly accept or request extraction.
3. Human must complete manual probes M-1 through M-23 against a live environment before final approval (no integration tests exist for the new features).
4. Backend migration (`npx prisma migrate deploy`) must be applied to the target environment before any draft/waypoints functionality will work.
