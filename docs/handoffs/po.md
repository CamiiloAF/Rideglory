# Iteration 2 PO Handoff — Event Discovery Filters + Attendee Profile Links

**Generated:** 2026-05-12  
**Iteration:** 2  
**Status:** READY FOR ARCHITECT  
**Stories:** HU-EVENT-FILTER-01, HU-EVENT-FILTER-02, HU-ATTENDEE-PROFILE-01  
**Agents:** backend, frontend, qa

---

## Goal

Make event discovery fully functional by wiring the existing filter bottom sheet to real backend query parameters, and enable riders to tap into other riders' profiles from the event attendee list.

## Why Now

Event filters exist in the UI but are not connected to the backend — riders see all events with no way to narrow by type, date, or city. The attendee list has no navigation, making community discovery impossible. Both are completions of existing UI with no new architecture. **The backend filter gap is the only concrete risk** and is addressed in this iteration with explicit query parameter forwarding on `GET /events` and `GET /events/upcoming`.

---

## User Stories

### US-2-1: Event List Filters

**Title:** Event list filters

**Description:**  
As a rider browsing events, I tap the filter icon on the event list and select event type, date range, and city so I see only the upcoming rides relevant to me.

**Acceptance Criteria:**

1. **Backend — `GET /events` and `GET /events/upcoming`:** Accept optional query parameters `type`, `dateFrom`, `dateTo`, and `city`.
2. **Backend — parameter forwarding:** Both routes forward all filter parameters to the events-ms `findAllEvents` handler without modification.
3. **Backend — Prisma WHERE logic:** `findAllEvents` applies `WHERE` conditions for each filter when the param is present:
   - `eventType == type` (exact match, case-sensitive)
   - `startDate >= dateFrom` (ISO 8601 date string, inclusive)
   - `startDate <= dateTo` (ISO 8601 date string, inclusive)
   - `city ILIKE city` (case-insensitive prefix match)
4. **Backend — combined filters:** Multiple filters are ANDed together (e.g., `type=touring AND dateFrom=2026-05-20 AND city=Medell` returns only touring events in Medellín starting on or after May 20).
5. **Backend — unit tests:** At least 5 test cases covering:
   - Type-only filter
   - Date-range-only filter
   - City-only filter
   - Combined filter (type + date + city)
   - No filters (returns all events, confirming backward compatibility)
6. **`EventsCubit` refactor:** The cubit state transitions from `Cubit<ResultState<List<EventModel>>>` to `Cubit<EventsState>` where `EventsState` is a `@freezed` class with two fields:
   - `ResultState<List<EventModel>> eventsResult`
   - `EventFilter? activeFilter` (a `@freezed` class with optional `type`, `dateFrom`, `dateTo`, `city` fields)
7. **`EventsCubit.applyFilters()`:** New method that accepts optional `{EventType? type, DateTime? dateFrom, DateTime? dateTo, String? city}`. Converts `DateTime` fields to ISO 8601 strings and calls the `GetEventsUseCase` with the params. Emits `state.copyWith(activeFilter: filter, eventsResult: loading())` then `state.copyWith(eventsResult: data(...))` on success or `error(...)` on failure.
8. **`EventsCubit.clearFilters()`:** New method that resets `activeFilter` to null and triggers a fresh fetch. Emits `state.copyWith(activeFilter: null, eventsResult: loading())` then the fresh result.
9. **Filter UI wiring:** The event filter bottom sheet (existing widget in `lib/features/events/presentation/widgets/event_filters_bottom_sheet.dart` or similar) is wired to `context.read<EventsCubit>().applyFilters(...)` on the "Filtrar" button tap.
10. **Date range picker:** Use `flutter_form_builder`'s `FormBuilderDateRangePicker` or wrap `showDateRangePicker` with the app's `ThemeData` (dark mode — no white Material calendar flash). The picker must not show a white Material theme even in dark mode.
11. **Active filter badge:** An orange `Badge` widget with the count of active filters is displayed on the filter icon in the event list app bar (e.g., "3" for all three filter types applied, "1" for just type). Badge is hidden when no filters are active.
12. **Filter clear UI:** A "Limpiar filtros" button (using `AppButton`) is visible in the filter bottom sheet only when at least one filter is active. Tapping it calls `EventsCubit.clearFilters()`.
13. **Filtered empty state:** When `eventsResult` is `empty` AND `activeFilter` is non-null, the empty state widget shows "No hay eventos con estos filtros" and includes a "Limpiar filtros" button to reset.
14. **All-events empty state:** When `eventsResult` is `empty` AND `activeFilter` is null, the empty state widget shows the original message (e.g., "No hay eventos próximos").
15. **`EventFilter` model:** Define as a `@freezed` class in `lib/features/events/domain/models/event_filter.dart` with optional fields:
    - `EventType? type`
    - `DateTime? dateFrom`
    - `DateTime? dateTo`
    - `String? city`
16. **`EventsState` model:** Define as a `@freezed` class in `lib/features/events/presentation/cubit/events_state.dart` with:
    - `ResultState<List<EventModel>> eventsResult`
    - `EventFilter? activeFilter`
17. **`GetEventsUseCase` update:** Signature changes to accept optional params: `Future<Either<DomainException, List<EventModel>>> call({EventType? type, DateTime? dateFrom, DateTime? dateTo, String? city})`.
18. **`EventService` (Retrofit) update:** Signature changes to accept optional query parameters:
    ```dart
    @GET('/events')
    Future<List<EventDto>> getEvents({
      @Query('type') String? type,
      @Query('dateFrom') String? dateFrom,
      @Query('dateTo') String? dateTo,
      @Query('city') String? city,
    });
    ```
    (Same for `/events/upcoming`.)
19. **`EventsRepositoryImpl` update:** Converts `DateTime` to ISO 8601 string before passing to `EventService`.
20. **Existing `EventsCubit` tests from Iteration 1 are updated** to work with the new `EventsState` structure. The tests must still verify initial state, loading, data, empty, and error branches — the structure changes but the behavior does not.
21. **New unit tests for filter logic:**
    - `EventsCubit.applyFilters()` with type-only, date-only, city-only, combined, and no params
    - `EventsCubit.clearFilters()` resets `activeFilter` to null and triggers fetch
22. **Widget tests:**
    - Filter empty state (when `eventsResult == empty && activeFilter != null`) renders "No hay eventos con estos filtros"
    - Filter badge count is correct (0 when `activeFilter == null`, 1–3 depending on how many of type/dateFrom/dateTo/city are non-null)
    - Clear filters button is visible only when `activeFilter != null`
23. **Build runner:** `dart run build_runner build --delete-conflicting-outputs` runs cleanly after `EventsState` and `EventFilter` freezed classes are added.
24. **Linting:** `dart analyze` passes with zero violations.
25. **Testing:** `flutter test` passes with 100% green tests.

---

### US-2-2: Clear Filters

**Title:** Clear filters

**Description:**  
As a rider, I can clear all active filters with one tap on the filter badge or in the bottom sheet so I return to the full event list without navigating away.

**Acceptance Criteria:**

1. **Single-tap clear option:** When filters are active, the filter badge or a dedicated clear button on the filter bottom sheet offers a one-tap clear action.
2. **`EventsCubit.clearFilters()` wired:** Tapping the clear option calls `context.read<EventsCubit>().clearFilters()`.
3. **State reset:** After clear, `state.activeFilter` is null and `state.eventsResult` is refreshed with all events.
4. **Empty state update:** The empty state message switches back to "No hay eventos próximos" (or the original message) when filters are cleared.
5. **Badge visibility:** The badge disappears when filters are cleared.
6. **Widget test:** Clear filter action resets state and refreshes the list.

---

### US-2-3: Attendee Profile Navigation

**Title:** Attendee profile navigation

**Description:**  
As a rider viewing the attendee list of an event, I tap another rider's avatar or name and see their profile page (name, email, vehicles) so I can learn about other community members on the same ride.

**Acceptance Criteria:**

1. **`RiderProfilePage` new page:** Created at `lib/features/users/presentation/pages/rider_profile_page.dart`.
2. **Route param:** The page accepts a `String userId` as route extra via `context.pushNamed()`.
3. **Data fetching:** The page fetches the user via `GetUserByIdUseCase` (calls the existing `UserService.getUserById()` endpoint).
4. **UI content:** Displays:
   - Rider name (from `UserModel.fullName`)
   - Rider email (from `UserModel.email`)
   - List of vehicles (from `UserModel` or fetched separately if needed)
5. **Read-only:** No edit affordances, no "Set as main vehicle" button, no delete button. Profile is display-only.
6. **ResultState branches:**
   - Loading: shimmer skeleton or loading indicator
   - Data: name, email, vehicle list rendered
   - Error: error banner with retry button
   - Empty: should not occur (assume every user has a name and email)
7. **Navigation:** Tapping a rider's avatar or name in the attendee list calls `context.pushNamed('rider_profile', extra: userId)`, which preserves the back button (unlike `goNamed`).
8. **`AppRoutes.riderProfile` route:** Registered in `lib/shared/router/app_router.dart` with path `/events/attendees/rider/:userId` or similar. Accepts `userId` as a route parameter or extra.
9. **`GetUserByIdUseCase` exists:** If not already present in `lib/features/users/domain/use_cases/`, create it following the standard pattern. Signature: `Future<Either<DomainException, UserModel>> call(String userId)`.
10. **`UserRepositoryImpl.getUserById()`:** Implements the domain interface method to call `UserService.getUserById(userId)` and map the DTO to a domain model.
11. **DI registration:** `GetUserByIdUseCase` is registered in `lib/core/di/injection.dart`.
12. **Attendee list tap handler:** In the existing attendee list widget (e.g., `event_detail_page.dart` or a dedicated attendee list widget), each rider item has an `onTap` that calls `context.pushNamed('rider_profile', extra: userId)`.
13. **New ARB keys:** (Populated in the next section — see localization.)
    - `rider_profileTitle` — "Perfil del motorista" or similar
    - `rider_noVehicles` — "Sin vehículos registrados" or similar
    - `rider_errorRetry` — "Reintentar"
14. **No hardcoded strings:** All user-visible text uses `context.l10n` keys from `app_es.arb`.
15. **Widget tests:**
    - `RiderProfilePage` in loading state shows shimmer
    - Data state shows rider name, email, and vehicle list
    - Error state shows error banner with retry button
    - Tapping a rider in the attendee list navigates to the rider profile page
16. **Integration test:** Rider A views event detail → taps a rider in the attendee list → navigates to the rider's profile page → sees their name, email, and vehicles → back button returns to attendee list.
17. **Build runner:** `dart run build_runner build --delete-conflicting-outputs` runs cleanly.
18. **Linting:** `dart analyze` passes with zero violations.
19. **Testing:** `flutter test` passes with 100% green tests.

---

## New Localization Keys

Add to `lib/l10n/app_es.arb` (Spanish only):

```json
{
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
}
```

---

## Backend Risk: Event Filter Gap

**Status:** Confirmed gap.

**Details:**  
- Current: `GET /events` and `GET /events/upcoming` do not accept or forward filter params (`type`, `dateFrom`, `dateTo`, `city`).
- Impact: Frontend can dispatch filters but backend ignores them — riders always see all events.
- Scope: Backend changes are **in scope for Iteration 2**. The architect will define the exact endpoint contracts (param names, types, WHERE logic) in `docs/handoffs/contracts/iter-2/backend_filter_contract.json`.

**Mitigation:**  
Backend agent will:
1. Add query params to both routes in the api-gateway (pass-through to events-ms).
2. Implement WHERE logic in events-ms `findAllEvents`.
3. Write unit tests for all filter combinations.

---

## Scope Decisions

### In Scope
- Backend filter parameter forwarding (`GET /events`, `GET /events/upcoming`)
- Prisma WHERE clause for each filter (type, date range, city)
- `EventsCubit` state refactor to include active filter
- Filter UI wiring (bottom sheet → `applyFilters()`)
- Attendee list tap → navigate to `RiderProfilePage`
- `RiderProfilePage` implementation (read-only display)
- All new localization keys (Iteration 2 Spanish only)
- Unit tests for filter logic and `RiderProfilePage` fetch
- Widget tests for filter empty state and rider profile states

### Out of Scope (Deferred)
- Advanced filter UI (search-as-you-type city autocomplete, event type tags, calendar picker fancy styling)
- Multi-language support (English); Spanish only for Iteration 2
- Rider profile photo upload (no `User.profilePhotoUrl` field in current Prisma schema; deferred to post-6b)
- Rider profile edit affordances
- Event organizer's ability to see attendee details (organizer access control is handled elsewhere)
- Favoriting or saving filters for quick re-apply

---

## Acceptance Checklist

Before handing off to Architect:

- [ ] All 3 user stories written with full acceptance criteria
- [ ] Backend gap (filter params) clearly documented and scoped
- [ ] New localization keys listed and ready for ARB file
- [ ] `EventsState` and `EventFilter` model shape defined
- [ ] Scope boundaries clear (what is in, what is out)
- [ ] No external dependencies or unknowns

**Sign-off:** Ready for Architect phase. No open questions.

---

## Next Phase: Architect

The Architect will:
1. Define the exact backend endpoint contracts and DTO shapes.
2. Design the `EventsState` and `EventFilter` freezed classes.
3. Update the `GetEventsUseCase` signature.
4. Create ADRs for state refactoring decisions.
5. Produce a handoff for backend and frontend agents.

Run `/solo-architect` to proceed.

---

## Related Documents

- **docs/PRD.md** § Iteration 2 — Event Discovery Filters + Attendee Profile Links
- **docs/PLAN.md** — Iteration 2 row and technical notes
- **workflow/state.json** — tasks for Iteration 2
- **docs/handoffs/iteration_context.md** — bridge from Iteration 1 to Iteration 2 (updated at closeout)
