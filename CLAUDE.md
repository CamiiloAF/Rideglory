# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**Rideglory** is a Flutter mobile application for motorcycle riding events and community coordination. The codebase uses **Clean Architecture** (domain/data/presentation layers), **BLoC/Cubit** for state management, and **Firebase** for authentication and backend integration. The backend API is located in the separate `rideglory-api` repository.

## Quick Commands

### Code Generation & Build
```bash
# Generate code (freezed models, json serialization, injectable DI, retrofit clients, envied config)
dart run build_runner build --delete-conflicting-outputs

# Rebuild only (use when code generation fails due to conflicts)
dart run build_runner rebuild --delete-conflicting-outputs

# Generate localization files from ARB (rare—usually auto-runs with flutter pub get)
flutter gen-l10n

# Analyze code for lint violations
dart analyze
```

### Development & Testing
```bash
# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run with coverage (if configured)
flutter test --coverage

# Format code
dart format lib/

# Check formatting without changes
dart format --output=none lib/
```

### Building & Running
```bash
# Run dev app (hot reload for testing)
flutter run

# Run on specific device
flutter run -d <device_id>

# Build APK for Android
flutter build apk --release

# Build IPA for iOS
flutter build ios --release
```

### Environment Setup
```bash
# Copy and configure the .env file
cp .env.example .env
# Edit .env with real Firebase and Maps credentials

# Copy Firebase configuration files (keep untracked locally)
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist

# After editing .env, regenerate env-related code
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

### Layered Structure (Clean Architecture)

Each feature is organized into three layers:

**Domain** (`lib/features/<feature>/domain/`)
- **Models:** Pure Dart classes (e.g., `VehicleModel`, `EventModel`)
- **Repositories:** Abstract interfaces defining data contracts
- **Use Cases:** Single responsibility classes that orchestrate domain logic
- **Constraints:** No Flutter imports, no HTTP calls, no `dart:io`

**Data** (`lib/features/<feature>/data/`)
- **DTOs:** Data Transfer Objects for API serialization/deserialization (generated with `json_serializable`). **Pattern B is mandatory:** every DTO with a 1:1 domain model MUST extend that model (`XDto extends XModel`) and define a companion `XModelExtension.toJson()` extension. `toModel()`, `fromModel()`, and `.toDto()` are forbidden. Canonical reference: `lib/features/events/data/dto/event_dto.dart`. Exceptions (composite DTOs, request-only DTOs) documented in `.cursor/rules/rideglory-coding-standards.mdc` and `docs/prds/prd-dto-inheritance-standard.md`.
- **Repositories:** Concrete implementations of domain interfaces
- **Services:** Retrofit clients for HTTP calls; WebSocket clients; Firebase integrations
- **Constraints:** No UI/widgets; `BuildContext` forbidden

**Presentation** (`lib/features/<feature>/presentation/`)
- **Cubits:** State management using BLoC pattern (extends `Cubit<ResultState<T>>`)
- **Pages:** Top-level screens (one per file)
- **Widgets:** Reusable UI components within the feature
- **Constraints:** No direct HTTP calls; no DTO exposure (use domain models); depend on Cubits and domain use cases

### State Management: ResultState<T>

All async operations use the `ResultState<T>` freezed union (from `lib/core/domain/result_state.dart`):
```dart
@freezed
class ResultState<T> {
  const factory ResultState.initial() = Initial<T>;
  const factory ResultState.loading() = Loading<T>;
  const factory ResultState.data({required T data}) = Data<T>;
  const factory ResultState.empty() = Empty<T>;
  const factory ResultState.error({required DomainException error}) = Error<T>;
}
```

**Cubit Pattern:**
- Simple async operations: `Cubit<ResultState<T>>` directly
- Complex state (2+ independent results): create a `@freezed` state class with a `ResultState<T>` field per result
- Example: `VehicleCubit` maintains a list of vehicles plus selection state; it extends `Cubit<ResultState<List<VehicleModel>>>`

### Data Flow Example: Vehicles

1. **Domain** (`lib/features/vehicles/domain/`)
   - `VehicleModel`: pure Dart model with copyWith
   - `VehicleRepository`: interface defining `getMyVehicles()`, `addVehicle()`, `setMainVehicle()`, etc.
   - Use cases like `GetMyVehiclesUseCase` that invoke the repository

2. **Data** (`lib/features/vehicles/data/`)
   - `VehicleDto`: JSON-serializable DTO matching API response
   - `VehicleService`: Retrofit-generated REST client with endpoints (`@GET`, `@POST`, etc.)
   - `VehicleRepositoryImpl`: uses DTOs directly as domain models (Pattern B — DTO extends Model); handles Firebase image uploads; wraps HTTP errors in `Either<DomainException, Model>`

3. **Presentation** (`lib/features/vehicles/presentation/`)
   - `VehicleCubit`: singleton cubit with `fetchMyVehicles()`, `selectVehicle()`, `addVehicleLocally()` methods
   - Uses `ResultState` to track loading, data, error states
   - Form cubit `VehicleFormCubit` for multi-step vehicle creation/editing

### HTTP & Error Handling

**REST Client** (`lib/core/http/`)
- **Dio configuration** (`AppDio`): timeouts (20s), Firebase Auth interceptor, debug logging
- **Retrofit**: Code-generated REST clients from annotated service interfaces (e.g., `VehicleService`, `EventService`)
- **Base URL resolution** (`ApiBaseUrlResolver`): dev uses local backend (emulator: `10.0.2.2:3000/api`, iOS sim: `localhost:3000/api`, physical device: `.env` override); production uses Firebase Remote Config
- **Error handling** (`rest_client_functions.dart`): `executeService()` wraps HTTP calls, maps Dio/Firebase exceptions to user-friendly Spanish error messages, returns `Either<DomainException, Model>`

**WebSocket** (Real-time Event Tracking)
- `TrackingWsClient`: manages WebSocket connection to `/tracking/ws` endpoint
- Auto-reconnect on disconnect
- Broadcasts rider locations as `Stream<List<RiderTrackingModel>>`

### Core Services

- **AuthService** (`lib/core/services/auth_service.dart`): Firebase Auth (email, Google, Apple sign-in); token management
- **LocationService**: GPS location updates via `geolocator`
- **UserStorageService**: `SharedPreferences` wrapper for persistent local data
- **ImageStorageService**: Firebase Storage for vehicle/user photos
- **PlaceService**: Mapbox Geocoding API para búsqueda de lugares (Retrofit client)

### Dependency Injection (GetIt + Injectable)

- **Configuration**: `lib/core/di/injection.dart` with `@InjectableInit` and `configureDependencies()`
- **Firebase module** (`lib/core/di/firebase_module.dart`): Provides singleton instances of Firebase services
- **Auto-registration**: Service classes marked with `@injectable`, `@singleton`, or `@lazySingleton`; repositories marked `@Injectable(as: InterfaceType)` to bind implementations
- **main.dart**: Calls `configureDependencies()` at startup; root `MultiBlocProvider` defines global cubits (`AuthCubit`, `VehicleCubit`, `MyRegistrationsCubit`)

## Routing & Navigation

**Router** (`lib/shared/router/app_router.dart`)
- Uses **go_router** for declarative routing
- Auth guard: `redirect` function checks Firebase auth state; redirects to login if needed
- Routes: splash → login/signup → home shell (with bottom nav) → nested feature pages
- **Navigation conventions** (from coding standards):
  - Use `context.pushNamed()` for normal screen transitions (leaves back button enabled)
  - Use `context.goAndClearStack(routeName)` for auth state changes (logout, onboarding completion)
  - Avoid `context.goNamed()` for feature flows

## Localization

**Framework**: Flutter's `gen-l10n` with ARB format
- **Source file**: `lib/l10n/app_es.arb` (Spanish)
- **Generated code**: `lib/l10n/app_localizations.dart` (main) and `app_localizations_es.dart` (translations)
- **Usage**: In widgets with `BuildContext`, call `context.l10n.<keyName>` (extension in `lib/core/extensions/l10n_extensions.dart`)
- **Key naming**: Prefix by feature (e.g., `auth_`, `event_`, `vehicle_`, `maintenance_`, `registration_`)
- **Flow**: Edit `.arb` → run `dart run build_runner build` (or `flutter gen-l10n`) → rebuild generated files → use in UI

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc`, `bloc` | State management (Cubit pattern) |
| `freezed`, `freezed_annotation` | Code-generated immutable models and unions |
| `json_serializable` | JSON ↔ Dart serialization |
| `injectable`, `get_it` | Dependency injection |
| `retrofit`, `dio` | REST client and HTTP layer |
| `go_router` | Declarative routing and navigation |
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_remote_config` | Firebase services |
| `google_sign_in` | OAuth sign-in |
| `mapbox_maps_flutter` | Mapas interactivos con estilos dark custom |
| `geolocator` | GPS location updates |
| `flutter_form_builder`, `form_builder_validators` | Form UI and validation |
| `flutter_quill` | Rich text editor |
| `web_socket_channel` | Real-time event tracking |
| `envied`, `envied_generator` | Environment variable injection |
| `shared_preferences` | Local persistence |
| `dartz` | Functional programming utilities (Either/Right/Left) |
| `intl` | Internationalization |
| `google_fonts` | Typography |

## Design System

**Atoms** (`lib/design_system/atoms/`)
Primitive components (buttons, text fields, etc.)

**Molecules** (`lib/design_system/molecules/`)
Composite components built from atoms

**Organisms** (`lib/design_system/organisms/`)
Feature-level complex components

**Foundation** (`lib/design_system/foundation/`)
Spacing, sizing, border radius constants

**Theme**: Dark mode with orange primary (`#f98c1f`), Space Grotesk font, 8px border radius standard

**Shared Widgets** (`lib/shared/widgets/`)
App-wide reusable components:
- `AppButton`, `AppTextButton`, `AppTextField`, `AppPasswordTextField` (from `form/`)
- `AppDialog`, `ConfirmationDialog` (from `modals/`)
- `EmptyStateWidget`, `NoSearchResultsEmptyWidget`, `VehicleListItem`, `VehicleSelectionBottomSheet`
- Navigation bars, bottom sheets, detail pills, info chips

**Color Scheme**:
- Prefer `Theme.of(context).colorScheme.<property>` (semantically correct, respects theme mode)
- Fallback to `AppColors` constants for colors not in colorScheme (dark backgrounds, borders)

## Code Standards (Summarized from `.cursor/rules/`)

### Strings (Localization)
- All user-visible text in `app_es.arb` with `context.l10n.<key>` in widgets
- Key naming: feature prefix + descriptive name (e.g., `event_title`, `vehicle_licensePlate`)
- No hardcoded string literals in UI

### Architecture Violations to Avoid
- **Domain** must not import Flutter packages or do network I/O
- **Data** must not import widgets or use `BuildContext`
- **Presentation** must not call HTTP clients directly or expose DTOs
- Dependencies flow inward: presentation → domain ← data (domain never depends on data/presentation)

### Cubits & State
- Simple operations: `Cubit<ResultState<T>>`
- Complex state: `@freezed` state class with multiple `ResultState<T>` fields, part of cubit file
- No boolean flags for loading/error (use `ResultState`)

### Widgets — Reglas críticas (violación cero tolerancia)
- **Un widget por archivo**: cada `.dart` tiene máximo 1 clase que extiende `StatelessWidget`/`StatefulWidget`/`PreferredSizeWidget`. La clase `State<T>` sí puede coexistir con su `StatefulWidget`.
- **Prohibidos los métodos que retornan widgets**: `Widget _buildHeader()`, `Widget _ctaBar(context)`, etc. → cada pieza de UI es su propia clase widget en su propio archivo.
- **Siempre verificar `lib/shared/widgets/form/` antes de implementar**: `AppTextField`, `AppMileageField`, `AppDatePicker`, `AppButton`, `AppTextButton`, `FormSectionHeader`, etc. Nunca usar `FormBuilderTextField`, `ElevatedButton` o `TextButton` directamente si existe un equivalente shared.

### Naming & Style
- Variables: avoid single-letter generics (`v`, `e`); prefer domain names (`vehicle`, `event`, `error`)
- Button text: sentence case (`'Iniciar sesión'`, not `'INICIAR SESIÓN'`)
- No obvious comments (class/method names should be self-explanatory)

### Linting
- Follow `analysis_options.yaml` rules: prefer const constructors, avoid print statements, enforce final variables, etc.
- Run `dart analyze` before committing
- Exclusions: `**/*.g.dart`, `**/*.freezed.dart` (code generation output)

## Features Overview

| Feature | Purpose | Key Files |
|---------|---------|-----------|
| **Authentication** | Email/Google/Apple sign-in | `lib/features/authentication/` |
| **Home** | Dashboard and main navigation | `lib/features/home/` |
| **Vehicles** | User garage, add/edit/delete vehicles | `lib/features/vehicles/` |
| **Events** | Create/browse/detail events, real-time tracking | `lib/features/events/` |
| **Event Registration** | Register for events, attendance approval workflow | `lib/features/event_registration/` |
| **Maintenance** | Log vehicle maintenance records | `lib/features/maintenance/` |
| **Users** | User profiles, discovery | `lib/features/users/` |
| **Profile** | Current user profile page | `lib/features/profile/` |
| **Splash** | App startup screen | `lib/features/splash/` |

## Backend Integration

**API Gateway**: Located in the `rideglory-api` repository
- Base URL: resolved from Firebase Remote Config or `.env` override (for dev)
- Authentication: Firebase ID tokens injected by `FirebaseAuthInterceptor`
- Contracts: DTOs in service interfaces must match API response shapes; breaking changes require coordination

**WebSocket**: Real-time tracking at `GET /api/tracking/ws`
- Clients publish location updates; server broadcasts to connected peers
- Auto-reconnect with exponential backoff on disconnect
- Used during active event rides

## Backend Repository

Shared contracts and services are in **`rideglory-api`** (separate Git repo):
- API routes, DTO specs, validation rules
- Microservices (tracking, event management, user management)
- When API contracts change, update DTOs in this repo and regenerate code

## Cursor Rules & Sub-Agents

The `.cursor/rules/` directory defines specialized roles:
- `rideglory-coding-standards.mdc`: Mandatory style/architecture rules (all features)
- `agent-flutter-developer.mdc`: Implementer role (coding, widgets, cubits)
- `agent-clean-architecture-reviewer.mdc`: Senior reviewer role (layer violations, architecture audits)
- `agent-architect.mdc`: Architectural reviewer (scalability, dependencies, lints)
- `agent-devops.mdc`: DevOps/tooling role (CI/CD, YAML configs)

For complex changes, follow the harness pattern in `AGENTS.md`:
1. Implementer (task agent) codes the feature
2. Reviewer (clean architecture agent) audits the diff → feedback
3. Implementer fixes issues → commit
4. (Repeat until approved)

This ensures architectural consistency without manual review steps.

## Debugging & Troubleshooting

**Code generation fails**
- Run `dart run build_runner clean` then rebuild
- Check `.env` for missing/malformed values
- Ensure all `part` directives are present in files using generated code

**Firebase configuration missing**
- Copy example Firebase files and fill real credentials
- Verify `AppEnv` fields in `lib/core/config/app_env.dart` match `.env` keys
- Run `dart run build_runner build` after `.env` changes

**Hot reload not picking up changes**
- Changes to service interfaces (Retrofit), DTOs, or DI config require full rebuild
- Use `flutter run -v` for verbose output

**Lint violations**
- Check `analysis_options.yaml` for the violated rule
- Run `dart analyze --no-summary` for detailed output
- Some rules can be suppressed with `// ignore: rule_name` if justified
