# Review Checklist — event-creation-fixes-custom-routes-drafts

## Phase chain

1. `po` — Scoped 4 areas: autocomplete activation, custom multi-waypoint routes, cupos stepper manual input, draft event support. Produced 15 ACs, 10 regression guardrails.
2. `architect` — Produced change map (7 backend + 27 frontend files), API contract, Prisma migration plan. Resolved draft findOne auth via separate `findOneEventForViewer` RPC.
3. `backend` — Applied all 5 architect change areas. Tests: 19 → 26 (7 new), all passing.
4. `design` — Designed 8 screens in event-creation-v2.pen: autocomplete states, RouteTypeSelector, CustomRouteBuilder, cupos stepper, EventFormBottomBar draft confirmation, MyDraftsPage, EventCardMyEventBadge variants, EventDetail draft owner view.
5. `design-route-builder` — Added 4 Custom Route Builder frames to rideglory.pen: empty state, 3-waypoint state, 9/9 limit state, active search state.
6. `frontend` — Implemented all 4 areas. Tests: 47 → 69 (all passing). 0 new dart analyze issues.
7. `qa` — Identified BUG-1 (2 hardcoded strings) and BUG-2 (multi-widget-per-file in 3 files). 23 manual probes required. Sign-off: conditional.
8. `tech_lead` (cycle 1) — Verdict: needs_changes. Confirmed BUG-1 and BUG-2; requested extraction of 6 widget classes and fix of 2 l10n strings.
9. `tech_lead` (cycle 2) — Verdict: ready_for_human_review. All cycle 1 blockers resolved. 1 low-severity finding accepted (does not block merge). flutter test: 96 passed.

---

## Pre-flight

- [ ] Run `dart analyze lib/` — expect 0 errors (1 pre-existing `dead_code` warning and 1 `prefer_const_declarations` info in `api_base_url_resolver.dart` are OK)
- [ ] Run `flutter test` — expect 96 passed, 1 pre-existing failure in `auth_cubit_test.dart` (unrelated to this iteration)

---

## Backend checks (human must run)

- [ ] Apply Prisma migration: `cd /Users/cami/Developer/Personal/rideglory-api/events-ms && npx prisma migrate deploy && npx prisma generate`
- [ ] Rebuild contracts package: `cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts && npm run build`
- [ ] Restart backend services (events-ms and api-gateway)
- [ ] Verify `EventState` enum has `DRAFT` value in `rideglory-contracts/src/events/enums/event.enums.ts`
- [ ] Run backend tests: `cd /Users/cami/Developer/Personal/rideglory-api/events-ms && npm test` — expect 26 passed, 0 failed

---

## Manual smoke tests (from qa.md § Manual probes)

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
| M-22 | Create event with "Ruta simple" + submit | `waypoints: []` in API payload; event saved normally |
| M-23 | Load events list with existing SCHEDULED/IN_PROGRESS events | Correct badges and lifecycle bars unchanged |

---

## Acceptance criteria sign-off

| AC | Description | Automated? | Manual probe needed |
|----|-------------|-----------|---------------------|
| AC-1 | Autocomplete fires for 3+ chars, debounced 400ms | No | M-1 |
| AC-2 | Loading spinner, empty state, error state in autocomplete | No | M-2, M-3, M-4 |
| AC-3 | Route type selector visible, default = Ruta simple | No | M-6 |
| AC-4 | Custom route: up to 9 waypoints, add/delete, disable at 9 | No | M-6, M-7, M-8, M-9 |
| AC-5 | Waypoints stored in EventModel, passed through buildEventToSave | No | M-22 |
| AC-6 | Cupos manual input, clamp [5,500], revert non-numeric | No | M-10, M-11, M-12 |
| AC-7 | "Guardar borrador" saves event with state=draft | No | M-13 |
| AC-8 | Draft appears in "Mis eventos" with orange "Borrador" badge | No | M-13, M-14 |
| AC-9 | "Mis borradores" page accessible from profile | No | M-14 |
| AC-10 | Drafts NOT visible to others; GET /api/events excludes drafts | Yes (backend TC-3-14, TC-1–TC-8) | M-18, M-19 |
| AC-11 | "Publicar" CTA transitions draft → SCHEDULED | Partial (backend TC-3-15) | M-15, M-16 |
| AC-12 | Owner can edit draft (all fields editable) | No | Manual |
| AC-13 | dart analyze zero new errors/warnings | Yes — 0 new issues | — |
| AC-14 | All user-visible strings in app_es.arb; no hardcoded strings | Yes (resolved in cycle 2) | — |
| AC-15 | New UI matches Pencil designs | No | Manual visual review |

---

## Regression watchlist (from tech_lead.md)

These items are confirmed low-risk by Tech Lead but require human manual verification:

| Risk | Assessment | Probe |
|------|-----------|-------|
| Existing EventState values broken | Low — `EventStateConverter` exhaustive; all tests pass | M-23 |
| AppCityAutocompleteField regression | Low — separate class in separate file; not modified | M-21 |
| Route simple flow broken | Low — `routeType==simple` sets `waypoints=[]`; RouteMapPreview tests pass | M-22 |
| Hardcoded strings in UI | Resolved — BUG-1 fixed in cycle 2 | AC-14 confirmed |
| Multi-widget-per-file violations | Resolved — BUG-2 fixed in cycle 2 | AC-13 confirmed |

**Accepted low-severity finding (does not block merge):**
- `lib/shared/widgets/form/app_place_suggestions_dropdown.dart:119` — `Widget _buildContainer(...)` is a widget-returning method (pure decoration helper). Accepted by Tech Lead. If a future cleanup sprint runs, extract to a private `_DropdownContainer` widget.

---

## Files changed summary

```
ios/Runner.xcodeproj/project.pbxproj                        | 186 +-
ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme |  11 +
lib/core/http/api_base_url_resolver.dart                    |   4 +-
lib/features/events/constants/event_form_fields.dart        |   4 +
lib/features/events/data/dto/event_dto.dart                 |   2 +
lib/features/events/data/dto/event_dto_converters.dart      |  19 +-
lib/features/events/data/repository/event_repository_impl.dart |  9 +
lib/features/events/data/service/event_service.dart         |   3 +
lib/features/events/domain/model/event_model.dart           |   5 +
lib/features/events/domain/repository/event_repository.dart |   2 +
lib/features/events/presentation/detail/cubit/event_detail_cubit.dart | 27 +
lib/features/events/presentation/detail/event_detail_by_id_page.dart  |  2 +
lib/features/events/presentation/detail/event_detail_page.dart        |  2 +
lib/features/events/presentation/detail/event_detail_view.dart        |  8 +-
lib/features/events/presentation/detail/widgets/event_detail_header_info.dart | 17 +-
lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart | 61 +
lib/features/events/presentation/form/cubit/event_form_cubit.dart      | 127 +-
lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart |  18 +-
lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart | 34 +
lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart | 101 +-
lib/features/events/presentation/list/widgets/event_card.dart          |   2 +
lib/features/home/presentation/widgets/home_event_card.dart            |   1 +
lib/features/profile/presentation/widgets/profile_actions_list.dart    |   6 +
lib/l10n/app_es.arb                                                    |  39 +-
lib/l10n/app_localizations.dart                                        | 168 +
lib/l10n/app_localizations_es.dart                                     |  90 +
lib/shared/router/app_router.dart                                      |   6 +
lib/shared/router/app_routes.dart                                      |   1 +
lib/shared/widgets/form/app_place_autocomplete.dart                    | 239 +-
rideglory.pen                                                          | 4307 ++++++++++++++++----
30 files changed, 4753 insertions(+), 748 deletions(-)
```

New files added (not visible in diff --stat as they appear within totals above):
- `lib/features/events/domain/use_cases/publish_event_use_case.dart`
- `lib/features/events/presentation/form/widgets/sections/event_route_type_selector.dart`
- `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart`
- `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart`
- `lib/features/events/presentation/form/widgets/sections/waypoint_counter.dart`
- `lib/features/events/presentation/form/widgets/sections/waypoint_limit_banner.dart`
- `lib/features/events/presentation/form/widgets/sections/waypoint_search_field.dart`
- `lib/features/events/presentation/form/widgets/sections/waypoints_empty_hint.dart`
- `lib/features/events/presentation/list/widgets/event_card_draft_badge.dart`
- `lib/features/events/presentation/drafts/my_drafts_page.dart`
- `lib/shared/widgets/form/app_place_suggestions_dropdown.dart`

---

## Optional follow-ups (not blocking)

- Extract `Widget _buildContainer(...)` in `app_place_suggestions_dropdown.dart` to a private `_DropdownContainer` widget (accepted low-severity finding from Tech Lead cycle 2).
- Add widget tests for: `AppPlaceAutocompleteField`, `CustomRouteBuilderSection`, `EventFormCubit.saveDraft`, `EventCardDraftBadge`, `EventStateConverter` DRAFT case, `EventDetailCubit.publishEvent`, cupos clamp logic (7 coverage gaps identified by QA).
- Waypoint reordering (drag-to-reorder) — explicitly out of scope for this iteration, post-MVP.
- Route polyline rendering in the custom route builder (out of scope per PRD § 5).
- Scheduled/timed publish — out of scope.
- Push notifications for draft creation or publication — out of scope.
