# § 1 Title

Event Creation Fixes: Autocomplete, Custom Routes, Cupos Stepper, and Draft Support

---

# § 2 Goal

Fix the disabled Mapbox autocomplete inputs in event creation, add a custom multi-waypoint route builder on the map, allow manual typing on the cupos stepper, and introduce draft events that are only visible to the creator until explicitly published.

---

# § 3 Type & Severity

- **Type:** improvement (autocomplete fix, cupos stepper) + feature_addition (custom routes, draft support)
- **Severity:** high — autocomplete is currently stubbed out (`enabled: false`), making location fields completely non-functional for users; drafts unlock a new authoring workflow

---

# § 4 Affected Areas

| Area | Current file path | Current state | Proposed change |
|---|---|---|---|
| `AppPlaceAutocompleteField` | `lib/shared/widgets/form/app_place_autocomplete.dart` | Widget is disabled — `enabled: false`, hint shows "Próximamente disponible", `PlaceService.autocomplete` is never called | Activate the field: debounce-search via `PlaceService.autocomplete`, show suggestions overlay, let user select a result and populate the form field |
| Event form locations section | `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` | Uses `AppPlaceAutocompleteField` for meeting point and destination; no waypoints concept exists | Add a `RouteTypeSelector` (simple A→B vs. custom) and, when custom is chosen, show a `CustomRouteBuilder` widget for up to 9 intermediate waypoints |
| Event form cubit | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | `buildEventToSave()` reads two location fields; no draft concept; `saveEvent()` always publishes immediately | Add `saveDraft()` path that creates event with state `EventState.draft`; add `publishDraft()` to transition from draft to scheduled; carry `waypoints` list in form state |
| `EventFormFields` constants | `lib/features/events/constants/event_form_fields.dart` | Has `meetingPoint`, `destination`, `maxParticipants`, etc. | Add `routeType`, `waypoints` constants |
| Max participants stepper | `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | Stepper only allows `+5`/`-5` button taps; no manual keyboard input | Allow direct text entry on the count display; validate: integer, 5–500, multiples of 5 optional |
| `EventModel` (domain) | `lib/features/events/domain/model/event_model.dart` | `EventState` enum has `scheduled`, `inProgress`, `cancelled`, `finished`; no `draft`; no `waypoints` field | Add `draft` to `EventState` enum; add `List<String> waypoints` field (ordered, up to 9 items) |
| `EventDto` (data) | `lib/features/events/data/dto/event_dto.dart` | Serializes all `EventModel` fields; no `waypoints`, no draft state | Add `waypoints` JSON field; `EventStateConverter` must handle `DRAFT` |
| `EventService` (Retrofit) | `lib/features/events/data/service/event_service.dart` | Exposes `createEvent`, `updateEvent`; no draft-specific endpoint | Add `publishEvent(id)` → `PATCH /api/events/{id}/publish` |
| `EventRepository` interface | `lib/features/events/domain/repository/event_repository.dart` | Declares `createEvent`, `updateEvent`, `getMyEvents` | Add `saveDraftEvent(EventModel)` and `publishEvent(String id)` |
| `EventRepositoryImpl` | `lib/features/events/data/repository/event_repository_impl.dart` | Implements current repository | Implement `saveDraftEvent` and `publishEvent` |
| `GetMyEventsUseCase` | `lib/features/events/domain/use_cases/get_my_events_use_case.dart` | Returns all events for the authenticated user | No change needed — drafts are owned events and must appear in this list |
| `EventsCubit` (my events view) | `lib/features/events/presentation/list/events_cubit.dart` | `EventsCubit.myEvents` shows all owner events; no draft badge logic | Draft events appear in the list; a `Borrador` badge is rendered via `EventCardMyEventBadge` (already exists) |
| Events list page | `lib/features/events/presentation/list/events_page.dart` | Has `showMyEvents` flag; no drafts section | No structural change — drafts appear mixed in "Mis eventos" with badge |
| "Mis borradores" section | Does not exist | N/A | New page/widget `MyDraftsPage` (or a tab/section within `EventsPage`) listing only `draft` events for the creator; accessible from profile or events screen |
| `EventCardMyEventBadge` widget | `lib/features/events/presentation/list/widgets/event_card_my_event_badge.dart` | Shows a badge on organizer's own events | Extend to show a distinct "Borrador" badge variant when `event.state == EventState.draft` |
| Backend — `EventState` enum | `rideglory-api/rideglory-contracts/src/events/enums/event.enums.ts` | `SCHEDULED`, `IN_PROGRESS`, `CANCELLED`, `FINISHED` | Add `DRAFT = 'DRAFT'` |
| Backend — Prisma schema | `rideglory-api/events-ms/prisma/schema.prisma` | `EventState` enum has 4 values; `Event` model has no `waypoints` | Add `DRAFT` to `EventState`; add `waypoints String[]` field on `Event` model; generate migration |
| Backend — events service | `rideglory-api/events-ms/src/events/events.service.ts` | `findAll` returns all events; `findByOwnerId` returns all owner events; no draft filtering | `findAll` must exclude `DRAFT` events (only visible to owner); `findByOwnerId` includes `DRAFT`; new `publishEvent(id, ownerId)` method to transition `DRAFT → SCHEDULED` |
| Backend — events controller | `rideglory-api/events-ms/src/events/events.controller.ts` | No `publishEvent` pattern | Add `@MessagePattern('publishEvent')` handler |
| Backend — API gateway events route | `rideglory-api/api-gateway/src/events/` | Existing CRUD routes | Add `PATCH /api/events/:id/publish` route forwarding `publishEvent` to events-ms |

---

# § 5 Out of Scope

- Scheduled/timed publish (drafts publish immediately on user action — no future scheduling)
- Draft sharing with other users (drafts are private to the creator until published)
- Offline draft storage (drafts are server-side only)
- Waypoint reordering after adding (add/remove only for MVP; drag-to-reorder is post-MVP)
- Route polyline rendering in the custom route builder (waypoints define stops; the Mapbox preview shows markers at each waypoint but no polyline — polyline already handled by iter-3 `routeGeoJson`)
- Changes to the `RouteMapPreview` geocoding logic (already correct after iter-3)
- Push notifications for draft creation or publication
- Draft events appearing in public event discovery (`findAll` excludes drafts)

---

# § 6 Acceptance Criteria

1. **AC-1 — Autocomplete enabled:** When the user types 3 or more characters in the meeting point or destination field, a dropdown of suggestions appears within 600 ms (debounced 400 ms + network latency). Suggestions come from `PlaceService.autocomplete`. Selecting a suggestion populates the field with the place name.

2. **AC-2 — Autocomplete loading/empty states:** While suggestions are loading, a spinner is visible inside the field. If no suggestions are returned, an "No se encontraron resultados" message is shown in the dropdown. If `PlaceService.autocomplete` throws, the dropdown shows a generic error message and does not crash.

3. **AC-3 — Route type selector:** The location section has a clearly visible selector letting the organizer choose between "Ruta simple (A→B)" and "Ruta personalizada". Default is simple A→B (current behavior unchanged).

4. **AC-4 — Custom route waypoints:** When "Ruta personalizada" is selected, a waypoints section appears. The organizer can add up to 9 intermediate waypoints (each is a place autocomplete search). Each added waypoint appears as a labeled card with a delete button. The "Agregar punto" button is disabled/hidden when 9 waypoints are present. Waypoints are ordered by insertion.

5. **AC-5 — Waypoints stored:** `EventModel.waypoints` holds an ordered `List<String>` of place names. The form cubit passes the waypoints list through `buildEventToSave()`. The backend `Event` model stores `waypoints String[]`.

6. **AC-6 — Cupos manual input:** The max participants stepper allows the user to tap the count display and enter a number directly from the keyboard. The entered value is validated to be an integer between 5 and 500 inclusive. Out-of-range or non-numeric entries revert to the previous valid value on focus loss.

7. **AC-7 — Draft creation:** The event form has a "Guardar borrador" secondary action (in addition to the primary publish action). Tapping it saves the event with `state = draft` via a new use case `SaveDraftEventUseCase`. The form fields are not validated as strictly (only `name` is required to save a draft).

8. **AC-8 — Draft visibility — "Mis eventos":** Drafts appear in the "Mis eventos" list (returned by `GET /api/events/me`). Each draft card shows a "Borrador" badge (orange outline badge, distinct from the existing "Mi evento" badge) using `EventCardMyEventBadge`.

9. **AC-9 — Draft visibility — "Mis borradores":** A dedicated "Mis borradores" section/page exists, showing only the creator's draft events. It is accessible from the profile page or a clearly labelled entry in the events section.

10. **AC-10 — Draft NOT visible to others:** Draft events do NOT appear in the public events list (`GET /api/events`). Non-owner users who know the event ID and call `GET /api/events/:id` receive a 404 (or 403). Only the owner can view a draft.

11. **AC-11 — Publish draft:** The event detail page for a draft event (visible only to the owner) has a "Publicar" primary CTA. Tapping it immediately transitions the event from `draft` to `scheduled` via `PATCH /api/events/:id/publish`. The UI reflects the new state immediately (optimistic update acceptable). Once published, the event appears in the public discovery feed.

12. **AC-12 — Edit draft:** The owner can edit a draft event (all fields editable, same form as create). Saving changes updates the draft. The "Publicar" action is also available from within the edit form.

13. **AC-13 — dart analyze:** `dart analyze` passes with zero new errors or warnings after all changes.

14. **AC-14 — app_es.arb:** All new user-visible strings are added to `lib/l10n/app_es.arb` with correct feature prefix keys (`event_`, `route_`). No hardcoded Spanish string literals in UI widgets.

15. **AC-15 — Design match:** All new UI components (route type selector, waypoint cards, cupos manual entry, draft badge, "Mis borradores" section, "Publicar" CTA) match the Pencil designs produced by the Design phase. The `rideglory.pen` file must be updated before frontend implementation begins.

---

# § 7 Regression Guardrails

- **Simple A→B flow unchanged:** Existing event creation using only meeting point and destination (no waypoints) continues to work exactly as before. No form breakage on current events.
- **RouteMapPreview unchanged:** The existing `RouteMapPreview` widget (iter-3) continues to geocode and render meeting point / destination markers correctly after autocomplete is activated.
- **AI cover generation preserved:** The `CoverPreviewWidget` and `generateCover` flow in `EventFormCubit` remain untouched.
- **Existing EventState values:** `scheduled`, `inProgress`, `cancelled`, `finished` continue to work in both Flutter and backend code — adding `draft` is strictly additive.
- **flutter test pass:** All 47 currently passing tests must continue to pass.
- **getMyEvents flow:** Existing "Mis eventos" page loads and displays non-draft events correctly; existing cubit/use case/repository chain is not broken.
- **Autocomplete field contract:** The existing `AppCityAutocompleteField` (city search in filters) is a different widget and must not be affected.
- **Backend findAll filters:** Existing query filters (type, dateFrom, dateTo, city) continue to work. Drafts exclusion is additive (`where: { state: { not: 'DRAFT' } }`).
- **No existing tests broken:** Any test that instantiates `EventFormMaxParticipantsSection` must still pass; tests for `AppPlaceAutocompleteField` must be updated or added.

---

# § 8 Implementation Notes

### Autocomplete Widget
- `AppPlaceAutocompleteField` must become a `StatefulWidget` (it is currently `StatelessWidget`).
- Use a debounce of 400 ms before calling `PlaceService.autocomplete`.
- Use Flutter's `Autocomplete<String>` or a custom overlay with `OverlayPortal` / `LayerLink` to show suggestions.
- `PlaceService` is already injectable (`@singleton`); inject it in the widget or via a dedicated cubit/notifier (preferred for testability).
- The `PlaceAutocompleteType` enum already maps to the correct `type` query param.

### Custom Route Builder
- New widget: `CustomRouteBuilderSection` (its own file, one class per file rule).
- Each waypoint entry is a `WaypointItemCard` (separate file).
- The waypoints list is stored in `EventFormCubit` state (add `List<String> waypoints` to `EventFormState`).
- The route type (simple vs. custom) is a `FormBuilderField<RouteType>` keyed by `EventFormFields.routeType`.
- On form submit, if `routeType == simple`, `waypoints = []`; if custom, use the cubit's waypoints list.

### Cupos Manual Entry
- Change `_MaxParticipantsStepper` to show a `TextFormField` (wrapped in `AppTextField` style or a bare styled field) instead of a static `Text` for the count.
- The field type is `int?`; show '—' placeholder when null (as today).
- On first tap, activate at min value (5) if currently null.
- Validate on `onEditingComplete` / `onFocusLost`: clamp to [5, 500].

### Draft Support — Flutter
- Add `EventState.draft` to the enum in `event_model.dart`.
- Add `EventStateConverter` case for `'DRAFT'` in `event_dto_converters.dart`.
- Add `SaveDraftEventUseCase` and `PublishEventUseCase` in domain.
- `EventFormCubit.saveDraft()` → calls `SaveDraftEventUseCase` with minimal validation (name only).
- `EventFormCubit.publishEvent(String id)` → calls `PublishEventUseCase`.
- `EventsCubit` already handles the list; drafts are included in `getMyEvents` result. No structural cubit change required.
- Draft badge: extend `EventCardMyEventBadge` with a `isDraft` flag that renders a different color/label.

### Draft Support — Backend
- Add `DRAFT` to `EventState` enum in `rideglory-contracts/src/events/enums/event.enums.ts`.
- Add `DRAFT` to Prisma `EventState` enum in `events-ms/prisma/schema.prisma`. Run `prisma migrate dev`.
- Add `waypoints String[]` to Prisma `Event` model. Run `prisma migrate dev` (or combine in one migration).
- `findAll` where clause: add `state: { not: EventState.DRAFT }`.
- `findOne` must check: if `event.state === EventState.DRAFT && event.ownerId !== authUserId` → throw 403 Forbidden. Note: `findOne` currently does not receive `authUserId` — this needs to be threaded through (payload change in controller + gateway).
- `publishEvent(id, ownerId)`: find event, verify owner, verify state is DRAFT, update to SCHEDULED.
- New `@MessagePattern('publishEvent')` in controller.
- New `PATCH /api/events/:id/publish` in api-gateway events routes (authenticated, owner-only guard).
- `CreateEventDto` already has `state: EventState = EventState.SCHEDULED` — no change required; client sends `state: 'DRAFT'` explicitly for drafts.

### Waypoints contract
- `waypoints: String[]` on `CreateEventDto` and `UpdateEventDto` in contracts.
- `waypoints` is ordered; index 0 is the first intermediate stop after the meeting point.

---

# § 9 Open Questions

1. **"Mis borradores" placement:** Should this be a tab within "Mis eventos" (EventsPage) or a separate page accessible from the profile? The SOURCE_PRD says "both sections" but does not specify the navigation entry point for "Mis borradores" as a standalone section. Design phase must decide.

2. **Draft findOne auth guard:** The current `findOne` RPC message does not carry `authUserId`. Passing it through requires changing the RPC payload shape in the api-gateway events proxy. Architect must confirm the safest way to thread auth context through the microservice without breaking existing callers.

3. **Waypoints in RouteMapPreview:** Should the custom route builder's waypoints be shown as markers on the embedded `RouteMapPreview` in the form? The SOURCE_PRD does not mention this explicitly. Assumed: yes (markers only, no polyline) — architect/design to confirm.

4. **Cupos stepper — multiples of 5 only?** The current stepper enforces steps of 5. With free-form input, should the constraint be "any integer 5–500" or "must be a multiple of 5"? The SOURCE_PRD says "+5/-5 increments OR manual typing" — assumed free integer in range.

5. **Draft publish endpoint name:** `PATCH /api/events/:id/publish` — confirm this does not conflict with any existing route in api-gateway.
