# PO Handoff — event-creation-fixes-custom-routes-drafts

## Goal

Fix the disabled location autocomplete inputs in event creation, add a custom multi-waypoint route builder, allow manual typing on the cupos stepper, and introduce draft events (backend + UI) that are private to the creator until explicitly published.

---

## Source quote

> Fix event creation autocomplete inputs (Mapbox Places), add custom multi-waypoint route creation (tap map + search, max 9 waypoints, user chooses simple A→B or custom), fix cupos input to allow +5/-5 increments or manual typing, add draft support (backend + UI: drafts visible in both a dedicated section and in "Mis eventos" with a tag, only visible to creator until published, publish is immediate). Design must match Pencil exactly.
>
> User clarifications:
> - Custom route UX: Tap on map + search to add waypoints
> - Waypoints limit: Maximum 9 intermediate waypoints
> - Publishing draft: Publishes immediately when creator clicks "Publicar"
> - Drafts UI: Both — separate "Mis borradores" section AND appear in "Mis eventos" with a "Borrador" tag

---

## Interpretation

The note identifies four distinct problems in the event creation flow, three of which are bugs/regressions and one is a new feature:

1. **Autocomplete broken (bug):** `AppPlaceAutocompleteField` is explicitly disabled (`enabled: false`) and shows "Próximamente disponible". The `PlaceService.autocomplete` Retrofit endpoint exists and is ready. This is a missing activation, not a missing backend capability.

2. **Route is always simple A→B (missing feature):** The event form only has meeting point + destination. There is no way to define intermediate waypoints. The `EventModel` has no `waypoints` field. This requires Flutter domain/data/presentation work AND a backend schema change (`waypoints String[]` on the `Event` model).

3. **Cupos stepper only supports button taps (usability bug):** The `EventFormMaxParticipantsSection` stepper widget has no text input — only +5/−5 buttons. Organizers with large events (100, 150, 250 riders) must tap many times to reach their target.

4. **Draft support (new feature):** Events can only be created in "published" state (`SCHEDULED`). There is no way to save a work-in-progress event as private. This requires: a new `DRAFT` state in the contracts enum + Prisma schema, backend filtering changes so drafts are never visible publicly, a new `PATCH /api/events/:id/publish` endpoint, Flutter domain/presentation changes, and new UI in both the form and the events list pages.

---

## Affected areas — current state

| Area | File | Line notes | Current state |
|---|---|---|---|
| `AppPlaceAutocompleteField` | `lib/shared/widgets/form/app_place_autocomplete.dart` | L41: `enabled: false`; L43: `hintText: 'Próximamente disponible'` | Fully stubbed. Widget ignores all props and renders a disabled `AppTextField`. |
| Event form locations section | `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` | L45–74: two `AppPlaceAutocompleteField`s; L80–103: `RouteMapPreview` | A→B only. No route type toggle, no waypoints UI. |
| `EventFormMaxParticipantsSection` | `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | L193: `_StepperButton` uses `GestureDetector`; L207–220: static `Text` for count | No text input. Step is hardcoded to 5 (L22: `_step = 5`). |
| `EventFormCubit` | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | L56: `saveEvent()` — always publishes; L183: `buildEventToSave()` | No draft path. `EventState.scheduled` is hardcoded at L228. |
| `EventFormState` (freezed) | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | L21–26 | Has `saveResult` and `coverGenerationResult`. No `waypoints` field, no draft-specific state. |
| `EventModel` | `lib/features/events/domain/model/event_model.dart` | L29–37: `EventState` enum (4 values); L39–58: class | No `draft` state, no `waypoints` field. |
| `EventDto` | `lib/features/events/data/dto/event_dto.dart` | L12–43 | No `waypoints` field. `EventStateConverter` does not handle `DRAFT`. |
| `EventService` (Retrofit) | `lib/features/events/data/service/event_service.dart` | L15–46 | No `publishEvent` endpoint. |
| `EventRepository` interface | `lib/features/events/domain/repository/event_repository.dart` | L8–28 | No `saveDraftEvent` or `publishEvent` declarations. |
| `PlaceService` | `lib/core/services/place_service.dart` | L15–18: `autocomplete(q, type)` declared and ready | Already functional Retrofit client; backend endpoint exists. Never called from UI. |
| `EventsCubit.myEvents` | `lib/features/events/presentation/list/events_cubit.dart` | L68–74: calls `getMyEventsUseCase()` | Returns all owner events; will include drafts once backend returns them. No structural change needed. |
| `EventCardMyEventBadge` | `lib/features/events/presentation/list/widgets/event_card_my_event_badge.dart` | (exists) | Shows a badge for the event creator. Does not yet have a "Borrador" variant. |
| "Mis borradores" page | N/A | Does not exist | Needs to be created. |
| Backend `EventState` enum | `rideglory-api/rideglory-contracts/src/events/enums/event.enums.ts` | L18–23 | 4 values: `SCHEDULED`, `IN_PROGRESS`, `CANCELLED`, `FINISHED`. No `DRAFT`. |
| Backend Prisma schema | `rideglory-api/events-ms/prisma/schema.prisma` | L31–36: `EventState` enum; L45–72: `Event` model | No `DRAFT` state. No `waypoints` field on `Event`. |
| Backend `findAll` | `rideglory-api/events-ms/src/events/events.service.ts` | L85–103 | No draft exclusion filter. Would expose drafts to all users if DRAFT state were added. |
| Backend `findByOwnerId` | `rideglory-api/events-ms/src/events/events.service.ts` | L105–110 | Returns all owner events by `ownerId`. Will include drafts correctly. |
| Backend events controller | `rideglory-api/events-ms/src/events/events.controller.ts` | L1–84 | No `publishEvent` message pattern. |
| API gateway events routes | `rideglory-api/api-gateway/src/events/` | (not read — needs inspection by Architect) | No `PATCH /api/events/:id/publish` route. |

---

## Acceptance criteria

1. Typing 3+ chars in meeting point or destination triggers debounced autocomplete (400 ms) via `PlaceService.autocomplete`; dropdown appears with suggestions.
2. Spinner shows while loading; "No se encontraron resultados" shows if empty; error is handled gracefully without crash.
3. Selecting a suggestion populates the form field with the place name.
4. Location section has a "Ruta simple" / "Ruta personalizada" toggle. Default is "Ruta simple".
5. Custom route mode shows a waypoints section; organizer can add up to 9 intermediate waypoints via place search.
6. Each waypoint appears as a labeled card with a delete button. "Agregar punto" is hidden/disabled at 9 waypoints.
7. Waypoints are stored in `EventModel.waypoints: List<String>` and persisted to `Event.waypoints String[]` in the DB.
8. Cupos count display is tap-to-edit with keyboard input; validated to integer 5–500; out-of-range reverts on focus loss.
9. Event form has "Guardar borrador" secondary action; saves with `state = DRAFT`; only `name` required for draft save.
10. Drafts appear in "Mis eventos" with a distinct "Borrador" badge (orange outline).
11. A "Mis borradores" section/page exists, listing only the creator's draft events.
12. Drafts are NOT returned by `GET /api/events` (public discovery); non-owners cannot see drafts via `GET /api/events/:id`.
13. The owner's draft detail page has a "Publicar" CTA that transitions the event to `SCHEDULED` immediately.
14. Once published, the event appears in the public events list.
15. `dart analyze` zero new errors/warnings; `app_es.arb` updated; all new strings localized.
16. All new widgets match Pencil designs produced in the Design phase.

---

## Regression guardrails

| What must NOT break | Verification step |
|---|---|
| Simple A→B event creation (meeting point + destination only) | Create a new event with no waypoints; confirm it saves and appears in the list |
| `RouteMapPreview` geocoding and rendering | Trigger form with meeting point typed; confirm map updates with marker |
| AI cover generation | Open event form, tap generate cover; confirm image generates and saves with event |
| `flutter test` 47 passing tests | Run `flutter test` after all changes; zero regressions |
| Existing `EventState` values in Flutter and backend | Load events list; confirm `scheduled`, `inProgress`, `cancelled`, `finished` events render correctly |
| `AppCityAutocompleteField` (distinct from place autocomplete) | Open event filter bottom sheet; confirm city search still works |
| Event detail page for non-owner | Open a published event as non-owner; confirm no "Publicar" button is shown |
| `EventsCubit` filters (type, date, city) | Apply filters on public events list; confirm drafts never appear |
| Backend `findAll` with filters | `GET /api/events?type=TOURISM` — confirm no DRAFT events returned |
| `findByOwnerId` includes drafts | `GET /api/events/me` — confirm DRAFT events included for the owner |

---

## Decisions needed from downstream agents

### For Architect
1. **Draft findOne auth guard:** `findOne` in events-ms does not receive `authUserId`. What is the cleanest pattern to thread auth context through the RPC chain without breaking existing callers? Options: (a) add optional `authUserId` to the RPC payload; (b) handle the draft visibility guard exclusively in the api-gateway (before forwarding the RPC); (c) always return the event from events-ms and let api-gateway 403 if it is a draft and the caller is not the owner.
2. **Waypoints in RouteMapPreview:** Should waypoint markers be shown in the form's embedded map preview? Confirm expected behavior.
3. **`CreateEventDto` state field:** Currently defaults to `SCHEDULED`. Clients must explicitly send `state: 'DRAFT'` to create a draft — confirm this is the correct approach vs. a separate `createDraft` endpoint.
4. **api-gateway events proxy:** Locate and share the path to the api-gateway events routes/controller file so backend agent can add the `PATCH /api/events/:id/publish` route.

### For Design
1. **"Mis borradores" entry point:** Where does this section appear in the navigation? Options: (a) a tab within the "Mis eventos" tab in `EventsPage`; (b) a new entry in the profile page; (c) both.
2. **Route type selector UI:** What does the toggle between "Ruta simple" and "Ruta personalizada" look like? Segmented button? Radio cards?
3. **Waypoint card design:** Show the waypoint label (place name), a drag handle (if reordering is included), and a delete icon. Confirm whether reordering is in scope (assumed out of scope for now).
4. **Cupos stepper with text input:** Show the inline text field replacing the static count display. Confirm whether the ±5 buttons are still present alongside the text field.
5. **Draft badge:** Confirm color, label, and shape distinct from the existing "Mi evento" organizer badge.
6. **"Publicar" CTA on draft detail:** Position on the detail page (full-width at bottom vs. inside the owner lifecycle bar).

### For Frontend
1. Confirm that injecting `PlaceService` directly into `AppPlaceAutocompleteField` via `getIt` is acceptable or if a dedicated cubit/notifier is preferred for testability.
2. Confirm the `FormBuilderField<RouteType>` approach for the route type selector vs. cubit-managed state.

### For Backend
1. Confirm that `waypoints String[]` is sufficient for ordered waypoint storage (no separate `Waypoint` model needed).
2. Confirm the Prisma migration strategy: one migration combining `DRAFT` + `waypoints`, or two separate migrations.

---

## Open questions for the human

1. Should the user be able to **reorder waypoints** (drag-to-reorder) or only add/delete? (Assumed out of scope for this iteration.)
2. For the **"Mis borradores" section** — should it be a tab within "Mis eventos" (tab bar inside `EventsPage`) or a standalone page accessible from the user's profile? The note says "both a dedicated section AND appear in Mis eventos with a tag" but does not specify the navigation entry for the dedicated section.
3. Should **all fields be editable in a draft** (same form as published event creation), or should there be fewer required fields when saving a draft? (Assumed: only `name` required for draft save, all fields optional.)

---

## Suggested phase plan

| Phase | Required | Reason |
|---|---|---|
| needsDesign | yes | New UI surfaces: route type toggle, waypoint cards, draft badge, "Mis borradores" page, "Publicar" CTA must be designed in Pencil before frontend implementation |
| needsBackend | yes | `DRAFT` state in contracts + Prisma, `waypoints` field in Prisma, `findAll` draft exclusion, `publishEvent` endpoint, auth guard for draft `findOne` |
| needsFrontend | yes | Autocomplete activation, custom route builder, cupos stepper manual input, draft UI, "Mis borradores" page |
| needsDb | yes | Prisma migration: `DRAFT` to `EventState` enum + `waypoints String[]` on `Event` model in events-ms |

---

## Notes for orchestrator

- **Phase order:** Design → Backend (can start in parallel with Design) → Frontend (blocked on Design frames AND backend `/publish` endpoint being defined) → QA → Tech Lead review.
- **No commit/PR rule:** This is a custom-iter; the human reviews all code changes before approving merge.
- **Dirty tree:** The repo has 7 pre-existing modified files (`android/app/build.gradle.kts`, `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`, `lib/core/http/api_base_url_resolver.dart`, `pubspec.yaml`, `rideglory.pen`). These are pre-existing and must not be attributed to this iteration.
- **Code generation:** After any changes to DTOs, models, or service interfaces, `dart run build_runner build --delete-conflicting-outputs` must be run. The `event_dto.g.dart` and `event_service.g.dart` files will need regeneration.
- **Contracts package:** `rideglory-contracts` is a separate Git submodule at `/Users/cami/Developer/Personal/rideglory-api/rideglory-contracts`. Enum changes there must be built (`tsc`) and the dist published/linked before events-ms can consume `DRAFT`.
