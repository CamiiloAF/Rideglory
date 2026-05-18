# Architect handoff — Iteration 3

**Date:** 2026-05-15
**Status:** done

Iteration 3 completes real-time tracking (SOS, organizer ride controls, background GPS), adds date-based maintenance + 24h event reminders, and migrates the maps SDK from `google_maps_flutter`/`geocoding` to `mapbox_maps_flutter` as the single maps SDK (Story 3.0 — blocking).

> **Brownfield note:** the tracking feature already exists (`TrackingWsClient`, `LiveTrackingCubit`, `LiveMapPage`, SOS widget stubs, backend `TrackingGateway` + `NotificationSchedulerService`). This iteration **extends** those — it does not rebuild them. SOS widgets (`sos_button.dart`, `sos_confirm_dialog.dart`, `sos_active_overlay.dart`) and `end_ride_confirm_dialog.dart` are local-state UI stubs that must be wired to the WebSocket/HTTP layer.

---

## Story 3.0 — Mapbox migration (FIRST, BLOCKING)

No iter-3 story other than 3.0 may start until 3.0 is merged and `dart analyze` is clean in `lib/`.

### 4 Dart files to migrate

| File | Current (Google) | Target (Mapbox) |
|------|------------------|-----------------|
| `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` | `GoogleMap` + `GoogleMapController` + `Marker` set + `BitmapDescriptor`; `LiveMapController` wraps zoom/center | `MapWidget` + `MapboxMap`; rider markers via `PointAnnotationManager` (custom image from `InitialsMarkerIcon` PNG bytes). `LiveMapController` now wraps `MapboxMap` — `zoomIn/Out` via `flyTo` with `getCameraState().zoom ± 1`; `centerOnMyLocation` via `geolocator` + `flyTo` |
| `lib/features/events/presentation/tracking/live_map_page.dart` | imports `google_maps_flutter` for `CameraPosition`/`LatLng`; default camera `LatLng(4.8133,-75.6961)` | replace `CameraPosition`→`CameraOptions`, `LatLng`→`Point(coordinates: Position(lng,lat))`. **Note Mapbox `Position` is lng,lat order.** Keep all SOS/control overlay code; wire later in 3.1/3.3/3.4 |
| `lib/features/events/presentation/tracking/widgets/initials_marker_icon.dart` | returns `BitmapDescriptor` (Google) | return `Uint8List` PNG bytes (rename `create()` → `createBytes()`); Mapbox `PointAnnotationManager.create` consumes `image: Uint8List` |
| `lib/shared/widgets/map/route_map_preview.dart` | `geocoding.locationFromAddress()`, `GoogleMap`, origin/dest `Marker`s, `_fitMapBounds` via `LatLngBounds` | see PlaceService pattern below; render `MapWidget` with two `PointAnnotation`s; fit camera via `MapboxMap.cameraForCoordinates` |

The barrel `lib/design_system/organisms/map/route_map_preview.dart` re-exports the shared widget — no change. Only consumer of `RouteMapPreview` is `event_form_locations_section.dart:80` (unchanged public API: `meetingPoint`, `destination`, `onViewMapTap`).

### PlaceService geocoding replacement (route_map_preview.dart)

`geocoding` (sync `locationFromAddress`) is removed. `PlaceService` (`lib/core/services/place_service.dart`) currently only exposes `autocomplete()`. **Add a geocode endpoint** so address→coordinates is an async Retrofit call:

- New `ApiRoutes.placesGeocode = '/places/geocode'`.
- New `PlaceService.geocode(@Query('q') String address)` → `GeocodeResultDto { double latitude; double longitude; String? formattedAddress; }`.
- New domain model `AddressLocation { double latitude; double longitude; String? label; }`.
- `route_map_preview.dart` becomes: keep 800ms debounce per field; each lookup calls `getIt<PlaceService>().geocode(...)`, tracked with `ResultState<AddressLocation>` per endpoint (origin, dest). Loading → spinner overlay (existing pattern); error → inline error banner (replace the current silent `catch`). This is the most architecturally complex piece of 3.0 — QA writes the widget test before the PR merges.

Backend already proxies Mapbox via `api-gateway/src/places/` (used for autocomplete). The geocode endpoint is a thin addition — see architect-for-backend.md.

### Native / config files (4)

| File | Change |
|------|--------|
| `pubspec.yaml` | remove `google_maps_flutter: ^2.10.0`, `geocoding: ^3.0.0`; add `mapbox_maps_flutter: ^2.2.0` + `flutter_foreground_task` (Story 3.5) |
| `android/app/src/main/AndroidManifest.xml` | remove Google Maps `com.google.android.geo.API_KEY` meta-data; runtime public token (`pk.*`) set in Dart via `MapboxOptions.setAccessToken()` in `main.dart` (reads `AppEnv.mapboxPublicToken`). Add `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` permissions + `flutter_foreground_task` service declaration (Story 3.5) |
| `android/gradle.properties` (or `~/.gradle/gradle.properties`) | `MAPBOX_DOWNLOADS_TOKEN=sk.*` (secret download token — **do NOT commit**; CI injects) |
| `ios/Runner/Info.plist` | remove Google Maps key; add `MBXAccessToken` = `pk.*`. Add/verify `NSLocationWhenInUseUsageDescription` + `NSLocationAlwaysAndWhenInUseUsageDescription` in clear Spanish. Set `UIBackgroundModes` → `location` |
| `ios/Podfile` | `platform :ios, '13.0'` minimum (already met); `pod install` after pubspec change |

**Token policy:** public token (`pk.*`) is public-scoped — keep it in `.env`/envied per no-hardcoded-strings rule, set at runtime. Download token (`sk.*`) is a secret — CI-injected only.

### Route render: GeoJsonSource + LineLayer (confirmed)

Event route polyline is rendered with `GeoJsonSource` + `LineLayer` on the Mapbox style — **NOT** `PolylineAnnotationManager`. Source data is the GeoJSON `LineString` returned by `GET /api/events/:eventId/route`. This is Story 3.9 (T-3-9), gated on 3.0.

---

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
|---------|----------------|--------------|----------------------|
| **Events / Tracking — Mapbox (3.0)** | `AddressLocation` model | `PlaceService.geocode()` + `GeocodeResultDto` | `live_map_widget.dart`, `live_map_page.dart`, `initials_marker_icon.dart`, `route_map_preview.dart` migrated to `mapbox_maps_flutter` |
| **Tracking — SOS (3.1/3.2)** | `RiderTrackingModel.isSos` bool; `SosAlert` model (riderId, name, lat, lng, phone?) | `TrackingWsClient`: `publishSos()` (`{type:'tracking.sos',data:{eventId,userId}}`), parse inbound `tracking.sos.alert` → `Stream<SosAlert>`; `RiderTrackingDto` gains `isSos` | `LiveTrackingCubit` adds `triggerSos()` + `sosAlertsResult` in state; `LiveMapPage` wires `SosButton`/`SosConfirmDialog`/`SosActiveOverlay` (remove local `_sosActive` bool); new `SosBanner` widget (Llamar/Localizar); red pulsing `PointAnnotation` for SOS riders |
| **Tracking — organizer controls (3.3/3.4)** | `StartRideUseCase`, `EndRideUseCase` | `TrackingService.startRide(eventId)` → `POST /events/:id/tracking/start`; `.endRide(eventId)` → `POST /events/:id/tracking/end`; `TrackingWsClient` parses `tracking.event.ended` → new `Stream<void> eventEnded` | `EventDetailCubit` adds `startRide()`; `EventDetailPage` shows "Iniciar rodada" (organizer + scheduled only); `LiveTrackingCubit` emits `isFinished=true` on `tracking.event.ended`; `LiveMapPage` auto-pops for all riders; organizer "Terminar rodada" wired to `EndRideUseCase` |
| **Tracking — background GPS (3.5)** | none | `LiveTrackingCubit` position stream runs inside `flutter_foreground_task` isolate on Android; iOS `geolocator` `AppleSettings(activityType: automotiveNavigation, allowBackgroundLocationUpdates: true)` | new `lib/core/services/background_tracking_service.dart` wraps `flutter_foreground_task`; `@pragma('vm:entry-point')` handler calls `configureDependencies()` in `onStart()`; `IsolateNameServer` bridges isolate→main for WS publish |
| **Tracking — route render + adherence (3.9)** | `EventRoute` model; `GetEventRouteUseCase` | `EventService.getRoute(eventId)` → `RouteGeoJsonDto` (GeoJSON LineString); repository maps to `EventRoute` | `LiveMapPage` renders route via `GeoJsonSource + LineLayer`; new `RouteAdherenceChip`; Haversine 200m check client-side (`lib/core/utils/geo_distance.dart`) |
| **Maintenance reminders (3.6)** | none (`receiveDateAlert` already on `MaintenanceModel`) | none Flutter-side; backend cron. `MaintenanceDto` already carries `nextMaintenanceDate` + `receiveDateAlert` | none — notification arrives via FCM → iter-2 notification center |
| **Event 24h reminder (3.7)** | none | none | none — pure backend cron |
| **Vehicles — Home SOAT badge (3.10)** | `VehicleModel` + `soatStatus` (enum `SoatStatus { none, valid, expiringSoon, expired }`) + `soatExpiryDate DateTime?` | `VehicleDto` gains `soatStatus`/`soatExpiryDate`; mapping in `vehicle_dto.dart`. Backend returns SOAT data from iter-2 | `home_garage_card.dart` renders iter-1 `DocumentSlotPill` molecule for main vehicle SOAT state |

---

## API contracts (rideglory-api changes)

All endpoints require Firebase ID token (Bearer) unless noted. Error shape: `{ message, statusCode, error }`.

| Method | Path | Auth | Request body | Success | Errors |
|--------|------|------|--------------|---------|--------|
| `POST` | `/api/events/:eventId/tracking/start` | Bearer — **organizer only** | none | `200 { id, state:"IN_PROGRESS" }` | `403` not organizer · `409` not `SCHEDULED` · `404` |
| `POST` | `/api/events/:eventId/tracking/end` | Bearer — **organizer only** | none | `200 { id, state:"FINISHED" }` | `403` · `409` not `IN_PROGRESS` · `404` |
| `GET` | `/api/events/:eventId/route` | Bearer | — | `200 { type:"LineString", coordinates:[[lng,lat],...] }` or `{}`/`204` if no route | `404` event |
| `GET` | `/api/places/geocode?q=<address>` | Bearer | — | `200 { latitude, longitude, formattedAddress }` | `404` no match · `400` empty q · `502` Mapbox upstream |
| WS msg | `tracking.sos` (client→server, `/api/tracking/ws`) | token in handshake | `{ type:"tracking.sos", data:{ eventId, userId } }` | server broadcasts `tracking.sos.alert` + FCM multicast | dedup: ignored if `sosTriggeredAt` set |
| WS msg | `tracking.sos.alert` (server→clients) | — | `{ type:"tracking.sos.alert", data:{ userId, fullName, latitude, longitude, phone? } }` | clients render banner + red marker | — |
| WS msg | `tracking.event.ended` (server→clients) | — | `{ type:"tracking.event.ended", data:{ eventId } }` | clients close tracking screen | emitted by `/tracking/end` |
| Cron | maintenance 30d reminder | — | — | `@Cron` (America/Bogota) inserts `notifications` row + FCM | — |
| Cron | event 24h reminder | — | — | `@Cron` every ~15min, finds events 24h out, FCM to approved registrants | — |

`tracking/start` + `tracking/end` extend `api-gateway/src/tracking/tracking-http.controller.ts` (already exists for snapshot). The SOS handler extends `tracking.gateway.ts`. `sosTriggeredAt` + `routeGeoJson` live on the events-ms `Event` model.

---

## New models and DTOs

| Name | Layer | File path | Notes |
|------|-------|-----------|-------|
| `AddressLocation` | domain (core) | `lib/shared/models/address_location.dart` | lat/lng/label for geocode result |
| `GeocodeResultDto` | data | `lib/core/services/dto/geocode_result_dto.dart` | json_serializable; matches `/places/geocode` |
| `SoatStatus` (enum) | domain | `lib/features/vehicles/domain/models/vehicle_model.dart` | `none/valid/expiringSoon/expired` — mirrors `DocumentSlotState` |
| `VehicleModel.soatStatus` + `.soatExpiryDate` | domain | `lib/features/vehicles/domain/models/vehicle_model.dart` | add to ctor, `copyWith`, `==`, `hashCode` |
| `SosAlert` | domain | `lib/features/events/domain/model/sos_alert.dart` | userId, fullName, lat, lng, phone? |
| `EventRoute` | domain | `lib/features/events/domain/model/event_route.dart` | `List<({double lat, double lng})>` from GeoJSON |
| `RouteGeoJsonDto` | data | `lib/features/events/data/dto/route_geojson_dto.dart` | GeoJSON LineString shape |
| `RiderTrackingModel.isSos` | domain | `lib/features/events/domain/model/rider_tracking_model.dart` | bool, default false |
| `StartRideUseCase`, `EndRideUseCase`, `GetEventRouteUseCase` | domain | `lib/features/events/domain/use_cases/` | thin use cases over repos |
| **Backend** `routeGeoJson Json?`, `sosTriggeredAt DateTime?` | data | events-ms `prisma/schema.prisma` `Event` model | `prisma migrate reset` discards data — no legacy migration |

---

## Environment variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MAPBOX_PUBLIC_TOKEN` (Flutter `.env` → `AppEnv`) | Public Mapbox token; set via `MapboxOptions.setAccessToken()` in `main.dart`. Public-scoped but kept in envied per no-hardcoded rule | `pk.eyJ1...` |
| `MAPBOX_DOWNLOADS_TOKEN` (gradle.properties / CI secret) | Secret SDK download token for Android Gradle + iOS Pods. **Never committed.** CI injects | `sk.eyJ1...` |
| `MAPBOX_ACCESS_TOKEN` (rideglory-api — may already exist for places) | Backend token for `/places/geocode` + `/places/autocomplete` | `pk.*`/`sk.*` |

No new backend env vars beyond Mapbox (already used by `places`). `@nestjs/schedule` + firebase-admin installed in iter-2.

---

## Boundary decision — SOS handler placement

**SOS WebSocket handler sits in `api-gateway/src/tracking/tracking.gateway.ts`** (the WebSocket boundary — connection, room membership, FCM dispatch already live there). The **`sosTriggeredAt` dedup field lives on the events-ms `Event` model**. Flow:
1. Gateway receives `tracking.sos` → RPC to events-ms `markSosTriggered(eventId)`.
2. events-ms sets `sosTriggeredAt` only if null; returns `{ triggered: bool, fullName, phone? }` (rider lookup).
3. If `triggered === true`: gateway broadcasts `tracking.sos.alert` to room AND FCM multicast to approved registrant tokens (reuse iter-2 lookup). If `false` → no-op.

Atomic dedup in the DB (events-ms owns event state); gateway owns transport + push. The HTTP `start/end` controller follows the same split: HTTP controller in api-gateway, state-transition RPC to events-ms.

---

## Risks and open questions

- **Story 3.0 consumes the sprint** — gated as iter-blocking; widget test required before merge. Mitigation: 3.0 is small and well-scoped; start day 1.
- **Mapbox `Position` is `[lng, lat]`** — opposite of Google `LatLng(lat, lng)`. High-frequency migration bug — call out in PR review.
- **`MAPBOX_DOWNLOADS_TOKEN` secret** — if missing in CI, Android/iOS build fails opaquely. DevOps must inject before 3.0 CI runs.
- **iOS CocoaPods ~200MB Mapbox binary** — CI cache key bumped immediately after 3.0 merge (devops T-3-12).
- **Android background GPS untestable in emulator** — physical device test mandatory (Xiaomi/Samsung battery restrictions). Logs attached to PR.
- **`InitialsMarkerIcon` return-type change** breaks only `live_map_widget.dart` (single caller) — migrate together.
- **`flutter_foreground_task` isolate + DI** — `configureDependencies()` in `onStart()`; `IsolateNameServer` bridges isolate→main. Same isolate-DI gotcha as iter-2 FCM background handler.
- **Open:** does events-ms already expose a generic `Event` patch/state RPC the gateway can reuse for `sosTriggeredAt`/state transition? Backend confirms in T-3-2/T-3-3; if not, add `markSosTriggered` + `transitionState` message handlers.

## Next agent needs to know

- **Backend (rideglory-api):** `tracking/start`+`tracking/end` in `tracking-http.controller.ts` (organizer guard); SOS handler in `tracking.gateway.ts` + `sosTriggeredAt` on events-ms `Event`; `routeGeoJson Json?` on `Event` + `GET /events/:id/route`; `/places/geocode` in api-gateway `places`; two `@Cron` entries in `NotificationSchedulerService` (maintenance 30d, event 24h, America/Bogota). Order: T-3-2 → T-3-4 → T-3-3 → T-3-5. `prisma migrate reset` events-ms after schema change.
- **Flutter dev:** Story 3.0 first and alone — 4 Dart + 4 native files, `PlaceService.geocode` replaces `geocoding`, `MapWidget`+annotations replace `GoogleMap`+markers, route via `GeoJsonSource+LineLayer`. Then 3.1–3.10 gated on 3.0 merge. Wire existing SOS widget stubs to `TrackingWsClient`/`LiveTrackingCubit`. `VehicleModel` SOAT fields + `DocumentSlotPill` on home card. `flutter_foreground_task` for Android bg GPS. New l10n keys with `map_`/`tracking_`/`sos_`/`vehicle_` prefixes.
- **DevOps:** add `MAPBOX_DOWNLOADS_TOKEN` CI secret before 3.0 CI; bump CocoaPods cache key after 3.0 merge; document background GPS device test in `DEPLOY.md`.
- **QA:** widget test for `route_map_preview.dart` is a hard gate before 3.0 merge; `dart analyze` 0/0 + `flutter test` no new failures; grep `lib/` for `google_maps_flutter`/`geocoding` → zero; physical device bg GPS logs (Android + iOS) attached to PR; verify `Info.plist` location strings in Spanish.

## Change log
- 2026-05-15 (iter-3): Architect phase complete. Story 3.0 Mapbox migration fully specced (4 Dart + 4 native files; `PlaceService.geocode` replacing `geocoding`; `GeoJsonSource+LineLayer` route render). Tracking SOS / organizer controls / background GPS mapped to layers. API contracts defined: `tracking/start`+`end`, `GET /events/:id/route`, `GET /places/geocode`, `tracking.sos`/`tracking.sos.alert`/`tracking.event.ended` WS messages, 2 cron entries. SOS handler boundary clarified (gateway transport + events-ms `sosTriggeredAt` dedup). `VehicleModel` SOAT fields + Home badge. ERD + SOS sequence diagram added to DIAGRAMS.md.
