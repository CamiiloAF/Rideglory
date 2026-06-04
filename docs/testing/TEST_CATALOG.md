# Test Catalog — Rideglory
Generated: 2026-05-20 (actualizado: 2026-06-04 — Fase 10: test guardián no-PII de analítica)

## Unit & Widget Tests (`test/`)

### Analytics (Core) — Fase 10 — Guardián no-PII
| File | What it covers | Status |
|------|---------------|--------|
| `test/core/services/analytics/analytics_taxonomy_no_pii_test.dart` | TC-pii-1..10: verifica que todos los nombres de evento ≤40 chars, snake_case, sin substrings PII prohibidos; claves de param ≤40 chars, snake_case, sin PII; nombres de pantalla canónicos sin ids dinámicos; catálogo sin duplicados; umbral de regresión de tamaño. 265 casos generados. | NEW |

### Authentication
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/authentication/application/auth_cubit_test.dart` | AuthCubit: checkAuthState, signInWithEmail (error), signUpWithEmail (error), signOut, sendPasswordResetEmail (success + error), AuthState helpers | NEW |

### Vehicles
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` | VehicleCubit: initial, fetchMyVehicles (data/error/empty), currentVehicle, addVehicleLocally, deleteVehicleLocally, selectVehicle, setMainVehicle, clearVehicles | NEW |

### Events
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` | GetGenerateCoverUseCase | EXISTING |
| `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart` | AttendeesList widget | EXISTING |
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | EventsFilterCubit | EXISTING |
| `test/features/events/presentation/list/widgets/event_filters_bottom_sheet_test.dart` | EventFiltersBottomSheet widget | EXISTING |
| `test/features/events/presentation/list/widgets/events_page_view_test.dart` | EventsPageView widget (empty/data/filtered states) | EXISTING |

### Event Registration
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart` | MyRegistrationsCubit: initial, fetchMyRegistrations (data/error/empty), updateStatusFilter, clearFilters, RegistrationModel helpers | NEW |

### Maintenance
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/maintenance/presentation/cubit/maintenances_cubit_test.dart` | MaintenancesCubit: initial, fetchMaintenances (data/error/empty), addMaintenanceLocally, deleteMaintenanceLocally, updateSearchQuery, calculateStatus | NEW |

### Notifications
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/notifications/presentation/cubit/notifications_cubit_test.dart` | NotificationsCubit | EXISTING |

### Profile
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/profile/presentation/cubit/profile_cubit_test.dart` | ProfileCubit: initial, fetchProfile (success/error), reset | EXISTING |

### SOAT
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/soat/domain/models/soat_model_test.dart` | SoatModel status badge logic | EXISTING |
| `test/features/soat/presentation/cubit/soat_cubit_test.dart` | SoatCubit: load (data/empty/error), save (success/error) | EXISTING |

### Users
| File | What it covers | Status |
|------|---------------|--------|
| `test/features/users/domain/use_cases/get_user_by_id_use_case_test.dart` | GetUserByIdUseCase | EXISTING |
| `test/features/users/presentation/cubit/rider_profile_cubit_test.dart` | RiderProfileCubit | EXISTING |
| `test/features/users/presentation/pages/rider_profile_page_test.dart` | RiderProfilePage widget (loading/data/error/initial states) | EXISTING |

### Shared Widgets
| File | What it covers | Status |
|------|---------------|--------|
| `test/shared/widgets/map/route_map_preview_test.dart` | RouteMapPreview widget (loading/error/data/empty states) | EXISTING |

### Root
| File | What it covers | Status |
|------|---------------|--------|
| `test/widget_test.dart` | Placeholder test | EXISTING |

---

## Patrol E2E Tests (`integration_test/`)
Require: `TEST_EMAIL` and `TEST_PASSWORD` dart-defines + Firebase connection

| File | Feature covered | Status |
|------|----------------|--------|
| `integration_test/events_patrol_test.dart` | Events flow (browse, filter) | NOT RUN (credentials required) |
| `integration_test/home_patrol_test.dart` | Home screen navigation | NOT RUN (credentials required) |
| `integration_test/profile_patrol_test.dart` | Profile page flow | NOT RUN (credentials required) |
| `integration_test/vehicles_patrol_test.dart` | Garage / vehicle management | NOT RUN (credentials required) |

---

## Coverage Gap Summary (per feature)

| Feature | Unit | Widget | E2E | Overall Status |
|---------|------|--------|-----|----------------|
| Authentication | AuthCubit (new) | - | - | PARTIAL |
| Vehicles | VehicleCubit (new) | - | patrol (no creds) | PARTIAL |
| Events | UseCase + FilterCubit + 3 widgets | - | patrol (no creds) | PARTIAL |
| Event Registration | MyRegistrationsCubit (new) | - | - | PARTIAL |
| Maintenance | MaintenancesCubit (new) | - | - | PARTIAL |
| Notifications | NotificationsCubit | - | - | PARTIAL |
| Profile | ProfileCubit | - | patrol (no creds) | PARTIAL |
| SOAT | SoatModel + SoatCubit | - | - | COVERED |
| Users | UseCase + Cubit + Page | RiderProfilePage | patrol (no creds) | COVERED |
| Home | - | - | patrol (no creds) | MISSING (unit) |
| Splash | - | - | - | MISSING |
