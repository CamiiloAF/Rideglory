# Architect Handoff — Iteration 2
# Event Discovery Filters + Attendee Profile Links

**Generated:** 2026-05-12
**Iteration:** 2
**Phase:** architect
**Status:** READY FOR BACKEND / FRONTEND / QA

---

## Key Finding: Filters Already Exist Client-Side

The existing `EventsCubit` already applies filters **locally** after fetching all events.
`EventFilters` is a plain Dart class (not freezed) holding `types`, `difficulties`, `city`,
`startDate`, `endDate`, `freeOnly`, `multiBrandOnly`.

**The PO handoff asks for a full cubit refactor to `EventsState` (freezed). This is WRONG
for the brownfield** — it would break all existing tests and UI without user value.

**ADR-3 Decision:** Keep the existing `EventFilters` + `Cubit<ResultState<List<EventModel>>>`
pattern. Add **backend forwarding only** for `type`, `dateFrom`, `dateTo`, `city`.
No freezed state refactor. Existing filter UI is already wired to `cubit.updateFilters()`.

Rationale:
- The filter bottom sheet is already fully wired to `cubit.updateFilters()` and `cubit.clearFilters()`.
- Filter badge and "Limpiar filtros" already exist in the UI.
- The only gap is that `getEvents()` and `getMyEvents()` don't send params to the API.
- A freezed refactor of `EventsState` would add ~200 lines of boilerplate with zero UX value.

---

## Story → Layer Map

### US-2-1 + US-2-2: Event Filters (Backend Wire-Up)

**Backend (rideglory-api)**
- `GET /events` and `GET /events/upcoming`: accept `type?`, `dateFrom?`, `dateTo?`, `city?`
- api-gateway passes params through to events-ms (no transform)
- events-ms `findAllEvents`: adds Prisma WHERE clauses for each param present

**Domain**
- `EventRepository.getEvents({String? type, String? dateFrom, String? dateTo, String? city})`
- `EventRepository.getMyEvents(...)` — same params (for consistency; currently unused in UI but future-proof)
- `GetEventsUseCase.call({EventType? type, DateTime? dateFrom, DateTime? dateTo, String? city})`
- Converts `DateTime` → ISO 8601 string, `EventType` → string value before forwarding

**Data**
- `EventService.getEvents(@Query params)` — Retrofit @Query annotations
- `EventRepositoryImpl.getEvents()` — reads `EventFilters` → converts → calls service

**Presentation**
- `EventsCubit.fetchEvents()` — reads `_filters` and passes them to `GetEventsUseCase`
- `EventsCubit.updateFilters()` now triggers a backend fetch (not just local re-filter)
- Local post-filter still applied for `difficulties`, `freeOnly`, `multiBrandOnly` (no backend support for these)
- Filter badge count = count of non-null/non-empty filter fields among: types, city, startDate, endDate, freeOnly, multiBrandOnly

---

### US-2-3: Attendee Profile Navigation

**Domain (new)**
- `UserRepository.getUserById(String id)` — new method on existing abstract class
- `GetUserByIdUseCase` at `lib/features/users/domain/use_cases/get_user_by_id_use_case.dart`

**Data (new)**
- `UserService.getUserById(String id)` — `@GET('/users/{id}')` (confirm endpoint with backend)
- `UserRepositoryImpl.getUserById(id)` — calls service, maps UserDto → UserModel (already compatible)

**Presentation (new)**
- `RiderProfileCubit extends Cubit<ResultState<UserModel>>` at `lib/features/users/presentation/`
- `RiderProfilePage` at `lib/features/users/presentation/pages/rider_profile_page.dart`
- Navigation: `context.pushNamed(AppRoutes.riderProfile, extra: userId)` from `AttendeesList`
- Route: `AppRoutes.riderProfile = '/events/attendees/rider-profile'`

**Attendee List change**
- `AttendeeProcessedItem.onTap` navigates to rider profile (not registration detail)
- `AttendeePendingRequestCard` — keep existing behavior (org workflow); optionally add profile tap

---

## New Domain Models

### EventFilter → Already exists as `EventFilters` plain class — no new model needed

No `EventsState` freezed class needed (ADR-3).

### No new event domain models

---

## New Files

```
lib/features/users/domain/use_cases/get_user_by_id_use_case.dart
lib/features/users/presentation/pages/rider_profile_page.dart
lib/features/users/presentation/cubit/rider_profile_cubit.dart
lib/features/users/presentation/widgets/rider_profile_content.dart
lib/features/users/presentation/widgets/rider_profile_loading.dart
```

---

## Changed Files

```
lib/features/users/domain/repository/user_repository.dart       (+getUserById)
lib/features/users/data/repository/user_repository_impl.dart    (+getUserById)
lib/features/users/data/service/user_service.dart               (+getUserById endpoint)
lib/features/events/domain/repository/event_repository.dart     (+filter params)
lib/features/events/data/service/event_service.dart             (+@Query params)
lib/features/events/data/repository/event_repository_impl.dart  (+param forwarding)
lib/features/events/domain/use_cases/get_events_use_case.dart   (+params)
lib/features/events/presentation/list/events_cubit.dart         (fetch calls use case with filters)
lib/shared/router/app_routes.dart                               (+riderProfile)
lib/shared/router/app_router.dart                               (+riderProfile route)
lib/l10n/app_es.arb                                             (+9 keys)
```

---

## API Contracts

### GET /events (updated)
```
Query params (all optional):
  type       String   EventType raw value (e.g. "Off-Road", "On-Road")
  dateFrom   String   ISO 8601 date "2026-05-01"
  dateTo     String   ISO 8601 date "2026-06-30"
  city       String   partial match, case-insensitive

Existing response shape unchanged.
```

### GET /events/upcoming (updated) — same query params

### GET /users/:id (new)
```
Path: /users/:id
Auth: Firebase ID token (existing interceptor)
Response: UserDto (same shape as GET /users/me)
```

---

## Localization Keys (app_es.arb additions)

```json
"event_filterTitle": "Filtros de eventos",
"event_filterType": "Tipo de evento",
"event_filterDateRange": "Rango de fechas",
"event_filterCity": "Ciudad",
"event_clearFilters": "Limpiar filtros",
"event_noResultsFiltered": "No hay eventos con estos filtros",
"event_applyFilters": "Filtrar",
"rider_profileTitle": "Perfil del motorista",
"rider_noVehicles": "Sin vehículos registrados",
"rider_errorRetry": "Reintentar"
```

Note: `event_clearFilters` and `event_applyFilters` may already exist in `app_es.arb` — verify before adding to avoid duplicates.

---

## ADR-3: No EventsState Freezed Refactor (Iter-2)

- The existing `EventsCubit<ResultState<List<EventModel>>>` is sufficient.
- Adding a freezed `EventsState` wrapper for `activeFilter` would require updating all existing tests,
  all `BlocBuilder` consumers, and all mock cubits — ~300 lines touched for zero UX gain.
- `EventFilters` already has `hasFilters` getter for badge display.
- Deferred to a dedicated refactor iteration if multiple cubits need coordinated state.

---

## DI

- `GetUserByIdUseCase` — `@injectable` (transient, no singleton needed)
- `RiderProfileCubit` — created by `BlocProvider` at page level (not root MBP)
- No changes to root `MultiBlocProvider`

---

## Build Runner

Run after all changes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Triggers: `event_service.g.dart` (new @Query params), `user_service.g.dart` (new endpoint),
`injection.config.dart` (new `GetUserByIdUseCase`).
