# Architect → Frontend Handoff — Iteration 2

**Iteration:** 2 | **Agent:** frontend | **Status:** READY

---

## ADR-3 Summary: No EventsState Freezed Refactor

Keep `EventsCubit extends Cubit<ResultState<List<EventModel>>>`.
Keep existing `EventFilters` plain class. Only wire `_filters` to the backend call.

---

## Task 1: Wire EventsCubit to Backend Filters

### GetEventsUseCase — updated signature
```dart
Future<Either<DomainException, List<EventModel>>> call({
  String? type,
  String? dateFrom,
  String? dateTo,
  String? city,
})
```

### EventRepository — updated interface
```dart
Future<Either<DomainException, List<EventModel>>> getEvents({
  String? type, String? dateFrom, String? dateTo, String? city,
});
```

### EventService — new @Query params
```dart
@GET(ApiRoutes.events)
Future<List<EventDto>> getEvents({
  @Query('type') String? type,
  @Query('dateFrom') String? dateFrom,
  @Query('dateTo') String? dateTo,
  @Query('city') String? city,
});
```

### EventRepositoryImpl — convert and forward
In `getEvents()`, read params and forward to `_eventService.getEvents(...)`.

### EventsCubit.fetchEvents() — pass current filters
```dart
Future<void> fetchEvents() async {
  emit(const ResultState.loading());
  final f = _filters;
  final result = await _getEventsUseCase(
    type: f.types.isNotEmpty ? f.types.first.name : null,
    dateFrom: f.startDate?.toIso8601String().substring(0, 10),
    dateTo: f.endDate?.toIso8601String().substring(0, 10),
    city: f.city,
  );
  result.fold(
    (error) => emit(ResultState.error(error: error)),
    (events) { _allEvents = events; _applyFiltersAndEmit(); },
  );
}
```

`updateFilters()` and `clearFilters()` must call `fetchEvents()` after setting `_filters`.

**Note:** `difficulties`, `freeOnly`, `multiBrandOnly` remain local-only filters.

---

## Task 2: GetUserByIdUseCase + Repository + Service

### New file: `lib/features/users/domain/use_cases/get_user_by_id_use_case.dart`
```dart
@injectable
class GetUserByIdUseCase {
  GetUserByIdUseCase(this._userRepository);
  final UserRepository _userRepository;
  Future<Either<DomainException, UserModel>> call(String userId) =>
      _userRepository.getUserById(userId);
}
```

### UserRepository — add method
```dart
Future<Either<DomainException, UserModel>> getUserById(String userId);
```

### UserService — add endpoint
```dart
@GET('/users/{id}')
Future<UserDto> getUserById(@Path('id') String id);
```

### UserRepositoryImpl — implement
```dart
Future<Either<DomainException, UserModel>> getUserById(String userId) =>
    executeService(function: () => _userService.getUserById(userId));
```

---

## Task 3: RiderProfileCubit

### New file: `lib/features/users/presentation/cubit/rider_profile_cubit.dart`
```dart
@injectable
class RiderProfileCubit extends Cubit<ResultState<UserModel>> {
  RiderProfileCubit(this._getUserByIdUseCase) : super(const ResultState.initial());
  final GetUserByIdUseCase _getUserByIdUseCase;

  Future<void> fetchRiderProfile(String userId) async {
    emit(const ResultState.loading());
    final result = await _getUserByIdUseCase(userId);
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (user) => emit(ResultState.data(data: user)),
    );
  }
}
```

---

## Task 4: RiderProfilePage

**File:** `lib/features/users/presentation/pages/rider_profile_page.dart`

- Accepts `String userId` from route extra
- Provides `RiderProfileCubit` via `BlocProvider(create: (_) => getIt<RiderProfileCubit>()..fetchRiderProfile(userId))`
- Four ResultState branches: loading (CircularProgressIndicator), data (name + email + note "Sin vehículos registrados"), error (banner + retry), empty (not expected)
- AppBar title: `context.l10n.rider_profileTitle`
- All strings from `context.l10n`

Widgets (one-per-file rule):
- `lib/features/users/presentation/widgets/rider_profile_content.dart` — data state
- `lib/features/users/presentation/widgets/rider_profile_loading.dart` — loading state

---

## Task 5: Route Registration

### app_routes.dart
```dart
static const String riderProfile = '/events/attendees/rider-profile';
```

### app_router.dart — add route (under eventAttendees or top-level)
```dart
GoRoute(
  path: AppRoutes.riderProfile,
  name: AppRoutes.riderProfile,
  builder: (context, state) {
    final userId = state.extra as String;
    return RiderProfilePage(userId: userId);
  },
),
```

### AttendeesList — wire tap
In `AttendeeProcessedItem.onTap`:
```dart
onTap: () => context.pushNamed(AppRoutes.riderProfile, extra: registration.userId),
```

---

## Task 6: Localization (app_es.arb)

Add if not already present:
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

---

## Build Runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

Regenerates: `event_service.g.dart`, `user_service.g.dart`, `injection.config.dart`.
