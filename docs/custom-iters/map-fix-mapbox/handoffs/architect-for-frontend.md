# Architect → Frontend Handoff — map-fix-mapbox

## TL;DR

Five-file fix to make the Mapbox map render on iOS and surface visible errors on load failure. The PRD's `$(MAPBOX_PUBLIC_TOKEN)` build-variable form does **not** work today (no xcconfig wiring) — use the literal `pk.*` token instead. The Mapbox callback name is `onMapLoadErrorListener` (with `Listener` suffix), not `onMapLoadError`.

## Files to edit (in this order)

### 1. `lib/main.dart` — fail-fast token assertion

Current (lines 40–43):
```dart
const mapboxToken = AppEnv.mapboxPublicToken;
if (mapboxToken != null && mapboxToken.isNotEmpty) {
  MapboxOptions.setAccessToken(mapboxToken);
}
```

Replace with:
```dart
const mapboxToken = AppEnv.mapboxPublicToken;
assert(
  mapboxToken != null && mapboxToken.isNotEmpty,
  'MAPBOX_PUBLIC_TOKEN must be set in .env',
);
MapboxOptions.setAccessToken(mapboxToken!);
```

Note: keep `const` (matches existing) — `AppEnv.mapboxPublicToken` is compile-time constant.

### 2. `ios/Runner/Info.plist` — add `MBXAccessToken`

Insert before the closing `</dict>` (line 76) and **outside** the `#ifdef RIDEGLORY_DEV_ATS ... #endif` block. Place it after `UIBackgroundModes`:

```xml
	<key>MBXAccessToken</key>
	<string>YOUR_MAPBOX_PUBLIC_TOKEN</string>
```

The token literal matches `MAPBOX_ACCESS_TOKEN` in `android/local.properties` line 7. Do **not** use `$(MAPBOX_PUBLIC_TOKEN)` — that build variable is not defined in any xcconfig and would resolve to empty.

After this edit run:
```bash
flutter clean
cd ios && pod install   # only if Pods/ is missing; usually skip
cd ..
flutter run -d <ios-simulator-id>
```

### 3. `lib/shared/widgets/map/route_map_preview.dart` — error placeholder

Keep the existing `import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;` — `MapLoadingErrorEventData` is unaffected by the hide.

**a)** In `_RouteMapPreviewState`, add a new field next to `_mapboxMap` (around line 33):
```dart
bool _mapLoadError = false;
```

**b)** In `build()`, change the condition at line 225 from:
```dart
if (_hasCoordsToShow)
  MapWidget(...)
else
  Center(...)
```
to:
```dart
if (_hasCoordsToShow && !_mapLoadError)
  MapWidget(...)
else
  Center(...)   // existing placeholder reused as-is
```

**c)** Inside `MapWidget(...)`, add the listener right after `onMapCreated`:
```dart
onMapLoadErrorListener: (MapLoadingErrorEventData data) {
  if (!mounted) return;
  setState(() => _mapLoadError = true);
},
```

The existing "Vista previa del mapa" / "Ingresa las dirección para ver la ruta" placeholder Column is reused verbatim — no copy or style changes.

### 4. `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` — expose error callback

**a)** Add a new optional parameter to the constructor (after `riders`):
```dart
class LiveMapWidget extends StatefulWidget {
  const LiveMapWidget({
    super.key,
    required this.onMapReady,
    required this.initialCameraOptions,
    required this.riders,
    this.onMapError,
  });

  final LiveMapReadyCallback onMapReady;
  final CameraOptions initialCameraOptions;
  final List<RiderTrackingModel> riders;
  final ValueChanged<String>? onMapError;
  // ...
}
```

**b)** In `build()`, add the listener to `MapWidget`:
```dart
return MapWidget(
  viewport: CameraViewportState(...),
  styleUri: MapboxStyles.STANDARD,
  onMapCreated: (mapboxMap) async { /* existing */ },
  onMapLoadErrorListener: (MapLoadingErrorEventData data) {
    widget.onMapError?.call(data.message);
  },
);
```

Pass only the `message` string upward — do not leak `MapLoadingErrorEventData` to consumers.

### 5. `lib/features/events/presentation/tracking/widgets/live_map_body.dart` — show SnackBar

In the `LiveMapWidget` instantiation (around line 61), wire the callback:

```dart
return LiveMapWidget(
  initialCameraOptions: initialCamera,
  riders: riders,
  onMapReady: (controller) => mapController.value = controller,
  onMapError: (message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.map_loadError)),
    );
  },
);
```

`removeCurrentSnackBar()` first prevents stacking if the listener fires repeatedly during rider-list rebuilds.

### 6. `lib/l10n/app_es.arb` — new key (optional but recommended)

Add a new key near the other `map_*` entries (alphabetical-ish around line 332):
```json
"map_loadError": "No se pudo cargar el mapa.",
"@map_loadError": {
  "description": "Shown as a SnackBar when the Mapbox map fails to load tiles or style during a live ride."
},
```

Then regenerate:
```bash
dart run build_runner build --delete-conflicting-outputs
```
(or `flutter gen-l10n` if that's the standing convention).

If you prefer to skip the new key, reuse `context.l10n.map_geocodeError` in step 5 — but architect recommends the new key because the geocode message is misleading in the tracking context.

## Mapbox API reference (verified in 2.23.1)

- Parameter: `MapWidget.onMapLoadErrorListener` (with `Listener` suffix)
- Type: `OnMapLoadErrorListener` = `void Function(MapLoadingErrorEventData)`
- Event data fields used: `message` (String). Other fields (`type`, `sourceId`, `tileId`, `timestamp`) are available but unused for this fix.

## What NOT to touch

- `_geocodeAddress`, `_fitMapBounds`, `_updateAnnotations` in `route_map_preview.dart`
- `_loadMarkerIcons`, `_updateAnnotations`, `InitialsMarkerIcon`, `LiveMapController` in `live_map_widget.dart`
- Any cubit, repository, or DI registration
- Android files — Android already works
- `pubspec.yaml`, `pubspec.lock`

## Verification checklist before handoff to QA

- [ ] `dart analyze lib/` — 0 errors (the `_formatKm` warning is pre-existing and acceptable)
- [ ] `dart format lib/main.dart lib/shared/widgets/map/route_map_preview.dart lib/features/events/presentation/tracking/widgets/live_map_widget.dart lib/features/events/presentation/tracking/widgets/live_map_body.dart` — no changes after format
- [ ] `flutter test` — same baseline as before iteration (TC-2-28 failure acceptable)
- [ ] Manual smoke on iOS simulator — event detail map tiles render
- [ ] Manual smoke on Android emulator — event detail map tiles render (regression check)
- [ ] Manual error path — temporarily corrupt the token in `.env` (e.g. `pk.invalid`), rerun `dart run build_runner build --delete-conflicting-outputs`, hot-restart the app, open event detail → placeholder shows in `RouteMapPreview`. Open live tracking → SnackBar with "No se pudo cargar el mapa." appears. Restore the token after testing.
