# Architect → QA

## Gate checks
- `dart analyze` — zero new errors/warnings (AC-13). Watch especially for non-exhaustive `switch` warnings on `EventState` — those are the highest-risk regression.
- `flutter test` — all 47 existing tests pass plus new tests below.
- Backend: `events-ms` and `api-gateway` compile (`tsc`); `rideglory-contracts` rebuilt.

## New / updated tests expected
- `AppPlaceAutocompleteField` — debounce fires after 3+ chars; suggestions render; loading spinner; empty "No se encontraron resultados"; error path does not crash; selecting a suggestion updates the FormBuilder field value. Mock `PlaceService` in GetIt.
- `EventFormMaxParticipantsSection` — existing tests must still pass; add: typed value 250 commits; typed 3 reverts to previous on focus loss; typed 999 clamps to 500; non-numeric reverts.
- `EventFormCubit` — `saveDraft()` builds an event with `state == EventState.draft` and only `name` required; `buildEventToSave()` carries `waypoints` for custom route and `[]` for simple; `publishEvent()` calls the use case.
- `CustomRouteBuilderSection` — add up to 9 waypoints; "Agregar punto" disabled/hidden at 9; delete removes the right index.
- `EventStateConverter` — `'DRAFT'` ↔ `EventState.draft` round-trips.
- `event_card_my_event_badge` — `isDraft: true` renders the "Borrador" variant.

## Functional test matrix

### Autocomplete (AC-1,2,3)
1. Type 3+ chars in meeting point → dropdown within ~600 ms.
2. Loading spinner visible during fetch.
3. No results → "No se encontraron resultados".
4. `PlaceService` throws → graceful error message, no crash.
5. Select a suggestion → field populated; `RouteMapPreview` updates marker.

### Custom routes (AC-3,4,5)
6. Route selector visible; default = "Ruta simple".
7. Switch to "Ruta personalizada" → waypoints section appears.
8. Add waypoints; each shows as a card with delete.
9. At 9 waypoints "Agregar punto" disabled/hidden.
10. Save → `EventModel.waypoints` ordered list; DB `Event.waypoints` populated; simple route → `waypoints == []`.

### Cupos (AC-6)
11. Tap count → keyboard input.
12. Enter 250 → accepted.
13. Enter 3 or 999 → reverts/clamps on focus loss.
14. `±5` buttons still work.

### Drafts (AC-7..12)
15. "Guardar borrador" with only `name` filled → saves `state = DRAFT`.
16. Draft appears in "Mis eventos" with orange-outline "Borrador" badge.
17. "Mis borradores" section lists ONLY the creator's drafts.
18. `GET /api/events` (public) → draft NOT present.
19. Non-owner `GET /api/events/:id` on a draft → 404.
20. Owner opens draft detail → "Publicar" CTA present.
21. Tap "Publicar" → `PATCH /api/events/:id/publish` → `state` becomes `SCHEDULED`; UI updates; event now in public feed.
22. Non-owner publish attempt (direct API) → 403; publishing a non-draft → 409.
23. Owner edits a draft → all fields editable; re-save persists.

## Regression guardrails (must NOT break)
- Simple A→B event creation (no waypoints) saves and lists normally.
- `scheduled`/`inProgress`/`cancelled`/`finished` badges + owner lifecycle bars render unchanged.
- `RouteMapPreview` geocoding/markers still correct.
- AI cover generation (`CoverPreviewWidget`/`generateCover`) untouched.
- `AppCityAutocompleteField` (filter city search) unaffected.
- `GET /events` filters (type/date/city) still work; drafts excluded.
- `GET /events/my` includes owner drafts.
- Tracking start/end, registrations, reminder cron still resolve events (`findOneEvent` unchanged).

## Proposed `app_es.arb` keys (verify all present, no hardcoded strings)
- `event_draftBadge` = "Borrador"
- `event_saveDraft` = "Guardar borrador" (already exists — confirm)
- `event_publishDraft` = "Publicar"
- `event_myDrafts` = "Mis borradores"
- `event_myDraftsEmpty` = empty-state copy for the drafts page
- `event_draftSavedSuccess`, `event_eventPublishedSuccess`
- `route_routeType` = "Tipo de ruta"
- `route_routeSimple` = "Ruta simple (A→B)"
- `route_routeCustom` = "Ruta personalizada"
- `route_addWaypoint` = "Agregar punto"
- `route_waypointLabel` / `route_waypointsTitle`
- `route_maxWaypointsReached` (9-limit hint)
- autocomplete: `route_noPlacesFound` = "No se encontraron resultados", `route_placeSearchError` (generic error)
(Final keys/copy come from Design — confirm against `rideglory.pen`.)

## File a BUG task if
- Any `EventState` switch throws / fails to compile.
- A draft is ever visible to a non-owner (list or by-id).
- `waypoints` not persisted or order lost.
- Autocomplete overlay leaks (timer/overlay not disposed) or crashes on rapid typing.
