# Architect Review — Rideglory Iteration Plan

> **Author:** Architect agent
> **Generated:** 2026-05-12
> **Input:** `docs/PRD.md` v1.0, `docs/handoffs/planning/00-existing-system-scan.md`, `docs/handoffs/planning/01-po-proposal.md`
> **Status:** Draft — awaiting Plan Reviewer sign-off

---

## 1. Stack Validation Summary

### What is already present and confirmed

| Capability | Status | Notes |
|-----------|--------|-------|
| HTTP layer (Dio + Retrofit) | Present | `AppDio`, `FirebaseAuthInterceptor`, `executeService()`, `ApiRoutes` all implemented |
| WebSocket (tracking) | Present | `TrackingWsClient` fully implemented; handles join, location update, leave, reconnect |
| Firebase Auth | Present | Token auto-refresh via Firebase SDK; injected in `FirebaseAuthInterceptor` |
| Firebase Storage | Present | `ImageStorageService` wraps `firebase_storage`; image upload + delete |
| File picking (images) | Present | `image_picker: ^1.2.1` in pubspec; used by `ImageStorageService` |
| SharedPreferences | Present | `shared_preferences: ^2.3.5`; `UserStorageService` wraps it |
| go_router | Present | v17.0.0; named routes in `AppRoutes`; `GoRouterRefreshStream` hooked to `AuthCubit` |
| DI (GetIt + Injectable) | Present | Fully configured; `@injectable`, `@singleton`, `@lazySingleton` throughout |
| BLoC/Cubit + ResultState<T> | Present | Standard pattern across all features |
| Code generation | Present | build_runner, freezed, json_serializable, injectable_generator, retrofit_generator |
| SOS button widget | Present | `SosButton` widget exists in `live_map_page.dart` — wired to empty `onPressed: () {}` |
| Localization (ARB) | Present | `app_es.arb` + `context.l10n` extension |

### What is missing and must be added

| Capability | Missing | Required for |
|-----------|---------|--------------|
| `firebase_messaging` | Not in pubspec | HU-PUSH-01 (FCM push notifications) |
| `file_picker` | Not in pubspec | HU-SOAT-01 (PDF upload — `image_picker` only picks images, not PDF) |
| `mocktail` or `mockito` | Not in dev_dependencies | HU-TEST-01 (unit/widget tests) |
| `bloc_test` | Not in dev_dependencies | HU-TEST-01 (Cubit state transition testing) |
| `network_image_mock` | Not in dev_dependencies | HU-TEST-01 (widget tests with cached images) |
| Claude API integration (backend) | Not implemented | HU-SOAT-01, HU-AI-01 |
| FCM token storage (backend) | Not implemented | HU-PUSH-01 |
| `notifications` module (backend) | Not implemented | HU-PUSH-01 |
| `insurance` domain + data layer | Not implemented | HU-SOAT-01 |
| `recommendations` endpoint (backend) | Not implemented | HU-AI-02 |
| Event filter query params (backend) | Unconfirmed | Iter 2 — see Risk-1 |
| Deep-link routes for FCM | Not implemented | HU-PUSH-01 |

### Mock strategy decision — HU-TEST-01

Use **`mocktail`** (not `mockito`). Rationale:
- No code generation step needed (`mocktail` uses `registerFallbackValue` + `Mock` extension; `mockito` requires `@GenerateMocks` and a build_runner pass).
- Compatible with the existing pattern of `@injectable` singletons — you mock the interface/abstract class, not a generated file.
- `bloc_test` is required alongside it for Cubit `expect:` assertions.

Add to `dev_dependencies` in `pubspec.yaml`:
```yaml
mocktail: ^1.0.4
bloc_test: ^10.0.0
network_image_mock: ^2.1.1
```

---

## 2. Per-Iteration Architecture Notes

---

### Iteration 1 — Test Infrastructure + Profile Feature Completion

#### Test infrastructure

**Packages to add (dev):** `mocktail`, `bloc_test`, `network_image_mock`

**Directory structure to establish:**
```
test/
  features/
    vehicles/
      domain/           # use case unit tests
      data/             # repository impl unit tests (mock VehicleService)
      presentation/     # cubit + widget tests
    events/
      domain/
      data/
      presentation/
    maintenance/
      domain/
      data/
      presentation/
  core/                 # ResultState, executeService tests
integration_test/
  auth_flow_test.dart   # stub group blocks only
  vehicles_flow_test.dart
  events_flow_test.dart
```

**Cubit testing pattern:**
```dart
// Example for VehicleCubit
blocTest<VehicleCubit, ResultState<List<VehicleModel>>>(
  'emits [loading, data] on successful fetch',
  build: () => VehicleCubit(getMyVehiclesUseCase: mockUseCase),
  act: (cubit) => cubit.fetchMyVehicles(),
  expect: () => [
    const ResultState<List<VehicleModel>>.loading(),
    ResultState<List<VehicleModel>>.data(data: [...]),
  ],
);
```

**Widget test pattern (with MockCubit):**
- Wrap the page under test in `BlocProvider<VehicleCubit>.value(value: mockCubit)`.
- Use `whenListen` from `bloc_test` to emit a state sequence.
- Use `network_image_mock` to prevent `CachedNetworkImage` from throwing in tests.

**No code generation step** for mocktail. Only `flutter pub get` needed.

#### Profile feature completion

**Backend:** No new endpoints needed. `GET /users/me` already exists and returns the `User` schema (which includes `fullName`, `email`, `profilePhotoUrl` if it is part of `UpdateUserDto`). Verify `imageUrl` field is in the `User` response from the users-ms — the Prisma schema shows the `User` model currently lacks a `profilePhotoUrl` field. This is the only gap.

**Decision required (before coding):** Add `profilePhotoUrl: String?` to the `User` Prisma model in users-ms, or expose what the current model has (no profile photo) in Phase 1.

**Flutter layers:**
- `ProfilePage` needs a `ProfileCubit` and a `GetMyProfileUseCase` (calls `UserService.getMe()`).
- `VehicleCubit` (already a global singleton) supplies the main vehicle — no new service call.
- The profile page reads `AuthCubit.state.currentUser` for the currently logged-in user ID, then calls `GetMyProfileUseCase` to fetch full profile data.

**Code generation:** Run `dart run build_runner build` after adding the `ProfileCubit` freezed state (if complex state is needed) or none if using `Cubit<ResultState<UserModel>>`.

---

### Iteration 2 — Event Discovery Filters + Attendee Profile Links

#### Event filters

**Backend gap — must confirm before coding:**
The existing `GET /events` gateway calls `eventsService.send('findAllEvents', {})` with no filter params. The `GET /events/upcoming` calls `findUpcomingEvents` with only `{ limit: 5 }`. Neither passes filter query parameters to the events-ms. The events-ms `EventsService` and Prisma queries must be updated to accept `type`, `dateFrom`, `dateTo`, and `city` (not free-text location — must match the existing `city` field in the Event schema).

**Backend changes required:**
- events-ms: Update `findAllEvents` handler to accept optional `{ type, dateFrom, dateTo, city }` filters and apply them in the Prisma query.
- api-gateway: Add `@Query()` params to `EventsController.findAll()` and forward them.

**Flutter changes:**
- `EventsCubit` needs a `applyFilters({EventType? type, DateTime? dateFrom, DateTime? dateTo, String? city})` method.
- The existing `event_filters_bottom_sheet.dart` widget is already present — wire it to the cubit method.
- The cubit state may need to be converted from `Cubit<ResultState<List<EventModel>>>` to a `@freezed` state with an `activeFilters` field alongside the `eventsResult`.

**Code generation:** Run `dart run build_runner build` if `EventFilterState` becomes a freezed class.

#### Attendee profile links

**Backend:** `GET /users/:id` endpoint already exists in the users controller.
**Flutter:** `UserService.getUserById(String id)` call → `GetUserByIdUseCase` → navigate to a `RiderProfilePage` (new page) that takes a `String userId` as route extra.
**Route to add:** `AppRoutes.riderProfile = '/users/:id'` or use query param pattern (current app convention uses `extra` objects, so `extra: userId` is consistent).

---

### Iteration 3 — SOAT & Mandatory Insurance Documents

#### PDF upload flow (device → Firebase Storage → backend → Claude API)

**New Flutter package required:** `file_picker: ^8.0.0`
- `image_picker` only handles images; PDF selection requires `file_picker`.
- `permission_handler` is already present for storage permissions.

**Flutter domain layer (`lib/features/vehicles/domain/`):**
```dart
// InsuranceDocumentModel — no Flutter imports
class InsuranceDocumentModel {
  final String vehicleId;
  final String storageUrl;
  final DateTime expirationDate;
  final String docType; // 'soat' | 'tecno' | 'other'
  final InsuranceDocumentStatus status; // valid | expiringSoon | expired
}

enum InsuranceDocumentStatus { valid, expiringSoon, expired }
```

**Flutter data layer (`lib/features/vehicles/data/`):**
```dart
@JsonSerializable()
class InsuranceDocumentDto {
  final String vehicleId;
  final String storageUrl;
  final String expirationDate; // ISO 8601
  final String docType;
}
```

**Upload flow:**
1. Flutter picks PDF via `file_picker` → uploads to Firebase Storage at `insurance/{userId}/{vehicleId}/soat.pdf` using a new `PdfStorageService` (or extending `ImageStorageService`).
2. Flutter calls `POST /vehicles/my/:vehicleId/insurance` with `{ storageUrl, docType }`.
3. Backend downloads PDF from Firebase Storage, sends to Claude Haiku API for extraction.
4. Backend returns `{ expirationDate: string | null, extractionError: boolean }`.
5. Flutter presents the date in a confirmation form; if `extractionError: true`, shows manual entry immediately.
6. On save, Flutter calls `PATCH /vehicles/my/:vehicleId/insurance` with the confirmed date.

**Backend changes required (rideglory-api):**
- vehicles-ms: Add `InsuranceDocument` model to Prisma schema (see Section 3 API Contracts for full shape).
- vehicles-ms: New `createInsuranceDocument` and `updateInsuranceDocument` message handlers.
- api-gateway: New `InsurancesController` or extend `VehiclesController` with `POST /vehicles/my/:vehicleId/insurance` and `PATCH /vehicles/my/:vehicleId/insurance`.
- api-gateway: New `AiModule` / `ClaudeService` that calls the Claude API (Anthropic SDK for Node.js). Claude Haiku receives the PDF base64 content and returns the extracted expiration date.

**Downloading PDF from Firebase Storage in backend:**
The backend receives the Firebase Storage URL from Flutter. The backend can either:
- **(Recommended) Download via Firebase Admin SDK** using the Storage bucket directly: `admin.storage().bucket().file(path).download()`. This avoids public URLs and keeps the file private.
- Alternatively, use a signed URL generated by the Flutter client before calling the backend (simpler but requires the signed URL to remain valid during extraction).

**ADR required:** See ADR-3 below.

**Code generation steps:**
1. `dart run build_runner build --delete-conflicting-outputs` (for `InsuranceDocumentDto` + freezed state).
2. vehicles-ms: `npx prisma migrate dev` after schema changes.
3. vehicles-ms: `npx prisma generate` after schema changes.

**Status indicator logic (Flutter, domain layer):**
```dart
InsuranceDocumentStatus computeStatus(DateTime expirationDate) {
  final now = DateTime.now();
  final daysLeft = expirationDate.difference(now).inDays;
  if (daysLeft < 0) return InsuranceDocumentStatus.expired;
  if (daysLeft <= 30) return InsuranceDocumentStatus.expiringSoon;
  return InsuranceDocumentStatus.valid;
}
```

---

### Iteration 4 — AI Event Cover Image Generation

#### Image generation approach (ADR required — see ADR-4)

The Claude API (Anthropic) does not generate images natively. Two practical options:

**Option A (Recommended): Unsplash / Pexels API for stock photo search**
- Backend receives `{ title, type, location }` → sends to Claude Haiku to generate a 3-5 word search query → queries Unsplash API → returns the best-match image URL.
- Pros: Fast (< 1s), free (Unsplash developer tier), no content policy issues, no image hosting cost.
- Cons: Not truly "AI-generated" — it is AI-assisted search.
- No Firebase Storage needed for the cover URL if Unsplash CDN URLs are stable.

**Option B: Replicate / Stability AI image generation**
- Backend sends prompt to Replicate (SDXL or Flux) → returns image URL → upload to Firebase Storage.
- Pros: Truly generated, unique images.
- Cons: 5-20s latency, cost per image (~$0.01-0.05), requires Replicate account and secret.

**Flutter wiring:**
The "Generar portada" button already exists in `EventFormPage`. The `EventFormCubit` needs:
- `generateCover({required String title, required String type, required String location})` method.
- A new state field: `ResultState<String> coverGenerationResult` (emits the image URL on success).
- On success, the URL is placed into the form's cover image field (replacing any existing image).
- The organizer can regenerate (calls again) or pick from gallery (existing image picker path).

**Backend changes required:**
- api-gateway: `POST /events/generate-cover` in `EventsController` (or a new `AiController`).
- api-gateway: `ClaudeService` (reused from Iter 3) generates the search query.
- api-gateway: `ImageSearchService` calls Unsplash API (or Replicate).

**No new Flutter packages required** if Unsplash URLs are returned directly (no local image download).
If image generation is via Replicate and must be stored in Firebase Storage, the backend handles the upload and returns the Storage URL — no Flutter changes to the upload mechanism.

**Code generation:** Run `dart run build_runner build` after modifying `EventFormCubit` state.

---

### Iteration 5 — AI Event Recommendations

#### Backend scoring algorithm

The `GET /events/recommendations` endpoint lives in the api-gateway, which already has access to events-ms, users-ms, and vehicles-ms via message bus. The scoring is assembled in the api-gateway's home module or a new recommendations module:

1. Fetch caller's main vehicle type from vehicles-ms.
2. Fetch caller's registration history (last 10 events) from events-ms.
3. Fetch upcoming events from events-ms.
4. Score each upcoming event:
   - Vehicle type match (exact or compatible): +40 points
   - Past registration in same event type: +40 points
   - Geographic proximity to user's residenceCity: +20 points
5. Return top 5 scored events. If fewer than 5 events are scoreable (new rider), fall back to upcoming events sorted by `startDate`.

**No external AI service needed for v1** — the scoring is deterministic. Claude narrative explanations are deferred to v2.

**Flutter changes:**
The `HomeCubit` and `HomeData` model need to be extended or a new `RecommendationsCubit` added. The PO proposal suggests a dedicated `RecommendationsCubit` — this is cleaner because:
- The home page already has `HomeCubit` for `mainVehicle` + `upcomingEvents`.
- Adding `recommendations` as a third result to `HomeCubit` would require converting it to a `@freezed` state class, which is significant refactoring.
- A separate `RecommendationsCubit` keeps responsibilities isolated.

**Local caching (`SharedPreferences`):**
```dart
// RecommendationsCacheService
static const _cacheKey = 'recommendations_cache';
static const _cacheExpiryKey = 'recommendations_cache_expiry';

Future<void> saveRecommendations(List<EventModel> events) async { ... }
Future<List<EventModel>?> loadCachedRecommendations() async {
  // Return null if expired (> 6 hours old) or absent
}
```

The `RecommendationsCubit.load()` method:
1. Emit cached data (if available) immediately.
2. Fetch from `GET /events/recommendations` in background.
3. Emit fresh data + update cache.

**Flutter `HomeDto` must NOT be changed** — recommendations come from a separate endpoint and are handled by the new cubit independently. No change to `HomeService` or `HomeRepositoryImpl`.

**Code generation:** `dart run build_runner build` after adding `RecommendationsCubit` state if it uses a freezed class.

---

### Iteration 6 — Push Notifications (FCM) + SOS Alert

#### FCM integration

**New Flutter package required:** `firebase_messaging: ^15.0.0`

**Platforms requiring additional setup:**
- Android: `AndroidManifest.xml` — `RECEIVE_BOOT_COMPLETED` permission, `FirebaseMessagingService` declaration. No new Gradle changes needed (firebase_core already handles Firebase initialization).
- iOS: Push notification capability in Xcode, APNs key in Firebase Console. Background modes: `remote-notification`.

**Token registration flow:**
```
App start (after login) →
  FirebaseMessaging.instance.getToken() →
  POST /users/device-token { token, platform: 'android'|'ios' } →
  Re-register on FirebaseMessaging.instance.onTokenRefresh
```

**Message handling states:**
| App State | Handler | Flutter action |
|-----------|---------|----------------|
| Foreground | `FirebaseMessaging.onMessage` | Show in-app SnackBar + navigate |
| Background | `FirebaseMessaging.onMessageOpenedApp` | Navigate on tap |
| Terminated | `FirebaseMessaging.getInitialMessage()` in `main()` | Navigate on tap |

**Deep-link routing problem with go_router v17 (`extra` objects):**
The current router uses `state.extra as SomeModel` for typed navigation. FCM payloads are JSON strings — they cannot carry Dart objects. The notification payload must carry only serializable data (IDs and route names), and the navigation layer must resolve the full objects from the backend.

Solution: Add a `NotificationNavigator` service that:
1. Reads the FCM `data` payload: `{ route, registrationId?, eventId? }`.
2. Calls the appropriate use case to fetch the full model.
3. Navigates using `context.pushNamed(route, extra: fetchedModel)`.

This means every deep-link target (`registration_detail`, `event_detail`, `live_tracking`) needs a "by-id" variant that fetches the model before rendering. `EventDetailByIdPage` already exists and follows this pattern — it is the template for the other targets.

**Backend changes required:**
- users-ms: Add `DeviceToken` Prisma model (see API Contracts, Section 3).
- api-gateway: `POST /users/device-token` endpoint in `UsersController`.
- api-gateway: New `NotificationsModule` with `FcmService` using Firebase Admin SDK (`firebase-admin` npm package).
- events-ms / registrations context: Call `FcmService` (via message bus or direct import in gateway) when registration status changes or event state changes.

**FCM dispatch triggers (backend):**
- Registration approved/rejected: registrations-ms emits event → gateway `NotificationsModule` sends FCM.
- New registration (pending): events-ms emits event → gateway sends FCM to organizer.
- Event state → `IN_PROGRESS`: events-ms emits event → gateway sends FCM to all approved registrants.
- Event state → `CANCELLED`: events-ms emits event → gateway sends FCM to all registrants.

#### SOS WebSocket extension

**No new Flutter package required.** The existing `TrackingWsClient` handles the WebSocket connection. It only needs new message types added to `_onMessage()`.

**`TrackingWsClient` changes:**
1. Add a `StreamController<SosAlertModel>` broadcast stream for SOS events.
2. In `_onMessage()`, handle `type == 'tracking.sos'` → parse and emit `SosAlertModel`.
3. Handle `type == 'tracking.sos_cancel'` → emit cancellation event.
4. Add `sendSos({required String eventId, required String riderId, required String riderName, required double lat, required double lng})` method.
5. Add `cancelSos({required String eventId, required String riderId})` method.

**`LiveTrackingCubit` changes:**
- Add `activeSosAlert: SosAlertModel?` field to `LiveTrackingState`.
- Subscribe to `TrackingWsClient.sosStream` in `start()`.
- On SOS received: emit `state.copyWith(activeSosAlert: sosAlert)`.
- On SOS cancel: emit `state.copyWith(activeSosAlert: null)`.
- `sendSos()` and `cancelSos()` methods proxy to `TrackingWsClient`.

**`LiveMapPage` changes:**
- `SosButton.onPressed` → `context.read<LiveTrackingCubit>().sendSos(...)`.
- New `SosOverlay` widget: `BlocBuilder` listening to `state.activeSosAlert` — renders a persistent red banner with the rider's name and a pin on the map at their last known position.

**Backend `TrackingGateway` changes:**
In `onClientMessage()`, add handlers for `tracking.sos` and `tracking.sos_cancel` that call `this.broadcast(meta.eventId, ...)` to all clients in the same room. No persistence needed — SOS is an in-memory real-time signal.

**Code generation:** Run `dart run build_runner build` after modifying `LiveTrackingState` (freezed).

---

### Iteration P (Parallel) — Design System in Pencil (HU-DESIGN-01)

No Flutter code changes. No backend changes. No packages. No code generation.

**Dependency on codebase:** The design agent reads the existing `AppColors`, `AppTextStyles`, and `AppTheme` files to extract the current design tokens before defining Pencil variables.

**Integration point for development iterations:** Starting Iteration 3, the frontend agent must open Pencil for new screen specs before writing any new widget. The design agent must complete HU-DESIGN-01 before Iteration 3 frontend work begins.

---

## 3. API Contracts (New Endpoints Only)

### 3.1 SOAT Insurance Document — Vehicles-ms + api-gateway

**Prisma schema addition (vehicles-ms):**
```prisma
enum InsuranceDocType {
  SOAT
  TECNO
  OTHER
}

model InsuranceDocument {
  id             String          @id @default(uuid())
  vehicleId      String
  storageUrl     String
  expirationDate DateTime
  docType        InsuranceDocType
  createdAt      DateTime        @default(now())
  updatedAt      DateTime        @updatedAt()

  vehicle Vehicle @relation(fields: [vehicleId], references: [id], onDelete: Cascade)

  @@unique([vehicleId, docType])
}
```

Add `insuranceDocuments InsuranceDocument[]` to the `Vehicle` model.

**Endpoint: Create/update insurance document**
```
POST /vehicles/my/:vehicleId/insurance
Authorization: Bearer <Firebase ID Token>
Content-Type: application/json

Request body:
{
  "storageUrl": "https://firebasestorage.googleapis.com/...",
  "docType": "soat" | "tecno" | "other"
}

Response 201:
{
  "id": "uuid",
  "vehicleId": "uuid",
  "storageUrl": "https://...",
  "expirationDate": "2026-03-15T00:00:00.000Z",  // extracted by Claude
  "docType": "soat",
  "extractionConfidence": "high" | "low",
  "createdAt": "...",
  "updatedAt": "..."
}

Response 422 (extraction failure):
{
  "error": "AI extraction failed",
  "message": "No se pudo extraer la fecha del PDF. Ingresa la fecha manualmente.",
  "extractionError": true
}
```

**Endpoint: Confirm/override expiration date**
```
PATCH /vehicles/my/:vehicleId/insurance/:documentId
Authorization: Bearer <Firebase ID Token>
Content-Type: application/json

Request body:
{
  "expirationDate": "2026-03-15T00:00:00.000Z"
}

Response 200:
{
  "id": "uuid",
  "vehicleId": "uuid",
  "storageUrl": "https://...",
  "expirationDate": "2026-03-15T00:00:00.000Z",
  "docType": "soat",
  "updatedAt": "..."
}
```

**Flutter DTO:**
```dart
@JsonSerializable()
class InsuranceDocumentDto {
  const InsuranceDocumentDto({
    required this.id,
    required this.vehicleId,
    required this.storageUrl,
    required this.expirationDate,
    required this.docType,
    this.extractionConfidence,
    this.extractionError,
  });

  final String id;
  final String vehicleId;
  final String storageUrl;
  final String expirationDate; // ISO 8601 string → parsed to DateTime in toModel()
  final String docType;
  final String? extractionConfidence;
  final bool? extractionError;

  factory InsuranceDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$InsuranceDocumentDtoFromJson(json);
}
```

**Firebase Storage path convention:**
`insurance/{userId}/{vehicleId}/{docType}.pdf`
Example: `insurance/abc123/def456/soat.pdf`

---

### 3.2 AI Event Cover Generation — api-gateway events module

```
POST /events/generate-cover
Authorization: Bearer <Firebase ID Token>
Content-Type: application/json

Request body:
{
  "title": "Rodada de los Nevados",
  "eventType": "OFF_ROAD",
  "city": "Manizales"
}

Response 200:
{
  "imageUrl": "https://images.unsplash.com/...",
  "source": "unsplash",  // or "generated" if using image-gen service
  "query": "mountain motorcycle off-road colombia"  // for debugging
}

Response 503 (service unavailable):
{
  "error": "Cover generation failed",
  "message": "No pudimos generar la portada en este momento. Sube tu propia imagen."
}
```

Note: If using Unsplash, the `imageUrl` is a CDN URL that does not need to be stored in Firebase Storage until the event is published. The organizer previews it in the form, and only on `POST /events` creation does it get saved as the event's `imageUrl`. The backend does not need to upload to Firebase Storage for the preview step.

---

### 3.3 Event Recommendations — api-gateway

```
GET /events/recommendations
Authorization: Bearer <Firebase ID Token>

Response 200:
{
  "recommendations": [
    {
      // Same shape as EventDto — no new fields needed
      "id": "uuid",
      "name": "Rodada Eje Cafetero",
      "eventType": "ON_ROAD",
      "city": "Armenia",
      "startDate": "2026-06-01T08:00:00.000Z",
      "difficulty": "MODERATE",
      "price": null,
      "imageUrl": "https://...",
      "state": "SCHEDULED",
      // ... all other EventDto fields
      "_score": 80  // optional debug field, strip before sending to Flutter if not needed
    }
  ],
  "fallback": false  // true if new-rider fallback was used
}
```

Flutter parses `recommendations` as `List<EventDto>` — the same DTO already used for events. No new DTO needed; only the endpoint and the cubit are new.

---

### 3.4 FCM Device Token Registration — users-ms + api-gateway

**Prisma schema addition (users-ms):**
```prisma
enum DevicePlatform {
  ANDROID
  IOS
}

model DeviceToken {
  id        String         @id @default(uuid())
  userId    String
  token     String         @unique
  platform  DevicePlatform
  createdAt DateTime       @default(now())
  updatedAt DateTime       @updatedAt()

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}
```

Add `deviceTokens DeviceToken[]` to `User` model.

**Endpoint:**
```
POST /users/device-token
Authorization: Bearer <Firebase ID Token>
Content-Type: application/json

Request body:
{
  "token": "fcm_token_string",
  "platform": "android" | "ios"
}

Response 200:
{
  "success": true
}
```

Upsert semantics: if the token already exists for this user, update `updatedAt`. If it exists for a different user (device transfer), reassign to the current user. This prevents stale tokens from delivering notifications to wrong users.

**Flutter DTO:**
```dart
@JsonSerializable()
class RegisterDeviceTokenDto {
  const RegisterDeviceTokenDto({required this.token, required this.platform});
  final String token;
  final String platform; // 'android' | 'ios'
}
```

---

### 3.5 SOS WebSocket Message Types (extension of existing protocol)

**Client → Server (send SOS):**
```json
{
  "type": "tracking.sos",
  "data": {
    "eventId": "uuid",
    "riderId": "uid",
    "riderName": "Carlos Ramírez",
    "latitude": 4.8133,
    "longitude": -75.6961
  }
}
```

**Client → Server (cancel SOS):**
```json
{
  "type": "tracking.sos_cancel",
  "data": {
    "eventId": "uuid",
    "riderId": "uid"
  }
}
```

**Server → All clients in event room (SOS broadcast):**
```json
{
  "type": "tracking.sos",
  "data": {
    "riderId": "uid",
    "riderName": "Carlos Ramírez",
    "latitude": 4.8133,
    "longitude": -75.6961,
    "eventId": "uuid"
  }
}
```

**Server → All clients in event room (cancel broadcast):**
```json
{
  "type": "tracking.sos_cancel",
  "data": {
    "riderId": "uid",
    "eventId": "uuid"
  }
}
```

Security: The gateway validates that the `riderId` in the SOS message matches the authenticated `uid` in `clientMeta` before broadcasting (same pattern as `handleLocationUpdate`).

---

## 4. Architectural Risks and Mitigations

### Risk 1 — Event filter backend gap (Iteration 2 blocker)

**Risk:** The `GET /events` and `GET /events/upcoming` endpoints do not currently pass any filter parameters through the NestJS message bus to events-ms. If the Prisma query in events-ms does not support filtering, Iteration 2's filter UI cannot be wired without backend changes.

**Severity:** Medium (blocks Iteration 2 filter feature; workaround is client-side filtering — but that is not acceptable at scale).

**Mitigation:** Before Iteration 2 frontend work begins, confirm with a `GET /events?type=OFF_ROAD` test against the dev backend. If the parameter is ignored, create a backend task as part of Iteration 2 to update the events-ms `findAllEvents` handler and the gateway controller.

**Recommended decision:** Add `city` (not free-text location) as the geographic filter. The `Event` model has a `city` field — match it exactly or use a case-insensitive prefix search.

---

### Risk 2 — go_router `extra` objects are not serializable from FCM payloads (Iteration 6)

**Risk:** All current navigation in the app uses `state.extra as SomeModel` — a Dart object passed in-memory. FCM notification payloads are JSON strings with simple scalar values. When the app is terminated and the user taps a notification, `go_router` cannot receive a Dart object through a push notification.

**Severity:** High (blocks the terminated-app deep-link requirement of HU-PUSH-01).

**Mitigation:** The pattern of `EventDetailByIdPage` (`/events/detail-by-id?id=...`) already shows the solution. For each FCM deep-link target:
- Ensure a "by-id" route variant exists that accepts only serializable params (query params or path params).
- The page fetches the full model from the backend before rendering.
- FCM `data` payload carries only: `{ "route": "registration_detail", "registrationId": "uuid" }`.

**New routes needed for FCM deep links:**
- `/events/registration-detail-by-id?id=:registrationId` → `RegistrationDetailByIdPage`
- `/events/attendees-by-id?eventId=:eventId` → `AttendeesPage` (may work with existing query param pattern)
- `/events/live-map-by-id?eventId=:eventId` → `LiveMapByIdPage` (fetches EventModel before building)

This is the most complex architectural task in Iteration 6 and must be planned before coding begins.

---

### Risk 3 — Claude API PDF extraction reliability (Iteration 3)

**Risk:** Claude Haiku has variable accuracy for PDF date extraction, especially for low-quality scans or non-standard SOAT layouts. If extraction fails silently (returns a wrong date with high confidence), the rider stores an incorrect expiration date without knowing.

**Severity:** Medium (incorrect insurance status indicator could cause real-world problems for the rider).

**Mitigations:**
1. Always present the extracted date in a confirmation step — never auto-save without user review.
2. Backend returns an `extractionConfidence` field (`high` | `low`). If `low`, UI shows a warning: "Verifica que la fecha sea correcta antes de guardar."
3. If Claude fails to parse any date, return a 422 with `extractionError: true` → UI defaults immediately to manual entry form.
4. Never send only the Storage URL to Claude — download the PDF content and send it as a base64-encoded document in the Claude API `documents` block (using Claude's document extraction capabilities, which are more reliable than asking it to "read a URL").

---

### Risk 4 — FCM notification delivery to terminated app on iOS (Iteration 6)

**Risk:** iOS requires APNs certificate/key to be configured in Firebase Console and push notification entitlements in Xcode. If the app is not signed with a provisioning profile that includes the push notification capability, FCM will fail silently on iOS physical devices (works on simulator but not in production).

**Severity:** High for iOS (critical feature simply does not work without proper setup).

**Mitigation:**
1. Before Iteration 6 frontend work, verify that the Apple Developer account has push notification capability enabled for the app bundle ID.
2. Upload APNs Auth Key (p8 file) to Firebase Console → Project Settings → Cloud Messaging → iOS app.
3. Add the background mode `remote-notification` to `Info.plist` and the push notification capability in Xcode.
4. DevOps iteration should include CI handling for the iOS signing identity.

---

### Risk 5 — Firebase Storage PDF access from the backend (Iteration 3)

**Risk:** Firebase Storage files are private by default. The backend cannot download the PDF from the Storage URL unless it has Firebase Admin credentials or the URL is a publicly accessible signed URL. If the backend tries to fetch the URL directly as an HTTP GET, it will receive a 403.

**Severity:** High (the entire AI extraction flow breaks if the backend cannot read the PDF).

**Mitigations:**
1. **(Recommended approach)** The Flutter client generates a short-lived signed URL (15 min) using Firebase Storage's `getDownloadURL()` — this is a public URL Firebase generates — and sends this URL to the backend. The backend downloads the PDF from this URL during the extraction request. The signed URL expires after use.
2. **Alternative:** Backend uses Firebase Admin SDK to access the storage bucket directly by file path. This requires the backend to know the storage path (`insurance/{userId}/{vehicleId}/{docType}.pdf`) rather than a URL. Flutter sends the path, not the URL, to the backend endpoint.

**Recommendation:** Option 2 (path-based access) is more secure — no URL exposure, no expiry timing issue. Flutter sends `{ storagePath, docType }` instead of `{ storageUrl, docType }`. The backend constructs the full Firebase Storage reference from the path using the Admin SDK.

---

## 5. ADRs Needed (Decision Points Before Coding)

### ADR-1: Mock library choice for test suite (before Iteration 1)

**Question:** Use `mocktail` or `mockito` for unit and widget tests?

**Recommendation:** `mocktail`. No code generation step, compatible with abstract class mocking, works with DI patterns already in the codebase.

**Decision owner:** QA agent (Iteration 1).

---

### ADR-2: `profilePhotoUrl` in User model — Phase 1 scope (before Iteration 1)

**Question:** Does the profile page in Iteration 1 show a profile photo? The `User` Prisma model in users-ms currently has no `imageUrl` or `profilePhotoUrl` field.

**Options:**
- A) Ship profile page without photo; add photo upload in a later iteration.
- B) Add `profilePhotoUrl: String?` to the User Prisma model now and include photo upload in Iteration 1.

**Recommendation:** Option A. Keeping Iteration 1 scoped to test infrastructure + basic profile (name, email, main vehicle) avoids Prisma migrations and a new backend task in an iteration that is already carrying significant QA work.

**Decision owner:** PO + backend agent (Iteration 1).

---

### ADR-3: PDF access strategy from backend (before Iteration 3)

**Question:** How does the backend access the uploaded PDF from Firebase Storage?

**Options:**
- A) Flutter sends a Firebase Storage download URL; backend fetches via HTTP.
- B) Flutter sends the storage path; backend accesses via Firebase Admin SDK.

**Recommendation:** Option B (path-based). More secure, no URL expiry issues, clean separation of concerns.

**If Option B:** Flutter sends `{ storagePath: "insurance/{userId}/{vehicleId}/soat.pdf", docType: "soat" }` to the backend. The backend constructs the Storage reference using `admin.storage().bucket().file(storagePath)`.

**Decision owner:** Architect + backend agent (before Iteration 3 backend sprint starts).

---

### ADR-4: AI cover image generation service (before Iteration 4)

**Question:** Which service generates event cover images?

**Options:**
- A) Unsplash API (free tier) — Claude generates a search query, Unsplash returns a photo. Fast, free, no content generation latency.
- B) Replicate / Stability AI — true generative image. Slower (~10s), costs ~$0.01/image.
- C) Static curated covers per event type — no external service, no cost, no latency. Manual curation required.

**Recommendation:** Option A for v1. It delivers visually appealing results instantly, costs nothing, and the Claude query-generation step gives it an "AI" feel. Option B can be added in v2 if riders/organizers request truly unique generated images.

**Decision owner:** PO + architect (before Iteration 4 planning).

---

### ADR-5: FCM deep-link routing architecture (before Iteration 6)

**Question:** How does the app navigate to the correct screen when a push notification is tapped while the app is terminated?

**Options:**
- A) Add "by-id" route variants for each FCM deep-link target; resolve the model from the backend before rendering.
- B) Store a serialized JSON snapshot of the required model in the FCM `data` payload; deserialize on open.

**Recommendation:** Option A. Option B is fragile — FCM data payloads have a 4KB limit, and stale data in a notification (e.g., a registration status that changed after the notification was sent) would cause UI inconsistency. The "by-id" pattern is already established in the codebase (`EventDetailByIdPage`).

**Required routes to add before Iteration 6 frontend work:**
- `/events/registration-detail-by-id`
- `/events/live-map-by-id`
- `/events/attendees-by-id` (for organizer new-request notification)

**Decision owner:** Architect + frontend agent (before Iteration 6 sprint starts).

---

## Appendix: Required pubspec.yaml additions by iteration

| Package | Type | Added in | Purpose |
|---------|------|---------|---------|
| `mocktail: ^1.0.4` | dev | Iteration 1 | Mocking for unit/widget tests |
| `bloc_test: ^10.0.0` | dev | Iteration 1 | Cubit state testing |
| `network_image_mock: ^2.1.1` | dev | Iteration 1 | Mock network images in widget tests |
| `file_picker: ^8.0.0` | prod | Iteration 3 | PDF file selection |
| `firebase_messaging: ^15.0.0` | prod | Iteration 6 | FCM push notifications |

All other iterations reuse the existing stack with no new packages.
