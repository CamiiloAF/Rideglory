# PO Handoff — map-fix-mapbox

## Goal

Fix the Mapbox black-screen bug on both platforms by adding `MBXAccessToken` to `ios/Runner/Info.plist`, replacing the conditional token set in `main.dart` with a fail-fast assertion, and wiring `onMapLoadError` handlers on both map widgets so failures surface as visible UI instead of a silent black rectangle.

---

## Interpretation

The PRD is a self-contained, well-diagnosed bug report. The root cause is unambiguous: the iOS Mapbox SDK initializes natively before Dart runs, so `Info.plist` must carry the public token. The conditional guard in `main.dart` is a latent risk (silently no-ops on misconfigured builds) that should be hardened. Both `RouteMapPreview` and `LiveMapWidget` lack error handlers on `MapWidget`, so any failure — token, network, scope — renders silently black.

No backend, design, or DB work is needed. All changes are purely Flutter + native config. The fix is four files; the largest is `route_map_preview.dart` where a `_mapLoadError` bool field and a new branch in `build()` are required.

Key confirmed facts from reading the source:
- `mapbox_maps_flutter` 2.23.1 is the resolved version in `pubspec.lock` — `onMapLoadError` is available.
- `ios/Runner/Info.plist` has NO `MBXAccessToken` key (confirmed line-by-line).
- `main.dart` lines 40–43 use the conditional guard exactly as the PRD describes.
- `RouteMapPreview.build()` instantiates `MapWidget` with only `onMapCreated` — no error handler.
- `LiveMapWidget.build()` instantiates `MapWidget` with only `onMapCreated` — no error handler.
- `AppEnv.mapboxPublicToken` is declared `String?` (optional) via `@EnviedField(optional: true)`.

---

## Affected Areas — Current State

### `ios/Runner/Info.plist`
No `MBXAccessToken` key. The relevant native Mapbox config is entirely absent. The existing plist ends at `UIBackgroundModes` + the `#ifdef RIDEGLORY_DEV_ATS` block. Add before `</dict>`:
```xml
<key>MBXAccessToken</key>
<string>$(MAPBOX_PUBLIC_TOKEN)</string>
```

### `lib/main.dart` (lines 40–43)
```dart
const mapboxToken = AppEnv.mapboxPublicToken;
if (mapboxToken != null && mapboxToken.isNotEmpty) {
  MapboxOptions.setAccessToken(mapboxToken);
}
```
Replace with:
```dart
final mapboxToken = AppEnv.mapboxPublicToken;
assert(mapboxToken != null && mapboxToken!.isNotEmpty, 'MAPBOX_PUBLIC_TOKEN must be set in .env');
MapboxOptions.setAccessToken(mapboxToken!);
```

### `lib/shared/widgets/map/route_map_preview.dart`
`_RouteMapPreviewState` has no `_mapLoadError` field. `MapWidget` in `build()`:
```dart
MapWidget(
  cameraOptions: CameraOptions(...),
  styleUri: MapboxStyles.DARK,
  onMapCreated: (mapboxMap) async { ... },
)
```
No `onMapLoadError`. When the style fails, the map container renders black inside the 200px `Container`. The existing "no coordinates" placeholder (map icon + two `Text` widgets) is already implemented in the `else` branch and can be reused.

### `lib/features/events/presentation/tracking/widgets/live_map_widget.dart`
`MapWidget` in `build()`:
```dart
return MapWidget(
  viewport: CameraViewportState(...),
  styleUri: MapboxStyles.STANDARD,
  onMapCreated: (mapboxMap) async { ... },
);
```
No error handler. `LiveMapWidget` exposes `onMapReady` callback but no error callback to its parent. The parent `LiveMapBody` would need an `onMapError` callback added to `LiveMapWidget`'s constructor to show a `SnackBar`.

---

## Acceptance Criteria

1. Opening an event detail page on Android emulator renders the Mapbox dark style map with tiles — not a black screen.
2. Opening an event detail page on iOS simulator renders the Mapbox dark style map with tiles — not a black screen.
3. Opening an event detail page on a physical Android device renders the map correctly.
4. Opening an event detail page on a physical iOS device renders the map correctly.
5. When the Mapbox token is invalid or the device is offline, `RouteMapPreview` shows the map icon + subtitle placeholder, not a black rectangle.
6. When map load fails in `LiveMapWidget`, the `onMapError` callback is invoked; `LiveMapBody` shows a `SnackBar` error instead of silence.
7. `dart analyze lib/` produces 0 errors. The pre-existing unused-element warning on `_formatKm` is acceptable.
8. The app launches without crashing on either platform after all four changes are applied.

---

## Regression Guardrails

| Area | Guardrail | Verification Step |
|------|-----------|-------------------|
| Android map | `MAPBOX_ACCESS_TOKEN` in `local.properties` and manifest placeholder in `build.gradle.kts` unchanged | `git diff android/` — no removals |
| Route map geocoding | `_geocodeAddress`, `_fitMapBounds`, `_updateAnnotations` unchanged | Code review diff — only `_mapLoadError` field + `onMapLoadError` added |
| Live tracking annotations | `_updateAnnotations`, `InitialsMarkerIcon`, `LiveMapController` unchanged | Code review diff — only error handler added to `MapWidget` |
| Existing tests | All currently passing tests remain green | `flutter test` output: only TC-2-28 pre-existing failure acceptable |
| DI / cubits | No cubit, repository, or use case files modified | No files under `lib/**/cubit/`, `lib/**/domain/`, `lib/**/data/` in diff |
| Localization | `app_es.arb` changes minimal — SnackBar in `LiveMapBody` may reuse existing key | `dart analyze` + `flutter gen-l10n` no errors |

---

## Suggested Phase Plan

```
needsDesign: false
needsBackend: false
needsFrontend: true
needsDb: false
```

Phases required: **frontend** → **qa** (dart analyze gate + manual smoke test on device) → **tech_lead** (code review).

Architect phase is optional — the changes are well-scoped and do not introduce new layers or contracts. If the architect phase runs, the sole concern is confirming `onMapLoadError` API shape in `mapbox_maps_flutter` 2.23.1 (already confirmed resolvable).

---

## Notes for Orchestrator

1. **iOS build prerequisite**: Developer must have `~/.netrc` with Mapbox credentials and run `pod install` before testing on iOS. This is not a code change — document in `DEPLOY.md`.

2. **`Info.plist` build variable**: The `$(MAPBOX_PUBLIC_TOKEN)` syntax in `Info.plist` requires a corresponding `MAPBOX_PUBLIC_TOKEN` entry in the Xcode build settings (or xcconfig). Confirm this is already wired (it should be, given Android's `local.properties` pattern). If not, the frontend developer must add it to the xcconfig files.

3. **`onMapLoadError` API**: Verify the exact callback signature in `mapbox_maps_flutter` 2.23.1 before implementing. The PRD refers to `MapWidget.onMapLoadError` — this should be `MapWidget(onMapLoadError: (MapLoadingError error) { ... })`. Cross-check the package's public API before writing.

4. **`main.dart` assert**: `assert()` statements are stripped in release builds in Flutter. The `assert` is for dev-time safety only. In release mode, `mapboxToken!` will throw a `Null check operator` error if the token is null — which is the correct fail-fast behavior for a release build with a missing token.

5. **No new widget tests required**: Mapbox map rendering requires the native platform layer and cannot be widget-tested. The QA gate is `dart analyze` (0 errors) + manual device smoke test. No mocktail/stub-based map test is needed for this bug fix.

6. **Scope is 4 files**: `ios/Runner/Info.plist`, `lib/main.dart`, `lib/shared/widgets/map/route_map_preview.dart`, `lib/features/events/presentation/tracking/widgets/live_map_widget.dart`. No other files should be modified.
