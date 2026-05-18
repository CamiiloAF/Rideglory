# Frontend Handoff — Iter-3: Tracking Completo + SOS + Organizer Controls + Mapbox Migration

**Agent:** Flutter Developer
**Iteration:** 3
**Phase:** frontend
**Status:** pass
**Completed at:** 2026-05-14

---

## Stories Delivered

### Story 3.0 — Mapbox SDK Migration (blocker)
- `pubspec.yaml`: removed `google_maps_flutter ^2.10.0` and `geocoding ^3.0.0`; added `mapbox_maps_flutter ^2.2.0` and `flutter_foreground_task ^8.14.0`
- `initials_marker_icon.dart`: renamed `create()` → `createBytes()`; return type `BitmapDescriptor` → `Uint8List`
- `live_map_widget.dart`: complete rewrite to Mapbox (`MapWidget`, `PointAnnotationManager`, `LiveMapController`); diff-based annotation management (no flicker); geolocator prefixed as `geo` to avoid `Position`/`LocationSettings` name conflicts
- `live_map_page.dart`: `CameraPosition`/`LatLng` → `CameraOptions`/`Position` (lng-first); `geolocator` prefixed as `geo`; SOS/organizer/finished overlay state driven by cubit
- `route_map_preview.dart`: sync `locationFromAddress()` → debounced async `PlaceService.geocode()` + `ResultState` loading/error inline banner; `mapbox_maps_flutter` imported with `hide Error` to avoid name conflict with `result_state.dart`
- `main.dart`: Mapbox token initialized via `MapboxOptions.setAccessToken(AppEnv.mapboxPublicToken)` before `runApp()`
- `android/app/src/main/AndroidManifest.xml`: Google Maps API key removed; `flutter_foreground_task` ForegroundService declaration added with `foregroundServiceType="location"`

### Story 3.1 — SOS Button
- `sos_button.dart`: `isActive` flag; active state = transparent fill + red border; inactive = solid red; `Semantics` wrapper
- `live_map_page.dart`: SOS button passes `isActive: state.hasSentSos`; `_onSosPressed()` calls `cubit.triggerSos()`

### Story 3.2 — SOS Banner (Llamar/Localizar)
- `sos_banner.dart` (new): `SosBannerWidget` with red background, rider name, subtitle, Llamar/Localizar buttons; `url_launcher` for `tel:` URI and Maps deep link (`geo:` Android / `maps:` iOS); Llamar hidden if rider has no phone
- `sos_confirm_dialog.dart`: existing confirmation dialog wired to SOS flow
- `cubit/live_tracking_state.dart`: added `sosAlertResult`, `hasSentSos`, `isFinished` fields
- `cubit/live_tracking_cubit.dart`: `triggerSos()`, `endRide()`, `_subscribeToSosAlerts()`, `_subscribeToEventEnded()` methods
- `data/service/tracking_ws_client.dart`: `sosAlerts` stream, `eventEnded` stream, `publishSos()`, `_handleSosAlert()` handlers for `tracking.sos.alert` and `tracking.event.ended` WS messages
- `domain/model/sos_alert_model.dart` (new): `SosAlertModel` pure domain class

### Story 3.3 — Organizer "Iniciar rodada"
- `widgets/event_detail_owner_lifecycle_bar.dart` (existing): `_OwnerStartBar` with green "Iniciar evento" button; already present and wired
- `detail/cubit/event_detail_cubit.dart`: `startEvent()` and `stopEvent()` methods already implemented
- `detail/event_detail_view.dart`: `EventDetailOwnerLifecycleBar` shown in `bottomNavigationBar` for owner

### Story 3.4 — Organizer "Terminar rodada"
- `widgets/organizer_control_bar.dart` (new): `OrganizerControlBar` with "Organizador" badge + "Terminar rodada" danger button in map overlay
- `widgets/ride_finished_overlay.dart` (new): `RideFinishedOverlay` with 🏁 emoji, event name, CTA "Volver al inicio" → `context.goAndClearStack(AppRoutes.home)`
- `data/service/event_service.dart`: `startRide(eventId)` and `endRide(eventId)` Retrofit methods added
- `cubit/live_tracking_cubit_factory.dart`: passes `TrackingWsClient` and `EventService` to cubit

### Story 3.5 — Background GPS
- `tracking_location_settings.dart` (existing): Android `AndroidSettings` with `ForegroundNotificationConfig` (non-dismissible) + iOS `AppleSettings` with `allowBackgroundLocationUpdates`; already complete
- `core/services/dto/geocode_result_dto.dart` (new): `GeocodeResultDto` for async geocode response
- `core/services/place_service.dart`: `geocode(@Query('q') address)` Retrofit method added
- `shared/models/address_location.dart` (new): `AddressLocation` pure model

### Story 3.10 — VehicleModel SOAT fields + Home Dashboard SOAT badge
- `domain/models/vehicle_model.dart`: added `SoatStatus` enum (`valid`, `expiringSoon`, `expired`); added `soatStatus: SoatStatus?` and `soatExpiryDate: DateTime?` fields; `copyWith`, `==`, `hashCode` updated
- `data/dto/vehicle_dto.dart`: `soatStatus` and `soatExpiryDate` fields forwarded to `VehicleModel` in `toModel()` and `VehicleModelExtension.toJson()`
- `home_garage_card.dart`: `_VehicleInfo` shows `_SoatBadge` widget conditionally when SOAT status or expiry date is present; badge uses `DocumentSlotState`-style color coding

---

## Key New Files

| File | Purpose |
|------|---------|
| `lib/features/events/domain/model/sos_alert_model.dart` | SOS alert pure domain model |
| `lib/features/events/presentation/tracking/widgets/sos_banner.dart` | SOS banner with Llamar/Localizar |
| `lib/features/events/presentation/tracking/widgets/organizer_control_bar.dart` | Organizer control overlay bar |
| `lib/features/events/presentation/tracking/widgets/ride_finished_overlay.dart` | Ride finished full-screen overlay |
| `lib/core/services/dto/geocode_result_dto.dart` | Geocode API response DTO |
| `lib/shared/models/address_location.dart` | AddressLocation pure model |

---

## Quality Gate

- `dart analyze lib/`: **0 errors, 0 warnings** (3 info-level deprecation hints from Mapbox SDK API — acceptable)
- `flutter test`: **43 pass, 1 pre-existing failure** (TC-2-28 rider email test — unrelated to iter-3, present before our changes)
- Zero `google_maps_flutter` or `geocoding` imports in `lib/`
- Zero hardcoded strings in UI — all via `context.l10n.<key>`
- `app_es.arb` updated with ~30 new keys

---

## l10n Keys Added (partial list)

`sos_button_label`, `sos_confirm_title`, `sos_confirm_body`, `sos_confirm_action`, `sos_banner_title`, `sos_banner_subtitle_with_phone`, `sos_banner_subtitle_no_phone`, `sos_call_action`, `sos_locate_action`, `tracking_start_ride`, `tracking_end_ride`, `tracking_end_ride_confirm_title`, `tracking_end_ride_confirm_body`, `tracking_organizer_badge`, `tracking_organizer_label`, `tracking_ride_finished`, `tracking_ride_finished_body`, `tracking_back_to_home`, `vehicle_soat_badge_label`, `vehicle_soat_tap_to_add`, `vehicle_soat_update`

---

## Contracts Required from Backend

| Endpoint | Used by |
|----------|---------|
| `POST /api/events/:id/tracking/start` | `EventService.startRide()` |
| `POST /api/events/:id/tracking/end` | `EventService.endRide()` |
| `GET /api/places/geocode?q=<address>` | `PlaceService.geocode()` → `GeocodeResultDto` |
| WS `tracking.sos.alert` event | `TrackingWsClient.sosAlerts` stream |
| WS `tracking.event.ended` event | `TrackingWsClient.eventEnded` stream |

---

## Deferred / Not Implemented

- Route GeoJSON render (`GeoJsonSource + LineLayer`) — Story 3.0 route rendering: backend endpoint exists, Flutter render not implemented (T-3-9)
- Route adherence chip (En ruta / Fuera de ruta) — requires route GeoJSON to be rendered (T-3-9)
- Red pulsing SOS marker annotation — visual enhancement (T-3-6 partial)
