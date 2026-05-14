# Existing System Scan — Rideglory

> Generated: 2026-05-13
> Flutter app: /Users/cami/Developer/Personal/Rideglory/lib/
> Backend: /Users/cami/Developer/Personal/rideglory-api

---

## 1. Flutter Feature Inventory

| Feature | Domain Models | Data (DTOs/Services) | Presentation (Cubits/Pages) | Status |
|---------|---------|---------|---------|---------|
| **Authentication** | — | Firebase Auth integration | AuthCubit, LoginPage, SignupPage, PasswordRecoveryPage | Implemented |
| **Splash** | — | Catalog loaders (brands, cities, event types, service types) | SplashCubit, SplashPage | Implemented |
| **Home Dashboard** | HomeData | HomeDashboardService | HomeCubit, HomePage | Implemented |
| **Events** | EventModel, RiderProfileModel, RiderTrackingModel | EventDto, EventService, TrackingService, TrackingWsClient | EventsCubit, EventDetailCubit, EventDeleteCubit, EventFormCubit, LiveTrackingCubit, EventListPage, EventDetailPage, CreateEventPage, EventTrackingPage, AttendeesPage, AttendeesManagementPage | **Implemented** (includes iter-2: filters + iter-4: AI cover generation) |
| **Event Registration** | EventRegistrationModel, VehicleSummaryModel, RegistrationWithEvent | EventRegistrationDto, RegistrationService | RegistrationFormCubit, MyRegistrationsCubit, RegistrationFormPage, RegistrationDetailPage, ManageRegistrationPage | Implemented |
| **Real-time Tracking** | RiderTrackingModel, UpdateLocationRequest | TrackingWsClient (WebSocket), RiderTrackingDto | LiveTrackingCubit, TrackingPage, TrackingParticipantsPage | **Implemented** — WebSocket client active, cubit for live state |
| **Vehicles (Garage)** | VehicleModel | VehicleDto, VehicleService | VehicleCubit, VehicleFormCubit, VehicleDeleteCubit, VehicleMaintenancesCubit | Implemented |
| **Maintenance** | MaintenanceModel, MaintenanceListSummary | MaintenanceDto, MaintenanceService | MaintenancesCubit, MaintenanceFormCubit, MaintenanceDeleteCubit | Implemented |
| **SOAT** | — | — | — | **Not started** — no domain model, DTO, or cubit found |
| **Profile** | UserModel | UserDto, UserService | ProfileCubit, RiderProfileCubit | Partial — user profile exists, follower system not yet implemented |
| **Notifications** | — | — | HomeNotificationButton widget | **Stub only** — UI placeholder, no FCM integration or notification center |
| **Deep Links** | — | — | — | **Not started** — no Firebase Dynamic Links integration |
| **Users (Discovery)** | UserModel | UserDto, UserService | RiderProfileCubit | Implemented — rider profile pages work |

---

## 2. Key Dependencies

| Category | Package | Purpose |
|----------|---------|---------|
| **State management** | flutter_bloc, bloc | Cubit pattern for all async operations |
| **Code generation** | freezed, freezed_annotation, json_serializable | Immutable models, union types, JSON serialization |
| **DI** | get_it, injectable | Service locator + auto-registration |
| **HTTP** | retrofit, dio | REST client generation + HTTP layer |
| **Router** | go_router | Declarative routing with auth guards |
| **Firebase** | firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_remote_config | Auth, storage, remote config for API base URL |
| **OAuth** | google_sign_in | Google Sign-In |
| **Maps** | google_maps_flutter, geocoding | Map display and geocoding |
| **Real-time** | web_socket_channel | WebSocket for event tracking |
| **Forms** | flutter_form_builder, form_builder_validators | Multi-step forms, field validation |
| **Localization** | intl, flutter_localizations | Spanish (es) localization via ARB |
| **Rich text** | flutter_quill | Rich text editor for event descriptions |
| **Images** | image_picker, cached_network_image, firebase_storage | Photo selection, caching, upload |
| **Device** | geolocator, battery_plus, permission_handler | GPS, battery level, permissions |
| **Storage** | shared_preferences, flutter_secure_storage | Local persistence, secure token storage |
| **UI utilities** | google_fonts, shimmer | Typography (Space Grotesk), loading placeholders |
| **Functional** | dartz | Either/Right/Left for error handling |

---

## 3. rideglory-api Surface

Backend is **microservices architecture** with API Gateway pattern.

### Modules & Controllers

| Module | Endpoints | Purpose | Auth guard |
|--------|-----------|---------|-----------|
| **API Gateway** | — | Routes, aggregates, serves frontend | — |
| **Auth** (`api-gateway/auth`) | `POST /auth/login`, `POST /auth/signup`, `POST /auth/refresh` (inferred) | Firebase token validation, user profile setup | Firebase ID token |
| **Events** (`events-ms/events`) | `POST /events/generate-cover`, `GET /events`, `GET /events/my`, `GET /events/upcoming`, `POST /events`, `GET /events/:id`, `PATCH /events/:id`, `DELETE /events/:id` | Event CRUD, AI cover generation (iter-4 completed), listing with filters (iter-2 completed) | Bearer token |
| **Registrations** (`events-ms/registrations`) | Inferred: `POST /registrations`, `GET /registrations/:id`, `PATCH /registrations/:id`, `DELETE /registrations/:id` | Event signup workflow, approval/rejection by organizer | Bearer token |
| **Vehicles** (`vehicles-ms/vehicles`) | `GET /vehicles`, `POST /vehicles`, `GET /vehicles/my`, `POST /vehicles/my/:vehicleId/main`, `GET /vehicles/:id`, `PATCH /vehicles/:id`, `DELETE /vehicles/hard-delete/:id` | Vehicle CRUD, set primary vehicle | Bearer token |
| **Tracking** (`events-ms/tracking`) | `GET /tracking/ws` (WebSocket), `POST /tracking/start` (inferred), `POST /tracking/end` (inferred), `GET /tracking/status` (inferred), `GET /events/:eventId/route` (inferred) | WebSocket for live rider location broadcasts | Bearer token + event context |
| **Maintenances** (`maintenances-ms/maintenances`) | Inferred: CRUD for maintenance records | Maintenance log, reminders | Bearer token |
| **Users** (`users-ms/users`) | Profile, followers (inferred) | User data, discovery, follow system | Bearer token |
| **Places** (`api-gateway/places`) | Inferred: Mapbox Geocoding, directions | Location search, route calculation | API key (backend-only) |
| **Home** (`api-gateway/home`) | Inferred: Dashboard aggregation | Fetch user's vehicles, upcoming events, maintenance alerts | Bearer token |
| **Catalogs** (`api-gateway/catalogs`) | `GET /catalogs/brands`, `GET /catalogs/cities`, `GET /catalogs/event-types`, `GET /catalogs/service-types` (inferred from PRD §6.2) | Static lookup tables, cached 24h | Public (no auth) |

### Key Backend Gaps (PRD §17)

| Endpoint | Status | Notes |
|----------|--------|-------|
| **SOAT endpoints** | Not found | `POST /vehicles/:vehicleId/soat`, `GET /vehicles/:vehicleId/soat` |
| **Event route** | Not found | `GET /events/:eventId/route` for polyline |
| **Tracking control** | Not found | `POST /events/:eventId/tracking/start`, `POST /events/:eventId/tracking/end` |
| **Tracking status** | Not found | `GET /events/:eventId/tracking/status` |
| **AI quota check** | Not found | `GET /events/generate-cover/quota` |
| **Notification schedule** | Not found | `POST /notifications/schedule`, `DELETE /notifications/schedule/:id` |
| **Follower endpoints** | Not found | `POST /users/:userId/follow`, `DELETE /users/:userId/follow`, `GET /users/:userId/followers`, `GET /users/:userId/following` |
| **Share metadata** | Not found | `GET /events/:eventId/share-metadata` |

---

## 4. Design Artifacts

| Artifact | Description |
|---------|-------------|
| **rideglory.pen** | Pencil design file (exists at project root) — source of truth for all screen designs, components, and layout. Contains 26+ frames covering all PRD modules with dark theme (Asphalt palette). |
| **Design system components** | Atoms (buttons, inputs), Molecules (composite UI), Organisms (feature-level components) in `lib/design_system/` |
| **Theme** | Dark mode only; primary color orange (`#f98c1f`), Space Grotesk font, 8px border radius standard. Implemented in `lib/core/theme/` |
| **Localization** | Spanish (Colombian) ARB file at `lib/l10n/app_es.arb`; generated localization files in `lib/l10n/` |

---

## 5. PRD Gap Analysis

| PRD Module | Status | What exists | What's missing |
|---|---|---|---|
| **5. Authentication** | ✅ Implemented | Login (email/password), Signup, Password recovery; Firebase Auth + Google Sign-In | Apple Sign-In (not in code) |
| **6. Splash** | ✅ Implemented | Logo, tagline, catalog loading in parallel (brands, cities, event types, service types), max 3s timeout, auth redirect | — |
| **7. Home Dashboard** | ✅ Implemented | Header with greeting, notification bell, my garage section (main vehicle card), upcoming events carousel | SOAT alerts inline; maintenance alerts inline (needs SOAT + maintenance model) |
| **8. Events** | ✅ Implemented (partial) | List with search, filters (date, city, type, difficulty), event cards with state badge, detail page with info, map preview, CTA bar; create/edit form with Mapbox geocoding, image upload, AI cover generation (iter-4); polyline route setup in form | Event state machine (scheduled / in_progress / finished / cancelled) — logic may be partial; "max participants" cap validation; event type/difficulty chips display |
| **9. Registrations** | ✅ Implemented | 4-step form (personal, medical, emergency, vehicle), registration detail page with QR code stub, approval/rejection workflow for organizer, manage attendees page with search/filter | Edit registration after creation (if event not started); message from organizer on rejection |
| **10. Tracking** | ✅ Implemented (partial) | WebSocket client (TrackingWsClient), cubit managing live state, tracking page layout, participant list with search/filter, speed/battery display, rider SOS state handling in model | SOS button UI + action; "end ride" button for organizer; adherence to route (200m radius check); push notifications on SOS; GPS in background with persistent notification; center-on-me button; speed average aggregation |
| **11. Garage** | ✅ Implemented | Vehicle list (main + others), detail page with specs, add/edit form with Mapbox brands autocomplete, set primary vehicle, edit/archive options | Document upload (SOAT, technical review) UI stubs in form; OCR for license plate scanning |
| **12. Maintenance** | ✅ Implemented | Dashboard with donut chart health %, 3-urgency sections (overdue/upcoming/on-time), historial grouped by year, 3-step form (type selection, completed/programmed tabs, vehicle picker), filters (type, state, date range) | Maintenance reminder push notifications (30d before, when km approaching); next service calculations |
| **13. SOAT** | ❌ Not started | Zero implementation | All 5 steps: upload/manual form, OCR extraction, status badge (vigente/por vencer/vencido), reminder push notifications (30d, 7d, day-of) |
| **14. Profile** | ⚠️ Partial | User profile page, edit form, rider profile page, events created by user, follower counts in UI | Follow/Unfollow buttons + logic; followed list; follower list; bio display |
| **15. Notifications** | ❌ Stub only | UI placeholder (bell icon) in home header | FCM integration, notification center page, deep link routing, 11 notification types per PRD §15 |
| **16. Deep links** | ❌ Not started | Zero implementation | Firebase Dynamic Links: `https://rideglory.page.link/event/{eventId}` with fallback to Play Store/App Store |
| **17.1 SOAT endpoints** | ❌ Not started | — | Backend endpoints + frontend DTO/service integration |
| **17.2 Tracking endpoints** | ⚠️ Partial | WebSocket (GET /tracking/ws) active | Missing: start, end, status HTTP endpoints; route polyline endpoint |
| **17.3 AI quota endpoint** | ✅ Partial | `POST /events/generate-cover` works (iter-4) | `GET /events/generate-cover/quota` missing (quota check happens in response on 429) |
| **17.4 Notification scheduling** | ❌ Not started | — | Backend scheduler endpoints + frontend calls |
| **17.5 Followers** | ❌ Not started | — | Backend endpoints + UI (follow button, lists) |
| **17.6 Share metadata** | ❌ Not started | — | Backend endpoint for Dynamic Link preview |
| **17.7 Catalogs** | ✅ Implemented | Brands, cities, event types, service types cached in splash; public endpoints | — |

---

## 6. Key Architectural Patterns

### Clean Architecture
- **Domain**: Pure Dart models, repository interfaces, use cases — no Flutter/HTTP imports
- **Data**: DTOs (freezed + json_serializable), service clients (Retrofit), repository implementations
- **Presentation**: Cubits (Cubit<ResultState<T>>), pages, widgets — no HTTP calls, no DTO exposure

### State Management
- **ResultState<T>**: Freezed union (initial, loading, data, empty, error) — universal pattern for async ops
- **Cubit pattern**: Simple ops use `Cubit<ResultState<T>>` directly; complex state uses `@freezed` state class with multiple `ResultState<T>` fields
- **Example**: `EventDetailCubit` extends `Cubit<EventDetailState>` where state has separate `ResultState` fields for event data, registrations, attendees

### HTTP & Error Handling
- **Dio + Retrofit**: Auto-generated REST clients from annotated service interfaces
- **FirebaseAuthInterceptor**: Injects Firebase ID token into all requests
- **Error mapping**: `rest_client_functions.dart` wraps calls, maps exceptions to user-friendly Spanish messages, returns `Either<DomainException, Model>`
- **Timeout**: 20s per Dio config

### Dependency Injection
- **GetIt + Injectable**: Services marked `@injectable`, `@singleton`, `@lazySingleton`; repositories marked `@Injectable(as: InterfaceType)`
- **DI initialization**: `configureDependencies()` called in main.dart
- **Firebase module**: Custom DI module provides singleton Firebase instances

### Routing
- **go_router**: Declarative, auth guard redirects unauthenticated users to `/login`
- **Named routes**: 17 routes defined (splash, login, home, events, garage, etc.)
- **Navigation conventions**: `context.pushNamed()` for normal transitions, `context.goAndClearStack()` for auth state changes, `context.goNamed()` for tab navigation

### Localization
- **ARB format**: `app_es.arb` (Spanish only in MVP)
- **Code generation**: `flutter gen-l10n` produces `app_localizations.dart`
- **Usage**: `context.l10n.<keyName>` in widgets; extension defined in `l10n_extensions.dart`

### WebSocket
- **TrackingWsClient**: Managed connection to `/api/tracking/ws?eventId={id}`
- **Message contract**: Client sends `{ type, lat, lng, speed, heading, batteryLevel, status }`, server broadcasts `{ type: "riders_update", riders: [...] }`
- **Auto-reconnect**: Exponential backoff on disconnect

---

## 7. Code Quality & Conventions

| Aspect | Status | Notes |
|--------|--------|-------|
| **Linting** | Active | `analysis_options.yaml` enforced; `dart analyze` pre-commit |
| **Testing** | Minimal | BLoC tests exist for some cubits; widget tests not comprehensive |
| **Naming** | Good | Follows conventions: feature-prefixed localization keys, descriptive variable names, one widget per file |
| **Architecture adherence** | Good | Layer violations rare; domain imports Flutter only in tests |
| **Code generation** | Working | `dart run build_runner build` generates code; no missing part directives observed |

---

## 8. Core Infrastructure

| Component | Location | Purpose |
|-----------|----------|---------|
| **Router** | `lib/shared/router/app_router.dart` | go_router configuration, routes, auth guard |
| **DI** | `lib/core/di/injection.dart` | GetIt + injectable setup |
| **HTTP** | `lib/core/http/` | Dio config (AppDio), Retrofit client base, error mapping (rest_client_functions.dart), FirebaseAuthInterceptor |
| **Theme** | `lib/core/theme/` | Dark mode, color scheme, typography |
| **Services** | `lib/core/services/` | AuthService (Firebase), LocationService (geolocator), UserStorageService (SharedPreferences), ImageStorageService (Firebase Storage), PlaceService (Mapbox Geocoding) |
| **Extensions** | `lib/core/extensions/` | Context extensions (l10n, navigation), DateTime, String utilities |
| **Exceptions** | `lib/core/exceptions/` | DomainException hierarchy for error handling |
| **Result state** | `lib/core/domain/result_state.dart` | Freezed union for all async operations |
| **Design system** | `lib/design_system/` | Atoms, molecules, organisms, foundation (spacing, sizing) |
| **Shared widgets** | `lib/shared/widgets/` | Reusable UI: AppButton, AppDialog, EmptyStateWidget, VehicleListItem, etc. |

---

## 9. Planning Implications

### Completed & Validated
1. **Iter-2 (Event Discovery Filters)**: Event list filters by date, city, type, difficulty implemented; filter state managed in EventsCubit
2. **Iter-4 (AI Cover Image Generation)**: `POST /events/generate-cover` integrated; bottom sheet UI shows 2×2 grid of generated images; quota logic returns 429 on limit

### Critical Gaps to Address (in order)
1. **SOAT module** (0% complete): Requires domain model, DTO, service integration, UI (upload/manual form, OCR stub, status badge, reminder scheduling). Blocks home dashboard alert display.
2. **Notifications** (5% complete): Stub button only; needs FCM integration, notification center page, 11 notification types (registration updates, SOAT reminders, maintenance alerts, SOS broadcasts, event status changes). Core to user engagement.
3. **Tracking SOS + organizer controls** (40% complete): WebSocket client works, cubit manages state; missing SOS button UI + confirmation, "end ride" button for organizer, push notification on SOS, persistent background notification during active ride.
4. **Followers system** (0% complete): No backend endpoints, no UI (follow button, follower/following lists). Lower priority but part of user discovery.
5. **Deep links** (0% complete): Firebase Dynamic Links not integrated; blocks event sharing feature.
6. **Backend endpoints** (60% complete): SOAT endpoints, tracking control (start/end/status), notification scheduling, follower endpoints, share metadata all missing from backend.

### Architectural Readiness
- Clean Architecture patterns well-established; no refactoring needed
- State management (ResultState, Cubit) proven pattern; scales well
- DI system solid; no bottlenecks
- Routing & navigation conventions in place
- Localization framework ready (Spanish only; English deferred)
- Error handling unified; user messages Spanish-first

### Next Iteration Recommendations
- **Iter-5 (SOAT + Notifications)**: Address 2 of the 3 top gaps; unlock dashboard alerts + user engagement
  - Backend: SOAT endpoints, notification scheduler
  - Frontend: SOAT flow, notification center, FCM setup
  - Design: Re-use rideglory.pen (SOAT screens likely designed; notification center may need finalization)
- **Iter-6 (Tracking Finalization + Followers)**: Complete tracking UX (SOS, organizer controls); add follower system
- **Iter-7 (Deep Links + Polish)**: Share feature, final testing, deployment prep

### Known Limitations (by design, not bugs)
- No offline mode; requires internet always
- No English localization (MVP is Spanish-only)
- No payment processing in-app (prices are informative)
- SOAT verification is manual, not automated via RUNT API
- No chat; WhatsApp/native call only for rider contact

---

## 10. File Paths Summary

| Category | Path |
|----------|------|
| **Flutter app root** | `/Users/cami/Developer/Personal/Rideglory/` |
| **Features** | `/Users/cami/Developer/Personal/Rideglory/lib/features/` |
| **Core (DI, routing, services)** | `/Users/cami/Developer/Personal/Rideglory/lib/core/` |
| **Design system** | `/Users/cami/Developer/Personal/Rideglory/lib/design_system/` |
| **Shared widgets** | `/Users/cami/Developer/Personal/Rideglory/lib/shared/` |
| **Localization** | `/Users/cami/Developer/Personal/Rideglory/lib/l10n/` |
| **Design file (Pencil)** | `/Users/cami/Developer/Personal/Rideglory/rideglory.pen` |
| **Backend root** | `/Users/cami/Developer/Personal/rideglory-api/` |
| **API Gateway** | `/Users/cami/Developer/Personal/rideglory-api/api-gateway/src/` |
| **Events microservice** | `/Users/cami/Developer/Personal/rideglory-api/events-ms/src/` |
| **Vehicles microservice** | `/Users/cami/Developer/Personal/rideglory-api/vehicles-ms/src/` |
| **Users microservice** | `/Users/cami/Developer/Personal/rideglory-api/users-ms/src/` |
| **Maintenances microservice** | `/Users/cami/Developer/Personal/rideglory-api/maintenances-ms/src/` |
| **Contracts (shared DTOs)** | `/Users/cami/Developer/Personal/rideglory-api/rideglory-contracts/src/` |

---

*Scan completed by System Scanner agent. No modifications made to codebase. Ready for PO/Architect handoff.*
