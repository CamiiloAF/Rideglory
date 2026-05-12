# Frontend Handoff — Iteration 2

**Phase:** frontend | **Iteration:** 2 | **Status:** DONE
**Completed:** 2026-05-12T22:30:00Z

---

## Changes Implemented

### Task 1: Event Filter Wire-up (US-2-1, US-2-2)

#### `EventService` — @Query params added
**File:** `lib/features/events/data/service/event_service.dart`

Added four optional `@Query` parameters to `getEvents()`:
- `type`, `dateFrom`, `dateTo`, `city`

Requires build_runner to regenerate `event_service.g.dart`.

#### `EventRepository` interface — updated signature
**File:** `lib/features/events/domain/repository/event_repository.dart`

`getEvents()` now accepts optional named params: `type`, `dateFrom`, `dateTo`, `city`.

#### `GetEventsUseCase` — updated signature
**File:** `lib/features/events/domain/use_cases/get_events_use_case.dart`

`call()` now accepts the same optional named params and forwards them to the repository.

#### `EventRepositoryImpl` — forwards params to service
**File:** `lib/features/events/data/repository/event_repository_impl.dart`

`getEvents()` overrides now pass all optional filter params through to `_eventService.getEvents(...)`.

#### `EventsCubit` — wired to backend
**File:** `lib/features/events/presentation/list/events_cubit.dart`

Key changes (ADR-3 compliant — no EventsState freezed refactor):
- `_fetchFn` type changed from `Future<dynamic> Function()` to accept optional named params `{type, dateFrom, dateTo, city}`
- `EventsCubit` constructor maps `getEventsUseCase.call` to the new signature
- `EventsCubit.myEvents` constructor maps `getMyEventsUseCase.call` (ignores filters, myEvents not filter-enabled)
- `fetchEvents()` reads `_filters`, converts to backend params, and passes them to `_fetchFn`
- `updateFilters()` now calls `fetchEvents()` instead of `_applyFiltersAndEmit()` — triggers backend refetch
- `clearFilters()` now calls `fetchEvents()` instead of `_applyFiltersAndEmit()` — triggers backend refetch

**Backend filter mapping:**
- `types.first.name` → `type` (only first selected type sent to backend; local multi-type filter still applies)
- `startDate?.toIso8601String().substring(0, 10)` → `dateFrom`
- `endDate?.toIso8601String().substring(0, 10)` → `dateTo`
- `city` → `city`

**Local-only filters** (difficulties, freeOnly, multiBrandOnly) remain in `_applyFiltersAndEmit()` unchanged.

#### `EventFiltersBottomSheet` — conditional "Limpiar filtros" button
**File:** `lib/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart`

"Limpiar filtros" `AppTextButton` is now only shown when `cubit.filters.hasFilters || _selectedTypes.isNotEmpty || _selectedDifficulties.isNotEmpty`.

#### `EventsDataView` — proper counter badge
**File:** `lib/features/events/presentation/list/widgets/events_data_view.dart`

Filter button badge updated:
- Shows a 16×16px white circle with primary-colored count text instead of a plain dot
- Count computed via `_activeFilterCount()`: +1 for types, +1 for non-empty city, +1 for any date set (range counts as 1)
- Hidden when count = 0

#### `EventsPageView` — filtered empty state
**File:** `lib/features/events/presentation/list/widgets/events_page_view.dart`

`empty` branch now checks `cubit.filters.hasFilters`:
- **Active filters:** icon `search_off`, title from `event_noResultsFiltered`, action "Limpiar filtros" → `clearFilters()`
- **No filters:** original behavior (icon `event_outlined`, title `event_noEvents`, action `event_createEvent`)

---

### Task 2: GetUserByIdUseCase + UserService + UserRepository (US-2-3)

#### `UserService` — new endpoint
**File:** `lib/features/users/data/service/user_service.dart`

Added `@GET('/users/{id}') Future<UserDto> getUserById(@Path('id') String id)`.

#### `UserRepository` — new method
**File:** `lib/features/users/domain/repository/user_repository.dart`

Added `Future<Either<DomainException, UserModel>> getUserById(String userId)`.

#### `UserRepositoryImpl` — implements getUserById
**File:** `lib/features/users/data/repository/user_repository_impl.dart`

Implements `getUserById` via `executeService(() => _userService.getUserById(userId))`.

#### `GetUserByIdUseCase` — new use case
**File:** `lib/features/users/domain/use_cases/get_user_by_id_use_case.dart` (NEW)

`@injectable` use case delegating to `UserRepository.getUserById`.

---

### Task 3: RiderProfileCubit (US-2-3)

**File:** `lib/features/users/presentation/cubit/rider_profile_cubit.dart` (NEW)

`@injectable` cubit extending `Cubit<ResultState<UserModel>>`. Exposes `fetchRiderProfile(String userId)`.

---

### Task 4: RiderProfilePage + Widgets (US-2-3)

**File:** `lib/features/users/presentation/pages/rider_profile_page.dart` (NEW)

- Provides `RiderProfileCubit` via `BlocProvider` + `getIt<RiderProfileCubit>()`
- AppBar title: `context.l10n.rider_profileTitle`
- Four ResultState branches: initial/loading → `RiderProfileLoading`, data → `RiderProfileContent`, error → `_RiderProfileError` (inline private widget), empty → `RiderProfileLoading`

**File:** `lib/features/users/presentation/widgets/rider_profile_content.dart` (NEW)

Displays: 72px `CircleAvatar` with initials, name (headlineSmall bold), email (bodyMedium onSurfaceVariant), optional city row, "Sin vehículos registrados" placeholder (vehicle list deferred).

**File:** `lib/features/users/presentation/widgets/rider_profile_loading.dart` (NEW)

Skeleton placeholder with shimmer-style grey containers matching the data state layout.

---

### Task 5: Route + Navigation (US-2-3)

#### `AppRoutes`
**File:** `lib/shared/router/app_routes.dart`

Added: `static const String riderProfile = '/events/attendees/rider-profile'`

#### `AppRouter`
**File:** `lib/shared/router/app_router.dart`

Added `GoRoute` for `AppRoutes.riderProfile` accepting `String` from `state.extra`.

#### `AttendeesList` — tap wired to rider profile
**File:** `lib/features/events/presentation/attendees/widgets/attendees_list.dart`

Processed attendee `onTap` now navigates to `AppRoutes.riderProfile` with `registration.userId` as extra.

#### `AttendeeProcessedItem` — trailing chevron
**File:** `lib/features/events/presentation/attendees/widgets/attendee_processed_item.dart`

When `onTap != null`: trailing shows `Icons.chevron_right_rounded` (onSurfaceVariant).
When `onTap == null`: trailing shows `Icons.more_vert_rounded` with `onOptionsPressed`.

---

### Task 6: Localization

**File:** `lib/l10n/app_es.arb` — 8 new keys added:
`event_filterTitle`, `event_filterType`, `event_filterDateRange`, `event_filterCity`, `event_noResultsFiltered`, `rider_profileTitle`, `rider_noVehicles`, `rider_errorRetry`

**File:** `lib/l10n/app_localizations.dart` — abstract getters added
**File:** `lib/l10n/app_localizations_es.dart` — Spanish implementations added

---

## Build Runner

`dart run build_runner build --delete-conflicting-outputs` — ran cleanly; 118 outputs written.

Regenerated: `event_service.g.dart`, `user_service.g.dart`, `injection.config.dart`.

---

## Analysis

`dart analyze` — 14 errors all in **pre-existing** maintenance code (`maintenance_service.dart`, `maintenances_summary_header.dart`). Zero new violations introduced by this iteration.

---

## Tests

`flutter test` — pre-existing failures only (same maintenance code that fails `dart analyze`). All new code compiles and DI-registers correctly via build_runner.

---

## Files Changed

**New:**
- `lib/features/users/domain/use_cases/get_user_by_id_use_case.dart`
- `lib/features/users/presentation/cubit/rider_profile_cubit.dart`
- `lib/features/users/presentation/pages/rider_profile_page.dart`
- `lib/features/users/presentation/widgets/rider_profile_content.dart`
- `lib/features/users/presentation/widgets/rider_profile_loading.dart`

**Modified:**
- `lib/features/events/data/service/event_service.dart`
- `lib/features/events/data/repository/event_repository_impl.dart`
- `lib/features/events/domain/repository/event_repository.dart`
- `lib/features/events/domain/use_cases/get_events_use_case.dart`
- `lib/features/events/presentation/list/events_cubit.dart`
- `lib/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart`
- `lib/features/events/presentation/list/widgets/events_data_view.dart`
- `lib/features/events/presentation/list/widgets/events_page_view.dart`
- `lib/features/events/presentation/attendees/widgets/attendees_list.dart`
- `lib/features/events/presentation/attendees/widgets/attendee_processed_item.dart`
- `lib/features/users/data/service/user_service.dart`
- `lib/features/users/data/repository/user_repository_impl.dart`
- `lib/features/users/domain/repository/user_repository.dart`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_es.dart`
- `lib/shared/router/app_routes.dart`
- `lib/shared/router/app_router.dart`

---

## Next Phase

QA — widget tests for filter badge, filtered empty state, RiderProfilePage states, attendee navigation.
