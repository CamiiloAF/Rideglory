# Existing System Scan — Rideglory

> **Generated:** 2026-05-12 (scanning session)
> **Flutter app:** `/Users/cami/Developer/Personal/Rideglory/lib/`
> **Backend:** `/Users/cami/Developer/Personal/rideglory-api` (NestJS microservices)
> **Architecture:** Clean Architecture (domain/data/presentation per feature) + BLoC/Cubit state management

---

## Flutter Feature Inventory

| Feature | Domain Models | Data (DTOs/Services) | Presentation (Cubits/Pages) | Status |
|---------|--------------|---------------------|---------------------------|--------|
| **authentication** | None (uses AuthService directly) | Firebase Auth via AuthService | AuthCubit (AuthState), Login/SignUp pages/widgets | Implemented |
| **event_registration** | EventRegistrationModel, RegistrationWithEvent, VehicleSummaryModel | EventRegistrationDto, VehicleSummaryDto, RegistrationService | RegistrationFormCubit, MyRegistrationsCubit, Pages: event_registration, my_registrations, registration_detail | Implemented |
| **events** | EventModel, RiderProfileModel, RiderTrackingModel, UpdateLocationRequest, UploadEventImageRequest | EventDto (+ converters), RiderProfileDto, RiderTrackingDto (+ converters), EventService, TrackingWsClient | EventFormCubit, EventsCubit, EventDetailCubit, AttendeesCubit, LiveTrackingCubit; Pages: form, list, detail, attendees, live_tracking | Implemented |
| **home** | HomeData | HomeDto, HomeService | HomeCubit (HomeState), home_page | Implemented |
| **maintenance** | MaintenanceModel, MaintenanceListSummary, MaintenanceUserListAggregate, MaintenanceVehicleListResult | MaintenanceDto, VehicleMaintenancesListResponseDto, MaintenanceService | MaintenancesCubit, MaintenanceFormCubit, MaintenanceDeleteCubit, VehicleMaintenancesCubit; Pages: form, detail | Implemented |
| **profile** | None | None | profile_page only | Stub (UI only, no cubit/service) |
| **splash** | None | None | SplashCubit (SplashState), splash_screen + widgets | Implemented (startup flow) |
| **users** | UserModel | UserDto, CreateUserDto, UserService | None (no presentation cubit) | Implemented (domain/data only) |
| **vehicles** | VehicleModel | VehicleDto, VehicleService | VehicleCubit, VehicleFormCubit, VehicleDeleteCubit; Pages: garage, form; Widgets: vehicle_card, vehicle_selector | Implemented |

---

## Key Dependencies

| Category | Package | Purpose | Version |
|----------|---------|---------|---------|
| **State management** | flutter_bloc | BLoC pattern | ^9.1.1 |
| **State management** | bloc | Core BLoC | ^9.1.0 |
| **Code generation** | freezed | Immutable model generation | ^3.2.3 |
| **Code generation** | json_serializable | DTO serialization | ^6.11.3 |
| **Code generation** | injectable | Dependency injection setup | ^2.7.1+2 |
| **Code generation** | injectable_generator | DI code gen | ^2.7.1 |
| **Code generation** | retrofit_generator | HTTP client code gen | ^10.2.5 |
| **HTTP client** | dio | HTTP requests | ^5.9.2 |
| **HTTP client** | retrofit | REST client generation | ^4.9.2 |
| **DI Container** | get_it | Service locator | ^9.2.0 |
| **Router** | go_router | Navigation & deep linking | ^17.0.0 |
| **Firebase** | firebase_core | Firebase initialization | ^4.2.1 |
| **Firebase** | firebase_auth | Email/Google/Apple auth | ^6.1.2 |
| **Firebase** | cloud_firestore | Firestore (not actively used) | ^6.1.0 |
| **Firebase** | firebase_storage | Image/document upload | ^13.1.0 |
| **Firebase** | firebase_remote_config | Base URL config (prod) | ^6.4.0 |
| **Forms** | flutter_form_builder | Form UI/validation | ^10.2.0 |
| **Forms** | form_builder_validators | Validation rules | ^11.0.0 |
| **Localization** | intl | i18n framework | ^0.20.2 |
| **Maps** | google_maps_flutter | Live tracking map | ^2.10.0 |
| **Location** | geolocator | GPS updates | ^14.0.2 |
| **Location** | geocoding | Address ↔ coordinates | ^3.0.0 |
| **WebSocket** | web_socket_channel | Real-time tracking | ^3.0.3 |
| **Storage** | shared_preferences | Local persistence | ^2.3.5 |
| **Storage** | flutter_secure_storage | Token storage | ^10.1.0 |
| **Storage** | image_picker | Select images | ^1.2.1 |
| **Utilities** | dartz | Either/functional patterns | 0.10.1 |
| **UI** | google_fonts | Space Grotesk typography | ^8.0.2 |
| **UI** | flutter_quill | Rich text editor | ^11.0.0 |
| **UI** | cached_network_image | Image caching | ^3.4.1 |
| **UI** | shimmer | Loading skeletons | ^3.0.0 |
| **Permissions** | permission_handler | OS permissions | ^11.3.1 |
| **Battery** | battery_plus | Battery awareness | ^6.2.1 |
| **Environment** | envied | .env injection | ^1.3.3 |
| **Build** | build_runner | Code generation runner | ^2.10.4 |

---

## rideglory-api Surface

**Architecture:** NestJS microservices with gateway pattern
**Authentication:** Firebase ID token + FirebaseAuthInterceptor (guards all routes)

### Microservices & Endpoints

#### API Gateway (`/api`)
Central proxy for all client requests. Maps to downstream microservices.

| Controller | Endpoint | Method | Purpose |
|-----------|----------|--------|---------|
| **events** | `/events` | GET | List all events (paginated/filtered) |
| **events** | `/events/upcoming` | GET | List upcoming events (with date filtering) |
| **events** | `/events/my` | GET | List user's own events (organizer) |
| **events** | `/events/:id` | GET | Event detail by ID |
| **events** | `/events` | POST | Create new event |
| **events** | `/events/:id` | PATCH | Update event |
| **events** | `/events/:id` | DELETE | Delete event |
| **registrations** | `/registrations/me` | GET | Get user's registrations (all statuses) |
| **registrations** | `/events/:eventId/registrations` | GET | Get event's registrations (organizer view) |
| **registrations** | `/events/:eventId/registrations` | POST | Register for event |
| **registrations** | `/registrations/:registrationId` | PATCH | Update registration status (approve/reject) |
| **registrations** | `/registrations/:registrationId` | POST | Custom registration updates |
| **vehicles** | `/vehicles` | GET | List all vehicles (public) |
| **vehicles** | `/vehicles/my` | GET | Get user's vehicles |
| **vehicles** | `/vehicles/my` | POST | Create new vehicle |
| **vehicles** | `/vehicles/my/:id` | PUT | Update user's vehicle |
| **vehicles** | `/vehicles/hard-delete/:id` | DELETE | Hard delete vehicle |
| **users** | `/users/me` | GET | Get current user profile |
| **users** | `/users/sign-up` | POST | User registration (during auth signup) |
| **users** | `/users/:id` | GET | Get user profile by ID |
| **users** | `/users/:id` | PATCH | Update user profile |
| **maintenances** | `/maintenances/vehicle/:vehicleId` | GET | Get vehicle's maintenance records |
| **maintenances** | `/maintenances/vehicle/:vehicleId` | POST | Create maintenance record |
| **maintenances** | `/maintenances/vehicle/:vehicleId/:maintenanceId` | PATCH | Update maintenance record |
| **maintenances** | `/maintenances/vehicle/:vehicleId/:maintenanceId` | DELETE | Delete maintenance record |
| **tracking** | `/tracking/ws` | GET (WebSocket) | Live tracking WebSocket connection |
| **tracking** | `/tracking/positions` | POST | Publish rider location (HTTP fallback) |
| **places** | `/places/autocomplete` | GET | Google Places autocomplete |
| **home** | `/home` | GET | Dashboard home data (recommended events, garage summary, etc.) |

#### Events Microservice (`events-ms`)
- Events CRUD + event state transitions
- Event registration workflows (pending → approved/rejected)
- Tracking session management (maps event status to WebSocket broadcast rooms)
- Real-time tracking data persistence

#### Vehicles Microservice (`vehicles-ms`)
- Vehicle CRUD per user
- Vehicle archive/unarchive (soft delete)
- Main vehicle selection

#### Users Microservice (`users-ms`)
- User profile management
- User creation during signup
- Profile photo storage reference

#### Maintenances Microservice (`maintenances-ms`)
- Maintenance record CRUD per vehicle
- Filtered lists by vehicle

#### Tracking (within events-ms)
- WebSocket live tracking (`/tracking/ws`)
- HTTP fallback position updates
- Broadcast rooms per event session
- Rider location streaming

---

## Design Artifacts

**Status:** No existing Pencil designs or HTML mockups

| Artifact | Location | Content |
|----------|----------|---------|
| Pencil design file | Not found | Expected: `pencil-new.pen` (per HU-DESIGN-01, referenced but not yet created) |
| HTML mockups | `/docs/design/html-mockups/` | Empty directory |
| Stitch prototypes | `/Users/cami/Downloads/stitch_rideglory/` (external) | Referenced as image source in PRD; not in repo |
| Design handoff | Not found | No `docs/handoffs/design.md` |

**Design System Definition (in code):**
- **Theme file:** `/lib/core/theme/` — dark mode with orange primary `#f98c1f`
- **Design tokens:** Space Grotesk font, 8px border radius, dark background
- **Atoms:** `/lib/design_system/atoms/` — buttons, text fields
- **Molecules:** `/lib/design_system/molecules/` — composite components
- **Organisms:** `/lib/design_system/organisms/` — feature-level components
- **Shared widgets:** `/lib/shared/widgets/` — app-wide components (AppButton, AppDialog, etc.)

**No Pencil variables file created yet.** Design system currently lives in Flutter code only.

---

## PRD Gap Analysis

| Requirement | Status | Notes |
|-------------|--------|-------|
| **Authentication (email/Google/Apple)** | Implemented | AuthService handles Firebase Auth; AuthCubit manages state; login/signup pages complete |
| **Vehicle Garage (CRUD)** | Implemented | VehicleCubit + VehicleFormCubit; Firebase image uploads via ImageStorageService; edit/delete/archive in place |
| **Event Discovery (list/detail/filter)** | Implemented | EventsCubit; list + detail pages; no filter UI yet (form fields exist) |
| **Event Registration (register/approval workflow)** | Implemented | EventRegistrationCubit + MyRegistrationsCubit; approval/rejection via UpdateEventRegistration use case |
| **Live Event Tracking (WebSocket + map)** | Implemented | LiveTrackingCubit; TrackingWsClient; LiveMapPage with Google Maps; real-time rider positions |
| **User Profiles (view own/others)** | Partial | UserModel + UserService exist; ProfilePage stub (UI only, no data binding) |
| **Maintenance Log** | Implemented | MaintenancesCubit + MaintenanceFormCubit; CRUD per vehicle |
| **SOAT & Insurance Documents** | Not started | No domain models, DTOs, services, or UI; no AI extraction; no document upload flow |
| **AI Event Cover Generation** | Not started | Button exists in EventFormPage but not wired to backend; no backend endpoint; no image generation service |
| **AI Event Recommendations** | Not started | Card exists on HomePage but not wired; no backend endpoint; no recommendation logic |
| **Push Notifications (FCM)** | Not started | No firebase_messaging integration; no FCM token registration; no notification handlers; no deep link setup |
| **SOS Alert (WebSocket)** | Not started | No SOS message type in TrackingWsClient; no UI overlay on live map; no broadcast logic |
| **Test coverage** | Minimal | Only `test/widget_test.dart` exists (empty); no unit/widget/integration tests for any feature |

---

## Key Architectural Patterns

### Authentication
- **Firebase Auth:** Email, Google, Apple sign-in via `AuthService` (singleton)
- **Token handling:** Firebase ID token auto-refreshed by Firebase SDK; injected by `FirebaseAuthInterceptor` in Dio
- **State management:** `AuthCubit` with `AuthState` freezed union (initial, authenticated, unauthenticated, loading, error)
- **Current user:** Stored in `AuthService.currentUser` (either `UserModel` or `FirebaseUser`)

### HTTP & Error Handling
- **Base URL resolution:** 
  - Dev: `.env` file (`localhost:3000/api` for iOS sim, `10.0.2.2:3000/api` for Android emulator)
  - Prod: Firebase Remote Config
- **HTTP client:** Dio + Retrofit (code-generated); auto-retry, 20s timeout
- **Error mapping:** `executeService()` in `rest_client_functions.dart` wraps calls, maps HTTP errors → `DomainException` with Spanish user messages
- **Functional style:** `Either<DomainException, T>` from dartz for error handling (domain/data layer convention)

### State Management
- **Simple async:** `Cubit<ResultState<T>>` for single data source (e.g., `VehicleCubit`, `MaintenancesCubit`)
- **Complex state:** `@freezed` state class with multiple `ResultState<T>` fields (e.g., `EventDetailState`, `VehicleFormState`)
- **No boolean flags:** Use `ResultState` (initial/loading/data/empty/error) instead of separate loading/error flags
- **Dependency injection:** GetIt service locator with `@injectable`, `@singleton` annotations; DI setup in `lib/core/di/injection.dart`

### Routing & Navigation
- **Framework:** go_router with declarative routes
- **Auth guard:** `redirect` function checks Firebase auth; unauthenticated users → login
- **Navigation conventions:**
  - `context.pushNamed('routeName')` — normal transitions (preserves back button)
  - `context.goAndClearStack('routeName')` — auth state changes, clears stack
  - Avoid `context.goNamed()` for feature flows
- **Deep linking:** Routes support params via `extra` (e.g., `registration_detail` with `RegistrationDetailExtra`)

### Localization
- **Source:** `lib/l10n/app_es.arb` (Spanish primary; no English translation yet)
- **Generation:** `dart run build_runner build` (or `flutter gen-l10n`)
- **Usage:** `context.l10n.<keyName>` (extension in `lib/core/extensions/l10n_extensions.dart`)
- **Key naming:** Feature prefix + descriptor (e.g., `event_title`, `vehicle_licensePlate`, `auth_welcomeMessage`)
- **No hardcoded UI strings**

### Real-time Tracking
- **WebSocket client:** `TrackingWsClient` (in `events/data/service/`)
- **Connection:** `GET /api/tracking/ws` (authenticated)
- **Message types:** Position updates with `{ type: "position", lat, lng, eventId, riderId }`
- **Reconnect:** Auto-reconnect with exponential backoff on disconnect
- **Broadcast:** Server broadcasts rider positions to all connected clients in same event
- **Flutter integration:** `watch_active_riders_use_case.dart` streams `List<RiderTrackingModel>` to UI

### Naming Conventions
- **Models:** PascalCase, no suffix (e.g., `VehicleModel`, `EventModel`)
- **DTOs:** PascalCase + `Dto` suffix (e.g., `VehicleDto`, `EventDto`)
- **Use cases:** PascalCase + `UseCase` suffix (e.g., `GetVehiclesUseCase`)
- **Repositories:** PascalCase + `Repository`/`RepositoryImpl` (e.g., `VehicleRepository` interface, `VehicleRepositoryImpl`)
- **Services:** PascalCase + `Service` suffix (e.g., `VehicleService`, `AuthService`)
- **Cubits:** PascalCase + `Cubit` suffix (e.g., `VehicleCubit`, `EventDetailCubit`)
- **Pages:** snake_case + `_page.dart` (e.g., `vehicle_form_page.dart`)
- **Widgets:** snake_case + `.dart`; one widget per file
- **Constants:** UPPER_SNAKE_CASE in dedicated `constants/` folders

### Firebase & Storage
- **Authentication:** firebase_auth (email, Google, Apple)
- **Remote config:** firebase_remote_config (prod base URL)
- **Cloud Storage:** firebase_storage (vehicle photos, user profiles, documents)
- **No Firestore collections** used in current codebase (all data from REST API)

---

## Known Gaps & Technical Debt

| Area | Gap | Impact |
|------|-----|--------|
| **Test coverage** | Only 1 empty test file; no unit/widget/integration tests | Cannot run CI checks; no regression detection |
| **Insurance/SOAT feature** | Domain/data/presentation layers missing; no PDF upload; no AI extraction | Cannot implement PRD requirement HU-SOAT-01 |
| **AI features** | No backend endpoints; no UI wiring; no Claude API integration | Cannot implement HU-AI-01 (event covers) or HU-AI-02 (recommendations) |
| **Push notifications** | No firebase_messaging integration; no FCM token handling; no deep link setup | Cannot implement HU-PUSH-01 notification triggers |
| **SOS alert** | No WebSocket message type; no UI overlay; no broadcast logic | Cannot implement real-time SOS feature |
| **Design handoff** | No Pencil design file; no HTML mockups; design only in code | Blocks HU-DESIGN-01 (Pencil design system setup) |
| **Profile feature** | Page stub only; no cubit, service, or data binding | Profile displays no data; view-only |
| **Authentication** | No Clean Architecture separation (no domain/data layers); uses AuthService directly | Authentication logic tightly coupled; harder to test/refactor |
| **Linting** | `dart analyze` likely has violations (not verified in this scan) | CI will fail until fixed |
| **Build artifacts** | No CI/CD pipeline defined; no `.github/workflows/` | Blocks automated testing/deployment |

---

## Current codebase metrics

| Metric | Count |
|--------|-------|
| Feature folders | 9 (authentication, event_registration, events, home, maintenance, profile, splash, users, vehicles) |
| Domain models | ~20 |
| DTOs | ~15 |
| Cubits | 17 |
| Pages | 15+ |
| Core services | 6 (auth, location, image_storage, user_storage, place_service) |
| Microservices | 5 (api-gateway, events-ms, vehicles-ms, users-ms, maintenances-ms) |
| API endpoints | 40+ (across all controllers) |
| Test files | 1 (empty) |
| Design artifacts | 0 (no Pencil, no HTML mockups) |

---

## Planning Implications

1. **Test suite is critical first step** — HU-TEST-01 must precede feature development. Current 0% coverage blocks CI. Recommend: unit tests for domain/data, widget tests for pages, 1 integration test per feature.

2. **Insurance/SOAT feature requires full stack** — New domain layer (InsuranceDocumentModel), data layer (DTOs, PDF service, AI extraction via Claude API), presentation layer (upload form, status indicator). Backend endpoint needed in rideglory-api. Estimate: 2–3 days.

3. **AI features (covers + recommendations)** — Event cover generation needs backend endpoint + Claude Imagen/DALL-E integration. Recommendations need scoring algorithm + caching. Button/card UI already exists; backend is the blocker. Estimate: 2–3 days per feature.

4. **Push notifications (FCM)** — Requires firebase_messaging integration, token storage in rideglory-api, deep link configuration, and FCM sending logic. No dependencies installed yet. Estimate: 2 days.

5. **Design system in Pencil** — HU-DESIGN-01 is a precursor task; all future UI changes should flow through Pencil first. No .pen file exists yet; recommend creating `pencil-new.pen` with design tokens, component library, and screen flows before starting UI iterations.

6. **SOS alert** — Relatively small feature (WebSocket message type, UI overlay, broadcast logic); should fit in larger real-time tracking iteration. Estimate: 1 day.

7. **Profile feature** — Currently a stub page with no data binding. Should be completed as part of user management iteration. Estimate: 1 day.

8. **Authentication refactoring (optional)** — Currently non-standard (no domain/data layers). If full Clean Architecture adoption is desired, refactor to match other features. Low priority; doesn't block other work.

9. **Brownfield status:** Most core features exist but lack test coverage and advanced features (AI, insurance, notifications). Next iterations should prioritize stabilization (tests) + advanced features (SOAT, AI, FCM, SOS) before scaling.

