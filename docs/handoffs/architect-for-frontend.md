> Slim handoff — read this before docs/handoffs/architect.md

# Architect → Frontend (Flutter) — Iteration 3

**Story 3.0 is the absolute blocker. Do NOT start any other story until 3.0 is merged and `dart analyze` passes with zero errors/warnings in `lib/`.**

---

## Story 3.0 — Mapbox SDK migration (start here)

### pubspec.yaml changes

Remove: `google_maps_flutter: ^2.10.0`, `geocoding: ^3.0.0`
Add: `mapbox_maps_flutter: ^2.2.0`, `flutter_foreground_task: ^8.x` (for Story 3.5)

Run `dart run build_runner build --delete-conflicting-outputs` after pub get.

### 4 Dart files to migrate

**1. `lib/features/events/presentation/tracking/widgets/live_map_widget.dart`**
- `GoogleMap` → `MapWidget`; `GoogleMapController` → `MapboxMap`
- Markers: `PointAnnotationManager.create(PointAnnotationOptions(geometry: Point(...), image: bytes))`
- `LiveMapController.zoomIn/Out` → `mapboxMap.flyTo(CameraOptions(zoom: currentZoom ± 1))`
- `LiveMapController.centerOnMyLocation` → `geolocator` position + `mapboxMap.flyTo`
- `InitialsMarkerIcon.create()` now returns `Uint8List` — pass directly as `image:`

**2. `lib/features/events/presentation/tracking/live_map_page.dart`**
- `CameraPosition` → `CameraOptions`
- `LatLng(lat, lng)` → `Point(coordinates: Position(lng, lat))` — **Mapbox is lng-first**
- Default fallback `LatLng(4.8133, -75.6961)` → `Position(-75.6961, 4.8133)` (lng, lat)
- Remove `google_maps_flutter` import. Keep all overlay/SOS/control widget code unchanged.

**3. `lib/features/events/presentation/tracking/widgets/initials_marker_icon.dart`**
- Rename `create()` → `createBytes()`; return type `Uint8List` (not `BitmapDescriptor`)
- Last 3 lines: remove `BitmapDescriptor.bytes(...)` → return raw `Uint8List.view(bytes!.buffer)`

**4. `lib/shared/widgets/map/route_map_preview.dart`**
- Remove `geocoding` import; remove `locationFromAddress()` usage
- New state: `ResultState<AddressLocation> _originResult`, `ResultState<AddressLocation> _destResult`
- Each debounced lookup: `getIt<PlaceService>().geocode(address)` → map `GeocodeResultDto` → `AddressLocation`
- Loading state: spinner overlay (existing pattern from the widget)
- Error state: inline red banner (replace silent `catch`)
- Map: `MapWidget` with two `PointAnnotationManager` annotations; fit bounds via `MapboxMap.cameraForCoordinates`

### New PlaceService geocode method

Add to `lib/core/services/place_service.dart`:
```dart
@GET(ApiRoutes.placesGeocode)
Future<GeocodeResultDto> geocode(@Query('q') String address);
```

Add `static const placesGeocode = '/places/geocode';` to `ApiRoutes`.

New DTO: `lib/core/services/dto/geocode_result_dto.dart`
```dart
@JsonSerializable()
class GeocodeResultDto {
  final double latitude;
  final double longitude;
  final String? formattedAddress;
  // ...standard json_serializable boilerplate
}
```

New domain model: `lib/shared/models/address_location.dart`
```dart
class AddressLocation {
  final double latitude;
  final double longitude;
  final String? label;
}
```

### Native config files (4)

| File | Action |
|------|--------|
| `android/app/src/main/AndroidManifest.xml` | Remove Google Maps API key meta-data. Add `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` permissions. Add `flutter_foreground_task` service declaration. Set Mapbox token at runtime via `MapboxOptions.setAccessToken(AppEnv.mapboxPublicToken)` in `main.dart` |
| `android/gradle.properties` | Add `MAPBOX_DOWNLOADS_TOKEN=sk.*` (from CI secret — do NOT hardcode) |
| `ios/Runner/Info.plist` | Remove Google Maps key. Add `MBXAccessToken = pk.*` (from AppEnv). Add/verify `NSLocationWhenInUseUsageDescription` + `NSLocationAlwaysAndWhenInUseUsageDescription` in clear Spanish. Add `location` to `UIBackgroundModes` |
| `ios/Podfile` | Confirm `platform :ios, '13.0'`. Run `pod install` |

Add `MAPBOX_PUBLIC_TOKEN` to `.env` and `AppEnv` (envied). Call `MapboxOptions.setAccessToken(AppEnv.mapboxPublicToken)` before `runApp()`.

**QA writes the `route_map_preview.dart` widget test BEFORE the 3.0 PR opens.**

---

## Stories 3.1–3.2 — SOS (gated on 3.0)

**`LiveTrackingState`** — add fields:
```dart
ResultState<SosAlert?> sosAlertResult,  // incoming SOS from others
@Default(false) bool hasSentSos,        // this user sent SOS
```

**`LiveTrackingCubit`** — add:
- `triggerSos()`: publishes `tracking.sos` WS message; sets `hasSentSos = true`
- Listen to `TrackingWsClient.sosAlerts` stream; emit new `sosAlertResult`

**`TrackingWsClient`** — add:
- `publishSos({required String eventId, required String userId})`
- `Stream<SosAlert> get sosAlerts` (parse `tracking.sos.alert` inbound messages)

**`RiderTrackingModel`** — add `bool isSos = false`; `RiderTrackingDto` gains `isSos`.

**New widgets:**
- `lib/features/events/presentation/tracking/widgets/sos_banner.dart` — red banner with rider name, "Llamar" (`url_launcher` tel: scheme, shown only if `phone != null`), "Localizar" (deep-link to Google Maps / Apple Maps). Wire to `LiveMapPage`.
- SOS marker: in `live_map_widget.dart`, riders with `isSos == true` get a separate red `PointAnnotation` on top; use `AnimationController` overlay widget for pulsing if Mapbox annotation animation is unavailable.

Remove local `_sosActive` bool from `LiveMapPage`; replace with cubit state.

---

## Stories 3.3–3.4 — Organizer ride controls (gated on 3.0)

**New use cases:** `lib/features/events/domain/use_cases/start_ride_use_case.dart`, `end_ride_use_case.dart`

**`TrackingService`** (Retrofit client) — add:
```dart
@POST('/api/events/{eventId}/tracking/start')
Future<EventDto> startRide(@Path() String eventId);

@POST('/api/events/{eventId}/tracking/end')
Future<EventDto> endRide(@Path() String eventId);
```

**`EventDetailCubit`** — add `startRide(String eventId)` → emits `ResultState` update on success.

**`EventDetailPage`** — show "Iniciar rodada" button only when `currentUser.id == event.ownerId && event.state == scheduled`.

**`LiveTrackingState`** — add `@Default(false) bool isFinished`.

**`LiveTrackingCubit`** — listen to `TrackingWsClient.eventEnded` stream; emit `isFinished = true`.

**`TrackingWsClient`** — add `Stream<void> get eventEnded` (parse `tracking.event.ended`).

**`LiveMapPage`** — `BlocListener` on `isFinished`: auto-pop when `true`. Organizer "Terminar rodada" button wired to `EndRideUseCase`.

---

## Story 3.5 — Background GPS

**Android:** `flutter_foreground_task` (already added in pubspec during 3.0).
- Create `lib/core/services/background_tracking_service.dart`.
- `@pragma('vm:entry-point')` on top-level `void startCallback()` function.
- Call `configureDependencies()` inside `onStart()`.
- Use `IsolateNameServer` to bridge location updates from isolate → main for WS publish.
- Permissions in `AndroidManifest.xml`: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`.

**iOS:** `geolocator` with:
```dart
AppleSettings(
  activityType: ActivityType.automotiveNavigation,
  allowBackgroundLocationUpdates: true,
  showBackgroundLocationIndicator: true,
)
```

Physical device test logs (Android + iOS) are mandatory for PR merge.

---

## Story 3.9 — Route render + adherence chip

**New use case + data:** `GetEventRouteUseCase` → `EventService.getRoute(eventId)` (`GET /api/events/:eventId/route`) → `RouteGeoJsonDto` → `EventRoute` domain model.

**`LiveMapPage`** on load: fetch route; render via `GeoJsonSource` + `LineLayer` on Mapbox style.

**New `RouteAdherenceChip` widget:** Haversine 200m check — `lib/core/utils/geo_distance.dart`:
```dart
double haversineMeters(double lat1, double lng1, double lat2, double lng2)
```
Check current user position against each GeoJSON coordinate; show "En ruta ✓" or "Fuera de ruta ⚠" chip.

---

## Story 3.10 — VehicleModel SOAT fields + Home badge

**`VehicleModel`** — add:
```dart
final SoatStatus? soatStatus;   // enum: none, valid, expiringSoon, expired
final DateTime? soatExpiryDate;
```
Update `copyWith`, `==`, `hashCode`.

**`VehicleDto`** — add `soatStatus` (JSON string → enum mapping) + `soatExpiryDate` (ISO string).

**`home_garage_card.dart`** — render `DocumentSlotPill` molecule for main vehicle's SOAT state.

---

## l10n keys (new, `map_`/`sos_`/`tracking_`/`vehicle_` prefix)

| Key | Spanish value |
|-----|--------------|
| `sos_button_label` | `SOS` |
| `sos_confirm_title` | `¿Enviar alerta SOS?` |
| `sos_confirm_body` | `Todos los participantes serán notificados de tu emergencia.` |
| `sos_sent_confirmation` | `SOS enviado` |
| `sos_call_action` | `Llamar` |
| `sos_locate_action` | `Localizar` |
| `tracking_start_ride` | `Iniciar rodada` |
| `tracking_end_ride` | `Terminar rodada` |
| `tracking_route_on_route` | `En ruta ✓` |
| `tracking_route_off_route` | `Fuera de ruta ⚠` |
| `tracking_ride_finished` | `La rodada ha terminado` |

> Full detail: docs/handoffs/architect.md
