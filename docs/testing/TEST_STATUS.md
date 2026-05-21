# Test Status Report — Rideglory
Generated: 2026-05-20

## Summary
| Category | Result |
|----------|--------|
| dart analyze | 0 errors, 1 warning, 1 info |
| flutter test | 108 passed, 0 failed, 0 skipped |
| Patrol e2e | NOT RUN — credentials required (TEST_EMAIL / TEST_PASSWORD) |
| Overall | HEALTHY |

### dart analyze detail
- `lib/core/http/api_base_url_resolver.dart:19` — `dead_code` warning (pre-existing)
- `lib/core/http/api_base_url_resolver.dart:17` — `prefer_const_declarations` info (pre-existing)
- No ERROR-level findings.

---

## Per-feature coverage
| Feature | Unit | Widget | E2E | Status |
|---------|------|--------|-----|--------|
| Authentication | AuthCubit (12 tests) | - | - | PARTIAL |
| Vehicles | VehicleCubit (11 tests) | - | NOT RUN | PARTIAL |
| Events | UseCase + FilterCubit + 3 widgets (27 tests) | 3 widget tests | NOT RUN | PARTIAL |
| Event Registration | MyRegistrationsCubit (7 tests) | - | - | PARTIAL |
| Maintenance | MaintenancesCubit (9 tests) | - | - | PARTIAL |
| Notifications | NotificationsCubit (existing) | - | - | PARTIAL |
| Profile | ProfileCubit (4 tests) | - | NOT RUN | PARTIAL |
| SOAT | SoatModel + SoatCubit (6 tests) | - | - | COVERED |
| Users | UseCase + Cubit + Page (15 tests) | RiderProfilePage (5 tests) | NOT RUN | COVERED |
| Home | - | - | NOT RUN | MISSING (unit) |
| Splash | - | - | - | MISSING |

---

## Failing tests
None. All 108 tests pass.

---

## New tests added this run
| File | Tests Added |
|------|-------------|
| `test/features/authentication/application/auth_cubit_test.dart` | 12 |
| `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` | 11 |
| `test/features/maintenance/presentation/cubit/maintenances_cubit_test.dart` | 9 |
| `test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart` | 7 |
| **Total new** | **39** |

Previous count: 69 tests
Current count: 108 tests

---

## Custom-iter created
NONE — no failures and no ERROR-level analyze findings.
No feature has 0 tests anymore (authentication, vehicles, maintenance, event_registration were covered this run).
Remaining gaps (home, splash) are UI-only with no cubit logic worth unit testing in isolation.

---

## Next run recommendations
1. Add widget tests for GaragePage and MaintenancesPage (loading/data/error states).
2. Add widget test for HomeScreen navigation bar.
3. Run Patrol e2e tests with real TEST_EMAIL / TEST_PASSWORD credentials.
4. Fix pre-existing `dead_code` warning in `api_base_url_resolver.dart`.
5. Consider adding `GetMyVehiclesUseCase` unit test (mirrors the users pattern).
