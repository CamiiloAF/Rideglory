# Architect Handoff — event-creation-fixes-custom-routes-drafts

## Goal acknowledgement

Four deliverables on the event creation flow:
1. Activate the stubbed `AppPlaceAutocompleteField` (debounced Mapbox Places search).
2. Add a simple/custom route selector + multi-waypoint builder (max 9 waypoints).
3. Allow manual keyboard input on the cupos (max participants) stepper.
4. Add server-side draft events: `DRAFT` state, private to creator, `PATCH /events/:id/publish`, draft visibility in "Mis eventos" + a dedicated "Mis borradores" section.

Key constraints confirmed against the code: this is strictly additive. Every existing `EventState` switch in Flutter is currently exhaustive (no default branch) and WILL fail to compile when `EventState.draft` is added — those switches are listed in the change map and MUST be patched in the same change set.

---

## Change map

Backend (`/Users/cami/Developer/Personal/rideglory-api`):

| File | Action | Reason | Risk |
|---|---|---|---|
| `rideglory-contracts/src/events/enums/event.enums.ts` | modify | Add `DRAFT = 'DRAFT'` to `EventState`. | low |
| `rideglory-contracts/src/events/dto/create-event.dto.ts` | modify | Add optional `waypoints?: string[]`. | low |
| `events-ms/prisma/schema.prisma` | modify | Add `DRAFT` to `EventState` enum; add `waypoints String[] @default([])` to `Event`. | med |
| `events-ms/prisma/migrations/<ts>_draft_and_waypoints/migration.sql` | create | Hand-authored migration: `ALTER TYPE` + `ADD COLUMN`. See MIGRATION_PLAN.md. | med |
| `events-ms/src/events/events.service.ts` | modify | `findAll`/`findUpcoming` exclude `DRAFT`; new `publishEvent(id, ownerId)`. | high |
| `events-ms/src/events/events.controller.ts` | modify | Add `@MessagePattern('publishEvent')` handler. | low |
| `api-gateway/src/events/events.controller.ts` | modify | Add `PATCH :id/publish` route; resolve `ownerId` via existing `getAuthenticatedUser`. | med |

Flutter (`/Users/cami/Developer/Personal/Rideglory`):

| File | Action | Reason | Risk |
|---|---|---|---|
| `lib/shared/widgets/form/app_place_autocomplete.dart` | rewrite | Convert to `StatefulWidget`; debounced overlay autocomplete via `PlaceService`. | high |
| `lib/features/events/constants/event_form_fields.dart` | modify | Add `routeType`, `waypoints` field-key constants. | low |
| `lib/features/events/domain/model/event_model.dart` | modify | Add `EventState.draft`; add `List<String> waypoints` field + copyWith. | med |
| `lib/features/events/data/dto/event_dto.dart` | modify | Add `waypoints` super param; thread through `EventModelExtension.toJson`. | med |
| `lib/features/events/data/dto/event_dto_converters.dart` | modify | `EventStateConverter`: map `DRAFT`/`draft`; add `case EventState.draft` in `toJson`. | low |
| `lib/features/events/data/service/event_service.dart` | modify | Add `publishEvent(id)` → `PATCH /events/{id}/publish`. | low |
| `lib/features/events/domain/repository/event_repository.dart` | modify | Add `publishEvent(String id)`. | low |
| `lib/features/events/data/repository/event_repository_impl.dart` | modify | Implement `publishEvent`. | low |
| `lib/features/events/domain/use_cases/publish_event_use_case.dart` | create | New use case wrapping `repository.publishEvent`. | low |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | modify | Add `waypoints` + `routeType` to state; `saveDraft()`; `buildEventToSave()` carries waypoints/state; relaxed draft validation. | high |
| `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` | modify | Add route type selector; render custom-route builder when custom. | high |
| `lib/features/events/presentation/form/widgets/sections/event_route_type_selector.dart` | create | Simple A→B vs custom segmented selector (`FormBuilderField<RouteType>`). | med |
| `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart` | create | Waypoint list + "Agregar punto" (max 9). | med |
| `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` | create | One waypoint card with label + delete. | low |
| `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | modify | Replace static count `Text` with inline editable field; clamp [5,500] on focus loss. | med |
| `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` | modify | `_DraftLink` calls `saveDraft()` instead of `context.pop()`. | med |
| `lib/features/events/presentation/list/widgets/event_card_my_event_badge.dart` | modify | Add `isDraft` flag → "Borrador" outline variant. | low |
| `lib/features/events/presentation/list/widgets/event_card.dart` | modify | Add `EventState.draft` case to both switches; render draft badge. | med |
| `lib/features/events/presentation/detail/event_detail_view.dart` | modify | Add `EventState.draft` to `_badgeLabel`/`_badgeColor`; owner draft → publish CTA. | high |
| `lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart` | modify | Add `EventState.draft` branch with "Publicar" CTA. | high |
| `lib/features/events/presentation/detail/cubit/event_detail_cubit.dart` | modify | Add `publishEvent(EventModel)` method using `PublishEventUseCase`. | med |
| `lib/features/events/presentation/list/widgets/events_data_view.dart` | modify | Pass `isDraft` to `EventCard`/badge for owner draft events. | low |
| `lib/features/events/presentation/drafts/my_drafts_page.dart` | create | "Mis borradores" page — reuses `EventsCubit.myEvents`, filters `state == draft`. | med |
| `lib/shared/router/app_routes.dart` | modify | Add `myDrafts` route constant. | low |
| `lib/shared/router/app_router.dart` | modify | Register `myDrafts` route. | low |
| `lib/l10n/app_es.arb` | modify | New `event_`/`route_` strings (see QA handoff list). | low |

Generated files needing rebuild: `event_dto.g.dart`, `event_service.g.dart`, `event_form_cubit.freezed.dart`, `event_detail_cubit.freezed.dart` — run `dart run build_runner build --delete-conflicting-outputs`.

---

## Data model impact

### ERD delta — `Event` model
- New column `waypoints String[]` with `@default([])`. Ordered list of intermediate place names; index 0 = first stop after meeting point. No separate `Waypoint` table — a string array is sufficient for MVP (no per-waypoint metadata, no FK).
- `EventState` enum gains `DRAFT`.

No new tables, no relations, no index changes. `EventRegistration` untouched.

### Migration sketch (one migration, two statements)
```sql
ALTER TYPE "EventState" ADD VALUE IF NOT EXISTS 'DRAFT';
ALTER TABLE "Event" ADD COLUMN "waypoints" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
```
`ADD VALUE` on an enum cannot run inside the same transaction as a statement that uses the new value — but here the `ALTER TABLE` does not reference `DRAFT`, so a single migration file is safe. Full detail in `analysis/MIGRATION_PLAN.md`.

---

## Contract impact

### 1. `EventState` enum (contracts + Prisma + Flutter)
- Contracts: add `DRAFT = 'DRAFT'`.
- Prisma: add `DRAFT` value.
- Flutter `EventState`: add `draft('Borrador')`.
- Flutter `EventStateConverter`: `fromJson` maps `'DRAFT'` and `'draft'` → `EventState.draft`; `toJson` adds `case EventState.draft => 'DRAFT'`.

### 2. `waypoints` field
- Wire format: JSON array of strings, e.g. `"waypoints": ["Parque Norte", "Mirador El Alto"]`.
- `CreateEventDto.waypoints?: string[]` — optional, `@IsArray() @IsString({each:true})`, defaults to `[]` server-side via Prisma default.
- `UpdateEventDto` inherits via `PartialType` — no edit needed.
- Flutter `EventModel.waypoints` defaults to `const []`; serialized as `waypoints` JSON key.

### 3. New endpoint — Publish draft

| Field | Value |
|---|---|
| Method / path | `PATCH /api/events/:id/publish` |
| Auth | Firebase token (existing gateway middleware). |
| Path param | `id` — event UUID (`ParseUUIDPipe`). |
| Request body | none. |
| RPC pattern | `publishEvent` → `{ id: string, ownerId: string }`. |
| Response | full `Event` object (same shape as `findOne`), now `state: 'SCHEDULED'`. |
| `404` | event not found. |
| `403` | requester is not the event owner. |
| `409` | event state is not `DRAFT` (already published / in progress / etc.). |

Gateway resolves `ownerId` exactly like `findMyEvents` does — `getAuthenticatedUser(request)` → `findUserByEmail` → `user.id`. No new auth plumbing.

### 4. Draft visibility (Open Question 2 — RESOLVED)
Keep the draft guard inside `events-ms`, not the gateway. Two independent guards:
- **List exclusion:** `findAll` and `findUpcoming` add `state: { not: EventState.DRAFT }`. `findByOwnerId` is unchanged (owner sees own drafts). This satisfies AC-10's "not in public feed".
- **Single-event guard:** thread `authUserId` into `findOne`. Add a NEW RPC pattern `findOneEventForViewer` carrying `{ id, authUserId }` used by the gateway's `GET :id`. The existing `findOneEvent` (id-only) stays untouched for internal callers (tracking, registrations, reminders) so nothing breaks. `findOneEventForViewer`: if `event.state === DRAFT && event.ownerId !== authUserId` → throw `404` (chosen over 403 — does not leak draft existence). Gateway `GET :id` resolves `authUserId` via `getAuthenticatedUser`.

Rationale: drafts never leave events-ms for non-owners; the gateway never has to inspect event state. This is the safest threading because existing `findOneEvent` callers keep their id-only payload.

### 5. `CreateEventDto.state` (Open Question 3 — RESOLVED)
No separate `createDraft` endpoint. The client sends `state: 'DRAFT'` explicitly on the existing `POST /events`. `CreateEventDto.state` already defaults to `SCHEDULED` and accepts any `EventState` via `@IsEnum`. The owner auto-registration in `create()` still runs for drafts — acceptable (owner is auto-registered to their own draft; harmless, and consistent once published).

---

## Env / config delta

None. No new environment variables, no new external services. Mapbox key for `PlaceService` already exists and the endpoint is already wired.

---

## Risk register

1. **Exhaustive `EventState` switches break compilation.** Adding `EventState.draft` breaks: `event_dto_converters.dart` (`EventStateConverter.toJson`), `event_card.dart` (`_badgeLabel`, `_badgeColor`), `event_detail_view.dart` (`_EventHeaderSection._badgeLabel`/`_badgeColor`), `event_detail_owner_lifecycle_bar.dart` (`build` switch). Mitigation: Frontend MUST add a `draft` branch to every one of these in the same change set. AC-13 (`dart analyze`) will catch any miss.
2. **Enum `ADD VALUE` transactionality.** `ALTER TYPE ... ADD VALUE` historically could not run in a transaction (Postgres <12) and cannot be used in the same statement batch that references the new label. Mitigation: the migration's `ALTER TABLE` does not reference `DRAFT`; `IF NOT EXISTS` makes it idempotent. Target Postgres 12+ (the project uses PrismaPg / standard PG).
3. **Owner auto-registration on drafts.** `EventsService.create()` always creates an `APPROVED` owner registration. For a draft this means an orphan-ish registration before publish. Mitigation: accept it — it is invisible to others (the event is a draft) and becomes valid on publish. Do NOT special-case it; that adds branching risk. Note for QA to verify no crash.
4. **`findOne` callers regression.** Tracking, registrations, reminder cron all call `findOneEvent`. Mitigation: do NOT change `findOneEvent`; add a separate `findOneEventForViewer` pattern only for the gateway `GET :id`. Zero blast radius on internal callers.
5. **Autocomplete overlay focus/dispose leaks.** `OverlayPortal`/`LayerLink` + debounce `Timer` must be cancelled in `dispose()`; the field must still register with `FormBuilder` (`FormBuilderField<String>`) so `formKey.currentState.value` keeps returning the place name. Mitigation: Frontend wraps a real `FormBuilderField<String>` and only adds the suggestion overlay; `RouteMapPreview` still reads `meetingPoint`/`destination` form values unchanged.
6. **Draft save with minimal validation.** `saveDraft()` must bypass `formKey.currentState.saveAndValidate()` (which enforces all required fields). Mitigation: add a separate build path `buildDraftToSave()` that calls `formKey.currentState.save()` (save without validate), requires only `name` non-empty, and fills safe defaults for missing required domain fields (`startDate`/`meetingTime` = now, `difficulty` = one, `eventType` = tourism, empty strings for meeting point/destination). `EventModel` constructor requires those — defaults keep it constructible.
7. **`maxParticipants` text entry instability.** Free-form input mid-edit can emit invalid `field.didChange`. Mitigation: only commit clamped value on focus loss / editing complete; keep the `±` buttons; revert to previous value if non-numeric.
8. **Migration not applied in dev/CI environments.** A new column with a default is backward-safe for existing rows. Mitigation: `@default([])` on `waypoints`; no data backfill needed. Existing events get `[]`.

---

## Regression test surface

- Create a simple A→B event (route type = simple, no waypoints) → saves, `waypoints == []`, appears in list.
- Existing events render: `scheduled`/`inProgress`/`cancelled`/`finished` badges and lifecycle bars unchanged.
- `RouteMapPreview` still geocodes meeting point + destination after autocomplete rewrite.
- AI cover generation (`generateCover` / `CoverPreviewWidget`) untouched and still works.
- `AppCityAutocompleteField` (event filters city search) unaffected — it is a different widget.
- `GET /events` public feed excludes drafts; existing `type`/`date`/`city` filters still work.
- `GET /events/my` includes drafts for owner.
- `GET /events/:id` for a non-owner draft → 404; for owner draft → 200.
- Tracking start/end, registrations, reminder cron still resolve `findOneEvent` correctly.
- `flutter test` — all 47 tests pass; `dart analyze` zero new issues.
- `EventFormMaxParticipantsSection` widget tests still pass after the text-field change.

---

## Implementation order

### Backend (can start immediately, parallel with Design)
1. `rideglory-contracts`: add `DRAFT` to `EventState`; add `waypoints?: string[]` to `CreateEventDto`. Run `npm run build` in `rideglory-contracts` so `dist/` is regenerated for consumers.
2. `events-ms/prisma/schema.prisma`: add `DRAFT` + `waypoints`. Hand-author `migrations/<ts>_draft_and_waypoints/migration.sql` (see MIGRATION_PLAN.md). Regenerate Prisma client.
3. `events.service.ts`: `findAll`/`findUpcoming` exclude `DRAFT`; add `publishEvent(id, ownerId)` and `findOneEventForViewer(id, authUserId)`.
4. `events.controller.ts`: add `@MessagePattern('publishEvent')` and `@MessagePattern('findOneEventForViewer')`.
5. `api-gateway/events.controller.ts`: add `PATCH :id/publish`; switch `GET :id` to send `findOneEventForViewer` with resolved `authUserId`.

### Frontend (blocked on Design frames + backend contract above being defined)
1. Domain: `EventModel` — add `EventState.draft`, `waypoints`. Add `PublishEventUseCase`. Extend `EventRepository`.
2. Data: `EventStateConverter`, `EventDto` (`waypoints`), `EventService.publishEvent`, `EventRepositoryImpl.publishEvent`. Run build_runner.
3. Fix all exhaustive `EventState` switches (Risk 1).
4. Rewrite `AppPlaceAutocompleteField` (stateful, debounced overlay).
5. `EventFormFields` constants; `event_route_type_selector.dart`; `custom_route_builder_section.dart`; `waypoint_item_card.dart`; wire into `event_form_locations_section.dart`.
6. `event_form_max_participants_section.dart` — inline editable field.
7. `EventFormCubit` — `waypoints`/`routeType` state, `saveDraft()`, `buildEventToSave()` carries waypoints + state.
8. `event_form_bottom_bar.dart` — `_DraftLink` → `saveDraft()`.
9. Draft badge (`event_card_my_event_badge.dart`), `event_card.dart`, `events_data_view.dart`.
10. `my_drafts_page.dart` + route registration; entry point per Design decision.
11. Detail: `event_detail_owner_lifecycle_bar.dart` publish CTA; `event_detail_cubit.dart` `publishEvent()`; `event_detail_view.dart` wiring.
12. `app_es.arb` strings; `dart analyze`; `flutter test`.

---

## Out of scope

Per PRD §5: scheduled/timed publish, draft sharing, offline draft storage, waypoint drag-reorder, route polyline in the builder, `RouteMapPreview` geocoding changes, push notifications for drafts, drafts in public discovery.

---

## Notes for orchestrator

- Open Questions 1 (RRouteMapPreview waypoint markers) and Design-side "Mis borradores" placement are DESIGN decisions — Design must resolve them in `rideglory.pen` before Frontend starts. Architect recommendation: show waypoint markers on `RouteMapPreview` (markers only, no polyline, additive) and place "Mis borradores" as an entry on the profile page (lowest navigation-structure risk; `EventsPage` has no tab bar today).
- Backend and Design can run fully in parallel. Frontend is blocked on BOTH.
- `rideglory-contracts` is a git submodule — after editing it, `npm run build` must run there and `events-ms` must pick up the new `dist/`. Flag to DevOps if CI consumes a published package version.
- No commits / no PR — human reviews. Pre-existing dirty files (7, listed in `_meta.json`) are NOT part of this iteration.
- Single Prisma migration folder name suggestion: `<timestamp>_draft_state_and_waypoints`.
