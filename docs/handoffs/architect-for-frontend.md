> Slim handoff — read this before docs/handoffs/architect.md

# Architect → Frontend (Flutter) — Iteration 6 (refactor-01)

**Date:** 2026-05-27
**Execution order:** implement T-6-1 through T-6-17 in strict linear sequence. One commit minimum per task. `dart analyze && flutter test` before each commit.

---

## Pre-flight baseline

```bash
dart analyze lib/ 2>&1 | tee /tmp/analyze_baseline.txt
flutter test 2>&1 | tail -5 | tee /tmp/test_baseline.txt
```

Expected: 2 warnings in `api_base_url_resolver.dart` (lines 17–19 — do NOT touch), 0 elsewhere. TC-2-28 pre-existing failure is acceptable — record it.

---

## T-6-1: REFACTOR-01 — Fix SOAT loading-button bug

**File:** `lib/features/soat/presentation/widgets/soat_data_view.dart`

Replace label-swap pattern with:
```dart
AppButton(
  label: context.l10n.soat_view_document,
  isLoading: _openingDocument,
  onPressed: _openDocument,  // AppButton.isLoading internally guards — no null-guard needed
)
```

DoD: `grep "soat_downloading" soat_data_view.dart` = 0; `grep "isLoading: _openingDocument"` = 1.

---

## T-6-2: REFACTOR-02 — Consolidate SOAT feature (+ REFACTOR-12)

High-risk. Full detail: PLAN.md §REFACTOR-02.

**MOVE** (update import paths):
- `vehicles/presentation/soat/soat_manual_capture_page.dart` → `soat/presentation/pages/`
- `vehicles/presentation/soat/soat_confirmation_page.dart` → `soat/presentation/pages/`
- `vehicles/presentation/soat/cubit/soat_form_cubit.dart` + `.freezed.dart` → `soat/presentation/cubit/`
- `vehicles/presentation/soat/widgets/soat_document_section.dart` → `soat/presentation/widgets/`
- `vehicles/presentation/soat/widgets/soat_validity_card.dart` → `soat/presentation/widgets/`
- `vehicles/presentation/soat/widgets/vehicle_soat_options_sheet.dart` → `soat/presentation/widgets/soat_vehicle_options_sheet.dart`

**DELETE** (superseded):
`soat_upload_page.dart`, `soat_upload_cubit.dart` (triggers DI regen), `soat_upload_option_card.dart`, `soat_manual_option_card.dart`, `soat_upload_question_header.dart`, `soat_vehicle_info_card.dart`, `soat_doc_preview.dart`, `soat_confirm_cta_bar.dart`, `soat_valid_alert.dart`

**DI regen immediately after deleting `soat_upload_cubit.dart`:**
```bash
dart run build_runner build --delete-conflicting-outputs
grep -rn "SoatUploadCubit" lib/ --include="*.dart"  # must be 0
dart analyze lib/
```

**Router:** keep `/vehicles/soat` route wired to new `SoatUploadPage`; add `AppRoutes.soatManualCapture = '/soat/manual-capture'` and corresponding `GoRoute`.

**NEW file:** `soat/presentation/pages/soat_manual_capture_params.dart` (params class).

**Justified Navigator annotations** (copy verbatim):
```dart
// Custom: sheetCtx.pop() — required pattern for showModalBottomSheet typed result return
// Custom: pushReplacement — VehicleFormPage must not remain in back stack after SOAT confirmation
```

**REFACTOR-12 (bundle here):** add 3-line exception comment in `notifications_state.dart`:
```dart
// Exception: isLoadingMore is a secondary loading indicator for cursor-based pagination append.
// It cannot be replaced by a second ResultState<List> because listResult must remain in Data
// state while additional pages are loading. Documented exception to the no-primitive-flag rule.
```

---

## T-6-3: REFACTOR-10 — context.goNamed violations

**Keep + annotate** (do NOT change) in PopScope of `profile_page.dart`, `garage_page.dart`, `events_page.dart`:
```dart
// Intentional: shell-tab navigation resets stack to prevent back-stack accumulation in StatefulShellRoute
```

**Replace** in `forgot_password_view.dart` ×2: `context.goNamed(AppRoutes.login)` → `context.pop()`

---

## T-6-4: REFACTOR-08 — FormBuilderTextField → AppTextField

5 occurrences in 4 files: `vehicle_specs_row.dart` (1), `vehicle_form_id_section.dart` (2), `maintenance_next_km_pill.dart` (1), `event_form_price_section.dart` (1). Map `name`, `labelText`, `validators` directly.

---

## T-6-5: REFACTOR-07 — Raw buttons → AppButton/AppTextButton

8 instances in 6 files. `sos_active_overlay.dart` OutlinedButton: verify `AppButton(style: AppButtonStyle.outlined)` matches the style; if not: `// Custom: SOS overlay requires OutlinedButton — AppButton outlined style does not match this context`.

Pre-condition: check `rider_profile_page_test.dart` for `find.byType(ElevatedButton)` — update test in same commit if found.

---

## T-6-6: REFACTOR-13 — showDialog fix

**File:** `info_chip_tooltip.dart` — replace `showDialog(...)` with `AppDialog`. If info-only with no action buttons: `// Custom: MileageInfoDialog is an info-only tooltip — AppDialog requires action buttons`. Also replace `Colors.black.withValues(...)` with `AppColors.*` or `colorScheme.*`.

---

## T-6-7: REFACTOR-11 — Color tokenization

**First commit: add new tokens to `lib/design_system/foundation/theme/app_colors.dart`:**
```dart
static const Color statusGreen = Color(0xFF22C55E);   // Tailwind green-500
static const Color statusWarning = Color(0xFFEAB308); // Tailwind yellow-500
static const Color statusError = Color(0xFFEF4444);   // Tailwind red-500
```

`primarySubtle` already exists. For `Color(0x66F98C1F)` → `colorScheme.primary.withValues(alpha: 0.4)`.

Annotations: `// Intentional: remove Material3 surface tint` for `Colors.transparent` in `surfaceTintColor`; `// Intentional: gradient stop` for gradient `Colors.transparent`.

Do color work in same commit as widget extraction (T-6-9/T-6-11) where files overlap, to avoid double-editing.

---

## T-6-8 through T-6-14: Widget extraction stories

See PLAN.md for each story's file list and extraction strategy. Key rules for all:
- One widget class per file (State<T> may coexist with its StatefulWidget)
- No `BuildContext` constructor params
- No widget-returning methods
- State mutators: typed callback constructor param
- State consumers: encapsulate BlocBuilder inside new widget file
- Extract one widget per commit; `flutter test` after each commit

**T-6-9 specific:** Classify each of `garage_vehicles_content.dart`'s 16 classes (pure-display / state-consumer / state-mutator) BEFORE touching the file.

**T-6-11 specific:** HARD AC — manually smoke-test all 4 CTA state variants (registered/pending/closed/full) for `event_detail_cta_bar.dart`.

**Unnamed-route decision (T-6-11, T-6-12):** Option B — annotate with:
```dart
// Custom: EventRouteConfigScreen has no go_router named route — anonymous push preserved.
// Reason: ephemeral form sub-screen, no deep-link requirement, router surface kept minimal.
// Custom: EventRouteMapScreen has no go_router named route — anonymous push preserved.
// Reason: ephemeral map preview, no deep-link requirement, router surface kept minimal.
```

---

## T-6-15: REFACTOR-09 — Migrate remaining Navigator calls

Two greps required (do both):
```bash
grep -rn "Navigator\.of(context)\." lib/features/ --include="*.dart" | grep -v "// Custom:"
grep -rn "Navigator\.pop(context" lib/features/ --include="*.dart" | grep -v "SystemNavigator\|// Custom:"
```

Justified exceptions (already annotated in T-6-2 — do not re-annotate):
- `vehicle_form_page.dart` pushReplacement
- `soat_manual_capture_page.dart` sheetCtx.pop ×3

For `maintenance_filters_bottom_sheet.dart` `Navigator.pop(context, _filters)` → `context.pop(_filters)` (if not done in T-6-13).

---

## T-6-16: REFACTOR-14 — AppFormNavHeader molecule

**Create:** `lib/design_system/molecules/app_form_nav_header.dart`

Implement the locked API from `architect.md §Decision A`:
- `AppFormNavAction` sealed class with `.text({label, onTap, emphasized, isLoading})`, `.icon({icon, onTap, pill})`, `.pillText({label, onTap, isLoading})`
- `AppFormNavHeader` with `title`, `leading`, `trailing`, `bottom`, `height=56`, `showBottomBorder=true`, `centerTitle=true`
- `PreferredSizeWidget` implementation; `preferredSize` accounts for `bottom` slot height

Migration:
| Old | New leading | New trailing | height |
|-----|------------|-------------|--------|
| `VehicleFormNavHeader` | `.text("Cancelar")` | `.text("Guardar", emphasized: true, isLoading: ...)` | 56 |
| `MaintenanceFormNavHeader` | `.icon(back, pill: true)` | `.pillText("Listo", isLoading: ...)` | 52 |
| `event_form_view.dart` AppBar | `.text("Cancelar")` | `.text("Publicar"/"Guardar cambios", emphasized: true, isLoading: ...)` | 56 |

Delete old feature-level nav header files after migration. Screenshot smoke test all 3 forms.

---

## T-6-17: REFACTOR-15 — ARB cleanup (execute LAST)

Target: 1357 → ≤1220 keys. 3 phases, one commit per phase.

```bash
jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_es.arb | wc -l
```

DO NOT DELETE keys matching dynamic patterns:
```bash
grep -rn "l10n\.\${" lib/ --include="*.dart"
grep -rn "l10n\.\w\+('" lib/ --include="*.dart" | grep -v "^lib/l10n/"
```

Spot-check families: `maintenanceType*`, `eventStatus*`, `registrationStatus*`, `notification_*`.

Run `flutter gen-l10n` and commit generated files after Phase 3.

---

## Hard constraints

- No new packages in `pubspec.yaml`
- No domain/ or data/ layer changes
- No API contract changes
- `api_base_url_resolver.dart` — DO NOT TOUCH (its 2 warnings are accepted out-of-scope)

> Full detail: docs/handoffs/architect.md

---

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
