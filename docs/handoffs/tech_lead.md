# Tech Lead Review — iter-3 (PR #15)

**Decision: BLOCKED**
**Reviewed at:** 2026-05-15T06:00:00Z
**PR:** https://github.com/CamiiloAF/Rideglory/pull/15
**Iteration:** 3 — Tracking Completo + SOS + Organizer Controls + Mapbox Migration

---

## Summary

PR #15 delivers 7 stories (3.0, 3.1, 3.2, 3.3, 3.4, 3.5, 3.10) including the full Mapbox migration, SOS flow, organizer ride controls, background GPS, and SOAT vehicle badge. The Story 3.0 hard gate (zero `google_maps_flutter` / `geocoding` imports) is satisfied. BUG-3-1 (widget test for `route_map_preview.dart`) is resolved — the test file is present and 4/4 pass.

However, **6 blocking violations** prevent merge: a Clean Architecture layer breach and 5 coding-standards violations. All are correctable in a single fix cycle.

---

## Hard Gates

| Gate | Status |
|---|---|
| Zero `google_maps_flutter` imports in `lib/` | PASS |
| Zero `geocoding` imports in `lib/` | PASS |
| `dart analyze` 0 errors/0 warnings | PASS (per frontend handoff) |
| `flutter test` — target stories pass | PASS (43 pass / 1 pre-existing fail TC-2-28) |
| BUG-3-1 widget test for `route_map_preview.dart` | PASS (4/4 cases present) |

---

## Blocking Violations

### BLOCK-1 — Clean Architecture: Data layer imported in cubit

**File:** `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` L15–17

The cubit imports `package:dio/dio.dart`, `event_service.dart`, and `tracking_ws_client.dart` — all data-layer concerns. The cubit also catches `DioException` directly (~L400), a data-layer exception type leaking into presentation.

**Required fix:** Extract a `TrackingRepository` interface (domain) with `endRide(String eventId)` and `publishSos(SosAlertModel)` methods. The data-layer `TrackingRepositoryImpl` wraps `EventService` and `TrackingWsClient` and converts `DioException` to `DomainException`. Cubit receives `TrackingRepository` via injection.

---

### BLOCK-2 — Coding Standards: `_buildXxx` helper methods

**File:** `lib/features/events/presentation/tracking/live_map_page.dart` L203, L224, L256

`_buildAppBar()`, `_buildLiveMapAppBar()`, `_buildBody()` are Widget-returning private methods violating the "no `_buildXxx` helpers" rule.

**Required fix:** Extract to separate widget files, e.g. `live_map_app_bar.dart` and `live_map_body.dart`.

---

### BLOCK-3 — Coding Standards: Hardcoded Spanish strings in `sos_banner.dart`

**File:** `lib/features/events/presentation/tracking/widgets/sos_banner.dart` L22, L34, L51

Three SnackBar messages not in `app_es.arb`:
- `'No se pudo iniciar la llamada.'`
- `'No se pudo obtener la ubicación del rider.'`
- `'No se pudo abrir el mapa.'`

**Required fix:** Add l10n keys (e.g., `tracking_sosCallError`, `tracking_sosLocationError`, `tracking_sosMapError`) and use `context.l10n.<key>`.

---

### BLOCK-4 — Coding Standards: Hardcoded Spanish string in `sos_button.dart`

**File:** `lib/features/events/presentation/tracking/widgets/sos_button.dart` L21

Semantics label `'Enviar alerta de emergencia'` is a raw literal.

**Required fix:** Add l10n key `tracking_sosSemanticsLabel` and use `context.l10n.tracking_sosSemanticsLabel`.

---

### BLOCK-5 — Coding Standards: Hardcoded Spanish string in `route_map_preview.dart`

**File:** `lib/shared/widgets/map/route_map_preview.dart` L288

Error text `'No se pudo obtener las coordenadas.'` is hardcoded in `build()`.

**Required fix:** Add l10n key `map_geocodeError` and use `context.l10n.map_geocodeError`.

---

### BLOCK-6 — Coding Standards: Multiple widget classes per file

**Files:**
- `lib/features/events/presentation/tracking/widgets/sos_banner.dart`: `SosBannerWidget` (L9) + `_SosBannerAction` (L131)
- `lib/features/home/presentation/widgets/home_garage_card.dart`: `HomeGarageCard` + `_HeroImage` + `_PlaceholderImage` + `_VehicleInfo` + `_SoatBadge`

**Required fix:** One widget class per file. Extract private widgets to sibling files in the same directory.

---

## Non-Blocking / Deferred

1. `home_garage_card.dart` — `_SoatBadge._statusLabel()` may return the same l10n key for all three `SoatStatus` values (valid/expiringSoon/expired). Verify three distinct keys are used. Fix before iter-4 if confirmed as logic bug.

2. `DioException` catch in cubit `endRide()` (~L400) will be automatically resolved when BLOCK-1 is addressed.

---

## What Passed

- Mapbox migration correct: `Position(longitude, latitude)` lng-first order respected throughout
- `mapbox_maps_flutter hide Error` import alias used where `ResultState<T>` is also used
- `geolocator as geo` alias used where Mapbox and geolocator Position types conflict
- `SosAlertModel` in domain layer — clean, no Flutter imports
- `GeocodeResultDto` in `lib/core/services/dto/` — correct placement
- `AddressLocation` in `lib/shared/models/` — clean domain model
- `OrganizerControlBar`, `RideFinishedOverlay` — one widget per file, AppButton used, l10n used
- `live_tracking_state.dart` — freezed state with `sosAlertResult: ResultState<SosAlertModel?>` — correct pattern
- `app_es.arb` — ~30 new keys with proper placeholder documentation
- `main.dart` — `MapboxOptions.setAccessToken(AppEnv.mapboxPublicToken)` before `runApp()`
- CI: `MAPBOX_DOWNLOADS_TOKEN` and `MAPBOX_ACCESS_TOKEN` secrets wired in `ci.yml`
- `AndroidManifest.xml` — Google Maps key removed, foreground service declared with `foregroundServiceType="location"`
- `route_map_preview_test.dart` — 4 test cases (loading/error/data/empty) using mocktail — BUG-3-1 resolved

---

## Decision

**BLOCKED.** Fix the 6 blocking violations and re-request review. No other phase may proceed until these are resolved and this review is updated to APPROVED.
