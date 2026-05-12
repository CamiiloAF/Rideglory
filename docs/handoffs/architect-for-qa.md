# Architect → QA Handoff — Iteration 2

**Iteration:** 2 | **Agent:** qa | **Status:** READY

---

## Test Commands

```bash
dart analyze                                        # zero violations required
flutter test                                        # 100% green required
dart run build_runner build --delete-conflicting-outputs  # must succeed cleanly
```

---

## Acceptance Criteria Traceability

### US-2-1 / US-2-2: Event Filters

| AC | Test type | What to verify |
|----|-----------|----------------|
| Backend filter params forwarded | Backend unit tests (NestJS) | GET /events with type/dateFrom/dateTo/city applies WHERE |
| fetchEvents() passes filters to use case | Cubit unit test (bloc_test) | `EventsCubit.fetchEvents()` calls `GetEventsUseCase` with correct params |
| updateFilters() triggers backend fetch | Cubit unit test | `updateFilters(filters)` → emits loading → data |
| clearFilters() resets and re-fetches | Cubit unit test | `clearFilters()` → `_filters` reset → loading → data |
| Filter badge count (0 when no filters) | Widget test | Badge hidden when `!cubit.filters.hasFilters` |
| Filter badge count (1-N when active) | Widget test | Badge shows correct count |
| Filtered empty state ("No hay eventos con estos filtros") | Widget test | `ResultState.empty()` + `hasFilters == true` |
| All-events empty state (original message) | Widget test | `ResultState.empty()` + `hasFilters == false` |
| Clear filters button visible only when active | Widget test | Visible iff `hasFilters == true` |

### US-2-3: Attendee Profile Navigation

| AC | Test type | What to verify |
|----|-----------|----------------|
| GetUserByIdUseCase calls repository | Unit test | Mock repo called with correct userId |
| RiderProfileCubit loading state | Cubit unit test (bloc_test) | Initial emit is loading |
| RiderProfileCubit data state | Cubit unit test | On success, emits `data(user)` |
| RiderProfileCubit error state | Cubit unit test | On failure, emits `error(...)` |
| RiderProfilePage loading UI | Widget test | Loading indicator shown |
| RiderProfilePage data UI | Widget test | Shows rider name and email |
| RiderProfilePage error UI | Widget test | Error banner + retry button |
| Attendee tap navigates to rider profile | Widget test | `pushNamed(riderProfile, extra: userId)` called |

---

## Existing Tests — No Regression

Existing `EventsCubit` tests must still pass. Because we are NOT doing the freezed state refactor,
no existing cubit test structure changes. Verify:
- `fetchEvents()` still works when `_filters` is empty (backward compat)
- `updateFilters()` and `clearFilters()` still apply local filters for `difficulties`/`freeOnly`/`multiBrandOnly`

---

## Out of Scope

- Backend filter unit tests are written by the backend agent (NestJS/Jest)
- Integration test for full flow (attendee → profile) is optional for iter-2
