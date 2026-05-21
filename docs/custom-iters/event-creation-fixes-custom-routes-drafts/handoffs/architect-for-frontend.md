# Architect → Frontend

Repo: `/Users/cami/Developer/Personal/Rideglory`. Touch ONLY files in the change map. One widget per file. Use `lib/shared/widgets/form/` widgets and `context.l10n.*` for all strings.

## 0. Blocked-on
Wait for the Design phase frames in `rideglory.pen` AND the backend contract (this doc reflects it). After DTO/model/service edits, run:
`dart run build_runner build --delete-conflicting-outputs`

## 1. Domain — `event_model.dart`
- Add `draft('Borrador')` to `EventState` — place it FIRST so existing `.values` ordering is least disruptive (order is cosmetic; just be consistent).
- Add field `final List<String> waypoints;` (default `const []` in constructor), include in `copyWith`.

## 2. Data
`event_dto_converters.dart` — `EventStateConverter`:
- `_map`: add `'draft': EventState.draft, 'DRAFT': EventState.draft`.
- `toJson`: add `case EventState.draft: return 'DRAFT';`.

`event_dto.dart`:
- Add `super.waypoints = const []` to the `EventDto` constructor params.
- Add `waypoints: waypoints` to `EventModelExtension.toJson`'s `EventDto(...)`.

`event_service.dart` — add:
```dart
@PATCH('${ApiRoutes.events}/{id}/publish')
Future<EventDto> publishEvent(@Path('id') String id);
```

`event_repository.dart` — add `Future<Either<DomainException, EventModel>> publishEvent(String id);`

`event_repository_impl.dart` — implement:
```dart
@override
Future<Either<DomainException, EventModel>> publishEvent(String id) =>
    executeService(function: () async => _eventService.publishEvent(id));
```

New `domain/use_cases/publish_event_use_case.dart` — `@injectable`, `call(String id)` → `repository.publishEvent(id)`. Mirror `CreateEventUseCase`.

## 3. Fix exhaustive `EventState` switches (compile-breakers — Risk 1)
Add an `EventState.draft` branch to EACH:
- `event_dto_converters.dart` `EventStateConverter.toJson` (done in §2).
- `event_card.dart` — `_badgeLabel` → `route_draftBadge` (or `event_draftBadge`); `_badgeColor` → orange/`AppColors.primary`.
- `event_detail_view.dart` — `_EventHeaderSection._badgeLabel` / `_badgeColor` same.
- `event_detail_owner_lifecycle_bar.dart` — `build` switch → new `_OwnerDraftBar` (see §9).

## 4. Autocomplete — `app_place_autocomplete.dart` (rewrite)
- Convert to `StatefulWidget`. Keep the public API (`name`, `labelText`, `hintText`, `placeType`, `isRequired`, `validator`, `onSelected`, `focusNode`, `textInputAction`, `onFieldSubmitted`).
- Wrap a real `FormBuilderField<String>` so `formKey.currentState.value[name]` keeps returning the selected place name (RouteMapPreview depends on it).
- Internal `TextEditingController` + `Timer` debounce 400 ms; on 3+ chars call `getIt<PlaceService>().autocomplete(query, placeType.value)`.
- `PlaceService.autocomplete` returns `List<String>` — show those strings directly in an overlay (`OverlayPortal` + `LayerLink`).
- States: spinner while loading inside the field; "No se encontraron resultados" when empty; generic error message on throw (no crash).
- Selecting a suggestion: set controller text, call `field.didChange(value)`, `onSelected?.call(value)`, close overlay.
- Cancel the `Timer` and dispose the controller/overlay in `dispose()`.
- NOTE: `PlaceAutocompleteType` enum has `cities` and `establishment` only — `establishment` is correct for meeting point / destination. Do NOT add new enum values.

## 4b. `AppCityAutocompleteField` — do NOT touch. Different widget; regression guardrail.

## 5. Route type + waypoints
`event_form_fields.dart` — add `routeType`, `waypoints` constants.

Define `enum RouteType { simple, custom }` (co-locate with the selector widget file or in the constants file — your call, one definition).

New `event_route_type_selector.dart` — `FormBuilderField<RouteType>` keyed `EventFormFields.routeType`, default `RouteType.simple`. Segmented selector "Ruta simple (A→B)" / "Ruta personalizada" per Pencil.

New `custom_route_builder_section.dart` — visible only when `routeType == custom`. Lists current waypoints (from `EventFormCubit` state), "Agregar punto" button that opens a place autocomplete to add a waypoint; button hidden/disabled at 9 waypoints.

New `waypoint_item_card.dart` — one card: place-name label + delete icon. No drag handle (reorder is out of scope).

`event_form_locations_section.dart` — render `EventRouteTypeSelector` above the destination/meeting fields; render `CustomRouteBuilderSection` when custom is selected.

Waypoints live in `EventFormCubit` state (not a FormBuilder field — the dynamic list is cubit-managed). On submit: `routeType == simple` → `waypoints = []`; else use cubit list.

## 6. Cupos manual input — `event_form_max_participants_section.dart`
- Replace the static count `Text` in `_MaxParticipantsStepper` with an inline editable numeric field (styled to match Pencil; keep the `±` buttons).
- Field is `int?`; `'—'` placeholder when null. First focus/`+` activates at min 5.
- On focus loss / editing complete: parse, clamp to `[5, 500]`; non-numeric → revert to previous valid value. Commit via `field.didChange`.
- One-widget-per-file rule still applies — extract the editable field into its own widget if it grows.

## 7. `EventFormCubit`
- `EventFormState`: add `@Default(<String>[]) List<String> waypoints` and `@Default(RouteType.simple) RouteType routeType` (or manage routeType purely via FormBuilder — pick one and be consistent; waypoints MUST be in cubit state).
- Methods to mutate waypoints: `addWaypoint(String)`, `removeWaypoint(int index)`.
- `buildEventToSave()` — read `routeType` from form; set `waypoints` accordingly; keep `state: _editingEvent?.state ?? EventState.scheduled` for the publish path.
- New `buildDraftToSave()` — call `formKey.currentState!.save()` (save WITHOUT validate); require only `name` non-empty (else return null / emit error); fill safe defaults for missing required `EventModel` fields: `startDate`/`meetingTime` = `DateTime.now()`, `difficulty` = `EventDifficulty.one`, `eventType` = `EventType.tourism`, `meetingPoint`/`destination`/`description`/`city` = `''`. Build `EventModel` with `state: EventState.draft`.
- New `saveDraft(...)` — mirror `saveEvent` but uses `buildDraftToSave()` and routes through `_createNewEvent` / `_saveExistingEvent` (draft can be created or re-saved). Reuse the cover upload logic.
- New `publishEvent(String id)` — calls `PublishEventUseCase`, emits result into `saveResult` (or a dedicated `publishResult` ResultState — prefer dedicated to keep listeners clean).

## 8. Form bottom bar — `event_form_bottom_bar.dart`
- `_DraftLink.onTap` currently calls `context.pop()`. Change it to call `cubit.saveDraft(...)` (same image-cubit plumbing as `_onPublish`). On success the existing `EventFormView` listener pops with the event.
- `_DraftLink` shows only in create mode today — keep that, but AC-12 wants "Publicar" available inside the draft edit form; that lives in the detail/lifecycle bar (§9), not here. The edit form for a draft uses the normal primary CTA to re-save the draft.

## 9. Draft detail + publish CTA
`event_card_my_event_badge.dart` — add `final bool isDraft` (default false); when true render an orange-outline "Borrador" badge variant (distinct from the gradient "Mi evento" badge).

`events_data_view.dart` / `event_card.dart` — for owner events with `state == draft`, pass `isDraft: true` to the badge; `event_card.dart` switch already gets a `draft` case (§3).

`event_detail_owner_lifecycle_bar.dart` — add `EventState.draft => _OwnerDraftBar(...)` to the `build` switch. New private `_OwnerDraftBar` widget: full-width primary "Publicar" CTA. Add an `onPublish` callback to `EventDetailOwnerLifecycleBar`.

`event_detail_view.dart` — the `bottomNavigationBar` condition currently shows the owner lifecycle bar only for `scheduled || inProgress`. Add `draft` to that condition; wire `onPublish` to `context.read<EventDetailCubit>().publishEvent(currentEvent)`. On success update `currentEvent` (the existing `lastUpdatedEventResult` listener pattern works — `publishEvent` should emit into the same channel).

`event_detail_cubit.dart` — add `publishEvent(EventModel)` that calls `PublishEventUseCase` and emits the updated event into `lastUpdatedEventResult` so the existing view listener picks it up.

## 10. "Mis borradores" page
New `presentation/drafts/my_drafts_page.dart` — reuse `EventsCubit.myEvents`, filter `events.where((e) => e.state == EventState.draft)`. Reuse `EventCard`/`EventsDataView` styling.
`app_routes.dart` — add `static const String myDrafts = '/events/drafts';`
`app_router.dart` — register the route.
Entry point: Architect recommends an entry on the profile page. Confirm against the Design frame; implement what Design specifies.

## 11. Strings — `app_es.arb`
Add all new strings with `event_` / `route_` prefix. See QA handoff for the proposed key list. No hardcoded Spanish in widgets.

## Done criteria
`dart analyze` zero new issues; `flutter test` all 47 pass; new UI matches Pencil.
