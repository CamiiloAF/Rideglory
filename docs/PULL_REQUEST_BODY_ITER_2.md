# feat(iter-2): Event Discovery Filters + Attendee Profile Links

## Stories Delivered

### US-2-1: Event List Filters
- `GetEventsUseCase` forwards `type`, `dateFrom`, `dateTo`, `city` query params to the API
- `EventsCubit.updateFilters()` maps `EventFilters` → backend params and triggers re-fetch
- Filter bottom sheet wired to `updateFilters()` — type chips, city text field, date range picker
- Active filter badge on filter icon (hidden when no filters)
- Filtered empty state: "No hay eventos con estos filtros"

### US-2-2: Clear Filters
- "Limpiar filtros" button in filter bottom sheet (visible only when `hasFilters`)
- "Limpiar filtros" button in filtered empty state
- `EventsCubit.clearFilters()` resets `EventFilters` and re-fetches all events

### US-2-3: Attendee Profile Navigation
- `AttendeesList` items are now tappable — tap routes to `RiderProfilePage(userId)`
- `RiderProfileCubit` + `GetUserByIdUseCase` fetch and display rider data
- Profile page shows full name, email, residence city, avatar initials
- Error state with retry button; loading skeleton

## Deferred
- TC-2-25 filter badge count (widget test deferred — badge renders correctly per manual verification)
- Backend filter integration tests (verified manually; unit tests in `rideglory-api`)

## Test Results
| Suite | Tests | Status |
|-------|-------|--------|
| EventsCubit filter logic | 10 | ✅ All pass |
| RiderProfileCubit | 6 | ✅ All pass |
| GetUserByIdUseCase | 4 | ✅ All pass |
| EventsPageView widget | 5 | ✅ All pass |
| EventFiltersBottomSheet widget | 3 | ✅ All pass |
| AttendeesList navigation | 3 | ✅ All pass |
| RiderProfilePage widget | 5 | ✅ All pass |
| **Total** | **36** | ✅ **All pass** |

## Handoffs
- [PO](docs/handoffs/po.md) | [Architect](docs/handoffs/architect.md) | [Design](docs/handoffs/design.md)
- [Backend](docs/handoffs/backend.md) | [Frontend](docs/handoffs/frontend.md)
- [QA](docs/handoffs/qa.md) | [DevOps](docs/handoffs/devops.md)

## Test plan
- [ ] Run `flutter test` — all 36 iter-2 tests pass
- [ ] Run `dart analyze` — zero new violations
- [ ] Open app → event list → tap filter icon → apply city filter → verify filtered results
- [ ] Clear filters → verify all events return
- [ ] Open event attendees list → tap an attendee → verify profile page loads
- [ ] Verify profile page shows name, email, avatar initials

🤖 Generated with [Claude Code](https://claude.com/claude-code)
