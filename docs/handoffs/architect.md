# Architect handoff — Iteration 6 (refactor-01)

**Date:** 2026-05-27
**Status:** done
**Type:** REFACTORING ONLY — zero new features, zero API changes, zero DB changes

---

## Iteration scope

Pure internal Flutter refactor. 17 stories. No new packages, no new API contracts, no new Retrofit endpoints, no new domain models, no new DTOs, no rideglory-api changes. Backend is fully on stand-down. Architect's work is entirely Flutter-layer decisions and component API specification.

---

## Story-to-layer mapping

All 17 stories are **presentation-layer only**. Exceptions noted:

| Story (REFACTOR-ID) | Flutter layer | Files touched | Notes |
|---------------------|--------------|---------------|-------|
| REFACTOR-01 | Presentation | `soat/presentation/widgets/soat_data_view.dart` | Single prop swap on AppButton |
| REFACTOR-02 | Presentation + DI | `vehicles/presentation/soat/*` → `soat/presentation/*`; `app_router.dart`; `app_routes.dart`; `injection.config.dart` (regen) | Only story touching DI; requires `build_runner` |
| REFACTOR-03a | Presentation | `vehicles/presentation/garage/widgets/*` | Widget extraction only |
| REFACTOR-03b | Presentation | `vehicles/presentation/form/*`, `vehicles/presentation/widgets/*` | Widget extraction only |
| REFACTOR-04 | Presentation | `authentication/login/presentation/*`, `authentication/signup/presentation/*` | Widget extraction only |
| REFACTOR-05a | Presentation | `events/presentation/detail/*` | Widget extraction; unnamed-route decision applies (see §Decision B) |
| REFACTOR-05b | Presentation | `events/presentation/form/*`, `events/presentation/tracking/*`, `events/presentation/list/*`, `events/presentation/drafts/*` | Widget extraction; unnamed-route decision applies (see §Decision B) |
| REFACTOR-06a | Presentation | `maintenance/presentation/*` | Widget extraction + `showDialog` fix (REFACTOR-13 bundled) |
| REFACTOR-06b | Presentation | `home/presentation/*`, `profile/presentation/*`, `users/presentation/widgets/*`, `event_registration/presentation/*` | Widget extraction |
| REFACTOR-07 | Presentation | 6 feature files | Raw button replacement |
| REFACTOR-08 | Presentation | 4 feature files | FormBuilderTextField → AppTextField |
| REFACTOR-09 | Presentation | 13+ feature files | Navigator.of → go_router |
| REFACTOR-10 | Presentation | `profile_page.dart`, `garage_page.dart`, `events_page.dart`, `forgot_password_view.dart` | goNamed annotations/replacements |
| REFACTOR-11 | Presentation | 25+ feature files | Color token replacement; `app_colors.dart` addition |
| REFACTOR-12 | Presentation | `notifications/presentation/cubit/notifications_state.dart` | Comment-only addition |
| REFACTOR-13 | Presentation | `maintenance/presentation/widgets/item_card/info_chip_tooltip.dart` | showDialog → AppDialog/annotation |
| REFACTOR-14 | Design system | `lib/design_system/molecules/app_form_nav_header.dart` (NEW); 3 feature form headers deleted | New molecule; 3 migration targets |
| REFACTOR-15 | Localization | `lib/l10n/app_es.arb` + generated files | ARB audit, 3-phase cleanup |

**No domain/ or data/ layer changes in any story.**

---

## API contracts (rideglory-api changes)

None. Backend stand-down this iteration.

---

## New models and DTOs

None. Refactor only.

---

## Environment variables

None. No new `.env` keys.

---

## Architectural decisions resolved

### A. AppFormNavHeader API (REFACTOR-14)

**Locked API — implement exactly as specified:**

```dart
// lib/design_system/molecules/app_form_nav_header.dart

/// Sealed variants for leading/trailing actions on form nav headers.
/// Use [AppFormNavAction.text] for text buttons (Cancelar, Guardar, Publicar).
/// Use [AppFormNavAction.icon] for icon-only buttons (back arrow, optionally in pill).
/// Use [AppFormNavAction.pillText] for pill-styled primary action buttons (Listo).
sealed class AppFormNavAction {
  const factory AppFormNavAction.text({
    required String label,
    required VoidCallback onTap,
    bool emphasized,    // true → semi-bold/primary color (e.g. "Guardar", "Publicar")
    bool isLoading,     // true → shows inline spinner, disables tap
  }) = AppFormNavActionText;

  const factory AppFormNavAction.icon({
    required IconData icon,
    required VoidCallback onTap,
    bool pill,          // true → 36×36 pill container (Maintenance back button)
  }) = AppFormNavActionIcon;

  const factory AppFormNavAction.pillText({
    required String label,
    required VoidCallback onTap,
    bool isLoading,     // true → shows inline spinner, disables tap
  }) = AppFormNavActionPillText;
}

/// Centralized form navigation header.
/// Replaces: VehicleFormNavHeader (56px), MaintenanceFormNavHeader (52px),
/// and the inline AppBar in event_form_view.dart.
/// Implements [PreferredSizeWidget] — plug directly into Scaffold.appBar.
class AppFormNavHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppFormNavHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.bottom,        // optional slot: progress bars (Maintenance form)
    this.height = 56.0, // Vehicle=56, Maintenance=52; set per caller
    this.showBottomBorder = true,
    this.centerTitle = true,
  });

  final String title;
  final AppFormNavAction? leading;
  final AppFormNavAction? trailing;
  final Widget? bottom;
  final double height;
  final bool showBottomBorder;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(
    bottom != null ? height + kBottomNavigationBarHeight * 0.5 : height,
  );
}
```

**Migration map:**

| Old file | Leading | Trailing | height | bottom |
|----------|---------|---------|--------|--------|
| `VehicleFormNavHeader` | `text("Cancelar", emphasized: false)` | `text("Guardar", emphasized: true, isLoading: ...)` | 56 | null |
| `MaintenanceFormNavHeader` | `icon(backIcon, pill: true)` | `pillText("Listo", isLoading: ...)` | 52 | `MaintenanceProgressBars(...)` (extract as separate widget) |
| `event_form_view.dart` AppBar | `text("Cancelar")` | `text("Publicar"/"Guardar cambios", emphasized: true, isLoading: ...)` | 56 | null |

**Out of scope:** `LiveMapSimpleAppBar`, `LiveMapOverlayAppBar`, `MaintenancesPageAppBar`.

**String unification:** Coordinate with REFACTOR-15. `vehicle_form_nav_cancel` / `event_form_nav_cancel` / `maintenance_form_nav_cancel` (all = "Cancelar") → collapse to `common_cancel`.

---

### B. Unnamed-route decision (REFACTOR-05a, 05b, 09)

**Decision: Option B — annotate `// Custom:`, do NOT add named routes.**

Justification: `EventRouteConfigScreen` and `EventRouteMapScreen` are ephemeral form sub-flows launched from a single callsite each, with no deep-link requirements. Adding named routes would require router changes and `extra` serialization — disproportionate complexity for a refactor-only iteration. Option B preserves intent transparently.

**Exact annotation to apply (copy verbatim):**

```dart
// Custom: EventRouteConfigScreen has no go_router named route — anonymous push preserved.
// Reason: ephemeral form sub-screen, no deep-link requirement, router surface kept minimal.
Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventRouteConfigScreen()));

// Custom: EventRouteMapScreen has no go_router named route — anonymous push preserved.
// Reason: ephemeral map preview, no deep-link requirement, router surface kept minimal.
Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventRouteMapScreen(route: route)));
```

---

### C. REFACTOR-12 exception pattern (`bool isLoadingMore`)

**Decision: Option A confirmed.** Keep `bool isLoadingMore`. Add this exact 3-line comment block immediately above the field:

```dart
// Exception: isLoadingMore is a secondary loading indicator for cursor-based pagination append.
// It cannot be replaced by a second ResultState<List> because listResult must remain in Data
// state while additional pages are loading. Documented exception to the no-primitive-flag rule.
@Default(false) bool isLoadingMore,
```

**Canonical exception template for any future ResultState<T> deviation:**
```
// Exception: <field> is <purpose>.
// It cannot be replaced by ResultState<T> because <reason>.
// Documented exception to the no-primitive-flag rule.
```

---

### D. Color tokens (REFACTOR-11)

**Decision: Add new tokens. Do NOT remap to existing `success`/`warning`/`error`.**

Current `AppColors` status tokens are Tailwind amber/emerald variants (≠ green-500/yellow-500). Add to `lib/design_system/foundation/theme/app_colors.dart`:

```dart
// ─── Status — Tailwind-exact (distinct from success/warning/error variants) ──
/// Tailwind green-500 — status badge "active/vigente"
static const Color statusGreen = Color(0xFF22C55E);
/// Tailwind yellow-500 — status badge "expiring/por vencer"
static const Color statusWarning = Color(0xFFEAB308);
/// Tailwind red-500 — status badge "expired/vencido" (aliases AppColors.error)
static const Color statusError = Color(0xFFEF4444);
```

**Note:** `primarySubtle` already exists (`Color(0xFF2D2117)`). Do NOT add a new one. For `Color(0x66F98C1F)` use `colorScheme.primary.withValues(alpha: 0.4)` inline.

Rationale: `statusGreen` (0xFF22C55E) ≠ `success` (0xFF10B981); `statusWarning` (0xFFEAB308) ≠ `warning` (0xFFF59E0B). Blind remapping changes rendered SOAT badge colors — a visual regression disguised as a refactor.

---

### E. `AppButton.isLoading` contract (REFACTOR-01)

**Verified from `lib/shared/widgets/form/app_button.dart` line 77:**

```dart
onTap: onPressed == null || isLoading ? null : onPressed,
```

`AppButton` **internally guards `onPressed` when `isLoading: true`**. Therefore REFACTOR-01 only needs:

```dart
AppButton(
  label: context.l10n.soat_view_document,
  isLoading: _openingDocument,
  onPressed: _openDocument,  // no null-guard needed — AppButton handles it
)
```

The dual-condition fallback (`onPressed: _openingDocument ? null : _openDocument`) is NOT needed.

---

### F. DI regeneration sequence (REFACTOR-02)

**Exact command sequence after deleting `soat_upload_cubit.dart`:**

```bash
# Step 1: delete the file
rm lib/features/vehicles/presentation/soat/cubit/soat_upload_cubit.dart

# Step 2: regenerate all generated files
dart run build_runner build --delete-conflicting-outputs

# Step 3: verify clean
grep -rn "SoatUploadCubit\|soat_upload_cubit" lib/ --include="*.dart"
# Must return 0 results

grep "SoatUploadCubit" lib/core/di/injection.config.dart
# Must return 0 results

dart analyze lib/
# Must return 0 errors
```

Run this before any other REFACTOR-02 steps that depend on clean compile.

---

### G. REFACTOR-15 l10n cleanup strategy

**3-phase approach confirmed.** Target: ≥10% reduction (1357 → ≤1220 keys).

**Key extraction command:**
```bash
jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_es.arb | wc -l
jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_es.arb > /tmp/arb_keys.txt
```

**Usage grep pattern:**
```bash
grep -rn "context\.l10n\." lib/features/ --include="*.dart" \
  | awk -F'context.l10n.' '{print $2}' \
  | awk -F'[^a-zA-Z0-9_]' '{print $1}' \
  | sort -u > /tmp/used_keys.txt

comm -23 <(sort /tmp/arb_keys.txt) /tmp/used_keys.txt > /tmp/unused_candidates.txt
```

**High-risk dynamic-reference patterns — DO NOT DELETE even if grep returns 0:**
1. Keys assembled via string interpolation: `context.l10n.${'prefix_$suffix'}`
2. Keys with `@` metadata `"placeholders"` — method-style generated accessors (check `.dart` file, not `.arb` consumers)
3. `switch`-assembled key families: `maintenanceType*`, `eventStatus*`, `registrationStatus*`
4. FCM notification type routing keys: `notification_*` selected at runtime from payload

**Dynamic reference detection:**
```bash
grep -rn "l10n\.\${" lib/ --include="*.dart"
grep -rn "l10n\.\w\+('" lib/ --include="*.dart" | grep -v "^lib/l10n/"
```

**Phase 2 unification targets (high-confidence common_ keys):**
`common_cancel`, `common_save`, `common_back`, `common_continue`, `common_accept`, `common_confirm`, `common_delete`, `common_edit`, `common_close`, `common_done`, `common_yes`, `common_no`, `common_retry`.

---

## No DIAGRAMS.md update

SOAT consolidation is a file move within the same feature — no data model boundary changes, no new sequence flows. Existing DIAGRAMS.md SOAT-save sequence (iter-2) remains accurate. No new diagrams needed.

---

## Risks and open questions

| Risk | Mitigation |
|------|-----------|
| SOAT blast perimeter — missed import causes compile error | `grep -r "vehicles/presentation/soat" lib/` before any deletion |
| `garage_vehicles_content.dart` shared state during extraction | Classify each class before touching; one extract per commit with `flutter test` after each |
| `event_detail_cta_bar.dart` has no widget tests — silent regression | 4-variant CTA smoke test is HARD acceptance criterion (not optional) |
| REFACTOR-15 deletes dynamically-referenced key → runtime crash | Run `flutter gen-l10n` + debug app after each batch; commit per phase |
| `Navigator.pop(context)` invisible to standard grep | Separate grep: `grep -rn "Navigator\.pop(context"` |
| statusGreen ≠ existing success token | New tokens committed first as standalone commit |

---

## Next agent: frontend

Frontend implements all 17 tasks in linear order T-6-1 → T-6-17. See `architect-for-frontend.md` for the feature-by-feature change list. Key constraints:
- REFACTOR-01 first (single-file baseline fix)
- REFACTOR-02 second (high-risk SOAT consolidation + DI regen)
- REFACTOR-11 color tokens committed as a standalone commit BEFORE any literal replacement
- REFACTOR-15 executed last, after all other stories have added/removed keys

---

## Change log

- 2026-05-27: Iteration 6 (refactor-01) architect phase complete. Decisions A-G resolved. AppFormNavHeader API locked. Unnamed-route Option B selected. REFACTOR-12 exception pattern confirmed. 3 new AppColors status tokens specified. AppButton.isLoading internal guard verified. DI regen sequence documented. REFACTOR-15 strategy confirmed. 4 slim handoffs written.

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
