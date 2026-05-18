# Architect Handoff — map-fix-mapbox

## Goal acknowledgement

Make Mapbox render on both platforms by (1) ensuring the iOS native SDK initializes with a valid public token via `Info.plist`, (2) making the Dart-side token set fail-fast on misconfiguration, and (3) surfacing visible UI when `MapWidget` fails to load its style — so users never see a silent black screen on event preview or live tracking.

The fix is purely Flutter + iOS native config. No backend, no DB, no design, no contract changes. The Mapbox public token (`pk.*`) is already public-safe (shipped in every Android APK), so embedding it in `Info.plist` is acceptable from a security standpoint.

## Change map

| File | Action | One-line reason | Risk |
|------|--------|-----------------|------|
| `ios/Runner/Info.plist` | modify | Add `MBXAccessToken` key with the literal `pk.*` token so the iOS Mapbox SDK initializes natively before Dart runs | med |
| `lib/main.dart` | modify | Replace silent conditional token set with fail-fast `assert` + unconditional `MapboxOptions.setAccessToken(mapboxToken!)` | low |
| `lib/shared/widgets/map/route_map_preview.dart` | modify | Add `_mapLoadError` state field; wire `MapWidget.onMapLoadErrorListener`; on error, render the existing icon + subtitle placeholder instead of black surface | med |
| `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` | modify | Add optional `onMapError` callback to constructor; wire `MapWidget.onMapLoadErrorListener` to invoke it | low |
| `lib/features/events/presentation/tracking/widgets/live_map_body.dart` | modify | Consume new `onMapError` from `LiveMapWidget` and show a `SnackBar` (reuse existing `context.l10n.map_geocodeError` or new key — see localization note) | low |
| `lib/l10n/app_es.arb` | modify (optional) | Add `map_loadError` key if a tracking-specific message is preferred; otherwise reuse `map_geocodeError` | low |

Files NOT in this list are out of bounds for the frontend phase.

## Data model impact

None.

## Contract impact

None — no API, DTO, or use case changes.

## Env / config delta

- `.env` already contains `MAPBOX_PUBLIC_TOKEN`. No new env vars.
- Xcode build variable `$(MAPBOX_PUBLIC_TOKEN)` is **NOT defined** in any xcconfig (confirmed by reading `ios/Flutter/Debug.xcconfig`, `Release.xcconfig`, and grepping `ios/` for the symbol). Using `$(MAPBOX_PUBLIC_TOKEN)` literally inside `Info.plist` would resolve to an empty string at build time.
- **Decision:** insert the **literal `pk.*` token** as the `MBXAccessToken` value in `Info.plist`. The same literal already lives in `android/local.properties` and is injected into the Android manifest at build time; embedding it on iOS does not change the public-token security posture. This avoids a parallel xcconfig wiring exercise that is out of scope for a bug-fix iteration. See "Notes for orchestrator" for the alternative.
- The literal pk token to use: the value of `MAPBOX_ACCESS_TOKEN` from `android/local.properties`.

## Risk register

1. **Risk:** `Info.plist` is preprocessed by the C preprocessor (`INFOPLIST_PREPROCESS = YES` in both xcconfigs) with `-traditional -P` flags so the `#ifdef RIDEGLORY_DEV_ATS` block works. Inserting a literal token with `pk.` is plain XML and is unaffected by the preprocessor (no `#` directives, no macro substitution). **Mitigation:** insert the key/value as plain XML before `</dict>` and outside the existing `#ifdef ... #endif` block. Validate by building both Debug and Release on iOS.
2. **Risk:** `assert(mapboxToken != null && mapboxToken!.isNotEmpty)` is stripped from release builds; if the `.env` token is missing in production, `MapboxOptions.setAccessToken(mapboxToken!)` will throw `Null check operator used on a null value` at startup. **Mitigation:** this is the desired fail-fast behavior — better to crash on the first frame than render a silent black map. Document in `DEPLOY.md`.
3. **Risk:** `route_map_preview.dart` already imports `mapbox_maps_flutter` with `hide Error` (because of the `ResultState.Error` name collision). The new field name `_mapLoadError` is a `bool` and the import hide does not affect `MapLoadingErrorEventData` (which has a different name). **Mitigation:** the frontend must keep the existing `hide Error` directive and reference `MapLoadingErrorEventData` directly (no alias needed).
4. **Risk:** `LiveMapWidget`'s parent (`live_map_body.dart`) is wrapped in a `BlocBuilder` that rebuilds on rider list changes. If `onMapError` triggers a `ScaffoldMessenger.of(context).showSnackBar()`, repeated rebuilds could spam the snackbar. **Mitigation:** parent should track whether the snackbar has already been shown (e.g. local `bool _mapErrorShown` in a `StatefulWidget` ancestor, or guard at call-site by clearing previous snackbars before showing). For simplicity, the snackbar callback can simply call `ScaffoldMessenger.of(context).removeCurrentSnackBar()` then `.showSnackBar(...)` so only one is visible.
5. **Risk:** `MapLoadingErrorEventData.type` may fire for transient tile failures (not full style failures) — this could cause the placeholder to replace a partly-working map. **Mitigation:** for `RouteMapPreview` the bar is low (no coords yet at startup, so a brief tile error mid-load is acceptable to show as placeholder). For `LiveMapWidget`, only fire the snackbar once per page life — see risk 4. Do not auto-recover from the placeholder; user must navigate away and back.
6. **Risk:** `pod install` on a fresh iOS dev machine requires `~/.netrc` with `MAPBOX_DOWNLOADS_TOKEN`. **Mitigation:** documented in PRD § 8. Frontend should not run `pod install`; if QA reports missing pods, point to the doc. Out of scope for this fix.

## Regression test surface

- **Widget tests:** Mapbox rendering is not widget-testable (requires native platform layer). No existing widget tests cover `RouteMapPreview` or `LiveMapWidget` rendering — only the cubits and pages around them. Gap is acceptable per PRD AC #7 (`dart analyze` + manual smoke test is the QA bar).
- **Existing tests covering touched code:** none directly. `main.dart` has no unit test. `LiveMapBody`/`LiveMapWidget` have no widget tests. `RouteMapPreview` has no widget test.
- **`flutter test`:** must remain green except for the pre-existing TC-2-28 failure noted in PRD.
- **`dart analyze`:** must produce 0 errors. The pre-existing unused-element warning on `_formatKm` is acceptable and must not increase.

## Implementation order

Frontend must execute in this order so each step is independently testable:

1. **`lib/main.dart`** — replace conditional token set with the assert + non-null assertion pattern. This is the lowest-risk change and makes future misconfigs loud.
2. **`ios/Runner/Info.plist`** — add `<key>MBXAccessToken</key><string>pk.eyJ1Ijoi...</string>` before `</dict>` and outside the `#ifdef RIDEGLORY_DEV_ATS` block. After this, iOS native init should pick up the token. Run `flutter clean && flutter run -d <ios-sim>` to verify the map renders.
3. **`lib/shared/widgets/map/route_map_preview.dart`** — add `bool _mapLoadError = false` field; wire `MapWidget.onMapLoadErrorListener: (data) { if (mounted) setState(() => _mapLoadError = true); }`; in `build()`, change the `if (_hasCoordsToShow)` branch to `if (_hasCoordsToShow && !_mapLoadError)` and let the existing `else` placeholder render. Important: keep `import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;` — `MapLoadingErrorEventData` is not affected by the hide.
4. **`lib/features/events/presentation/tracking/widgets/live_map_widget.dart`** — add optional `final ValueChanged<String>? onMapError;` constructor parameter; wire `MapWidget.onMapLoadErrorListener: (data) => widget.onMapError?.call(data.message)`.
5. **`lib/features/events/presentation/tracking/widgets/live_map_body.dart`** — pass `onMapError:` to `LiveMapWidget`; in the callback show a single `SnackBar` (clear previous first). Reuse `context.l10n.map_geocodeError` or add a new `map_loadError` key in `app_es.arb` if the wording is too geocode-specific.
6. **(Optional) `lib/l10n/app_es.arb`** — if step 5 needs a new key, add `"map_loadError": "No se pudo cargar el mapa."` and rerun `flutter gen-l10n` (or `dart run build_runner build --delete-conflicting-outputs`).
7. Run `dart analyze lib/` — must report 0 errors.
8. Run `flutter test` — must match pre-iteration baseline (TC-2-28 failure acceptable).
9. Manual smoke: open event detail on iOS sim and Android emulator; verify map tiles render. Then temporarily set a bad token in `.env`, run `dart run build_runner build`, and verify the placeholder shows on event detail and the snackbar appears on live tracking.

## Mapbox API details

Verified by reading `~/.pub-cache/hosted/pub.dev/mapbox_maps_flutter-2.23.1/lib/src/`:

- **Parameter name on `MapWidget`:** `onMapLoadErrorListener` (NOT `onMapLoadError` — the PRD's working name is shorthand; the actual API has the `Listener` suffix). Source: `lib/src/map_widget.dart` line 61.
- **Callback typedef:** `typedef void OnMapLoadErrorListener(MapLoadingErrorEventData mapLoadingErrorEventData);` (source: `lib/src/callbacks.dart` lines 20–21).
- **`MapLoadingErrorEventData` shape** (source: `lib/src/events.dart` lines 127–150):
  ```dart
  class MapLoadingErrorEventData {
    final MapLoadErrorType type;   // style / source / tile / sprite / glyphs
    final String message;          // human-readable error
    final String? sourceId;
    final TileID? tileId;
    final int timestamp;
  }
  ```
- **Wiring pattern** (same as existing `onMapCreated`):
  ```dart
  MapWidget(
    // ...existing params...
    onMapCreated: (mapboxMap) async { /* existing */ },
    onMapLoadErrorListener: (MapLoadingErrorEventData data) {
      if (!mounted) return;
      setState(() => _mapLoadError = true); // for RouteMapPreview
      // OR widget.onMapError?.call(data.message);  // for LiveMapWidget
    },
  )
  ```
- **Naming for `LiveMapWidget` constructor parameter:** `onMapError` is fine as a public surface name (cleaner than exposing the Mapbox-specific listener type to consumers). Pass only the `String message` upward — keep `MapLoadingErrorEventData` internal.
- **Import note for `route_map_preview.dart`:** the file imports with `hide Error` due to `ResultState.Error` collision. `MapLoadingErrorEventData` and `OnMapLoadErrorListener` are unaffected by `hide Error` because their names contain `Error` only as a substring, not as the bare symbol — verified by inspection. No import changes required.

## Out of scope

- Wiring `MAPBOX_PUBLIC_TOKEN` into xcconfig so the `Info.plist` `$(MAPBOX_PUBLIC_TOKEN)` substitution works at build time. The literal embedding is a faster, lower-risk path for this bug fix. A future iteration can refactor to xcconfig-driven injection if secret rotation becomes a concern.
- Mapbox style customization, attribution tweaks, or marker icon changes — only error handling is in scope.
- Adding widget tests for the map widgets — Mapbox cannot be widget-tested.
- Updating `DEPLOY.md` with the `~/.netrc` requirement — that is the devops phase responsibility (PRD § 8) and not part of frontend work.
- Touching `LiveMapController`, geocoding logic, `_updateAnnotations`, or `InitialsMarkerIcon`.

## Notes for orchestrator

1. **Token embedding decision:** the literal-in-plist choice flips the PRD's `$(MAPBOX_PUBLIC_TOKEN)` recommendation because no such build variable exists in xcconfig today. If you prefer the build-variable form, the alternative is: add `MAPBOX_PUBLIC_TOKEN = pk.eyJ1...` to `ios/Flutter/Debug.xcconfig` and `Release.xcconfig`, then use `$(MAPBOX_PUBLIC_TOKEN)` in `Info.plist`. Net effect is identical at build time; literal embedding is simpler.
2. **Localization key:** the architect recommends reusing `map_geocodeError` ("No se pudo obtener las coordenadas.") only for `RouteMapPreview` — but for `LiveMapWidget`, a SnackBar with that text would be misleading (the error is the map style, not geocoding). Strongly recommend adding `map_loadError: "No se pudo cargar el mapa."` to `app_es.arb`.
3. **No new tests required** beyond `dart analyze` (0 errors) per PRD AC #7. Manual smoke is the verification gate.
4. **iOS `pod install`:** if QA hits Mapbox XCFramework download failures, the dev machine is missing `~/.netrc` — see PRD § 8. Not a code issue.
