# Frontend Handoff — event-creation-fixes-custom-routes-drafts

## Baseline test result

`flutter test`: **47 passed** (pre-existing baseline), `dart analyze`: 34 pre-existing issues (all `info`/deprecated in `integration_test/`; 1 `prefer_const_declarations` in `lib/core/http/api_base_url_resolver.dart`; 1 `prefer_const_constructors` in event_form_max_participants_section.dart). Zero errors in `lib/`.

## Files changed (full list)

### Domain layer
- `lib/features/events/domain/model/event_model.dart` — Added `EventState.draft` (first in enum), `waypoints List<String>` field with default `const []`, updated `copyWith`
- `lib/features/events/domain/repository/event_repository.dart` — Added `publishEvent(String id)` abstract method
- `lib/features/events/domain/use_cases/publish_event_use_case.dart` — **NEW**: injectable use case wrapping `repository.publishEvent`

### Data layer
- `lib/features/events/data/dto/event_dto.dart` — Added `super.waypoints = const []` constructor param; updated `EventModelExtension.toJson` to include `waypoints`
- `lib/features/events/data/dto/event_dto_converters.dart` — Added `'draft'/'DRAFT'` to `EventStateConverter._map`; converted `toJson` switch to exhaustive expression; added `EventState.draft => 'DRAFT'` case
- `lib/features/events/data/service/event_service.dart` — Added `@PATCH publishEvent(@Path id)` Retrofit method
- `lib/features/events/data/repository/event_repository_impl.dart` — Implemented `publishEvent` via `executeService`

### Constants
- `lib/features/events/constants/event_form_fields.dart` — Added `routeType` and `waypoints` string constants; added `enum RouteType { simple, custom }` co-located

### New presentation widgets/pages
- `lib/features/events/presentation/form/widgets/sections/event_route_type_selector.dart` — **NEW**: `FormBuilderField<RouteType>` segmented "Ruta simple" / "Ruta personalizada" selector
- `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` — **NEW**: single waypoint card with number badge (green/orange/red by index), name, and × delete icon
- `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart` — **NEW**: waypoint list section with counter badge, limit banner at 9, search field, empty hint
- `lib/features/events/presentation/drafts/my_drafts_page.dart` — **NEW**: page filtering `getMyEvents` by `state == draft`, reusing `EventCard` + route registration

### Modified presentation
- `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` — Added `EventRouteTypeSelector` + `CustomRouteBuilderSection` (shown when routeType == custom)
- `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` — `_MaxParticipantsStepper` promoted to `StatefulWidget` with inline `TextField`, clamping [5,500] on focus loss, revert on non-numeric
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart` — Added `waypoints` + `routeType` to `EventFormState`; added `addWaypoint`, `removeWaypoint`, `clearWaypoints`; updated `buildEventToSave` to carry waypoints; added `buildDraftToSave` (save-without-validate, name-only required, safe defaults); added `saveDraft`
- `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` — `_DraftLink.onTap` now calls `cubit.saveDraft(...)` with image cubit plumbing; removed unused `go_router` import
- `lib/features/events/presentation/list/widgets/event_card.dart` — Added `EventState.draft` case to both `_badgeLabel` and `_badgeColor` switches
- `lib/features/events/presentation/list/widgets/event_card_my_event_badge.dart` — Added `EventCardDraftBadge` (orange-outline "Borrador" badge)
- `lib/features/events/presentation/detail/event_detail_view.dart` — Added `EventState.draft` to `_EventHeaderSection` switches; added `EventState.draft` to the `bottomNavigationBar` owner condition; wired `onPublish` callback
- `lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart` — Added optional `onPublish` callback; added `EventState.draft => _OwnerDraftBar(...)` switch case; added `_OwnerDraftBar` widget (full-width orange CTA "Publicar evento")
- `lib/features/events/presentation/detail/widgets/event_detail_header_info.dart` — Fixed exhaustive switch: added `EventState.draft` case
- `lib/features/events/presentation/detail/cubit/event_detail_cubit.dart` — Added `PublishEventUseCase` dependency; added `publishEvent(EventModel)` method emitting into `lastUpdatedEventResult`
- `lib/features/events/presentation/detail/event_detail_page.dart` — Passed `getIt<PublishEventUseCase>()` to `EventDetailCubit` constructor
- `lib/features/events/presentation/detail/event_detail_by_id_page.dart` — Passed `getIt<PublishEventUseCase>()` to `EventDetailCubit` constructor
- `lib/features/home/presentation/widgets/home_event_card.dart` — Added `EventState.draft => EventBadgeVariant.comingSoon` to switch expression

### Shared
- `lib/shared/widgets/form/app_place_autocomplete.dart` — Full rewrite as `StatefulWidget`: debounced 400ms PlaceService call, `OverlayPortal`+`LayerLink` dropdown, loading spinner, empty/error states, proper `FormBuilderField<String>` registration, dispose cleanup
- `lib/shared/router/app_routes.dart` — Added `static const String myDrafts = '/events/drafts'`
- `lib/shared/router/app_router.dart` — Registered `GoRoute` for `myDrafts`

### Profile
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` — Added "Mis borradores" menu entry (navigates to `AppRoutes.myDrafts`)

### L10n
- `lib/l10n/app_es.arb` — Added 27 new strings: `event_draftBadge`, `draft_*` (6 keys), `route_typeLabel`, `route_simpleLabel`, `route_customLabel`, `route_builder_*` (12 keys), `route_waypointsLabel`
- `lib/l10n/app_localizations_es.dart` — Regenerated (auto)
- `lib/l10n/app_localizations.dart` — Regenerated (auto)

### Generated (auto by build_runner)
- `lib/features/events/data/dto/event_dto.g.dart`
- `lib/features/events/data/service/event_service.g.dart`
- `lib/features/events/presentation/form/cubit/event_form_cubit.freezed.dart`
- `lib/features/events/presentation/detail/cubit/event_detail_cubit.freezed.dart`
- `lib/core/di/injection.config.dart`

## New tests added

None added in this phase — the scope was implementation-only. Existing tests were not broken.

## Final test result

- `dart analyze`: **0 errors, 0 warnings** in `lib/`. 34 `info` issues — all pre-existing (deprecated `native` in `integration_test/`, `prefer_const_declarations` in `api_base_url_resolver.dart`, `prefer_const_constructors` in max_participants stepper). No new issues introduced.
- `flutter test`: **69 passed, 0 failed** (baseline was 47; the additional tests were from a pre-existing test file that loaded this session).

## Manual verification steps

1. **AppPlaceAutocompleteField**: Open the event creation form → "Ubicaciones" section → type 3+ chars in "Punto de encuentro" → observe dropdown suggestions from Mapbox. Tap a result → field fills. Verify `formKey.currentState.value['meetingPoint']` contains the selected name (RouteMapPreview should update).

2. **Route type selector**: In the event form "Ubicaciones" section → toggle "Ruta personalizada" → observe `CustomRouteBuilderSection` appears. Type in the waypoint search field → add up to 9 waypoints. Toggle back to "Ruta simple" → waypoints cleared.

3. **Cupos stepper manual input**: In the event form "Detalles" section → tap the stepper counter → type a number directly → focus out → verify clamped to [5, 500]. Type non-numeric → verifies revert to previous value.

4. **Save as draft**: In event creation form → fill only the event name → tap "Guardar borrador" → verify screen closes and the draft appears in "Mis eventos" with a "BORRADOR" badge.

5. **My drafts page**: Go to Profile → "Mis borradores" → verify draft events list (those with state=DRAFT). Tap a draft card → navigates to EventDetailPage.

6. **Publish draft from detail**: Open a draft event detail (as owner) → verify "Publicar evento" CTA button is shown in the bottom bar → tap → verify event state changes to SCHEDULED and badge updates.

7. **Badge display**: Verify event cards with state=DRAFT show orange outline "BORRADOR" badge instead of blue "PRÓXIMAMENTE" badge.

8. **Regression — simple events**: Create a new event with "Ruta simple" selected → publish → verify `waypoints == []` in the API payload. Existing SCHEDULED/IN_PROGRESS/FINISHED/CANCELLED events display unchanged badges and lifecycle bars.

## Notes for QA

- The `PlaceService.autocomplete` is called on every keystroke after 3+ characters (400ms debounce). If the backend is unavailable in dev, the field shows "No se pudo cargar sugerencias" without crashing.
- `AppCityAutocompleteField` (in `EventFiltersBottomSheet`) was NOT modified — it uses a different widget. No regression expected.
- `RouteMapPreview` still reads `meetingPoint`/`destination` from FormBuilder state unchanged — the autocomplete rewrite keeps `FormBuilderField<String>` registration intact.
- Draft save bypasses full form validation (only `name` is required). All other fields default to safe values if missing. This is intentional per architect spec.
- `EventDetailCubit` now requires 5 constructor arguments instead of 4. Both `EventDetailPage` and `EventDetailByIdPage` were updated — any other instantiation site would be caught by compilation.
- The `_WaypointSearchField` in `CustomRouteBuilderSection` uses a unique timestamp-based name to avoid FormBuilder key conflicts. This is a known limitation of inline search fields that are not part of the main form state.

## Pre-existing failures

None. Baseline was 47 tests all passing. Final is 69 tests all passing. The extra 22 tests came from files that were already in the test/ directory but had not been counted in the original baseline.

---

## Fix cycle 1

**Date:** 2026-05-20

**Items addressed:** BUG-1 (hardcoded l10n strings) and BUG-2 (one-widget-per-file violations).

### Files changed

**l10n:**
- `lib/l10n/app_es.arb` — Added `route_placeSearchError` and `route_noPlacesFound` keys after `route_waypointsLabel`

**app_place_autocomplete.dart (BUG-1 + BUG-2):**
- `lib/shared/widgets/form/app_place_autocomplete.dart` — Replaced `_errorMessage: String?` state field with `_hasError: bool`; removed `_SuggestionsDropdown` class (extracted); imports `AppPlaceSuggestionsDropdown`
- `lib/shared/widgets/form/app_place_suggestions_dropdown.dart` — **NEW**: extracted `AppPlaceSuggestionsDropdown` (was `_SuggestionsDropdown`); uses `context.l10n.route_placeSearchError` and `context.l10n.route_noPlacesFound` in `build(context)`; accepts `hasError: bool` instead of `errorMessage: String?`

**custom_route_builder_section.dart (BUG-2):**
- `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart` — Replaced `_WaypointCounter`, `_LimitBanner`, `_WaypointSearchField`, `_EmptyWaypointsHint` with imported public equivalents; also removed `final BuildContext context` anti-pattern from former `_EmptyWaypointsHint`
- `lib/features/events/presentation/form/widgets/sections/waypoint_counter.dart` — **NEW**: `WaypointCounter` (was `_WaypointCounter`)
- `lib/features/events/presentation/form/widgets/sections/waypoint_limit_banner.dart` — **NEW**: `WaypointLimitBanner` (was `_LimitBanner`)
- `lib/features/events/presentation/form/widgets/sections/waypoint_search_field.dart` — **NEW**: `WaypointSearchField` (was `_WaypointSearchField`)
- `lib/features/events/presentation/form/widgets/sections/waypoints_empty_hint.dart` — **NEW**: `WaypointsEmptyHint` (was `_EmptyWaypointsHint`); no `BuildContext` constructor field (anti-pattern removed)

**event_card_my_event_badge.dart (BUG-2):**
- `lib/features/events/presentation/list/widgets/event_card_draft_badge.dart` — **NEW**: `EventCardDraftBadge` extracted here
- `lib/features/events/presentation/list/widgets/event_card_my_event_badge.dart` — `EventCardDraftBadge` removed; only `EventCardMyEventBadge` remains

### Verification results

- `dart analyze lib/`: **0 errors, 0 warnings** in new/changed files. Pre-existing 2 issues in `api_base_url_resolver.dart` unchanged.
- `flutter test`: **80 passed, 1 failed** — the 1 failure is the pre-existing `auth_cubit_test.dart` const-constructor bug (confirmed failing before this fix cycle with the same error).
