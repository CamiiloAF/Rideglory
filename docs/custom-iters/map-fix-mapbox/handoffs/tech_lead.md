# Tech Lead Review — map-fix-mapbox

**Reviewer:** Tech Lead agent
**Reviewed at:** 2026-05-16T23:10:00Z
**Based on QA handoff:** QA PASS (2026-05-16T22:46:37Z)

---

## Review verdict

**APPROVED**

All changes are correct, minimal, architecturally clean, and non-breaking. No required changes. See recommended follow-ups for non-blocking improvements.

---

## Correctness findings

### `lib/main.dart`

**PASS — correct and sufficient.**

- `AppEnv.mapboxPublicToken` is declared `static const String?` (optional, envied-generated). In a properly configured build, envied bakes the token in at compile time and the field is never null.
- The `assert(mapboxToken != null && mapboxToken!.isNotEmpty, ...)` fires in debug mode when the `.env` is missing or has an empty `MAPBOX_PUBLIC_TOKEN`. The `!` inside the assert body is benign (asserts are not evaluated when stripped).
- After the assert, `MapboxOptions.setAccessToken(mapboxToken!)` is unconditional. In release mode the assert is stripped but the `!` non-null assertion remains and will throw `Null check operator used on a null value` at startup if the token is missing. This is the desired fail-fast behavior: a misconfigured production build crashes immediately rather than rendering a silent black map. Acceptable and intended.
- The old conditional guard (`if (mapboxToken != null && mapboxToken.isNotEmpty)`) correctly identified the defensive gap. The new pattern eliminates it.

### `ios/Runner/Info.plist`

**PASS — correct placement, correct XML structure.**

- `MBXAccessToken` key/value is placed inside `</dict>` **after** the `#endif` that closes the `RIDEGLORY_DEV_ATS` block (confirmed by diff: the two new lines appear between `#endif` and `</dict>`). It is therefore present in all build configurations (Debug, Profile, Release) and is unaffected by the ATS preprocessor block.
- The file is preprocessed with `-traditional -P` flags; the new plain XML `<key>`/`<string>` pair contains no C preprocessor directives and is immune to preprocessing — no substitution or stripping occurs.
- Value is the literal `pk.eyJ1IjoiY2FtaWlsbzkyIi...` token (matching `android/local.properties`). This is a read-only Mapbox **public** token — not a secret. Embedding it in `Info.plist` is architecturally equivalent to the Android manifest placeholder injection and is appropriate for client-side SDKs.
- The pre-existing `CFBundleSignature` missing `<string>` value at line 21 is confirmed pre-existing (identical in HEAD); not introduced by this change.

### `lib/shared/widgets/map/route_map_preview.dart`

**PASS — error gating is correct and safe.**

- `bool _mapLoadError = false` is a state field on `_RouteMapPreviewState`. It starts false and is set to true on the first `onMapLoadErrorListener` callback.
- The condition `_hasCoordsToShow && !_mapLoadError` correctly shows the `MapWidget` only when (a) there are coordinates to render AND (b) no map load error has occurred. When `_mapLoadError` is true, the widget falls to the `else` branch showing the existing placeholder icon. This matches AC #5.
- `onMapLoadErrorListener` is wired to the correct `MapWidget` — the sole `MapWidget` in `build()`.
- The `if (!mounted) return;` guard before `setState` in the callback is correct and safe.
- The `import ... hide Error` directive is preserved (confirmed: line 4). `MapLoadingErrorEventData` is a separate class from `Error` and is not hidden — no conflict.
- `_mapLoadError` is sticky (never reset to false within the widget instance). When the user navigates away and returns, a new `_RouteMapPreviewState` instance is created and `_mapLoadError` starts false again — so the error is naturally cleared by navigation. This is correct and matches the architect's intent.

**Minor observation (non-blocking):** The placeholder text strings `'Vista previa del mapa'`, `'Ingresa las dirección para ver la ruta'`, and `'Ver en mapa'` are hardcoded in Spanish — not using `context.l10n`. This violates the project's localization rule (CLAUDE.md: "All user-visible text in `app_es.arb`"). However, these strings are **pre-existing** — they exist in the widget before this iteration's changes. They are not introduced by this change and are out of scope for this bug fix. Additionally, `'Ingresa las dirección para ver la ruta'` has a grammatical agreement error (`las dirección` should be `la dirección`) that is also pre-existing. These are flagged as follow-ups only.

### `lib/features/events/presentation/tracking/widgets/live_map_widget.dart`

**PASS — correct API surface and correct wiring.**

- `final ValueChanged<String>? onMapError` is the right type signature: `ValueChanged<String>` is `void Function(String)`, which matches the intent of passing only `data.message` upward. This is a clean abstraction that shields consumers from the Mapbox-specific `MapLoadingErrorEventData` type.
- The parameter is optional (nullable) with a `?`. There is one existing caller — `LiveMapBody` — which now passes `onMapError:`. Because the parameter is optional, zero other callers are broken (the parameter defaults to null and the callback is a no-op via `?.call(...)`). No breaking change.
- `onMapLoadErrorListener: (MapLoadingErrorEventData data) { widget.onMapError?.call(data.message); }` is correctly wired. No `mounted` check is needed here because the callback only delegates to an optional parent callback (no `setState` or `BuildContext` usage inside `_LiveMapWidgetState`'s listener body).
- The `MapWidget` has no wrapping `if (!mounted)` guard needed in this listener because the callback itself is stateless at this level — the state management responsibility is delegated to the parent.

### `lib/features/events/presentation/tracking/widgets/live_map_body.dart`

**PASS — deduplication and context safety are correct.**

- The `onMapError` callback captures the `BlocBuilder`'s `builder` context (the `(context, state)` parameter at line 53), not the outer `build(BuildContext context)` context. The `BlocBuilder` context is a valid mounted context as long as the widget is in the tree — this is the correct context to use for `ScaffoldMessenger.of(context)`.
- `removeCurrentSnackBar()` is called before `showSnackBar()` — deduplication is correct. Even if `onMapLoadErrorListener` fires repeatedly (e.g. for tile-level errors on each tile), only one SnackBar is ever visible at a time.
- `context.l10n.map_loadError` resolves correctly: the key exists in `app_es.arb`, the abstract getter is in `app_localizations.dart`, and the implementation is in `app_localizations_es.dart`.
- `LiveMapBody` is `StatelessWidget`. The `onMapError` callback is a closure created fresh on each `build` + `BlocBuilder` rebuild. This is fine — `LiveMapWidget` holds the callback as a final field that is updated via `didUpdateWidget` when the widget config changes (standard Flutter pattern).

### `lib/l10n/app_es.arb` + generated files

**PASS.**

- `"map_loadError": "No se pudo cargar el mapa."` is placed correctly after `map_geocodeError` in the map-feature key group.
- `@map_loadError` metadata block has a description — good practice.
- `app_localizations.dart` abstract getter and `app_localizations_es.dart` implementation both present and matching.
- The message text is specific to a map-load failure, correctly distinguished from the geocoding error (`map_geocodeError`).

---

## Architecture compliance

**PASS — no violations.**

| Rule | Status | Notes |
|------|--------|-------|
| Domain layer isolation | PASS | No domain or data files modified |
| No HTTP/data calls in widgets | PASS | `route_map_preview.dart` and `live_map_body.dart` are pure presentation |
| No BuildContext in non-widget code | PASS | `ScaffoldMessenger.of(context)` is used inside a `BlocBuilder.builder` callback — a widget context, not a service or repository |
| No DTO exposure in presentation | PASS | `MapLoadingErrorEventData` (a Mapbox SDK type) is not exposed to `LiveMapBody`; only `String message` crosses the widget boundary |
| One widget per file | PASS | `LiveMapController` lives in the same file as `LiveMapWidget` — `LiveMapController` is not a widget, it is a plain Dart controller class; no rule violation |
| No direct HTTP in presentation | PASS | No new HTTP calls added |
| ResultState pattern | PASS | No new state; error handling uses local `bool` field for a purely presentational toggle (correct for a widget-level UI flag) |

---

## Risk assessment

### Risk 1 — assert stripped in release; `!` non-null assertion remains

**Acceptable.** The assert provides a loud failure in debug during development. In release, the `!` operator throws at startup if the token is null — which is the correct behavior. A silent null token would produce a black map with no developer feedback; a startup crash is strictly better. This is documented in the architect handoff and matches the PRD's intent. No action required.

### Risk 2 — Literal `pk.*` token in Info.plist (security)

**Acceptable — no security concern.** Mapbox public tokens (`pk.*`) are designed for client-side embedding and have no write or admin capabilities. The identical token is already shipped in every Android APK via the manifest placeholder in `android/app/build.gradle.kts`. Adding it to `Info.plist` does not change the security posture. Secret `sk.*` tokens (used only for server-side operations) must never be committed — none are present here.

### Risk 3 — `_mapLoadError` stays true for widget lifetime; no retry

**Acceptable for this iteration.** Navigating away and back creates a fresh `_RouteMapPreviewState` instance, resetting `_mapLoadError` to false. This is the natural Flutter widget lifecycle and does not require any explicit reset logic. A retry button would be a quality-of-life improvement but is explicitly out of scope for this bug fix. The error state is also specific to a failed Mapbox token/style load — once the app is correctly configured, this error will not fire in normal usage. Flagged as a non-blocking follow-up.

### Risk 4 — Stale/unmounted context in `live_map_body.dart` snackbar callback

**No real risk — context is safe.** The `context` captured by the `onMapError` closure is the `BlocBuilder.builder` context (a scoped `BuildContext` associated with the `BlocBuilder` element). This context is valid and mounted while `LiveMapBody` is in the widget tree. `ScaffoldMessenger.of(context)` resolves to the `Scaffold` ancestor above `LiveMapBody`, which is valid. The callback can only fire while `LiveMapWidget` is mounted (Mapbox calls `onMapLoadErrorListener` only during map lifecycle, which is tied to the widget's lifecycle). There is no scenario where the callback fires after the widget is unmounted that would cause a practical problem, because `ScaffoldMessenger` is obtained lazily at call time. This is safe.

---

## Code quality notes

The following are non-blocking observations — the implementation meets the project's quality bar.

1. **Pre-existing hardcoded strings in `route_map_preview.dart` (not introduced by this change):** Three Spanish string literals in the placeholder UI are not using `context.l10n`. One has a grammatical error (`'Ingresa las dirección para ver la ruta'` → `'Ingresa la dirección para ver la ruta'`). These pre-date this iteration and should be fixed in a dedicated cleanup iteration.

2. **`dart format` not run by Frontend before handoff.** Two files required formatting fixes by QA. This is a minor process gap — the Frontend agent should run `dart format` before handing off. Worth noting for future iterations.

3. **`onMapError` callback fires for all `MapLoadErrorType` values**, including `tile` failures mid-session. For `LiveMapWidget`, this means a transient tile fetch failure during a live ride would show a "No se pudo cargar el mapa" SnackBar even though the map is otherwise functional. This is a UX edge case — the `removeCurrentSnackBar()` deduplication mitigates the spam, and the severity (showing one extra SnackBar occasionally) is low. A future improvement could filter on `data.type == MapLoadErrorType.style` to only surface style-level failures.

4. **`live_map_body.dart` is `StatelessWidget` — the `onMapError` callback cannot track "already shown" state.** If `LiveMapWidget` is rebuilt (e.g., a rider update triggers `BlocBuilder`), a new `onMapError` closure is passed via `didUpdateWidget`. If the error fires between two rebuilds, two SnackBars could theoretically show in rapid succession. In practice this is extremely unlikely (map errors do not fire on every frame), and `removeCurrentSnackBar()` mitigates it. A stateful guard (`bool _mapErrorShown`) would be the robust fix but is out of scope for this iteration.

5. **No `mounted` check in `LiveMapWidget`'s `onMapLoadErrorListener` callback.** Not needed here because the callback contains no Flutter state mutations (`setState`) — it only delegates to `widget.onMapError?.call(...)`. If `widget.onMapError` is null or does nothing, the callback is effectively a no-op. This is correct.

---

## Required changes

None.

---

## Recommended follow-ups

1. **Localize hardcoded strings in `route_map_preview.dart`** — move `'Vista previa del mapa'`, `'Ingresa la dirección para ver la ruta'` (also fix the grammatical error), and `'Ver en mapa'` to `app_es.arb` under appropriate `map_` keys. This was a pre-existing violation out of scope here.

2. **Add retry mechanism to `RouteMapPreview` error state** — when `_mapLoadError` is true, the placeholder could include a "Reintentar" button that calls `setState(() => _mapLoadError = false)` to let the map re-render. This is a UX improvement for the offline/bad-token scenario.

3. **Filter `onMapLoadErrorListener` by error type in `LiveMapWidget`** — consider only invoking `widget.onMapError` when `data.type == MapLoadErrorType.style` (full style load failure) rather than on every tile or sprite error, to reduce false-positive SnackBars during live tracking.

4. **Wire xcconfig for `$(MAPBOX_PUBLIC_TOKEN)` substitution in `Info.plist`** — the architect recommended the literal token as a simpler short-term fix. A future iteration should add `MAPBOX_PUBLIC_TOKEN = pk.eyJ1...` to `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` and switch `Info.plist` to use `$(MAPBOX_PUBLIC_TOKEN)`. This aligns iOS with the Android build-variable pattern and avoids the literal token appearing in git blame.

5. **Update `DEPLOY.md`** with the iOS `~/.netrc` setup prerequisite (PRD § 8). Scoped to the DevOps phase, not implemented here.

6. **Frontend process: run `dart format` before handoff** — two files needed formatting fixes by QA in this iteration. Recommend adding `dart format lib/` as the final step before declaring Frontend complete.
