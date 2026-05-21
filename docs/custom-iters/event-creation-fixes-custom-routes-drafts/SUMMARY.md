# Summary — event-creation-fixes-custom-routes-drafts

## Goal

Fix the disabled Mapbox autocomplete inputs in event creation, add a custom multi-waypoint route builder on the map, allow manual typing on the cupos stepper, and introduce draft events that are only visible to the creator until explicitly published.

---

## What changed

### Flutter (frontend)

**Autocomplete fix**
- `AppPlaceAutocompleteField` fully rewritten as `StatefulWidget` with 400ms debounce, `OverlayPortal`+`LayerLink` dropdown, loading spinner, empty and error states.
- `AppPlaceSuggestionsDropdown` extracted to its own file (1 widget per file rule).
- 2 l10n keys added to `app_es.arb`: `route_placeSearchError`, `route_noPlacesFound`.

**Cupos stepper manual input**
- `event_form_max_participants_section.dart` stepper promoted to `StatefulWidget` with inline `TextField`.
- Value clamped to [5, 500] on focus loss; non-numeric input reverts to previous valid value.

**Custom route builder**
- `EventRouteTypeSelector`: segmented "Ruta simple" / "Ruta personalizada" control (new file).
- `CustomRouteBuilderSection`: waypoint list with counter, limit banner at 9, search field, empty hint (new file, with 4 extracted sub-widgets in own files: `WaypointCounter`, `WaypointLimitBanner`, `WaypointSearchField`, `WaypointsEmptyHint`).
- `WaypointItemCard`: single waypoint row with number badge and delete icon (new file).
- `EventFormLocationsSection` updated to show route type selector and custom route builder when custom is active.
- `EventFormCubit` gains `waypoints`/`routeType` in `EventFormState`; `addWaypoint`, `removeWaypoint`, `clearWaypoints`; `buildDraftToSave`; `saveDraft`.
- `EventFormFields` constants: `routeType`, `waypoints` added; `RouteType` enum co-located.

**Draft support**
- `EventState.draft` added to domain enum and `EventStateConverter`.
- `waypoints List<String>` field added to `EventModel` and `EventDto`.
- `PublishEventUseCase` (new injectable use case).
- `publishEvent` Retrofit method added to `EventService` (`PATCH /events/{id}/publish`).
- `EventRepository.publishEvent` interface + `EventRepositoryImpl` implementation.
- `EventDetailCubit.publishEvent()` method added; `PublishEventUseCase` injected.
- `EventDetailOwnerLifecycleBar` gains `_OwnerDraftBar` widget: full-width orange "Publicar evento" CTA.
- `EventCardDraftBadge` extracted to its own file; orange-outline "Borrador" badge.
- `event_card.dart`, `event_detail_view.dart`, `event_detail_header_info.dart`, `home_event_card.dart` all updated with exhaustive `EventState.draft` switch cases.
- `MyDraftsPage` (new page, `/events/drafts` route) registered in `app_router.dart` and `app_routes.dart`.
- Profile menu entry "Mis borradores" added to `profile_actions_list.dart`.
- `event_form_bottom_bar.dart` `_DraftLink.onTap` wired to `cubit.saveDraft(...)`.
- 27 new l10n strings in `app_es.arb` (`event_draftBadge`, `draft_*`, `route_*`).

### Backend (rideglory-api)

- `rideglory-contracts/src/events/enums/event.enums.ts`: `DRAFT = 'DRAFT'` added to `EventState`.
- `rideglory-contracts/src/events/dto/create-event.dto.ts`: `waypoints?: string[]` field added.
- `events-ms/prisma/schema.prisma`: `DRAFT` added to `EventState` enum; `waypoints String[] @default([])` added to `Event` model.
- `events-ms/prisma/migrations/20260520220000_draft_state_and_waypoints/migration.sql`: idempotent migration (`IF NOT EXISTS` guards).
- `events-ms/src/events/events.service.ts`: `findAll` and `findUpcoming` exclude `DRAFT`; new `findOneEventForViewer` (404 for non-owner drafts); new `publishEvent` (ownership + state guards, transitions DRAFT to SCHEDULED).
- `events-ms/src/events/events.controller.ts`: `@MessagePattern` handlers for `findOneEventForViewer` and `publishEvent`.
- `api-gateway/src/events/events.controller.ts`: `PATCH :id/publish` (authenticated); `GET :id` now auth-aware (calls `findOneEventForViewer`).
- 7 new unit tests (TC-3-12 through TC-3-18).

### Design (rideglory.pen)

- 8 screens designed in event-creation-v2.pen: autocomplete all states, RouteTypeSelector, CustomRouteBuilder (4 states), cupos stepper states, EventFormBottomBar draft sheet, MyDraftsPage, EventCardMyEventBadge variants, EventDetail draft owner view.
- 4 Custom Route Builder frames added directly to `rideglory.pen`: empty state, 3-waypoint state, 9/9 limit state, active search state.

---

## Files modified

```
ios/Runner.xcodeproj/project.pbxproj                                                    | 186 +-
ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme                             |  11 +
lib/core/http/api_base_url_resolver.dart                                                |   4 +-
lib/features/events/constants/event_form_fields.dart                                    |   4 +
lib/features/events/data/dto/event_dto.dart                                             |   2 +
lib/features/events/data/dto/event_dto_converters.dart                                  |  19 +-
lib/features/events/data/repository/event_repository_impl.dart                         |   9 +
lib/features/events/data/service/event_service.dart                                    |   3 +
lib/features/events/domain/model/event_model.dart                                      |   5 +
lib/features/events/domain/repository/event_repository.dart                            |   2 +
lib/features/events/presentation/detail/cubit/event_detail_cubit.dart                  |  27 +
lib/features/events/presentation/detail/event_detail_by_id_page.dart                   |   2 +
lib/features/events/presentation/detail/event_detail_page.dart                         |   2 +
lib/features/events/presentation/detail/event_detail_view.dart                         |   8 +-
lib/features/events/presentation/detail/widgets/event_detail_header_info.dart          |  17 +-
lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart  |  61 +
lib/features/events/presentation/form/cubit/event_form_cubit.dart                      | 127 +-
lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart               |  18 +-
lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart | 34 +
lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart | 101 +-
lib/features/events/presentation/list/widgets/event_card.dart                          |   2 +
lib/features/home/presentation/widgets/home_event_card.dart                            |   1 +
lib/features/profile/presentation/widgets/profile_actions_list.dart                    |   6 +
lib/l10n/app_es.arb                                                                    |  39 +-
lib/l10n/app_localizations.dart                                                        | 168 +
lib/l10n/app_localizations_es.dart                                                     |  90 +
lib/shared/router/app_router.dart                                                      |   6 +
lib/shared/router/app_routes.dart                                                      |   1 +
lib/shared/widgets/form/app_place_autocomplete.dart                                    | 239 +-
rideglory.pen                                                                          | 4307 ++++++++++++++++----
30 files changed, 4753 insertions(+), 748 deletions(-)
```

---

## Tests

- Flutter: 96 passed (baseline was 47 before this iteration), 1 pre-existing failure (`auth_cubit_test.dart` — unrelated, file not touched).
- Backend: 26 passed (baseline was 19), 0 failures.
- dart analyze: 0 new errors or warnings; 2 pre-existing issues in `api_base_url_resolver.dart`.

---

## Risks / regression watchlist

| Risk | Assessment |
|------|-----------|
| Existing EventState values broken | Low — `EventStateConverter` exhaustive across all 5 values; all tests pass |
| AppCityAutocompleteField regression | Low — separate class, separate file, not touched |
| Route simple flow broken | Low — `routeType==simple` forces `waypoints=[]`; RouteMapPreview tests pass |
| Backend findAll exposing drafts | Resolved — `state: { not: 'DRAFT' }` guard in `findAll` and `findUpcoming` |
| Draft findOne auth bypass | Resolved — `findOneEventForViewer` RPC checks ownership |
| Accepted low-severity finding | `Widget _buildContainer(...)` in `app_place_suggestions_dropdown.dart` — accepted by Tech Lead, does not block merge |

---

## Human action required before deploying

1. Apply Prisma migration in events-ms:
   ```bash
   cd /Users/cami/Developer/Personal/rideglory-api/events-ms
   npx prisma migrate deploy && npx prisma generate
   ```
2. Rebuild contracts package:
   ```bash
   cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
   npm run build
   ```
3. Restart backend services (events-ms and api-gateway).
4. Run manual smoke tests M-1 through M-23 from `REVIEW_CHECKLIST.md`.

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

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## Workspace files

`docs/custom-iters/event-creation-fixes-custom-routes-drafts/` should be committed alongside the code changes as the analysis trail.
